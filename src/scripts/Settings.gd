extends Node

const SAVE_PATH = "user://settings.ini"

var mouseSensitivty = 3/10

var _config_file = ConfigFile.new()
var _settings = {
	"Game": {
		"Mode": "get_fov()",
		"Sensitivty": mouseSensitivty
		}
	}

func _ready():
	var file2Check = File.new()
	if file2Check.file_exists(SAVE_PATH):
		load_settings()
	else:
		save_settings()
	

func save_settings():
	for section in _settings.keys():
		for key in _settings[section].keys():
			_config_file.set_value(section, key, _settings[section][key])
	_config_file.save(SAVE_PATH)
	
func load_settings():
	print("Loading settings from path:" + ProjectSettings.globalize_path(SAVE_PATH))
	var error = _config_file.load(SAVE_PATH)
	if error != OK:
		print("Failed loading settings file, Error code %s" % error)
		return _settings
		
	for section in _settings.keys():
		for key in _settings[section]:
			_settings[section][key] = _config_file.get_value(section, key, null)
			
