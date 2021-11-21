class_name Map

# Map loader
#  Usage example
#   const Map = preload("map.gd")
# 	var path = "Beat Saber (Built in)/ExpertPlus.dat"
# 	var map = Map.new(path)
# 	map.get_notes("ExpertPlus")

const BS_LEVELS = ["Easy", "NormalStandard", "Normal", "HardStandard", "Hard", "Expert", "ExpertStandard", "ExpertPlusStandard", "ExpertPlus"]

var path = null
var bs_level_data = {}

func _init(path):
	self.path = path
	var file = File.new()
	# print(OS.get_user_data_dir())
	
	file.open(path, File.READ) 
	var level = parse_json(file.get_as_text())
	var difficulty = self.path.get_basename().get_file()
	self.bs_level_data[difficulty] = level
	
func get_notes(difficulty):
	for note in self.bs_level_data[difficulty]["_notes"]:
		self.add_note(difficulty, note)
	
	return

func add_note(level, note):
	print("Implement me")
	return
	
