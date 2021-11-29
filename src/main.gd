extends Spatial

onready var path:String = "res://Levels/test"
onready var difficulty = "ExpertPlusStandard"

onready var travel_distance = $Player/ARVROrigin.global_transform.origin.distance_to($SpawnLocation.global_transform.origin)

export (NodePath) var viewport = null
var interface : ARVRInterface
# References
onready var _player = $Player
onready var _left_hand = $Player/ARVROrigin/LeftHand
onready var _right_hand = $Player/ARVROrigin/RightHand
onready var _spawn_location = $SpawnLocation

var song_speed = 1
var toggle_speed_lock = false

var speed_decay = 0.1

var _bounce_time = 0
var _bounce_freq = 0
var _bounce_amp = 0.025

#FYI if the script has a classname, you don't need to preload it in
#const Map = preload("scripts/MapLoader.gd")
onready var map = null

# how many beats does it take the spawned notes to travel to arvr origin
onready var notes_delay = 8

#Does this need be unique? Consider moving to a utility singleton
onready var _rand = RandomNumberGenerator.new()

var notescene = load("res://scenes/Note.tscn")
var obstaclescene = load("res://scenes/Obstacle.tscn")

var time_begin = null
var time_delay

func _ready():
	if GameVariables.ENABLE_VR:
		if not initialise_VR():
			print ("failed to init VR")
	else:
		print("No VR")
		_left_hand.queue_free()
		_right_hand.queue_free()


	setup_map(path)
	var song_offset = map.get_offset()
	$BeatPlayer.connect("beat", self, "_on_beat_detected")
	$BeatPlayer.bpm = map.get_bpm()
	
	time_begin = OS.get_ticks_usec()
	time_delay = AudioServer.get_time_to_next_mix() + AudioServer.get_output_latency()
	print ("time delay:", time_delay)
	$BeatPlayer.offset = song_offset - float(time_delay)
	
	Engine.time_scale = song_speed
	$BeatPlayer.pitch_scale = song_speed

	$Ground.setup_ground(map.get_bpm(), notes_delay)
	$EnvironmentParticles.setup_particles(map.get_bpm(), notes_delay)
	
	$BeatPlayer.play()
	
	_bounce_time-=song_offset - float(time_delay)
	_bounce_freq =  60/map.get_bpm() * calc_object_speed()

# Perhaps we will need this to handle delay
#func _process(delta):
#	# Obtain from ticks.
#	var time = (OS.get_ticks_usec() - time_begin) / 1000000.0
#	# Compensate for latency.
#	time -= time_delay
#	# May be below 0 (did not begin yet).
#	time = max(0, time)
#	print("Time is: ", time)

# export(PackedScene) var note_object
# export(NodePath) onready var beat_player = get_node(beat_player) as BeatPlayer


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
	# song_speed = 0.4
	#$BeatPlayer.pitch_scale = song_speed
	
	var tmp = map._on_beat_detected(difficulty, beat + notes_delay)
	var notes = tmp[0]
	var obstacles = tmp[1]
	var events = tmp[2]
	
	for note in notes:
		
		# Spawn note
		var note_instance = notescene.instance()
		# note_instance.get_child(0).visible()
		
		_spawn_location.add_child(note_instance)
		
		var note_speed = map.get_bpm() / 60 * travel_distance / notes_delay
		#print(note_speed)
		note_instance.setup_note(note, note_speed, map.get_bpm(), travel_distance)
		# note_instance.transform.origin = Vector3(-1,-1,-1)
	#	_rand.randomize()
	#
	#	var wall_size = 1
	#	note_instance.transform.origin = Vector3(
	#	_rand.randf_range(-wall_size, wall_size),
	#	_rand.randf_range(0.5, 2),
	#	- 2
	#)

		
		# add_child(note_instance)
		# note_instance.setup_note(note)
		
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

	
#func rangef(start: float, end: float, step: float):
#	var res = Array()
#	var i = start
#	if step < 0:
#		while i > end:
#			res.push_back(i)
#			i += step
#	elif step > 0:
#		while i < end:
#			res.push_back(i)
#			i += step
#	return res
#
#
#func change_song_speed(speed):
#	self.song_speed = speed
#	$BeatPlayer.pitch_scale = speed
#
#	var notes = _spawn_location.get_children()
#	for note in notes:
#		note.speed =  map.get_bpm() / 60 * travel_distance / (notes_delay) * speed_multiplier * self.song_speed
#	return
#
#func warp_song(target_speed, step, duration_stay, step_delay):
#	var initial_speed = self.song_speed
#
#	# this is a lock so we dont do this twice
#	if not toggle_speed_lock:
#		toggle_speed_lock = true
#
#		# Slow down
#		print("do the time warp")
#		for i in rangef(self.song_speed, target_speed, -step):
#			change_song_speed(i)
#			yield(get_tree().create_timer(step_delay), "timeout")
#
#		# Speed up
#		yield(get_tree().create_timer(duration_stay), "timeout")
#
#		for i in rangef(target_speed, initial_speed, step):
#			change_song_speed(i)
#			yield(get_tree().create_timer(step_delay), "timeout")
#			change_song_speed(initial_speed)
#		toggle_speed_lock = false
#
#	return
	

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
		$BeatPlayer.pitch_scale = Engine.time_scale
		yield(get_tree().create_timer(step_delay),"timeout")
	
	print ("starting stay time")
	yield(get_tree().create_timer(duration_stay),"timeout")
	
	while (not is_equal_approx(Engine.time_scale, song_speed)):
		Engine.time_scale = lerp(Engine.time_scale, song_speed, step)
		$BeatPlayer.pitch_scale = Engine.time_scale
		yield(get_tree().create_timer(step_delay),"timeout")
	
	#ensure these values are reset to base
	Engine.time_scale = song_speed
	$BeatPlayer.pitch_scale = song_speed
	
	toggle_speed_lock = false
	
	#warp_song(target_speed, step, duration_stay, step_delay)


