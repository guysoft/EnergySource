extends Spatial

export(float) var speed = 2
export(Vector3) var direction = Vector3(0,0,1)

onready var _velocity = Vector3(0,0,0)

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
