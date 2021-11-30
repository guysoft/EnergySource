extends MarginContainer

export(NodePath) var start_button
export(NodePath) var quit_button
export(String) var start_scene

var start_pressed := false
var quit_pressed := false

func _ready():
	if start_button:
		start_button = get_node(start_button)
	if quit_button:
		quit_button = get_node(quit_button)
	
	start_button.connect("pressed", self, "_on_start_button_pressed")
	quit_button.connect("pressed", self, "_on_quit_button_pressed")

func _on_start_button_pressed():
	if start_pressed:
		return
	$AcceptSound.play()
	start_pressed = true
	Global.manager().load_scene(start_scene,"game")

func _on_quit_button_pressed():
	get_tree().current_scene.quit()
