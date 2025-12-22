extends Node3D

@export var environment: Environment
@export var music: AudioStream
@export var start_delay = 1.0

@onready var _beat_player = Global.manager()._beatplayer
@onready var _player = Global.manager()._player
@onready var _environment_manager = Global.manager()._environment_manager

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
