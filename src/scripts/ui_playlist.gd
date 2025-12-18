extends VBoxContainer

# View modes for the playlist UI
enum ViewMode { PLAYLISTS, SONGS }

@onready var playlist_items = $ListContainer/PlaylistItems
@onready var scroll_up_btn = $ListContainer/ScrollUpBtn
@onready var scroll_down_btn = $ListContainer/ScrollDownBtn
@onready var play_button = $PlayButton
@onready var playlist_label = $HeaderContainer/PlaylistLabel
@onready var back_button = $HeaderContainer/BackButton

var _current_view_mode: ViewMode = ViewMode.PLAYLISTS
var _selected_playlist_index: int = -1
var _selected_playlist = null  # PlaylistData for songs view
var _selected_song_index: int = -1
var _beatplayer = null

func _get_beatplayer():
	if _beatplayer == null:
		var manager = Global.manager()
		if manager:
			_beatplayer = manager._beatplayer
	return _beatplayer

func _ready():
	# Connect button signals using button_down for VR raycast compatibility
	if scroll_up_btn and not scroll_up_btn.button_down.is_connected(_on_scroll_up_pressed):
		scroll_up_btn.button_down.connect(_on_scroll_up_pressed)
	if scroll_down_btn and not scroll_down_btn.button_down.is_connected(_on_scroll_down_pressed):
		scroll_down_btn.button_down.connect(_on_scroll_down_pressed)
	if play_button and not play_button.button_down.is_connected(_on_play_pressed):
		play_button.button_down.connect(_on_play_pressed)
	if back_button and not back_button.button_down.is_connected(_on_back_pressed):
		back_button.button_down.connect(_on_back_pressed)
	if playlist_items:
		if not playlist_items.item_selected.is_connected(_on_item_selected):
			playlist_items.item_selected.connect(_on_item_selected)
		# Connect double-click for entering playlist or navigating to song
		if not playlist_items.item_activated.is_connected(_on_item_activated):
			playlist_items.item_activated.connect(_on_item_activated)
	
	# Connect to scroll changes for button visibility
	if playlist_items:
		var v_scroll = playlist_items.get_v_scroll_bar()
		if v_scroll and not v_scroll.is_connected("value_changed", _on_scroll_changed):
			v_scroll.connect("value_changed", _on_scroll_changed)
	
	# Start in playlists view
	_show_playlists_view()


func _show_playlists_view():
	"""Switch to showing list of playlists"""
	_current_view_mode = ViewMode.PLAYLISTS
	_selected_playlist = null
	_selected_song_index = -1
	
	# Update UI
	if playlist_label:
		playlist_label.text = "PLAYLISTS"
	if back_button:
		back_button.visible = false
	
	_populate_playlists()
	_update_play_button()


func _show_songs_view(playlist):
	"""Switch to showing songs in a specific playlist"""
	if playlist == null:
		return
	
	_current_view_mode = ViewMode.SONGS
	_selected_playlist = playlist
	_selected_song_index = -1
	
	# Update UI
	if playlist_label:
		playlist_label.text = playlist.name
	if back_button:
		back_button.visible = true
	
	_populate_songs()
	_update_play_button()


func _populate_playlists():
	if not playlist_items:
		return
	
	playlist_items.clear()
	
	var playlists = PlaylistManager.get_playlists()
	
	if playlists.size() == 0:
		playlist_items.add_item("No playlists found")
		playlist_items.set_item_disabled(0, true)
		return
	
	for playlist in playlists:
		var song_count = playlist.entries.size()
		var display_text = playlist.name + " (" + str(song_count) + " songs)"
		
		# Add shuffle indicator
		if playlist.is_shuffle:
			display_text += " [Shuffle]"
		
		playlist_items.add_item(display_text)
	
	# Update scroll button visibility
	call_deferred("_update_scroll_button_visibility")


