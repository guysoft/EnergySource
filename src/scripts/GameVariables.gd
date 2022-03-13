extends Node

const UI_PIXELS_TO_METER = 1.0 / 512


# Don't edit
export var vr_enabled = false

var ENABLE_VR = true

# Enable or disable to let non-vr mode move with up/right/left/down keys
var NON_VR_MOVEMENT = false

## In game variables

# The path os the song to play
var path = null
# The difficulty to load
var difficulty = null

# Defalt location of songs
var internal_songs_path:String = ""
var custom_songs_path:String = ""
var song_selected

var custom_levels_foldername = "Levels"

func _ready():
	var dir = ""
	if OS.get_name() == "HTML5":
		dir = "res:/"
	else:
		if OS.has_feature("editor"):
			print ("editor build")
			dir = ProjectSettings.globalize_path("res://").get_base_dir()
			self.internal_songs_path = dir + "/" + custom_levels_foldername
			self.custom_songs_path = ""
		else:
			print ("export build")
			dir = OS.get_executable_path().get_base_dir()
			self.internal_songs_path = ProjectSettings.globalize_path("res:/").get_base_dir() + "/" + custom_levels_foldername
			self.custom_songs_path = "user://Levels"

	print ("internal path: ", self.internal_songs_path)
	print ("custom path: ", self.custom_songs_path)
	
	#Check to see if the songs_path directory exists, if not create the directory
	var chk_dir = Directory.new()
	if not chk_dir.dir_exists(GameVariables.custom_songs_path):
		print ("custom levels folder doesn't exist! Creating...")
		chk_dir.make_dir(GameVariables.custom_songs_path)
	
	self.path = dir + "/Levels/test"
	self.difficulty = "ExpertPlusStandard"


