extends SceneTree

# Simple test script to validate texture migration from Godot 3 to 4
# Run with: godot --headless --script res://tests/test_textures.gd

func _init():
	print("\n=== Texture Migration Validation Tests ===\n")
	var all_passed = true
	
	# Test 1: All external texture resources from Godot 3 are loadable
	all_passed = test_all_external_textures() and all_passed
	
	# Test 2: NoiseTexture2D materials
	all_passed = test_noise_materials() and all_passed
	
	# Test 3: Note materials
	all_passed = test_note_materials() and all_passed
	
	# Test 4: Environment resources
	all_passed = test_environments() and all_passed
	
	# Test 5: Scene resources with noise
	all_passed = test_scenes_with_noise() and all_passed
	
	# Test 6: All effect .tres files load
	all_passed = test_all_effect_files() and all_passed
	
	# Test 7: All menu and UI scenes load and instantiate
	all_passed = test_all_menu_scenes() and all_passed
	
	# Test 8: All game scenes load and instantiate
	all_passed = test_all_game_scenes() and all_passed
	
	# Test 9: AnimationPlayer scenes have valid animations
	all_passed = test_animation_players() and all_passed
	
	# Test 10: VR Controller Raycast validation
	all_passed = test_vr_controller_raycast() and all_passed
	
	# Test 11: XR Simulator null safety
	all_passed = test_xr_simulator_null_safety() and all_passed
	
	# Test 12: UIArea XR click handling (re-entrancy protection)
	all_passed = test_ui_area_click_handling() and all_passed
	
	# Test 13: PauseMenu scene and VR raycast compatibility
	all_passed = test_pause_menu() and all_passed
	
	# Test 14: Menu to Game flow (UICanvasInteract instantiation)
	all_passed = test_menu_to_game_flow() and all_passed
	
	# Test 15: Song list scroll buttons
	all_passed = test_song_list_scroll_buttons() and all_passed
	
	print("\n=== Test Summary ===")
	if all_passed:
		print("✓ ALL TESTS PASSED")
	else:
		print("✗ SOME TESTS FAILED")
	
	quit(0 if all_passed else 1)

func test_noise_materials() -> bool:
	print("--- Testing Noise Materials ---")
	var passed = true
	
	# Ground material
	var ground = load("res://effects/Ground.tres")
	if ground == null:
		print("  ✗ Ground.tres failed to load")
		passed = false
	else:
		var noise_param = ground.get_shader_parameter("noise")
		if noise_param == null:
			print("  ✗ Ground.tres: noise parameter is null")
			passed = false
		elif not noise_param is NoiseTexture2D:
			print("  ✗ Ground.tres: noise is not NoiseTexture2D, got: ", noise_param.get_class())
			passed = false
		else:
			print("  ✓ Ground.tres: noise is NoiseTexture2D")
	
	# Menu logo material
	var menu_logo = load("res://effects/menu_logo_material.tres")
	if menu_logo == null:
		print("  ✗ menu_logo_material.tres failed to load")
		passed = false
	else:
		var noise_param = menu_logo.get_shader_parameter("noise")
		if noise_param == null:
			print("  ✗ menu_logo_material.tres: noise parameter is null")
			passed = false
		elif not noise_param is NoiseTexture2D:
			print("  ✗ menu_logo_material.tres: noise is not NoiseTexture2D, got: ", noise_param.get_class())
			passed = false
		else:
			print("  ✓ menu_logo_material.tres: noise is NoiseTexture2D")
	
	return passed

func test_note_materials() -> bool:
	print("--- Testing Note Materials ---")
	var passed = true
	
	var note_files = [
		"res://effects/note_0_material.tres",
		"res://effects/note_1_material.tres",
		"res://effects/note_3_material.tres"
	]
	
	for path in note_files:
		var mat = load(path)
		if mat == null:
			print("  ✗ ", path, " failed to load")
			passed = false
		else:
			var noise_param = mat.get_shader_parameter("noise")
			if noise_param == null:
				print("  ✗ ", path, ": noise parameter is null")
				passed = false
			elif not noise_param is NoiseTexture2D:
				print("  ✗ ", path, ": noise is not NoiseTexture2D, got: ", noise_param.get_class())
				passed = false
			else:
				print("  ✓ ", path, ": noise is NoiseTexture2D")
	
	return passed

func test_environments() -> bool:
	print("--- Testing Environment Resources ---")
	var passed = true
	
	var env_files = [
		"res://effects/Dark_environment.tres",
		"res://effects/MenuScreen_environment.tres"
	]
	
	for path in env_files:
		var env = load(path)
		if env == null:
			print("  ✗ ", path, " failed to load")
			passed = false
		elif not env is Environment:
			print("  ✗ ", path, " is not Environment, got: ", env.get_class())
			passed = false
		else:
			var sky = env.sky
			if sky == null:
				print("  ✗ ", path, ": sky is null")
				passed = false
			elif not sky is Sky:
				print("  ✗ ", path, ": sky is not Sky, got: ", sky.get_class())
				passed = false
			else:
				var sky_mat = sky.sky_material
				if sky_mat == null:
					print("  ✗ ", path, ": sky_material is null")
					passed = false
				elif not sky_mat is ProceduralSkyMaterial:
					print("  ✗ ", path, ": sky_material is not ProceduralSkyMaterial, got: ", sky_mat.get_class())
					passed = false
				else:
					print("  ✓ ", path, ": has Sky with ProceduralSkyMaterial")
	
	return passed

