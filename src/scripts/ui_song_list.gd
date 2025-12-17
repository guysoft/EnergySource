extends ScrollContainer

@export var tab:String # (String, "Original", "Custom", "PowerBeatsVR")

# Item types for tracking what each list entry represents
enum ItemType { FOLDER, PARENT_DIR, MUSIC_FILE, BEATSABER_SONG }

@onready var songs_list = []
# Store full paths for each song to handle different formats
@onready var songs_paths = []
# Store item types to handle selection differently
@onready var item_types = []
# Track which items are disabled (no layout)
@onready var disabled_items = []

var _beatplayer = null

func _get_beatplayer():
	if _beatplayer == null:
		var manager = Global.manager()
		if manager:
			_beatplayer = manager._beatplayer
	return _beatplayer

var songs_list_ui
var no_songs_label
var path_label = null
var scroll_up_btn = null
var scroll_down_btn = null

var path = ""

# Folder navigation state for PowerBeatsVR music browser
var current_music_folder: String = ""  # Relative to pbvr_music_path

# Music file extensions
const MUSIC_EXTENSIONS = ["ogg", "mp3", "wav"]

# Grey color for disabled items
const DISABLED_COLOR = Color(0.5, 0.5, 0.5)


func _ready():
	populate_list()


func populate_list():
	# Clear previous data
	songs_list.clear()
	songs_paths.clear()
	item_types.clear()
	disabled_items.clear()
	
	# Get UI nodes based on tab structure
	_setup_ui_nodes()
	
	if tab == "Original":
		# Populate Item List with internal levels (Beat Saber format)
		path = GameVariables.internal_songs_path
		_add_beatsaber_songs(path)
		_populate_beatsaber_ui()
	elif tab == "Custom":
		# Custom tab uses PowerBeatsVR music folder browser
		_populate_powerbeatsvr_browser()
	elif tab == "PowerBeatsVR":
		# Dedicated PowerBeatsVR tab - also uses music folder browser
		_populate_powerbeatsvr_browser()


func _setup_ui_nodes():
	"""Setup UI node references based on tab type"""
	if tab == "Custom":
		# Custom tab has VBoxContainer structure with PathLabel
		songs_list_ui = $VBoxContainer/ListContainer/SongList
		no_songs_label = $VBoxContainer/NoSongsLabel
		path_label = $VBoxContainer/HBoxContainer/PathLabel
		scroll_up_btn = $VBoxContainer/ListContainer/ScrollUpBtn
		scroll_down_btn = $VBoxContainer/ListContainer/ScrollDownBtn
	else:
		# Original tab has HBoxContainer structure
		songs_list_ui = $HBoxContainer/ListContainer/SongList
		no_songs_label = $HBoxContainer/NoSongsLabel
		path_label = null
		scroll_up_btn = $HBoxContainer/ListContainer/ScrollUpBtn
		scroll_down_btn = $HBoxContainer/ListContainer/ScrollDownBtn
	
	# Connect to scroll changes to update button visibility
	if songs_list_ui:
		var v_scroll = songs_list_ui.get_v_scroll_bar()
		if v_scroll and not v_scroll.is_connected("value_changed", _on_scroll_changed):
			v_scroll.connect("value_changed", _on_scroll_changed)


func _populate_beatsaber_ui():
	"""Populate UI for Beat Saber format songs"""
	var icon = preload("res://icon.png")
	
	songs_list_ui.clear()
	
	for i in range(songs_list.size()):
		var item = songs_list[i]
		var item_path = songs_paths[i]
		
		# Use MapFactory to load Beat Saber maps (they need info.dat parsing)
		var map = MapFactory.create_map(item_path)
		if not map:
			push_warning("Failed to load map: " + item_path)
			continue
		
		var song_name = map.get_name()
		var cover_name = map.get_cover_name()
		
		# Try to load cover image (Beat Saber format has covers)
		if cover_name != "":
			var cover = item_path + "/" + cover_name
			if FileAccess.file_exists(cover):
				var image = Image.new()
				var _err = image.load(cover)
				image.resize(128, 128)
				icon = ImageTexture.create_from_image(image)
		
		var index = songs_list_ui.get_item_count()
		
		if song_name == "":
			songs_list_ui.add_item(item, icon)
		else:
			songs_list_ui.add_item(song_name, icon)
			songs_list_ui.set_item_tooltip_enabled(index, false)
	
	_finalize_list_ui()


