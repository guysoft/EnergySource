extends Node

class_name BeatResponder

export(Array,ShaderMaterial) var materials = []
export(Dictionary) var params
export(float) var lerp_value = 0.5
export(bool) var disabled:=false

export(float) var response_frequency = 1.0
export(NodePath) onready var beat_player = get_node(beat_player) as BeatPlayer

var last_beat = 0 
var set_value


func _ready():
	if disabled:
		return
	if not materials:
		set_process(false)
		return
	
	if beat_player:
		beat_player.connect("beat",self,"_on_beat_detected")


func _process(delta):
	if not disabled:
		for material in materials:
			for key in params.keys():
				if material.shader.has_param(key):
					var current_value = material.get_shader_param(key)
					material.set_shader_param(key, lerp(current_value, 0, lerp_value*delta))


func _on_beat_detected(beat):
	if not disabled:
		if beat>=last_beat + response_frequency:
			for material in materials:
				for key in params.keys():
					if material.shader.has_param(key):
						print (key, " ", params[key])
						material.set_shader_param(key, params[key])
			last_beat = beat
