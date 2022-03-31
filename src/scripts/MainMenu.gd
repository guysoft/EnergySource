extends Spatial

export(Environment) var environment:Environment
export(AudioStream) var music:AudioStream
export var start_delay = 1.0

onready var _beat_player = Global.manager()._beatplayer
onready var _player = Global.manager()._player
onready var _environment_manager = Global.manager()._environment_manager

func _ready():
	#$AudioStreamPlayer.play()
	_environment_manager.change_environment(environment)
	
	#start_delay = $AudioStreamPlayer.stream.get_length()
	#yield(get_tree().create_timer(start_delay), "timeout")
	if _beat_player and music:
		_beat_player.stream = music
		_beat_player.play()
		#_environment.start_strobe(_music.bpm/2)
	
	_player.in_game=false
	_player.game_node=null
	

func switch_weapon(index):
	print("Switching weapon: ", index)
	
	if GameVariables.ENABLE_VR:
		var left_weapon = GameVariables.weapons[index]
		var right_weapon = GameVariables.weapons[index]
		
		_player._left_hand.equip_weapon(left_weapon.instance())
		_player._right_hand.equip_weapon(right_weapon.instance())
		