func _populate_powerbeatsvr_browser():
	"""Populate UI for PowerBeatsVR music folder browser"""
	songs_list_ui.clear()
	
	var music_root = GameVariables.pbvr_music_path
	if music_root == "":
		_show_no_songs()
		return
	
	var current_path = music_root
	if current_music_folder != "":
		current_path = music_root + "/" + current_music_folder
	
	# Update path label
	if path_label:
		if current_music_folder == "":
			path_label.text = "/"
		else:
			path_label.text = "/" + current_music_folder
	
	# Check if directory exists
	if not DirAccess.dir_exists_absolute(current_path):
		_show_no_songs()
		return
	
	# Add ".." entry if not at root
	if current_music_folder != "":
		songs_list.append("..")
		songs_paths.append("")
		item_types.append(ItemType.PARENT_DIR)
		disabled_items.append(false)
		songs_list_ui.add_item("[..]", null)
	
	# List directory contents
	var items = list_files_in_directory(current_path)
	
	# First add folders
	for item in items:
		var item_path = current_path + "/" + item
		if DirAccess.dir_exists_absolute(item_path):
			songs_list.append(item)
			songs_paths.append(item_path)
			item_types.append(ItemType.FOLDER)
			disabled_items.append(false)
			songs_list_ui.add_item("[DIR] " + item, null)
	
	# Then add music files
	for item in items:
		var item_path = current_path + "/" + item
		if _is_music_file(item):
			var has_layout = _has_matching_layout(item)
			songs_list.append(item)
			songs_paths.append(item_path)
			item_types.append(ItemType.MUSIC_FILE)
			disabled_items.append(not has_layout)
			
			# Add to UI
			var display_name = item.get_basename()  # Remove extension for display
			var index = songs_list_ui.get_item_count()
			songs_list_ui.add_item(display_name, null)
			
			# Grey out if no layout
			if not has_layout:
				songs_list_ui.set_item_custom_fg_color(index, DISABLED_COLOR)
				songs_list_ui.set_item_tooltip(index, "No layout available")
				songs_list_ui.set_item_selectable(index, false)
	
	_finalize_list_ui()


func _show_no_songs():
	"""Show the 'no songs' message"""
	songs_list_ui.visible = false
	no_songs_label.visible = true


func _finalize_list_ui():
	"""Finalize the list UI after populating"""
	# If there are no songs, display the no songs label
	if songs_list_ui.get_item_count() == 0:
		_show_no_songs()
		# Hide scroll buttons when no songs
		if scroll_up_btn:
			scroll_up_btn.visible = false
		if scroll_down_btn:
			scroll_down_btn.visible = false
		return
	
	songs_list_ui.visible = true
	no_songs_label.visible = false
	
	# Update scroll button visibility after list is populated
	# Use call_deferred to ensure UI has been laid out
	call_deferred("_update_scroll_button_visibility")
	
	# For PowerBeatsVR browser, don't auto-select
	if tab in ["Custom", "PowerBeatsVR"]:
		# Find first selectable item
		for i in range(songs_list_ui.get_item_count()):
			if i < disabled_items.size() and not disabled_items[i]:
				if i < item_types.size() and item_types[i] == ItemType.MUSIC_FILE:
					songs_list_ui.select(i)
					songs_list_ui.ensure_current_is_visible()
					_on_SongList_item_selected(i)
					return
		return
	
	# Original Beat Saber behavior
	if GameVariables.song_selected == null:
		songs_list_ui.select(0)
		GameVariables.song_selected = 0
	else:
		# Make sure selected index is valid
		if GameVariables.song_selected >= songs_list_ui.get_item_count():
			GameVariables.song_selected = 0
		songs_list_ui.select(GameVariables.song_selected)
	
	songs_list_ui.ensure_current_is_visible()
	_on_SongList_item_selected(GameVariables.song_selected)


