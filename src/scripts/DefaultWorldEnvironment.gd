extends WorldEnvironment


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
func _on_Sky_texture_sky_updated():
	$Sky_texture.copy_to_environment($WorldEnvironment.environment)
		# set the time of day to 10:30am
	$Sky_texture.set_time_of_day(15.5, get_node("DirectionalLight3D"), deg_to_rad(15.0))
