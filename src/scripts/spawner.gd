extends Node

@export var active: bool = false
@export var spawn_time: float = 1.0
@export var spawn_object: PackedScene
@export var bounding_box: AABB

#Does this need be unique? Consider moving to a utility singleton
@onready var _rand = RandomNumberGenerator.new()
@onready var _timer = $Timer


func _ready():
	_rand.randomize()
	_timer.wait_time = spawn_time
	_timer.start()

func spawn():
	if not active:
		return

	var spawn_instance = spawn_object.instantiate()
	
	spawn_instance.transform.origin = Vector3(
		_rand.randf_range(bounding_box.position.x, bounding_box.end.x),
		_rand.randf_range(bounding_box.position.y, bounding_box.end.y),
		_rand.randf_range(bounding_box.position.z, bounding_box.end.z)
	)
	
	self.add_child(spawn_instance)


func _on_Timer_timeout():
	spawn()
