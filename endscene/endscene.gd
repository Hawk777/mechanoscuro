extends Node2D

export(AudioStream) var switch_unpress
export(AudioStream) var monster_dealert
export(AudioStream) var monster_alert
export(AudioStream) var level_complete
export(AudioStream) var credit_sound
onready var _credits_player = get_node("EndCreditsPlayer") as AudioStreamPlayer
onready var _sound_player = get_node("SoundPlayer") as AudioStreamPlayer
var timer
var fadeTimer
var check # counts how many scenes have been shown, to time the credits properly
# Called when the node enters the scene tree for the first time.
func _ready():
	check=0
	timer = Timer.new()
	add_child(timer)
	timer.connect("timeout",self,"_on_Timer_timeout")
	timer.set_wait_time(1)
	timer.start()
	fadeTimer=Timer.new()
	add_child(fadeTimer)
	fadeTimer.connect("timeout",self,"_on_FadeTimer_timeout")
	fadeTimer.set_wait_time(0.5)
	_credits_player.stream=credit_sound
	_credits_player.play()


func _on_Timer_timeout():
	print("time")
	match (check):
		0:
			check+=1
			fadeTimer.start()
			timer.start(2)
			_sound_player.stream=switch_unpress
			_sound_player.play()
		1:
			check+=1
			fadeTimer.start()
			timer.set_wait_time(3)
			timer.start()
		2:
			check+=1
			fadeTimer.start()
			timer.set_wait_time(3)
			timer.start()
		3:
			check+=1
			fadeTimer.start()
			timer.set_wait_time(3)
			timer.start()
			_sound_player.stream=monster_dealert
			_sound_player.play()
		4:
			check+=1
			fadeTimer.start()
			timer.set_wait_time(3)
			timer.start()
			_sound_player.stream=monster_alert
			_sound_player.play()
		5:
			check+=1
			timer.set_wait_time(3)
			timer.start()
			_sound_player.stream=level_complete
			_sound_player.play()
		6:
			return
func _on_FadeTimer_timeout():
	print("fade")
	var currDark
	match (check):
		0:
			currDark = null
		1:
			currDark = get_node("Dark1")
		2:
			currDark = get_node("Dark2")
		3:
			currDark = get_node("Dark3")
		4:
			currDark = get_node("Dark4")
		5:
			currDark = get_node("Dark5")
		6:
			currDark = get_node("Dark6")
	currDark.modulate.a-=0.4
	fadeTimer.start()


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
