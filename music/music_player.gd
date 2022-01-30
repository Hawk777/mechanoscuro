extends Node

const CUTOFF_DECIBELS := -80.0
const CUTOFF_LINEAR := db2linear(CUTOFF_DECIBELS)
const ZERO_LINEAR := db2linear(0.0)

export(float) var crossfade_time := 1.0

var _last_was_menu := true

onready var _fast := $Fast as AudioStreamPlayer
onready var _menu := $Menu as AudioStreamPlayer
onready var _panic := $Panic as AudioStreamPlayer
onready var _slow := $Slow as AudioStreamPlayer
onready var _in_game := [_fast, _panic, _slow]


func _process(delta: float) -> void:
	var player := get_tree().get_nodes_in_group("player").pop_back() as Player
	if player == null:
		_process_for_menu(delta, not _last_was_menu)
		_last_was_menu = true
	else:
		var enemies = get_tree().get_nodes_in_group("enemies")
		_process_for_level(delta, player, enemies, _last_was_menu)
		_last_was_menu = false
	print_debug("menu=%f, slow=%f, fast=%f, panic=%f" % [_menu.volume_db, _slow.volume_db, _fast.volume_db, _panic.volume_db])


func _process_for_menu(delta: float, first: bool) -> void:
	# Fade out any leftover level music.
	var any_game_playing := false
	for i in _in_game:
		var clip := i as AudioStreamPlayer
		_fade_down(clip, delta, true)
		any_game_playing = any_game_playing or clip.playing

	# The menu music will be played from a fresh start. Prepare it.
	if first:
		if _menu.playing:
			_menu.stop()
		_menu.volume_db = 0.0

	# Once the level music is gone, play the menu music.
	if not any_game_playing and not _menu.playing:
		_menu.play()


func _process_for_level(delta: float, player: Player, enemies: Array, _first: bool) -> void:
	# Fade out any leftover menu music. Don’t start anything else until that’s done.
	_fade_down(_menu, delta, true)
	if not _menu.playing:
		# Decide which clip should be playing.
		var any_chasing := false
		for i in get_tree().get_nodes_in_group("enemies"):
			var en := i as enemy
			any_chasing = any_chasing or en.mode == enemy.CHASING
		var target_clip: AudioStreamPlayer
		if any_chasing:
			target_clip = _panic
		elif player.get_tile().isLit or player.get_tile().lamped:
			target_clip = _fast
		else:
			target_clip = _slow

		# Check if the in-game clips are playing yet.
		if _fast.playing:
			# The in-game clips are playing, so we just need to crossfade towards the target clip.
			var volume_step := delta / crossfade_time
			for i in _in_game:
				var clip := i as AudioStreamPlayer
				if clip == target_clip:
					clip.volume_db = linear2db(move_toward(db2linear(clip.volume_db), ZERO_LINEAR, volume_step))
				else:
					clip.volume_db = linear2db(move_toward(db2linear(clip.volume_db), CUTOFF_LINEAR, volume_step))
		else:
			# No clips are playing yet, which means we must have been fading out the menu music.
			# We need to get the proper initial clip playing, at full volume to start.
			for i in _in_game:
				var clip := i as AudioStreamPlayer
				clip.play()
				clip.volume_db = CUTOFF_DECIBELS
			target_clip.volume_db = 0.0


func _fade_down(clip: AudioStreamPlayer, delta_time: float, stop: bool) -> void:
	if clip.playing:
		clip.volume_db = linear2db(move_toward(db2linear(clip.volume_db), CUTOFF_LINEAR, delta_time / crossfade_time))
		if stop and is_equal_approx(clip.volume_db, CUTOFF_DECIBELS):
			clip.stop()