#func _init_vr() -> ARVRInterface:
#	print("Starting vr")
#	# pass
#	var arvr_interface = ARVRServer.find_interface("OpenXR")
#	if arvr_interface and arvr_interface.initialize():
#		print("Yes VR")
#		get_viewport().arvr = true
#		get_viewport().hdr = false
#		get_viewport().keep_3d_linear = true
#		GameVariables.vr_enabled = true
#	else:
#		print("Failed to start VR")
#	return arvr_interface

func initialise_VR() -> bool:
	var interface = ARVRServer.find_interface("OpenXR")
	print (interface)
	if interface and interface.initialize():
		print("OpenXR Interface initialized")

		# Connect to our plugin signals
		_connect_plugin_signals()

		var vp : Viewport = null
		if viewport:
			vp = get_node(viewport)
		else:
			vp = get_viewport()
		
		# Change our viewport so it is tied to our ARVR interface and renders to our HMD
		vp.arvr = true

		# Our interface will tell us whether we should keep our render buffer in linear color space
		# If true our preview will be darker.
		vp.keep_3d_linear = $Configuration.keep_3d_linear()

		# increase our physics engine update speed
		var refresh_rate = $Configuration.get_refresh_rate()
		if refresh_rate == 0:
			# Only Facebook Reality Labs supports this at this time
			print("No refresh rate given by XR runtime")

			# Use something sufficiently high
			Engine.iterations_per_second = 144
		else:
			print("HMD refresh rate is set to " + str(refresh_rate))

			# Match our physics to our HMD
			Engine.iterations_per_second = refresh_rate

		return true
	else:
		return false

func _connect_plugin_signals():
	ARVRServer.connect("openxr_session_begun", self, "_on_openxr_session_begun")
	ARVRServer.connect("openxr_session_ending", self, "_on_openxr_session_ending")
	ARVRServer.connect("openxr_focused_state", self, "_on_openxr_focused_state")
	ARVRServer.connect("openxr_visible_state", self, "_on_openxr_visible_state")
	ARVRServer.connect("openxr_pose_recentered", self, "_on_openxr_pose_recentered")

func _on_openxr_session_begun():
	print("OpenXR session begun")

func _on_openxr_session_ending():
	print("OpenXR session ending")

func _on_openxr_focused_state():
	print("OpenXR focused state")

func _on_openxr_visible_state():
	print("OpenXR visible state")

func _on_openxr_pose_recentered():
	print("OpenXR pose recentered")
	
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


#func change_song_speed(speed):
#	self.song_speed = speed
#	$BeatPlayer.pitch_scale = speed
#
#	var notes = _spawn_location.get_children()
#	for note in notes:
#		note.speed =  map.get_bpm() / 60 * travel_distance / (notes_delay) * speed_multiplier * self.song_speed
#	return

#func warp_song(target_speed, step, duration_stay, step_delay):
#	var initial_speed = self.song_speed
#
#	# this is a lock so we dont do this twice
#	if not toggle_speed_lock:
#		toggle_speed_lock = true
#
#		# Slow down
#		print("do the time warp")
#		for i in rangef(self.song_speed, target_speed, -step):
#			change_song_speed(i)
#			yield(get_tree().create_timer(step_delay), "timeout")
#
#		# Speed up
#		yield(get_tree().create_timer(duration_stay), "timeout")
#
#		for i in rangef(target_speed, initial_speed, step):
#			change_song_speed(i)
#			yield(get_tree().create_timer(step_delay), "timeout")
#			change_song_speed(initial_speed)
#		toggle_speed_lock = false
#
#	return

