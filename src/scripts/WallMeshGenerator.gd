@tool
class_name WallMeshGenerator
extends RefCounted

## Generates wall meshes for PowerBeatsVR wall types
## Based on geometry extracted from PowerBeatsVR Unity assets

# Wall type constants (matching PowerBeatsVRMap.gd)
const WALL_SINGLE_COLUMN = 0
const WALL_DOUBLE_COLUMN = 1
const WALL_ARCHWAY_CENTER = 2
const WALL_ARCHWAY_LEFT = 3
const WALL_ARCHWAY_RIGHT = 4
const WALL_OPENING_LEFT = 5
const WALL_OPENING_RIGHT = 6
const WALL_BAR_FOREHEAD = 7

# Default dimensions based on PowerBeatsVR analysis
# Total play area: X = -1.7 to 1.7, Y = 0 to 2.5
const WALL_WIDTH = 3.4       # Full width
const WALL_HEIGHT = 2.5      # Full height  
const WALL_DEPTH = 1.0       # Z depth
const OPENING_HEIGHT = 1.5   # Height of the opening (Y = 0 to 1.5)
const HALF_WIDTH = 1.7       # Half of wall width


static func generate_wall_mesh(wall_type: int) -> ArrayMesh:
	"""Generate an ArrayMesh for the given wall type."""
	match wall_type:
		WALL_SINGLE_COLUMN:
			return _generate_column_mesh(0.5)  # Narrow column
		WALL_DOUBLE_COLUMN:
			return _generate_column_mesh(1.0)  # Wide column
		WALL_ARCHWAY_CENTER:
			return _generate_archway_mesh(0.0)  # Centered
		WALL_ARCHWAY_LEFT:
			return _generate_archway_mesh(-0.6)  # Offset left
		WALL_ARCHWAY_RIGHT:
			return _generate_archway_mesh(0.6)  # Offset right
		WALL_OPENING_LEFT:
			return _generate_opening_left_mesh()
		WALL_OPENING_RIGHT:
			return _generate_opening_right_mesh()
		WALL_BAR_FOREHEAD:
			return _generate_bar_mesh()
		_:
			# Fallback to simple box
			return _generate_box_mesh(WALL_WIDTH, WALL_HEIGHT, WALL_DEPTH)


static func generate_collision_shapes(wall_type: int) -> Array:
	"""
	Generate collision shape data for the given wall type.
	Returns an array of dictionaries: [{shape: BoxShape3D, offset: Vector3}, ...]
	For compound shapes (like OpeningLeft), returns multiple shapes.
	"""
	match wall_type:
		WALL_SINGLE_COLUMN:
			return _collision_shapes_column(0.5)
		WALL_DOUBLE_COLUMN:
			return _collision_shapes_column(1.0)
		WALL_ARCHWAY_CENTER:
			return _collision_shapes_archway(0.0)
		WALL_ARCHWAY_LEFT:
			return _collision_shapes_archway(-0.6)
		WALL_ARCHWAY_RIGHT:
			return _collision_shapes_archway(0.6)
		WALL_OPENING_LEFT:
			return _collision_shapes_opening_left()
		WALL_OPENING_RIGHT:
			return _collision_shapes_opening_right()
		WALL_BAR_FOREHEAD:
			return _collision_shapes_bar()
		_:
			# Fallback to simple full-size box
			return _collision_shapes_box(WALL_WIDTH, WALL_HEIGHT, WALL_DEPTH)


static func _collision_shapes_box(width: float, height: float, depth: float) -> Array:
	"""Create a single centered box collision shape."""
	var shape = BoxShape3D.new()
	shape.size = Vector3(width, height, depth)
	return [{
		"shape": shape,
		"offset": Vector3(0, height / 2.0, depth / 2.0)
	}]


static func _collision_shapes_column(width: float) -> Array:
	"""Create collision for column walls (Types 0, 1)."""
	var shape = BoxShape3D.new()
	shape.size = Vector3(width, WALL_HEIGHT, WALL_DEPTH)
	return [{
		"shape": shape,
		"offset": Vector3(0, WALL_HEIGHT / 2.0, WALL_DEPTH / 2.0)
	}]


