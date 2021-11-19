extends Node


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_Timer_timeout():
	# print("Spawn start")
	var rand = RandomNumberGenerator.new()
	var ballscene = load("res://scenes/ball.tscn")
	
	var wall_size = 1
	
	var ball = ballscene.instance()
	rand.randomize()
	ball.transform.origin = Vector3(
		rand.randf_range(-wall_size, wall_size),
		rand.randf_range(0.5, 2),
		- 2
	)
	# print("Done")
	
	self.add_child(ball)

