extends Spatial

onready var path:String = "res://Levels/test/ExpertPlusStandard.dat"
onready var difficulty = "ExpertPlusStandard"

# References
onready var _player = $Player
onready var _left_hand = $Player/ARVROrigin/LeftHand
onready var _right_hand = $Player/ARVROrigin/RightHand

onready var map = null
const Map = preload("scripts/MapLoader.gd")
#Does this need be unique? Consider moving to a utility singleton
onready var _rand = RandomNumberGenerator.new()

var notescene = load("res://scenes/Note.tscn")

onready var _map = $Map

func _ready():
	if GameVariables.ENABLE_VR:
		_init_vr()
	else:
		print("No VR")
		_left_hand.queue_free()
		_right_hand.queue_free()
	
	$BeatPlayer.connect("beat", self, "_on_beat_detected")
	setup_map(path)

# export(PackedScene) var note_object
# export(NodePath) onready var beat_player = get_node(beat_player) as BeatPlayer

func _on_beat_detected(beat):
	var notes = map._on_beat_detected(difficulty, beat)
	for note in notes:
		
		# Spawn note
		var note_instance = notescene.instance()
		# note_instance.get_child(0).visible()
		
		# TODO calculate offset which should include the speed and bpm
		# print(note["x"], note["y"], note["offset"])
		note_instance.transform.origin = Vector3(note["x"], note["y"], -2 - note["offset"])
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
		self.add_child(note_instance)
		note_instance.activate()

func setup_map(path:String):
	map = Map.new(path)
	map.get_notes(difficulty)

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



