extends Spatial

export(Texture) var miss_texture
export(Texture) var early_texture
export(Texture) var perfect_texture
export(Texture) var late_texture

#var hit_range = Vector2(-0.25, 0.25)
#var increment = 17.0
#var increment = (abs(hit_range.x) + abs(hit_range.y)) / 3

func show_feedback(position, accuracy):
	
	print ("accuracy: ", accuracy)
	global_transform.origin = position
	
	var mat = $MeshInstance.get_surface_material(0)
	
	
	#EARLY
	if accuracy>0.0 and accuracy < 1.0:
		print ("EARLY")
		mat.albedo_texture = early_texture
		#$AnimationPlayer.play("Early")
	
	#PERFECT
	if accuracy>1.0 and accuracy<2.0:
		print ("PERFECT")
		mat.albedo_texture = perfect_texture
		#$AnimationPlayer.play("Perfect")
	
	#LATE
	if accuracy>2.0 and accuracy<3.0:
		print ("LATE")
		mat.albedo_texture = late_texture
		#$AnimationPlayer.play("Late")
	
	#MISS
	if accuracy<0.0 or accuracy>3.0:
		print ("MISS")
		mat.albedo_texture = miss_texture
		#$AnimationPlayer.play("Miss")

	
	$AnimationPlayer.play("show")
	
	yield($AnimationPlayer, "animation_finished")
	queue_free()
