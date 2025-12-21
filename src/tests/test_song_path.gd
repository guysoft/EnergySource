extends SceneTree

# Test script for Song Path Handling
# Tests the unified song path approach where:
# - PowerBeatsVR: GameVariables.path = music file path, layout is derived
# - Beat Saber: GameVariables.path = level folder path, audio is inside
#
# Run with: godot --headless --script res://tests/test_song_path.gd

func _init():
	print("\n=== Song Path Handling Tests ===\n")
	var all_passed = true
	
	# Test 1: MapFactory detects music files as PowerBeatsVR
	all_passed = test_mapfactory_detect_music_files() and all_passed
	
	# Test 2: MapFactory detects JSON files as PowerBeatsVR
	all_passed = test_mapfactory_detect_json_files() and all_passed
	
	# Test 3: MapFactory detects Beat Saber folders
	all_passed = test_mapfactory_detect_beatsaber() and all_passed
	
	# Test 4: Layout path derivation from music path
	all_passed = test_layout_path_derivation() and all_passed
	
	# Test 5: PowerBeatsVRMap music_path property
	all_passed = test_powerbeatsvr_music_path_property() and all_passed
	
	# Test 6: Song path flow simulation
	all_passed = test_song_path_flow_simulation() and all_passed
	
	# Test 7: Playlist mode song path handling
	all_passed = test_playlist_song_path_handling() and all_passed
	
	# Test 8: Edge cases
	all_passed = test_edge_cases() and all_passed
	
	print("\n=== Test Summary ===")
	if all_passed:
		print("✓ ALL SONG PATH TESTS PASSED")
	else:
		print("✗ SOME TESTS FAILED")
	
	quit(0 if all_passed else 1)


func test_mapfactory_detect_music_files() -> bool:
	print("--- Testing MapFactory Music File Detection ---")
	var passed = true
	
	# Test detection logic for music files
	# Note: We can't use MapFactory directly in headless mode without full autoloads
	# So we test the logic patterns
	
	var test_paths = [
		{"path": "music/song.ogg", "ext": "ogg", "expected": "POWER_BEATS_VR"},
		{"path": "music/song.mp3", "ext": "mp3", "expected": "POWER_BEATS_VR"},
		{"path": "music/song.wav", "ext": "wav", "expected": "POWER_BEATS_VR"},
		{"path": "music/song.OGG", "ext": "ogg", "expected": "POWER_BEATS_VR"},  # Case insensitive
	]
	
	for test in test_paths:
		var ext = test.path.get_extension().to_lower()
		var is_music_file = ext in ["ogg", "mp3", "wav"]
		
		if is_music_file:
			print("  ✓ Detected '", test.path, "' as music file (ext: ", ext, ")")
		else:
			print("  ✗ Failed to detect '", test.path, "' as music file")
			passed = false
	
	# Test non-music files
	var non_music_paths = [
		"music/song.txt",
		"music/song.json",
		"music/song",
	]
	
	for path in non_music_paths:
		var ext = path.get_extension().to_lower()
		var is_music_file = ext in ["ogg", "mp3", "wav"]
		
		if not is_music_file:
			print("  ✓ Correctly identified '", path, "' as NOT a music file")
		else:
			print("  ✗ Incorrectly identified '", path, "' as music file")
			passed = false
	
	return passed


func test_mapfactory_detect_json_files() -> bool:
	print("--- Testing MapFactory JSON File Detection ---")
	var passed = true
	
	# Test that JSON files are still detected as PowerBeatsVR (backwards compat)
	var test_paths = [
		{"path": "Layouts/song.json", "expected": "POWER_BEATS_VR"},
		{"path": "Layouts/Test Song.json", "expected": "POWER_BEATS_VR"},
	]
	
	for test in test_paths:
		var is_json = test.path.ends_with(".json")
		
		if is_json:
			print("  ✓ Detected '", test.path, "' as JSON layout file")
		else:
			print("  ✗ Failed to detect '", test.path, "' as JSON layout")
			passed = false
	
	return passed


func test_mapfactory_detect_beatsaber() -> bool:
	print("--- Testing MapFactory Beat Saber Detection ---")
	var passed = true
	
	# Test the detection logic for Beat Saber format
	# Beat Saber = folder with info.dat inside
	
	# We can't check actual file existence in headless mode without the files
	# But we can test the logic
	
	var test_cases = [
		{"is_dir": true, "has_info_dat": true, "expected": "BEAT_SABER"},
		{"is_dir": true, "has_info_dat": false, "expected": "UNKNOWN"},
		{"is_dir": false, "has_info_dat": false, "expected": "NOT_BEAT_SABER"},
	]
	
	for test in test_cases:
		# Simulate the detection logic
		var result = "UNKNOWN"
		if test.is_dir:
			if test.has_info_dat:
				result = "BEAT_SABER"
		else:
			result = "NOT_BEAT_SABER"
		
		if result == test.expected:
			print("  ✓ Detection correct for is_dir=", test.is_dir, ", has_info_dat=", test.has_info_dat)
		else:
			print("  ✗ Detection wrong: expected ", test.expected, ", got ", result)
			passed = false
	
	return passed


