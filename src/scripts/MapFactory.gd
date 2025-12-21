class_name MapFactory

# Factory for creating map loaders based on the level format
# Supports both Beat Saber (folder with info.dat) and PowerBeatsVR (JSON file) formats

# Preload scripts to ensure they're available (class_name may not work in all contexts)
const PowerBeatsVRMapScript = preload("res://scripts/PowerBeatsVRMap.gd")

enum MapFormat {
	BEAT_SABER,      # Folder containing info.dat and difficulty .dat files
	POWER_BEATS_VR,  # Single JSON file with all data
	UNKNOWN
}


static func detect_format(path: String) -> MapFormat:
	# Check for Beat Saber format (folder with info.dat)
	if DirAccess.dir_exists_absolute(path):
		if FileAccess.file_exists(path + "/info.dat") or FileAccess.file_exists(path + "/Info.dat"):
			return MapFormat.BEAT_SABER
	
	# Check for PowerBeatsVR format: music file (.ogg, .mp3, .wav)
	var ext = path.get_extension().to_lower()
	if ext in ["ogg", "mp3", "wav"] and FileAccess.file_exists(path):
		return MapFormat.POWER_BEATS_VR
	
	# Check for PowerBeatsVR format: JSON layout file (backwards compat)
	if path.ends_with(".json") and FileAccess.file_exists(path):
		return MapFormat.POWER_BEATS_VR
	
	return MapFormat.UNKNOWN


static func create_map(path: String):
	# Create and return the appropriate map loader based on detected format
	var format = detect_format(path)
	
	match format:
		MapFormat.BEAT_SABER:
			print("MapFactory: Creating Beat Saber map for: " + path)
			return Map.new(path)
		MapFormat.POWER_BEATS_VR:
			var layout_path = path
			var music_path = ""
			
			# If path is a music file, derive the layout path from it
			var ext = path.get_extension().to_lower()
			if ext in ["ogg", "mp3", "wav"]:
				music_path = path
				var song_name = path.get_file().get_basename()
				layout_path = GameVariables.pbvr_layouts_path + "/" + song_name + ".json"
				print("MapFactory: Creating PowerBeatsVR map from music file: " + path)
				print("MapFactory: Derived layout path: " + layout_path)
			else:
				print("MapFactory: Creating PowerBeatsVR map for: " + path)
			
			var map = PowerBeatsVRMapScript.new(layout_path)
			if music_path != "":
				map.music_path = music_path
			return map
		_:
			push_error("MapFactory: Unknown map format for path: " + path)
			return null


static func get_format_name(format: MapFormat) -> String:
	match format:
		MapFormat.BEAT_SABER:
			return "Beat Saber"
		MapFormat.POWER_BEATS_VR:
			return "PowerBeatsVR"
		_:
			return "Unknown"

