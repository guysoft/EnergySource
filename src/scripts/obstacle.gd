extends Area3D

class_name Note

var speed = 2
@export var direction: Vector3 = Vector3(0,0,1)
@export var despawn_z: float = 12.0

@onready var _velocity = Vector3(0,0,0)
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
var size_x = 1.0
var size_y = 1.0
var size_z = 1.0

# Track extra collision shapes for compound walls
var _extra_collision_shapes: Array = []

#Refs
@onready var _audio_stream_player = $HitSound
@onready var _animation_player = $AnimationPlayer
@onready var _mesh = $MeshInstance3D as MeshInstance3D
@onready var _collision = $CollisionShape3D
@onready var _spawn_timer = $Timer

func _ready():
	deactivate(false)

func setup_obstacle(obstacle, obstacle_speed, bpm, distance):
	# Check for PBVR wall type first
	if obstacle.has("_pbvr_wall_type"):
		_setup_pbvr_wall(obstacle, obstacle_speed, bpm, distance)
		return
	
	# Fall through to Beat Saber style obstacle handling
	_setup_beatsaber_obstacle(obstacle, obstacle_speed, bpm, distance)


func _setup_pbvr_wall(obstacle: Dictionary, obstacle_speed: float, bpm: float, distance: float):
	"""Setup a PowerBeatsVR wall with correct mesh, position, and collision."""
	self.speed = obstacle_speed
	
	var wall_type = int(obstacle.get("_pbvr_wall_type", 0))
	var depth_beats = float(obstacle.get("duration", 1.0))
	var wall_name = obstacle.get("_pbvr_wall_name", "Unknown")
	
	# Get position from obstacle data
	var x = float(obstacle.get("x", 0.0))
	var y = float(obstacle.get("y", 0.0))
	
	# Apply fixed positioning rules from PowerBeatsVR
	match wall_type:
		WallMeshGenerator.WALL_ARCHWAY_CENTER:
			x = 0.0  # Always centered
		WallMeshGenerator.WALL_ARCHWAY_LEFT:
			x = -0.7  # Fixed left position
		WallMeshGenerator.WALL_ARCHWAY_RIGHT:
			x = 0.7  # Fixed right position
		WallMeshGenerator.WALL_OPENING_LEFT, WallMeshGenerator.WALL_OPENING_RIGHT:
			x = 0.0  # Always centered
	
	# PBVR walls sit on the floor (y=0 in mesh space)
	y = 0.0
	
	# Generate the mesh for this wall type
	var wall_mesh = WallMeshGenerator.generate_wall_mesh(wall_type)
	if wall_mesh == null:
		push_error("PBVR Wall: Failed to generate mesh for wall type %d" % wall_type)
		return
	_mesh.mesh = wall_mesh
	
	# Calculate Z depth: depth_beats * (distance / notes_delay_beats)
	# In PBVR: wall depth = depthInBeats * (APPEARANCE_POINT.z / ballFlightDurationInBeats)
	# Here: notes_delay determines how many beats ahead we spawn, similar to ballFlightDuration
	# The speed already encodes distance/time, so: z_depth = depth_beats * speed * seconds_per_beat
	# Simplified: z_depth = depth_beats * distance / notes_delay_beats
	# Since we don't have direct access to notes_delay, calculate from speed:
	# speed = (bpm/60) * distance / notes_delay => notes_delay = (bpm/60) * distance / speed
	var seconds_per_beat = 60.0 / bpm
	var z_depth = depth_beats * speed * seconds_per_beat
	
	# Ensure minimum depth for visibility
	if z_depth < 0.5:
		z_depth = 0.5
	
	# Scale only the Z axis - wall X/Y dimensions are baked into the mesh
	_mesh.scale = Vector3(1.0, 1.0, z_depth)
	
	# Generate collision shapes for this wall type
	_setup_collision_for_pbvr_wall(wall_type, z_depth)
	
	# Position the obstacle so front face is at Z=0 (spawn location)
	# Wall mesh goes from local Z=0 to Z=z_depth, so position at -z_depth puts front at 0
	transform.origin = Vector3(x, y, -z_depth)
	
	despawn_z = distance + z_depth
	
	print("PBVR Wall: type=%d (%s), depth_beats=%.2f, z_depth=%.2f, pos=(%.2f, %.2f, %.2f)" % [
		wall_type, wall_name, depth_beats, z_depth, x, y, -z_depth])
	
	# Handle spawn offset timer
	if obstacle.get("offset", 0.0) > 0.0:
		_spawn_timer.wait_time = obstacle["offset"] * 60.0 / bpm


