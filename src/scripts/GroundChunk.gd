extends MeshInstance3D
## =============================================================================
## GROUND CHUNK SCRIPT (For individual terrain pieces)
## =============================================================================
##
## A simplified version of the micro conveyor system for smaller terrain chunks.
## Use for testing individual ground pieces or creating modular terrain.
##
## Unlike GroundMicroConveyor.gd, this one doesn't scroll automatically.
## It just demonstrates the debug coloring on a static ground piece.
## =============================================================================

@export var mesh_size: float = 8.0    # Matches PlaneMesh size
@export var grid_scale: float = 2.0   # UV scale
@export var auto_debug: bool = true   # Enable debug mode on start

var material: ShaderMaterial


func _ready():
	# Get material
	material = get_surface_override_material(0)
	if material == null:
		material = get_active_material(0)
	
	if material:
		material.set_shader_parameter("mesh_size_z", mesh_size)
		material.set_shader_parameter("uv1_scale", Vector3(grid_scale, grid_scale, grid_scale))
		
		if auto_debug:
			set_debug_mode(true)
	
	print("GroundChunk: Ready (static, for testing)")


func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_D:
			var current = material.get_shader_parameter("debug_height_colors")
			set_debug_mode(not current)
			print("Debug mode: ", not current)


func set_debug_mode(enabled: bool):
	## Enable/disable debug height coloring
	if material:
		material.set_shader_parameter("debug_height_colors", enabled)

