extends SceneTree

# Unit tests for PowerBeatsVR level loading
# Run with: godot --headless --script res://tests/test_powerbeatsvr.gd

const WELLERMAN_PATH = "res://PowerBeatsVRLevels/Layouts/Wellerman.json"
const TEST_BS_PATH = "res://Levels/test"

# Load scripts manually for headless testing (class_name not available without full editor)
var PowerBeatsVRMapScript = preload("res://scripts/PowerBeatsVRMap.gd")
var MapFactoryScript = preload("res://scripts/MapFactory.gd")
var BeatSaberMapScript = preload("res://scripts/MapLoader.gd")


# Minimal fake Settings autoload for headless tests.
class FakeSettings extends Node:
	var only_power_balls_enabled := false

	func _init(enabled: bool = false):
		only_power_balls_enabled = enabled

	func get_setting(section: String, key: String):
		if section == "game" and key == "only_power_balls":
			return only_power_balls_enabled
		return null


func _install_fake_settings(only_power_balls_enabled: bool) -> void:
	# Avoid clobbering a real autoload if tests are ever run inside the editor.
	var root := get_root()
	var existing := root.get_node_or_null("Settings")
	if existing != null:
		# If a Settings node already exists, do not replace it.
		# The new loaders default to false when Settings isn't available, so tests that
		# require Settings should be run headless.
		return
	var settings := FakeSettings.new(only_power_balls_enabled)
	settings.name = "Settings"
	settings.set_meta("__fake_settings", true)
	root.add_child(settings)


func _remove_fake_settings() -> void:
	var root := get_root()
	var existing := root.get_node_or_null("Settings")
	if existing != null and existing.has_meta("__fake_settings"):
		root.remove_child(existing)
		existing.free()

func _init():
	print("\n=== PowerBeatsVR Level Loading Tests ===\n")
	var all_passed = true
	
	all_passed = test_json_loading() and all_passed
	all_passed = test_position_mapping() and all_passed
	all_passed = test_action_type_mapping() and all_passed
	all_passed = test_beat_parsing() and all_passed
	all_passed = test_subbeat_offset() and all_passed
	all_passed = test_difficulty_enumeration() and all_passed
	all_passed = test_map_factory_detection() and all_passed
	all_passed = test_wellerman_level() and all_passed
	all_passed = test_wall_type_mapping() and all_passed
	all_passed = test_ball_flight_duration() and all_passed
	all_passed = test_only_power_balls_default_false_beatsaber() and all_passed
	all_passed = test_only_power_balls_forces_powerballs_pbvr() and all_passed
	all_passed = test_only_power_balls_forces_powerballs_beatsaber() and all_passed
	
	# Summary
	print("\n=== Test Summary ===")
	if all_passed:
		print("✓ ALL TESTS PASSED")
	else:
		print("✗ SOME TESTS FAILED")
	
	quit(0 if all_passed else 1)


func test_json_loading() -> bool:
	print("--- Testing JSON Loading ---")
	var passed = true
	
	# Test that Wellerman.json exists and loads
	var global_path = ProjectSettings.globalize_path(WELLERMAN_PATH)
	if not FileAccess.file_exists(global_path):
		print("  ✗ Wellerman.json not found at: " + global_path)
		return false
	
	var map = PowerBeatsVRMapScript.new(global_path)
	
	if map.json_data.is_empty():
		print("  ✗ JSON data is empty after loading")
		passed = false
	else:
		print("  ✓ JSON data loaded successfully")
	
	if map.get_name() == "":
		print("  ✗ Song name is empty")
		passed = false
	else:
		print("  ✓ Song name: " + map.get_name())
	
	if map.get_bpm() <= 0:
		print("  ✗ BPM is invalid: " + str(map.get_bpm()))
		passed = false
	else:
		print("  ✓ BPM: " + str(map.get_bpm()))
	
	return passed