static func _collision_shapes_opening_left() -> Array:
	"""
	Create collision shapes for OpeningLeft (Type 5).
	Two boxes: right column (full height) + left header (top only).
	"""
	var shapes = []
	
	# Right column: X: 0 to 1.7, Y: 0 to 2.5
	var right_shape = BoxShape3D.new()
	right_shape.size = Vector3(HALF_WIDTH, WALL_HEIGHT, WALL_DEPTH)
	shapes.append({
		"shape": right_shape,
		"offset": Vector3(HALF_WIDTH / 2.0, WALL_HEIGHT / 2.0, WALL_DEPTH / 2.0)
	})
	
	# Left header: X: -1.7 to 0, Y: 1.5 to 2.5
	var header_height = WALL_HEIGHT - OPENING_HEIGHT
	var left_shape = BoxShape3D.new()
	left_shape.size = Vector3(HALF_WIDTH, header_height, WALL_DEPTH)
	shapes.append({
		"shape": left_shape,
		"offset": Vector3(-HALF_WIDTH / 2.0, OPENING_HEIGHT + header_height / 2.0, WALL_DEPTH / 2.0)
	})
	
	return shapes


static func _collision_shapes_opening_right() -> Array:
	"""
	Create collision shapes for OpeningRight (Type 6).
	Two boxes: left column (full height) + right header (top only).
	"""
	var shapes = []
	
	# Left column: X: -1.7 to 0, Y: 0 to 2.5
	var left_shape = BoxShape3D.new()
	left_shape.size = Vector3(HALF_WIDTH, WALL_HEIGHT, WALL_DEPTH)
	shapes.append({
		"shape": left_shape,
		"offset": Vector3(-HALF_WIDTH / 2.0, WALL_HEIGHT / 2.0, WALL_DEPTH / 2.0)
	})
	
	# Right header: X: 0 to 1.7, Y: 1.5 to 2.5
	var header_height = WALL_HEIGHT - OPENING_HEIGHT
	var right_shape = BoxShape3D.new()
	right_shape.size = Vector3(HALF_WIDTH, header_height, WALL_DEPTH)
	shapes.append({
		"shape": right_shape,
		"offset": Vector3(HALF_WIDTH / 2.0, OPENING_HEIGHT + header_height / 2.0, WALL_DEPTH / 2.0)
	})
	
	return shapes


static func _collision_shapes_archway(x_offset: float) -> Array:
	"""
	Create collision shapes for archway walls (Types 2, 3, 4).
	Three boxes: left wall, right wall, lintel above arch.
	"""
	var shapes = []
	var arch_width = 1.0
	var arch_height = 1.2
	
	# Left wall: X: -1.7 to (x_offset - arch_width/2)
	var left_width = (x_offset - arch_width / 2.0) - (-HALF_WIDTH)
	if left_width > 0.01:
		var left_shape = BoxShape3D.new()
		left_shape.size = Vector3(left_width, WALL_HEIGHT, WALL_DEPTH)
		var left_center_x = -HALF_WIDTH + left_width / 2.0
		shapes.append({
			"shape": left_shape,
			"offset": Vector3(left_center_x, WALL_HEIGHT / 2.0, WALL_DEPTH / 2.0)
		})
	
	# Right wall: X: (x_offset + arch_width/2) to 1.7
	var right_width = HALF_WIDTH - (x_offset + arch_width / 2.0)
	if right_width > 0.01:
		var right_shape = BoxShape3D.new()
		right_shape.size = Vector3(right_width, WALL_HEIGHT, WALL_DEPTH)
		var right_center_x = (x_offset + arch_width / 2.0) + right_width / 2.0
		shapes.append({
			"shape": right_shape,
			"offset": Vector3(right_center_x, WALL_HEIGHT / 2.0, WALL_DEPTH / 2.0)
		})
	
	# Lintel: above the arch opening
	var lintel_height = WALL_HEIGHT - arch_height
	var lintel_shape = BoxShape3D.new()
	lintel_shape.size = Vector3(arch_width, lintel_height, WALL_DEPTH)
	shapes.append({
		"shape": lintel_shape,
		"offset": Vector3(x_offset, arch_height + lintel_height / 2.0, WALL_DEPTH / 2.0)
	})
	
	return shapes


