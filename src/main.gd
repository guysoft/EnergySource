extends Node


# References
onready var _player = $Player
onready var _left_hand = $Player/ARVROrigin/LeftHand
onready var _right_hand = $Player/ARVROrigin/RightHand

func _ready():
	if GameVariables.ENABLE_VR:
		_init_vr()
	else:
		print("No VR")
		_left_hand.queue_free()
		_right_hand.queue_free()

func _init_vr() -> ARVRInterface:
	print("Starting vr")
	# pass
	var arvr_interface = ARVRServer.find_interface("OpenXR")
	if arvr_interface and arvr_interface.initialize():
		print("Yes VR")
		get_viewport().arvr = true
		get_viewport().hdr = false
		get_viewport().keep_3d_linear = true
		GameVariables.vr_enabled = true
	else:
		print("Failed to start VR")
	return arvr_interface