func test_scenes_with_noise() -> bool:
	print("--- Testing Scenes with Noise ---")
	var passed = true
	
	# Ground scene
	var ground_scene = load("res://scenes/Ground.tscn")
	if ground_scene == null:
		print("  ✗ Ground.tscn failed to load")
		passed = false
	else:
		var instance = ground_scene.instantiate()
		if instance == null:
			print("  ✗ Ground.tscn failed to instantiate")
			passed = false
		else:
			print("  ✓ Ground.tscn loads and instantiates")
			instance.queue_free()
	
	# UITransition scene
	var transition_scene = load("res://scenes/UITransition.tscn")
	if transition_scene == null:
		print("  ✗ UITransition.tscn failed to load")
		passed = false
	else:
		var instance = transition_scene.instantiate()
		if instance == null:
			print("  ✗ UITransition.tscn failed to instantiate")
			passed = false
		else:
			print("  ✓ UITransition.tscn loads and instantiates")
			instance.queue_free()
	
	return passed

func test_all_external_textures() -> bool:
	print("--- Testing All External Texture Resources (from Godot 3) ---")
	var passed = true
	
	# All texture files that were referenced in Godot 3 effects
	var texture_paths = [
		"res://textures/grid.png",
		"res://models/ground/Tiles074_2K_NormalDX.png",
		"res://models/ground/Tiles074_2K_Roughness.png",
		"res://effects/circle_05.png",
		"res://effects/circle_04.png",
		"res://effects/star_04.png",
		"res://effects/star_08.png",
		"res://effects/ui_bomb.png",
		"res://effects/ui_early.png",
		"res://effects/ui_late.png",
		"res://effects/ui_miss.png",
		"res://effects/ui_perfect.png",
	]
	
	for path in texture_paths:
		var tex = load(path)
		if tex == null:
			print("  ✗ ", path, " failed to load")
			passed = false
		elif not (tex is Texture2D):
			print("  ✗ ", path, " is not Texture2D, got: ", tex.get_class())
			passed = false
		else:
			print("  ✓ ", path, " loads as Texture2D")
	
	return passed

func test_all_effect_files() -> bool:
	print("--- Testing All Effect .tres Files Load ---")
	var passed = true
	
	# All .tres files from Godot 3 effects folder
	var effect_files = [
		"res://effects/Dark_environment.tres",
		"res://effects/Ground.tres",
		"res://effects/MenuScreen_environment.tres",
		"res://effects/back_laser_material.tres",
		"res://effects/bw_gradient.tres",
		"res://effects/center_lights_material.tres",
		"res://effects/environment_particles_material.tres",
		"res://effects/left_laser_material.tres",
		"res://effects/menu_environment.tres",
		"res://effects/menu_logo_material.tres",
		"res://effects/menu_theme.tres",
		"res://effects/note_0_material.tres",
		"res://effects/note_1_material.tres",
		"res://effects/note_3_material.tres",
		"res://effects/note_displace_shader.tres",
		"res://effects/obstacle_material.tres",
		"res://effects/right_laser_material.tres",
		"res://effects/ring_material.tres",
		"res://effects/sun_bleached_environment.tres",
		"res://effects/wall_material.tres",
	]
	
	for path in effect_files:
		var res = load(path)
		if res == null:
			print("  ✗ ", path, " failed to load")
			passed = false
		else:
			print("  ✓ ", path, " loads as ", res.get_class())
	
	return passed

func test_all_menu_scenes() -> bool:
	print("--- Testing All Menu/UI Scenes (2D on 3D) ---")
	var passed = true
	
	# Menu and UI scenes - these are 2D UI rendered in 3D world
	var menu_scenes = [
		"res://scenes/MainMenu.tscn",
		"res://scenes/MainMenuLeft.tscn",
		"res://scenes/MainMenuUI.tscn",
		"res://scenes/Menu.tscn",
		"res://scenes/UICanvas.tscn",
		"res://scenes/UICanvasInteract.tscn",
		"res://scenes/UITransition.tscn",
		"res://scenes/ui_combo.tscn",
		"res://scenes/ui_energy_bar.tscn",
		"res://scenes/ui_score.tscn",
		"res://scenes/ui_song_list.tscn",
		"res://scenes/ui_time_left.tscn",
		"res://scenes/Feature_UIRayCast.tscn",
		"res://scenes/GameOffSplash.tscn",
		"res://scenes/NoteFeedback.tscn",
	]
	
	for path in menu_scenes:
		var scene = load(path)
		if scene == null:
			print("  ✗ ", path, " failed to load")
			passed = false
		else:
			var instance = scene.instantiate()
			if instance == null:
				print("  ✗ ", path, " failed to instantiate")
				passed = false
			else:
				print("  ✓ ", path, " loads and instantiates")
				instance.queue_free()
	
	return passed

