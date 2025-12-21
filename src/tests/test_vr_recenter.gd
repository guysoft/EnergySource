extends SceneTree

# Unit tests for VRRecenter functionality
# Run with: godot --headless --script res://tests/test_vr_recenter.gd

# Preload scripts for headless testing (autoloads not available)
var SettingsScript = preload("res://scripts/Settings.gd")

func _init():
	print("\n=== VR Recenter Unit Tests ===\n")
	var all_passed = true
	
	# Test 1: Settings script loads with VR section
	all_passed = test_settings_vr_section() and all_passed
	
	# Test 2: Rotation offset calculation
	all_passed = test_rotation_offset_calculation() and all_passed
	
	# Test 3: Position offset calculation
	all_passed = test_position_offset_calculation() and all_passed
	
	# Test 4: Edge cases
	all_passed = test_edge_cases() and all_passed
	
	# Test 5: Settings get/set with defaults
	all_passed = test_settings_get_with_default() and all_passed
	
	print("\n=== Test Summary ===")
	if all_passed:
		print("✓ ALL VR RECENTER TESTS PASSED")
	else:
		print("✗ SOME VR RECENTER TESTS FAILED")
	
	quit(0 if all_passed else 1)


func test_settings_vr_section() -> bool:
	print("--- Testing Settings VR Section ---")
	var passed = true
	
	if SettingsScript == null:
		print("  ✗ Settings.gd failed to load")
		return false
	
	print("  ✓ Settings.gd loads successfully")
	
	var instance = SettingsScript.new()
	if instance == null:
		print("  ✗ Failed to instantiate Settings")
		return false
	
	# Check VR section exists in default settings
	if not instance._settings.has("vr"):
		print("  ✗ Default _settings missing 'vr' section")
		passed = false
	else:
		print("  ✓ Default _settings has 'vr' section")
		
		var vr = instance._settings["vr"]
		
		if not vr.has("recenter_offset_position"):
			print("  ✗ vr missing 'recenter_offset_position' field")
			passed = false
		else:
			var pos = vr["recenter_offset_position"]
			if not pos is Vector3:
				print("  ✗ 'recenter_offset_position' is not Vector3: ", typeof(pos))
				passed = false
			elif pos != Vector3.ZERO:
				print("  ✗ 'recenter_offset_position' default is not Vector3.ZERO: ", pos)
				passed = false
			else:
				print("  ✓ 'recenter_offset_position' is Vector3.ZERO")
		
		if not vr.has("recenter_offset_rotation"):
			print("  ✗ vr missing 'recenter_offset_rotation' field")
			passed = false
		else:
			var rot = vr["recenter_offset_rotation"]
			if not (rot is float or rot is int):
				print("  ✗ 'recenter_offset_rotation' is not a number: ", typeof(rot))
				passed = false
			elif rot != 0.0:
				print("  ✗ 'recenter_offset_rotation' default is not 0.0: ", rot)
				passed = false
			else:
				print("  ✓ 'recenter_offset_rotation' is 0.0")
	
	instance.free()
	return passed


# Copy of VRRecenter.calculate_rotation_offset for testing
func _calculate_rotation_offset(camera_forward: Vector3) -> float:
	"""Calculate the Y rotation offset given a camera forward direction."""
	var forward = camera_forward
	forward.y = 0
	if forward.length_squared() < 0.001:
		return 0.0
	forward = forward.normalized()
	
	var world_forward = Vector3(0, 0, -1)
	return forward.signed_angle_to(world_forward, Vector3.UP)


# Copy of VRRecenter.calculate_position_offset for testing
func _calculate_position_offset(camera_position: Vector3, rotation_offset: float) -> Vector3:
	"""Calculate the position offset given camera position and rotation offset."""
	var offset = Vector3(-camera_position.x, 0, -camera_position.z)
	return offset.rotated(Vector3.UP, rotation_offset)


func test_rotation_offset_calculation() -> bool:
	print("--- Testing Rotation Offset Calculation ---")
	var passed = true
	
	# Test cases: [camera_forward, expected_angle_degrees]
	# The rotation offset rotates XROrigin3D so world forward aligns with where camera faces
	var test_cases = [
		# Camera facing forward (-Z) should give 0 rotation
		[Vector3(0, 0, -1), 0.0],
		# Camera facing right (+X): rotate origin +90° so -Z content appears at +X
		[Vector3(1, 0, 0), 90.0],
		# Camera facing left (-X): rotate origin -90° so -Z content appears at -X
		[Vector3(-1, 0, 0), -90.0],
		# Camera facing backward (+Z) should give 180 degrees
		[Vector3(0, 0, 1), 180.0],
		# Camera facing 45 degrees right: +45° rotation
		[Vector3(1, 0, -1).normalized(), 45.0],
		# Camera facing 45 degrees left: -45° rotation
		[Vector3(-1, 0, -1).normalized(), -45.0],
	]
	
	for test in test_cases:
		var camera_forward = test[0]
		var expected_degrees = test[1]
		var result_radians = _calculate_rotation_offset(camera_forward)
		var result_degrees = rad_to_deg(result_radians)
		
		# Allow small floating point tolerance
		if abs(result_degrees - expected_degrees) > 0.1:
			# Handle 180/-180 equivalence
			if abs(abs(result_degrees) - 180.0) < 0.1 and abs(abs(expected_degrees) - 180.0) < 0.1:
				print("  ✓ rotation_offset(", camera_forward, ") = ", snapped(result_degrees, 0.1), "° (±180 equivalent)")
			else:
				print("  ✗ rotation_offset(", camera_forward, ") = ", snapped(result_degrees, 0.1), "°, expected ", expected_degrees, "°")
				passed = false
		else:
			print("  ✓ rotation_offset(", camera_forward, ") = ", snapped(result_degrees, 0.1), "°")
	
	return passed