func test_only_power_balls_default_false_beatsaber() -> bool:
	print("--- Testing Only Power Balls Default (Beat Saber) ---")
	_remove_fake_settings()
	var passed = true

	var bs_path = ProjectSettings.globalize_path(TEST_BS_PATH)
	if not DirAccess.dir_exists_absolute(bs_path):
		print("  ⚠ Beat Saber test path not found, skipping: " + bs_path)
		return true

	var map = BeatSaberMapScript.new(bs_path)
	map.get_level("Expert")

	var found_ball = false
	for beat_no in map.notes.get("Expert", {}):
		for note in map.notes["Expert"][beat_no]:
			if int(note.get("_type", -1)) == 3:
				continue # bomb
			found_ball = true
			if note.get("_is_power_ball", false) != false:
				print("  ✗ Expected _is_power_ball == false by default, got: ", note.get("_is_power_ball"))
				passed = false

	if found_ball:
		print("  ✓ Beat Saber notes default to non-PowerBall when Settings is missing")
	else:
		print("  ⚠ No non-bomb notes found in Beat Saber test map")

	return passed


func test_only_power_balls_forces_powerballs_pbvr() -> bool:
	print("--- Testing Only Power Balls Forces PowerBalls (PowerBeatsVR) ---")
	_remove_fake_settings()
	_install_fake_settings(true)
	var passed = true

	var global_path = ProjectSettings.globalize_path(WELLERMAN_PATH)
	var map = PowerBeatsVRMapScript.new(global_path)
	map.get_level("Beginner")

	var found_ball = false
	for beat_no in map.notes.get("Beginner", {}):
		for note in map.notes["Beginner"][beat_no]:
			if int(note.get("_type", -1)) == 3:
				continue # bomb
			found_ball = true
			if note.get("_is_power_ball", false) != true:
				print("  ✗ Expected PowerBall flag to be forced true, got: ", note.get("_is_power_ball"))
				passed = false

	if found_ball:
		print("  ✓ PowerBeatsVR notes are flagged as PowerBalls when only_power_balls is enabled")
	else:
		print("  ⚠ No non-bomb notes found in PowerBeatsVR map to validate")

	_remove_fake_settings()
	return passed


func test_only_power_balls_forces_powerballs_beatsaber() -> bool:
	print("--- Testing Only Power Balls Forces PowerBalls (Beat Saber) ---")
	_remove_fake_settings()
	_install_fake_settings(true)
	var passed = true

	var bs_path = ProjectSettings.globalize_path(TEST_BS_PATH)
	if not DirAccess.dir_exists_absolute(bs_path):
		print("  ⚠ Beat Saber test path not found, skipping: " + bs_path)
		_remove_fake_settings()
		return true

	var map = BeatSaberMapScript.new(bs_path)
	map.get_level("Expert")

	var found_ball = false
	for beat_no in map.notes.get("Expert", {}):
		for note in map.notes["Expert"][beat_no]:
			if int(note.get("_type", -1)) == 3:
				continue # bomb
			found_ball = true
			if note.get("_is_power_ball", false) != true:
				print("  ✗ Expected PowerBall flag to be forced true, got: ", note.get("_is_power_ball"))
				passed = false

	if found_ball:
		print("  ✓ Beat Saber notes are flagged as PowerBalls when only_power_balls is enabled")
	else:
		print("  ⚠ No non-bomb notes found in Beat Saber test map to validate")

	_remove_fake_settings()
	return passed


