extends Area

class_name Note

var speed = 2
export(Vector3) var direction = Vector3(0,0,1)
export(float) var despawn_z = 12.0

onready var _velocity = Vector3(0,0,0)

var _time:float
var _line_index:int
var _line_layer:int
var _type:int
var _cut_direction:int
var _custom_data = {}

#Refs
onready var _animation_player = $AnimationPlayer
onready var _mesh = $MeshInstance as MeshInstance
onready var _collision = $CollisionShape
onready var _spawn_timer = $Timer

func _ready():
	deactivate()

func setup_note(note, speed, bpm):
	self.speed = speed
	if not note:
		return
	
	transform.origin = Vector3(note["x"], note["y"], 0)
	
	#if the note has an offset, set up the timer to match
	if note["offset"] > 0.0:
		_spawn_timer.wait_time = note["offset"] * bpm / 60
	
	#set the material based on the note type
	var mat = _mesh.get_active_material(0)
	if note["_type"] == 0:
		mat.albedo_color = Color.red
		mat.emission = Color.red
	elif note["_type"] == 1:
		mat.albedo_color = Color.blue
		mat.emission = Color.blue
	elif note["_type"] == 3:
		mat.albedo_color = Color.white
		mat.emission = Color.white

func activate():
#	print ("note activated: ", name)
#	print ("time: ", _time)
#	print ("line index: ", _line_index)
#	print ("line layer: ", _line_layer)
#	print ("type: ", _type)
#	print ("time: ", _cut_direction)
#	print ("custom_data: ", _custom_data)
	
	#if the spawn timer has been setup with an offset
	#start the timer and wait until it's done
	if _spawn_timer.wait_time > 0.001:
		_spawn_timer.start()
		yield(_spawn_timer, "timeout")
	
	set_physics_process(true)
	_collision.set_deferred("disabled", false)
	_animation_player.play("spawn")

func deactivate():
	_animation_player.play("despawn")
	set_physics_process(false)
	_collision.set_deferred("disabled", true)
	
func _physics_process(delta):
	_velocity = direction * speed * delta
	translate(_velocity)
	
	if self.transform.origin.z > despawn_z:
		self.deactivate()
