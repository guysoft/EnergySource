extends Node3D

# Floating score text that appears at hit location and drifts away
# Green for full/perfect hits (FULLIMPACT), white for partial hits (MINIMUMIMPACT)
# Matches PowerBeatsVR behavior

@onready var _label: Label3D = $Label3D

# Animation constants (matching PowerBeatsVR)
const ANIMATION_DURATION = 1.0  # seconds
const DRIFT_UP = 0.5  # Y drift (slightly up for visibility)
const DRIFT_BACKWARD = -2.0  # Z drift (opposite of note direction, so player can see)
const SCALE_START = Vector3(0.5, 0.5, 0.5)
const SCALE_END = Vector3.ZERO

# Colors
const COLOR_PERFECT = Color.GREEN
const COLOR_PARTIAL = Color.WHITE


func show_score(position: Vector3, score: int, is_perfect: bool):
	# Position at hit location
	global_position = position
	
	# Set text and color
	_label.text = str(score)
	_label.modulate = COLOR_PERFECT if is_perfect else COLOR_PARTIAL
	
	# Start scaled down
	_label.scale = SCALE_START
	
	# Calculate end position (drift up and backward so player can see)
	var end_pos = _label.position + Vector3(
		randf_range(-0.3, 0.3),  # slight random X offset
		DRIFT_UP,
		DRIFT_BACKWARD
	)
	
	# Create animation tween
	var tween = create_tween().set_parallel(true)
	
	# Scale up quickly, then down
	tween.tween_property(_label, "scale", Vector3.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# Position drift
	tween.tween_property(_label, "position", end_pos, ANIMATION_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# Fade out alpha
	tween.tween_property(_label, "modulate:a", 0.0, ANIMATION_DURATION)
	
	# Scale down after initial pop (delayed)
	tween.tween_property(_label, "scale", SCALE_END, 0.5).set_delay(ANIMATION_DURATION - 0.5)
	
	# Clean up when done
	tween.chain().tween_callback(queue_free)
