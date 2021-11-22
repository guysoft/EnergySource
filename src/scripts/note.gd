extends Area

class_name Note

export(float) var speed = 2
export(Vector3) var direction = Vector3(0,0,1)

onready var _velocity = Vector3(0,0,0)

var _time:float
var _line_index:int
var _line_layer:int
var _type:int
var _cut_direction:int
var _custom_data = {}

#Refs
onready var _mesh = $MeshInstance
onready var _collision = $CollisionShape


func _ready():
	deactivate()
	
func setup_note(note):
	if not note:
		return
	
#	print ("setting up note")
#	print (note)
	
	if "_time" in note:
		_time = float(note["_time"])
	if "_line_index" in note:
		_line_index = note["_line_index"]
	if "_line_layer" in note:
		_line_layer = note["_line_layer"]
	if "_type" in note:
		_type = note["_type"]
	if "_cut_direction" in note:
		_cut_direction = note["_cut_direction"]
	if "_custom_data" in note:
		_custom_data = note["_custom_data"] #Might have to make a copy

func activate():
#	print ("note activated: ", name)
#	print ("time: ", _time)
#	print ("line index: ", _line_index)
#	print ("line layer: ", _line_layer)
#	print ("type: ", _type)
#	print ("time: ", _cut_direction)
#	print ("custom_data: ", _custom_data)
	set_physics_process(true)
	_collision.set_deferred("disabled", false)
	_mesh.visible=true

func deactivate():
	set_physics_process(false)
	_collision.set_deferred("disabled", true)
	_mesh.visible=false
	
func _physics_process(delta):
	_velocity = direction * speed * delta
	translate(_velocity)
	
	if self.transform.origin.z > 4:
		# print("ball freed")
		#self.queue_free()
		self.deactivate()
