extends ScrollContainer

@export var tab:String # (String, "Original", "Custom")



@onready var songs_list = []

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
	
	if tab == "Original":
		# Populate Item List with internal levels
		path = GameVariables.internal_songs_path
	elif tab == "Custom":
		# Populate Item List with user levels
		path = GameVariables.custom_songs_path
	
	if not path=="":
		var files = list_files_in_directory(path)
		if files:
			for item in files:
				songs_list.append(item)
	
	songs_list_ui = $HBoxContainer/SongList
	no_songs_label = $HBoxContainer/NoSongsLabel
	
	songs_list.sort()
	songs_list_ui.clear()

	for item in songs_list:
		print("Found song in: " + item)
		var item_path = path + "/" + item
		
		var map = Map.new(item_path)
		var cover = item_path + "/" + map.get_cover_name()
		var song_name = map.get_name()
		print("song name: " + song_name)
		
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
		songs_list_ui.select(GameVariables.song_selected)
		
	_on_SongList_item_selected(GameVariables.song_selected)

func list_files_in_directory(path):
	var files = []
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin() # TODOConverter3To4 fill missing arguments https://github.com/godotengine/godot/pull/40547

		while true:
			var file = dir.get_next()
			if file == "":
				break
			elif not file.begins_with("."):
				files.append(file)
	
		dir.list_dir_end()
		return files
	return []

func _on_SongList_item_selected(index):
	if songs_list_ui.get_item_count()<=0:
		return
	GameVariables.song_selected = index
	var selected_song = songs_list[index]
	GameVariables.path = path + "/" + selected_song
	var map = Map.new(GameVariables.path)
	
	# Set the first available difficulty for this map
	var difficulties = map.get_available_difficulties()
	if difficulties.size() > 0:
		GameVariables.difficulty = difficulties[0]
		print("Selected difficulty: " + GameVariables.difficulty)
	
	var audio_loader = AudioLoader.new()
	var beatplayer = _get_beatplayer()
	if beatplayer:
		beatplayer.stop_music()
		beatplayer.stream = audio_loader.loadfile(map.get_song(), false, audio_loader.AUDIO_EXT.OGG)
		beatplayer.bpm = map.get_bpm()
		beatplayer.play_music()


func _on_visibility_changed():
	pass
	#if not visible:
		#songs_list_ui.unselect_all()
