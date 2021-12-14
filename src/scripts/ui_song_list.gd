extends ScrollContainer

onready var songs_list = []

onready var _beatplayer = Global.manager()._beatplayer

func _ready():
	# Populate Item List
	for item in list_files_in_directory(GameVariables.songs_path):
		songs_list.append(item)
	songs_list.sort()

	var icon = load("res://icon.png")
	var songs_list_ui = $HBoxContainer/SongList

	songs_list_ui.clear()

	for item in songs_list:
		print("Found song in: " + item)
		var item_path = GameVariables.songs_path + "/" + item
		
		var cover = item_path + "/" + "cover.jpg"
		var map = Map.new(item_path)
		var song_name = map.get_name()
		print("song name: " + song_name)
		
		var file = File.new()
		if file.file_exists(cover):
			var image = Image.new()
			var err = image.load(cover)
			image.resize(128, 128)
			icon = ImageTexture.new()
			icon.create_from_image(image, 0)
			
		if song_name == "":
			songs_list_ui.add_item(item, icon)
		else:
			songs_list_ui.add_item(song_name, icon)
	if GameVariables.song_selected == null:
		songs_list_ui.select(0)
		GameVariables.song_selected = 0
	else:
		songs_list_ui.select(GameVariables.song_selected)
		
	_on_SongList_item_selected(GameVariables.song_selected)


func list_files_in_directory(path):
	var files = []
	var dir = Directory.new()
	dir.open(path)
	dir.list_dir_begin()

	while true:
		var file = dir.get_next()
		if file == "":
			break
		elif not file.begins_with("."):
			files.append(file)

	dir.list_dir_end()

	return files

func _on_SongList_item_selected(index):
	GameVariables.song_selected = index
	var selected_song = songs_list[index]
	GameVariables.path = GameVariables.songs_path + "/" + selected_song
	var map = Map.new(GameVariables.path)
	
	var audio_loader = AudioLoader.new()
#	if not _beatplayer:
#		_beatplayer = Global.manager()._beatplayer
	if _beatplayer:
		_beatplayer.stop()
		_beatplayer.stream = audio_loader.loadfile(map.get_song())
		_beatplayer.bpm = map.get_bpm()
		_beatplayer.play()
