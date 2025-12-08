extends XRController3D

@export var velocity_track_point: NodePath

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

var _simulation_buttons_pressed       = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];

var _buttons_pressed       = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
var _buttons_just_pressed  = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
var _buttons_just_released = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];

signal activated
signal deactivated

@onready var webxr_interface = Global.manager().webxr_interface

# Called when the node enters the scene tree for the first time.
func _ready():
	if velocity_track_point:
		pass
		# velocity_track_point = get_node(velocity_track_point) as Marker3D

func _get_button_name_from_index(index: int) -> String:
	match index:
		15: return "trigger_click"
		14: return "grip_click"
		13: return "menu_button"
		7: return "ax_button"
		1: return "by_button"
	return ""

func _get_index_from_button_name(name: String) -> int:
	match name:
		"trigger_click": return 15
		"grip_click": return 14
		"menu_button": return 13
		"ax_button": return 7
		"by_button": return 1
	return -1

func _on_button_released(name: String):
	var button = _get_index_from_button_name(name)
	if button == -1: return

#	var btn
#	if webxr_btn==0:
#		btn=JOY_VR_TRIGGER
#	if webxr_btn==1:
#		btn=JOY_VR_GRIP
#	check_button(0, btn)
	print ("release signal: ", name)
	_simulation_buttons_pressed[button]=0
	#check_button(button,0)
	
func _on_button_pressed(name: String):
	var button = _get_index_from_button_name(name)
	if button == -1: return

	print ("pressed signal: ", name)
	_simulation_buttons_pressed[button]=1
	#check_button(button,1)
#	var btn
#	if webxr_btn==0:
#		btn=JOY_VR_TRIGGER
#	if webxr_btn==1:
#		btn=JOY_VR_GRIP
#	check_button(1,btn)

func _process(delta):
	if Global.manager().webxr_interface:
		webxr_interface = Global.manager().webxr_interface
	if get_is_active():
		if !visible:
			visible = true
			print("Activated " + name)
			emit_signal("activated")
			if webxr_interface:
				connect("button_pressed", Callable(self, "_on_button_pressed"))
				connect("button_released", Callable(self, "_on_button_released"))
	elif visible:
		visible = false
		print("Deactivated " + name)
		emit_signal("deactivated")
		if webxr_interface:
			disconnect("button_pressed", Callable(self, "_on_button_pressed"))
			disconnect("button_released", Callable(self, "_on_button_released"))
	
	_update_buttons_and_sticks()
	_update_rumble(delta)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	#calc_velocity_old()
	if track_velocity:
		calc_velocity(delta)

func _sim_is_button_pressed(i) -> int:
	if GameVariables.ENABLE_VR and not webxr_interface:
		var button_name = _get_button_name_from_index(i)
		if button_name != "":
			return 1 if is_button_pressed(button_name) else 0 # convert bool to int
		return 0
	else: return _simulation_buttons_pressed[i]

func _update_buttons_and_sticks():
	for i in range(0,16):
#		if webxr_interface:
#			if i==JOY_VR_TRIGGER or i==JOY_VR_GRIP:
#				continue
		var b = _sim_is_button_pressed(i);
		check_button(i,b)

func check_button(i,b):
	if b != _buttons_pressed[i]:
		_buttons_pressed[i] = b
		if b==1:
			_buttons_just_pressed[i]=1
		else:
			_buttons_just_released[i]=1
	else:
		_buttons_just_pressed[i]=0
		_buttons_just_released[i]=0

func is_button_just_pressed(button_name: String) -> bool:
	var index = _get_index_from_button_name(button_name)
	if index == -1:
		return false
	return _buttons_just_pressed[index] == 1

func is_button_just_released(button_name: String) -> bool:
	var index = _get_index_from_button_name(button_name)
	if index == -1:
		return false
	return _buttons_just_released[index] == 1

func simple_rumble(intensity, duration):
	_rumble_intensity = intensity;
	_rumble_duration = duration;
	
func is_simple_rumbling():
	return (_rumble_duration > 0.0);
	
func _update_rumble(dt):
	if (_rumble_duration < - 100): return;
	trigger_haptic_pulse("haptic", 100.0, _rumble_intensity, 0.1, 0)
	_rumble_duration -= dt;
	if (_rumble_duration <= 0.0):
		_rumble_duration = -128.0;
		trigger_haptic_pulse("haptic", 100.0, 0.0, 0.1, 0)

func calc_velocity(delta):
	velocity = Vector3(0, 0, 0)

	if points.size() > 0:
		for vel in points:
			velocity += vel

		# Get the average velocity, instead of just adding them together.
		velocity = velocity / points.size()

	var tracker_node = get_node(velocity_track_point)
	if not tracker_node:
		return

	points.append((tracker_node.global_transform.origin - prior_controller_position) / delta)

	velocity += (tracker_node.global_transform.origin - prior_controller_position) / delta
	prior_controller_position = tracker_node.global_transform.origin

	if points.size() > TRACK_LENGTH:
		points.remove_at(0)


func calc_velocity_old():
	var time_now = Time.get_ticks_usec()
	
	points.append([time_now, self.transform.origin])
	
	for i in range(points.size()-1, -1, -1):
		if time_now - points[i][0] > TIME_CIRCLE:
			points.remove_at(i)
			
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
