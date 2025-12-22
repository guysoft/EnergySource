extends Node

# DEVELOPMENT CONSTS
@export var debug_start_scene: String # (String, "GGJ2Splash", "Menu","Game")
var splash_path = "res://scenes/GameOffSplash.tscn"
var menu_path = "res://scenes/MainMenu.tscn"
var game_path = "res://scenes/Game.tscn"

# Scene loader variables
var scenes_holder : Node;
var loaded_scenes_map = {}
var loaded_scenes_list : Array = []

# WebXR variables
var webxr_interface
var vr_web_supported = false

# OpenXR variables
@export var viewport: NodePath
var interface : XRInterface

# References
@onready var _player = $Player
@onready var _left_hand = $Player/XROrigin3D/LeftHand
@onready var _right_hand = $Player/XROrigin3D/RightHand
@onready var _transition = $Player/XROrigin3D/XRCamera3D/UITransition
@onready var _environment_manager = $EnvironmentManager
@onready var _beatplayer = $BeatPlayer

var first = true




func _enter_tree():
	print ("enter tree")
	add_to_group("global_game_manager");
	
	#create a node called scenes holder
	scenes_holder = Node.new();
	scenes_holder.name="ScenesHolder"
	add_child(scenes_holder)

func _ready():

#	yield(SilentWolf.Scores.get_high_scores(), "sw_scores_received")
#	print("Scores: " + str(SilentWolf.Scores.scores))
	
	print ("ready begin")
	if GameVariables.ENABLE_VR:
		if not initialise_OpenXR():
			print ("failed to init OpenXR")
			
			# WebXR set up
			$Button.connect("pressed", Callable(self, "_on_Button_pressed"))
			
			webxr_interface = XRServer.find_interface("WebXR")
			if webxr_interface:
				print ("found webxr interface")
				# WebXR uses a lot of asynchronous callbacks, so we connect to various
				# signals in order to receive them.
				webxr_interface.connect("session_supported", Callable(self, "_webxr_session_supported"))
				webxr_interface.connect("session_started", Callable(self, "_webxr_session_started"))
				webxr_interface.connect("session_ended", Callable(self, "_webxr_session_ended"))
				webxr_interface.connect("session_failed", Callable(self, "_webxr_session_failed"))
	 
#				webxr_interface.connect("select", self, "_webxr_on_select")
#				webxr_interface.connect("selectstart", self, "_webxr_on_select_start")
#				webxr_interface.connect("selectend", self, "_webxr_on_select_end")
#
#				webxr_interface.connect("squeeze", self, "_webxr_on_squeeze")
#				webxr_interface.connect("squeezestart", self, "_webxr_on_squeeze_start")
#				webxr_interface.connect("squeezeend", self, "_webxr_on_squeeze_end")

				webxr_interface.is_session_supported("immersive-vr")
			else:
				print ("failed to find webxr interface")
				GameVariables.ENABLE_VR = false #temp, disable on final build
	else:
		print("No VR")
		_left_hand.queue_free()
		_right_hand.queue_free()
		
	match (debug_start_scene):
		"GGJ2Splash":
			load_scene(splash_path, "splash")
		"Menu":
			load_scene(menu_path, "menu")
		"Game":
			load_scene(game_path, "maze")
	
	process_mode = Node.PROCESS_MODE_ALWAYS;
	scenes_holder.process_mode = Node.PROCESS_MODE_PAUSABLE;

	get_tree().paused=false
	
	set_process(false)
	
	# Apply initial quality settings
	_apply_quality_settings()

func _apply_quality_settings():
	# Enable VRS (Variable Rate Shading) for mobile renderer on Quest
	# This provides significant performance gains with minimal visual impact
	if QualitySettings.is_quest():
		get_viewport().vrs_mode = Viewport.VRS_XR
		print("GameManager: Enabled VRS_XR for Quest")
	
	# Control the main scene lighting based on quality settings
	if has_node("Sun"):
		$Sun.visible = QualitySettings.lighting_enabled()
	
	# Control PlayerCenter particles
	if has_node("Player/PlayerCenter"):
		var player_center = $Player/PlayerCenter
		if not QualitySettings.particles_enabled():
			player_center.visible = false
			if player_center.has_method("set_emitting"):
				player_center.emitting = false
	
	# Log quality settings for debugging
	print("QualitySettings: ", QualitySettings.get_debug_info())

