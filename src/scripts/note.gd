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

var alive = false

#Refs
onready var _audio_stream_player = $AudioStreamPlayer3D
onready var _animation_player = $AnimationPlayer
onready var _mesh = $MeshInstance as MeshInstance
onready var _collision = $CollisionShape
onready var _spawn_timer = $Timer

func _ready():
	deactivate(false)

func setup_note(note, speed, bpm, distance):
	self.speed = speed
	if not note:
		return
	
	transform.origin = Vector3(note["x"], note["y"], 0)
	
	despawn_z = distance
	
	#if the note has an offset, set up the timer to match
	if note["offset"] > 0.0:
		_spawn_timer.wait_time = note["offset"] * 60 / bpm
		print ("Note offset: ", note["offset"])
		print ("wait time: ", _spawn_timer.wait_time)
	
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
	#if the spawn timer has been setup with an offset
	#start the timer and wait until it's done
	if alive:
		return
	
	alive = true
	
	if _spawn_timer.wait_time > 0.001:
		_spawn_timer.start()
		yield(_spawn_timer, "timeout")
	
	set_physics_process(true)
	_collision.set_deferred("disabled", false)
	_animation_player.play("spawn")

func deactivate(delete:bool = true, delete_delay:float=1.0):
	set_physics_process(false)
	_collision.set_deferred("disabled", true)
	if delete:
		yield (get_tree().create_timer(delete_delay), "timeout")
		queue_free()
	
func on_hit(velocity, linear_velocity):
	_audio_stream_player.play()
	direction = velocity.normalize()
	speed = linear_velocity
	despawn()
	
func despawn():
	if not alive:
		return
	
	alive = false
	
	_animation_player.play("despawn")
	yield(_animation_player, "animation_finished")
	deactivate()

func _physics_process(delta):
	_velocity = direction * speed * delta
	translate(_velocity)
	
	if self.transform.origin.z > despawn_z:
		self.despawn()