func _populate_songs():
	"""Populate the list with songs from the selected playlist"""
	if not playlist_items or _selected_playlist == null:
		return
	
	playlist_items.clear()
	
	if _selected_playlist.entries.size() == 0:
		playlist_items.add_item("No songs in playlist")
		playlist_items.set_item_disabled(0, true)
		return
	
	for i in range(_selected_playlist.entries.size()):
		var song = _selected_playlist.entries[i]
		var display_text = str(i + 1) + ". " + song.name
		
		# Add difficulty indicator
		if song.difficulty != "":
			display_text += " [" + song.difficulty + "]"
		
		playlist_items.add_item(display_text)
		
		# Disable songs without layout
		if song.layout_path == "":
			playlist_items.set_item_disabled(i, true)
			playlist_items.set_item_custom_fg_color(i, Color(0.5, 0.5, 0.5))
			playlist_items.set_item_tooltip(i, "No layout available")
	
	# Update scroll button visibility
	call_deferred("_update_scroll_button_visibility")


func _on_back_pressed():
	"""Return to playlists view"""
	if _current_view_mode == ViewMode.SONGS:
		_show_playlists_view()


func _on_scroll_up_pressed():
	if not playlist_items:
		return
	
	var v_scroll = playlist_items.get_v_scroll_bar()
	if not v_scroll:
		return
	
	var page_size = playlist_items.size.y
	var new_value = max(0, v_scroll.value - page_size)
	v_scroll.value = new_value
	_update_scroll_button_visibility()


func _on_scroll_down_pressed():
	if not playlist_items:
		return
	
	var v_scroll = playlist_items.get_v_scroll_bar()
	if not v_scroll:
		return
	
	var page_size = playlist_items.size.y
	var max_scroll = v_scroll.max_value - v_scroll.page
	var new_value = min(max_scroll, v_scroll.value + page_size)
	v_scroll.value = new_value
	_update_scroll_button_visibility()


func _on_scroll_changed(_value: float):
	_update_scroll_button_visibility()


func _update_scroll_button_visibility():
	if not playlist_items:
		return
	
	var v_scroll = playlist_items.get_v_scroll_bar()
	if not v_scroll:
		if scroll_up_btn:
			scroll_up_btn.visible = false
		if scroll_down_btn:
			scroll_down_btn.visible = false
		return
	
	var content_exceeds_view = v_scroll.max_value > v_scroll.page
	
	if not content_exceeds_view:
		if scroll_up_btn:
			scroll_up_btn.visible = false
		if scroll_down_btn:
			scroll_down_btn.visible = false
		return
	
	if scroll_up_btn:
		scroll_up_btn.visible = v_scroll.value > 0
	
	if scroll_down_btn:
		var max_scroll = v_scroll.max_value - v_scroll.page
		scroll_down_btn.visible = v_scroll.value < max_scroll


func _on_play_pressed():
	"""Handle play button press - behavior depends on view mode"""
	if _current_view_mode == ViewMode.PLAYLISTS:
		# In playlists view, enter the selected playlist
		if _selected_playlist_index >= 0:
			var playlist = PlaylistManager.get_playlist(_selected_playlist_index)
			if playlist:
				_show_songs_view(playlist)
	else:
		# In songs view, start the playlist
		if _selected_playlist == null or _selected_playlist.entries.size() == 0:
			push_warning("Playlist has no songs")
			return
		
		# Start playlist mode and load game
		if not PlaylistManager.start_playlist(_selected_playlist):
			push_warning("Playlist has no valid songs (all missing layouts)")
			return
		
		# Load the game scene
		Global.manager().load_scene(Global.manager().game_path, "game")


func _on_item_selected(index: int):
	"""Handle single click on item"""
	if playlist_items.get_item_count() <= 0:
		return
	
	if _current_view_mode == ViewMode.PLAYLISTS:
		if index < 0 or index >= PlaylistManager.get_playlist_count():
			return
		
		_selected_playlist_index = index
		_update_play_button()
		
		# Preview first song in playlist
		var playlist = PlaylistManager.get_playlist(index)
		if playlist and playlist.entries.size() > 0:
			_preview_playlist_song(playlist, 0)
	else:
		# Songs view
		if _selected_playlist == null:
			return
		if index < 0 or index >= _selected_playlist.entries.size():
			return
		
		# Check if song is disabled (no layout)
		var song = _selected_playlist.entries[index]
		if song.layout_path == "":
			return
		
		_selected_song_index = index
		_update_play_button()
		
		# Preview the selected song
		_preview_playlist_song(_selected_playlist, index)


