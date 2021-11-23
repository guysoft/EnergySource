extends Spatial

onready var path:String = "res://Levels/test/ExpertPlusStandard.dat"
onready var difficulty = "ExpertPlusStandard"

export (NodePath) var viewport = null
var interface : ARVRInterface
# References
onready var _player = $Player
onready var _left_hand = $Player/ARVROrigin/LeftHand
onready var _right_hand = $Player/ARVROrigin/RightHand
onready var _spawn_location = $SpawnLocation

#FYI if the script has a classname, you don't need to preload it in
#const Map = preload("scripts/MapLoader.gd")
onready var map = null

#Does this need be unique? Consider moving to a utility singleton
onready var _rand = RandomNumberGenerator.new()

var notescene = load("res://scenes/Note.tscn")

onready var _map = $Map

func _ready():
	if GameVariables.ENABLE_VR:
		if not initialise_VR():
			print ("failed to init VR")
	else:
		print("No VR")
		_left_hand.queue_free()
		_right_hand.queue_free()

	setup_map(path)
	$BeatPlayer.connect("beat", self, "_on_beat_detected")
	$BeatPlayer.play()

# export(PackedScene) var note_object
# export(NodePath) onready var beat_player = get_node(beat_player) as BeatPlayer

func _on_beat_detected(beat):
	var notes = map._on_beat_detected(difficulty, beat)
	for note in notes:
		
		# Spawn note
		var note_instance = notescene.instance()
		# note_instance.get_child(0).visible()
		
		_spawn_location.add_child(note_instance)
		
		# TODO calculate offset which should include the speed and bpm
		# print(note["x"], note["y"], note["offset"])
		#note_instance.transform.origin = Vector3(note["x"], note["y"], -5 - note["offset"])
		note_instance.setup_note(note)
		# note_instance.transform.origin = Vector3(-1,-1,-1)
	#	_rand.randomize()
	#
	#	var wall_size = 1
	#	note_instance.transform.origin = Vector3(
	#	_rand.randf_range(-wall_size, wall_size),
	#	_rand.randf_range(0.5, 2),
	#	- 2
	#)

		
		# add_child(note_instance)
		# note_instance.setup_note(note)
		
		note_instance.activate()

func setup_map(path:String):
	map = Map.new(path)
	map.get_notes(difficulty)

#func _init_vr() -> ARVRInterface:
#	print("Starting vr")
#	# pass
#	var arvr_interface = ARVRServer.find_interface("OpenXR")
#	if arvr_interface and arvr_interface.initialize():
#		print("Yes VR")
#		get_viewport().arvr = true
#		get_viewport().hdr = false
#		get_viewport().keep_3d_linear = true
#		GameVariables.vr_enabled = true
#	else:
#		print("Failed to start VR")
#	return arvr_interface

func initialise_VR() -> bool:
	var interface = ARVRServer.find_interface("OpenXR")
	print (interface)
	if interface and interface.initialize():
		print("OpenXR Interface initialized")

		# Connect to our plugin signals
		_connect_plugin_signals()

		var vp : Viewport = null
		if viewport:
			vp = get_node(viewport)
		else:
			vp = get_viewport()
		
		# Change our viewport so it is tied to our ARVR interface and renders to our HMD
		vp.arvr = true

		# Our interface will tell us whether we should keep our render buffer in linear color space
		# If true our preview will be darker.
		vp.keep_3d_linear = $Configuration.keep_3d_linear()

		# increase our physics engine update speed
		var refresh_rate = $Configuration.get_refresh_rate()
		if refresh_rate == 0:
			# Only Facebook Reality Labs supports this at this time
			print("No refresh rate given by XR runtime")

			# Use something sufficiently high
			Engine.iterations_per_second = 144
		else:
			print("HMD refresh rate is set to " + str(refresh_rate))

			# Match our physics to our HMD
			Engine.iterations_per_second = refresh_rate

		return true
	else:
		return false

func _connect_plugin_signals():
	ARVRServer.connect("openxr_session_begun", self, "_on_openxr_session_begun")
	ARVRServer.connect("openxr_session_ending", self, "_on_openxr_session_ending")
	ARVRServer.connect("openxr_focused_state", self, "_on_openxr_focused_state")
	ARVRServer.connect("openxr_visible_state", self, "_on_openxr_visible_state")
	ARVRServer.connect("openxr_pose_recentered", self, "_on_openxr_pose_recentered")

func _on_openxr_session_begun():
	print("OpenXR session begun")

func _on_openxr_session_ending():
	print("OpenXR session ending")

func _on_openxr_focused_state():
	print("OpenXR focused state")

func _on_openxr_visible_state():
	print("OpenXR visible state")

func _on_openxr_pose_recentered():
	print("OpenXR pose recentered")