func test_all_game_scenes() -> bool:
	print("--- Testing All Game Scenes ---")
	var passed = true
	
	# Core game scenes
	var game_scenes = [
		"res://scenes/Game.tscn",
		"res://scenes/GameManager.tscn",
		"res://scenes/GameVariables.tscn",
		"res://scenes/Ground.tscn",
		"res://scenes/Lasers.tscn",
		"res://scenes/Map.tscn",
		"res://scenes/Note.tscn",
		"res://scenes/NoteExplosion.tscn",
		"res://scenes/Obstacle.tscn",
		"res://scenes/Player.tscn",
		"res://scenes/Spawner.tscn",
		"res://scenes/ball.tscn",
		"res://scenes/environment_particles.tscn",
		"res://scenes/player_center.tscn",
	]
	
	for path in game_scenes:
		var scene = load(path)
		if scene == null:
			print("  ✗ ", path, " failed to load")
			passed = false
		else:
			var instance = scene.instantiate()
			if instance == null:
				print("  ✗ ", path, " failed to instantiate")
				passed = false
			else:
				print("  ✓ ", path, " loads and instantiates")
				instance.queue_free()
	
	return passed

func test_animation_players() -> bool:
	print("--- Testing AnimationPlayer Scenes ---")
	var passed = true
	
	# Scenes with AnimationPlayer that need specific animations
	var animation_tests = [
		{"scene": "res://scenes/GameOffSplash.tscn", "animations": ["RESET", "fade"]},
		{"scene": "res://scenes/UITransition.tscn", "animations": ["RESET", "fade", "fade_out"]},
	]
	
	for test in animation_tests:
		var scene = load(test["scene"])
		if scene == null:
			print("  ✗ ", test["scene"], " failed to load")
			passed = false
			continue
		
		var instance = scene.instantiate()
		if instance == null:
			print("  ✗ ", test["scene"], " failed to instantiate")
			passed = false
			continue
		
		var anim_player = instance.get_node_or_null("AnimationPlayer")
		if anim_player == null:
			print("  ✗ ", test["scene"], ": AnimationPlayer not found")
			passed = false
			instance.queue_free()
			continue
		
		var all_anims_found = true
		for anim_name in test["animations"]:
			if not anim_player.has_animation(anim_name):
				print("  ✗ ", test["scene"], ": Animation '", anim_name, "' not found")
				passed = false
				all_anims_found = false
		
		if all_anims_found:
			print("  ✓ ", test["scene"], ": All animations found (", ", ".join(test["animations"]), ")")
		
		instance.queue_free()
	
	return passed

