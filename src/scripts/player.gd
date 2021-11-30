extends KinematicBody

# velocity mechanics settnings
const HIT_VELOCITY = 0
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

var energy_decay_rate = 10

func reset_player():
	self.score = 0
	self.energy = 0
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
	Events.emit_signal("current_energy_updated", energy)

func _ready():
	# TODO Change this not to the global variable
	# but after checking if vr worked
	
	_beat_player = Global.manager()._beatplayer
	
	if not GameVariables.ENABLE_VR:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		forward_velocity = Walk_Speed
		set_process(true)
	

func _process(delta):
	
	
	process_controller_input("left", delta)
	process_controller_input("right", delta)
	
	if in_game and game_node:
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
	
	if not GameVariables.ENABLE_VR:
		if Exit_On_Escape:
				if Input.is_key_pressed(KEY_ESCAPE):
						get_tree().quit()
	
	
	
func _physics_process(delta):
	
	if not GameVariables.ENABLE_VR:
		velocity.y -= GRAVITY
		
		if game_node:
			if Input.is_key_pressed(KEY_P):
				game_node.toggle_speed(0.5, 0.1, 5.0, 0.01)
		
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
	if not GameVariables.ENABLE_VR:
		if event is InputEventMouseMotion:
			rotate_y(-Sensitivity_X * event.relative.x)
			# rotate_x(-Sensitivity_Y * event.relative.y)


func handle_hit(body, hand):
	var controller = null
	if hand == "left":
		controller = Global.manager()._left_hand
	else:
		controller = Global.manager()._right_hand
	print("hit " + hand + " "  + body.name)
	
	
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
			
			print ("Controller velocity vector: ", velocity)
			print ("Controller linear velocity: ", linear_velocity)
			
			if linear_velocity >= HIT_VELOCITY:
				print ("Hit threshold passed!")
				
				var beat = 0
				if _beat_player:
					beat = _beat_player.get_beat()
				
				self.energy += 1
				
				var hit_offset = beat - body._time
				var hit_accuracy = remap_value(hit_offset, hit_range, accuracy_range)
				print ("accuracy:", hit_accuracy)
				
				
				self.combo+=1
				
				#calculate score value based on accuracy
				#if the value is outside the range, it's a miss!
				var score_value = 0
				
				if hit_accuracy<0.0 and hit_accuracy>3.0:
					self.combo = 0
					score_value = -50
				else:
					
					if controller.is_simple_rumbling():
						controller._rumble_duration = 0.25
					else:
						controller.simple_rumble(0.5, 0.25)
					
					#note is early
					if hit_accuracy>0.0 and hit_accuracy<1.0:
						score_value = 50
					#note is perfect
					if hit_accuracy>1.0 and hit_accuracy<2.0:
						score_value = 100
					#note is late
					if hit_accuracy>2.0 and hit_accuracy<3.0:
						score_value = 50
	
				score_value *= combo
				
				self.score += score_value

				if body.has_method("on_hit"):
					body.on_hit(velocity, linear_velocity, hit_accuracy)
				else:
					body.queue_free()
		
#			if controller.get_rumble() == 0.0:
#				print("rumble")
#				controller.set_rumble(1.0)

#remaps a value from input range to output range
func remap_value(value, input_range:Vector2, output_range:Vector2)->float:
	return (value-input_range.x) / (input_range.y - input_range.x) * (output_range.y - output_range.x) + output_range.x

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

func process_controller_input(hand, delta):
	var hand_object = null
	if hand=="left":
		hand_object = Global.manager()._left_hand
	elif hand=="right":
		hand_object = Global.manager()._right_hand
	
	if not hand_object:
		print ("not a hand")
		return
	
	time_direction = NEUTRAL
	
	if hand_object._buttons_pressed[JOY_VR_TRIGGER] and energy>energy_decay_rate*delta:
		print ("joy button pressed")
		#self.get_parent().toggle_speed(1.5, 0.1, 5.0, 0.01)
		self.song_acceleration+=acceleration_rate * delta
		time_direction = FASTER
		self.energy -= energy_decay_rate * delta
	if hand_object._buttons_pressed[JOY_VR_GRIP] and energy>energy_decay_rate*delta:
		print ("joy grip pressed")
		#self.get_parent().toggle_speed(0.5, 0.1, 5.0, 0.01)
		self.song_acceleration+=acceleration_rate * delta
		time_direction = SLOWER
		self.energy -= energy_decay_rate * delta

func button_pressed(button, hand):
	pass
