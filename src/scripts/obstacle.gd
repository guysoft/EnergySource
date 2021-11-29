extends Area

class_name Note

var speed = 2
export(Vector3) var direction = Vector3(0,0,1)
export(float) var despawn_z = 12.0

onready var _velocity = Vector3(0,0,0)
const bs_level_width = 4
const bs_level_height = 3

var _time:float
var _line_index:int
var _line_layer:int
var _type:int
var _cut_direction:int
var _custom_data = {}

var alive = false

# TODO get this from mesh size
var size_x = 0.5
var size_y = 0.5
var size_z = 0.5

#Refs
onready var _audio_stream_player = $AudioStreamPlayer3D
onready var _animation_player = $AnimationPlayer
onready var _mesh = $MeshInstance as MeshInstance
onready var _collision = $CollisionShape
onready var _spawn_timer = $Timer

func _ready():
	deactivate(false)

func setup_obstacle(obstacle, speed, bpm, distance):
	self.speed = speed
	if not obstacle:
		return
	
	print(obstacle["x1"])
	print(obstacle["y1"])
	var scale_x = 0
	var scale_y = 0
	var scale_z = 0
	var padding_x = 0
	var padding_y = 0
	
	if obstacle["type"] == "full_height":
		scale_x = obstacle["width"]
		scale_y = bs_level_height
		padding_x = (obstacle["width"] - 1) * size_x / 2.0
	elif obstacle["type"] == "crouch":
		scale_x = bs_level_width
		scale_y = obstacle["width"]
		padding_y = (obstacle["width"] - 1) * size_x / 2.0
		padding_x = (bs_level_width - 3) / 2.0 + 0.25
	print("got: " + obstacle["type"])
	print("width: " + str(obstacle["width"]))
	print("index: " + str(obstacle["_lineIndex"]))
		
	var z = obstacle["duration"] * bpm / 60 * (1/size_z)
	transform.origin = Vector3(obstacle["x1"] + padding_x, obstacle["y1"] + padding_y, -z)
	self.scale_object_local(Vector3(scale_x, scale_y, z))
	
	
	
	despawn_z = distance
	
	#if the note has an offset, set up the timer to match
	if obstacle["offset"] > 0.0:
		_spawn_timer.wait_time = obstacle["offset"] * 60 / bpm
		print ("Obstacle offset: ", obstacle["offset"])
		print ("wait time: ", _spawn_timer.wait_time)
		
#	var mat = _mesh.get_active_material(0)
#	mat.albedo_color = Color.green
#	mat.emission = Color.green
		
	""""	
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
	"""

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

#TODO: Take into account the controller position of the hit?
func on_hit(velocity, linear_velocity):
	_audio_stream_player.play()
	direction = velocity.normalized()
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
	global_translate(_velocity)
	
	if self.transform.origin.z > despawn_z:
		self.despawn()
