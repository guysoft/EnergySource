extends Node

class_name BeatResponder

export(bool) var disabled:=false
export(float) var response_frequency = 1.0
export(NodePath) onready var beat_player = get_node(beat_player) as BeatPlayer

var last_beat = 0 

func _ready():
	if beat_player:
		beat_player.connect("beat",self,"_on_beat_detected")


func _on_beat_detected(beat):
	if beat>=last_beat + response_frequency:
		print (beat, " beat response!")
		last_beat = beat
