extends Spatial

export(Texture) var miss_texture
export(Texture) var early_texture
export(Texture) var perfect_texture
export(Texture) var late_texture

func show_feedback(position, accuracy):
	
	print ("accuracy: ", accuracy)
	global_transform.origin = position
	
	var mat = $MeshInstance.get_surface_material(0)
	
	
	#LATE
	if accuracy>-0.1 and accuracy<-0.03:
		print ("LATE")
		mat.albedo_texture = late_texture
		#$AnimationPlayer.play("Late")
	
	#PERFECT
	if accuracy>-0.03 and accuracy<0.08:
		print ("PERFECT")
		mat.albedo_texture = perfect_texture
		#$AnimationPlayer.play("Perfect")
	
	#EARLY
	if accuracy>0.08 and accuracy<0.15:
		print ("EARLY")
		mat.albedo_texture = early_texture
		#$AnimationPlayer.play("Early")
	
	#MISS
	if accuracy<-0.15 or accuracy>0.15:
		print ("MISS")
		mat.albedo_texture = miss_texture
		#$AnimationPlayer.play("Miss")

	
	$AnimationPlayer.play("show")
	
	yield($AnimationPlayer, "animation_finished")
	queue_free()
