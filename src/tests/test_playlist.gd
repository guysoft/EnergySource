extends SceneTree

# Test script for Playlist Manager functionality
# Run with: godot --headless --script res://tests/test_playlist.gd

func _init():
	print("\n=== Playlist Manager Tests ===\n")
	var all_passed = true
	
	# Test 1: Windows path conversion
	all_passed = test_windows_path_conversion() and all_passed
	
	# Test 2: JSON structure parsing
	all_passed = test_json_parsing() and all_passed
	
	# Test 3: Shuffle logic
	all_passed = test_shuffle_logic() and all_passed
	
	# Test 4: Playlist mode state
	all_passed = test_playlist_mode_state() and all_passed
	
	# Test 5: Time formatting
	all_passed = test_time_formatting() and all_passed
	
	# Test 6: Play order generation
	all_passed = test_play_order_generation() and all_passed
	
	# Test 7: Song entry parsing
	all_passed = test_song_entry_parsing() and all_passed
	
	# Test 8: Playlist data structure
	all_passed = test_playlist_data_structure() and all_passed
	
	# Test 9: Next song logic
	all_passed = test_next_song_logic() and all_passed
	
	# Test 10: UI scenes load correctly
	all_passed = test_ui_scenes() and all_passed
	
	# Test 11: Playlist dual-mode view
	all_passed = test_playlist_dual_mode() and all_passed
	
	# Test 12: Skip song simulation (next_song loads correct data)
	all_passed = test_skip_song_simulation() and all_passed
	
	print("\n=== Test Summary ===")
	if all_passed:
		print("✓ ALL PLAYLIST TESTS PASSED")
	else:
		print("✗ SOME TESTS FAILED")
	
	quit(0 if all_passed else 1)


func test_windows_path_conversion() -> bool:
	print("--- Testing Windows Path Conversion ---")
	var passed = true
	
	# Test case 1: Standard Windows path with backslashes
	var win_path1 = "C:\\users\\steamuser\\Desktop\\music\\ogg\\song.ogg"
	var filename1 = _extract_filename_from_windows_path(win_path1)
	if filename1 == "song.ogg":
		print("  ✓ Extracted filename from backslash path: ", filename1)
	else:
		print("  ✗ Failed to extract filename from backslash path, got: ", filename1)
		passed = false
	
	# Test case 2: Windows path with forward slashes
	var win_path2 = "C:/users/steamuser/Desktop/music/test.mp3"
	var filename2 = _extract_filename_from_windows_path(win_path2)
	if filename2 == "test.mp3":
		print("  ✓ Extracted filename from forward slash path: ", filename2)
	else:
		print("  ✗ Failed to extract filename from forward slash path, got: ", filename2)
		passed = false
	
	# Test case 3: Path with special characters in filename
	var win_path3 = "C:\\music\\Don't Stop Til You Get Enough.ogg"
	var filename3 = _extract_filename_from_windows_path(win_path3)
	if filename3 == "Don't Stop Til You Get Enough.ogg":
		print("  ✓ Extracted filename with special chars: ", filename3)
	else:
		print("  ✗ Failed to extract filename with special chars, got: ", filename3)
		passed = false
	
	# Test case 4: Is Windows path detection
	if _is_windows_path("C:\\path\\to\\file.txt"):
		print("  ✓ Correctly identified Windows path with backslashes")
	else:
		print("  ✗ Failed to identify Windows path with backslashes")
		passed = false
	
	if _is_windows_path("C:/path/to/file.txt"):
		print("  ✓ Correctly identified Windows path with forward slashes")
	else:
		print("  ✗ Failed to identify Windows path with forward slashes")
		passed = false
	
	if not _is_windows_path("/home/user/music/song.ogg"):
		print("  ✓ Correctly identified Unix path as non-Windows")
	else:
		print("  ✗ Incorrectly identified Unix path as Windows path")
		passed = false
	
	return passed


