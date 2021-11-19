extends Node

var enable_vr = true;

# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	if GameVariables.ENABLE_VR:
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
	else:
		print("No VR")
		$Player/ARVROrigin/LeftHand.free()
		$Player/ARVROrigin/RightHand.free()
		




	


