extends Spatial

var BALL_SPEED = 0.01

# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass
	# print("ball created")
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	self.transform.origin = Vector3(self.transform.origin.x, self.transform.origin.y, self.transform.origin.z + BALL_SPEED)
	
	if self.transform.origin.z > 1:
		# print("ball freed")
		self.free()
	




func _on_CollisionShape_gameplay_entered(body):
	print("wee")
