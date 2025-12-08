extends GPUParticles3D

func _ready():
	pass

func setup_particles(bpm, delay):
	var speed = bpm / 60 * 16 / delay
	# Godot 4: initial_velocity was split into initial_velocity_min and initial_velocity_max
	process_material.initial_velocity_min = speed
	process_material.initial_velocity_max = speed