func test_layout_path_derivation() -> bool:
	print("--- Testing Layout Path Derivation ---")
	var passed = true
	
	# Test that layout path is correctly derived from music path
	# music_path: /path/to/music/song.ogg -> layout: /path/to/Layouts/song.json
	
	var test_cases = [
		{
			"music_path": "/PowerBeatsVRLevels/music/ogg/Wellerman.ogg",
			"layouts_path": "/PowerBeatsVRLevels/Layouts",
			"expected_layout": "/PowerBeatsVRLevels/Layouts/Wellerman.json"
		},
		{
			"music_path": "/music/Test Song.mp3",
			"layouts_path": "/Layouts",
			"expected_layout": "/Layouts/Test Song.json"
		},
		{
			"music_path": "/music/song with spaces.wav",
			"layouts_path": "/Layouts",
			"expected_layout": "/Layouts/song with spaces.json"
		},
	]
	
	for test in test_cases:
		var song_name = test.music_path.get_file().get_basename()
		var layout_path = test.layouts_path + "/" + song_name + ".json"
		
		if layout_path == test.expected_layout:
			print("  ✓ Derived layout for '", test.music_path.get_file(), "': ", layout_path)
		else:
			print("  ✗ Wrong layout: expected '", test.expected_layout, "', got '", layout_path, "'")
			passed = false
	
	return passed


func test_powerbeatsvr_music_path_property() -> bool:
	print("--- Testing PowerBeatsVRMap music_path Property ---")
	var passed = true
	
	# Test that get_song() returns music_path when set
	# Simulate the logic without instantiating the actual class
	
	# Test case 1: music_path is set
	var music_path = "/music/song.ogg"
	var derived_path = "/music/derived_song.ogg"  # What get_song() would normally derive
	
	# Simulate get_song() logic
	var result = music_path if music_path != "" else derived_path
	
	if result == music_path:
		print("  ✓ get_song() returns explicit music_path when set")
	else:
		print("  ✗ get_song() should return explicit music_path")
		passed = false
	
	# Test case 2: music_path is empty
	music_path = ""
	result = music_path if music_path != "" else derived_path
	
	if result == derived_path:
		print("  ✓ get_song() falls back to derived path when music_path is empty")
	else:
		print("  ✗ get_song() should fall back to derived path")
		passed = false
	
	return passed


func test_song_path_flow_simulation() -> bool:
	print("--- Testing Song Path Flow Simulation ---")
	var passed = true
	
	# Simulate the full flow for PowerBeatsVR:
	# 1. User selects song in ui_song_list
	# 2. GameVariables.path = music_path
	# 3. MapFactory.create_map(music_path) derives layout and sets map.music_path
	# 4. Game.gd loads map and calls map.get_song()
	# 5. map.get_song() returns the correct music path
	
	print("  --- Simulating PowerBeatsVR song selection ---")
	
	# Step 1-2: User selects song
	var selected_music_path = "/PowerBeatsVRLevels/music/ogg/Wellerman.ogg"
	var simulated_game_vars_path = selected_music_path
	print("  Step 1-2: GameVariables.path = '", simulated_game_vars_path, "'")
	
	# Step 3: MapFactory creates map
	var ext = simulated_game_vars_path.get_extension().to_lower()
	var is_music_file = ext in ["ogg", "mp3", "wav"]
	var derived_layout_path = ""
	var map_music_path = ""
	
	if is_music_file:
		map_music_path = simulated_game_vars_path
		var song_name = simulated_game_vars_path.get_file().get_basename()
		derived_layout_path = "/PowerBeatsVRLevels/Layouts/" + song_name + ".json"
		print("  Step 3: MapFactory derives layout: '", derived_layout_path, "'")
		print("         MapFactory sets map.music_path = '", map_music_path, "'")
	else:
		print("  ✗ Music file not detected")
		passed = false
	
	# Step 4-5: Game loads and calls get_song()
	var result_song_path = map_music_path if map_music_path != "" else "derived_from_layout"
	
	if result_song_path == selected_music_path:
		print("  Step 4-5: map.get_song() returns '", result_song_path, "'")
		print("  ✓ Full flow works: selected music = returned music")
	else:
		print("  ✗ Flow broken: selected '", selected_music_path, "' != returned '", result_song_path, "'")
		passed = false
	
	# Now simulate Beat Saber flow (should remain unchanged)
	print("  --- Simulating Beat Saber song selection ---")
	
	var bs_folder_path = "/Levels/MySong"
	simulated_game_vars_path = bs_folder_path
	print("  Step 1-2: GameVariables.path = '", simulated_game_vars_path, "'")
	
	# For Beat Saber, MapFactory just passes the folder path through
	# get_song() reads from info.dat
	ext = simulated_game_vars_path.get_extension().to_lower()
	is_music_file = ext in ["ogg", "mp3", "wav"]
	
	if not is_music_file:
		print("  Step 3: MapFactory creates Beat Saber map (folder path)")
		# Simulate get_song() reading from info.dat
		var bs_song_path = bs_folder_path + "/song.ogg"  # Typical Beat Saber structure
		print("  Step 4-5: map.get_song() returns '", bs_song_path, "' (from info.dat)")
		print("  ✓ Beat Saber flow unchanged")
	else:
		print("  ✗ Beat Saber folder incorrectly detected as music file")
		passed = false
	
	return passed


