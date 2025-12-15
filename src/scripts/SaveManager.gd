extends Node

const SAVE_DIR = "user://saves/"
const SAVE_FILE = "user://saves/player_data.json"

var _data = {
	"playtime": {
		"today": 0.0,
		"date": ""
	}
}

func _ready():
	_ensure_save_dir()
	load_data()

func _ensure_save_dir():
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_absolute(SAVE_DIR)

func save_data():
	var file = FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(_data, "\t"))
		file.close()

func load_data():
	if not FileAccess.file_exists(SAVE_FILE):
		save_data()  # Create default file
		return
	
	var file = FileAccess.open(SAVE_FILE, FileAccess.READ)
	if file:
		var json = JSON.new()
		if json.parse(file.get_as_text()) == OK:
			_data = json.data
		file.close()

func get_value(section: String, key: String, default = null):
	if _data.has(section) and _data[section].has(key):
		return _data[section][key]
	return default

func set_value(section: String, key: String, value):
	if not _data.has(section):
		_data[section] = {}
	_data[section][key] = value
