extends WorldEnvironment

@export var strobe:bool = false

func _ready() -> void:
	await owner.ready
	if environment:
		change_environment(environment)

func change_environment(new_environment:Environment):
	print ("set environment called!")
	if new_environment:
		#$AnimationPlayer.stop()
		self.environment=new_environment

#func start_strobe(bpm:float):
#	print ("Environment Manager: attempting to start strobe")
#	if environment.fog_enabled and strobe:
#		print ("Environment Manager: successfully started strobe")
#		$AnimationPlayer.playback_speed = bpm/60.0
#		$AnimationPlayer.play("strobe")
#	else:
#		print ("Environment Manager: failed to start strobe")
#		$AnimationPlayer.play("_basis")
