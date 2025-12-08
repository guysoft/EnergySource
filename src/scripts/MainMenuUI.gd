extends MarginContainer

@export var start_scene: String

var start_pressed := false
var quit_pressed := false

func _ready():
	start_pressed = false

func _input(event):
	if Input.is_key_pressed(KEY_ENTER):
		_on_start_button_pressed()
	if Input.is_key_pressed(KEY_ESCAPE):
		_on_quit_button_pressed()


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
	await animation.animation_finished
	get_tree().quit()
