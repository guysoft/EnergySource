extends Node

# Playlist Manager - Handles loading playlists from JSON and managing playlist playback state

# Data classes
class SongEntry:
	var name: String
	var original_path: String  # Windows path from JSON
	var music_path: String     # Resolved local path
	var layout_path: String    # Path to layout JSON
	var music_length: float
	var layout_length: float
	var difficulty: String
	
	func _init():
		name = ""
		original_path = ""
		music_path = ""
		layout_path = ""
		music_length = 0.0
		layout_length = 0.0
		difficulty = "Expert"

class PlaylistData:
	var name: String
	var is_shuffle: bool
	var is_repeat: bool
	var is_endurance: bool
	var entries: Array  # Array of SongEntry
	var play_order: Array  # Array of int - shuffled indices if is_shuffle
	
	func _init():
		name = ""
		is_shuffle = false
		is_repeat = false
		is_endurance = false
		entries = []
		play_order = []
	
	func generate_play_order():
		play_order.clear()
		for i in range(entries.size()):
			play_order.append(i)
		
		if is_shuffle:
			# Fisher-Yates shuffle
			var rng = RandomNumberGenerator.new()
			rng.randomize()
			for i in range(play_order.size() - 1, 0, -1):
				var j = rng.randi_range(0, i)
				var temp = play_order[i]
				play_order[i] = play_order[j]
				play_order[j] = temp

# State variables
var _playlists: Array = []  # Array of PlaylistData
var _current_playlist: PlaylistData = null
var _current_song_index: int = 0  # Index into play_order
var _playlist_mode: bool = false
var _playlist_total_time: float = 0.0
var _playlist_time_tracking: bool = false

# Signals
signal playlist_loaded
signal playlist_started
signal playlist_song_changed(song_index: int, song_entry: SongEntry)
signal playlist_completed

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_playlists()
	Events.connect("song_begin", _on_song_begin)
	Events.connect("song_end", _on_song_end)

func _process(delta):
	if _playlist_time_tracking and _playlist_mode and not get_tree().paused:
		_playlist_total_time += delta

func _on_song_begin():
	if _playlist_mode:
		_playlist_time_tracking = true

func _on_song_end():
	if _playlist_mode:
		_playlist_time_tracking = false

# Load playlists from JSON file
func _load_playlists():
	_playlists.clear()
	
	var json_path = _get_playlists_json_path()
	if json_path == "":
		push_warning("PlaylistManager: Could not find playlists.json")
		return
	
	if not FileAccess.file_exists(json_path):
		push_warning("PlaylistManager: playlists.json not found at: " + json_path)
		return
	
	var file = FileAccess.open(json_path, FileAccess.READ)
	if file == null:
		push_error("PlaylistManager: Failed to open playlists.json")
		return
	
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_text)
	if error != OK:
		push_error("PlaylistManager: Failed to parse playlists.json: " + json.get_error_message())
		return
	
	var data = json.get_data()
	if not data.has("playlists"):
		push_error("PlaylistManager: playlists.json missing 'playlists' key")
		return
	
	for playlist_data in data["playlists"]:
		var playlist = _parse_playlist(playlist_data)
		if playlist != null:
			_playlists.append(playlist)
	
	print("PlaylistManager: Loaded ", _playlists.size(), " playlists")
	emit_signal("playlist_loaded")

func _get_playlists_json_path() -> String:
	# Look in parent directory of project (where PowerBeatsVRLevels is)
	var project_dir = ""
	var parent_dir = ""
	
	if OS.has_feature("editor"):
		project_dir = ProjectSettings.globalize_path("res://")
		if project_dir.ends_with("/"):
			project_dir = project_dir.substr(0, project_dir.length() - 1)
		parent_dir = project_dir.get_base_dir()
	else:
		project_dir = OS.get_executable_path().get_base_dir()
		parent_dir = project_dir
	
	var json_path = parent_dir + "/PowerBeatsVRLevels/playlists.json"
	return json_path

