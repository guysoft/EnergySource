class_name Map

# Map loader
#  Usage example
#   const Map = preload("map.gd")
# 	var path = "Beat Saber (Built in)/ExpertPlus.dat"
# 	var map = Map.new(path)
# 	map.get_notes("ExpertPlus")

const BS_LEVELS = ["Easy", "NormalStandard", "Normal", "HardStandard", "Hard", "Expert", "ExpertStandard", "ExpertPlusStandard", "ExpertPlus"]
const NOTE_TYPE = {"BOMB": 3}
const OBSTACLE_TYPE = {"FULL_HEIGHT": 0, "CROUCH": 1}

# The width from each side in the center (the total width is twice this number)
const LEVEL_WIDTH = 0.8
# Lowest point in the game map beneeth your center
const LEVEL_LOW = 0.6
# Highest point in the map
const LEVEL_HIGH = 1.05

var path = null
var bs_level_data = {}
var bs_info_data = null
var difficulty = null

var notes = {}
var obstacles = {}
var events = {}
var next_beat_event
var note_offset = 0


func _init(path):
	print ("loading map")
	self.path = path
	var info_path = self.path + "/info.dat"
	var file = File.new()
	file.open(info_path, File.READ)
	self.bs_info_data = parse_json(file.get_as_text())
	file.close()

func set_difficulty(select_difficulty):
	self.difficulty = select_difficulty
	return
	
func get_difficulty():
	return self.difficulty

func get_bpm():
	return self.bs_info_data["_beatsPerMinute"]

func get_offset():
	return self.bs_info_data["_songTimeOffset"] # + self.bs_data["_shufflePeriod"] * self.get_bpm()

func get_note_count(difficulty):
	return self.bs_level_data[difficulty]["_notes"].size()

func get_song():
	return self.path + "/song.ogg"

func _on_beat_detected(difficulty, beat:int):
	# assert(typeof(beat) == TYPE_INT)
	
	# print(self.notes[difficulty])
	var return_value_notes = []
	var return_value_obstacles = []
	var return_value_events = []
	if self.notes.has(difficulty):
		if self.notes[difficulty].has(int(beat)):
			return_value_notes = self.notes[difficulty][int(beat)]
			
	if self.obstacles.has(difficulty):
		if self.obstacles[difficulty].has(int(beat)):
			return_value_obstacles = self.obstacles[difficulty][int(beat)]
	
	if self.events.has(difficulty):
		if self.events[difficulty].has(int(beat)):
			return_value_events = self.events[difficulty][int(beat)]
	
	return [return_value_notes, return_value_obstacles, return_value_events]

func get_level(difficulty):
	var difficulty_path = self.path + "/" + difficulty + ".dat"
	var file = File.new()
	file.open(difficulty_path, File.READ)
	var level = parse_json(file.get_as_text())
	file.close()
	self.bs_level_data[difficulty] = level
	
	for note in self.bs_level_data[difficulty]["_notes"]:
		# print ("adding note: ", note)
		# print ("note time:", note["_time"])
		self.add_note(difficulty, note)
	
	for obstacle in self.bs_level_data[difficulty]["_obstacles"]:
		# print ("adding obstacle: ", obstacle)
		# print ("obstacle time:", obstacle["_time"])		
		self.add_obstacle(difficulty, obstacle)
	
	for event in self.bs_level_data[difficulty]["_events"]:
		self.add_event(difficulty,event)
	
	self.set_difficulty(difficulty)
	return

func line_index_layer_to_position(note):
	# beat saber layer moves between 0-2
	# beat saber index moves between 0-3
	# max posy in beat saber = 0.5 - 1.0
	# max posx in beat saber = -1.3 - 1.3
	var index_to_position_x = {
		0: -LEVEL_WIDTH,
		1: -LEVEL_WIDTH*0.5,
		2: LEVEL_WIDTH*0.5,
		3: LEVEL_WIDTH
	}
	var layer_to_position_y = {
		0: LEVEL_LOW,
		1: (LEVEL_HIGH*2 + LEVEL_LOW)/2,
		2: LEVEL_HIGH*2
	}
	var position_x = index_to_position_x[int(note["_lineIndex"])]
	var position_y = layer_to_position_y[int(note["_lineLayer"])]
	return [position_x, position_y]

func add_note(difficulty, note):
	if not self.notes.has(difficulty):
		self.notes[difficulty] = {}
		
	var beat_number = int(note["_time"])
	var offset = note["_time"] - int(note["_time"])
	if not self.notes[difficulty].has(beat_number):
		self.notes[difficulty][beat_number] = []
		
	# Here we can change the note data to fit our game level
	var tmp = null
	tmp = line_index_layer_to_position(note)
	note["x"] = tmp[0]
	note["y"] = tmp[1]
	note["offset"] = offset
	
	self.notes[difficulty][beat_number].append(note)
	return

func add_obstacle(difficulty, obstacle):
	if not self.obstacles.has(difficulty):
		self.obstacles[difficulty] = {}
		
	var beat_number = int(obstacle["_time"])
	var offset = obstacle["_time"] - int(obstacle["_time"])
	if not self.obstacles[difficulty].has(beat_number):
		self.obstacles[difficulty][beat_number] = []
		
	# Get obstacle data
	var x_position = obstacle["_lineIndex"]
	var bs_type = obstacle["_type"]
	var duration = obstacle["_duration"]
	var width = obstacle["_width"]
	
	# Some levels use for fx and it breaks stuff if not handled
	if duration == 0:
		return
	
	# Here we can change the obstacle data to fit our game level	
	if bs_type == OBSTACLE_TYPE["CROUCH"]:
		obstacle["type"] = "crouch"
	else:
		obstacle["type"] = "full_height"
	
	obstacle["duration"] = duration
	obstacle["width"] = width
	obstacle["offset"] = offset
	
	self.obstacles[difficulty][beat_number].append(obstacle)
	return

func add_event(difficulty, event):
	if not self.events.has(difficulty):
		self.events[difficulty] = {}
		
	var beat_number = int(event["_time"])
	var offset = event["_time"] - int(event["_time"])
	if not self.events[difficulty].has(beat_number):
		self.events[difficulty][beat_number] = []
		
	# Here we can change the note data to fit our game level
#	var tmp = null
#	tmp = line_index_layer_to_position(note)
#	note["x"] = tmp[0]
#	note["y"] = tmp[1]
	event["offset"] = offset
	
	self.events[difficulty][beat_number].append(event)
	return
