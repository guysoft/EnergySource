extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	$TabContainer/Settings/DisableTimeWarp.button_pressed = Settings.get_setting("game", "disable_time_warp")


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_DisableTimeWarp_toggled(button_pressed):
	Settings.set_setting("game", "disable_time_warp", button_pressed)
