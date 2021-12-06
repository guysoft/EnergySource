extends KinematicBody

# velocity mechanics settnings
const HIT_VELOCITY = 0.2
const BOMB_SCORE_VALUE = 100 
const BOMB_ENERGY_VALUE = 25
const MAX_COMBO = 8

# Payer movement in non-vr mode settings
export var Sensitivity_X = 0.01
export var Sensitivity_Y = 0.01
export var Invert_Y_Axis = true
export var Exit_On_Escape = true
export var Maximum_Y_Look = 45
export var Accelaration = 5
export var Maximum_Walk_Speed = 10
export var Jump_Speed = 2

var in_game = false
var game_node #reference to game node

var _beat_player

const GRAVITY = 0 #0.098
var velocity = Vector3(0,0,0)
var forward_velocity = 0
var Walk_Speed = 0.1

enum {FASTER, NEUTRAL, SLOWER}
const MAX_ACCELERATION = 1
const MIN_ACCELERATION = 0
var time_direction = NEUTRAL
var song_acceleration = 0.00 setget set_song_acceleration
var song_deceleration = 1.0 #rate at which we return to zero
var acceleration_rate = 0.25

var hit_range = Vector2(-0.25, 0.25)
var accuracy_range = Vector2(0.0, 3.0)

var score = 0 setget set_score
var energy = 0 setget set_energy
var combo = 0 setget set_combo

var can_use_energy = true

var energy_decay_rate = 7

func reset_player():
	self.score = 0
	self.energy = 0
	self.combo = 0
	self.can_use_energy=true
	self.song_acceleration = 0.0
	self.time_direction = NEUTRAL
	
	if not _beat_player:
		_beat_player = Global.manager()._beatplayer

func set_song_acceleration(newval):
	song_acceleration = newval
	if song_acceleration>MAX_ACCELERATION:
		song_acceleration = MAX_ACCELERATION
	if song_acceleration<=MIN_ACCELERATION:
		song_acceleration = MIN_ACCELERATION

func set_combo(new_val):
	combo = new_val
	if combo>=MAX_COMBO:
		combo = MAX_COMBO
	Events.emit_signal("current_combo_updated", combo)
	
func set_score(new_val):
	score = new_val
	if score<0:
		score=0
	Events.emit_signal("current_score_updated", score)

func set_energy(new_val):
	energy = new_val
	if energy>100: energy = 100
	if energy<0: energy = 0
	if energy==0: disable_energy_use(1.0)
	Events.emit_signal("current_energy_updated", energy)

func _ready():
	# TODO Change this not to the global variable
	# but after checking if vr worked
	
	_beat_player = Global.manager()._beatplayer
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if not GameVariables.ENABLE_VR:
		
		forward_velocity = Walk_Speed
		set_process(true)
	

func _process(delta):
	
	if in_game and game_node:
		#increase energy passively
		self.energy += (1.5*delta*Engine.time_scale)
	
		process_controller_input("left", delta)
		process_controller_input("right", delta)
	
		if can_use_energy:
			if time_direction == FASTER:
				#print ("Faster:", get_parent().song_speed)
				game_node.set_song_speed(game_node.song_speed + song_acceleration*delta)
			elif time_direction == SLOWER:
				#print ("Slower:", get_parent().song_speed)
				game_node.set_song_speed(game_node.song_speed - song_acceleration*delta)
			elif time_direction == NEUTRAL:
				#print ("Neutral:", get_parent().song_speed)
				if not is_equal_approx(game_node.song_speed,1.0):
					if game_node.song_speed > 1.0:
						game_node.set_song_speed(game_node.song_speed-song_deceleration * delta)
					elif game_node.song_speed <1.0:
						game_node.set_song_speed(game_node.song_speed+song_deceleration * delta)
				else:
					game_node.song_speed = 1.0
	
	
func _physics_process(delta):
	
	if not GameVariables.ENABLE_VR and in_game and not get_tree().paused:
		velocity.y -= GRAVITY
		
