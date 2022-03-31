extends Spatial

class_name Weapon

enum HANDS{LEFT,RIGHT}

const LEFT_COLOR = Color("f66df4")
const RIGHT_COLOR = Color("67f8fd")

export(HANDS) var hand

onready var material = $Blade.get_surface_material(0)

var velocity_track_point

func _ready():
	if hand==HANDS.LEFT:
		material.albedo_color = LEFT_COLOR
	else:
		material.albedo_color = RIGHT_COLOR
		

func get_track_point():
	if has_node("EndTracker"):
		return get_node("EndTracker")