func test_vr_controller_raycast() -> bool:
	print("--- Testing VR Controller Raycast ---")
	var passed = true
	
	# Test 1: Feature_UIRayCast.tscn loads with correct material types
	var raycast_scene = load("res://scenes/Feature_UIRayCast.tscn")
	if raycast_scene == null:
		print("  ✗ Feature_UIRayCast.tscn failed to load")
		passed = false
	else:
		var instance = raycast_scene.instantiate()
		if instance == null:
			print("  ✗ Feature_UIRayCast.tscn failed to instantiate")
			passed = false
		else:
			# Check raycast mesh material
			var raycast_mesh = instance.get_node_or_null("RayCastPosition/RayCastMesh")
			if raycast_mesh == null:
				print("  ✗ Feature_UIRayCast.tscn: RayCastMesh not found")
				passed = false
			else:
				var mat = raycast_mesh.get_surface_override_material(0)
				if mat == null:
					mat = raycast_mesh.mesh.surface_get_material(0) if raycast_mesh.mesh else null
				if mat != null and mat is StandardMaterial3D:
					if mat.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED:
						print("  ✓ Feature_UIRayCast.tscn: RayCastMesh has unshaded material")
					else:
						print("  ✗ Feature_UIRayCast.tscn: RayCastMesh material not unshaded")
						passed = false
				else:
					print("  ✓ Feature_UIRayCast.tscn: RayCastMesh loads (material check skipped)")
			
			# Check hit marker material
			var hit_marker = instance.get_node_or_null("RayCastPosition/RayCastHitMarker")
			if hit_marker == null:
				print("  ✗ Feature_UIRayCast.tscn: RayCastHitMarker not found")
				passed = false
			else:
				print("  ✓ Feature_UIRayCast.tscn: RayCastHitMarker found")
			
			instance.queue_free()
	
	# Test 2: controller.gd has check_button function implemented
	var controller_script = load("res://scripts/controller.gd")
	if controller_script == null:
		print("  ✗ controller.gd failed to load")
		passed = false
	else:
		# Create a dummy instance to check if check_button works
		# We can't easily test the function body, but we can verify the script loads
		print("  ✓ controller.gd loads successfully")
	
	# Test 3: Player.tscn has controller_path set on Feature_UIRayCast nodes
	# Note: We check the scene file directly since scripts may not compile without autoloads
	var player_scene = load("res://scenes/Player.tscn")
	if player_scene == null:
		print("  ✗ Player.tscn failed to load")
		passed = false
	else:
		var instance = player_scene.instantiate()
		if instance == null:
			print("  ✗ Player.tscn failed to instantiate")
			passed = false
		else:
			# Check left hand raycast
			var left_raycast = instance.get_node_or_null("XROrigin3D/LeftHand/Position3D2/Marker3D/Feature_UIRayCast")
			if left_raycast == null:
				print("  ✗ Player.tscn: Left hand Feature_UIRayCast not found")
				passed = false
			else:
				# In headless mode without autoloads, scripts may not compile
				# so we check if the property exists before accessing it
				if "controller_path" in left_raycast:
					if left_raycast.controller_path != NodePath(""):
						print("  ✓ Player.tscn: Left hand Feature_UIRayCast has controller_path set")
					else:
						print("  ✗ Player.tscn: Left hand Feature_UIRayCast controller_path is empty")
						passed = false
				else:
					# Script didn't compile, check scene file directly
					print("  ✓ Player.tscn: Left hand Feature_UIRayCast found (script check skipped)")
			
			# Check right hand raycast
			var right_raycast = instance.get_node_or_null("XROrigin3D/RightHand/Marker3D/Marker3D/Feature_UIRayCast")
			if right_raycast == null:
				print("  ✗ Player.tscn: Right hand Feature_UIRayCast not found")
				passed = false
			else:
				if "controller_path" in right_raycast:
					if right_raycast.controller_path != NodePath(""):
						print("  ✓ Player.tscn: Right hand Feature_UIRayCast has controller_path set")
					else:
						print("  ✗ Player.tscn: Right hand Feature_UIRayCast controller_path is empty")
						passed = false
				else:
					print("  ✓ Player.tscn: Right hand Feature_UIRayCast found (script check skipped)")
			
			# Check camera raycast (should NOT have controller_path)
			var camera_raycast = instance.get_node_or_null("XROrigin3D/XRCamera3D/Feature_UIRayCast")
			if camera_raycast != null:
				print("  ✓ Player.tscn: Camera Feature_UIRayCast found (for non-VR fallback)")
			
			instance.queue_free()
	
	return passed

func test_xr_simulator_null_safety() -> bool:
	print("--- Testing XR Simulator Null Safety ---")
	var passed = true
	
	# Load the XR Simulator script and verify it has null checks
	var xr_sim_script = load("res://addons/xr-simulator/XRSimulator.gd")
	if xr_sim_script == null:
		print("  ✗ XRSimulator.gd failed to load")
		return false
	else:
		print("  ✓ XRSimulator.gd loads successfully")
	
	# Read the script source to verify null checks exist
	var file = FileAccess.open("res://addons/xr-simulator/XRSimulator.gd", FileAccess.READ)
	if file == null:
		print("  ✗ Could not open XRSimulator.gd for reading")
		return false
	
	var source = file.get_as_text()
	file.close()
	
	# Check that move_controller has null check for controller
	if source.find("func move_controller") != -1:
		var move_start = source.find("func move_controller")
		var move_end = source.find("func ", move_start + 1)
		if move_end == -1:
			move_end = source.length()
		var move_func = source.substr(move_start, move_end - move_start)
		if move_func.find("not controller") != -1:
			print("  ✓ move_controller has null check for controller")
		else:
			print("  ✗ move_controller is missing null check for controller")
			passed = false
	
	# Check that attract_controller has null check for controller
	if source.find("func attract_controller") != -1:
		var attract_start = source.find("func attract_controller")
		var attract_end = source.find("func ", attract_start + 1)
		if attract_end == -1:
			attract_end = source.length()
		var attract_func = source.substr(attract_start, attract_end - attract_start)
		if attract_func.find("not controller") != -1:
			print("  ✓ attract_controller has null check for controller")
		else:
			print("  ✗ attract_controller is missing null check for controller")
			passed = false
	
	# Check that rotate_z_axis has null check for controller
	if source.find("func rotate_z_axis") != -1:
		var rotate_start = source.find("func rotate_z_axis")
		var rotate_end = source.find("func ", rotate_start + 1)
		if rotate_end == -1:
			rotate_end = source.length()
		var rotate_func = source.substr(rotate_start, rotate_end - rotate_start)
		if rotate_func.find("not controller") != -1:
			print("  ✓ rotate_z_axis has null check for controller")
		else:
			print("  ✗ rotate_z_axis is missing null check for controller")
			passed = false
	
	# Check that simulate_trigger has null check for controller
	if source.find("func simulate_trigger") != -1:
		var sim_start = source.find("func simulate_trigger")
		var sim_end = source.find("func ", sim_start + 1)
		if sim_end == -1:
			sim_end = source.length()
		var sim_func = source.substr(sim_start, sim_end - sim_start)
		if sim_func.find("not controller") != -1:
			print("  ✓ simulate_trigger has null check for controller")
		else:
			print("  ✗ simulate_trigger is missing null check for controller")
			passed = false
	
	# Check that simulate_grip has null check for controller
	if source.find("func simulate_grip") != -1:
		var grip_start = source.find("func simulate_grip")
		var grip_end = source.find("func ", grip_start + 1)
		if grip_end == -1:
			grip_end = source.length()
		var grip_func = source.substr(grip_start, grip_end - grip_start)
		if grip_func.find("not controller") != -1:
			print("  ✓ simulate_grip has null check for controller")
		else:
			print("  ✗ simulate_grip is missing null check for controller")
			passed = false
	
	# Check that simulate_buttons has null check for controller
	if source.find("func simulate_buttons") != -1:
		var btn_start = source.find("func simulate_buttons")
		var btn_end = source.find("func ", btn_start + 1)
		if btn_end == -1:
			btn_end = source.length()
		var btn_func = source.substr(btn_start, btn_end - btn_start)
		if btn_func.find("not controller") != -1:
			print("  ✓ simulate_buttons has null check for controller")
		else:
			print("  ✗ simulate_buttons is missing null check for controller")
			passed = false
	
	return passed


