extends Node

# QualitySettings autoload
# Detects Quest 2 (Android) and provides platform-aware quality settings
# Also provides debug toggles for performance testing

static var _is_quest_cached: bool = false
static var _cache_initialized: bool = false

# Debug performance test settings
# Set these to false to disable features and test their performance impact
static var debug_particles_enabled: bool = true
static var debug_lighting_enabled: bool = true
static var debug_postprocess_enabled: bool = true  # Glow, bloom, fog
static var debug_note_explosions_enabled: bool = true
static var debug_environment_particles_enabled: bool = true

# Performance test mode - when true, applies aggressive optimizations
static var performance_test_mode: bool = false

func _ready():
	_initialize_cache()
	_check_performance_test_env()
	
	# Debug: Uncomment to auto-apply minimal settings for performance testing
	#if is_quest():
	#	apply_minimal_settings()
	#	print("QualitySettings: Auto-applied MINIMAL settings for Quest performance test")

static func _initialize_cache():
	if _cache_initialized:
		return
	_is_quest_cached = OS.get_name() == "Android"
	_cache_initialized = true
	if _is_quest_cached:
		print("QualitySettings: Running on Quest/Android - using low quality settings")
	else:
		print("QualitySettings: Running on PC - using high quality settings")

func _check_performance_test_env():
	# Check for environment variable to enable performance test mode
	# Deploy with: adb shell setprop debug.tempovr.perf_test 1
	if OS.has_environment("TEMPOVR_PERF_TEST"):
		performance_test_mode = true
		print("QualitySettings: Performance test mode enabled via environment")

## Returns true if running on Quest/Android, false otherwise
static func is_quest() -> bool:
	if not _cache_initialized:
		_initialize_cache()
	return _is_quest_cached

## Check if particles should be enabled
static func particles_enabled() -> bool:
	return debug_particles_enabled and not performance_test_mode

## Check if lighting effects should be enabled
static func lighting_enabled() -> bool:
	return debug_lighting_enabled and not performance_test_mode

## Check if post-processing should be enabled
static func postprocess_enabled() -> bool:
	return debug_postprocess_enabled and not performance_test_mode

## Check if note explosions should be enabled
static func note_explosions_enabled() -> bool:
	return debug_note_explosions_enabled and not performance_test_mode

## Check if environment particles should be enabled
static func environment_particles_enabled() -> bool:
	return debug_environment_particles_enabled and not performance_test_mode

## Apply minimal quality settings for performance testing
static func apply_minimal_settings():
	debug_particles_enabled = false
	debug_lighting_enabled = false
	debug_postprocess_enabled = false
	debug_note_explosions_enabled = false
	debug_environment_particles_enabled = false
	print("QualitySettings: Applied minimal settings for performance testing")

## Apply normal quality settings
static func apply_normal_settings():
	debug_particles_enabled = true
	debug_lighting_enabled = true
	debug_postprocess_enabled = true
	debug_note_explosions_enabled = true
	debug_environment_particles_enabled = true
	print("QualitySettings: Applied normal settings")

## Get current settings as dictionary for debugging
static func get_debug_info() -> Dictionary:
	return {
		"is_quest": is_quest(),
		"particles": debug_particles_enabled,
		"lighting": debug_lighting_enabled,
		"postprocess": debug_postprocess_enabled,
		"note_explosions": debug_note_explosions_enabled,
		"environment_particles": debug_environment_particles_enabled,
		"performance_test_mode": performance_test_mode
	}
