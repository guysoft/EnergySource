extends StaticBody3D

@export var ground_size = 4.0

func _ready():
	pass

func setup_ground(bpm, delay, color):
	$GroundShape.mesh.size = Vector2(ground_size,ground_size)
	var mat = $GroundShape.get_surface_override_material(0)
	if mat == null:
		# Try to get the active material if no override is set
		mat = $GroundShape.get_active_material(0)
	if mat == null:
		push_warning("Ground: No material found on GroundShape")
		return
	mat.set_shader_parameter("uv1_scale",Vector3(ground_size,ground_size,ground_size))
	var speed = bpm / 60 * ground_size / delay
	mat.set_shader_parameter("speed_mult", speed)
	
	if color is Color:
		mat.set_shader_parameter("albedo", color)
