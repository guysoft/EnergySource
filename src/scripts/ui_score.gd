extends Label

export var lerp_amount = 0.5

var time_step = 0.01
var target_value = 0
var value = 0
var updating = false

#var prefix = "SCORE: "
var prefix = ""

func _ready():
	#move to main
	text = prefix + String(value)
	Events.connect("current_score_updated", self, "_on_current_score_updated")

func _on_current_score_updated(new_score):
	target_value = new_score
	#print ("updating score:", target_value)
	if updating:
		return
	updating = true
	while (not is_equal_approx(value, target_value)):
		value = lerp(value, target_value, lerp_amount)
		var output_string = "%06d"
		text = output_string %[value]
		yield (get_tree().create_timer(time_step),"timeout")
	
	value = target_value
	
	var output_string = "%06d"
	text = output_string % [value]
	#String(int(value))
	
	updating = false
