extends Label

var value = 0
var updating = false

#var prefix = "SCORE: "
var prefix = "x"

func _ready():
	#move to main
	text = prefix + String(value)
	Events.connect("current_combo_updated", self, "_on_current_combo_updated")

func _on_current_combo_updated(new_combo):
	value = new_combo
	print ("updating combo:", value)

	text = prefix + String(int(value))