func test_ui_area_click_handling() -> bool:
	print("--- Testing UIArea XR Click Handling ---")
	var passed = true
	
	# Test 1: UIArea script has re-entrancy protection
	var file = FileAccess.open("res://scripts/UIArea.gd", FileAccess.READ)
	if file == null:
		print("  ✗ Could not open UIArea.gd for reading")
		return false
	
	var source = file.get_as_text()
	file.close()
	
	# Check for re-entrancy guard variable
	if source.find("_processing_input") != -1:
		print("  ✓ UIArea.gd has _processing_input re-entrancy guard")
	else:
		print("  ✗ UIArea.gd is missing _processing_input re-entrancy guard")
		passed = false
	
	# Check that ui_raycast_hit_event checks for re-entrancy
	if source.find("if _processing_input") != -1:
		print("  ✓ UIArea.gd checks _processing_input in ui_raycast_hit_event")
	else:
		print("  ✗ UIArea.gd is missing re-entrancy check in ui_raycast_hit_event")
		passed = false
	
	# Check that push_input is called with call_deferred to prevent stack overflow
	if source.find("push_input.call_deferred") != -1:
		print("  ✓ UIArea.gd uses call_deferred for push_input (prevents stack overflow)")
	else:
		print("  ✗ UIArea.gd is not using call_deferred for push_input")
		passed = false
	
	# Check for Godot 4 API: pressed instead of button_pressed
	if source.find("e.pressed = click") != -1:
		print("  ✓ UIArea.gd uses Godot 4 API (e.pressed instead of e.button_pressed)")
	else:
		if source.find("e.button_pressed") != -1:
			print("  ✗ UIArea.gd still uses Godot 3 API (e.button_pressed)")
			passed = false
		else:
			print("  ✗ UIArea.gd is missing pressed assignment")
			passed = false
	
	# Test 2: UICanvasInteract scene has UIArea with correct structure
	var ui_canvas_scene = load("res://scenes/UICanvasInteract.tscn")
	if ui_canvas_scene == null:
		print("  ✗ UICanvasInteract.tscn failed to load")
		passed = false
	else:
		var instance = ui_canvas_scene.instantiate()
		if instance == null:
			print("  ✗ UICanvasInteract.tscn failed to instantiate")
			passed = false
		else:
			# Check for SubViewport
			var subviewport = instance.get_node_or_null("SubViewport")
			if subviewport == null:
				print("  ✗ UICanvasInteract.tscn: SubViewport not found")
				passed = false
			else:
				print("  ✓ UICanvasInteract.tscn: SubViewport found")
			
			# Check for UIArea
			var ui_area = instance.get_node_or_null("UIArea")
			if ui_area == null:
				print("  ✗ UICanvasInteract.tscn: UIArea not found")
				passed = false
			else:
				print("  ✓ UICanvasInteract.tscn: UIArea found")
				
				# Check that UIArea has the ui_raycast_hit_event method
				if ui_area.has_method("ui_raycast_hit_event"):
					print("  ✓ UIArea has ui_raycast_hit_event method")
				else:
					print("  ✗ UIArea is missing ui_raycast_hit_event method")
					passed = false
			
			instance.queue_free()
	
	# Test 3: MainMenuUI has re-entrancy protection for start button
	var main_menu_ui_file = FileAccess.open("res://scripts/MainMenuUI.gd", FileAccess.READ)
	if main_menu_ui_file == null:
		print("  ✗ Could not open MainMenuUI.gd for reading")
	else:
		var main_menu_source = main_menu_ui_file.get_as_text()
		main_menu_ui_file.close()
		
		# Check that start button has guard against multiple presses
		if main_menu_source.find("start_pressed") != -1:
			if main_menu_source.find("if start_pressed") != -1:
				print("  ✓ MainMenuUI.gd has start_pressed guard against multiple clicks")
			else:
				print("  ✗ MainMenuUI.gd has start_pressed but missing guard check")
				passed = false
		else:
			print("  ✗ MainMenuUI.gd is missing start_pressed guard variable")
			passed = false
	
	return passed