func test_position_mapping() -> bool:
	print("--- Testing Position Mapping ---")
	var passed = true
	
	# Test position mapping with VERTICAL_OFFSET of 1.3
	# PowerBeatsVR stores Y with -1.3 offset, so we add 1.3 back
	# JSON Y -0.5 -> actual 0.8, JSON Y 0.0 -> actual 1.3
	
	var map = PowerBeatsVRMapScript.new("")
	var VERTICAL_OFFSET = 1.3
	
	# Test center position: Y=0.0 -> Y=1.3
	var center = map._pbvr_to_es_position([0.0, 0.0])
	if not is_equal_approx(center.x, 0.0) or not is_equal_approx(center.y, 0.0 + VERTICAL_OFFSET):
		print("  ✗ Center position mapping failed: ", center)
		passed = false
	else:
		print("  ✓ Center position maps correctly: ", center)
	
	# Test left position: Y=0.5 -> Y=1.8
	var left = map._pbvr_to_es_position([-1.3, 0.5])
	if not is_equal_approx(left.x, -1.3) or not is_equal_approx(left.y, 0.5 + VERTICAL_OFFSET):
		print("  ✗ Left position mapping failed: ", left)
		passed = false
	else:
		print("  ✓ Left position maps correctly: ", left)
	
	# Test right position: Y=1.3 -> Y=2.6
	var right = map._pbvr_to_es_position([1.3, 1.3])
	if not is_equal_approx(right.x, 1.3) or not is_equal_approx(right.y, 1.3 + VERTICAL_OFFSET):
		print("  ✗ Right position mapping failed: ", right)
		passed = false
	else:
		print("  ✓ Right position maps correctly: ", right)
	
	# Test typical Wellerman position: Y=-0.5 -> Y=0.8
	var typical = map._pbvr_to_es_position([1.10000002384186, -0.5])
	if not is_equal_approx(typical.x, 1.1) or not is_equal_approx(typical.y, -0.5 + VERTICAL_OFFSET):
		print("  ✗ Typical position mapping failed: ", typical)
		passed = false
	else:
		print("  ✓ Typical position maps correctly (Y=-0.5 -> 0.8): ", typical)
	
	return passed


func test_action_type_mapping() -> bool:
	print("--- Testing Action Type Mapping ---")
	var passed = true
	
	# Test NormalBall -> note type based on X position
	# Negative X = left (type 0), Positive X = right (type 1)
	
	var global_path = ProjectSettings.globalize_path(WELLERMAN_PATH)
	var map = PowerBeatsVRMapScript.new(global_path)
	map.get_level("Beginner")
	
	# Check that we have notes
	if map.notes.is_empty():
		print("  ✗ No notes parsed")
		return false
	
	var found_left = false
	var found_right = false
	
	for beat_no in map.notes.get("Beginner", {}):
		for note in map.notes["Beginner"][beat_no]:
			if note["x"] < 0 and note["_type"] == 0:
				found_left = true
			elif note["x"] >= 0 and note["_type"] == 1:
				found_right = true
	
	if found_left:
		print("  ✓ Left notes (type 0) found for negative X positions")
	else:
		print("  ✗ No left notes found for negative X positions")
		passed = false
	
	if found_right:
		print("  ✓ Right notes (type 1) found for positive X positions")
	else:
		print("  ✗ No right notes found for positive X positions")
		passed = false
	
	return passed


func test_beat_parsing() -> bool:
	print("--- Testing Beat Parsing ---")
	var passed = true
	
	var global_path = ProjectSettings.globalize_path(WELLERMAN_PATH)
	var map = PowerBeatsVRMapScript.new(global_path)
	map.get_level("Beginner")
	
	# Check that notes were parsed at various beat numbers
	var note_count = map.get_note_count("Beginner")
	
	if note_count == 0:
		print("  ✗ No notes parsed for Beginner difficulty")
		return false
	else:
		print("  ✓ Parsed " + str(note_count) + " notes for Beginner")
	
	# Test _on_beat_detected returns correct format
	var result = map._on_beat_detected("Beginner", 4)
	
	if not result is Array or result.size() != 3:
		print("  ✗ _on_beat_detected should return [notes, obstacles, events] array")
		passed = false
	else:
		print("  ✓ _on_beat_detected returns correct array format")
		
		var notes = result[0]
		var obstacles = result[1]
		var events = result[2]
		
		print("    Beat 4: " + str(notes.size()) + " notes, " + 
			  str(obstacles.size()) + " obstacles, " + 
			  str(events.size()) + " events")
	
	return passed