# Adds a scene to the tree via load_scene and unloads all other scenes
func change_scene_to_file(scene, unique_id: String) -> bool:
	return await load_scene(scene, unique_id);

# Adds a scene to the tree via load_scene without unloading any other scenes
func add_scene(scene, unique_id: String) -> bool:
	return await load_scene(scene, unique_id, true)

# Loads a scene to the manager with the specified unique_id. If additive is
# true then the scene will be loaded parallel to other scenes, otherwise all other
# scenes will be unloaded before this one is loaded. The scene can either be a path
# to the resource or a PackedScene. Returns true on success, false otherwise.
func load_scene(scene, unique_id: String, additive = false) -> bool:
	
	_beatplayer.stop_music()
	if first==true:
		_transition.visible=false
	else:
		_transition.get_node("AnimationPlayer").play("fade")
		await _transition.get_node("AnimationPlayer").animation_finished

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
		
	var new_scene = to_load.instantiate()
	loaded_scenes_map[unique_id] = new_scene
	loaded_scenes_list.append(new_scene)
	
	scenes_holder.add_child(new_scene, true)
	print("Memory: " + str(OS.get_static_memory_peak_usage()))
	#if not first==true:
	if not first==true:
		await get_tree().create_timer(1.0).timeout
		_transition.get_node("AnimationPlayer").play_backwards("fade")
	#yield(transition.get_node("AnimationPlayer"), "animation_finished")
	
	first=false
	
	return true

# Unloads the scene with the specified unique_id. If a camera has been registered
# to that scene that camera is deleted too.
func unload_scene(unique_id : String):
	if loaded_scenes_map.has(unique_id):
		loaded_scenes_list.erase(loaded_scenes_map[unique_id])
		loaded_scenes_map[unique_id].queue_free()
		loaded_scenes_map.erase(unique_id)

# Web XR functions
func _webxr_on_select(controller_id: int) -> void:
	if GameVariables.ENABLE_VR:
		print("Select: " + str(controller_id))
	 
		var controller: XRPositionalTracker = webxr_interface.get_controller(controller_id)
		print (controller.get_orientation())
		print (controller.get_position())
 
func _webxr_on_select_start(controller_id: int) -> void:
	if GameVariables.ENABLE_VR:
#		var controller
#		if controller_id==1:
#			controller = _left_hand
#		else:
#			controller = _right_hand
		
		var controller = webxr_interface.get_controller(controller_id) as XRController3D
		
		# controller.check_button(JOY_VR_TRIGGER,1)
		print("Select Start: " + str(controller_id))
 
func _webxr_on_select_end(controller_id: int) -> void:
	if GameVariables.ENABLE_VR:
		print("Select End: " + str(controller_id))
		var controller
		if controller_id==1:
			controller = _left_hand
		else:
			controller = _right_hand
		# controller.check_button(JOY_VR_TRIGGER,0)
		
func _webxr_on_squeeze(controller_id: int) -> void:
	if GameVariables.ENABLE_VR:
		print("Squeeze: " + str(controller_id))
 
func _webxr_on_squeeze_start(controller_id: int) -> void:
	if GameVariables.ENABLE_VR:
		print("Squeeze Start: " + str(controller_id))
		var controller
		if controller_id==1:
			controller = _left_hand
		else:
			controller = _right_hand
		# controller.check_button(JOY_VR_GRIP,1)
		
func _webxr_on_squeeze_end(controller_id: int) -> void:
	if GameVariables.ENABLE_VR:
		print("Squeeze End: " + str(controller_id))
		var controller
		if controller_id==1:
			controller = _left_hand
		else:
			controller = _right_hand
		# controller.check_button(JOY_VR_GRIP,0)

