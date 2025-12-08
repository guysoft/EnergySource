extends Node3D

@export var speed: float = 2
@export var direction: Vector3 = Vector3(0,0,1)

@onready var _velocity = Vector3(0,0,0)

func _ready():
	pass
	# print("ball created")
	
func _physics_process(delta):
	_velocity = direction * speed * delta
	translate(_velocity)
	
	if self.transform.origin.z > 4:
		# print("ball freed")
		self.queue_free()

func _process(delta):
	pass