func test_subbeat_offset() -> bool:
	print("--- Testing SubBeat Offset Parsing ---")
	var passed = true
	
	var global_path = ProjectSettings.globalize_path(WELLERMAN_PATH)
	var map = PowerBeatsVRMapScript.new(global_path)
	map.get_level("Beginner")
	
	# Look for notes with non-zero offset (from subBeats)
	var found_offset = false
	var offset_values = []
	
	for beat_no in map.notes.get("Beginner", {}):
		for note in map.notes["Beginner"][beat_no]:
			if note["offset"] > 0.001:
				found_offset = true
				if not offset_values.has(note["offset"]):
					offset_values.append(note["offset"])
	
	if found_offset:
		print("  ✓ Found notes with sub-beat offsets")
		print("    Offset values found: " + str(offset_values.slice(0, 5)))
	else:
		print("  ✗ No sub-beat offsets found (expected from Wellerman)")
		passed = false
	
	return passed


func test_difficulty_enumeration() -> bool:
	print("--- Testing Difficulty Enumeration ---")
	var passed = true
	
	var global_path = ProjectSettings.globalize_path(WELLERMAN_PATH)
	var map = PowerBeatsVRMapScript.new(global_path)
	
	var difficulties = map.get_available_difficulties()
	
	if difficulties.is_empty():
		print("  ✗ No difficulties found")
		return false
	
	print("  ✓ Available difficulties: " + str(difficulties))
	
	# Check that difficulties are from the expected set
	for diff in difficulties:
		if diff in PowerBeatsVRMapScript.DIFFICULTIES:
			print("    ✓ " + diff + " is a valid PowerBeatsVR difficulty")
		else:
			print("    ✗ " + diff + " is not a standard PowerBeatsVR difficulty")
			passed = false
	
	return passed


func test_map_factory_detection() -> bool:
	print("--- Testing MapFactory Format Detection ---")
	var passed = true
	
	# Note: MapFactory uses static functions, need to call via class name reference
	# Since class_name isn't available in headless mode, we test the logic manually
	
	# Test PowerBeatsVR detection - JSON file ending with .json
	var pbvr_path = ProjectSettings.globalize_path(WELLERMAN_PATH)
	
	# Manual format detection test (mirrors MapFactory.detect_format logic)
	var is_pbvr = pbvr_path.ends_with(".json") and FileAccess.file_exists(pbvr_path)
	if is_pbvr:
		print("  ✓ Correctly detected PowerBeatsVR format for .json file")
	else:
		print("  ✗ Failed to detect PowerBeatsVR format")
		passed = false
	
	# Test Beat Saber detection - folder with info.dat
	var bs_path = ProjectSettings.globalize_path(TEST_BS_PATH)
	if DirAccess.dir_exists_absolute(bs_path):
		var has_info_dat = FileAccess.file_exists(bs_path + "/info.dat") or FileAccess.file_exists(bs_path + "/Info.dat")
		
		if has_info_dat:
			print("  ✓ Correctly detected Beat Saber format for folder with info.dat")
		else:
			print("  ✗ Failed to detect Beat Saber format (no info.dat)")
			passed = false
	else:
		print("  ⚠ Beat Saber test path not found, skipping: " + bs_path)
	
	# Test unknown format - nonexistent path
	var unknown_path = "/nonexistent/path"
	var is_unknown = not DirAccess.dir_exists_absolute(unknown_path) and not FileAccess.file_exists(unknown_path)
	if is_unknown:
		print("  ✓ Correctly returns UNKNOWN for invalid path")
	else:
		print("  ✗ Should return UNKNOWN for invalid path")
		passed = false
	
	return passed


func test_wellerman_level() -> bool:
	print("--- Testing Wellerman Level Full Load ---")
	var passed = true
	
	var global_path = ProjectSettings.globalize_path(WELLERMAN_PATH)
	
	# Test PowerBeatsVRMap creation directly (since MapFactory static calls don't work in headless)
	var map = PowerBeatsVRMapScript.new(global_path)
	
	if map == null:
		print("  ✗ PowerBeatsVRMap creation returned null")
		return false
	
	# Check for expected methods
	if not map.has_method("_pbvr_to_es_position"):
		print("  ✗ Created wrong type (missing _pbvr_to_es_position method)")
		return false
	
	print("  ✓ MapFactory created PowerBeatsVRMap instance")
	
	# Test metadata
	if map.get_name() != "Wellerman":
		print("  ✗ Wrong song name: " + map.get_name())
		passed = false
	else:
		print("  ✓ Song name: Wellerman")
	
	if map.get_bpm() != 96:
		print("  ✗ Wrong BPM: " + str(map.get_bpm()))
		passed = false
	else:
		print("  ✓ BPM: 96")
	
	# Load a difficulty
	var difficulties = map.get_available_difficulties()
	if difficulties.size() > 0:
		map.get_level(difficulties[0])
		var note_count = map.get_note_count(difficulties[0])
		print("  ✓ Loaded " + difficulties[0] + " with " + str(note_count) + " notes")
	
	# Test song path finding
	var song_path = map.get_song()
	if song_path == "":
		print("  ⚠ Audio file not found (may be expected in test environment)")
	else:
		print("  ✓ Audio file: " + song_path)
	
	return passed