func _on_item_activated(index: int):
	"""Handle double-click on item"""
	if _current_view_mode == ViewMode.PLAYLISTS:
		# Double-click on playlist: enter songs view
		if index >= 0 and index < PlaylistManager.get_playlist_count():
			var playlist = PlaylistManager.get_playlist(index)
			if playlist:
				_show_songs_view(playlist)
	else:
		# Double-click on song: navigate to it in the song list
		if _selected_playlist and index >= 0 and index < _selected_playlist.entries.size():
			var song = _selected_playlist.entries[index]
			if song.layout_path != "":
				navigate_to_song(index)


func _preview_playlist_song(playlist, song_index: int):
	if song_index < 0 or song_index >= playlist.entries.size():
		return
	
	var song = playlist.entries[song_index]
	if song.music_path == "":
		push_warning("No music file found for: " + song.name)
		return
	
	# Play preview audio
	var audio_loader = AudioLoader.new()
	var beatplayer = _get_beatplayer()
	if beatplayer:
		beatplayer.stop_music()
		var stream = audio_loader.loadfile(song.music_path, false)
		if stream:
			beatplayer.stream = stream
			# Try to get BPM from layout if available
			if song.layout_path != "":
				var map = MapFactory.create_map(song.layout_path)
				if map:
					beatplayer.bpm = map.get_bpm()
			beatplayer.play_music()
		else:
			push_warning("Failed to load audio file: " + song.music_path)


func _update_play_button():
	if not play_button:
		return
	
	if _current_view_mode == ViewMode.PLAYLISTS:
		if _selected_playlist_index < 0:
			play_button.disabled = true
			play_button.text = "Select Playlist"
		else:
			var playlist = PlaylistManager.get_playlist(_selected_playlist_index)
			if playlist and playlist.entries.size() > 0:
				play_button.disabled = false
				play_button.text = "View Songs"
			else:
				play_button.disabled = true
				play_button.text = "No Songs"
	else:
		# Songs view
		if _selected_playlist and _selected_playlist.entries.size() > 0:
			play_button.disabled = false
			play_button.text = "Play Playlist"
		else:
			play_button.disabled = true
			play_button.text = "No Songs"


# Get the songs for the currently selected playlist
func get_selected_playlist_songs() -> Array:
	if _selected_playlist == null:
		return []
	return _selected_playlist.entries


# Navigate to song list and select a specific song
func navigate_to_song(song_index: int):
	if _selected_playlist == null:
		return
	if song_index < 0 or song_index >= _selected_playlist.entries.size():
		return
	
	var song = _selected_playlist.entries[song_index]
	
	# Set game variables to navigate to this song in the song list
	if song.layout_path != "":
		GameVariables.path = song.layout_path
		GameVariables.difficulty = song.difficulty
	
	# Find the song list UI and select the song
	# Look for MainMenu node to access the song list
	var main_menu = get_tree().root.get_node_or_null("GameManager/ScenesHolder/MainMenu")
	if main_menu == null:
		# Alternative path
		main_menu = get_tree().get_first_node_in_group("main_menu")
	
	if main_menu:
		# Find the UI_SongList in UICanvasInteract2
		var song_list_canvas = main_menu.get_node_or_null("UICanvasInteract2")
		if song_list_canvas:
			# Get the SubViewport's child (the actual UI_SongList control)
			var subviewport = song_list_canvas.get_node_or_null("SubViewport")
			if subviewport and subviewport.get_child_count() > 0:
				var song_list_ui = subviewport.get_child(0)
				if song_list_ui and song_list_ui.has_method("select_song_by_path"):
					song_list_ui.select_song_by_path(song.layout_path)
				elif song_list_ui:
					# Fallback: just set game variables and let user see the song list
					print("Song list found but select_song_by_path not available")
	
	print("Navigate to song: ", song.name, " at ", song.layout_path)


# Get current view mode
func get_view_mode() -> ViewMode:
	return _current_view_mode
