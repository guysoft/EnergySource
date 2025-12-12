extends ScrollContainer

@export var tab:String # (String, "Original", "Custom", "PowerBeatsVR")



@onready var songs_list = []
# Store full paths for each song to handle different formats
@onready var songs_paths = []

var _beatplayer = null

func _get_beatplayer():
	if _beatplayer == null:
		var manager = Global.manager()
		if manager:
			_beatplayer = manager._beatplayer
	return _beatplayer

var songs_list_ui
var no_songs_label

var path = ""

func _ready():
	populate_list()

func populate_list():
	#replace with custom icon
	var icon = preload("res://icon.png")
	
	# Clear previous data
	songs_list.clear()
	songs_paths.clear()
	
	if tab == "Original":
		# Populate Item List with internal levels (Beat Saber format)
		path = GameVariables.internal_songs_path
		_add_beatsaber_songs(path)
	elif tab == "Custom":
		# Populate Item List with user levels (Beat Saber format)
		path = GameVariables.custom_songs_path
		_add_beatsaber_songs(path)
		# Also add PowerBeatsVR levels to Custom tab
		_add_powerbeatsvr_songs(GameVariables.pbvr_layouts_path)
	elif tab == "PowerBeatsVR":
		# Dedicated PowerBeatsVR tab
		_add_powerbeatsvr_songs(GameVariables.pbvr_layouts_path)
	
	songs_list_ui = $HBoxContainer/SongList
	no_songs_label = $HBoxContainer/NoSongsLabel
	
	songs_list_ui.clear()

	for i in range(songs_list.size()):
		var item = songs_list[i]
		var item_path = songs_paths[i]
		
		print("Found song: " + item + " at: " + item_path)
		
		# Use MapFactory to create the appropriate loader
		var map = MapFactory.create_map(item_path)
		if not map:
			push_warning("Failed to load map: " + item_path)
			continue
		
		var song_name = map.get_name()
		var cover_name = map.get_cover_name()
		print("song name: " + song_name)
		
		# Try to load cover image (Beat Saber format has covers)
		if cover_name != "":
			var cover = item_path.get_base_dir() + "/" + cover_name
			if item_path.ends_with(".json"):
				# PowerBeatsVR - cover would be in same dir as JSON (not typically available)
				cover = item_path.get_base_dir() + "/" + cover_name
			else:
				# Beat Saber - cover is in the folder
				cover = item_path + "/" + cover_name
			
			if FileAccess.file_exists(cover):
				var image = Image.new()
				var err = image.load(cover)
				image.resize(128, 128)
				icon = ImageTexture.create_from_image(image)
		
		var index = songs_list_ui.get_item_count()
		
		if song_name == "":
			songs_list_ui.add_item(item, icon)
		else:
			songs_list_ui.add_item(song_name, icon)
			songs_list_ui.set_item_tooltip_enabled(index, false)
	
	#if there are no songs, display the no songs label
	if songs_list_ui.get_item_count()==0:
		songs_list_ui.visible=false
		no_songs_label.visible=true
		return # Added return to avoid selecting from empty list
	
	if GameVariables.song_selected == null:
		songs_list_ui.select(0)
		GameVariables.song_selected = 0
	else:
		# Make sure selected index is valid
		if GameVariables.song_selected >= songs_list_ui.get_item_count():
			GameVariables.song_selected = 0
		songs_list_ui.select(GameVariables.song_selected)
		
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


func _add_powerbeatsvr_songs(search_path: String):
	"""Add PowerBeatsVR format songs (.json files)"""
	if search_path == "":
		return
	
	var files = list_files_in_directory(search_path)
	if files:
		for item in files:
			if item.ends_with(".json"):
				var item_path = search_path + "/" + item
				songs_list.append(item.get_basename())  # Remove .json extension for display
				songs_paths.append(item_path)


func list_files_in_directory(dir_path):
	var files = []
	var dir = DirAccess.open(dir_path)
	if dir:
		dir.list_dir_begin() # TODOConverter3To4 fill missing arguments https://github.com/godotengine/godot/pull/40547

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
	if songs_list_ui.get_item_count()<=0:
		return
	if index < 0 or index >= songs_paths.size():
		return
		
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
		print("Selected difficulty: " + GameVariables.difficulty)
	
	var audio_loader = AudioLoader.new()
	var beatplayer = _get_beatplayer()
	if beatplayer:
		beatplayer.stop_music()
		var song_path = map.get_song()
		if song_path != "":
			beatplayer.stream = audio_loader.loadfile(song_path, false, audio_loader.AUDIO_EXT.OGG)
			beatplayer.bpm = map.get_bpm()
			beatplayer.play_music()
		else:
			push_warning("No audio file found for: " + selected_path)


func _on_visibility_changed():
	pass
	#if not visible:
		#songs_list_ui.unselect_all()
