extends Spatial

export(Environment) var environment:Environment
export (NodePath) var viewport = null #Unused, here for compatability
export var start_time_offset = 0

var notescene = preload("res://scenes/Note.tscn")
var obstaclescene = preload("res://scenes/Obstacle.tscn")

# References
onready var _player = Global.manager()._player
onready var _beat_player = Global.manager()._beatplayer
onready var _environment_manager = Global.manager()._environment_manager
onready var _spawn_location = $SpawnLocation
onready var _hit_marker = $HitMarker
onready var travel_distance = $HitMarker.global_transform.origin.distance_to($SpawnLocation.global_transform.origin)

# how many beats does it take the spawned notes to travel to arvr origin
onready var notes_delay = 4

const MIN_SONG_SPEED = 0.5
const MAX_SONG_SPEED = 1.5
var _song_length
var song_speed = 1
var _song_offset
var toggle_speed_lock = false

var _bounce_time = 0
var _bounce_freq = 0
var _bounce_amp = 0.025

onready var _map = null

#Does this need be unique? Consider moving to a utility singleton
onready var _rand = RandomNumberGenerator.new()

var _time_begin = null
var _time_delay

func _ready():
	
	_player.reset_player()
	_player.in_game = true
	_player.game_node = self
	
	var difficulty = GameVariables.difficulty
	var path = GameVariables.path
	
	_map = setup_map(path, difficulty)
	setup_song(_map)
	setup_environment(_map)

	#begin timer to offset start of song
	$StartTimer.start()
	

func setup_song(map:Map):
	if not map:
		return
	_beat_player.stop()

	_beat_player.connect("beat", self, "_on_beat_detected")
	
	if OS.get_name() == "HTML5":
		_beat_player.stream = load(map.path + "/song.ogg")
	else:
		var audio_loader = AudioLoader.new()
		_beat_player.stream = audio_loader.loadfile(map.get_song(), false, audio_loader.AUDIO_EXT.OGG)
	
	_song_length = _beat_player.stream.get_length()
	_beat_player.bpm = map.get_bpm()
	
	_time_begin = OS.get_ticks_usec() #currently unused
	_time_delay = AudioServer.get_time_to_next_mix() + AudioServer.get_output_latency()
	#print ("time delay:", time_delay)
	_song_offset = map.get_offset()
	_beat_player.offset = _song_offset + float(_time_delay)
	
	set_song_speed(song_speed)

#setup the visual elements
func setup_environment(map:Map):
	_environment_manager.change_environment(environment)
	
	#enable the saturation adjustment
	_environment_manager.environment.adjustment_enabled=true
	
	#set color and speed which to move ground and particles
	$Ground.setup_ground(map.get_bpm(), notes_delay, Color.chocolate)
	$EnvironmentParticles.setup_particles(map.get_bpm(), notes_delay)
	
	#position center lights
	$Lasers/CenterLights.transform.origin.y = Map.LEVEL_LOW
	$Lasers/CenterLights/LeftLight.transform.origin.x = -Map.LEVEL_WIDTH-1
	$Lasers/CenterLights/RightLight.transform.origin.x = Map.LEVEL_WIDTH+1
	
	#Bounce calculation, currently unused
	_bounce_time-=_song_offset - float(_time_delay)
	_bounce_freq =  60/map.get_bpm() * calc_object_speed()
	
#disabled as this is unused
#func _process(delta: float) -> void:
#	#take_screenshot()
#	if GameVariables.ENABLE_VR:
#		# Web XR processs
#		var left_controller_id = 100
#		var thumbstick_x_axis_id = 2
#		var thumbstick_y_axis_id = 3
#
#		var thumbstick_vector := Vector2(
#			Input.get_joy_axis(left_controller_id, thumbstick_x_axis_id),
#			Input.get_joy_axis(left_controller_id, thumbstick_y_axis_id))
#
#		if thumbstick_vector != Vector2.ZERO:
#			print ("Left thumbstick position: " + str(thumbstick_vector))


