extends StaticBody3D
## =============================================================================
## DUAL MESH CONVEYOR BELT GROUND SYSTEM
## =============================================================================
##
## This script implements smooth infinite scrolling terrain that is compatible
## with Meta SpaceWarp frame prediction. It uses TWO meshes that leapfrog each
## other, teleporting only when fully out of view behind the player.
##
## HOW IT WORKS:
## 1. Two meshes (A and B) both move continuously in +Z direction
## 2. When a mesh goes fully behind the player, it teleports ahead of the other
## 3. Each mesh has its own UV offset (via instance uniform) that increments on teleport
## 4. Result: Smooth motion that SpaceWarp can predict correctly
##
## WHY THIS FIXES SPACEWARP:
## - Old system: mesh snapped back every 0.5 units (visible discontinuity)
## - New system: mesh teleports every ~64 units when fully behind player (invisible)
## - SpaceWarp sees consistent +Z motion vectors, predicts correctly
##
## DEBUG MODE:
## Call set_debug_mode(true) to enable height visualization:
## - Red = peaks, Green = middle, Blue = valleys
## - White grid lines show UV boundaries
## =============================================================================

@export var ground_size: float = 8.0
@export var subdivisions: int = 128  # Match the mesh subdivisions
@export var grid_scale: float = 2.0  # Grid texture repetitions (lower = bigger squares)

# Dual mesh system
var mesh_a: MeshInstance3D
var mesh_b: MeshInstance3D
var uv_offset_a: float = 0.0
var uv_offset_b: float = 0.0  # Set in _ready based on initial position

# Teleport parameters (calculated at runtime)
var teleport_threshold: float  # When mesh.position.z > this, teleport
var teleport_distance: float   # How far to jump back (2 mesh lengths)
var uv_per_teleport: float     # UV increment per teleport
var world_size: float          # Full mesh size in world space

# Subdivision periods (for UV calculation)
var subdivision_period_world: float
var subdivision_period_uv: float

var speed: float = 0.0
var material: ShaderMaterial


func _ready():
	mesh_a = $GroundShapeA
	mesh_b = $GroundShapeB
	
	# Get the actual mesh scale from the transform
	var mesh_scale_z = mesh_a.transform.basis.get_scale().z
	
	# Calculate world size (mesh local size * scale)
	world_size = ground_size * mesh_scale_z
	
	# Calculate subdivision periods (kept for UV calculations)
	subdivision_period_world = world_size / float(subdivisions)
	subdivision_period_uv = (1.0 / float(subdivisions)) * grid_scale
	
	# Teleport parameters
	# Threshold: when mesh center is one world_size behind player origin (fully out of view)
	teleport_threshold = world_size
	# Distance: jump back 2 mesh lengths to land ahead of the other mesh
	teleport_distance = world_size * 2.0
	# UV: how much UV offset to add per teleport (2 mesh lengths worth)
	uv_per_teleport = (teleport_distance / subdivision_period_world) * subdivision_period_uv
	
	# Initial UV offset for mesh B (it's one world_size ahead, so one mesh-length of UV)
	var uv_per_mesh_length = (world_size / subdivision_period_world) * subdivision_period_uv
	uv_offset_b = uv_per_mesh_length  # 2.0 with default settings
	
	# Get material for non-instance shader parameters
	material = mesh_a.get_surface_override_material(0)
	if material == null:
		material = mesh_a.get_active_material(0)
	
	# Apply initial UV offsets
	mesh_a.set_instance_shader_parameter("uv_offset_z", uv_offset_a)
	mesh_b.set_instance_shader_parameter("uv_offset_z", uv_offset_b)


func _process(delta: float):
	if speed == 0.0:
		return
	
	var movement = speed * delta
	
	# Both meshes always move forward (+Z direction, toward player)
	# This creates smooth, predictable motion for SpaceWarp
	mesh_a.position.z += movement
	mesh_b.position.z += movement
	
	# Teleport when fully behind player (out of view)
	if mesh_a.position.z > teleport_threshold:
		mesh_a.position.z -= teleport_distance
		uv_offset_a += uv_per_teleport
		mesh_a.set_instance_shader_parameter("uv_offset_z", uv_offset_a)
	
	if mesh_b.position.z > teleport_threshold:
		mesh_b.position.z -= teleport_distance
		uv_offset_b += uv_per_teleport
		mesh_b.set_instance_shader_parameter("uv_offset_z", uv_offset_b)


func setup_ground(bpm: float, delay: float, color):
	## Setup the ground with BPM-synced scrolling speed
	## Called by GameManager when a song starts
	
	if mesh_a == null:
		mesh_a = $GroundShapeA
	if mesh_b == null:
		mesh_b = $GroundShapeB
	
	# Update mesh size on both meshes
	mesh_a.mesh.size = Vector2(ground_size, ground_size)
	mesh_b.mesh.size = Vector2(ground_size, ground_size)
	
	# Get material for non-instance parameters
	material = mesh_a.get_surface_override_material(0)
	if material == null:
		material = mesh_a.get_active_material(0)
	if material == null:
		push_warning("Ground: No material found on GroundShapeA")
		return
	
	# Set grid texture scale (controls how many times grid repeats)
	material.set_shader_parameter("uv1_scale", Vector3(grid_scale, grid_scale, grid_scale))
	
	# Set mesh size for triplanar offset calculation
	material.set_shader_parameter("mesh_size_z", ground_size)
	
	# Recalculate parameters based on current settings
	var mesh_scale_z = mesh_a.transform.basis.get_scale().z
	world_size = ground_size * mesh_scale_z
	subdivision_period_world = world_size / float(subdivisions)
	subdivision_period_uv = (1.0 / float(subdivisions)) * grid_scale
	teleport_threshold = world_size
	teleport_distance = world_size * 2.0
	uv_per_teleport = (teleport_distance / subdivision_period_world) * subdivision_period_uv
	
	# Calculate scroll speed from BPM
	speed = bpm / 60.0 * ground_size / delay
	
	# Set color
	if color is Color:
		material.set_shader_parameter("albedo", color)
	
	# Reset state for new song
	reset_ground()


func reset_ground():
	## Reset terrain to initial state (useful when restarting game)
	
	# Reset positions: A at origin, B one world_size ahead (-Z direction)
	if mesh_a:
		mesh_a.position.z = 0.0
	if mesh_b:
		mesh_b.position.z = -world_size
	
	# Reset UV offsets
	# A starts at 0, B is one mesh-length ahead in UV space
	var uv_per_mesh_length = (world_size / subdivision_period_world) * subdivision_period_uv
	uv_offset_a = 0.0
	uv_offset_b = uv_per_mesh_length  # 2.0 with default settings
	
	# Apply UV offsets via instance parameters
	if mesh_a:
		mesh_a.set_instance_shader_parameter("uv_offset_z", uv_offset_a)
	if mesh_b:
		mesh_b.set_instance_shader_parameter("uv_offset_z", uv_offset_b)


func set_debug_mode(enabled: bool):
	## Enable/disable debug height coloring
	## Red = peaks, Green = middle, Blue = valleys
	## White grid lines show UV cell boundaries
	if material:
		material.set_shader_parameter("debug_height_colors", enabled)


func set_curved_world(enabled: bool, strength: float = 0.002):
	## Enable/disable curved world effect (horizon hiding)
	## strength: how much to curve (0.001-0.01 typical)
	if material:
		material.set_shader_parameter("enable_curve", enabled)
		material.set_shader_parameter("curve_strength", strength)