func _setup_collision_for_pbvr_wall(wall_type: int, z_scale: float):
	"""Setup collision shapes for PBVR wall, supporting compound shapes."""
	# Clear any existing extra collision shapes
	for shape_node in _extra_collision_shapes:
		shape_node.queue_free()
	_extra_collision_shapes.clear()
	
	# Get collision shape data from WallMeshGenerator
	var collision_data = WallMeshGenerator.generate_collision_shapes(wall_type)
	
	if collision_data.size() == 0:
		return
	
	# First shape goes into the existing CollisionShape3D
	var first = collision_data[0]
	_collision.shape = first["shape"]
	var offset = first["offset"]
	_collision.position = Vector3(offset.x, offset.y, offset.z * z_scale)
	_collision.scale = Vector3(1.0, 1.0, z_scale)
	
	# Additional shapes get new CollisionShape3D nodes
	for i in range(1, collision_data.size()):
		var shape_data = collision_data[i]
		var collision_node = CollisionShape3D.new()
		collision_node.shape = shape_data["shape"]
		var col_offset = shape_data["offset"]
		collision_node.position = Vector3(col_offset.x, col_offset.y, col_offset.z * z_scale)
		collision_node.scale = Vector3(1.0, 1.0, z_scale)
		add_child(collision_node)
		_extra_collision_shapes.append(collision_node)


func _setup_beatsaber_obstacle(obstacle: Dictionary, _spd: float, bpm: float, distance: float):
	"""Setup a Beat Saber style obstacle (grid-based positioning)."""
	self.speed = speed
	if not obstacle:
		return
	
	var scale_x = 0
	var scale_y = 0
	var scale_z = 0
	var x = -90
	var y = -90
	
	if obstacle["type"] == "full_height":
		var index_to_position_x = {
			0: -Map.LEVEL_WIDTH, 
			1: -Map.LEVEL_WIDTH*0.5,
			2: Map.LEVEL_WIDTH*0.5,
			3: Map.LEVEL_WIDTH
		}
		
		#scale_x is double the width
		scale_x = 2*Map.LEVEL_WIDTH/4 * obstacle["width"]
		#scale_x = Map.LEVEL_WIDTH*0.25 * obstacle["width"]
		scale_y = Map.LEVEL_HIGH*2 - Map.LEVEL_LOW
		#x = index_to_position_x[int(obstacle["_lineIndex"])] + 0.5 * scale_x
		x = index_to_position_x[int(obstacle["_lineIndex"])]*obstacle["width"] + 0.5 * scale_x
		y = (Map.LEVEL_HIGH*2 + Map.LEVEL_LOW)/2
		
	elif obstacle["type"] == "crouch":
		var index_to_position_x = {
			0: -Map.LEVEL_WIDTH,
			1: -Map.LEVEL_WIDTH*0.5,
			2: Map.LEVEL_WIDTH*0.5,
			3: Map.LEVEL_WIDTH
		}
		scale_x = 2*Map.LEVEL_WIDTH/4 * obstacle["width"]
		scale_y = (Map.LEVEL_HIGH*2 - Map.LEVEL_LOW) / 2
		x = index_to_position_x[int(obstacle["_lineIndex"])] + 0.5 * scale_x
		#y = Map.LEVEL_LOW + (Map.LEVEL_HIGH - Map.LEVEL_LOW) * 0.75 + scale_y/2
		#y = Map.LEVEL_LOW + (Map.LEVEL_HIGH - Map.LEVEL_LOW)
		y = Map.LEVEL_HIGH*2
		
	print("got: " + obstacle["type"])
	print("width: " + str(obstacle["width"]))
	print("index: " + str(obstacle["_lineIndex"]))
		
	var z = obstacle["duration"] * bpm / 60 * (1/size_z) / 2
	#self.scale_object_local(Vector3(scale_x, scale_y, z))
	$MeshInstance3D.scale = (Vector3(scale_x, scale_y, z))
	$CollisionShape3D.scale = (Vector3(scale_x, scale_y, z))
	transform.origin = Vector3(x, y, -z)
	
	despawn_z = distance+z
	
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
		mat.albedo_color = Color.RED
		mat.emission = Color.RED
	elif note["_type"] == 1:
		mat.albedo_color = Color.BLUE
		mat.emission = Color.BLUE
	elif note["_type"] == 3:
		mat.albedo_color = Color.WHITE
		mat.emission = Color.WHITE
	"""

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

#TODO: Take into account the controller position of the hit?
func on_hit():
	_audio_stream_player.play()
	
func despawn():
	if not alive:
		return
	
	alive = false
	
	_animation_player.play("despawn")
	await _animation_player.animation_finished
	deactivate()

func _physics_process(delta):
	_velocity = direction * speed * delta
	global_translate(_velocity)
	
	if self.transform.origin.z > despawn_z+(speed*0.25):
		self.despawn()