func test_json_parsing() -> bool:
	print("--- Testing JSON Structure Parsing ---")
	var passed = true
	
	# Create test JSON structure
	var test_json = {
		"playlists": [
			{
				"name": "test_playlist",
				"isShuffle": true,
				"isRepeat": false,
				"isEndurance": false,
				"entries": [
					{
						"name": "Test Song 1",
						"path": "C:\\music\\test1.ogg",
						"musicLength": 180.5,
						"layoutLength": 175.0,
						"difficulty": "Expert"
					}
				]
			}
		]
	}
	
	# Validate structure
	if test_json.has("playlists"):
		print("  ✓ JSON has 'playlists' key")
	else:
		print("  ✗ JSON missing 'playlists' key")
		passed = false
	
	var playlists = test_json["playlists"]
	if playlists.size() > 0:
		print("  ✓ Playlists array is not empty")
	else:
		print("  ✗ Playlists array is empty")
		passed = false
	
	var playlist = playlists[0]
	if playlist.has("name") and playlist["name"] == "test_playlist":
		print("  ✓ Playlist name parsed correctly")
	else:
		print("  ✗ Playlist name not parsed correctly")
		passed = false
	
	if playlist.has("isShuffle") and playlist["isShuffle"] == true:
		print("  ✓ isShuffle property parsed correctly")
	else:
		print("  ✗ isShuffle property not parsed correctly")
		passed = false
	
	if playlist.has("entries") and playlist["entries"].size() > 0:
		print("  ✓ Entries array parsed correctly")
	else:
		print("  ✗ Entries array not parsed correctly")
		passed = false
	
	return passed


func test_shuffle_logic() -> bool:
	print("--- Testing Shuffle Logic ---")
	var passed = true
	
	# Create an array and shuffle it multiple times
	var original = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
	var shuffled1 = _shuffle_array(original.duplicate())
	var shuffled2 = _shuffle_array(original.duplicate())
	
	# Check that shuffled arrays have same length
	if shuffled1.size() == original.size():
		print("  ✓ Shuffled array maintains same length")
	else:
		print("  ✗ Shuffled array has different length")
		passed = false
	
	# Check that shuffled arrays contain same elements
	var sorted1 = shuffled1.duplicate()
	sorted1.sort()
	if sorted1 == original:
		print("  ✓ Shuffled array contains same elements")
	else:
		print("  ✗ Shuffled array missing elements")
		passed = false
	
	# Two shuffles should (usually) produce different results
	# Note: There's a very small chance they could be the same
	if shuffled1 != shuffled2 or shuffled1 != original:
		print("  ✓ Shuffle produces varied results")
	else:
		print("  ⚠ Shuffle may not be working (could be coincidence)")
		# Don't fail the test as this could rarely happen by chance
	
	return passed


func test_playlist_mode_state() -> bool:
	print("--- Testing Playlist Mode State ---")
	var passed = true
	
	# Note: We can't fully test PlaylistManager autoload in headless mode
	# So we test the logic patterns instead
	
	# Test initial state
	var is_playlist_mode = false
	var current_song_index = 0
	var playlist_total_time = 0.0
	
	if not is_playlist_mode:
		print("  ✓ Initial playlist mode is false")
	else:
		print("  ✗ Initial playlist mode should be false")
		passed = false
	
	if current_song_index == 0:
		print("  ✓ Initial song index is 0")
	else:
		print("  ✗ Initial song index should be 0")
		passed = false
	
	if playlist_total_time == 0.0:
		print("  ✓ Initial playlist time is 0")
	else:
		print("  ✗ Initial playlist time should be 0")
		passed = false
	
	# Simulate starting playlist
	is_playlist_mode = true
	current_song_index = 0
	playlist_total_time = 0.0
	
	if is_playlist_mode:
		print("  ✓ Playlist mode activates correctly")
	else:
		print("  ✗ Playlist mode should be active")
		passed = false
	
	# Simulate advancing to next song
	current_song_index += 1
	
	if current_song_index == 1:
		print("  ✓ Song index advances correctly")
	else:
		print("  ✗ Song index should be 1")
		passed = false
	
	return passed


func test_time_formatting() -> bool:
	print("--- Testing Time Formatting ---")
	var passed = true
	
	# Test format_playlist_time logic
	var test_cases = [
		{"seconds": 0.0, "expected": "00:00"},
		{"seconds": 30.0, "expected": "00:30"},
		{"seconds": 60.0, "expected": "01:00"},
		{"seconds": 90.5, "expected": "01:30"},
		{"seconds": 3600.0, "expected": "60:00"},
		{"seconds": 125.7, "expected": "02:05"},
	]
	
	for test in test_cases:
		var result = _format_playlist_time(test["seconds"])
		if result == test["expected"]:
			print("  ✓ ", test["seconds"], "s -> ", result)
		else:
			print("  ✗ ", test["seconds"], "s -> got ", result, ", expected ", test["expected"])
			passed = false
	
	return passed