#		if game_node:
#			if Input.is_key_pressed(KEY_P):
#				game_node.toggle_speed(0.5, 0.1, 5.0, 0.01)
		
		if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
				Walk_Speed += Accelaration
				if Walk_Speed > Maximum_Walk_Speed:
						Walk_Speed = Maximum_Walk_Speed
				velocity.x = -global_transform.basis.z.x * Walk_Speed
				velocity.z = -global_transform.basis.z.z * Walk_Speed
		if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
				Walk_Speed += Accelaration
				if Walk_Speed > Maximum_Walk_Speed:
						Walk_Speed = Maximum_Walk_Speed
				velocity.x = global_transform.basis.z.x * Walk_Speed
				velocity.z = global_transform.basis.z.z * Walk_Speed
		if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
				Walk_Speed += Accelaration
				if Walk_Speed > Maximum_Walk_Speed:
						Walk_Speed = Maximum_Walk_Speed
				velocity.x = -global_transform.basis.x.x * Walk_Speed
				velocity.z = -global_transform.basis.x.z * Walk_Speed
				
		if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
				Walk_Speed += Accelaration
				if Walk_Speed > Maximum_Walk_Speed:
						Walk_Speed = Maximum_Walk_Speed
				velocity.x = global_transform.basis.x.x * Walk_Speed
				velocity.z = global_transform.basis.x.z * Walk_Speed
				
		if not(Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_RIGHT)):
				velocity.x = 0
				velocity.z = 0
				
		if is_on_floor():
				if Input.is_action_just_pressed("ui_accept"):
						velocity.y = Jump_Speed
		velocity = move_and_slide(velocity, Vector3(0,1,0))

func _input(event):
	if not GameVariables.ENABLE_VR and in_game:
		if Input.is_key_pressed(KEY_ESCAPE):
				pause_game()
		
		if event is InputEventMouseMotion and not get_tree().paused:
			rotate_y(-Sensitivity_X * event.relative.x)
			# rotate_x(-Sensitivity_Y * event.relative.y)


func handle_hit(body, hand):
	var controller = null
	if hand == "left":
		controller = Global.manager()._left_hand
	else:
		controller = Global.manager()._right_hand
	#print("hit " + hand + " "  + body.name)
	
#	if body.is_in_group("obstacle"):
#		$BombSound.play()
#		game_node.toggle_speed(0.5, 0.1, 1.0, 0.01)
#		self.combo = 0
#		self.score -= 100
	
	if body.is_in_group("note"):
		
		#if it's a bomb
		if body._type == 3:
			$BombSound.play()
			self.score -= BOMB_SCORE_VALUE
			self.energy -= BOMB_ENERGY_VALUE
			self.combo = 0
			if body.has_method("on_hit"):
				body.on_hit(0, 0, 25) #sufficiently high accuracy value to trigger bomb 
			else:
				body.queue_free()
		else:
			velocity = controller.get("velocity")
		
			var linear_velocity = velocity.length()
			
			#print ("Controller velocity vector: ", velocity)
			#print ("Controller linear velocity: ", linear_velocity)
			
			if linear_velocity >= HIT_VELOCITY:
				#print ("Hit threshold passed!")
				
				var beat = 0
				if _beat_player:
					beat = _beat_player.get_beat()
				
				
				
				var hit_offset = beat - body._time
				var hit_accuracy = Utility.remap_value(hit_offset, hit_range, accuracy_range)
				#print ("accuracy:", hit_accuracy)
				
				
				self.combo+=1
				
				#calculate score value based on accuracy
				#if the value is outside the range, it's a miss!
				var score_value = 0
				
				if hit_accuracy<0.0 and hit_accuracy>3.0:
					self.combo = 0
					self.energy-= 1
					score_value = -50
					
				else:
					
					if controller.is_simple_rumbling():
						controller._rumble_duration = 0.25
					else:
						controller.simple_rumble(0.5, 0.25)
					
					#note is early
					if hit_accuracy>0.0 and hit_accuracy<1.0:
						score_value = 50
						self.energy += 1
					#note is perfect
					if hit_accuracy>1.0 and hit_accuracy<2.0:
						score_value = 100
						self.energy += 2
					#note is late
					if hit_accuracy>2.0 and hit_accuracy<3.0:
						score_value = 50
						self.energy += 1
	
				score_value *= combo
				
				self.score += score_value

				if body.has_method("on_hit"):
					body.on_hit(velocity, linear_velocity, hit_accuracy)
				else:
					body.queue_free()
		
#			if controller.get_rumble() == 0.0:
#				print("rumble")
#				controller.set_rumble(1.0)

##remaps a value from input range to output range
#func remap_value(value, input_range:Vector2, output_range:Vector2)->float:
#	return (value-input_range.x) / (input_range.y - input_range.x) * (output_range.y - output_range.x) + output_range.x

#SIGNAL CALLBACKS

func _on_left_hand_body_entered(body):
	handle_hit(body, "left")


func _on_right_hand_body_entered(body):
	handle_hit(body, "right")


#func _on_Area_body_exited_left(body):
#	handle_hit(body, "left")
#
#
#func _on_Area_body_exited_right(body):
#	handle_hit(body, "right")


func _on_Area_area_entered_right(area):
	handle_hit(area, "right")


func _on_Area_area_entered_left(area):
	handle_hit(area, "left")


func _on_LeftHand_button_pressed(button):
	button_pressed(button, "left")

