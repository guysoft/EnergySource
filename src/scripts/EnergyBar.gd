extends ProgressBar

export var start_value = 0.0
export var lerp_amount = 0.1

var time_step = 0.01
var target_value = 0
var updating = false

func _ready():
	#move to main
	value = start_value
	Events.connect("current_energy_updated", self, "_on_current_energy_updated")

func _on_current_energy_updated(new_energy):
	target_value = new_energy
	print ("updating energy:", target_value)
	if updating:
		return
	updating = true
	while (not is_equal_approx(value, target_value)):
		value = int(lerp(value, target_value, lerp_amount))
		yield (get_tree().create_timer(time_step),"timeout")
	
	updating = false
