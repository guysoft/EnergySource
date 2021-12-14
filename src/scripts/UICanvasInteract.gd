tool
extends Spatial

#move this to a utility singleton
const UI_PIXELS_TO_METER = 1.0 / 1024

var ui_control:Control = null

onready var viewport = $Viewport
onready var ui_area = $UIArea
onready var mesh_instance : MeshInstance = $UIArea/UIMeshInstance

var ui_collisionshape = null;

export var transparent = false
export var disable_collision = false
export var editor_live_update = false

var mesh_material = null

var ui_size = Vector2()

#func _input(event: InputEvent) -> void:
#	if event:
#		viewport.input(event)

func _get_configuration_warning():
	if (ui_control == null): return "Need a Control node as child."
	return '';

#find the control node
#searches through all the children and finds the control node
func find_child_control():
	ui_control = null;
	for c in get_children():
		if c is Control:
			ui_control = c;
			break;
			

func update_size():
	ui_size = ui_control.get_size();
	if (ui_area != null):
		ui_area.scale.x = ui_size.x * UI_PIXELS_TO_METER;
		ui_area.scale.y = ui_size.y * UI_PIXELS_TO_METER;
	if (viewport != null):
		print ("setting viewport size:", ui_size)
		viewport.set_size(ui_size);

func _ready():
	mesh_material = mesh_instance.get_surface_material(0);
	# only enable transparency when necessary as it is significantly slower than non-transparent rendering
	mesh_material.flags_transparent = transparent;
	
	if Engine.editor_hint:
		return;
	
	find_child_control();
	update_size();
	
	ui_control.get_parent().remove_child(ui_control);
	viewport.add_child(ui_control);
	ui_control.visible = true; # set visible here as it might was set invisible for editing multiple controls
	
	ui_collisionshape = $UIArea/UICollisionShape

func _editor_update_preview():
	#duplicate the ui
	var preview_node= ui_control.duplicate(DUPLICATE_USE_INSTANCING)
	#set it to be visible
	preview_node.visible = true
	
	#remove all the current ui elements from the viewport
	for c in viewport.get_children():
		viewport.remove_child(c)
		c.queue_free()
	
	#readd the updated children to the viewport
	viewport.add_child(preview_node)


func disable_collision():
	ui_collisionshape.set_deferred("disabled", true)

func enable_collision():
	ui_collisionshape.set_deferred("disabled", false)

func _process(delta: float) -> void:
	#if we aren't in the editor
	if !Engine.editor_hint:
		if ui_size!=ui_control.get_size():
			update_size();
		if disable_collision:
			#disable the collision
			ui_collisionshape.disabled = true
		else:
			#if visible, disabled is false, if not visible, disabled is true
			ui_collisionshape.disabled = not is_visible_in_tree()
		return
	
	#if we are in the editor
	var last = ui_control
	find_child_control()
	if (ui_control != null):
		if (last != ui_control || ui_size != ui_control.get_size()):
			update_size();
			_editor_update_preview()
		elif (editor_live_update):
			_editor_update_preview()
	
	
