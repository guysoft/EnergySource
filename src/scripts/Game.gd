extends Spatial

export(Environment) var environment:Environment
export (NodePath) var viewport = null #Unused, here for compatability

onready var path:String = "res://Levels/test"
onready var difficulty = "Expert"

var notescene = preload("res://scenes/Note.tscn")
var obstaclescene = preload("res://scenes/Obstacle.tscn")

# References
onready var _player = Global.manager()._player
onready var _beat_player = Global.manager()._beatplayer
onready var _environment_manager = Global.manager()._environment_manager
onready var _spawn_location = $SpawnLocation
onready var travel_distance = $HitMarker.global_transform.origin.distance_to($SpawnLocation.global_transform.origin)

# WebXR variables
var webxr_interface
var vr_web_supported = false

#OpenXR
var interface : ARVRInterface

# how many beats does it take the spawned notes to travel to arvr origin
onready var notes_delay = 4

var song_speed = 1
var toggle_speed_lock = false

var speed_decay = 0.1 #unused?

var _bounce_time = 0
var _bounce_freq = 0
var _bounce_amp = 0.025

onready var map = null

#Does this need be unique? Consider moving to a utility singleton
onready var _rand = RandomNumberGenerator.new()

var time_begin = null
var time_delay

func _ready():
	
	_player.reset_player()
	_player.in_game = true
	_player.game_node = self
	
	_environment_manager.change_environment(environment)
	
	setup_map(path)
	var song_offset = map.get_offset()
	_beat_player.stop()
	_beat_player.connect("beat", self, "_on_beat_detected")
	_beat_player.stream = load(path + "/song.ogg")
	_beat_player.bpm = map.get_bpm()
	
	time_begin = OS.get_ticks_usec()
	time_delay = AudioServer.get_time_to_next_mix() + AudioServer.get_output_latency()
	print ("time delay:", time_delay)
	_beat_player.offset = song_offset + float(time_delay)
	
	Engine.time_scale = song_speed
	_beat_player.pitch_scale = song_speed
	
	$Ground.setup_ground(map.get_bpm(), notes_delay, Color.chocolate)
	$EnvironmentParticles.setup_particles(map.get_bpm(), notes_delay)
	
	_beat_player.connect("finished", self, "_on_music_finished")
	$StartTimer.start()
	
	_bounce_time-=song_offset - float(time_delay)
	_bounce_freq =  60/map.get_bpm() * calc_object_speed()


func _process(delta: float) -> void:
	
	
	if GameVariables.ENABLE_VR:
		# Web XR processs
		var left_controller_id = 100
		var thumbstick_x_axis_id = 2
		var thumbstick_y_axis_id = 3
	 
		var thumbstick_vector := Vector2(
			Input.get_joy_axis(left_controller_id, thumbstick_x_axis_id),
			Input.get_joy_axis(left_controller_id, thumbstick_y_axis_id))
	 
		if thumbstick_vector != Vector2.ZERO:
			print ("Left thumbstick position: " + str(thumbstick_vector))


func calc_object_speed():
	return map.get_bpm() / 60 * travel_distance / notes_delay


func bounce_notes(delta):
	var bounce = cos(_bounce_time*_bounce_freq)*0.15
	_bounce_time+=delta
	for child in $SpawnLocation.get_children():
		if child.is_in_group("note"):
			child.transform.origin.y = child._y_offset + bounce

#func _physics_process(delta):
	#bounce_notes(delta)

