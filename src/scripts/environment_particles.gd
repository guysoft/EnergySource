extends Particles

func _ready():
	pass

func setup_particles(bpm, delay):
	var speed = bpm / 60 * 16 / delay
	process_material.initial_velocity = speed;
