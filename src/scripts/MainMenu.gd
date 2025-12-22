extends Node3D

@export var environment: Environment
@export var music: AudioStream
@export var start_delay = 1.0

@onready var _beat_player = Global.manager()._beatplayer
@onready var _player = Global.manager()._player
@onready var _environment_manager = Global.manager()._environment_manager

# Shader warmup - preload game assets to compile shaders before entering game
var _shaders_warmed_up: bool = false

# VR Recenter: Y+B button hold detection
var _recenter_hold_time := 0.0
var _recenter_triggered := false

func _ready():
	#$AudioStreamPlayer.play()
	_environment_manager.change_environment(environment)
	
	# Quest optimization: disable expensive environment effects
	# This achieves 72 FPS without modifying SubViewport update modes
	if QualitySettings.is_quest() and environment:
		environment.glow_enabled = false
		environment.fog_enabled = false
		environment.volumetric_fog_enabled = false
		environment.background_mode = Environment.BG_COLOR
		environment.background_color = Color(0.02, 0.02, 0.04, 1.0)
		environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		environment.ambient_light_color = Color(0.15, 0.15, 0.2, 1.0)
		environment.ambient_light_energy = 0.3
	
	#start_delay = $AudioStreamPlayer.stream.get_length()
	#yield(get_tree().create_timer(start_delay), "timeout")
	if _beat_player and music:
		_beat_player.stream = music
		_beat_player.play_music()
		#_environment.start_strobe(_music.bpm/2)
	
	_player.in_game=false
	_player.game_node=null
	
	_update_playtime_display()
	
	# Pre-warm shaders for game scene on Quest
	_warmup_game_shaders()

func _update_playtime_display():
	# UICanvas moves the Control into SubViewport at runtime
	var playtime_label = $UICanvas/SubViewport/ReferenceRect/Panel/TodayPlayTimeLabel/TodayPlayTime
	if playtime_label:
		var seconds = PlaytimeTracker.get_playtime_today()
		playtime_label.text = PlaytimeTracker.format_playtime(seconds)

func _process(delta):
	_check_recenter_input(delta)

func _check_recenter_input(delta):
	"""Check for Y+B buttons held together for 3 seconds to trigger VR recenter."""
	if not GameVariables.ENABLE_VR:
		return
	
	var left_hand = Global.manager()._left_hand
	var right_hand = Global.manager()._right_hand
	
	if not left_hand or not right_hand:
		return
	
	# Check if both Y (left by_button) and B (right by_button) are pressed
	var y_pressed = left_hand.is_button_pressed("by_button")
	var b_pressed = right_hand.is_button_pressed("by_button")
	
	if y_pressed and b_pressed:
		_recenter_hold_time += delta
		
		# Trigger recenter after holding for 3 seconds
		if _recenter_hold_time >= VRRecenter.RECENTER_HOLD_TIME and not _recenter_triggered:
			_recenter_triggered = true
			_trigger_recenter()
	else:
		# Reset when buttons released
		_recenter_hold_time = 0.0
		_recenter_triggered = false

func _trigger_recenter():
	"""Trigger the VR recenter action with haptic feedback."""
	print("MainMenu: Triggering VR recenter")
	
	# Provide haptic feedback on both controllers
	var left_hand = Global.manager()._left_hand
	var right_hand = Global.manager()._right_hand
	
	if left_hand:
		left_hand.simple_rumble(0.5, 0.3)
	if right_hand:
		right_hand.simple_rumble(0.5, 0.3)
	
	# Perform the recenter
	VRRecenter.recenter()

func _warmup_game_shaders():
	"""Pre-compile game shaders in the menu to avoid stuttering when game starts.
	
	This instantiates Note and Obstacle scenes off-screen, makes them visible,
	applies all material variants, and renders them for several frames to force 
	the GPU to compile all required shaders before the player enters the game.
	"""
	print("MainMenu: _warmup_game_shaders called, _shaders_warmed_up=", _shaders_warmed_up)
	
	if _shaders_warmed_up:
		print("MainMenu: Skipping warmup (already done)")
		return
	
	print("MainMenu: is_quest=", QualitySettings.is_quest())
	
	# Only needed on Quest where shader compilation is noticeable
	if not QualitySettings.is_quest():
		_shaders_warmed_up = true
		print("MainMenu: Skipping warmup (not Quest)")
		return
	
	print("MainMenu: Warming up game shaders...")
	
	# Preload game object scenes
	var notescene = preload("res://scenes/Note.tscn")
	var obstaclescene = preload("res://scenes/Obstacle.tscn")
	
	# Also preload the materials directly to ensure they're in GPU memory
	var _mat0 = preload("res://effects/note_0_material.tres")
	var _mat1 = preload("res://effects/note_1_material.tres")
	var _mat3 = preload("res://effects/note_3_material.tres")
	var _wall_mat = preload("res://effects/wall_material.tres")
	
	var warmup_objects = []
	
	# Instantiate notes with different materials applied
	# Position off-screen but still within render distance
	for i in range(3):  # For materials 0, 1, 3 (there's no material 2)
		var note = notescene.instantiate()
		note.position = Vector3(i * 2, -50, -20)  # Off-screen but rendered
		note.visible = true  # Force visible (overrides default invisible state)
		add_child(note)
		
		# Apply the specific material to the mesh
		var mesh = note.get_node_or_null("MeshInstance3D")
		if mesh:
			mesh.visible = true
			mesh.scale = Vector3(1, 1, 1)  # Override RESET animation scale of 0
			if i == 0:
				mesh.material_override = _mat0
			elif i == 1:
				mesh.material_override = _mat1
			else:
				mesh.material_override = _mat3
		
		warmup_objects.append(note)
	
	# Instantiate obstacle with wall material
	var obstacle = obstaclescene.instantiate()
	obstacle.position = Vector3(6, -50, -20)
	obstacle.visible = true
	add_child(obstacle)
	var obs_mesh = obstacle.get_node_or_null("MeshInstance3D")
	if obs_mesh:
		obs_mesh.visible = true
		obs_mesh.scale = Vector3(1, 1, 1)
		obs_mesh.material_override = _wall_mat
	warmup_objects.append(obstacle)
	
	print("MainMenu: Warmup objects created: ", warmup_objects.size())
	
	# Wait for GPU to process and compile shaders
	# Need more frames to ensure all shader variants are compiled
	for frame_idx in range(10):
		await get_tree().process_frame
	
	print("MainMenu: Warmup frames complete, cleaning up")
	
	# Cleanup warmup objects
	for obj in warmup_objects:
		obj.queue_free()
	
	_shaders_warmed_up = true
	print("MainMenu: Shader warmup complete")