#calculate the speed at which the notes/obstacles should travel
func calc_object_speed():
	return _map.get_bpm() / 60 * travel_distance / notes_delay

#works but notes are not timed to the beat
#would be faster as a shader, but wouldn't include collision
func bounce_notes(delta):
	var bounce = cos(_bounce_time*_bounce_freq)*0.15
	_bounce_time+=delta
	for child in $SpawnLocation.get_children():
		if child.is_in_group("note"):
			child.transform.origin.y = child._y_offset + bounce

#disabled because note bounce broken
#could possibly add to a vertex shader
#func _physics_process(delta):
	#bounce_notes(delta)

#Functionality to play the song.
#reads from the map in beat chunks and spawns notes,obstacles and events.
#All spawn simulatenously but each can have offsets which are used to time when they actually appear.
func _on_beat_detected(beat):

	var tmp = _map._on_beat_detected(_map.get_difficulty(), beat + notes_delay)
	var notes = tmp[0]
	var obstacles = tmp[1]
	var events = tmp[2]
	
	for note in notes:
		# Spawn note
		var note_instance = notescene.instance()
		_spawn_location.add_child(note_instance)
		
		var note_speed = calc_object_speed()
		#print(note_speed)
		note_instance.setup_note(note, note_speed, _map.get_bpm(), travel_distance)
	
		note_instance.activate()
		
	for obstacle in obstacles:
		# Spawn obstacle
		var obstacle_instance = obstaclescene.instance()
		_spawn_location.add_child(obstacle_instance)
		
		var obstacle_speed = calc_object_speed()
		#print(note_speed)
		obstacle_instance.setup_obstacle(obstacle, obstacle_speed, _map.get_bpm(), travel_distance)
		
		obstacle_instance.activate()
	
	#Move this to an event manager
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

#simple helper to setup the map
func setup_map(path:String, difficulty:String)->Map:
	var map = Map.new(path)
	map.get_level(difficulty)
	return map


#function for changing the song speed and adjusting the
#beatplayer pitch, engine speed and environment satuation control
#simultaneously
func set_song_speed(newval, do_lerp = false, lerp_step = 0.05, lerp_delay= 0.05):
	song_speed = newval
	if song_speed <= MIN_SONG_SPEED: 
		song_speed = MIN_SONG_SPEED
	if song_speed >= MAX_SONG_SPEED:
		song_speed = MAX_SONG_SPEED
	
	#print ("adjusting song_speed: ", song_speed)
	
	if do_lerp:
		if is_equal_approx(Engine.time_scale,song_speed):
			return
		else:
			while (not is_equal_approx(Engine.time_scale, song_speed)):
				_beat_player.pitch_scale = lerp(_beat_player.pitch_scale, song_speed, lerp_step)
				_environment_manager.environment.adjustment_saturation = Utility.remap_value(song_speed,Vector2(0.5,1.5),Vector2(0.0,2.0))
				Engine.time_scale = lerp(Engine.time_scale, song_speed, lerp_step)
				yield (get_tree().create_timer(lerp_delay),"timeout")
	
	_environment_manager.environment.adjustment_saturation = Utility.remap_value(song_speed,Vector2(0.5,1.5),Vector2(0.0,2.0))
	_beat_player.pitch_scale = song_speed
	Engine.time_scale = song_speed

#Smoothly interpolate speed to target speed for x amount of time and
#then interpolate back
func toggle_speed(target_speed, step, duration_stay, step_delay):
	if toggle_speed_lock:
		return
	toggle_speed_lock = true

	set_song_speed(target_speed,true,step,step_delay)

	yield(get_tree().create_timer(duration_stay),"timeout")

	set_song_speed(1.0,true,step,step_delay)
	
	toggle_speed_lock = false

#signal callback for beatplayer when music ends
#propogates a global event song_end to the event bus
func _on_music_finished():
	Events.emit_signal("song_end")
	$ScoreCanvas.visible = false
	$EndTimer.start()

