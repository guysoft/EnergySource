class_name PowerBeatsVRMap

# PowerBeatsVR Map Loader
# Loads and parses PowerBeatsVR JSON level format
# Implements the same interface as Map (MapLoader.gd) for Beat Saber levels

# True PowerBeatsVR coordinate limits (from developers)
# These are documented but not enforced - levels may exceed these
# posx = -1.3 to 1.3
# posy = 0.5 to 1.3
const PBVR_X_MIN = -1.3
const PBVR_X_MAX = 1.3
const PBVR_Y_MIN = 0.5
const PBVR_Y_MAX = 1.3

# BPM Range thresholds (from PowerBeatsVR GameManager.cs)
# Used to determine ball flight duration
const BPM_MID_THRESHOLD = 100
const BPM_HIGH_THRESHOLD = 145

# Position adjustment constants (tune these if needed)
# VERTICAL_OFFSET: From PowerBeatsVR Util.cs - stored Y is offset by -1.3
# JSON stores Y values like -0.5, 0.25 which need +1.3 to get actual position
const PBVR_VERTICAL_OFFSET = 1.3

# Optional scaling if coordinate ranges don't match
const PBVR_X_SCALE = 1.0  # Multiply X by this
const PBVR_Y_SCALE = 1.0  # Multiply Y by this (after offset)

# Optional additional offset for fine-tuning
const PBVR_X_OFFSET = 0.0  # Add to X after scaling
const PBVR_Y_OFFSET = 0.0  # Add to Y after offset+scaling

# Action type constants
const ACTION_NORMAL_BALL = "NormalBall"
const ACTION_POWER_BALL = "PowerBall"
const ACTION_BALL_OBSTACLE = "BallObstacle"
const ACTION_WALL_OBSTACLE = "WallObstacle"
const ACTION_STREAM = "Stream"

# Note types matching EnergySource/Beat Saber
const NOTE_TYPE_LEFT = 0
const NOTE_TYPE_RIGHT = 1
const NOTE_TYPE_BOMB = 3

# Wall type names for placeholders and debugging
const WALL_TYPE_NAMES = {
	0: "SingleColumn",
	1: "DoubleColumn",
	2: "ArchwayCenter",
	3: "ArchwayLeft",
	4: "ArchwayRight",
	5: "OpeningLeft",
	6: "OpeningRight",
	7: "BarAcrossTheForehead"
}

# Wall type to obstacle type mapping
const WALL_TYPE_TO_OBSTACLE = {
	0: "full_height",      # SingleColumn
	1: "full_height",      # DoubleColumn (placeholder)
	2: "archway_center",   # ArchwayCenter (placeholder)
	3: "archway_left",     # ArchwayLeft (placeholder)
	4: "archway_right",    # ArchwayRight (placeholder)
	5: "opening_left",     # OpeningLeft (placeholder)
	6: "opening_right",    # OpeningRight (placeholder)
	7: "crouch"            # BarAcrossTheForehead
}

# Available difficulties in PowerBeatsVR
const DIFFICULTIES = ["Beginner", "Advanced", "Expert"]

var path: String = ""
var json_data: Dictionary = {}
var difficulty: String = ""
var notes: Dictionary = {}
var obstacles: Dictionary = {}
var events: Dictionary = {}  # Empty for PowerBeatsVR - kept for interface compatibility

# Music search paths - will be set based on the layout file location
var music_search_paths: Array = []


func _init(json_path: String):
	self.path = json_path
	_load_json()
	_setup_music_paths()


func _load_json():
	if not FileAccess.file_exists(path):
		push_error("PowerBeatsVRMap: JSON file not found: " + path)
		return
	
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("PowerBeatsVRMap: Could not open JSON file: " + path)
		return
	
	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	file.close()
	
	if error != OK:
		push_error("PowerBeatsVRMap: JSON parse error: " + json.get_error_message())
		return
	
	json_data = json.data
	print("PowerBeatsVRMap: Loaded level '", get_name(), "' by ", json_data.get("author", "Unknown"))


func _setup_music_paths():
	# Setup search paths for the music file
	# PowerBeatsVR stores music separately from layouts
	var base_dir = path.get_base_dir()  # e.g., .../PowerBeatsVRLevels/Layouts
	var parent_dir = base_dir.get_base_dir()  # e.g., .../PowerBeatsVRLevels
	
	# Search in these locations (in order):
	# 1. Same directory as the JSON file
	# 2. ../music/ relative to Layouts
	# 3. ../music/all/ relative to Layouts (common PowerBeatsVR structure)
	music_search_paths = [
		base_dir,
		parent_dir + "/music",
		parent_dir + "/music/all"
	]


