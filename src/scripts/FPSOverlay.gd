extends Node3D
## FPS Overlay for VR debugging
## Displays framerate and frame time as a Label3D that follows the camera
## Press menu button to cycle through performance test modes

@export var enabled: bool = true
@export var offset: Vector3 = Vector3(0.3, -0.2, -0.5)  # Bottom-right of view
@export var update_interval: float = 0.5  # Update every 500ms for readability
@export var show_quality_info: bool = true  # Show quality settings info

@onready var label: Label3D = $Label3D

var _time_since_update: float = 0.0
var _frame_times: Array[float] = []
var _max_samples: int = 20
var _test_mode_index: int = 0

# Test mode configurations
var _test_modes: Array[Dictionary] = [
	{"name": "NORMAL", "particles": true, "lighting": true, "postprocess": true, "explosions": true, "env_particles": true},
	{"name": "NO PARTICLES", "particles": false, "lighting": true, "postprocess": true, "explosions": false, "env_particles": false},
	{"name": "NO LIGHTING", "particles": true, "lighting": false, "postprocess": true, "explosions": true, "env_particles": true},
	{"name": "NO POSTFX", "particles": true, "lighting": true, "postprocess": false, "explosions": true, "env_particles": true},
	{"name": "MINIMAL", "particles": false, "lighting": false, "postprocess": false, "explosions": false, "env_particles": false},
]

func _ready() -> void:
	if not enabled:
		visible = false
		return
	
	# Make sure we're always rendered on top
	if label:
		label.no_depth_test = true
		label.fixed_size = true
		label.pixel_size = 0.001
	
	# Sync test mode index with QualitySettings state
	_sync_test_mode_from_quality_settings()

func _sync_test_mode_from_quality_settings() -> void:
	# Find which test mode matches current QualitySettings
	for i in range(_test_modes.size()):
		var mode = _test_modes[i]
		if (mode["particles"] == QualitySettings.debug_particles_enabled and
			mode["lighting"] == QualitySettings.debug_lighting_enabled and
			mode["postprocess"] == QualitySettings.debug_postprocess_enabled and
			mode["explosions"] == QualitySettings.debug_note_explosions_enabled and
			mode["env_particles"] == QualitySettings.debug_environment_particles_enabled):
			_test_mode_index = i
			print("FPSOverlay: Synced to test mode: ", mode["name"])
			return
	# If no exact match found, check if all false (MINIMAL)
	if (not QualitySettings.debug_particles_enabled and
		not QualitySettings.debug_lighting_enabled and
		not QualitySettings.debug_postprocess_enabled):
		_test_mode_index = 4  # MINIMAL index
		print("FPSOverlay: Detected MINIMAL settings")

func _process(delta: float) -> void:
	if not enabled:
		return
	
	# Track frame times for averaging
	_frame_times.append(delta)
	if _frame_times.size() > _max_samples:
		_frame_times.remove_at(0)
	
	_time_since_update += delta
	if _time_since_update >= update_interval:
		_time_since_update = 0.0
		_update_display()
	
	# Follow the camera
	_follow_camera()

func _input(event: InputEvent) -> void:
	# Cycle test modes when menu button is pressed (on either controller)
	if event is InputEventJoypadButton:
		# Menu button is typically button 3 on Quest controllers
		if event.button_index == JOY_BUTTON_START and event.pressed:
			cycle_test_mode()

func cycle_test_mode() -> void:
	_test_mode_index = (_test_mode_index + 1) % _test_modes.size()
	var mode = _test_modes[_test_mode_index]
	
	QualitySettings.debug_particles_enabled = mode["particles"]
	QualitySettings.debug_lighting_enabled = mode["lighting"]
	QualitySettings.debug_postprocess_enabled = mode["postprocess"]
	QualitySettings.debug_note_explosions_enabled = mode["explosions"]
	QualitySettings.debug_environment_particles_enabled = mode["env_particles"]
	
	print("FPSOverlay: Switched to test mode: ", mode["name"])
	
	# Force immediate display update
	_update_display()

func _follow_camera() -> void:
	var camera := get_viewport().get_camera_3d()
	if camera:
		# Position relative to camera
		global_transform.origin = camera.global_transform.origin + camera.global_transform.basis * offset
		# Face the camera
		look_at(camera.global_transform.origin, Vector3.UP)
		# Flip to face camera (Label3D faces -Z by default)
		rotate_object_local(Vector3.UP, PI)

func _update_display() -> void:
	if not label:
		return
	
	var fps := Engine.get_frames_per_second()
	var avg_frame_time := _get_average_frame_time()
	
	# Color code based on performance
	# Quest 2 targets: 72Hz (13.9ms), 90Hz (11.1ms), 120Hz (8.3ms)
	var color: Color
	if fps >= 72:
		color = Color.GREEN
	elif fps >= 60:
		color = Color.YELLOW
	else:
		color = Color.RED
	
	label.modulate = color
	
	# Build display text
	var text := "%d FPS\n%.1f ms" % [fps, avg_frame_time * 1000.0]
	
	if show_quality_info:
		var mode_name = _test_modes[_test_mode_index]["name"]
		text += "\n[%s]" % mode_name
	
	label.text = text

func _get_average_frame_time() -> float:
	if _frame_times.is_empty():
		return 0.0
	var total := 0.0
	for t in _frame_times:
		total += t
	return total / _frame_times.size()

## Toggle overlay visibility
func toggle() -> void:
	enabled = not enabled
	visible = enabled

## Get current stats as dictionary (for logging/debugging)
func get_stats() -> Dictionary:
	return {
		"fps": Engine.get_frames_per_second(),
		"frame_time_ms": _get_average_frame_time() * 1000.0,
		"physics_fps": Engine.physics_ticks_per_second,
		"test_mode": _test_modes[_test_mode_index]["name"]
	}

## Set a specific test mode by index
func set_test_mode(index: int) -> void:
	if index >= 0 and index < _test_modes.size():
		_test_mode_index = index
		cycle_test_mode()  # This will apply the settings
		_test_mode_index -= 1  # Adjust since cycle_test_mode increments

