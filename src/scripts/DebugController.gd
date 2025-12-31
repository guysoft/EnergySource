extends Node
## Remote Debug Controller
## 
## Enables keyboard-based debugging for Quest via ADB.
## Keys can be sent via: adb shell input keyevent KEYCODE_X
##
## Debug Keys:
##   F1  - Auto-start test level (Matt Gray song)
##   F2  - Return to main menu
##   F3  - Print current game state
##   F4  - Toggle debug overlay
##   1-5 - Quick select difficulty (1=Beginner, 5=Expert)
##   ENTER - Confirm/Start
##   ESCAPE - Back/Menu

class_name DebugController

## Enable/disable debug controller
var enabled: bool = true

## Reference to the test song path (customize as needed)
var test_song_name: String = "Matt Gray - Sanxion Loader 2014 Remake Preview.mp3"

func _ready():
	print("DebugController: Initialized - keyboard debug controls enabled")
	print("DebugController: F1=test level, F2=menu, F3=state, ENTER=start")

func _input(event):
	if not enabled:
		return
		
	if event is InputEventKey and event.pressed and not event.echo:
		_handle_key(event.keycode)

func _handle_key(keycode: int):
	print("DebugController: Key pressed: ", keycode, " (", OS.get_keycode_string(keycode), ")")
	
	match keycode:
		KEY_F1:
			_start_test_level()
		KEY_F2:
			_return_to_menu()
		KEY_F3:
			_print_game_state()
		KEY_F4:
			_toggle_debug_overlay()
		KEY_1:
			_set_difficulty("Beginner")
		KEY_2:
			_set_difficulty("Easy")
		KEY_3:
			_set_difficulty("Normal")
		KEY_4:
			_set_difficulty("Advanced")
		KEY_5:
			_set_difficulty("Expert")
		KEY_ENTER, KEY_KP_ENTER:
			_confirm_action()
		KEY_ESCAPE:
			_back_action()

func _start_test_level():
	print("DebugController: Starting test level...")
	
	# Set up the test song path
	var music_path = GameVariables.pbvr_music_path + "/" + test_song_name
	print("DebugController: Test song path: ", music_path)
	
	# Check if file exists
	if not FileAccess.file_exists(music_path):
		print("DebugController: ERROR - Test song not found at: ", music_path)
		return
	
	# Set game variables
	GameVariables.path = music_path
	GameVariables.difficulty = "Expert"
	
	print("DebugController: Loading game scene with path=", GameVariables.path)
	
	# Load the game scene
	var manager = Global.manager()
	if manager:
		manager.load_scene(manager.game_path, "game")
	else:
		print("DebugController: ERROR - Could not get game manager")

func _return_to_menu():
	print("DebugController: Returning to menu...")
	var manager = Global.manager()
	if manager:
		manager.load_scene(manager.menu_path, "menu")
	else:
		print("DebugController: ERROR - Could not get game manager")

func _print_game_state():
	print("DebugController: === GAME STATE ===")
	print("  path: ", GameVariables.path)
	print("  difficulty: ", GameVariables.difficulty)
	print("  pbvr_music_path: ", GameVariables.pbvr_music_path)
	print("  pbvr_layouts_path: ", GameVariables.pbvr_layouts_path)
	print("  ENABLE_VR: ", GameVariables.ENABLE_VR)
	
	var manager = Global.manager()
	if manager:
		print("  Current scenes: ", manager.loaded_scenes_list)
		if manager._player:
			print("  in_game: ", manager._player.in_game)
	
	print("DebugController: === END STATE ===")

func _toggle_debug_overlay():
	print("DebugController: Toggle debug overlay (not implemented)")
	# Could toggle FPS overlay or other debug info

func _set_difficulty(difficulty: String):
	print("DebugController: Setting difficulty to: ", difficulty)
	GameVariables.difficulty = difficulty

func _confirm_action():
	print("DebugController: Confirm/Enter pressed")
	# This is handled by individual scenes (MainMenuUI, etc.)
	# Just log it for debugging purposes

func _back_action():
	print("DebugController: Back/Escape pressed")
	# This is handled by individual scenes
	# Just log it for debugging purposes

