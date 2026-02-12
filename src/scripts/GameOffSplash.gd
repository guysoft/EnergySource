extends Node3D

#export(String) var next:String = ""
@export var length: float = 1.0
#export(String) var next #next scene to load
@export var environment: Environment

@onready var _manager = Global.manager()
@onready var _environment = Global.manager()._environment_manager

func _ready() -> void:
	if environment:
		_environment.change_environment(environment)
	await get_tree().create_timer(1).timeout
	if _manager.webxr_interface:
		_manager.begin_webxr()
	$AudioStreamPlayer.pitch_scale = 8.5/length
	$AudioStreamPlayer.play()
	$AnimationPlayer.set_speed_scale(1.0/length)
	$AnimationPlayer.play("fade")
	await $AnimationPlayer.animation_finished
	await get_tree().create_timer(1).timeout
	_manager.load_scene(_manager.menu_path, "menu")
