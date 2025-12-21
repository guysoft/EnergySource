extends SceneTree

# Unit tests for WallMeshGenerator
# Run with: godot --headless --script res://tests/test_wall_generation.gd

# Load scripts manually for headless testing
var WallMeshGeneratorScript = preload("res://scripts/WallMeshGenerator.gd")


func _init():
	print("\n=== Wall Mesh Generation Tests ===\n")
	var all_passed = true
	
	all_passed = test_all_wall_types_generate_mesh() and all_passed
	all_passed = test_mesh_vertex_counts() and all_passed
	all_passed = test_collision_shapes_valid() and all_passed
	all_passed = test_opening_left_collision_count() and all_passed
	all_passed = test_opening_right_collision_count() and all_passed
	all_passed = test_archway_collision_count() and all_passed
	all_passed = test_simple_wall_collision_count() and all_passed
	all_passed = test_wall_type_names() and all_passed
	
	# Summary
	print("\n=== Test Summary ===")
	if all_passed:
		print("✓ ALL TESTS PASSED")
	else:
		print("✗ SOME TESTS FAILED")
	
	quit(0 if all_passed else 1)


func test_all_wall_types_generate_mesh() -> bool:
	print("--- Testing All Wall Types Generate Valid Mesh ---")
	var passed = true
	
	for wall_type in range(8):
		var mesh = WallMeshGeneratorScript.generate_wall_mesh(wall_type)
		var type_name = WallMeshGeneratorScript.get_wall_type_name(wall_type)
		
		if mesh == null:
			print("  ✗ Wall type %d (%s) returned null mesh" % [wall_type, type_name])
			passed = false
			continue
		
		if not mesh is ArrayMesh:
			print("  ✗ Wall type %d (%s) did not return ArrayMesh" % [wall_type, type_name])
			passed = false
			continue
		
		var surface_count = mesh.get_surface_count()
		if surface_count == 0:
			print("  ✗ Wall type %d (%s) has no surfaces" % [wall_type, type_name])
			passed = false
			continue
		
		print("  ✓ Wall type %d (%s) generated valid mesh with %d surface(s)" % [wall_type, type_name, surface_count])
	
	return passed


func test_mesh_vertex_counts() -> bool:
	print("--- Testing Mesh Vertex Counts ---")
	var passed = true
	
	# Each box has 6 faces * 2 triangles * 3 vertices = 36 vertices
	# Expected vertex counts based on the number of boxes in each mesh:
	# SingleColumn: 1 box = 36
	# DoubleColumn: 1 box = 36
	# OpeningLeft/Right: 2 boxes = 72
	# Archway (3 boxes): 3 boxes = 108
	# Bar: 1 box = 36
	
	var expected_min_vertices = {
		WallMeshGeneratorScript.WALL_SINGLE_COLUMN: 36,
		WallMeshGeneratorScript.WALL_DOUBLE_COLUMN: 36,
		WallMeshGeneratorScript.WALL_ARCHWAY_CENTER: 108,
		WallMeshGeneratorScript.WALL_ARCHWAY_LEFT: 108,
		WallMeshGeneratorScript.WALL_ARCHWAY_RIGHT: 108,
		WallMeshGeneratorScript.WALL_OPENING_LEFT: 72,
		WallMeshGeneratorScript.WALL_OPENING_RIGHT: 72,
		WallMeshGeneratorScript.WALL_BAR_FOREHEAD: 36,
	}
	
	for wall_type in expected_min_vertices:
		var mesh = WallMeshGeneratorScript.generate_wall_mesh(wall_type)
		var type_name = WallMeshGeneratorScript.get_wall_type_name(wall_type)
		
		if mesh == null or mesh.get_surface_count() == 0:
			print("  ✗ Wall type %d (%s) has no mesh" % [wall_type, type_name])
			passed = false
			continue
		
		# Get vertex count from first surface
		var arrays = mesh.surface_get_arrays(0)
		var vertex_array = arrays[Mesh.ARRAY_VERTEX]
		var vertex_count = vertex_array.size()
		var expected = expected_min_vertices[wall_type]
		
		if vertex_count < expected:
			print("  ✗ Wall type %d (%s): expected >= %d vertices, got %d" % [wall_type, type_name, expected, vertex_count])
			passed = false
		else:
			print("  ✓ Wall type %d (%s): %d vertices (expected >= %d)" % [wall_type, type_name, vertex_count, expected])
	
	return passed


