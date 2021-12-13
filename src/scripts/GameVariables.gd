extends Node

const UI_PIXELS_TO_METER = 1.0 / 512

# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
var ENABLE_VR = true

# Don't edit
export var vr_enabled = false


## In game variables

# The path os the song to play
var path = null
# The difficulty to load
var difficulty = null

# Defalt location of songs
var songs_path = null
var song_selected = null


# Enable or disable to let non-vr mode move with up/right/left/down keys
var NON_VR_MOVEMENT = false