func _add_beatsaber_songs(search_path: String):
	"""Add Beat Saber format songs (folders with info.dat)"""
	if search_path == "":
		return
	
	var files = list_files_in_directory(search_path)
	if files:
		for item in files:
			var item_path = search_path + "/" + item
			# Check if it's a Beat Saber level (folder with info.dat)
			if DirAccess.dir_exists_absolute(item_path):
				if FileAccess.file_exists(item_path + "/info.dat") or FileAccess.file_exists(item_path + "/Info.dat"):
					songs_list.append(item)
					songs_paths.append(item_path)
					item_types.append(ItemType.BEATSABER_SONG)
					disabled_items.append(false)


func _is_music_file(filename: String) -> bool:
	"""Check if a filename is a music file"""
	var ext = filename.get_extension().to_lower()
	return ext in MUSIC_EXTENSIONS


func _has_matching_layout(music_filename: String) -> bool:
	"""Check if a music file has a matching JSON layout in the Layouts folder"""
	var base_name = music_filename.get_basename()  # "song.ogg" -> "song"
	var json_path = GameVariables.pbvr_layouts_path + "/" + base_name + ".json"
	return FileAccess.file_exists(json_path)


func _get_layout_path(music_filename: String) -> String:
	"""Get the JSON layout path for a music file"""
	var base_name = music_filename.get_basename()
	return GameVariables.pbvr_layouts_path + "/" + base_name + ".json"


func list_files_in_directory(dir_path):
	var files = []
	var dir = DirAccess.open(dir_path)
	if dir:
		dir.list_dir_begin()

		while true:
			var file = dir.get_next()
			if file == "":
				break
			elif not file.begins_with("."):
				files.append(file)
	
		dir.list_dir_end()
		files.sort()
		return files
	return []


func _on_SongList_item_selected(index):
	if songs_list_ui.get_item_count() <= 0:
		return
	if index < 0 or index >= songs_list.size():
		return
	
	# Ensure the selected item is visible and update scroll buttons
	songs_list_ui.ensure_current_is_visible()
	call_deferred("_update_scroll_button_visibility")
	
	# Check item type for PowerBeatsVR browser
	if index < item_types.size():
		var item_type = item_types[index]
		
		match item_type:
			ItemType.PARENT_DIR:
				# Navigate up
				_navigate_up()
				return
			ItemType.FOLDER:
				# Navigate into folder
				_navigate_into(songs_list[index])
				return
			ItemType.MUSIC_FILE:
				# Check if disabled
				if index < disabled_items.size() and disabled_items[index]:
					return  # Can't select disabled items
				# Select PowerBeatsVR song
				_select_powerbeatsvr_song(index)
				return
			ItemType.BEATSABER_SONG:
				# Fall through to Beat Saber handling
				pass
	
	# Beat Saber song selection (Original tab or fallback)
	GameVariables.song_selected = index
	var selected_path = songs_paths[index]
	GameVariables.path = selected_path
	
	# Use MapFactory to create the appropriate loader
	var map = MapFactory.create_map(selected_path)
	if not map:
		push_error("Failed to load map: " + selected_path)
		return
	
	# Set the first available difficulty for this map
	var difficulties = map.get_available_difficulties()
	if difficulties.size() > 0:
		GameVariables.difficulty = difficulties[0]
	
	var audio_loader = AudioLoader.new()
	var beatplayer = _get_beatplayer()
	if beatplayer:
		beatplayer.stop_music()
		var song_path = map.get_song()
		if song_path != "":
			var stream = audio_loader.loadfile(song_path, false)
			if stream:
				beatplayer.stream = stream
				beatplayer.bpm = map.get_bpm()
				beatplayer.play_music()
			else:
				push_warning("Failed to load audio file: " + song_path)
		else:
			push_warning("No audio file found for: " + selected_path)