func get_name() -> String:
	return json_data.get("name", "")


func get_bpm() -> float:
	return float(json_data.get("bpm", 120))


func get_offset() -> float:
	return float(json_data.get("offset", 0))


func get_ball_flight_duration() -> int:
	# Ball flight duration in beats - how long balls take to fly from spawn to player
	# From PowerBeatsVR GameManager.cs - Expert difficulty timing
	# BPM < 100  (Low):  2 beats
	# BPM 100-145 (Mid): 2 beats
	# BPM >= 145 (High): 3 beats
	var bpm = get_bpm()
	if bpm >= BPM_HIGH_THRESHOLD:
		return 3  # High BPM songs need more time
	else:
		return 2  # Low and Mid BPM songs


func get_song() -> String:
	# Find the audio file matching the level name
	var song_name = path.get_file().get_basename()  # e.g., "Wellerman" from "Wellerman.json"
	
	# Try different extensions
	var extensions = [".ogg", ".mp3", ".wav"]
	
	for search_path in music_search_paths:
		for ext in extensions:
			var song_path = search_path + "/" + song_name + ext
			if FileAccess.file_exists(song_path):
				print("PowerBeatsVRMap: Found audio file: " + song_path)
				return song_path
	
	push_warning("PowerBeatsVRMap: Could not find audio file for: " + song_name)
	return ""


func get_cover_name() -> String:
	# PowerBeatsVR doesn't have cover images
	return ""


func get_available_difficulties() -> Array:
	var available = []
	for diff in DIFFICULTIES:
		if json_data.has(diff):
			var diff_data = json_data[diff]
			if diff_data is Dictionary and diff_data.has("beats"):
				var beats = diff_data["beats"]
				if beats is Array and beats.size() > 0:
					available.append(diff)
	return available


func set_difficulty(select_difficulty: String):
	self.difficulty = select_difficulty


func get_difficulty() -> String:
	return self.difficulty


func get_level(select_difficulty: String):
	self.difficulty = select_difficulty
	
	if not json_data.has(select_difficulty):
		push_error("PowerBeatsVRMap: Difficulty not found: " + select_difficulty)
		return
	
	var diff_data = json_data[select_difficulty]
	if not diff_data is Dictionary or not diff_data.has("beats"):
		push_error("PowerBeatsVRMap: Invalid difficulty data for: " + select_difficulty)
		return
	
	# Clear previous data
	notes[select_difficulty] = {}
	obstacles[select_difficulty] = {}
	events[select_difficulty] = {}
	
	# Parse all beats
	var beats = diff_data["beats"]
	for beat in beats:
		_parse_beat(select_difficulty, beat)
	
	print("PowerBeatsVRMap: Loaded ", select_difficulty, " - ", 
		  get_note_count(select_difficulty), " notes")


func _parse_beat(diff: String, beat: Dictionary):
	var beat_no = int(beat.get("beatNo", 0))
	
	# Parse main beat actions (offset = 0)
	var actions = beat.get("actions", [])
	for action in actions:
		_parse_action(diff, beat_no, 0.0, action)
	
	# Parse sub-beats (fractional timing)
	var sub_beats = beat.get("subBeats", [])
	for sub_beat in sub_beats:
		var offset = float(sub_beat.get("offset", 0.0))
		var sub_actions = sub_beat.get("actions", [])
		for action in sub_actions:
			_parse_action(diff, beat_no, offset, action)


func _parse_action(diff: String, beat_no: int, offset: float, action: Dictionary):
	var action_type = action.get("action", "")
	var position = action.get("position", [0.0, 0.0])
	
	match action_type:
		ACTION_NORMAL_BALL, ACTION_POWER_BALL:
			_add_note(diff, beat_no, offset, position, action_type)
		ACTION_BALL_OBSTACLE:
			_add_bomb(diff, beat_no, offset, position)
		ACTION_WALL_OBSTACLE:
			_add_wall(diff, beat_no, offset, position, action)
		ACTION_STREAM:
			# Streams are not implemented - log and skip
			print("PowerBeatsVRMap: Stream action at beat ", beat_no, " (not implemented)")
		_:
			push_warning("PowerBeatsVRMap: Unknown action type: " + action_type)