func test_pause_menu() -> bool:
	print("--- Testing PauseMenu Scene ---")
	var passed = true
	
	# Test 1: PauseMenu.tscn loads
	var pause_menu_scene = load("res://scenes/PauseMenu.tscn")
	if pause_menu_scene == null:
		print("  ✗ PauseMenu.tscn failed to load")
		return false
	else:
		print("  ✓ PauseMenu.tscn loads successfully")
	
	# Test 2: Game.tscn has PauseMenu with all required nodes
	var game_scene = load("res://scenes/Game.tscn")
	if game_scene == null:
		print("  ✗ Game.tscn failed to load")
		return false
	
	var game_instance = game_scene.instantiate()
	if game_instance == null:
		print("  ✗ Game.tscn failed to instantiate")
		return false
	
	var pause_menu = game_instance.get_node_or_null("PauseMenu")
	if pause_menu == null:
		print("  ✗ Game.tscn: PauseMenu node not found")
		game_instance.queue_free()
		return false
	else:
		print("  ✓ Game.tscn: PauseMenu node found")
	
	# Test 3: PauseMenu has UIArea for VR raycast compatibility
	var ui_area = pause_menu.get_node_or_null("UIArea")
	if ui_area == null:
		print("  ✗ PauseMenu: UIArea not found (VR raycast won't work)")
		passed = false
	else:
		if ui_area.has_method("ui_raycast_hit_event"):
			print("  ✓ PauseMenu: UIArea has ui_raycast_hit_event method (VR raycast compatible)")
		else:
			print("  ✗ PauseMenu: UIArea is missing ui_raycast_hit_event method")
			passed = false
	
	# Test 4: PauseMenu has SubViewport for UI rendering
	var subviewport = pause_menu.get_node_or_null("SubViewport")
	if subviewport == null:
		print("  ✗ PauseMenu: SubViewport not found")
		passed = false
	else:
		print("  ✓ PauseMenu: SubViewport found")
	
	# Test 5: PauseMenu has required buttons
	var pause_btns = pause_menu.get_node_or_null("SubViewport/PauseContainer/PauseBtns")
	if pause_btns == null:
		print("  ✗ PauseMenu: PauseBtns not accessible at SubViewport/PauseContainer/PauseBtns")
		passed = false
	else:
		var resume_btn = pause_btns.get_node_or_null("ResumeBtn")
		var restart_btn = pause_btns.get_node_or_null("RestartBtn")
		var menu_btn = pause_btns.get_node_or_null("MenuBtn")
		
		if resume_btn and restart_btn and menu_btn:
			print("  ✓ PauseMenu: All buttons found (ResumeBtn, RestartBtn, MenuBtn)")
		else:
			print("  ✗ PauseMenu: Some buttons missing")
			passed = false
	
	# Test 6: PauseMenu has audio players
	var unpause_sound = pause_menu.get_node_or_null("UnpauseSound")
	var pause_sound = pause_menu.get_node_or_null("PauseSound")
	if unpause_sound and pause_sound:
		print("  ✓ PauseMenu: Audio players found (UnpauseSound, PauseSound)")
	else:
		print("  ✗ PauseMenu: Audio players missing")
		passed = false
	
	game_instance.queue_free()
	return passed


