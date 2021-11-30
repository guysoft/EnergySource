extends Spatial

export(Texture) var miss_texture
export(Texture) var early_texture
export(Texture) var perfect_texture
export(Texture) var late_texture

var hit_range = Vector2(-0.25, 0.25)
#var increment = 17.0
var increment = (hit_range.x + hit_range.y) / 3

func show_feedback(position, accuracy):
	
	print ("accuracy: ", accuracy)
	global_transform.origin = position
	
	var mat = $MeshInstance.get_surface_material(0)
	
	
	#LATE
	if accuracy>hit_range.x and accuracy < (hit_range.x + increment):
		print ("LATE")
		mat.albedo_texture = late_texture
		#$AnimationPlayer.play("Late")
	
	#PERFECT
	if accuracy>(hit_range.x+increment) and accuracy<(hit_range.y-increment):
		print ("PERFECT")
		mat.albedo_texture = perfect_texture
		#$AnimationPlayer.play("Perfect")
	
	#EARLY
	if accuracy>(hit_range.y-increment) and accuracy<hit_range.y:
		print ("EARLY")
		mat.albedo_texture = early_texture
		#$AnimationPlayer.play("Early")
	
	#MISS
	if accuracy<hit_range.x or accuracy>hit_range.y:
		print ("MISS")
		mat.albedo_texture = miss_texture
		#$AnimationPlayer.play("Miss")

	
	$AnimationPlayer.play("show")
	
	yield($AnimationPlayer, "animation_finished")
	queue_free()