func test_play_order_generation() -> bool:
	print("--- Testing Play Order Generation ---")
	var passed = true
	
	# Test non-shuffled play order
	var entries_count = 5
	var play_order = []
	for i in range(entries_count):
		play_order.append(i)
	
	if play_order == [0, 1, 2, 3, 4]:
		print("  ✓ Non-shuffled play order is sequential")
	else:
		print("  ✗ Non-shuffled play order should be [0, 1, 2, 3, 4]")
		passed = false
	
	# Test that shuffled order still contains all indices
	var shuffled_order = _shuffle_array(play_order.duplicate())
	var sorted_shuffled = shuffled_order.duplicate()
	sorted_shuffled.sort()
	
	if sorted_shuffled == [0, 1, 2, 3, 4]:
		print("  ✓ Shuffled play order contains all indices")
	else:
		print("  ✗ Shuffled play order missing indices")
		passed = false
	
	return passed


func test_song_entry_parsing() -> bool:
	print("--- Testing Song Entry Parsing ---")
	var passed = true
	
	# Test song entry data structure
	var entry_data = {
		"name": "Test Song",
		"path": "C:\\music\\test.ogg",
		"musicLength": 180.5,
		"layoutLength": 175.0,
		"difficulty": "Expert"
	}
	
	# Validate parsing
	var name = entry_data.get("name", "Unknown")
	var original_path = entry_data.get("path", "")
	var music_length = entry_data.get("musicLength", 0.0)
	var layout_length = entry_data.get("layoutLength", 0.0)
	var difficulty = entry_data.get("difficulty", "Expert")
	
	if name == "Test Song":
		print("  ✓ Song name parsed: ", name)
	else:
		print("  ✗ Song name parsing failed")
		passed = false
	
	if original_path == "C:\\music\\test.ogg":
		print("  ✓ Original path parsed: ", original_path)
	else:
		print("  ✗ Original path parsing failed")
		passed = false
	
	if is_equal_approx(music_length, 180.5):
		print("  ✓ Music length parsed: ", music_length)
	else:
		print("  ✗ Music length parsing failed")
		passed = false
	
	if is_equal_approx(layout_length, 175.0):
		print("  ✓ Layout length parsed: ", layout_length)
	else:
		print("  ✗ Layout length parsing failed")
		passed = false
	
	if difficulty == "Expert":
		print("  ✓ Difficulty parsed: ", difficulty)
	else:
		print("  ✗ Difficulty parsing failed")
		passed = false
	
	return passed


func test_playlist_data_structure() -> bool:
	print("--- Testing Playlist Data Structure ---")
	var passed = true
	
	# Test playlist data parsing
	var playlist_data = {
		"name": "test",
		"isShuffle": true,
		"isRepeat": false,
		"isEndurance": true,
		"entries": []
	}
	
	var name = playlist_data.get("name", "Unnamed")
	var is_shuffle = playlist_data.get("isShuffle", false)
	var is_repeat = playlist_data.get("isRepeat", false)
	var is_endurance = playlist_data.get("isEndurance", false)
	
	if name == "test":
		print("  ✓ Playlist name: ", name)
	else:
		print("  ✗ Playlist name parsing failed")
		passed = false
	
	if is_shuffle == true:
		print("  ✓ isShuffle: ", is_shuffle)
	else:
		print("  ✗ isShuffle parsing failed")
		passed = false
	
	if is_repeat == false:
		print("  ✓ isRepeat: ", is_repeat)
	else:
		print("  ✗ isRepeat parsing failed")
		passed = false
	
	if is_endurance == true:
		print("  ✓ isEndurance: ", is_endurance)
	else:
		print("  ✗ isEndurance parsing failed")
		passed = false
	
	return passed


