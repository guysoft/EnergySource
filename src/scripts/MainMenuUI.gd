extends MarginContainer

export(NodePath) var start_button
export(NodePath) var quit_button
export(String) var start_scene

var start_pressed := false
var quit_pressed := false

func _ready():
	start_pressed = false
	if start_button:
		print (start_button)
		start_button = get_node(start_button)
	if quit_button:
		print (quit_button)
		quit_button = get_node(quit_button)
	
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