static func _collision_shapes_bar() -> Array:
	"""Create collision shape for bar wall (Type 7)."""
	var bar_bottom = 1.5
	var bar_height = 0.3
	
	var shape = BoxShape3D.new()
	shape.size = Vector3(WALL_WIDTH, bar_height, WALL_DEPTH)
	return [{
		"shape": shape,
		"offset": Vector3(0, bar_bottom + bar_height / 2.0, WALL_DEPTH / 2.0)
	}]


static func _generate_opening_left_mesh() -> ArrayMesh:
	"""
	Generate OpeningLeft wall (Type 5).
	Wall with opening on the LEFT side - player passes through left.
	
	Structure (front view):
	    Y=2.5  ████████████████████████
	           ████  HEADER  ████████████
	    Y=1.5  ████████████████████████
	           ░░░░░░░░░░░░████████████  
	    Y=0    ░░ OPENING ░░████ WALL ██
	          X=-1.7     X=0       X=1.7
	"""
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# The wall consists of two boxes:
	# 1. Right column: full height (X: 0 to 1.7, Y: 0 to 2.5)
	# 2. Left header: top only (X: -1.7 to 0, Y: 1.5 to 2.5)
	
	# Right column (full height)
	_add_box_to_surface(surface_tool, 
		Vector3(0, 0, 0),           # min
		Vector3(HALF_WIDTH, WALL_HEIGHT, WALL_DEPTH))  # max
	
	# Left header (above opening)
	_add_box_to_surface(surface_tool,
		Vector3(-HALF_WIDTH, OPENING_HEIGHT, 0),  # min
		Vector3(0, WALL_HEIGHT, WALL_DEPTH))       # max
	
	surface_tool.generate_normals()
	return surface_tool.commit()


static func _generate_opening_right_mesh() -> ArrayMesh:
	"""
	Generate OpeningRight wall (Type 6).
	Wall with opening on the RIGHT side - player passes through right.
	Mirror of OpeningLeft.
	"""
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Left column (full height)
	_add_box_to_surface(surface_tool,
		Vector3(-HALF_WIDTH, 0, 0),
		Vector3(0, WALL_HEIGHT, WALL_DEPTH))
	
	# Right header (above opening)
	_add_box_to_surface(surface_tool,
		Vector3(0, OPENING_HEIGHT, 0),
		Vector3(HALF_WIDTH, WALL_HEIGHT, WALL_DEPTH))
	
	surface_tool.generate_normals()
	return surface_tool.commit()


static func _generate_column_mesh(width: float) -> ArrayMesh:
	"""
	Generate a vertical column wall (Types 0, 1).
	Centered column that blocks the middle.
	"""
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var half_w = width / 2.0
	_add_box_to_surface(surface_tool,
		Vector3(-half_w, 0, 0),
		Vector3(half_w, WALL_HEIGHT, WALL_DEPTH))
	
	surface_tool.generate_normals()
	return surface_tool.commit()


static func _generate_archway_mesh(x_offset: float) -> ArrayMesh:
	"""
	Generate an archway wall (Types 2, 3, 4).
	Walls on left and right with an arch in the middle to duck under.
	
	For simplicity, we create a rectangular opening (not curved arch).
	"""
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var arch_width = 1.0  # Width of the archway opening
	var arch_height = 1.2  # Height player can duck under
	
	# Left wall
	_add_box_to_surface(surface_tool,
		Vector3(-HALF_WIDTH, 0, 0),
		Vector3(x_offset - arch_width/2, WALL_HEIGHT, WALL_DEPTH))
	
	# Right wall
	_add_box_to_surface(surface_tool,
		Vector3(x_offset + arch_width/2, 0, 0),
		Vector3(HALF_WIDTH, WALL_HEIGHT, WALL_DEPTH))
	
	# Top lintel (above the arch)
	_add_box_to_surface(surface_tool,
		Vector3(x_offset - arch_width/2, arch_height, 0),
		Vector3(x_offset + arch_width/2, WALL_HEIGHT, WALL_DEPTH))
	
	surface_tool.generate_normals()
	return surface_tool.commit()


