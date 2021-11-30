extends Spatial

export(Environment) var environment:Environment
export(AudioStream) var music:AudioStream

onready var _beat_player = Global.manager()._beatplayer
onready var _player = Global.manager()._player
onready var _environment_manager = Global.manager()._environment_manager

func _ready():
	$AudioStreamPlayer.play()
	_environment_manager.change_environment(environment)
	if _beat_player and music:
		_beat_player.stream = music
		_beat_player.play()
		#_environment.start_strobe(_music.bpm/2)
