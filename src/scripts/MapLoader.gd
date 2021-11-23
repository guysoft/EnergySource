class_name Map

# Map loader
#  Usage example
#   const Map = preload("map.gd")
# 	var path = "Beat Saber (Built in)/ExpertPlus.dat"
# 	var map = Map.new(path)
# 	map.get_notes("ExpertPlus")

const BS_LEVELS = ["Easy", "NormalStandard", "Normal", "HardStandard", "Hard", "Expert", "ExpertStandard", "ExpertPlusStandard", "ExpertPlus"]

# The width from each side in the center (the total width is twice this number)
const LEVEL_WITH = 0.7
# Lowest point in the game map beneeth your center
const LEVEL_LOW = 0.5
# Highest point in the map
const LEVEL_HIGH = 1.2

var path = null
var bs_level_data = {}

var notes = {}
var next_beat_event
var note_offset = 0


# Spawning stuff TODO move to its own place

func _init(path):
	print ("loading map")
	self.path = path
	var file = File.new()
	# print(OS.get_user_data_dir())
	
	file.open(path, File.READ) 
	var level = parse_json(file.get_as_text())
	var difficulty = self.path.get_basename().get_file()
	self.bs_level_data[difficulty] = level
	# print(level)

func _on_beat_detected(difficulty, beat:int):
	# assert(typeof(beat) == TYPE_INT)
	
	# print(self.notes[difficulty])
	var return_value = []
	if self.notes.has(difficulty):
		if self.notes[difficulty].has(int(beat)):
			return self.notes[difficulty][int(beat)]
	
	return return_value

func get_notes(difficulty):
	for note in self.bs_level_data[difficulty]["_notes"]:
		# print ("adding note: ", note)
		# print ("note time:", note["_time"])
		self.add_note(difficulty, note)
	# notes = get_children()
	return
	
func obstacle_line_index_layer_to_position(obstacle):
	# index 0 to 3
	# width 0-4 (can be negative but it creates bugs in beat saber)
	# posy = 0.5 - 1.3
	# posx = -1.3 - 1.3
	
	# Left example
	# position = [-0.976259469985962,-1.29999995231628]
	var PADDING = 2
	var WALL_WIDTH = 0.5
	var position_x = (-LEVEL_WITH  + (2*LEVEL_WITH/3) * obstacle["_lineIndex"]) * PADDING - WALL_WIDTH
	
	# 0.65 because the minimal size of -1.3 + 0.65 * 4 = 1.3
	# position_x2/position_y = position_x + 0.65 * obstacle["_width"]
	var position_y = -0.976259469985962
	return [position_x, position_y]

func line_index_layer_to_position(note):
	# beat saber layer moves between 0-2
	# beat saber index moves between 0-3
	# max posy in beat saber = 0.5 - 1.0
	# max posx in beat saber = -1.3 - 1.3
	var position_x = -LEVEL_WITH + (2*LEVEL_WITH/3) * note["_lineIndex"]
	var position_y = LEVEL_LOW + (LEVEL_HIGH - LEVEL_LOW)/2 * note["_lineLayer"]
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
	note["offset"] = stepify(offset,0.05) #rounded to nearest 0.05 for timer
	
	self.notes[difficulty][beat_number].append(note)
	return


func get_obstacles(difficulty):
	for obstacle in self.bs_level_data[difficulty]["_obstacles"]:
		self.add_obstacle(difficulty, obstacle)

func add_obstacle(difficulty, obstacle):
	if not self.notes.has(difficulty):
		self.notes[difficulty] = {}
		
	var beat_number = int(obstacle["_time"])
	if not self.notes[difficulty].has(beat_number):
		self.notes[difficulty][beat_number] = []
		
	# Here we can change the note data to fit our game level
	var x = null
	var y = null
	[x, y] = obstacle_line_index_layer_to_position(obstacle)
	obstacle["x"] = x
	obstacle["y"] = y
	
	self.notes[difficulty][beat_number].append(obstacle)
	return