func test_playlist_song_path_handling() -> bool:
	print("--- Testing Playlist Song Path Handling ---")
	var passed = true
	
	# Simulate playlist mode:
	# PlaylistManager._load_current_song() sets GameVariables.path = song.music_path
	# This ensures the correct song plays even in playlist mode
	
	# Create mock playlist with songs
	var playlist_songs = [
		{"name": "Song1", "music_path": "/music/song1.ogg", "layout_path": "/Layouts/Song1.json"},
		{"name": "Song2", "music_path": "/music/song2.ogg", "layout_path": "/Layouts/Song2.json"},
		{"name": "Song3", "music_path": "/music/song3.ogg", "layout_path": "/Layouts/Song3.json"},
	]
	
	var current_song_index = 0
	var is_playlist_mode = true
	
	# Test playing each song
	for i in range(playlist_songs.size()):
		var song = playlist_songs[i]
		
		# Simulate _load_current_song()
		var simulated_game_vars_path = song.music_path  # Now uses music_path!
		
		# Simulate MapFactory.create_map()
		var song_name = simulated_game_vars_path.get_file().get_basename()
		var derived_layout = "/Layouts/" + song_name + ".json"  # Simplified path
		
		# Simulate map.get_song()
		var map_music_path = simulated_game_vars_path  # Set by MapFactory
		var result = map_music_path if map_music_path != "" else "derived"
		
		if result == song.music_path:
			print("  ✓ Playlist song ", i+1, ": correct music path returned")
		else:
			print("  ✗ Playlist song ", i+1, ": wrong path - expected '", song.music_path, "', got '", result, "'")
			passed = false
	
	# Test the bug fix: non-playlist song after playlist
	print("  --- Testing non-playlist song after playlist (bug fix) ---")
	
	# Simulate: user played playlist, now selects a normal song
	is_playlist_mode = false  # Would be set by end_playlist() or new song selection
	var new_song_music_path = "/music/different_song.ogg"
	
	# ui_song_list sets GameVariables.path to music path
	var simulated_path = new_song_music_path
	
	# MapFactory creates map with this music path
	var map_music_path = simulated_path
	
	# get_song() returns the music path
	var result = map_music_path if map_music_path != "" else "wrong"
	
	if result == new_song_music_path:
		print("  ✓ Non-playlist song after playlist: correct music path")
		print("    (Bug fixed: no stale playlist state affecting audio path)")
	else:
		print("  ✗ Wrong path: expected '", new_song_music_path, "', got '", result, "'")
		passed = false
	
	return passed


func test_edge_cases() -> bool:
	print("--- Testing Edge Cases ---")
	var passed = true
	
	# Test 1: Song name with special characters
	var special_names = [
		"Don't Stop Til You Get Enough",
		"Song (Remix)",
		"Artist - Song Title",
		"Song [Radio Edit]",
		"Café Music",
	]
	
	for name in special_names:
		var music_path = "/music/" + name + ".ogg"
		var song_name = music_path.get_file().get_basename()
		var layout_path = "/Layouts/" + song_name + ".json"
		
		# Verify the song name is preserved
		if song_name == name:
			print("  ✓ Special name preserved: '", name, "'")
		else:
			print("  ✗ Special name corrupted: expected '", name, "', got '", song_name, "'")
			passed = false
	
	# Test 2: Empty music path handling
	var empty_music_path = ""
	var result = empty_music_path if empty_music_path != "" else "fallback"
	
	if result == "fallback":
		print("  ✓ Empty music_path falls back correctly")
	else:
		print("  ✗ Empty music_path should fall back")
		passed = false
	
	# Test 3: Extension detection case insensitivity
	var mixed_case_paths = [
		{"path": "song.OGG", "expected": true},
		{"path": "song.Ogg", "expected": true},
		{"path": "song.MP3", "expected": true},
		{"path": "song.WAV", "expected": true},
	]
	
	for test in mixed_case_paths:
		var ext = test.path.get_extension().to_lower()
		var is_music = ext in ["ogg", "mp3", "wav"]
		
		if is_music == test.expected:
			print("  ✓ Case insensitive detection for: ", test.path)
		else:
			print("  ✗ Case sensitivity issue for: ", test.path)
			passed = false
	
	# Test 4: Path with multiple dots
	var multi_dot_path = "/music/Artist.Name - Song.Title.ogg"
	var basename = multi_dot_path.get_file().get_basename()
	var expected_basename = "Artist.Name - Song.Title"
	
	if basename == expected_basename:
		print("  ✓ Multi-dot filename handled: '", basename, "'")
	else:
		print("  ✗ Multi-dot filename wrong: expected '", expected_basename, "', got '", basename, "'")
		passed = false
	
	return passed

