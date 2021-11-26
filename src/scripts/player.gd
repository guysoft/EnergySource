extends KinematicBody

# Ball mechanics settnings
var HIT_VELOCITY = 0

export(NodePath) onready var beat_player

# Payer movement in non-vr mode settings
export var Sensitivity_X = 0.01
export var Sensitivity_Y = 0.01
export var Invert_Y_Axis = true
export var Exit_On_Escape = true
export var Maximum_Y_Look = 45
export var Accelaration = 5
export var Maximum_Walk_Speed = 10
export var Jump_Speed = 2

const GRAVITY = 0 #0.098
var velocity = Vector3(0,0,0)
var forward_velocity = 0
var Walk_Speed = 0.1

var score = 0 setget set_score

func set_score(new_val):
	score = new_val
	Events.emit_signal("current_score_updated", score)

func _ready():
	# TODO Change this not to the global variable
	# but after checking if vr worked
	
	beat_player = get_node(beat_player)
	
	if not GameVariables.ENABLE_VR:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		forward_velocity = Walk_Speed
		set_process(true)
	

func _process(delta):
	if not GameVariables.ENABLE_VR:
		if Exit_On_Escape:
				if Input.is_key_pressed(KEY_ESCAPE):
						get_tree().quit()
	
	
	
func _physics_process(delta):
	if not GameVariables.ENABLE_VR:
		velocity.y -= GRAVITY
		
		if Input.is_key_pressed(KEY_P):
			self.get_parent().toggle_speed(0.5, 0.1, 5.0, 0.01)
		
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
		controller = $ARVROrigin/LeftHand
	else:
		controller = $ARVROrigin/RightHand
	
	print("hit " + hand + " "  + body.name)
	# body.name == "Ball" TODO, remove the balls
	if body.is_in_group("note"):
		velocity = controller.get("velocity")
	
		var linear_velocity = velocity.length()
		
		print ("Controller velocity vector: ", velocity)
		print ("Controller linear velocity: ", linear_velocity)
		
		if linear_velocity >= HIT_VELOCITY:
			print ("Hit threshold passed!")
			
			var beat = 0
			if beat_player:
				beat = beat_player.get_beat()
			
			self.score += body.calc_score(beat)
			
			if body.has_method("on_hit"):
				body.on_hit(velocity, linear_velocity)
			else:
				body.queue_free()
			
#			if controller.get_rumble() == 0.0:
#				print("rumble")
#				controller.set_rumble(1.0)

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

func button_pressed(button, hand):
	if button ==  JOY_VR_TRIGGER:
		self.get_parent().toggle_speed(0.5, 0.1, 5.0, 0.01)
