extends Area3D

class_name Obstacle

enum {HIT, MISS}

var speed = 2

@export var materials = [] # (Array, ShaderMaterial)
@export var hit_effect: PackedScene
@export var feedback_effect: PackedScene
@export var direction: Vector3 = Vector3(0,0,1)
@export var despawn_z: float = 12.0

@onready var _velocity = Vector3(0,0,0)

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
var _is_power_ball: bool = false  # PowerBalls require 4x velocity to hit

var alive = false
var been_hit = false

#Refs
@onready var _audio_stream_player = $AudioStreamPlayer3D
@onready var _animation_player = $AnimationPlayer
@onready var _mesh = $MeshInstance3D as MeshInstance3D
@onready var _collision = $CollisionShape3D
@onready var _spawn_timer = $Timer

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
		
	# Check if this is a PowerBall (requires 4x velocity to hit)
	_is_power_ball = note.get("_is_power_ball", false)
	
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
	
	# Apply purple tint for PowerBalls (must be after material is set)
	if _is_power_ball:
		_set_ball_purple()

func activate():
	#if the spawn timer has been setup with an offset
	#start the timer and wait until it's done
	if alive:
		return
	
	alive = true
	
	if _spawn_timer.wait_time > 0.001:
		_spawn_timer.start()
		await _spawn_timer.timeout
	
	set_physics_process(true)
	_collision.set_deferred("disabled", false)
	_animation_player.play("spawn")

func deactivate(delete:bool = true, delete_delay:float=1.0):
	set_physics_process(false)
	_collision.set_deferred("disabled", true)
	if delete:
		await get_tree().create_timer(delete_delay).timeout
		queue_free()

# HitLevel enum values (must match player.gd)
const HIT_LEVEL_TOOLOW = 0
const HIT_LEVEL_MINIMUMIMPACT = 1
const HIT_LEVEL_FULLIMPACT = 2

#TODO: Take into account the controller position of the hit?
func on_hit(velocity, linear_velocity, hit_level):
	if been_hit:
		return
	
	been_hit = true
	
	# Play hit sound
	_audio_stream_player.play()
	if velocity:
		direction = velocity.normalized()
	if linear_velocity:
		speed = linear_velocity
	
	spawn_feedback(0, hit_level)
	
	# Visual feedback based on hit level
	if hit_level == HIT_LEVEL_TOOLOW:
		# Turn ball black to indicate weak hit (didn't score)
		_set_ball_dark()
	elif hit_level == HIT_LEVEL_MINIMUMIMPACT or hit_level == HIT_LEVEL_FULLIMPACT:
		# Spawn hit effect for valid hits (semi or full impact)
		spawn_hit_effect()
	
	_collision.set_deferred("disabled", true)
	
	despawn(HIT)


# Turn the ball black/dark to indicate a weak hit that didn't score
func _set_ball_dark():
	# IMPORTANT:
	# Don't duplicate materials here. The beat effect (BeatResponder) animates shader
	# parameters on the shared note materials. Duplicating would "disconnect" this
	# ball from beat updates, causing the beat displacement to get stuck.
	#
	# Instead, override only the per-instance visual parameters.
	var mat = _mesh.material_override
	if mat is ShaderMaterial:
		_mesh.set_instance_shader_parameter("albedo_color", Color.BLACK)
		# Also dim emission if present
		if mat.get_shader_parameter("emission_color") != null:
			_mesh.set_instance_shader_parameter("emission_color", Color.BLACK)
	elif mat is StandardMaterial3D:
		# Fallback (StandardMaterial3D doesn't support instance shader params).
		# This may still create a per-ball material, but our note materials are ShaderMaterials.
		var dark_mat = mat.duplicate()
		dark_mat.albedo_color = Color.BLACK
		dark_mat.emission = Color.BLACK
		_mesh.material_override = dark_mat


# Turn the ball purple to indicate a PowerBall (requires 4x velocity to hit)
func _set_ball_purple():
	# IMPORTANT:
	# Use per-instance shader parameters instead of duplicating the material, so
	# the shared BeatResponder-driven shader params (like min_displace) continue
	# to animate and don't get "stuck" on PowerBalls.
	var mat = _mesh.material_override
	if mat is ShaderMaterial:
		_mesh.set_instance_shader_parameter("albedo_color", Color.PURPLE)
		# Set emission to purple glow if present
		if mat.get_shader_parameter("emission_color") != null:
			_mesh.set_instance_shader_parameter("emission_color", Color.PURPLE * 0.5)
	elif mat is StandardMaterial3D:
		# Fallback (StandardMaterial3D doesn't support instance shader params).
		var purple_mat = mat.duplicate()
		purple_mat.albedo_color = Color.PURPLE
		purple_mat.emission = Color.PURPLE * 0.5
		_mesh.material_override = purple_mat

func spawn_hit_effect():
	# Skip explosions if disabled for performance testing
	if not QualitySettings.note_explosions_enabled():
		return
	if hit_effect == null:
		push_warning("Note: hit_effect is not assigned")
		return
	var hit_effect_instance = hit_effect.instantiate()
	get_tree().current_scene.add_child(hit_effect_instance)

	var spawn_position = global_transform.origin
	hit_effect_instance.setup_effect(spawn_position, speed)

func spawn_feedback(offset, hit_level):
	if feedback_effect == null:
		push_warning("Note: feedback_effect is not assigned")
		return
	
	# Check if game is still valid (may be null during scene transitions like skip)
	var manager = Global.manager()
	if manager == null or manager._player == null or manager._player.game_node == null:
		return
	
	var feedback_instance = feedback_effect.instantiate()
	get_tree().current_scene.add_child(feedback_instance)
	
	var marker_position = manager._player.game_node._hit_marker.global_transform.origin.z
	var note_transform = global_transform.origin
	var spawn_position = Vector3(note_transform.x,note_transform.y,marker_position)
	#var spawn_position = global_transform.origin + Vector3(0,0,offset)
	feedback_instance.show_feedback(spawn_position, hit_level)

func despawn(type):
	if not alive:
		return
	
	alive = false
	
	_animation_player.play("despawn")
	
	_collision.set_deferred("disabled", true)
	
	if type==HIT:
		print ("hit")
		
	elif type==MISS and not been_hit and _type!=3:
		#print ("miss")
		spawn_feedback(-speed*0.25, HIT_LEVEL_TOOLOW) # TOOLOW = miss
		#bad reference, replace with signal
		var manager = Global.manager()
		if manager and manager._player:
			manager._player.combo = 0
			manager._player.energy -= 1
		
	await _animation_player.animation_finished
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
