extends Label

export var lerp_amount = 0.1

var step = 0.01
var target_value = 0
var value = 0
var updating = false

func _ready():
	#move to main
	text = "SCORE: " + String(value)
	Events.connect("current_score_updated", self, "_on_current_score_updated")

func _on_current_score_updated(new_score):
	target_value = new_score
	print ("updating score:", target_value)
	if updating:
		return
	updating = true
	while (not is_equal_approx(value, target_value)):
		value = int(lerp(value, target_value, lerp_amount))
		text = "SCORE: " + String(value)
		yield (get_tree().create_timer(step),"timeout")
	
	updating = false