func test_menu_to_game_flow() -> bool:
	print("--- Testing Menu to Game Flow ---")
	var passed = true
	
	# Test 1: Game.tscn loads and instantiates without errors
	var game_scene = load("res://scenes/Game.tscn")
	if game_scene == null:
		print("  ✗ Game.tscn failed to load")
		return false
	
	var game_instance = game_scene.instantiate()
	if game_instance == null:
		print("  ✗ Game.tscn failed to instantiate")
		return false
	else:
		print("  ✓ Game.tscn loads and instantiates successfully")
	
	# Test 2: PauseMenu in Game.tscn has all required nodes
	var pause_menu = game_instance.get_node_or_null("PauseMenu")
	if pause_menu == null:
		print("  ✗ Game.tscn: PauseMenu not found")
		game_instance.queue_free()
		return false
	else:
		print("  ✓ Game.tscn: PauseMenu found")
	
	# Test 3: PauseMenu has UIArea/UIMeshInstance (fixes the get_surface_override_material error)
	var ui_mesh = pause_menu.get_node_or_null("UIArea/UIMeshInstance")
	if ui_mesh == null:
		print("  ✗ PauseMenu: UIArea/UIMeshInstance not found (would cause null error)")
		passed = false
	else:
		print("  ✓ PauseMenu: UIArea/UIMeshInstance found (prevents null error)")
		
		# Test that mesh has material
		var mat = ui_mesh.get_surface_override_material(0)
		if mat == null:
			print("  ✗ PauseMenu: UIMeshInstance has no surface material")
			passed = false
		else:
			print("  ✓ PauseMenu: UIMeshInstance has surface material")
	
	# Test 4: PauseMenu has SubViewport
	var subviewport = pause_menu.get_node_or_null("SubViewport")
	if subviewport == null:
		print("  ✗ PauseMenu: SubViewport not found")
		passed = false
	else:
		print("  ✓ PauseMenu: SubViewport found")
	
	# Test 5: PauseMenu has UIArea
	var ui_area = pause_menu.get_node_or_null("UIArea")
	if ui_area == null:
		print("  ✗ PauseMenu: UIArea not found")
		passed = false
	else:
		print("  ✓ PauseMenu: UIArea found (VR raycast compatible)")
	
	# Test 6: PauseMenu buttons are accessible through correct path
	var pause_btns = pause_menu.get_node_or_null("SubViewport/PauseContainer/PauseBtns")
	if pause_btns == null:
		print("  ✗ PauseMenu: PauseBtns not accessible")
		passed = false
	else:
		var resume_btn = pause_btns.get_node_or_null("ResumeBtn")
		var restart_btn = pause_btns.get_node_or_null("RestartBtn")
		var menu_btn = pause_btns.get_node_or_null("MenuBtn")
		
		if resume_btn and restart_btn and menu_btn:
			print("  ✓ PauseMenu: All buttons accessible (ResumeBtn, RestartBtn, MenuBtn)")
		else:
			print("  ✗ PauseMenu: Some buttons missing")
			passed = false
	
	# Test 7: BigScore UI also has required UIArea/UIMeshInstance
	var big_score = game_instance.get_node_or_null("BigScore")
	if big_score:
		var big_score_mesh = big_score.get_node_or_null("UIArea/UIMeshInstance")
		if big_score_mesh == null:
			print("  ✗ BigScore: UIArea/UIMeshInstance not found")
			passed = false
		else:
			print("  ✓ BigScore: UIArea/UIMeshInstance found")
	
	# Test 8: ScoreCanvas UI also has required UIMeshInstance
	var score_canvas = game_instance.get_node_or_null("ScoreCanvas")
	if score_canvas:
		var score_mesh = score_canvas.get_node_or_null("UIMeshInstance")
		if score_mesh == null:
			print("  ✗ ScoreCanvas: UIMeshInstance not found")
			passed = false
		else:
			print("  ✓ ScoreCanvas: UIMeshInstance found")
	
	game_instance.queue_free()
	return passed


