extends Label

var value = 0
var updating = false

#var prefix = "SCORE: "
var prefix = "x"

func _ready():
	#move to main
	text = prefix + str(value)
	Events.connect("current_combo_updated", Callable(self, "_on_current_combo_updated"))

func _on_current_combo_updated(new_combo):
	value = new_combo
	#print ("updating combo:", value)

	text = prefix + str(int(value))
