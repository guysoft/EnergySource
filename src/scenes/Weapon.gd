extends Spatial

class_name Weapon

enum HANDS{LEFT,RIGHT}

#TODO: offload to global so player can change weapon color
const LEFT_COLOR = Color("67f8fd")
const RIGHT_COLOR = Color("f66df4")


export(String) var weapon_name="Weapon"
export(HANDS) var hand
export(NodePath) var mesh

var material
var area
var velocity_track_point

func _ready():
	pass

func _enter_tree():
	if mesh:
		mesh = get_node(mesh) as MeshInstance
	
	material = mesh.get_surface_material(0)
	
	if hand==HANDS.LEFT:
		material.albedo_color = LEFT_COLOR
	else:
		material.albedo_color = RIGHT_COLOR
	
	connect_signals()

func connect_signals():
	if (find_node("Area")):
		area = get_node("Area")
		area.connect("area_entered", self, "_on_area_entered")

func get_track_point():
	if has_node("EndTracker"):
		return get_node("EndTracker")

func _on_area_entered(area):
	#Events.emit_signal("weapon_hit", Weapon)
	#BAD CASTING, NEED TO STANDARDIZE LEFT/RIGHT CONTROLLER ENUMS
	var hand_string
	if hand==HANDS.LEFT: hand_string = "left"
	else:
		hand_string="right"
	Events.emit_signal("weapon_hit", area, hand_string)
