extends Node

class_name BeatResponder

@export var materials = [] # (Array,ShaderMaterial)
@export var params: Dictionary
@export var lerp_value: float = 0.5
@export var disabled :=false
@export var set_value: float = 10.0
@export var response_frequency: float = 1.0
@export var min_average_freq: float = 0.015;

#Refs
@onready var _beat_player = Global.manager()._beatplayer
@onready var _bus = AudioServer.get_bus_effect_instance(0,0)


var last_beat = 0 


func _ready():
	if disabled:
		return
	if not materials:
		set_process(false)
		return
	
	if _beat_player:
		_beat_player.connect("beat", Callable(self, "_on_beat_detected"))
		_beat_player.connect("reset", Callable(self, "_on_beatplayer_reset"))


func _process(delta):
	if not disabled:
		for material in materials:
			for key in params.keys():
				if material.get_shader_parameter(key) != null:
					var current_value = material.get_shader_parameter(key)
					# Godot 4: lerp requires all arguments to be same type (float)
					material.set_shader_parameter(key, lerpf(float(current_value), float(set_value), lerp_value * delta))


func _on_beat_detected(beat):
	var mag = _bus.get_magnitude_for_frequency_range(0,20000,1).length()
	print (mag)
	if not disabled and mag>min_average_freq:
		if beat>=last_beat + response_frequency:
			for material in materials:
				for key in params.keys():
					if material.get_shader_parameter(key) != null:
						#print (key, " ", params[key])
						material.set_shader_parameter(key, params[key])
			last_beat = beat

func _on_beatplayer_reset(beat):
	last_beat=beat