#start delay callback as there seems to be some issue with the beatplayer
#triggering a song end callback from the menu music, showing the end of level
#score card early. Should probably add a secondary audiostream for menu music
func _on_StartTimer_timeout():
	var time_left = $ScoreCanvas/Viewport/ReferenceRect/CenterContainer/VBoxContainer/UITimeLeft
	time_left.time = (_song_length*start_time_offset)+_beat_player.offset
	_beat_player.play(_song_length*start_time_offset)
	_beat_player.connect("finished", self, "_on_music_finished")
	Events.emit_signal("song_begin")


func _on_EndTimer_timeout():
	$BigScore/SongFinished.play()
	$BigScore.visible = true
	
	var clear_time = $ScoreCanvas/Viewport/ReferenceRect/CenterContainer/VBoxContainer/UITimeLeft.time
	var time_multiplier = (_song_length/clear_time)
	$BigScore/Viewport/ReferenceRect/VBoxContainer/TimeBonus.text = String(stepify(time_multiplier*100, 0.01)) + "%"
	
	var multiplier_color = Color.white
	if time_multiplier<0.95:
		multiplier_color = Color.yellow
	if time_multiplier<-1.25:
		multiplier_color = Color.red
	if time_multiplier>1.05:
		multiplier_color = Color.aqua
	if time_multiplier>1.25:
		multiplier_color = Color.green
	$BigScore/Viewport/ReferenceRect/VBoxContainer/TimeBonus.add_color_override("font_color", multiplier_color)
	
	#unimplemented
	#begin calculation of whether player got a good score
	#count total misses, perfects, early, lates
	#provide rank and suggestion based on performance
	var total_notes = _map.get_note_count(_map.get_difficulty())
	
	$BigScore/Viewport/ReferenceRect/VBoxContainer/Finished.visible=true
	yield(get_tree().create_timer(0.5),"timeout")
	$BigScore/Viewport/ReferenceRect/VBoxContainer/HSeparator2.visible=true
	$BigScore/Viewport/ReferenceRect/VBoxContainer/TimeBonusLabel.visible=true
	yield(get_tree().create_timer(0.5),"timeout")
	$BigScore/Viewport/ReferenceRect/VBoxContainer/TimeBonus.visible=true
	yield(get_tree().create_timer(0.5),"timeout")
	$BigScore/Viewport/ReferenceRect/VBoxContainer/ScoreCardLabel.visible=true
	yield(get_tree().create_timer(0.5),"timeout")
	$BigScore/Viewport/ReferenceRect/VBoxContainer/UIScore.visible=true
	_player.score *= time_multiplier

	yield(get_tree().create_timer(1),"timeout")
	$BigScore/Viewport/ReferenceRect/VBoxContainer/HSeparator.visible=true
	$BigScore/Viewport/ReferenceRect/VBoxContainer/HBoxContainer.visible=true
	$BigScore/Viewport/ReferenceRect/VBoxContainer/HBoxContainer/MenuButton.disabled=false
	$BigScore/Viewport/ReferenceRect/VBoxContainer/HBoxContainer/RestartButton.disabled=false
	
	#log_score("gravebud", _player.score)
	#$Leaderboard.visible = true

func _on_MenuButton_pressed():
	$BigScore/AcceptSound.play()
	_player.in_game = false
	_player.game_node = null
	Global.manager().load_scene(Global.manager().menu_path,"menu")


func _on_RestartButton_pressed():
	$BigScore/AcceptSound.play()
	_player.in_game = false
	_player.game_node = null
	Global.manager().load_scene(Global.manager().game_path,"game")

var screenshot_number=1
func take_screenshot():
	viewport = get_viewport()
	viewport.arvr = true
	var image = viewport.get_texture().get_data()
	image.flip_y()
	image.save_png("res://screenshots/screenshot_" + String(screenshot_number) + ".png")
	screenshot_number+=1


