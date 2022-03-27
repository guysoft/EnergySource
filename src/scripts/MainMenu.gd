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
	
	
func remove_children(node):
	for n in node.get_children():
		node.remove_child(n)
		n.queue_free()


func switch_weapon(index):
	print("Switching wapon")
	
	if GameVariables.ENABLE_VR:
		var left_weapon = MeshInstance.new()
		left_weapon.mesh = CubeMesh.new()
		left_weapon.global_scale(Vector3(0.1, 0.1, 0.1))
		
		var right_weapon = MeshInstance.new()
		right_weapon.mesh = CubeMesh.new()
		right_weapon.global_scale(Vector3(0.1, 0.1, 0.1))
		
		
		var left_controller_node = _player.get_node("ARVROrigin/LeftHand/Position3D/Weapon")
		var right_controller_node = _player.get_node("ARVROrigin/RightHand/Position3D/Weapon")
		
		remove_children(left_controller_node)
		left_weapon.to_global(left_controller_node.global_transform.origin)
		left_controller_node.add_child(left_weapon)
		
		remove_children(right_controller_node)
		right_weapon.to_global(right_controller_node.global_transform.origin)
		right_controller_node.add_child(right_weapon)
		
		
