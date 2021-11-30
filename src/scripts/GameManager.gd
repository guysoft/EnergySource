extends Node

# DEVELOPMENT CONSTS
export (String, "Menu","Game") var debug_start_scene
var menu_path = "res://scenes/Menu.tscn"
var game_path = "res://scenes/Game.tscn"

# Scene loader variables
var scenes_holder : Node;
var loaded_scenes_map = {}
var loaded_scenes_list : Array = []

# WebXR variables
var webxr_interface
var vr_web_supported = false

# OpenXR variables
export (NodePath) var viewport = null
var interface : ARVRInterface

# References
onready var _player = $Player
onready var _left_hand = $Player/ARVROrigin/LeftHand
onready var _right_hand = $Player/ARVROrigin/RightHand
onready var _transition = $Player/ARVROrigin/ARVRCamera/UITransition
onready var _environment_manager = $EnvironmentManager
onready var _beatplayer = $BeatPlayer

#var _scorecard = $

func _enter_tree():
	print ("enter tree")
	add_to_group("global_game_manager");
	
	#create a node called scenes holder
	scenes_holder = Node.new();
	scenes_holder.name="ScenesHolder"
	add_child(scenes_holder)

func _ready():
	print ("ready begin")
	if GameVariables.ENABLE_VR:
		if not initialise_VR():
			print ("failed to init VR")
			GameVariables.ENABLE_VR = false #temp, disable on final build
	else:
		print("No VR")
		_left_hand.queue_free()
		_right_hand.queue_free()
		
		
	# WebXR set up
	if GameVariables.ENABLE_VR:
		$Button.connect("pressed", self, "_on_Button_pressed")
	 
		webxr_interface = ARVRServer.find_interface("WebXR")
		if webxr_interface:
			# WebXR uses a lot of asynchronous callbacks, so we connect to various
			# signals in order to receive them.
			webxr_interface.connect("session_supported", self, "_webxr_session_supported")
			webxr_interface.connect("session_started", self, "_webxr_session_started")
			webxr_interface.connect("session_ended", self, "_webxr_session_ended")
			webxr_interface.connect("session_failed", self, "_webxr_session_failed")
	 
			webxr_interface.connect("select", self, "_webxr_on_select")
			webxr_interface.connect("selectstart", self, "_webxr_on_select_start")
			webxr_interface.connect("selectend", self, "_webxr_on_select_end")
	 
			webxr_interface.connect("squeeze", self, "_webxr_on_squeeze")
			webxr_interface.connect("squeezestart", self, "_webxr_on_squeeze_start")
			webxr_interface.connect("squeezeend", self, "_webxr_on_squeeze_end")
	 
			# This returns immediately - our _webxr_session_supported() method 
			# (which we connected to the "session_supported" signal above) will
			# be called sometime later to let us know if it's supported or not.
			webxr_interface.is_session_supported("immersive-vr")
			# $Player/ARVROrigin/LeftController.connect("button_pressed", self, "_on_LeftController_button_pressed")
			# $Player/ARVROrigin/LeftController.connect("button_release", self, "_on_LeftController_button_release")

	
	
	match (debug_start_scene):
		"Menu":
			load_scene(menu_path, "menu")
		"Game":
			load_scene(game_path, "maze")
	
	pause_mode = Node.PAUSE_MODE_PROCESS;
	scenes_holder.pause_mode = Node.PAUSE_MODE_STOP;
	
	set_process(false)

# Adds a scene to the tree via load_scene and unloads all other scenes
func change_scene(scene, unique_id: String) -> bool:
	return load_scene(scene, unique_id);

# Adds a scene to the tree via load_scene without unloading any other scenes
func add_scene(scene, unique_id: String) -> bool:
	return load_scene(scene, unique_id, true)

# Loads a scene to the manager with the specified unique_id. If additive is
# true then the scene will be loaded parallel to other scenes, otherwise all other
# scenes will be unloaded before this one is loaded. The scene can either be a path
# to the resource or a PackedScene. Returns true on success, false otherwise.
func load_scene(scene, unique_id: String, additive = false) -> bool:
	
	_transition.get_node("AnimationPlayer").play("fade")
	yield(_transition.get_node("AnimationPlayer"), "animation_finished")
	
	var to_load : PackedScene;
	
	if scene is String:
		to_load = load(scene);
	elif scene is PackedScene:
		to_load = scene;
	else:
		return false;
		
	if not additive:
		for loaded_scene in loaded_scenes_list:
			loaded_scene.queue_free()
		loaded_scenes_list.clear()
		loaded_scenes_map = {}
	
	if loaded_scenes_map.has(unique_id):
		return false
		
	var new_scene = to_load.instance()
	loaded_scenes_map[unique_id] = new_scene
	loaded_scenes_list.append(new_scene)
	
	scenes_holder.add_child(new_scene, true)
	print("Memory: " + str(OS.get_static_memory_peak_usage()))
	yield(get_tree().create_timer(1.0), "timeout")
	_transition.get_node("AnimationPlayer").play_backwards("fade")
	#yield(transition.get_node("AnimationPlayer"), "animation_finished")
	
	return true