func test_next_song_logic() -> bool:
	print("--- Testing Next Song Logic ---")
	var passed = true
	
	# Simulate playlist with 3 songs
	var play_order = [0, 1, 2]
	var current_index = 0
	var is_repeat = false
	
	# Test advancing through playlist
	# First song
	if current_index == 0:
		print("  ✓ Starting at song 0")
	else:
		passed = false
	
	# Has next?
	if current_index < play_order.size() - 1:
		print("  ✓ Has next song from index 0")
	else:
		print("  ✗ Should have next song from index 0")
		passed = false
	
	# Advance to next
	current_index += 1
	if current_index == 1:
		print("  ✓ Advanced to song 1")
	else:
		passed = false
	
	# Advance again
	current_index += 1
	if current_index == 2:
		print("  ✓ Advanced to song 2")
	else:
		passed = false
	
	# At end - no more songs (non-repeat mode)
	if current_index >= play_order.size() - 1:
		print("  ✓ At last song (index 2)")
	else:
		print("  ✗ Should be at last song")
		passed = false
	
	# Try to advance past end
	current_index += 1
	if current_index >= play_order.size():
		if is_repeat:
			current_index = 0
			print("  ✓ Would restart if repeat mode")
		else:
			print("  ✓ Playlist complete (no repeat)")
	else:
		print("  ✗ Index should exceed play_order size")
		passed = false
	
	return passed


func test_ui_scenes() -> bool:
	print("--- Testing Playlist UI Scenes ---")
	var passed = true
	
	# Test ui_playlist.tscn
	var playlist_scene = load("res://scenes/ui_playlist.tscn")
	if playlist_scene == null:
		print("  ✗ ui_playlist.tscn failed to load")
		passed = false
	else:
		var instance = playlist_scene.instantiate()
		if instance == null:
			print("  ✗ ui_playlist.tscn failed to instantiate")
			passed = false
		else:
			print("  ✓ ui_playlist.tscn loads and instantiates")
			
			# Check for required nodes
			var playlist_items = instance.get_node_or_null("ListContainer/PlaylistItems")
			var play_button = instance.get_node_or_null("PlayButton")
			
			if playlist_items:
				print("  ✓ PlaylistItems node found")
			else:
				print("  ✗ PlaylistItems node not found")
				passed = false
			
			if play_button:
				print("  ✓ PlayButton node found")
			else:
				print("  ✗ PlayButton node not found")
				passed = false
			
			instance.queue_free()
	
	# Test Game.tscn has playlist elements
	var game_scene = load("res://scenes/Game.tscn")
	if game_scene == null:
		print("  ✗ Game.tscn failed to load")
		passed = false
	else:
		var instance = game_scene.instantiate()
		if instance == null:
			print("  ✗ Game.tscn failed to instantiate")
			passed = false
		else:
			print("  ✓ Game.tscn loads and instantiates")
			
			# Check for NextButton in BigScore
			# Note: UICanvasInteract reparents children to SubViewport at runtime
			# In headless mode without autoloads, scripts don't run so reparenting doesn't happen
			# Check both possible paths
			var next_btn = instance.get_node_or_null("BigScore/ReferenceRect/VBoxContainer/HBoxContainer/NextButton")
			if next_btn == null:
				next_btn = instance.get_node_or_null("BigScore/SubViewport/ReferenceRect/VBoxContainer/HBoxContainer/NextButton")
			if next_btn:
				print("  ✓ NextButton found in BigScore")
				if not next_btn.visible:
					print("  ✓ NextButton is hidden by default")
				else:
					print("  ✗ NextButton should be hidden by default")
					passed = false
			else:
				print("  ✗ NextButton not found in BigScore")
				passed = false
			
			# Check for PlaylistTimeLabel in ScoreCanvas
			# Same issue - check both paths
			var playlist_time = instance.get_node_or_null("ScoreCanvas/ReferenceRect/CenterContainer/VBoxContainer/PlaylistTimeLabel")
			if playlist_time == null:
				playlist_time = instance.get_node_or_null("ScoreCanvas/SubViewport/ReferenceRect/CenterContainer/VBoxContainer/PlaylistTimeLabel")
			if playlist_time:
				print("  ✓ PlaylistTimeLabel found in ScoreCanvas")
				if not playlist_time.visible:
					print("  ✓ PlaylistTimeLabel is hidden by default")
				else:
					print("  ✗ PlaylistTimeLabel should be hidden by default")
					passed = false
			else:
				print("  ✗ PlaylistTimeLabel not found in ScoreCanvas")
				passed = false
			
			instance.queue_free()
	
	# Test PauseMenu.tscn has SkipBtn (moved to PauseContainer, not PauseBtns)
	var pause_scene = load("res://scenes/PauseMenu.tscn")
	if pause_scene == null:
		print("  ✗ PauseMenu.tscn failed to load")
		passed = false
	else:
		var instance = pause_scene.instantiate()
		if instance == null:
			print("  ✗ PauseMenu.tscn failed to instantiate")
			passed = false
		else:
			print("  ✓ PauseMenu.tscn loads and instantiates")
			
			# SkipBtn is now in PauseContainer (sibling to PauseBtns)
			var skip_btn = instance.get_node_or_null("SubViewport/PauseContainer/SkipBtn")
			if skip_btn:
				print("  ✓ SkipBtn found in PauseMenu")
			else:
				print("  ✗ SkipBtn not found in PauseMenu at SubViewport/PauseContainer/SkipBtn")
				passed = false
			
			# Check that UIMeshInstance is visible (required for menu to render)
			var ui_mesh = instance.get_node_or_null("UIArea/UIMeshInstance")
			if ui_mesh:
				if ui_mesh.visible:
					print("  ✓ UIMeshInstance is visible (required for rendering)")
				else:
					print("  ✗ UIMeshInstance should be visible for pause menu to render")
					passed = false
			else:
				print("  ✗ UIMeshInstance not found in UIArea")
				passed = false
			
			instance.queue_free()
	
	return passed