func _webxr_session_supported(session_mode: String, supported: bool) -> void:
	if GameVariables.ENABLE_VR:
		if session_mode == 'immersive-vr':
			vr_web_supported = supported

func begin_webxr():
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
	else:
		GameVariables.ENABLE_VR = true
	return

func _on_Button_pressed() -> void:
	begin_webxr()

 
func _webxr_session_started() -> void:
	if GameVariables.ENABLE_VR:
		$Button.visible = false
		# This tells Godot to start rendering to the headset.
		get_viewport().use_xr = true
		# This will be the reference space type you ultimately got, out of the
		# types that you requested above. This is useful if you want the game to
		# work a little differently in 'bounded-floor' versus 'local-floor'.
		print ("RefCounted space type: " + webxr_interface.reference_space_type)
		
		# Initialize VR recenter with XR nodes and apply saved offset
		var xr_origin = $Player/XROrigin3D
		var xr_camera = $Player/XROrigin3D/XRCamera3D
		VRRecenter.set_xr_nodes(xr_origin, xr_camera)
 
func _webxr_session_ended() -> void:
	if GameVariables.ENABLE_VR:
		$Button.visible = true
		# If the user exits immersive mode, then we tell Godot to render to the web
		# page again.
		get_viewport().use_xr = false
 
func _webxr_session_failed(message: String) -> void:
	if GameVariables.ENABLE_VR:
		OS.alert("Failed to initialize: " + message)

func initialise_OpenXR() -> bool:
	interface = XRServer.find_interface("OpenXR")
	print (interface)
	if interface and interface.initialize():
		print("OpenXR Interface initialized")

		# Connect to our plugin signals
		_connect_plugin_signals()

		var vp : Viewport = null
		if viewport:
			vp = get_node(viewport) as Viewport
		else:
			vp = get_viewport()
		
		# Set render resolution based on platform
		# Quest 2 native resolution is 1832x1920 per eye. OpenXR defaults to ~1440x1536.
		# Using 1.25-1.3 multiplier brings it close to native resolution.
		# Quest: 1.25 (near-native) for better quality while maintaining performance
		# PC: 1.5 (supersampling) for better quality
		interface.render_target_size_multiplier = 1.25 if QualitySettings.is_quest() else 1.5
		print("Render target size multiplier set to: " + str(interface.render_target_size_multiplier))
		
		# Change our viewport so it is tied to our ARVR interface and renders to our HMD
		vp.use_xr = true

		# Our interface will tell us whether we should keep our render buffer in linear color space
		# If true our preview will be darker.
		# vp.keep_3d_linear = $Configuration.keep_3d_linear()

		# increase our physics engine update speed
		var refresh_rate = 144.0
		if interface.has_method("get_display_refresh_rate"):
			refresh_rate = interface.get_display_refresh_rate()
		if refresh_rate == 0:
			# Only Facebook Reality Labs supports this at this time
			print("No refresh rate given by XR runtime")

			# Use something sufficiently high
			Engine.physics_ticks_per_second = 144
		else:
			print("HMD refresh rate is set to " + str(refresh_rate))

			# Match our physics to our HMD
			Engine.physics_ticks_per_second = refresh_rate

		# Initialize VR recenter with XR nodes and apply saved offset
		var xr_origin = $Player/XROrigin3D
		var xr_camera = $Player/XROrigin3D/XRCamera3D
		VRRecenter.set_xr_nodes(xr_origin, xr_camera)

		return true
	else:
		return false


func _connect_plugin_signals():
	interface.connect("session_begun", Callable(self, "_on_openxr_session_begun"))
	interface.connect("session_ending", Callable(self, "_on_openxr_session_ending"))
	interface.connect("session_focussed", Callable(self, "_on_openxr_focused_state"))
	interface.connect("session_visible", Callable(self, "_on_openxr_visible_state"))
	interface.connect("pose_recentered", Callable(self, "_on_openxr_pose_recentered"))

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
	
