extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	$TabContainer/Settings/DisableTimeWarp.pressed = Settings.get_setting("game", "disable_time_warp")


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_DisableTimeWarp_toggled(button_pressed):
	Settings.set_setting("game", "disable_time_warp", button_pressed)


func _on_WeaponList_item_selected(index):
	print ("weapon selected: ", index)
	get_parent().get_parent().get_parent().switch_weapon(index)
