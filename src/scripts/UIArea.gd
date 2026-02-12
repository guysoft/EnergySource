# A Helper to make UIs work on a Area object
extends Area3D

# Member variables
var prev_pos = null
var last_click_pos = null
var viewport = null

var last_pos2d = null;

# Re-entrancy guard to prevent stack overflow from synchronous input processing
var _processing_input := false


func ui_raycast_hit_event(position, click, release):
	# Prevent re-entrant calls that could cause stack overflow
	if _processing_input:
		return
	
	# note: this transform assumes that the unscaled area is [-0.5, -0.5] to [0.5, 0.5] in size
	var local_position = to_local(position);
	var pos2d = Vector2(local_position.x, -local_position.y)
	pos2d = pos2d + Vector2(0.5, 0.5)
	pos2d.x *= viewport.size.x
	pos2d.y *= viewport.size.y
	

	if (click || release):
		var e = InputEventMouseButton.new();
		e.pressed = click;
		e.button_index = MOUSE_BUTTON_LEFT;
		e.position = pos2d;
		e.global_position = pos2d;
		
		if (click): print("Click");
		if (release): print("Release");

		# Use call_deferred to prevent stack overflow from synchronous input processing
		_processing_input = true
		viewport.push_input.call_deferred(e);
		call_deferred("_reset_processing_input")
		
	elif (last_pos2d != null && last_pos2d != pos2d):
		var e = InputEventMouseMotion.new();
		e.relative = pos2d - last_pos2d;
		e.velocity = (pos2d - last_pos2d) / 16.0; #?? chose an arbitrary scale here for now
		e.global_position = pos2d;
		e.position = pos2d;
		
		# Use call_deferred for motion too to maintain consistency
		viewport.push_input.call_deferred(e);
	last_pos2d = pos2d;


func _reset_processing_input():
	_processing_input = false


func _ready():
	viewport = get_parent().get_node("SubViewport");
