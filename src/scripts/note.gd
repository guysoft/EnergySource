extends Area

class_name Obstacle

enum {HIT, MISS}

var speed = 2

export(Array, ShaderMaterial) var materials = []
export(PackedScene) var hit_effect
export(PackedScene) var feedback_effect
export(Vector3) var direction = Vector3(0,0,1)
export(float) var despawn_z = 12.0

onready var _velocity = Vector3(0,0,0)

#Values used for note bounce
var _bpm
var _bounce_time = 0
var bounce_freq = 0
var _y_offset = 0

var _time:float
var _line_index:int
var _line_layer:int
var _type:int
var _cut_direction:int
var _custom_data = {}

var alive = false
var been_hit = false

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
	
	_y_offset = note["y"]
	
	despawn_z = distance
	
	_bpm = bpm
	
	bounce_freq = (_bpm/60) * speed
	
	_time = note["_time"]
	_type = note["_type"]
	
	#if the note has an offset, set up the timer to match
	if not is_equal_approx(note["offset"],0.0):
		var calc_offset = note["offset"] * 60 / bpm
		_bounce_time = calc_offset
		_spawn_timer.wait_time = calc_offset
		#print ("Note offset: ", note["offset"])
		#print ("wait time: ", _spawn_timer.wait_time)
		
	#set the material based on the note type
	#var mat = _mesh.get_active_material(0) as ShaderMaterial
	if note["_type"] == 0:
		_mesh.material_override = materials[0]
	elif note["_type"] == 1:
		#Color.
		_mesh.material_override = materials[1]
#		mat.set_shader_param("albedo_color", Color.palegreen)
#		mat.set_shader_param("emission_color", Color.palegreen * 1.0)
#		mat.set_shader_param("albedo_color", Color.palegreen)
#		mat.set_shader_param("emission_color", Color.palegreen * 1.0)
	elif note["_type"] == 3: 
		_mesh.material_override = materials[2]
#		mat.set_shader_param("albedo_color", Color.aquamarine)
#		mat.set_shader_param("emission_color", Color.aquamarine * 1.0)
#		mat.albedo_color = Color.white
#		mat.emission = Color.white * 5.0

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
func on_hit(velocity, linear_velocity, hit_accuracy):
	if been_hit:
		return
	
	been_hit = true
	
	#_audio_stream_player.play()
	if velocity:
		direction = velocity.normalized()
	if linear_velocity:
		speed = linear_velocity
	
	spawn_feedback(hit_accuracy)
	
	if hit_accuracy>0.0 and hit_accuracy<3.0:
		spawn_hit_effect()
	#if hit_accuracy==25:
		#spawn_bomb_effect()
	
	_collision.set_deferred("disabled", true)
	
	despawn(HIT)

func spawn_hit_effect():
	var hit_effect_instance = hit_effect.instance()
	get_tree().current_scene.add_child(hit_effect_instance)
	hit_effect_instance.setup_effect(global_transform.origin, speed)

func spawn_feedback(accuracy):
	var feedback_instance = feedback_effect.instance()
	get_tree().current_scene.add_child(feedback_instance)
	feedback_instance.show_feedback(global_transform.origin, accuracy)

func despawn(type):
	if not alive:
		return
	
	alive = false
	
	_animation_player.play("despawn")
	
	_collision.set_deferred("disabled", true)
	
	if type==HIT:
		print ("hit")
		
	elif type==MISS and not been_hit:
		print ("miss")
		spawn_feedback(-10) #sufficiently high value to ensure a miss
		#bad reference, replace with signal
		Global.manager()._player.combo = 0
		
	yield(_animation_player, "animation_finished")
	deactivate()

#DISABLED AS IT DOESN'T WORK
#func bounce_note():
	#var bounce = cos(_bounce_time*bounce_freq)*0.05
	#transform.origin.y = _y_offset - bounce
	#_bounce_time+=delta

func _physics_process(delta):
	_velocity = direction * speed * delta #consider moving to setup if it doesn't change
	
	#bounce_note()
	
	translate(_velocity)
	
	if self.transform.origin.z > despawn_z+(speed*0.25):
		self.despawn(MISS)
