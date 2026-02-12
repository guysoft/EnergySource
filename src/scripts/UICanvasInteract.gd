@tool
extends Node3D

#move this to a utility singleton
const UI_PIXELS_TO_METER = 1.0 / 1024

var ui_control:Control = null

@onready var viewport = $SubViewport
@onready var ui_area = $UIArea
@onready var mesh_instance : MeshInstance3D = $UIArea/UIMeshInstance

var ui_collisionshape = null;

@export var transparent = false
@export var disable_collision = false
@export var editor_live_update = false

var mesh_material = null

var ui_size = Vector2()

#func _input(event: InputEvent) -> void:
#	if event:
#		viewport.input(event)

func _get_configuration_warnings():
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
	if not ui_control:
		return
	
	var current_size = ui_control.get_size()
	var min_size = ui_control.get_combined_minimum_size()
	
	ui_size = current_size
	if ui_size.x < min_size.x:
		ui_size.x = min_size.x
	if ui_size.y < min_size.y:
		ui_size.y = min_size.y

	if (ui_area != null):
		ui_area.scale.x = ui_size.x * UI_PIXELS_TO_METER;
		ui_area.scale.y = ui_size.y * UI_PIXELS_TO_METER;
	if (viewport != null):
		print ("setting viewport size:", ui_size)
		viewport.set_size(ui_size);

	# Fix for Godot 4: Explicitly bind viewport texture to material
	if mesh_instance and viewport:
		var mat = mesh_instance.get_surface_override_material(0)
		if mat:
			mat.albedo_texture = viewport.get_texture()

func _ready():
	if mesh_instance:
		mesh_material = mesh_instance.get_surface_override_material(0);
		# only enable transparency when necessary as it is significantly slower than non-transparent rendering
		if mesh_material is StandardMaterial3D:
			mesh_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if transparent else BaseMaterial3D.TRANSPARENCY_DISABLED
	
	if Engine.is_editor_hint():
		return;
	
	find_child_control();
	update_size();
	
	if ui_control and ui_control.get_parent():
		ui_control.get_parent().remove_child(ui_control);
	if ui_control and viewport:
		viewport.add_child(ui_control);
		ui_control.visible = true; # set visible here as it might was set invisible for editing multiple controls
	
	if ui_area:
		ui_collisionshape = ui_area.get_node_or_null("UICollisionShape")

func _editor_update_preview():
	#duplicate the ui
	var preview_node= ui_control.duplicate(0)
	#set it to be visible
	preview_node.visible = true
	
	#remove all the current ui elements from the viewport
	for c in viewport.get_children():
		viewport.remove_child(c)
		c.queue_free()
	
	#readd the updated children to the viewport
	viewport.add_child(preview_node)


func disable_collision_func():
	if ui_collisionshape:
		ui_collisionshape.set_deferred("disabled", true)

func enable_collision():
	if ui_collisionshape:
		ui_collisionshape.set_deferred("disabled", false)

func _process(delta: float) -> void:
	#if we aren't in the editor
	if !Engine.is_editor_hint():
		if ui_control and ui_size != ui_control.get_size():
			update_size();
		if ui_collisionshape:
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
	
	
