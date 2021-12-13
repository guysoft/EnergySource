extends MarginContainer

export(NodePath) var start_button
export(NodePath) var quit_button
export(String) var start_scene

var start_pressed := false
var quit_pressed := false

onready var songs_list = []

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

func _ready():
	start_pressed = false
	if start_button:
		print (start_button)
		start_button = get_node(start_button)
	if quit_button:
		print (quit_button)
		quit_button = get_node(quit_button)
		
	# Populate Item List
	for item in list_files_in_directory(GameVariables.songs_path):
		songs_list.append(item)
	songs_list.sort()

	var icon = load("res://icon.png")
	var songs_list_ui = $VBoxContainer2/ScrollContainer/SongList

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
	
	start_button.connect("pressed", self, "_on_start_button_pressed")
	quit_button.connect("pressed", self, "_on_quit_button_pressed")

func _input(event):
	if Input.is_key_pressed(KEY_ENTER):
		_on_start_button_pressed()
	if Input.is_key_pressed(KEY_ESCAPE):
		_on_quit_button_pressed()
#		if event is InputEventKey:
#			print ("test2")
#			if event.action=="ui_accept" and event.pressed:
#				_on_start_button_pressed()
#			if event.action=="ui_cancel" and event.pressed:
#				_on_quit_button_pressed()


func _on_start_button_pressed():
	if start_pressed:
		return
	$AcceptSound.play()
	start_pressed = true
	Global.manager().load_scene(Global.manager().game_path,"game")

func _on_quit_button_pressed():
	$BackSound.play()
	var animation = Global.manager()._transition.get_node("AnimationPlayer") as AnimationPlayer
	animation.play("fade")
	yield(animation,"animation_finished")
	get_tree().quit()


func _on_SongList_item_selected(index):
	GameVariables.song_selected = index
	var selected_song = songs_list[index]
	GameVariables.path = GameVariables.songs_path + "/" + selected_song
	var map = Map.new(GameVariables.path)
	
	var audio_loader = AudioLoader.new()
	$BackSound.stream = audio_loader.loadfile(map.get_song())
	$BackSound.play()
