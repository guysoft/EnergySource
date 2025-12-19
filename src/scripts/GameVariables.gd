extends Node

const UI_PIXELS_TO_METER = 1.0 / 512


# Don't edit
@export var vr_enabled = false

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

# PowerBeatsVR level paths
var pbvr_layouts_path: String = ""
var pbvr_music_path: String = ""
var pbvr_levels_foldername = "PowerBeatsVRLevels"

func _ready():
	var dir = ""
	var project_dir = ""  # The res:// directory (where project.godot is)
	var parent_dir = ""   # Parent of project dir (where PowerBeatsVRLevels is)
	
	if OS.get_name() == "HTML5":
		dir = "res:/"
		project_dir = dir
		parent_dir = dir
	elif OS.get_name() == "Android":
		# On Android/Quest, use the app's external storage directory
		# This allows music to be sideloaded via adb push
		print("Android/Quest build")
		var internal_data_dir = OS.get_user_data_dir()  # /data/data/<package>/files (internal)
		var external_storage = "/storage/emulated/0"  # Standard Android external storage
		# External app data dir (accessible via adb push)
		var external_data_dir = external_storage + "/Android/data/com.tempovr.game/files"
		
		project_dir = internal_data_dir
		
		# Check multiple possible locations for PowerBeatsVRLevels
		# Priority order:
		# 1. External app data dir (adb pushable): /storage/emulated/0/Android/data/com.tempovr.game/files/
		# 2. Internal app data dir: /data/data/com.tempovr.game/files/
		# 3. Root of external storage: /storage/emulated/0/
		print("Checking for PowerBeatsVRLevels...")
		print("  External data dir: ", external_data_dir)
		print("  Internal data dir: ", internal_data_dir)
		
		if DirAccess.dir_exists_absolute(external_data_dir + "/" + pbvr_levels_foldername):
			parent_dir = external_data_dir
			print("Found PowerBeatsVRLevels in external app data dir")
		elif DirAccess.dir_exists_absolute(internal_data_dir + "/" + pbvr_levels_foldername):
			parent_dir = internal_data_dir
			print("Found PowerBeatsVRLevels in internal app data dir")
		elif DirAccess.dir_exists_absolute(external_storage + "/" + pbvr_levels_foldername):
			parent_dir = external_storage
			print("Found PowerBeatsVRLevels in external storage root")
		else:
			# Default to external app data dir - user will need to create folder via adb
			parent_dir = external_data_dir
			print("PowerBeatsVRLevels not found, defaulting to: ", parent_dir)
		
		dir = project_dir
		self.internal_songs_path = internal_data_dir + "/" + custom_levels_foldername
		self.custom_songs_path = external_data_dir + "/" + custom_levels_foldername
	else:
		if OS.has_feature("editor"):
			print ("editor build")
			project_dir = ProjectSettings.globalize_path("res://")
			# Remove trailing slash if present, then get parent
			if project_dir.ends_with("/"):
				project_dir = project_dir.substr(0, project_dir.length() - 1)
			parent_dir = project_dir.get_base_dir()
			dir = project_dir
			self.internal_songs_path = project_dir + "/" + custom_levels_foldername
			self.custom_songs_path = ""
		else:
			print ("export build")
			dir = OS.get_executable_path().get_base_dir()
			project_dir = dir
			parent_dir = dir  # For exports, PowerBeatsVRLevels should be next to the executable
			self.internal_songs_path = dir + "/" + custom_levels_foldername
			self.custom_songs_path = dir + "/" + custom_levels_foldername

	print ("project path: ", project_dir)
	print ("parent path: ", parent_dir)
	print ("internal path: ", self.internal_songs_path)
	print ("custom path: ", self.custom_songs_path)
	
	#Check to see if the songs_path directory exists, if not create the directory
	if self.custom_songs_path != "" and not DirAccess.dir_exists_absolute(self.custom_songs_path):
		print ("custom levels folder doesn't exist! Creating...")
		DirAccess.make_dir_absolute(self.custom_songs_path)
	
	# Setup PowerBeatsVR paths - located in parent directory (outside src/)
	var pbvr_base = parent_dir + "/" + pbvr_levels_foldername
	self.pbvr_layouts_path = pbvr_base + "/Layouts"
	self.pbvr_music_path = pbvr_base + "/music"
	print ("PowerBeatsVR layouts path: ", self.pbvr_layouts_path)
	print ("PowerBeatsVR music path: ", self.pbvr_music_path)
	
	self.path = project_dir + "/Levels/test"
	self.difficulty = "Expert"
