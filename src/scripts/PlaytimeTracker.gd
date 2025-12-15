extends Node

var _is_playing = false
var _playtime_today = 0.0
var _save_timer = 0.0
const SAVE_INTERVAL = 5.0  # Save every 5 seconds during play

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS  # Run even when paused
	Events.connect("song_begin", _on_song_begin)
	Events.connect("song_end", _on_song_end)
	_check_new_day()
	_playtime_today = SaveManager.get_value("playtime", "today", 0.0)

func _process(delta):
	if not _is_playing:
		return
	if get_tree().paused:
		return  # Don't accumulate while paused
	
	_playtime_today += delta
	_save_timer += delta
	
	if _save_timer >= SAVE_INTERVAL:
		_save_playtime()
		_save_timer = 0.0

func _on_song_begin():
	_is_playing = true
	_save_timer = 0.0

func _on_song_end():
	_is_playing = false
	_save_playtime()

func _save_playtime():
	SaveManager.set_value("playtime", "today", _playtime_today)
	SaveManager.set_value("playtime", "date", _get_today_string())
	SaveManager.save_data()

func _check_new_day():
	var stored_date = SaveManager.get_value("playtime", "date", "")
	var today = _get_today_string()
	if stored_date != today:
		SaveManager.set_value("playtime", "today", 0.0)
		SaveManager.set_value("playtime", "date", today)
		SaveManager.save_data()
		_playtime_today = 0.0

func _get_today_string() -> String:
	var date = Time.get_date_dict_from_system()
	return "%04d-%02d-%02d" % [date.year, date.month, date.day]

func get_playtime_today() -> float:
	return _playtime_today

func format_playtime(seconds: float) -> String:
	var total_seconds = int(seconds)
	var hours = total_seconds / 3600
	var minutes = (total_seconds % 3600) / 60
	var secs = total_seconds % 60
	return "%02d:%02d:%02d" % [hours, minutes, secs]