func test_position_offset_calculation() -> bool:
	print("--- Testing Position Offset Calculation ---")
	var passed = true
	
	# Test cases: [camera_position, rotation_offset_radians, expected_offset]
	var test_cases = [
		# Camera at origin, no rotation: offset should be zero
		[Vector3(0, 1.5, 0), 0.0, Vector3(0, 0, 0)],
		# Camera at (1, 1.5, 0), no rotation: offset should be (-1, 0, 0)
		[Vector3(1, 1.5, 0), 0.0, Vector3(-1, 0, 0)],
		# Camera at (0, 1.5, 2), no rotation: offset should be (0, 0, -2)
		[Vector3(0, 1.5, 2), 0.0, Vector3(0, 0, -2)],
		# Camera at (1, 1.5, 1), no rotation: offset should be (-1, 0, -1)
		[Vector3(1, 1.5, 1), 0.0, Vector3(-1, 0, -1)],
	]
	
	for test in test_cases:
		var camera_pos = test[0]
		var rotation_offset = test[1]
		var expected = test[2]
		var result = _calculate_position_offset(camera_pos, rotation_offset)
		
		# Allow small floating point tolerance
		if result.distance_to(expected) > 0.01:
			print("  ✗ position_offset(", camera_pos, ", ", rotation_offset, ") = ", result, ", expected ", expected)
			passed = false
		else:
			print("  ✓ position_offset(", camera_pos, ", ", rotation_offset, ") = ", result)
	
	return passed


func test_edge_cases() -> bool:
	print("--- Testing Edge Cases ---")
	var passed = true
	
	# Test 1: Vertical camera forward (looking up/down) - should handle gracefully
	var vertical_forward = Vector3(0, 1, 0)  # Looking straight up
	var result = _calculate_rotation_offset(vertical_forward)
	if is_nan(result) or is_inf(result):
		print("  ✗ Vertical camera forward produced NaN/Inf: ", result)
		passed = false
	else:
		print("  ✓ Vertical camera forward handled: ", snapped(rad_to_deg(result), 0.1), "°")
	
	# Test 2: Zero vector (shouldn't happen but let's be safe)
	var zero_forward = Vector3(0, 0, 0)
	result = _calculate_rotation_offset(zero_forward)
	if is_nan(result) or is_inf(result):
		print("  ✗ Zero vector produced NaN/Inf: ", result)
		passed = false
	else:
		print("  ✓ Zero vector handled: ", snapped(rad_to_deg(result), 0.1), "°")
	
	# Test 3: Nearly vertical forward with tiny horizontal component
	var nearly_vertical = Vector3(0.001, 0.999, 0).normalized()
	result = _calculate_rotation_offset(nearly_vertical)
	if is_nan(result) or is_inf(result):
		print("  ✗ Nearly vertical forward produced NaN/Inf: ", result)
		passed = false
	else:
		print("  ✓ Nearly vertical forward handled: ", snapped(rad_to_deg(result), 0.1), "°")
	
	return passed


func test_settings_get_with_default() -> bool:
	print("--- Testing Settings get_setting with default ---")
	var passed = true
	
	var instance = SettingsScript.new()
	if instance == null:
		print("  ✗ Failed to instantiate Settings")
		return false
	
	# Test getting existing value
	var pos = instance.get_setting("vr", "recenter_offset_position", Vector3.ONE)
	if pos != Vector3.ZERO:
		print("  ✗ get_setting for existing key returned wrong value: ", pos)
		passed = false
	else:
		print("  ✓ get_setting for existing key returns correct value")
	
	# Test getting non-existent section with default
	var missing_section = instance.get_setting("nonexistent", "key", "default_value")
	if missing_section != "default_value":
		print("  ✗ get_setting for missing section didn't return default: ", missing_section)
		passed = false
	else:
		print("  ✓ get_setting for missing section returns default")
	
	# Test getting non-existent key with default
	var missing_key = instance.get_setting("vr", "nonexistent_key", 42)
	if missing_key != 42:
		print("  ✗ get_setting for missing key didn't return default: ", missing_key)
		passed = false
	else:
		print("  ✓ get_setting for missing key returns default")
	
	instance.free()
	return passed