func _on_beat_detected(beat):

	var tmp = map._on_beat_detected(difficulty, beat + notes_delay)
	var notes = tmp[0]
	var obstacles = tmp[1]
	var events = tmp[2]
	
	for note in notes:
		# Spawn note
		var note_instance = notescene.instance()
		_spawn_location.add_child(note_instance)
		
		var note_speed = calc_object_speed()
		#print(note_speed)
		note_instance.setup_note(note, note_speed, map.get_bpm(), travel_distance)
	
		note_instance.activate()
		
	for obstacle in obstacles:
		# Spawn obstacle
		var obstacle_instance = obstaclescene.instance()
		_spawn_location.add_child(obstacle_instance)
		
		var obstacle_speed = calc_object_speed()
		#print(note_speed)
		obstacle_instance.setup_obstacle(obstacle, obstacle_speed, map.get_bpm(), travel_distance)
		
		obstacle_instance.activate()
	
	for event in events:
		#back laser
		var type = event["_type"]
		var lights = [$Lasers/BackLaser,$Lasers/RingLights,$Lasers/LeftLasers,$Lasers/RightLasers,$Lasers/CenterLights]
		var brightness = 1.5
		#if event type is a light event
		if type <=4:
			var light = type
			var material = lights[light].get_child(0).get_surface_material(0) as SpatialMaterial
			#turn off
			if event["_value"] == 0:
				lights[light].visible = false
			#turn on blue
			if event["_value"] == 1:
				#material change to blue
				lights[light].visible = true
				material.albedo_color = Color.aqua * brightness 
			#flash brightly blue, return to previous state
			if event["_value"] == 2:
				lights[light].visible = true
				material.albedo_color = Color.aqua* brightness 
			#flash brightly blue, fade to black
			if event["_value"] == 3:
				lights[light].visible = true
				material.albedo_color = Color.aqua * brightness 
			#Unused
			#if event["_value"] == 4:
			#turn on red
			if event["_value"] == 5:
				lights[light].visible = true
				material.albedo_color = Color.greenyellow * brightness 
			#flash bright red, return to previous
			if event["_value"] == 6:
				lights[light].visible = true
				material.albedo_color = Color.greenyellow * brightness 
			#flash bright red, fade to black
			if event["_value"] == 7:
				lights[light].visible = true
				material.albedo_color = Color.greenyellow * brightness 
		#ring spin, remapped to ground displacement
		elif type == 8:
			$GroundBeatResponse.disabled=false

func setup_map(path:String):
	map = Map.new(path)
	map.get_level(difficulty)


func set_song_speed(newval, do_lerp = false, lerp_step = 0.05, lerp_delay= 0.05):
	song_speed = newval
	if song_speed <= 0.5: 
		song_speed = 0.5
	if song_speed >= 1.5:
		song_speed = 1.5
	
	print ("adjusting song_speed: ", song_speed)
	
	if do_lerp:
		if is_equal_approx(Engine.time_scale,song_speed):
			return
		else:
			_beat_player.pitch_scale = lerp(_beat_player.pitch_scale, song_speed, lerp_step)
			Engine.time_scale = lerp(Engine.time_scale, song_speed, lerp_step)
			yield (get_tree().create_timer(lerp_delay),"timeout")
	
	_beat_player.pitch_scale = song_speed
	Engine.time_scale = song_speed


func toggle_speed(target_speed, step, duration_stay, step_delay):
#	var target_speed = 0.1
#	var step = 0.1
	if toggle_speed_lock:
		return
	
	toggle_speed_lock=true
	
	#multiply the stay duration by the target_speed
	var calc_speed = target_speed * song_speed
	duration_stay *= calc_speed
	
	while (not is_equal_approx(Engine.time_scale, calc_speed)):
		print (Engine.time_scale)
		if abs(calc_speed-Engine.time_scale)>=0.01:
			Engine.time_scale = lerp(Engine.time_scale, calc_speed, step)
		else:
			Engine.time_scale = calc_speed
		_beat_player.pitch_scale = Engine.time_scale
		yield(get_tree().create_timer(step_delay),"timeout")
	
	print ("starting stay time")
	yield(get_tree().create_timer(duration_stay),"timeout")
	
	while (not is_equal_approx(Engine.time_scale, song_speed)):
		Engine.time_scale = lerp(Engine.time_scale, song_speed, step)
		_beat_player.pitch_scale = Engine.time_scale
		yield(get_tree().create_timer(step_delay),"timeout")
	
	#ensure these values are reset to base
	Engine.time_scale = song_speed
	_beat_player.pitch_scale = song_speed
	
	toggle_speed_lock = false
	
	#warp_song(target_speed, step, duration_stay, step_delay)
 
func _on_LeftController_button_pressed(button: int) -> void:
	if GameVariables.ENABLE_VR:
		print ("Button pressed: " + str(button))
 
func _on_LeftController_button_release(button: int) -> void:
	if GameVariables.ENABLE_VR:
		print ("Button release: " + str(button))

func rangef(start: float, end: float, step: float):
	var res = Array()
	var i = start
	if step < 0:
		while i > end:
			res.push_back(i)
			i += step
	elif step > 0:
		while i < end:
			res.push_back(i)
			i += step
	return res


func _on_music_finished():
	$EndTimer.start()

func _on_StartTimer_timeout():
	_beat_player.play()


func _on_EndTimer_timeout():
	#show scorecard with options to restart or return to menu
	pass