func _parse_playlist(data: Dictionary) -> PlaylistData:
	var playlist = PlaylistData.new()
	
	playlist.name = data.get("name", "Unnamed")
	playlist.is_shuffle = data.get("isShuffle", false)
	playlist.is_repeat = data.get("isRepeat", false)
	playlist.is_endurance = data.get("isEndurance", false)
	
	var entries_data = data.get("entries", [])
	for entry_data in entries_data:
		var entry = _parse_song_entry(entry_data)
		if entry != null:
			playlist.entries.append(entry)
	
	# Generate initial play order
	playlist.generate_play_order()
	
	return playlist

func _parse_song_entry(data: Dictionary) -> SongEntry:
	var entry = SongEntry.new()
	
	entry.name = data.get("name", "Unknown")
	entry.original_path = data.get("path", "")
	entry.music_length = data.get("musicLength", 0.0)
	entry.layout_length = data.get("layoutLength", 0.0)
	entry.difficulty = data.get("difficulty", "Expert")
	
	# Convert Windows path to local path
	entry.music_path = _convert_windows_path(entry.original_path)
	
	# Get layout path based on song name
	entry.layout_path = _get_layout_path_for_song(entry.name)
	
	return entry

# Convert Windows-style path to local PowerBeatsVRLevels/music path
func _convert_windows_path(windows_path: String) -> String:
	if windows_path == "":
		return ""
	
	# Normalize path separators
	var normalized = windows_path.replace("\\", "/")
	
	# Look for this file in PowerBeatsVRLevels/music
	var music_root = GameVariables.pbvr_music_path
	if music_root == "":
		return ""
	
	# Try to extract the relative path from "music/" onwards
	# e.g., "C:/users/steamuser/Desktop/music/ogg/song.ogg" -> "ogg/song.ogg"
	var music_marker = "/music/"
	var music_idx = normalized.to_lower().find(music_marker)
	if music_idx != -1:
		var relative_path = normalized.substr(music_idx + music_marker.length())
		var local_path = music_root + "/" + relative_path
		if FileAccess.file_exists(local_path):
			return local_path
	
	# Fallback: just use filename and check direct path
	var filename = normalized.get_file()
	var direct_path = music_root + "/" + filename
	if FileAccess.file_exists(direct_path):
		return direct_path
	
	# Search recursively in music folder as last resort
	var found_path = _find_file_recursive(music_root, filename)
	if found_path != "":
		return found_path
	
	# File not found, return empty
	push_warning("PlaylistManager: Could not find music file: " + filename + " (from: " + windows_path + ")")
	return ""

func _find_file_recursive(dir_path: String, filename: String) -> String:
	var dir = DirAccess.open(dir_path)
	if dir == null:
		return ""
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if not file_name.begins_with("."):
			var full_path = dir_path + "/" + file_name
			
			if dir.current_is_dir():
				# Recurse into subdirectory
				var found = _find_file_recursive(full_path, filename)
				if found != "":
					dir.list_dir_end()
					return found
			else:
				# Check if filename matches
				if file_name == filename:
					dir.list_dir_end()
					return full_path
		
		file_name = dir.get_next()
	
	dir.list_dir_end()
	return ""

func _get_layout_path_for_song(song_name: String) -> String:
	var layouts_path = GameVariables.pbvr_layouts_path
	if layouts_path == "":
		return ""
	
	# Layout files are named after the song
	var layout_path = layouts_path + "/" + song_name + ".json"
	if FileAccess.file_exists(layout_path):
		return layout_path
	
	return ""

# Public API

func get_playlists() -> Array:
	return _playlists

func get_playlist_count() -> int:
	return _playlists.size()

func get_playlist(index: int) -> PlaylistData:
	if index < 0 or index >= _playlists.size():
		return null
	return _playlists[index]

func get_playlist_by_name(playlist_name: String) -> PlaylistData:
	for playlist in _playlists:
		if playlist.name == playlist_name:
			return playlist
	return null

func is_playlist_mode() -> bool:
	return _playlist_mode

func get_current_playlist() -> PlaylistData:
	return _current_playlist

func get_current_song_index() -> int:
	return _current_song_index

