extends MeshInstance3D
## =============================================================================
## MICRO CONVEYOR BELT TEST SCRIPT (Standalone)
## =============================================================================
##
## This is a standalone version of the micro conveyor system for testing.
## Use with GroundCurveTest.tscn to debug terrain scrolling without game deps.
##
## HOW IT WORKS:
## 1. The mesh physically moves toward the player (positive Z direction)
## 2. When it moves one subdivision period, it snaps back to start
## 3. The UV offset increments to compensate, keeping texture continuous
##
## DEBUG MODE:
## Call set_debug_mode(true) to enable height visualization:
## - Red = peaks, Green = middle, Blue = valleys
## - White grid lines show UV boundaries
##
## CONTROLS (in test scene):
## - Just runs automatically at constant speed
## - Press D to toggle debug mode
## =============================================================================

@export var mesh_size: float = 100.0  # Matches PlaneMesh size
@export var subdivisions: int = 128   # Must match mesh subdivide_width/depth
@export var grid_scale: float = 4.0   # UV scale (texture repetitions)
@export var speed: float = 2.0        # Scroll speed in world units/sec

# Calculated at runtime
var subdivision_period_world: float
var subdivision_period_uv: float
var mesh_offset_z: float = 0.0
var uv_accumulated_offset: float = 0.0

var material: ShaderMaterial
var debug_mode: bool = false


func _ready():
	# Calculate subdivision periods
	subdivision_period_world = mesh_size / float(subdivisions)
	subdivision_period_uv = (1.0 / float(subdivisions)) * grid_scale
	
	# Get material
	material = get_surface_override_material(0)
	if material == null:
		material = get_active_material(0)
	
	if material:
		# Set mesh size for triplanar coordinate conversion
		material.set_shader_parameter("mesh_size_z", mesh_size)
		material.set_shader_parameter("uv1_scale", Vector3(grid_scale, grid_scale, grid_scale))
		
		# Enable debug mode by default for test scene
		set_debug_mode(true)
	
	print("GroundMicroConveyor: Ready")
	print("  mesh_size: ", mesh_size)
	print("  subdivisions: ", subdivisions)
	print("  grid_scale: ", grid_scale)
	print("  world_period: ", subdivision_period_world)
	print("  uv_period: ", subdivision_period_uv)


func _process(delta: float):
	if speed == 0.0 or material == null:
		return
	
	var movement = speed * delta
	mesh_offset_z += movement
	
	# Check if we've moved more than one subdivision period
	while mesh_offset_z >= subdivision_period_world:
		mesh_offset_z -= subdivision_period_world  # Snap back
		uv_accumulated_offset += subdivision_period_uv  # Increment UV offset
	
	# Apply mesh position offset
	position.z = mesh_offset_z
	
	# Update shader with accumulated UV offset
	material.set_shader_parameter("uv_offset_z", uv_accumulated_offset)


func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_D:
			set_debug_mode(not debug_mode)
			print("Debug mode: ", debug_mode)


func set_debug_mode(enabled: bool):
	## Enable/disable debug height coloring
	## Red = peaks, Green = middle, Blue = valleys
	debug_mode = enabled
	if material:
		material.set_shader_parameter("debug_height_colors", enabled)


func set_curved_world(enabled: bool, strength: float = 0.002):
	## Enable/disable curved world effect (horizon hiding)
	if material:
		material.set_shader_parameter("enable_curve", enabled)
		material.set_shader_parameter("curve_strength", strength)
