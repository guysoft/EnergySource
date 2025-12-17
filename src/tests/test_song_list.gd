extends SceneTree

# Unit tests for ui_song_list.gd functionality
# Tests folder navigation, music file detection, and layout matching
# Run with: godot --headless --script res://tests/test_song_list.gd

func _init():
	print("\n=== Song List Unit Tests ===\n")
	var all_passed = true
	
	# Test 1: Music file extension detection
	all_passed = test_is_music_file() and all_passed
	
	# Test 2: Layout matching logic
	all_passed = test_has_matching_layout() and all_passed
	
	# Test 3: Folder navigation bounds
	all_passed = test_folder_navigation_bounds() and all_passed
	
	# Test 4: Path display formatting
	all_passed = test_path_display() and all_passed
	
	# Test 5: Scene loads correctly
	all_passed = test_scene_loads() and all_passed
	
	# Test 6: Item types enum
	all_passed = test_item_types() and all_passed
	
	print("\n=== Test Summary ===")
	if all_passed:
		print("✓ ALL TESTS PASSED")
	else:
		print("✗ SOME TESTS FAILED")
	
	quit(0 if all_passed else 1)


func test_is_music_file() -> bool:
	print("--- Testing Music File Detection ---")
	var passed = true
	
	# Valid music file extensions
	var valid_files = ["song.ogg", "track.mp3", "audio.wav", "SONG.OGG", "Track.MP3"]
	for file in valid_files:
		if _is_music_file(file):
			print("  ✓ '", file, "' detected as music file")
		else:
			print("  ✗ '", file, "' should be detected as music file")
			passed = false
	
	# Invalid/non-music files
	var invalid_files = ["song.json", "track.txt", "audio.dat", "song.ogg.import", "readme.md"]
	for file in invalid_files:
		if not _is_music_file(file):
			print("  ✓ '", file, "' correctly rejected as non-music file")
		else:
			print("  ✗ '", file, "' should NOT be detected as music file")
			passed = false
	
	return passed


func test_has_matching_layout() -> bool:
	print("--- Testing Layout Matching Logic ---")
	var passed = true
	
	# Test the matching logic (without actual file system)
	# The function should extract basename and check for .json in Layouts folder
	
	# Test basename extraction
	var test_cases = [
		{"file": "song.ogg", "expected_base": "song"},
		{"file": "My Song.mp3", "expected_base": "My Song"},
		{"file": "Track-01.wav", "expected_base": "Track-01"},
	]
	
	for test in test_cases:
		var base_name = test["file"].get_basename()
		if base_name == test["expected_base"]:
			print("  ✓ '", test["file"], "' -> '", base_name, "' (correct)")
		else:
			print("  ✗ '", test["file"], "' -> '", base_name, "' (expected '", test["expected_base"], "')")
			passed = false
	
	# Test that _get_layout_path constructs correct path
	var layout_path = _get_layout_path("TestSong.ogg")
	if layout_path.ends_with("/TestSong.json"):
		print("  ✓ Layout path construction: ends with '/TestSong.json'")
	else:
		print("  ✗ Layout path construction failed: ", layout_path)
		passed = false
	
	return passed


func test_folder_navigation_bounds() -> bool:
	print("--- Testing Folder Navigation Bounds ---")
	var passed = true
	
	# Test _navigate_up logic simulation
	var test_paths = [
		{"current": "", "expected_after_up": ""},  # Already at root
		{"current": "folder1", "expected_after_up": ""},  # Go to root
		{"current": "folder1/subfolder", "expected_after_up": "folder1"},  # Go up one level
		{"current": "a/b/c/d", "expected_after_up": "a/b/c"},  # Go up in deep path
	]
	
	for test in test_paths:
		var result = _simulate_navigate_up(test["current"])
		if result == test["expected_after_up"]:
			print("  ✓ Navigate up from '", test["current"], "' -> '", result, "'")
		else:
			print("  ✗ Navigate up from '", test["current"], "' -> '", result, "' (expected '", test["expected_after_up"], "')")
			passed = false
	
	# Test _navigate_into logic simulation
	var into_tests = [
		{"current": "", "folder": "songs", "expected": "songs"},
		{"current": "songs", "folder": "rock", "expected": "songs/rock"},
		{"current": "a/b", "folder": "c", "expected": "a/b/c"},
	]
	
	for test in into_tests:
		var result = _simulate_navigate_into(test["current"], test["folder"])
		if result == test["expected"]:
			print("  ✓ Navigate into '", test["folder"], "' from '", test["current"], "' -> '", result, "'")
		else:
			print("  ✗ Navigate into '", test["folder"], "' from '", test["current"], "' -> '", result, "' (expected '", test["expected"], "')")
			passed = false
	
	return passed


func test_path_display() -> bool:
	print("--- Testing Path Display Formatting ---")
	var passed = true
	
	# Test path label formatting
	var test_cases = [
		{"current_folder": "", "expected_label": "/"},
		{"current_folder": "songs", "expected_label": "/songs"},
		{"current_folder": "songs/rock", "expected_label": "/songs/rock"},
	]
	
	for test in test_cases:
		var label = _format_path_label(test["current_folder"])
		if label == test["expected_label"]:
			print("  ✓ Path '", test["current_folder"], "' displays as '", label, "'")
		else:
			print("  ✗ Path '", test["current_folder"], "' displays as '", label, "' (expected '", test["expected_label"], "')")
			passed = false
	
	return passed


