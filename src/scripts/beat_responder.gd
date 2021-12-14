extends Node

class_name BeatResponder

export(Array,ShaderMaterial) var materials = []
export(Dictionary) var params
export(float) var lerp_value = 0.5
export(bool) var disabled:=false
export(float) var set_value = 10.0
export(float) var response_frequency = 1.0
export(float) var min_average_freq = 0.015;

#Refs
onready var _beat_player = Global.manager()._beatplayer
onready var _bus = AudioServer.get_bus_effect_instance(0,0)


var last_beat = 0 


func _ready():
	if disabled:
		return
	if not materials:
		set_process(false)
		return
	
	if _beat_player:
		_beat_player.connect("beat",self,"_on_beat_detected")
		_beat_player.connect("reset",self,"_on_beatplayer_reset")


func _process(delta):
	if not disabled:
		for material in materials:
			for key in params.keys():
				if material.shader.has_param(key):
					var current_value = material.get_shader_param(key)
					material.set_shader_param(key, lerp(current_value, set_value, lerp_value*delta))


func _on_beat_detected(beat):
	var mag = _bus.get_magnitude_for_frequency_range(0,20000,1).length()
	print (mag)
	if not disabled and mag>min_average_freq:
		if beat>=last_beat + response_frequency:
			for material in materials:
				for key in params.keys():
					if material.shader.has_param(key):
						#print (key, " ", params[key])
						material.set_shader_param(key, params[key])
			last_beat = beat

func _on_beatplayer_reset(beat):
	last_beat=beat
