extends Label

var time = 0
#TODO format correctly with mm:ss

func _ready():
	#move to main
	format_time()
	set_process(false)
	Events.connect("song_begin", self, "_on_song_begin")
	Events.connect("song_end", self, "_on_song_end")

func _on_song_begin():
	set_process(true)
func _on_song_end():
	set_process(false)

func _process(delta):
	var ts = Engine.time_scale
	var d = delta * (1.0/Engine.time_scale)
	time = time + d
	format_time()

func format_time():
	var minutes = int(time / 60)
	var seconds = time - minutes*60
	var miliseconds = (seconds - int(seconds))*100

	var output_string = "%02d:%02d:%02d"
	text = output_string % [minutes, seconds, miliseconds]
