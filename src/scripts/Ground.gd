extends StaticBody3D
## =============================================================================
## MICRO CONVEYOR BELT GROUND SYSTEM
## =============================================================================
##
## This script implements smooth infinite scrolling terrain without vertex
## "pumping" artifacts that occur with pure shader-based UV scrolling.
##
## HOW IT WORKS:
## 1. The mesh physically moves toward the player (positive Z direction)
## 2. When it moves one subdivision period, it snaps back to start
## 3. The UV offset increments to compensate, keeping texture continuous
## 4. Result: Vertices move WITH the mesh instead of sampling moving noise
##
## This eliminates the "ripple" effect where vertices appear to pulse up/down
## as noise values scroll through fixed vertex positions.
##
## DEBUG MODE:
## Call set_debug_mode(true) to enable height visualization:
## - Red = peaks, Green = middle, Blue = valleys
## - White grid lines show UV boundaries
## =============================================================================

@export var ground_size: float = 8.0
@export var subdivisions: int = 128  # Match the mesh subdivisions
@export var grid_scale: float = 2.0  # Grid texture repetitions (lower = bigger squares)

# Calculated at runtime
var subdivision_period_world: float  # How far mesh moves before reset
var subdivision_period_uv: float     # How much UV offsets on reset
var mesh_offset_z: float = 0.0       # Current mesh Z position
var uv_accumulated_offset: float = 0.0  # Accumulated UV offset
var speed: float = 0.0               # Current scroll speed

var material: ShaderMaterial
var ground_shape: MeshInstance3D


func _ready():
	ground_shape = $GroundShape
	
	# Get the actual mesh scale from the transform (GroundShape has scale applied)
	var mesh_scale_z = ground_shape.transform.basis.get_scale().z
	
	# Calculate subdivision periods accounting for mesh scale
	# World: physical distance mesh moves before reset (in parent/world space)
	# The mesh is scaled, so world_size = mesh_size * scale
	var world_size_z = ground_size * mesh_scale_z
	subdivision_period_world = world_size_z / float(subdivisions)
	
	# UV: how much to offset UV when mesh resets (in scaled UV space)
	subdivision_period_uv = (1.0 / float(subdivisions)) * grid_scale
	
	# Get material for shader parameter updates
	material = ground_shape.get_surface_override_material(0)
	if material == null:
		material = ground_shape.get_active_material(0)


func _process(delta: float):
	if speed == 0.0 or material == null:
		return
	
	var movement = speed * delta
	mesh_offset_z += movement  # Move positive Z (terrain scrolls toward player)
	
	# Check if we've moved more than one subdivision period
	while mesh_offset_z >= subdivision_period_world:
		mesh_offset_z -= subdivision_period_world  # Snap back
		uv_accumulated_offset += subdivision_period_uv  # Increment UV offset
	
	# Apply mesh position offset
	ground_shape.position.z = mesh_offset_z
	
	# Update shader with accumulated UV offset
	material.set_shader_parameter("uv_offset_z", uv_accumulated_offset)


func setup_ground(bpm: float, delay: float, color):
	## Setup the ground with BPM-synced scrolling speed
	## Called by GameManager when a song starts
	
	if ground_shape == null:
		ground_shape = $GroundShape
	
	# Update mesh size
	ground_shape.mesh.size = Vector2(ground_size, ground_size)
	
	# Get material
	material = ground_shape.get_surface_override_material(0)
	if material == null:
		material = ground_shape.get_active_material(0)
	if material == null:
		push_warning("Ground: No material found on GroundShape")
		return
	
	# Set grid texture scale (controls how many times grid repeats)
	# Lower value = bigger grid squares
	material.set_shader_parameter("uv1_scale", Vector3(grid_scale, grid_scale, grid_scale))
	
	# Set mesh size for triplanar offset calculation
	# (needed to convert UV-space offset to VERTEX-space offset)
	material.set_shader_parameter("mesh_size_z", ground_size)
	
	# Get the actual mesh scale from the transform
	var mesh_scale_z = ground_shape.transform.basis.get_scale().z
	var world_size_z = ground_size * mesh_scale_z
	
	# Recalculate periods based on current settings (accounting for scale)
	subdivision_period_world = world_size_z / float(subdivisions)
	subdivision_period_uv = (1.0 / float(subdivisions)) * grid_scale
	
	# Calculate scroll speed from BPM
	# Speed = distance per beat * beats per second
	speed = bpm / 60.0 * ground_size / delay
	
	# Set color
	if color is Color:
		material.set_shader_parameter("albedo", color)
	
	# Reset state for new song
	reset_ground()


func reset_ground():
	## Reset terrain to initial state (useful when restarting game)
	mesh_offset_z = 0.0
	uv_accumulated_offset = 0.0
	if ground_shape:
		ground_shape.position.z = 0.0
	if material:
		material.set_shader_parameter("uv_offset_z", 0.0)


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
