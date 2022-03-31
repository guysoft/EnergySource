extends Spatial

class_name Weapon

enum HANDS{LEFT,RIGHT}

#TODO: offload to global so player can change weapon color
const LEFT_COLOR = Color("f66df4")
const RIGHT_COLOR = Color("67f8fd")

export(HANDS) var hand
export(NodePath) var mesh

var material
var velocity_track_point

func _ready():
	
	if mesh:
		mesh = get_node(mesh) as MeshInstance
		
		material = mesh.get_surface_material(0)
		
		if hand==HANDS.LEFT:
			material.albedo_color = LEFT_COLOR
		else:
			material.albedo_color = RIGHT_COLOR
		

func get_track_point():
	if has_node("EndTracker"):
		return get_node("EndTracker")
