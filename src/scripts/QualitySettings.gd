extends Node

# QualitySettings autoload
# Detects Quest 2 (Android) and provides platform-aware quality settings

static var _is_quest_cached: bool = false
static var _cache_initialized: bool = false

func _ready():
	_initialize_cache()

static func _initialize_cache():
	if _cache_initialized:
		return
	_is_quest_cached = OS.get_name() == "Android"
	_cache_initialized = true
	if _is_quest_cached:
		print("QualitySettings: Running on Quest/Android - using low quality settings")
	else:
		print("QualitySettings: Running on PC - using high quality settings")

## Returns true if running on Quest/Android, false otherwise
static func is_quest() -> bool:
	if not _cache_initialized:
		_initialize_cache()
	return _is_quest_cached