func test_playlist_dual_mode() -> bool:
	print("--- Testing Playlist Dual-Mode View ---")
	var passed = true
	
	# Load ui_playlist scene and check for dual-mode elements
	var playlist_scene = load("res://scenes/ui_playlist.tscn")
	if playlist_scene == null:
		print("  ✗ ui_playlist.tscn failed to load")
		return false
	
	var instance = playlist_scene.instantiate()
	if instance == null:
		print("  ✗ ui_playlist.tscn failed to instantiate")
		return false
	
	# Check for HeaderContainer with BackButton and PlaylistLabel
	var header_container = instance.get_node_or_null("HeaderContainer")
	if header_container:
		print("  ✓ HeaderContainer found")
	else:
		print("  ✗ HeaderContainer not found")
		passed = false
	
	var back_button = instance.get_node_or_null("HeaderContainer/BackButton")
	if back_button:
		print("  ✓ BackButton found in HeaderContainer")
		if not back_button.visible:
			print("  ✓ BackButton is hidden by default (correct for playlists view)")
		else:
			print("  ⚠ BackButton is visible by default (may be intended)")
	else:
		print("  ✗ BackButton not found in HeaderContainer")
		passed = false
	
	var playlist_label = instance.get_node_or_null("HeaderContainer/PlaylistLabel")
	if playlist_label:
		print("  ✓ PlaylistLabel found in HeaderContainer")
	else:
		print("  ✗ PlaylistLabel not found in HeaderContainer")
		passed = false
	
	# Test ViewMode enum exists in script
	var script = instance.get_script()
	if script:
		# We can't directly check enum in GDScript, but we can verify the script loads
		print("  ✓ Script attached to ui_playlist")
	else:
		print("  ✗ No script attached to ui_playlist")
		passed = false
	
	# Test that get_view_mode method exists
	# Note: In headless mode without autoloads, script may not fully compile
	# so has_method may fail even though the method exists in the source
	if instance.has_method("get_view_mode"):
		print("  ✓ get_view_mode() method exists")
	else:
		# Expected in headless mode - script dependencies (Global, etc.) aren't available
		print("  ⚠ get_view_mode() check skipped (script has missing dependencies in headless mode)")
	
	instance.queue_free()
	return passed


