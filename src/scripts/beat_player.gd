extends AudioStreamPlayer
class_name BeatPlayer
# # brief
# beatplayer is simple stream player for rhythm games which wraps AudioStreamPlayer.
#
# - interpolated offset with process() → don't manually enable or disable processing.
# - knowledge of bpm and beat
# - supports minus playback offset

var song_position: float: get = get_song_position, set = set_song_position
var _playback_position_last_known: float = 0
var _playback_position_interpolated: float = 0 # interpolated offset by physics_process or process

@export var bpm: float = 100.0 # this can be set anytime since this value dosesn't affect other variables

@export var offset: float = 0.0 # beat calculation offset in second. does not affect to playback position
var _beat: float: get = get_beat, set = set_beat # calculated value!

@export var lerp_val: float = 0.5
@export var pop_filter: float = 0.8

#CUSTOM
@export var beat_subdivisions := 0.25
var last_beat:float = 0.0

signal beat
signal reset

##################
# setter, getter #
##################

func set_beat(beat_pos: float):
	var beat_per_second: float = ((bpm) / 60.0)
	self.song_position = beat_pos / beat_per_second
func get_beat():
	var beat_per_second: float = ((bpm) / 60.0)
	return (self.song_position) * beat_per_second

# this doesn't set seek
func set_song_position(playback_pos: float) -> void:
	_playback_position_last_known = playback_pos
	_playback_position_interpolated = playback_pos
	
func get_song_position() -> float: return _playback_position_interpolated

############
# utillity #
############

func beat_to_playback(beat_val: float) -> float:
	var beat_per_second: float = (bpm / 60.0)
	return beat_val / beat_per_second
	
func playback_to_beat(playback_pos: float) -> float:
	var beat_per_second: float = (bpm / 60.0)
	return (playback_pos) * beat_per_second

##################################
# overrides of AudioStreamPlayer #
##################################

func play_absolute(from_position: float = 0.0) -> void:
	play_music(from_position - offset)

func play_music(from_position: float = 0.0):
	if self.stream == null:
		return
		
	#_prevent_loop()
	
	last_beat = playback_to_beat(from_position)
	emit_signal("reset",last_beat)
	
	self.song_position = from_position
	if from_position + offset >= 0.0:
		super.play(from_position + offset)
	set_process(true)

func seek_music(to_position: float) -> void:
	self.song_position = to_position
	last_beat = playback_to_beat(to_position)
	emit_signal("reset",last_beat)
	if to_position + offset < 0.0:
		set_process(true)
		super.stop()
	else:
		super.seek(to_position + offset)

func seek_to_beat(beat_target: float) -> void:
	set_beat(beat_target) # this calls setter and changes playback_position
	self.last_beat = beat_target
	emit_signal("reset",last_beat)
	self.seek_music(self.song_position)
	
func stop_music() -> void:
	super.stop()
	last_beat=0
	emit_signal("reset",last_beat)
	set_process(false)
	
#####################
# overrides of Node #
#####################

func _ready() -> void:
	await owner.ready
	var error: int = connect("finished", Callable(self, "__finished_beatplayer"))
	if error != OK:
		print_debug(error)
	
	#set_process(true) # it seems like AudioStreamPlayer automatically sets processing to true

func _process(delta: float) -> void:
	if !stream_paused:
		_interpolate_playback_position(delta)
		beat_pulse()
	# Removed flooding print_debug message when paused

###############
# own methods #
###############

func beat_pulse():

	var beat_pulse_val = int(get_beat())
	#print (beat_pulse)
	if beat_pulse_val>last_beat:
		last_beat=beat_pulse_val
		# Removed flooding print message - beat signal still emitted
		emit_signal("beat", last_beat)


func _interpolate_playback_position(delta: float) -> void:
	# update new virtual playback position
	_playback_position_interpolated += delta
	
	if not _playback_position_interpolated < 0.0:
		# if processing but not playing, play it
		if not playing:
			super.play(0)
			return

		# if actual playback pos is changed, apply it
		var super_pos: float = super.get_playback_position() - offset
		if super_pos != _playback_position_last_known and super_pos != 0.0: # 0.0 when started. we ignore that
			_playback_position_last_known = super_pos
			
			# when popped up value occured
			if pop_filter != 0.0 and abs(_playback_position_interpolated - super_pos) > pop_filter:
				return
			
			# update _playback_position_interpolated by [lerp or not]
			if lerp_val != 0.0:
				var lerp_pos: float = lerp(super_pos, _playback_position_interpolated, pow(lerp_val, delta))
				_playback_position_interpolated = lerp_pos
			else:
				_playback_position_interpolated = super_pos

func __finished_beatplayer() -> void:
	self.song_position = super.get_playback_position()
	set_process(false)
	
func _prevent_loop():
	var stream_obj = stream
	if stream_obj is AudioStreamOggVorbis:
		var stream_ogg: AudioStreamOggVorbis = stream_obj as AudioStreamOggVorbis
		if stream_ogg != null: stream_ogg.loop = false
	
	if stream_obj is AudioStreamWAV:
		var stream_sample: AudioStreamWAV = stream_obj as AudioStreamWAV
		if stream_sample != null: stream_sample.loop_mode = AudioStreamWAV.LOOP_DISABLED
