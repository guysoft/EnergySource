extends Node3D

@export var miss_texture: Texture2D
@export var semi_texture: Texture2D    # Used for MINIMUMIMPACT (semi-hit)
@export var perfect_texture: Texture2D # Used for FULLIMPACT (full hit)
@export var late_texture: Texture2D    # Legacy, kept for compatibility
@export var bomb_texture: Texture2D

# HitLevel enum values (must match player.gd)
const HIT_LEVEL_TOOLOW = 0
const HIT_LEVEL_MINIMUMIMPACT = 1
const HIT_LEVEL_FULLIMPACT = 2

func show_feedback(position, hit_level):
	
	print ("hit_level: ", hit_level)
	global_transform.origin = position
	
	var mat = $MeshInstance3D.get_surface_override_material(0)
	if mat == null:
		mat = $MeshInstance3D.get_active_material(0)
	if mat == null:
		push_warning("NoteFeedback: No material found on MeshInstance3D")
		queue_free()
		return
	
	# PowerBeatsVR style feedback based on hit level
	match hit_level:
		HIT_LEVEL_TOOLOW:
			# Too weak / miss
			mat.albedo_texture = miss_texture
		HIT_LEVEL_MINIMUMIMPACT:
			# Semi-hit (minimum impact)
			mat.albedo_texture = semi_texture if semi_texture else miss_texture
		HIT_LEVEL_FULLIMPACT:
			# Full impact (perfect!)
			mat.albedo_texture = perfect_texture
		_:
			# Unknown - show miss
			mat.albedo_texture = miss_texture
	
	$AnimationPlayer.play("show")
	
	await $AnimationPlayer.animation_finished
	queue_free()
