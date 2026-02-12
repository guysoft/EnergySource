extends Node3D

@export var active := true;
@export var controller_path: NodePath
@export var ui_raycast_length := 3.0;
@export var ui_mesh_length := 1.0;

@export var adjust_left_right := true;

# Controller reference - resolved in _ready()
var controller_node: XRController3D = null

# Camera mode: when no controller is set, this raycast is used for non-VR mouse look-and-click
var is_camera_mode := false

@onready var ui_raycast_position : Node3D = $RayCastPosition;
@onready var ui_raycast : RayCast3D = $RayCastPosition/RayCast3D;
@onready var ui_raycast_mesh : MeshInstance3D = $RayCastPosition/RayCastMesh;
@onready var ui_raycast_hitmarker : MeshInstance3D = $RayCastPosition/RayCastHitMarker;
@onready var webxr = Global.manager().webxr_interface

var is_colliding := false;

# Track button state for just pressed/released detection
var _trigger_was_pressed := false
var _mouse_was_pressed := false

func _ready():
	# Resolve controller path to node reference
	if controller_path:
		var node = get_node_or_null(controller_path)
		if node is XRController3D:
			controller_node = node
	
	# Determine if we're in camera mode (no controller = camera-based raycast for non-VR)
	is_camera_mode = (controller_node == null)
	
	if is_camera_mode:
		# Camera mode: raycast forward (-Z axis) for look-and-click selection
		ui_raycast.set_target_position(Vector3(0, 0, -ui_raycast_length));
		
		# Setup the mesh to extend along Z axis (forward direction)
		var box_mesh = BoxMesh.new()
		box_mesh.size = Vector3(0.004, 0.004, ui_mesh_length)
		ui_raycast_mesh.mesh = box_mesh
		ui_raycast_mesh.position = Vector3(0, 0, -ui_mesh_length * 0.5)
	else:
		# Controller mode: raycast along -Y axis to align with blade direction
		ui_raycast.set_target_position(Vector3(0, -ui_raycast_length, 0));
		
		# Setup the mesh to extend along Y axis (blade direction)
		var box_mesh = BoxMesh.new()
		box_mesh.size = Vector3(0.004, ui_mesh_length, 0.004)
		ui_raycast_mesh.mesh = box_mesh
		ui_raycast_mesh.position = Vector3(0, -ui_mesh_length * 0.5, 0)
	
	ui_raycast_hitmarker.visible = false;
	ui_raycast_mesh.visible = false

# we use the physics process here be in sync with the controller position
func _physics_process(_dt):
	if (!active): 
		return;
	if (!visible): 
		return;
	if Global.manager().webxr_interface:
		webxr = Global.manager().webxr_interface
	_update_raycasts();


func _update_raycasts():
	ui_raycast_hitmarker.visible = false;
	ui_raycast_mesh.visible = false;
	
	ui_raycast.force_raycast_update(); # need to update here to get the current position; else the marker laggs behind
	
	if ui_raycast.is_colliding():
		
		var c = ui_raycast.get_collider();
		if (!c.has_method("ui_raycast_hit_event")): 
			print ("does not have ui_raycast_hit_event")
			return;
		
		var click = false;
		var release = false;
		
		# Show raycast mesh when pointing at UI
		ui_raycast_mesh.visible = true;
		
		if controller_node:
			# Use XRController3D's is_button_pressed for proper XR input detection
			# This works with both real VR hardware and XR Simulator
			var trigger_pressed = controller_node.is_button_pressed("trigger_click")
			click = trigger_pressed and not _trigger_was_pressed
			release = not trigger_pressed and _trigger_was_pressed
			_trigger_was_pressed = trigger_pressed
		else:
			# Non-VR mode: support both keyboard (ui_accept) and mouse click
			var keyboard_click = Input.is_action_just_pressed("ui_accept", false)
			var keyboard_release = Input.is_action_just_released("ui_accept", false)
			
			# Also check for mouse button click (left mouse button)
			var mouse_pressed = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
			var mouse_click = mouse_pressed and not _mouse_was_pressed
			var mouse_release = not mouse_pressed and _mouse_was_pressed
			_mouse_was_pressed = mouse_pressed
			
			click = keyboard_click or mouse_click
			release = keyboard_release or mouse_release
		
		var hit_position = ui_raycast.get_collision_point();
		ui_raycast_hitmarker.visible = true;
		ui_raycast_hitmarker.global_transform.origin = hit_position;
		
		c.ui_raycast_hit_event(hit_position, click, release);
		is_colliding = true;
	else:
		is_colliding = false;
		_trigger_was_pressed = false; # Reset when not colliding
		_mouse_was_pressed = false; # Reset mouse state when not colliding