func _navigate_up():
	"""Navigate to parent folder"""
	if current_music_folder == "":
		return  # Already at root
	
	# Go up one level
	var parts = current_music_folder.split("/")
	parts.remove_at(parts.size() - 1)
	current_music_folder = "/".join(parts)
	
	populate_list()


func _navigate_into(folder_name: String):
	"""Navigate into a subfolder"""
	if current_music_folder == "":
		current_music_folder = folder_name
	else:
		current_music_folder = current_music_folder + "/" + folder_name
	
	populate_list()


func _select_powerbeatsvr_song(index: int):
	"""Select a PowerBeatsVR song from the music browser"""
	var music_filename = songs_list[index]
	var music_path = songs_paths[index]
	var layout_path = _get_layout_path(music_filename)
	
	# Set game variables to use the layout path
	GameVariables.song_selected = index
	GameVariables.path = layout_path
	
	# Use MapFactory to load the layout
	var map = MapFactory.create_map(layout_path)
	if not map:
		push_error("Failed to load map: " + layout_path)
		return
	
	# Set the first available difficulty for this map
	var difficulties = map.get_available_difficulties()
	if difficulties.size() > 0:
		GameVariables.difficulty = difficulties[0]
	
	# Play preview audio
	var audio_loader = AudioLoader.new()
	var beatplayer = _get_beatplayer()
	if beatplayer:
		beatplayer.stop_music()
		# Use the actual music file path we browsed to
		var stream = audio_loader.loadfile(music_path, false)
		if stream:
			beatplayer.stream = stream
			beatplayer.bpm = map.get_bpm()
			beatplayer.play_music()
		else:
			push_warning("Failed to load audio file: " + music_path)


func _on_visibility_changed():
	pass
	#if not visible:
		#songs_list_ui.unselect_all()


func _on_scroll_up_pressed():
	"""Scroll the list up by one page"""
	if not songs_list_ui:
		return
	
	var v_scroll = songs_list_ui.get_v_scroll_bar()
	if not v_scroll:
		return
	
	# Calculate page size based on visible area
	var page_size = songs_list_ui.size.y
	var new_value = max(0, v_scroll.value - page_size)
	v_scroll.value = new_value
	_update_scroll_button_visibility()


func _on_scroll_down_pressed():
	"""Scroll the list down by one page"""
	if not songs_list_ui:
		return
	
	var v_scroll = songs_list_ui.get_v_scroll_bar()
	if not v_scroll:
		return
	
	# Calculate page size based on visible area
	var page_size = songs_list_ui.size.y
	var max_scroll = v_scroll.max_value - v_scroll.page
	var new_value = min(max_scroll, v_scroll.value + page_size)
	v_scroll.value = new_value
	_update_scroll_button_visibility()


func _on_scroll_changed(_value: float):
	"""Called when scroll position changes"""
	_update_scroll_button_visibility()


func _update_scroll_button_visibility():
	"""Update visibility of scroll buttons based on scroll position"""
	if not songs_list_ui:
		return
	
	var v_scroll = songs_list_ui.get_v_scroll_bar()
	if not v_scroll:
		# No scrollbar means content fits, hide both buttons
		if scroll_up_btn:
			scroll_up_btn.visible = false
		if scroll_down_btn:
			scroll_down_btn.visible = false
		return
	
	# Check if scrollbar is actually needed (content exceeds visible area)
	var content_exceeds_view = v_scroll.max_value > v_scroll.page
	
	if not content_exceeds_view:
		# Content fits in view, hide both buttons
		if scroll_up_btn:
			scroll_up_btn.visible = false
		if scroll_down_btn:
			scroll_down_btn.visible = false
		return
	
	# Show up button if we can scroll up (not at top)
	if scroll_up_btn:
		scroll_up_btn.visible = v_scroll.value > 0
	
	# Show down button if we can scroll down (not at bottom)
	if scroll_down_btn:
		var max_scroll = v_scroll.max_value - v_scroll.page
		scroll_down_btn.visible = v_scroll.value < max_scroll