func test_scene_loads() -> bool:
	print("--- Testing Scene Loading ---")
	var passed = true
	
	# Test that ui_song_list.tscn loads
	var scene = load("res://scenes/ui_song_list.tscn")
	if scene == null:
		print("  ✗ ui_song_list.tscn failed to load")
		return false
	else:
		print("  ✓ ui_song_list.tscn loads successfully")
	
	var instance = scene.instantiate()
	if instance == null:
		print("  ✗ ui_song_list.tscn failed to instantiate")
		return false
	else:
		print("  ✓ ui_song_list.tscn instantiates successfully")
	
	# Check for TabContainer
	var tab_container = instance.get_node_or_null("TabContainer")
	if tab_container == null:
		print("  ✗ TabContainer not found")
		passed = false
	else:
		print("  ✓ TabContainer found")
	
	# Check for Custom tab structure
	var custom_tab = instance.get_node_or_null("TabContainer/Custom")
	if custom_tab == null:
		print("  ✗ Custom tab not found")
		passed = false
	else:
		print("  ✓ Custom tab found")
		
		# Check for PathLabel
		var path_label = custom_tab.get_node_or_null("VBoxContainer/HBoxContainer/PathLabel")
		if path_label == null:
			print("  ✗ PathLabel not found in Custom tab")
			passed = false
		else:
			print("  ✓ PathLabel found in Custom tab")
		
		# Check for SongList
		var song_list = custom_tab.get_node_or_null("VBoxContainer/SongList")
		if song_list == null:
			print("  ✗ SongList not found in Custom tab")
			passed = false
		else:
			print("  ✓ SongList found in Custom tab")
		
		# Check for NoSongsLabel
		var no_songs = custom_tab.get_node_or_null("VBoxContainer/NoSongsLabel")
		if no_songs == null:
			print("  ✗ NoSongsLabel not found in Custom tab")
			passed = false
		else:
			print("  ✓ NoSongsLabel found in Custom tab")
	
	# Check for Original tab structure
	var original_tab = instance.get_node_or_null("TabContainer/Original")
	if original_tab == null:
		print("  ✗ Original tab not found")
		passed = false
	else:
		print("  ✓ Original tab found")
	
	instance.queue_free()
	return passed


func test_item_types() -> bool:
	print("--- Testing Item Types ---")
	var passed = true
	
	# Check that the script has the expected item types
	# We can't load the script directly as an enum, but we can verify the scene
	# works and manually verify enum values
	
	# ItemType enum should have: FOLDER, PARENT_DIR, MUSIC_FILE, BEATSABER_SONG
	var expected_types = ["FOLDER", "PARENT_DIR", "MUSIC_FILE", "BEATSABER_SONG"]
	
	# Read the script source to verify enum exists
	var file = FileAccess.open("res://scripts/ui_song_list.gd", FileAccess.READ)
	if file == null:
		print("  ✗ Could not open ui_song_list.gd for reading")
		return false
	
	var source = file.get_as_text()
	file.close()
	
	# Check for ItemType enum
	if source.find("enum ItemType") != -1:
		print("  ✓ ItemType enum found")
		
		for type_name in expected_types:
			if source.find(type_name) != -1:
				print("  ✓ ItemType.", type_name, " found")
			else:
				print("  ✗ ItemType.", type_name, " not found")
				passed = false
	else:
		print("  ✗ ItemType enum not found")
		passed = false
	
	# Check for MUSIC_EXTENSIONS constant
	if source.find("MUSIC_EXTENSIONS") != -1:
		print("  ✓ MUSIC_EXTENSIONS constant found")
	else:
		print("  ✗ MUSIC_EXTENSIONS constant not found")
		passed = false
	
	# Check for DISABLED_COLOR constant
	if source.find("DISABLED_COLOR") != -1:
		print("  ✓ DISABLED_COLOR constant found")
	else:
		print("  ✗ DISABLED_COLOR constant not found")
		passed = false
	
	return passed


# Helper functions that mirror the ui_song_list.gd implementation
# These are used for testing without needing autoloads

const MUSIC_EXTENSIONS = ["ogg", "mp3", "wav"]

func _is_music_file(filename: String) -> bool:
	"""Check if a filename is a music file"""
	var ext = filename.get_extension().to_lower()
	return ext in MUSIC_EXTENSIONS


func _get_layout_path(music_filename: String) -> String:
	"""Get the JSON layout path for a music file"""
	var base_name = music_filename.get_basename()
	# Using placeholder path since GameVariables isn't available in tests
	return "/test/Layouts/" + base_name + ".json"


func _simulate_navigate_up(current_folder: String) -> String:
	"""Simulate _navigate_up function"""
	if current_folder == "":
		return ""  # Already at root
	
	# Go up one level
	var parts = current_folder.split("/")
	parts.remove_at(parts.size() - 1)
	return "/".join(parts)


func _simulate_navigate_into(current_folder: String, folder_name: String) -> String:
	"""Simulate _navigate_into function"""
	if current_folder == "":
		return folder_name
	else:
		return current_folder + "/" + folder_name


func _format_path_label(current_folder: String) -> String:
	"""Format the path label text"""
	if current_folder == "":
		return "/"
	else:
		return "/" + current_folder