func _add_note(diff: String, beat_no: int, offset: float, position: Array, action_type: String):
	if not notes.has(diff):
		notes[diff] = {}
	if not notes[diff].has(beat_no):
		notes[diff][beat_no] = []
	
	var pos = _pbvr_to_es_position(position)
	
	# Determine note type based on X position (left vs right)
	var note_type = NOTE_TYPE_LEFT if pos.x < 0 else NOTE_TYPE_RIGHT
	
	# Check if this is a PowerBall or if "Only Power Balls" mode forces all to be PowerBalls
	var force_power_balls = _get_only_power_balls_setting()
	var is_power_ball = (action_type == ACTION_POWER_BALL) or force_power_balls
	
	var note = {
		"x": pos.x,
		"y": pos.y,
		"_time": float(beat_no) + offset,
		"_type": note_type,
		"_lineIndex": 0,  # Not used but kept for compatibility
		"_lineLayer": 0,  # Not used but kept for compatibility
		"_cutDirection": 8,  # Any direction
		"offset": offset,
		"_pbvr_action": action_type,  # Store original action for potential future use
		"_is_power_ball": is_power_ball  # PowerBalls require 4x velocity to hit
	}
	
	notes[diff][beat_no].append(note)


func _add_bomb(diff: String, beat_no: int, offset: float, position: Array):
	if not notes.has(diff):
		notes[diff] = {}
	if not notes[diff].has(beat_no):
		notes[diff][beat_no] = []
	
	var pos = _pbvr_to_es_position(position)
	
	var bomb = {
		"x": pos.x,
		"y": pos.y,
		"_time": float(beat_no) + offset,
		"_type": NOTE_TYPE_BOMB,
		"_lineIndex": 0,
		"_lineLayer": 0,
		"_cutDirection": 0,
		"offset": offset
	}
	
	notes[diff][beat_no].append(bomb)


func _add_wall(diff: String, beat_no: int, offset: float, position: Array, action: Dictionary):
	if not obstacles.has(diff):
		obstacles[diff] = {}
	if not obstacles[diff].has(beat_no):
		obstacles[diff][beat_no] = []
	
	var pos = _pbvr_to_es_position(position)
	var wall_type = int(action.get("type", 0))
	var depth = float(action.get("depth", 1.0))
	
	var obstacle_type = WALL_TYPE_TO_OBSTACLE.get(wall_type, "full_height")
	
	var obstacle = {
		"x": pos.x,
		"y": pos.y,
		"_time": float(beat_no) + offset,
		"_lineIndex": 0,
		"_type": wall_type,
		"_duration": depth,
		"_width": 1,
		"type": obstacle_type,
		"duration": depth,
		"width": 1,
		"offset": offset,
		"_pbvr_wall_type": wall_type,
		"_pbvr_wall_name": WALL_TYPE_NAMES.get(wall_type, "Unknown")
	}
	
	obstacles[diff][beat_no].append(obstacle)


func _pbvr_to_es_position(position: Array) -> Vector2:
	# Convert PowerBeatsVR stored coordinates to actual game coordinates
	# PowerBeatsVR stores Y with a -1.3 offset (from Util.cs VERTICAL_OFFSET)
	var x = float(position[0]) if position.size() > 0 else 0.0
	var y = float(position[1]) if position.size() > 1 else 0.0
	
	# Apply PowerBeatsVR vertical offset (stored Y is offset by -1.3)
	y += PBVR_VERTICAL_OFFSET
	
	# Apply optional scaling
	x *= PBVR_X_SCALE
	y *= PBVR_Y_SCALE
	
	# Apply optional fine-tuning offset
	x += PBVR_X_OFFSET
	y += PBVR_Y_OFFSET
	
	return Vector2(x, y)


func get_note_count(diff: String) -> int:
	if not notes.has(diff):
		return 0
	
	var count = 0
	for beat_no in notes[diff]:
		count += notes[diff][beat_no].size()
	return count


func _on_beat_detected(diff: String, beat: int) -> Array:
	# Returns [notes, obstacles, events] for the given beat number
	# This matches the interface expected by Game.gd
	
	var return_notes = []
	var return_obstacles = []
	var return_events = []
	
	if notes.has(diff) and notes[diff].has(int(beat)):
		return_notes = notes[diff][int(beat)]
	
	if obstacles.has(diff) and obstacles[diff].has(int(beat)):
		return_obstacles = obstacles[diff][int(beat)]
	
	if events.has(diff) and events[diff].has(int(beat)):
		return_events = events[diff][int(beat)]
	
	return [return_notes, return_obstacles, return_events]


# Helper to safely get the "only_power_balls" setting
# Returns false if Settings autoload is not available (e.g., headless testing)
static func _get_only_power_balls_setting() -> bool:
	# Settings is an autoload Node (not an Engine singleton). In headless/unit tests,
	# it may not exist, so default to false.
	var main_loop = Engine.get_main_loop()
	var tree := main_loop as SceneTree
	if tree == null:
		return false
	var settings_node = tree.root.get_node_or_null("Settings")
	if settings_node and settings_node.has_method("get_setting"):
		return bool(settings_node.get_setting("game", "only_power_balls"))
	return false

