extends StaticBody

export var ground_size = 4.0

func _ready():
	pass

func setup_ground(bpm, delay):
	$GroundShape.mesh.size = Vector2(ground_size,ground_size)
	var mat = $GroundShape.get_surface_material(0)
	mat.set_shader_param("uv1_scale",Vector3(ground_size,ground_size,ground_size))
	var speed = bpm / 60 * ground_size / delay
	$GroundShape.get_surface_material(0).set_shader_param("speed_mult", speed)