# Unloads the scene with the specified unique_id. If a camera has been registered
# to that scene that camera is deleted too.
func unload_scene(unique_id : String):
	if loaded_scenes_map.has(unique_id):
		loaded_scenes_list.erase(loaded_scenes_map[unique_id])
		loaded_scenes_map[unique_id].queue_free()
		loaded_scenes_map.erase(unique_id)

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
	
	
# Web XR functions
func _webxr_on_select(controller_id: int) -> void:
	if GameVariables.ENABLE_VR:
		print("Select: " + str(controller_id))
	 
		var controller: ARVRPositionalTracker = webxr_interface.get_controller(controller_id)
		print (controller.get_orientation())
		print (controller.get_position())
 
func _webxr_on_select_start(controller_id: int) -> void:
	if GameVariables.ENABLE_VR:
		print("Select Start: " + str(controller_id))
 
func _webxr_on_select_end(controller_id: int) -> void:
	if GameVariables.ENABLE_VR:
		print("Select End: " + str(controller_id))
 
func _webxr_on_squeeze(controller_id: int) -> void:
	if GameVariables.ENABLE_VR:
		print("Squeeze: " + str(controller_id))
 
func _webxr_on_squeeze_start(controller_id: int) -> void:
	if GameVariables.ENABLE_VR:
		print("Squeeze Start: " + str(controller_id))
 
func _webxr_on_squeeze_end(controller_id: int) -> void:
	if GameVariables.ENABLE_VR:
		print("Squeeze End: " + str(controller_id))


func _webxr_session_supported(session_mode: String, supported: bool) -> void:
	if GameVariables.ENABLE_VR:
		if session_mode == 'immersive-vr':
			vr_web_supported = supported
 
func _on_Button_pressed() -> void:
	if GameVariables.ENABLE_VR:
		
		if not vr_web_supported:
			OS.alert("Your browser doesn't support VR")
			return
	 
		# We want an immersive VR session, as opposed to AR ('immersive-ar') or a
		# simple 3DoF viewer ('viewer').
		webxr_interface.session_mode = 'immersive-vr'
		# 'bounded-floor' is room scale, 'local-floor' is a standing or sitting
		# experience (it puts you 1.6m above the ground if you have 3DoF headset),
		# whereas as 'local' puts you down at the ARVROrigin.
		# This list means it'll first try to request 'bounded-floor', then 
		# fallback on 'local-floor' and ultimately 'local', if nothing else is
		# supported.
		webxr_interface.requested_reference_space_types = 'bounded-floor, local-floor, local'
		# In order to use 'local-floor' or 'bounded-floor' we must also
		# mark the features as required or optional.
		webxr_interface.required_features = 'local-floor'
		webxr_interface.optional_features = 'bounded-floor'
	 
		# This will return false if we're unable to even request the session,
		# however, it can still fail asynchronously later in the process, so we
		# only know if it's really succeeded or failed when our 
		# _webxr_session_started() or _webxr_session_failed() methods are called.
		if not webxr_interface.initialize():
			OS.alert("Failed to initialize")
			return
 
func _webxr_session_started() -> void:
	if GameVariables.ENABLE_VR:
		$Button.visible = false
		# This tells Godot to start rendering to the headset.
		get_viewport().arvr = true
		# This will be the reference space type you ultimately got, out of the
		# types that you requested above. This is useful if you want the game to
		# work a little differently in 'bounded-floor' versus 'local-floor'.
		print ("Reference space type: " + webxr_interface.reference_space_type)
 
func _webxr_session_ended() -> void:
	if GameVariables.ENABLE_VR:
		$Button.visible = true
		# If the user exits immersive mode, then we tell Godot to render to the web
		# page again.
		get_viewport().arvr = false
 
func _webxr_session_failed(message: String) -> void:
	if GameVariables.ENABLE_VR:
		OS.alert("Failed to initialize: " + message)
 
func _on_LeftController_button_pressed(button: int) -> void:
	if GameVariables.ENABLE_VR:
		print ("Button pressed: " + str(button))
 
func _on_LeftController_button_release(button: int) -> void:
	if GameVariables.ENABLE_VR:
		print ("Button release: " + str(button))