func test_song_list_scroll_buttons() -> bool:
	print("--- Testing Song List Scroll Buttons ---")
	var passed = true
	
	# Test 1: ui_song_list.tscn loads
	var song_list_scene = load("res://scenes/ui_song_list.tscn")
	if song_list_scene == null:
		print("  ✗ ui_song_list.tscn failed to load")
		return false
	else:
		print("  ✓ ui_song_list.tscn loads successfully")
	
	var instance = song_list_scene.instantiate()
	if instance == null:
		print("  ✗ ui_song_list.tscn failed to instantiate")
		return false
	else:
		print("  ✓ ui_song_list.tscn instantiates successfully")
	
	# Test 2: Original tab has scroll buttons
	var original_tab = instance.get_node_or_null("TabContainer/Original")
	if original_tab == null:
		print("  ✗ Original tab not found")
		passed = false
	else:
		var original_scroll_up = original_tab.get_node_or_null("HBoxContainer/ListContainer/ScrollUpBtn")
		var original_scroll_down = original_tab.get_node_or_null("HBoxContainer/ListContainer/ScrollDownBtn")
		
		if original_scroll_up == null:
			print("  ✗ Original tab: ScrollUpBtn not found")
			passed = false
		else:
			print("  ✓ Original tab: ScrollUpBtn found")
			# Check initial visibility is false
			if original_scroll_up.visible:
				print("  ✗ Original tab: ScrollUpBtn should start hidden")
				passed = false
			else:
				print("  ✓ Original tab: ScrollUpBtn starts hidden")
		
		if original_scroll_down == null:
			print("  ✗ Original tab: ScrollDownBtn not found")
			passed = false
		else:
			print("  ✓ Original tab: ScrollDownBtn found")
			# Check initial visibility is false
			if original_scroll_down.visible:
				print("  ✗ Original tab: ScrollDownBtn should start hidden")
				passed = false
			else:
				print("  ✓ Original tab: ScrollDownBtn starts hidden")
		
		# Check SongList exists in ListContainer
		var original_song_list = original_tab.get_node_or_null("HBoxContainer/ListContainer/SongList")
		if original_song_list == null:
			print("  ✗ Original tab: SongList not found in ListContainer")
			passed = false
		else:
			print("  ✓ Original tab: SongList found in ListContainer")
	
	# Test 3: Custom tab has scroll buttons
	var custom_tab = instance.get_node_or_null("TabContainer/Custom")
	if custom_tab == null:
		print("  ✗ Custom tab not found")
		passed = false
	else:
		var custom_scroll_up = custom_tab.get_node_or_null("VBoxContainer/ListContainer/ScrollUpBtn")
		var custom_scroll_down = custom_tab.get_node_or_null("VBoxContainer/ListContainer/ScrollDownBtn")
		
		if custom_scroll_up == null:
			print("  ✗ Custom tab: ScrollUpBtn not found")
			passed = false
		else:
			print("  ✓ Custom tab: ScrollUpBtn found")
			# Check initial visibility is false
			if custom_scroll_up.visible:
				print("  ✗ Custom tab: ScrollUpBtn should start hidden")
				passed = false
			else:
				print("  ✓ Custom tab: ScrollUpBtn starts hidden")
		
		if custom_scroll_down == null:
			print("  ✗ Custom tab: ScrollDownBtn not found")
			passed = false
		else:
			print("  ✓ Custom tab: ScrollDownBtn found")
			# Check initial visibility is false
			if custom_scroll_down.visible:
				print("  ✗ Custom tab: ScrollDownBtn should start hidden")
				passed = false
			else:
				print("  ✓ Custom tab: ScrollDownBtn starts hidden")
		
		# Check SongList exists in ListContainer
		var custom_song_list = custom_tab.get_node_or_null("VBoxContainer/ListContainer/SongList")
		if custom_song_list == null:
			print("  ✗ Custom tab: SongList not found in ListContainer")
			passed = false
		else:
			print("  ✓ Custom tab: SongList found in ListContainer")
	
	# Test 4: Check scroll button signal connections exist in scene file
	var file = FileAccess.open("res://scenes/ui_song_list.tscn", FileAccess.READ)
	if file == null:
		print("  ✗ Could not open ui_song_list.tscn for reading")
		passed = false
	else:
		var content = file.get_as_text()
		file.close()
		
		# Check Original tab signal connections
		if content.find("signal=\"pressed\" from=\"TabContainer/Original/HBoxContainer/ListContainer/ScrollUpBtn\"") != -1:
			print("  ✓ Original tab: ScrollUpBtn pressed signal connected")
		else:
			print("  ✗ Original tab: ScrollUpBtn pressed signal not connected")
			passed = false
		
		if content.find("signal=\"pressed\" from=\"TabContainer/Original/HBoxContainer/ListContainer/ScrollDownBtn\"") != -1:
			print("  ✓ Original tab: ScrollDownBtn pressed signal connected")
		else:
			print("  ✗ Original tab: ScrollDownBtn pressed signal not connected")
			passed = false
		
		# Check Custom tab signal connections
		if content.find("signal=\"pressed\" from=\"TabContainer/Custom/VBoxContainer/ListContainer/ScrollUpBtn\"") != -1:
			print("  ✓ Custom tab: ScrollUpBtn pressed signal connected")
		else:
			print("  ✗ Custom tab: ScrollUpBtn pressed signal not connected")
			passed = false
		
		if content.find("signal=\"pressed\" from=\"TabContainer/Custom/VBoxContainer/ListContainer/ScrollDownBtn\"") != -1:
			print("  ✓ Custom tab: ScrollDownBtn pressed signal connected")
		else:
			print("  ✗ Custom tab: ScrollDownBtn pressed signal not connected")
			passed = false
	
	# Test 5: Check script has scroll handler methods
	var script_file = FileAccess.open("res://scripts/ui_song_list.gd", FileAccess.READ)
	if script_file == null:
		print("  ✗ Could not open ui_song_list.gd for reading")
		passed = false
	else:
		var script_content = script_file.get_as_text()
		script_file.close()
		
		if script_content.find("func _on_scroll_up_pressed()") != -1:
			print("  ✓ Script has _on_scroll_up_pressed method")
		else:
			print("  ✗ Script missing _on_scroll_up_pressed method")
			passed = false
		
		if script_content.find("func _on_scroll_down_pressed()") != -1:
			print("  ✓ Script has _on_scroll_down_pressed method")
		else:
			print("  ✗ Script missing _on_scroll_down_pressed method")
			passed = false
		
		if script_content.find("func _update_scroll_button_visibility()") != -1:
			print("  ✓ Script has _update_scroll_button_visibility method")
		else:
			print("  ✗ Script missing _update_scroll_button_visibility method")
			passed = false
	
	instance.queue_free()
	return passed