func test_collision_shapes_valid() -> bool:
	print("--- Testing Collision Shapes Are Valid ---")
	var passed = true
	
	for wall_type in range(8):
		var shapes = WallMeshGeneratorScript.generate_collision_shapes(wall_type)
		var type_name = WallMeshGeneratorScript.get_wall_type_name(wall_type)
		
		if shapes == null or shapes.size() == 0:
			print("  ✗ Wall type %d (%s) returned no collision shapes" % [wall_type, type_name])
			passed = false
			continue
		
		var all_valid = true
		for i in range(shapes.size()):
			var shape_data = shapes[i]
			
			if not shape_data.has("shape") or not shape_data.has("offset"):
				print("  ✗ Wall type %d (%s) shape %d missing 'shape' or 'offset' key" % [wall_type, type_name, i])
				all_valid = false
				continue
			
			var shape = shape_data["shape"]
			var offset = shape_data["offset"]
			
			if not shape is BoxShape3D:
				print("  ✗ Wall type %d (%s) shape %d is not BoxShape3D" % [wall_type, type_name, i])
				all_valid = false
				continue
			
			if shape.size.x <= 0 or shape.size.y <= 0 or shape.size.z <= 0:
				print("  ✗ Wall type %d (%s) shape %d has invalid size: %s" % [wall_type, type_name, i, shape.size])
				all_valid = false
				continue
			
			if not offset is Vector3:
				print("  ✗ Wall type %d (%s) shape %d offset is not Vector3" % [wall_type, type_name, i])
				all_valid = false
		
		if all_valid:
			print("  ✓ Wall type %d (%s): %d valid collision shape(s)" % [wall_type, type_name, shapes.size()])
		else:
			passed = false
	
	return passed


func test_opening_left_collision_count() -> bool:
	print("--- Testing OpeningLeft Has 2 Collision Shapes ---")
	
	var shapes = WallMeshGeneratorScript.generate_collision_shapes(WallMeshGeneratorScript.WALL_OPENING_LEFT)
	
	if shapes.size() == 2:
		print("  ✓ OpeningLeft has 2 collision shapes (right column + left header)")
		return true
	else:
		print("  ✗ OpeningLeft should have 2 collision shapes, got %d" % shapes.size())
		return false


func test_opening_right_collision_count() -> bool:
	print("--- Testing OpeningRight Has 2 Collision Shapes ---")
	
	var shapes = WallMeshGeneratorScript.generate_collision_shapes(WallMeshGeneratorScript.WALL_OPENING_RIGHT)
	
	if shapes.size() == 2:
		print("  ✓ OpeningRight has 2 collision shapes (left column + right header)")
		return true
	else:
		print("  ✗ OpeningRight should have 2 collision shapes, got %d" % shapes.size())
		return false


func test_archway_collision_count() -> bool:
	print("--- Testing Archway Walls Have 3 Collision Shapes ---")
	var passed = true
	
	for wall_type in [WallMeshGeneratorScript.WALL_ARCHWAY_CENTER, 
					   WallMeshGeneratorScript.WALL_ARCHWAY_LEFT, 
					   WallMeshGeneratorScript.WALL_ARCHWAY_RIGHT]:
		var shapes = WallMeshGeneratorScript.generate_collision_shapes(wall_type)
		var type_name = WallMeshGeneratorScript.get_wall_type_name(wall_type)
		
		if shapes.size() == 3:
			print("  ✓ %s has 3 collision shapes (left wall + right wall + lintel)" % type_name)
		else:
			print("  ✗ %s should have 3 collision shapes, got %d" % [type_name, shapes.size()])
			passed = false
	
	return passed


func test_simple_wall_collision_count() -> bool:
	print("--- Testing Simple Walls Have 1 Collision Shape ---")
	var passed = true
	
	for wall_type in [WallMeshGeneratorScript.WALL_SINGLE_COLUMN, 
					   WallMeshGeneratorScript.WALL_DOUBLE_COLUMN, 
					   WallMeshGeneratorScript.WALL_BAR_FOREHEAD]:
		var shapes = WallMeshGeneratorScript.generate_collision_shapes(wall_type)
		var type_name = WallMeshGeneratorScript.get_wall_type_name(wall_type)
		
		if shapes.size() == 1:
			print("  ✓ %s has 1 collision shape" % type_name)
		else:
			print("  ✗ %s should have 1 collision shape, got %d" % [type_name, shapes.size()])
			passed = false
	
	return passed


func test_wall_type_names() -> bool:
	print("--- Testing Wall Type Names ---")
	var passed = true
	
	var expected_names = {
		0: "SingleColumn",
		1: "DoubleColumn",
		2: "ArchwayCenter",
		3: "ArchwayLeft",
		4: "ArchwayRight",
		5: "OpeningLeft",
		6: "OpeningRight",
		7: "BarForehead"
	}
	
	for wall_type in expected_names:
		var name = WallMeshGeneratorScript.get_wall_type_name(wall_type)
		var expected = expected_names[wall_type]
		
		if name == expected:
			print("  ✓ Wall type %d -> '%s'" % [wall_type, name])
		else:
			print("  ✗ Wall type %d: expected '%s', got '%s'" % [wall_type, expected, name])
			passed = false
	
	# Test unknown type
	var unknown = WallMeshGeneratorScript.get_wall_type_name(99)
	if unknown == "Unknown":
		print("  ✓ Unknown wall type returns 'Unknown'")
	else:
		print("  ✗ Unknown wall type should return 'Unknown', got '%s'" % unknown)
		passed = false
	
	return passed

