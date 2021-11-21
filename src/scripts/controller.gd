extends ARVRController

var velocity = Vector3(0,0,0)
var old_velocity = Vector3(0,0,0)
var points = []

# How much points to keep in history
const TIME_CIRCLE = 500000


# Called when the node enters the scene tree for the first time.
func _ready():
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	# Calculate velocity
	var time_now = OS.get_ticks_usec()
	
	points.append([time_now, self.transform.origin])
	
	for i in range(points.size()-1, -1, -1):
		if time_now - points[i][0] > TIME_CIRCLE:
			points.remove(i)
			
	var last_point = points[points.size()-2][1]
	var last_time = points[points.size()-2][0]
	var location_now = self.transform.origin
			
	velocity = (location_now - last_point) / (time_now - last_time) * 1000000
	
	if not abs(velocity.x) < 2 or not abs(velocity.x) > 1:
		velocity.x = 0

	if not abs(velocity.y) < 2 or not abs(velocity.y) > 1:
		velocity.y = 0

	if not abs(velocity.z) < 2 or not abs(velocity.z) > 1:
		velocity.z = 0
			
	velocity.x = velocity.x* sin(self.rotation.x) + 0.9*old_velocity.x
	velocity.y = velocity.y* sin(self.rotation.y) + 0.9*old_velocity.y
	velocity.z = velocity.z* sin(self.rotation.z) + 0.9*old_velocity.z
			
