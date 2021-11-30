extends ARVRController

var track_velocity := true

var velocity = Vector3(0,0,0)
var old_velocity = Vector3(0,0,0)
var points = []

var prior_controller_position = Vector3(0,0,0)

# How much points to keep in history
const TIME_CIRCLE = 500000

const TRACK_LENGTH = 30

var _rumble_intensity = 0.0;
var _rumble_duration = -128.0; #-1 means deactivated so applications can also set their own rumble

var _buttons_pressed       = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
var _buttons_just_pressed  = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
var _buttons_just_released = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];

signal activated
signal deactivated


# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func _process(delta):
	if get_is_active():
		if !visible:
			visible = true
			print("Activated " + name)
			emit_signal("activated")
	elif visible:
		visible = false
		print("Deactivated " + name)
		emit_signal("deactivated")
	
	_update_buttons_and_sticks()
	_update_rumble(delta)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	#calc_velocity_old()
	if track_velocity:
		calc_velocity(delta)

func _update_buttons_and_sticks():
	for i in range(0,16):
		
		var b = is_button_pressed(i)
		
		if b != _buttons_pressed[i] :
			_buttons_pressed[i] = b
			print (i, " pressed")
			if b==1:
				_buttons_just_pressed[i]=1
				print (i, " just pressed")
			else:
				_buttons_just_released[i]=1
				print (i, " just released")
		else:
			_buttons_just_pressed[i]=0
			_buttons_just_released[i]=0


func simple_rumble(intensity, duration):
	_rumble_intensity = intensity;
	_rumble_duration = duration;
	
func is_simple_rumbling():
	return (_rumble_duration > 0.0);
	
func _update_rumble(dt):
	if (_rumble_duration < - 100): return;
	set_rumble(_rumble_intensity);
	_rumble_duration -= dt;
	if (_rumble_duration <= 0.0):
		_rumble_duration = -128.0;
		set_rumble(0.0);

func calc_velocity(delta):
	velocity = Vector3(0, 0, 0)

	if points.size() > 0:
		for vel in points:
			velocity += vel

		# Get the average velocity, instead of just adding them together.
		velocity = velocity / points.size()

	points.append((global_transform.origin - prior_controller_position) / delta)

	velocity += (global_transform.origin - prior_controller_position) / delta
	prior_controller_position = global_transform.origin

	if points.size() > TRACK_LENGTH:
		points.remove(0)


func calc_velocity_old():
	var time_now = OS.get_ticks_usec()
	
	points.append([time_now, self.transform.origin])
	
	for i in range(points.size()-1, -1, -1):
		if time_now - points[i][0] > TIME_CIRCLE:
			points.remove(i)
			
	var last_point = points[points.size()-2][1]
	var last_time = points[points.size()-2][0]
	var location_now = self.transform.origin
			
	velocity = (location_now - last_point) / (time_now - last_time) * 1000000
	
	if not abs(velocity.x) < 2 or not abs(velocity.x) > 1:
		velocity.x = 0

	if not abs(velocity.y) < 2 or not abs(velocity.y) > 1:
		velocity.y = 0

	if not abs(velocity.z) < 2 or not abs(velocity.z) > 1:
		velocity.z = 0
			
	velocity.x = velocity.x* sin(self.rotation.x) + 0.9*old_velocity.x
	velocity.y = velocity.y* sin(self.rotation.y) + 0.9*old_velocity.y
	velocity.z = velocity.z* sin(self.rotation.z) + 0.9*old_velocity.z
