extends Node3D

@export var miss_texture: Texture2D
@export var early_texture: Texture2D
@export var perfect_texture: Texture2D
@export var late_texture: Texture2D
@export var bomb_texture: Texture2D


#var hit_range = Vector2(-0.25, 0.25)
#var increment = 17.0
#var increment = (abs(hit_range.x) + abs(hit_range.y)) / 3

func show_feedback(position, accuracy):
	
	print ("accuracy: ", accuracy)
	global_transform.origin = position
	
	var mat = $MeshInstance3D.get_surface_override_material(0)
	if mat == null:
		mat = $MeshInstance3D.get_active_material(0)
	if mat == null:
		push_warning("NoteFeedback: No material found on MeshInstance3D")
		queue_free()
		return
	
	#EARLY
	if accuracy>0.0 and accuracy < 1.0:
		#print ("EARLY")
		mat.albedo_texture = early_texture
		#$AnimationPlayer.play("Early")
	
	#PERFECT
	if accuracy>1.0 and accuracy<2.0:
		#print ("PERFECT")
		mat.albedo_texture = perfect_texture
		#$AnimationPlayer.play("Perfect")
	
	#LATE
	if accuracy>2.0 and accuracy<3.0:
		#print ("LATE")
		mat.albedo_texture = late_texture
		#$AnimationPlayer.play("Late")
	
	#MISS
	if accuracy<0.0 or accuracy>3.0:
		#print ("MISS")
		mat.albedo_texture = miss_texture
		#$AnimationPlayer.play("Miss")

	#special case for bombs
	if accuracy==25:
		#print ("BOMB")
		mat.albedo_texture = bomb_texture
	
	$AnimationPlayer.play("show")
	
	await $AnimationPlayer.animation_finished
	queue_free()
