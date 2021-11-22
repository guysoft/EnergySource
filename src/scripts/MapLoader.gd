extends Spatial
class_name Map

# Map loader
#  Usage example
#   const Map = preload("map.gd")
# 	var path = "Beat Saber (Built in)/ExpertPlus.dat"
# 	var map = Map.new(path)
# 	map.get_notes("ExpertPlus")

export(PackedScene) var note_object
export(NodePath) onready var beat_player = get_node(beat_player) as BeatPlayer



const BS_LEVELS = ["Easy", "NormalStandard", "Normal", "HardStandard", "Hard", "Expert", "ExpertStandard", "ExpertPlusStandard", "ExpertPlus"]

var path = null
var bs_level_data = {}

var notes = null
var next_beat_event
var note_offset = 0


# Spawning stuff TODO move to its own place

onready var bounding_box = bounding_box

#Does this need be unique? Consider moving to a utility singleton
onready var _rand = RandomNumberGenerator.new()

func _ready():
	beat_player.connect("beat", self, "_on_beat_detected")

func _on_beat_detected(beat):
	if not notes:
		return
	if note_offset>notes.size():
		return
	
	if notes[note_offset]._time<=beat:
		notes[note_offset].activate()
		note_offset+=1

func load_map(path):
	print ("loading map")
	self.path = path
	var file = File.new()
	# print(OS.get_user_data_dir())
	
	file.open(path, File.READ) 
	var level = parse_json(file.get_as_text())
	var difficulty = self.path.get_basename().get_file()
	self.bs_level_data[difficulty] = level
	print (level)

func get_notes(difficulty):
	for note in self.bs_level_data[difficulty]["_notes"]:
		print ("adding note: ", note)
		print ("note time:", note["_time"])
		self.add_note(difficulty, note)
	notes = get_children()
	
	return

func get_obstacles(difficulty):
	for obstacle in self.bs_level_data[difficulty]["_obstacles"]:
		self.add_obstacle(difficulty, obstacle)
	
func add_note(level, note):
	#print("Implement me")
	if not level or not note:
		return
		
	if note_object:
		
		_rand.randomize()
		
		var wall_size = 1
		
		var note_instance = note_object.instance() as Note
		
		note_instance.transform.origin = Vector3(
		_rand.randf_range(-wall_size, wall_size),
		_rand.randf_range(0.5, 2),
		- 2
	)
	
		add_child(note_instance)
		note_instance.setup_note(note)
	return

func add_obstacle(level,obstacle):
	print ("Implement me")
	return