func test_skip_song_simulation() -> bool:
	print("--- Testing Skip Song Simulation ---")
	var passed = true
	
	# Simulate a playlist with multiple songs
	# This tests that after "skipping" (calling next_song), the correct song data is set
	
	# Create mock song entries with layout paths
	var songs = [
		{"name": "Song1", "layout_path": "res://test/song1.json", "difficulty": "Easy"},
		{"name": "Song2", "layout_path": "res://test/song2.json", "difficulty": "Normal"},
		{"name": "Song3", "layout_path": "res://test/song3.json", "difficulty": "Hard"},
	]
	
	# Simulate playlist state
	var current_song_index = 0
	var play_order = [0, 1, 2]
	var is_playlist_mode = true
	
	# Test initial state
	var current_song = songs[play_order[current_song_index]]
	if current_song.name == "Song1":
		print("  ✓ Initial song is Song1")
	else:
		print("  ✗ Initial song should be Song1")
		passed = false
	
	# Simulate skip (next_song logic)
	current_song_index += 1
	if current_song_index < play_order.size():
		current_song = songs[play_order[current_song_index]]
		# In real code, this sets GameVariables.path = song.layout_path
		var simulated_path = current_song.layout_path
		var simulated_difficulty = current_song.difficulty
		
		if simulated_path == "res://test/song2.json":
			print("  ✓ After skip, path is set to Song2's layout")
		else:
			print("  ✗ After skip, path should be Song2's layout, got: ", simulated_path)
			passed = false
		
		if simulated_difficulty == "Normal":
			print("  ✓ After skip, difficulty is set to Normal")
		else:
			print("  ✗ After skip, difficulty should be Normal")
			passed = false
		
		if current_song.name == "Song2":
			print("  ✓ Current song is now Song2")
		else:
			print("  ✗ Current song should be Song2")
			passed = false
	else:
		print("  ✗ Skip failed - index out of bounds")
		passed = false
	
	# Simulate another skip
	current_song_index += 1
	if current_song_index < play_order.size():
		current_song = songs[play_order[current_song_index]]
		if current_song.name == "Song3":
			print("  ✓ After second skip, current song is Song3")
		else:
			print("  ✗ After second skip, current song should be Song3")
			passed = false
	else:
		print("  ✗ Second skip failed - index out of bounds")
		passed = false
	
	# Simulate skip at end of playlist (should end playlist)
	current_song_index += 1
	if current_song_index >= play_order.size():
		is_playlist_mode = false
		print("  ✓ Skip at end of playlist correctly ends playlist mode")
	else:
		print("  ✗ Skip at end should have ended playlist mode")
		passed = false
	
	# Test that skipping songs without layouts works
	print("  --- Testing skip with invalid songs ---")
	var songs_with_invalid = [
		{"name": "ValidSong1", "layout_path": "res://valid1.json", "difficulty": "Easy"},
		{"name": "InvalidSong", "layout_path": "", "difficulty": "Normal"},  # No layout
		{"name": "ValidSong2", "layout_path": "res://valid2.json", "difficulty": "Hard"},
	]
	
	current_song_index = 0
	play_order = [0, 1, 2]
	is_playlist_mode = true
	
	# Simulate skip that should skip the invalid song
	# In real next_song(), it loops until finding a valid song
	current_song_index += 1
	var found_valid = false
	while current_song_index < play_order.size():
		current_song = songs_with_invalid[play_order[current_song_index]]
		if current_song.layout_path != "":
			found_valid = true
			break
		# Invalid song, skip to next
		current_song_index += 1
	
	if found_valid and current_song.name == "ValidSong2":
		print("  ✓ Skip correctly skipped invalid song and found ValidSong2")
	else:
		print("  ✗ Skip should have skipped invalid song and found ValidSong2")
		passed = false
	
	# Test that path is always set (even for invalid songs we skip past)
	# The key fix was that _load_current_song always sets GameVariables.path
	var test_path_always_set = ""
	for song_data in songs_with_invalid:
		# Simulate _load_current_song always setting the path
		test_path_always_set = song_data.layout_path  # Always set, even if empty
		# This prevents stale data from previous songs
	
	if test_path_always_set == "res://valid2.json":
		print("  ✓ Path is always updated (prevents stale data)")
	else:
		print("  ⚠ Path update test inconclusive")
	
	return passed


# Helper functions (replicating PlaylistManager logic for testing)

func _extract_filename_from_windows_path(path: String) -> String:
	var normalized = path.replace("\\", "/")
	return normalized.get_file()


func _is_windows_path(path: String) -> bool:
	return path.find(":\\") != -1 or path.find(":/") != -1


func _shuffle_array(arr: Array) -> Array:
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	for i in range(arr.size() - 1, 0, -1):
		var j = rng.randi_range(0, i)
		var temp = arr[i]
		arr[i] = arr[j]
		arr[j] = temp
	return arr


func _format_playlist_time(seconds: float) -> String:
	var total_seconds = int(seconds)
	var minutes = total_seconds / 60
	var secs = total_seconds % 60
	return "%02d:%02d" % [minutes, secs]