static func _generate_bar_mesh() -> ArrayMesh:
	"""
	Generate BarAcrossTheForehead wall (Type 7).
	A horizontal bar at head height that player ducks under.
	"""
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var bar_bottom = 1.5  # Bottom of bar (player ducks below this)
	var bar_height = 0.3  # Thickness of bar
	
	_add_box_to_surface(surface_tool,
		Vector3(-HALF_WIDTH, bar_bottom, 0),
		Vector3(HALF_WIDTH, bar_bottom + bar_height, WALL_DEPTH))
	
	surface_tool.generate_normals()
	return surface_tool.commit()


static func _generate_box_mesh(width: float, height: float, depth: float) -> ArrayMesh:
	"""Generate a simple centered box mesh."""
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	_add_box_to_surface(surface_tool,
		Vector3(-width/2, 0, 0),
		Vector3(width/2, height, depth))
	
	surface_tool.generate_normals()
	return surface_tool.commit()


static func _add_box_to_surface(st: SurfaceTool, min_pos: Vector3, max_pos: Vector3):
	"""Add a box (6 faces, 12 triangles) to the SurfaceTool."""
	var p = [
		Vector3(min_pos.x, min_pos.y, min_pos.z),  # 0: front bottom left
		Vector3(max_pos.x, min_pos.y, min_pos.z),  # 1: front bottom right
		Vector3(max_pos.x, max_pos.y, min_pos.z),  # 2: front top right
		Vector3(min_pos.x, max_pos.y, min_pos.z),  # 3: front top left
		Vector3(min_pos.x, min_pos.y, max_pos.z),  # 4: back bottom left
		Vector3(max_pos.x, min_pos.y, max_pos.z),  # 5: back bottom right
		Vector3(max_pos.x, max_pos.y, max_pos.z),  # 6: back top right
		Vector3(min_pos.x, max_pos.y, max_pos.z),  # 7: back top left
	]
	
	# Calculate UVs based on position (simple planar mapping)
	var _size = max_pos - min_pos
	
	# Front face (Z = min)
	_add_quad(st, p[0], p[1], p[2], p[3], Vector3(0, 0, -1))
	
	# Back face (Z = max)
	_add_quad(st, p[5], p[4], p[7], p[6], Vector3(0, 0, 1))
	
	# Left face (X = min)
	_add_quad(st, p[4], p[0], p[3], p[7], Vector3(-1, 0, 0))
	
	# Right face (X = max)
	_add_quad(st, p[1], p[5], p[6], p[2], Vector3(1, 0, 0))
	
	# Top face (Y = max)
	_add_quad(st, p[3], p[2], p[6], p[7], Vector3(0, 1, 0))
	
	# Bottom face (Y = min)
	_add_quad(st, p[4], p[5], p[1], p[0], Vector3(0, -1, 0))


static func _add_quad(st: SurfaceTool, v0: Vector3, v1: Vector3, v2: Vector3, v3: Vector3, normal: Vector3):
	"""Add a quad (2 triangles) to the SurfaceTool."""
	# Simple UV mapping
	var uv0 = Vector2(0, 1)
	var uv1 = Vector2(1, 1)
	var uv2 = Vector2(1, 0)
	var uv3 = Vector2(0, 0)
	
	# Triangle 1: v0, v1, v2
	st.set_normal(normal)
	st.set_uv(uv0)
	st.add_vertex(v0)
	st.set_uv(uv1)
	st.add_vertex(v1)
	st.set_uv(uv2)
	st.add_vertex(v2)
	
	# Triangle 2: v0, v2, v3
	st.set_normal(normal)
	st.set_uv(uv0)
	st.add_vertex(v0)
	st.set_uv(uv2)
	st.add_vertex(v2)
	st.set_uv(uv3)
	st.add_vertex(v3)


static func get_wall_type_name(wall_type: int) -> String:
	"""Get human-readable name for wall type."""
	match wall_type:
		WALL_SINGLE_COLUMN: return "SingleColumn"
		WALL_DOUBLE_COLUMN: return "DoubleColumn"
		WALL_ARCHWAY_CENTER: return "ArchwayCenter"
		WALL_ARCHWAY_LEFT: return "ArchwayLeft"
		WALL_ARCHWAY_RIGHT: return "ArchwayRight"
		WALL_OPENING_LEFT: return "OpeningLeft"
		WALL_OPENING_RIGHT: return "OpeningRight"
		WALL_BAR_FOREHEAD: return "BarForehead"
		_: return "Unknown"
