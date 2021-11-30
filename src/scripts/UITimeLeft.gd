extends Label

var time = 0
var minutes_prefix = ""
var seconds_prefix = ""
#TODO format correctly with mm:ss

func _ready():
	#move to main
	text = String(stepify(time,0.1))
	#Events.connect("current_score_updated", self, "_on_current_score_updated")

func _process(delta):
	var ts = Engine.time_scale
	var d = delta * (1.0/Engine.time_scale)
	time = time + d
	
	var minutes = int(time / 60)
	var seconds = stepify(time-minutes,0.1)
	
	if minutes<10:
		minutes_prefix = "0"
	else:
		minutes_prefix = ""
	if seconds<10:
		seconds_prefix = "0"
	else:
		seconds_prefix = ""
	
	text = minutes_prefix + String(minutes) + ":" + seconds_prefix + String(seconds)
	#text = String(stepify(time,0.1))
