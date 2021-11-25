tool
extends Spatial

class_name UICanvas

var ui_control:Control = null

onready var viewport = $Viewport
onready var ui_mesh_instance:MeshInstance = $UIMeshInstance

export var transparent = false
export var editor_live_update = false setget set_editor_update

var mesh_material = null

var ui_size = Vector2()

func _get_configuration_warning():
	if (ui_control == null): return "Need a Control node as child."
	return '';

#find the control node
#searches through all the children and finds the control node
func find_child_control():
	ui_control = null
	for c in get_children():
		if c is Control:
			ui_control = c
			break;
			

func update_size():
	ui_size = ui_control.get_size();
	if (ui_mesh_instance != null):
		ui_mesh_instance.scale.x = ui_size.x * GameVariables.UI_PIXELS_TO_METER
		ui_mesh_instance.scale.y = ui_size.y * GameVariables.UI_PIXELS_TO_METER
	if (viewport != null):
		print ("setting viewport size:", ui_size)
		viewport.set_size(ui_size)

func _ready():
	mesh_material = ui_mesh_instance.get_surface_material(0)
	# only enable transparency when necessary as it is significantly slower than non-transparent rendering
	mesh_material.flags_transparent = transparent
	
	if Engine.editor_hint:
		return;
	
	find_child_control()
	update_size()
	
	ui_control.get_parent().remove_child(ui_control)
	viewport.add_child(ui_control)
	ui_control.visible = true; # set visible here as it might was set invisible for editing multiple controls


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


func set_editor_update(val):
	editor_live_update = val

func update_editor():
	var last = ui_control
	find_child_control()
	if (ui_control != null):
		if (last != ui_control || ui_size != ui_control.get_size()):
			update_size();
			_editor_update_preview()
		elif (editor_live_update):
			_editor_update_preview()

func _process(delta: float) -> void:
	#if we aren't in the editor
	if !Engine.editor_hint:
		return
	
	update_editor()
	
	