func get_current_song() -> SongEntry:
	if _current_playlist == null:
		return null
	if _current_song_index < 0 or _current_song_index >= _current_playlist.play_order.size():
		return null
	var actual_index = _current_playlist.play_order[_current_song_index]
	return _current_playlist.entries[actual_index]

func get_total_songs_in_playlist() -> int:
	if _current_playlist == null:
		return 0
	return _current_playlist.entries.size()

func get_playlist_total_time() -> float:
	return _playlist_total_time

func format_playlist_time() -> String:
	var total_seconds = int(_playlist_total_time)
	var minutes = total_seconds / 60
	var seconds = total_seconds % 60
	return "%02d:%02d" % [minutes, seconds]

func has_next_song() -> bool:
	if _current_playlist == null:
		return false
	return _current_song_index < _current_playlist.play_order.size() - 1

func start_playlist(playlist: PlaylistData) -> bool:
	if playlist == null:
		push_error("PlaylistManager: Cannot start null playlist")
		return false
	
	_current_playlist = playlist
	_current_song_index = -1  # Will be incremented to 0 in _find_first_valid_song
	_playlist_mode = true
	_playlist_total_time = 0.0
	_playlist_time_tracking = false
	
	# Regenerate play order (handles shuffle)
	_current_playlist.generate_play_order()
	
	print("PlaylistManager: Starting playlist '", playlist.name, "' with ", playlist.entries.size(), " songs")
	if playlist.is_shuffle:
		print("PlaylistManager: Playlist is shuffled")
	
	emit_signal("playlist_started")
	
	# Find first valid song (skip songs without layouts)
	if not _find_first_valid_song():
		push_error("PlaylistManager: No valid songs in playlist")
		end_playlist()
		return false
	
	return true


func _find_first_valid_song() -> bool:
	# Find the first song with a valid layout
	while _current_song_index < _current_playlist.play_order.size() - 1:
		_current_song_index += 1
		if _load_current_song():
			return true
	return false

func start_playlist_by_index(index: int):
	var playlist = get_playlist(index)
	if playlist != null:
		start_playlist(playlist)

func next_song() -> bool:
	if not _playlist_mode or _current_playlist == null:
		return false
	
	# Loop to find the next valid song (skip songs without layouts)
	while true:
		_current_song_index += 1
		
		if _current_song_index >= _current_playlist.play_order.size():
			# Playlist finished
			if _current_playlist.is_repeat:
				# Restart playlist (with new shuffle if enabled)
				_current_song_index = -1  # Will be incremented to 0 on next iteration
				_current_playlist.generate_play_order()
				continue
			else:
				# End playlist mode
				emit_signal("playlist_completed")
				end_playlist()
				return false
		
		# Try to load this song
		if _load_current_song():
			return true
		# Song was invalid (no layout), continue to next
	
	# Unreachable, but required for GDScript static analysis
	return false

func skip_to_song(index: int) -> bool:
	if not _playlist_mode or _current_playlist == null:
		return false
	if index < 0 or index >= _current_playlist.play_order.size():
		return false
	
	_current_song_index = index
	return _load_current_song()

func end_playlist():
	_playlist_mode = false
	_current_playlist = null
	_current_song_index = 0
	_playlist_time_tracking = false

func _load_current_song() -> bool:
	var song = get_current_song()
	if song == null:
		push_error("PlaylistManager: No current song to load")
		return false
	
	# Always set game variables (even if empty - so we don't use stale data)
	GameVariables.path = song.layout_path
	GameVariables.difficulty = song.difficulty
	
	# Check if song has a valid layout
	if song.layout_path == "":
		push_warning("PlaylistManager: Song has no layout, skipping: " + song.name)
		return false
	
	print("PlaylistManager: Loading song ", _current_song_index + 1, "/", get_total_songs_in_playlist(), ": ", song.name)
	emit_signal("playlist_song_changed", _current_song_index, song)
	return true

# For previewing a song from a playlist without starting playlist mode
func preview_song_from_playlist(playlist: PlaylistData, song_index: int) -> SongEntry:
	if playlist == null or song_index < 0 or song_index >= playlist.entries.size():
		return null
	return playlist.entries[song_index]

# Reload playlists from disk
func reload_playlists():
	_load_playlists()
