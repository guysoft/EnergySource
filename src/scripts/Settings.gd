extends Node

const SAVE_PATH = "user://settings.ini"

var _config_file = ConfigFile.new()
var _settings = {
	"game": {
		"disable_time_warp": false,
		"only_power_balls": false
		}
	}

func _ready():
	if FileAccess.file_exists(SAVE_PATH):
		load_settings()
	else:
		save_settings()
	

func save_settings():
	for section in _settings.keys():
		for key in _settings[section].keys():
			_config_file.set_value(section, key, _settings[section][key])
	_config_file.save(SAVE_PATH)
	
func set_setting(section, key, value):
	_settings[section][key] = value
	save_settings()
	
func get_setting(section, key):
	return _settings[section][key]
	
func load_settings():
	print("Loading settings from path:" + ProjectSettings.globalize_path(SAVE_PATH))
	var error = _config_file.load(SAVE_PATH)
	if error != OK:
		print("Failed loading settings file, Error code %s" % error)
		return _settings
		
	for section in _config_file.get_sections():
		if not section in _settings.keys():
			_settings[section] = {}
		for key in _config_file.get_section_keys(section):
			_settings[section][key] = _config_file.get_value(section, key, null)
	print(_settings)
			
