extends Label

var time = 60*2

func _ready():
	#move to main
	text = String(stepify(time,0.1))
	#Events.connect("current_score_updated", self, "_on_current_score_updated")

func _process(delta):
	var ts = Engine.time_scale
	var d = delta * (1.0/Engine.time_scale)
	time = time - d
	text = String(stepify(time,0.1))
