extends Spatial

var vel

func setup_effect(position:Vector3, speed:float):
	var mat = $Sparks.process_material as ParticlesMaterial
	mat.gravity = Vector3(0,2.0,0)
	global_transform.origin = position
	vel = Vector3(0,0,speed);
	$Sparks.emitting=true
	$CenterSpark.emitting = true
	yield(get_tree().create_timer(2.0),"timeout")
	queue_free()

func _physics_process(delta):
	translate(vel*delta)