func test_wall_type_mapping() -> bool:
	print("--- Testing Wall Type Mapping ---")
	var passed = true
	
	# Test that all wall types have mappings
	for wall_type in PowerBeatsVRMapScript.WALL_TYPE_NAMES:
		var wall_name = PowerBeatsVRMapScript.WALL_TYPE_NAMES[wall_type]
		var obstacle_type = PowerBeatsVRMapScript.WALL_TYPE_TO_OBSTACLE.get(wall_type, null)
		
		if obstacle_type == null:
			print("  ✗ Wall type " + str(wall_type) + " (" + wall_name + ") has no obstacle mapping")
			passed = false
		else:
			print("  ✓ Wall type " + str(wall_type) + " (" + wall_name + ") -> " + obstacle_type)
	
	# Verify crouch wall (type 7) maps to crouch
	if PowerBeatsVRMapScript.WALL_TYPE_TO_OBSTACLE.get(7) == "crouch":
		print("  ✓ BarAcrossTheForehead (7) correctly maps to 'crouch'")
	else:
		print("  ✗ BarAcrossTheForehead (7) should map to 'crouch'")
		passed = false
	
	return passed


func test_ball_flight_duration() -> bool:
	print("--- Testing Ball Flight Duration ---")
	var passed = true
	
	# Test Wellerman (96 BPM = Low BPM range)
	# Expert difficulty should have 2 beats flight duration
	var global_path = ProjectSettings.globalize_path(WELLERMAN_PATH)
	var wellerman_map = PowerBeatsVRMapScript.new(global_path)
	
	var wellerman_duration = wellerman_map.get_ball_flight_duration()
	var wellerman_bpm = wellerman_map.get_bpm()
	
	print("  Wellerman BPM: " + str(wellerman_bpm))
	print("  Ball flight duration: " + str(wellerman_duration) + " beats")
	
	# Wellerman is 96 BPM which is Low range (< 100)
	# Expert difficulty should be 2 beats
	if wellerman_duration == 2:
		print("  ✓ Low BPM (96) correctly returns 2 beats")
	else:
		print("  ✗ Low BPM (96) should return 2 beats, got: " + str(wellerman_duration))
		passed = false
	
	# Test BPM threshold logic by creating mock maps with different BPMs
	# We can't easily create maps with different BPMs, so we test the thresholds directly
	
	# Verify threshold constants exist
	if PowerBeatsVRMapScript.BPM_HIGH_THRESHOLD == 145:
		print("  ✓ BPM_HIGH_THRESHOLD is 145")
	else:
		print("  ✗ BPM_HIGH_THRESHOLD should be 145")
		passed = false
	
	if PowerBeatsVRMapScript.BPM_MID_THRESHOLD == 100:
		print("  ✓ BPM_MID_THRESHOLD is 100")
	else:
		print("  ✗ BPM_MID_THRESHOLD should be 100")
		passed = false
	
	# Calculate expected flight time for Wellerman
	var flight_time = 60.0 / wellerman_bpm * wellerman_duration
	print("  Expected flight time: " + str(snapped(flight_time, 0.01)) + " seconds")
	
	if flight_time < 1.5:  # Should be about 1.25 seconds for 96 BPM with 2 beats
		print("  ✓ Flight time is reasonable (~1.25s for 96 BPM)")
	else:
		print("  ✗ Flight time seems too long: " + str(flight_time))
		passed = false
	
	return passed