func _on_RightHand_button_pressed(button):
	button_pressed(button, "right")

func _on_LeftHand_button_release(button):
	button_released(button, "left")

func _on_RightHand_button_release(button):
	button_released(button, "right")


var last_position

func pause_game():
	var pause_state = get_tree().paused
	get_tree().paused = !pause_state

	if get_tree().paused:
		set_process(false)
		if _beat_player:
			_beat_player.stream_paused = true
		$ARVROrigin/PauseLabel/UnpauseSound.play()
		$ARVROrigin/PauseLabel.visible=true
		#$ARVROrigin/PauseLabel.enable_collision()
		$ARVROrigin/PauseLabel.disable_collision = false
		#if game_node: game_node._spawn_location.visible = false
	else:
		set_process(true)
		if _beat_player:
			_beat_player.stream_paused = false
		$ARVROrigin/PauseLabel/PauseSound.play()
		$ARVROrigin/PauseLabel.visible=false
		$ARVROrigin/PauseLabel.disable_collision= true
		#if game_node: game_node._spawn_location.visible = true
	

func process_controller_input(hand, delta):
	var hand_object = null
	if hand=="left":
		hand_object = Global.manager()._left_hand
	elif hand=="right":
		hand_object = Global.manager()._right_hand

	if not hand_object:
		#print ("not a hand")
		return
	
	
	if in_game:
		time_direction = NEUTRAL
		
		var trigger
		var grip
		if Global.manager().webxr_interface:
			trigger = 4
			grip = 5
		else:
			trigger = JOY_VR_TRIGGER
			grip = JOY_VR_GRIP
		
		if hand_object._buttons_just_pressed[JOY_OCULUS_MENU]:
			pause_game()
		
		#if hand_object._buttons_pressed[JOY_OPENVR_MENU]:
		
		if hand_object._buttons_just_pressed[trigger] or hand_object._buttons_just_pressed[JOY_VR_GRIP]:
			if can_use_energy==false or energy<energy_decay_rate*delta:
				$BombSound.play()
		
		if hand_object._buttons_pressed[trigger]:
			if energy>energy_decay_rate*delta and can_use_energy:
				#print ("joy button pressed")
				#self.get_parent().toggle_speed(1.5, 0.1, 5.0, 0.01)
				self.song_acceleration+=acceleration_rate * delta
				time_direction = FASTER
				self.energy -= energy_decay_rate * delta
		
		if hand_object._buttons_pressed[grip]:
			if energy>energy_decay_rate*delta and can_use_energy:
				#print ("joy grip pressed")
				#self.get_parent().toggle_speed(0.5, 0.1, 5.0, 0.01)
				self.song_acceleration+=acceleration_rate * delta
				time_direction = SLOWER
				self.energy -= energy_decay_rate * delta
		




			

func button_pressed(button, hand):
	pass
#	var hand_object = null
#	if hand=="left":
#		hand_object = Global.manager()._left_hand
#	elif hand=="right":
#		hand_object = Global.manager()._right_hand
#
	#hand_object._buttons_just_pressed[button] = !hand_object._buttons_just_pressed[button]
	
#	hand_object._buttons_just_pressed[button] = 1
#	hand_object._buttons_pressed[button] = 1
	
	#hand_object.check_button(button,1)

func button_released(button,hand):
	pass
#	var hand_object = null
#	if hand=="left":
#		hand_object = Global.manager()._left_hand
#	elif hand=="right":
#		hand_object = Global.manager()._right_hand
#
#	hand_object.check_button(button,0)
	
#	hand_object._buttons_just_released[button] = 1
#	hand_object._buttons_pressed[button] = 0


func _on_HeadArea_area_entered(area):
	if area.is_in_group("obstacle"):
		$BombSound.play()
		self.combo = 0
		self.score -= 500
		self.energy -= 25
		game_node.toggle_speed(0.5, 0.1, 1.0, 0.01)
		disable_energy_use(1.5)

func disable_energy_use(seconds):
	can_use_energy = false
	yield(get_tree().create_timer(seconds),"timeout")
	can_use_energy = true


func _on_ResumeBtn_pressed():
	$ARVROrigin/PauseLabel/PauseSound.play()
	pause_game()

func _on_MenuBtn_pressed():
	$ARVROrigin/PauseLabel/PauseSound.play()
	pause_game()
	reset_player()
	yield(get_tree().create_timer(0.1),"timeout")
	Global.manager().load_scene(Global.manager().menu_path,"menu")

func _on_RestartBtn_pressed():
	$ARVROrigin/PauseLabel/PauseSound.play()
	reset_player()
	pause_game()
	yield(get_tree().create_timer(0.1),"timeout")
	Global.manager().load_scene(Global.manager().game_path,"game")
