extends Node3D

@export var environment: Environment
@export var music: AudioStream
@export var start_delay = 1.0

@onready var _beat_player = Global.manager()._beatplayer
@onready var _player = Global.manager()._player
@onready var _environment_manager = Global.manager()._environment_manager

func _ready():
	#$AudioStreamPlayer.play()
	_environment_manager.change_environment(environment)
	
	#start_delay = $AudioStreamPlayer.stream.get_length()
	#yield(get_tree().create_timer(start_delay), "timeout")
	if _beat_player and music:
		_beat_player.stream = music
		_beat_player.play_music()
		#_environment.start_strobe(_music.bpm/2)
	
	_player.in_game=false
	_player.game_node=null
