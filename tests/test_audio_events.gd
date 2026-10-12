extends Node
## Headless test for Audio ducking, pause muffling and event reactions. Run: godot --headless --path . res://tests/test_audio_events.tscn
var _fails := 0

func _check(cond: bool, what: String) -> void:
	print(("PASS " if cond else "FAIL ") + what)
	if not cond:
		_fails += 1

func _busy() -> int:
	var n := 0
	for p in Audio._pool:
		if p.playing:
			n += 1
	return n

func _quiet() -> void:
	for p in Audio._pool:
		p.stop()

func _ready() -> void:
	# ducking
	_check(Audio.duck_target_db() == 0.0 and is_zero_approx(Audio.duck_applied_db()), "not ducked at start")
	Events.dialogue_started.emit("x")
	_check(is_equal_approx(Audio.duck_target_db(), Audio.DIALOGUE_DUCK_DB), "dialogue_started ducks Music/Amb")
	await get_tree().create_timer(0.5).timeout
	_check(absf(Audio.duck_applied_db() - Audio.DIALOGUE_DUCK_DB) < 0.5, "duck is fully applied after the fade")
	Events.dialogue_ended.emit("x")
	await get_tree().create_timer(0.9).timeout
	_check(absf(Audio.duck_applied_db()) < 0.5 and Audio.duck_target_db() == 0.0, "dialogue_ended restores full level")
	Audio.duck(5.0)
	_check(Audio.duck_target_db() == 0.0, "duck never boosts (positive db clamped to 0)")
	Audio.unduck(0.05)

	# pause muffle
	Events.game_paused.emit(true)
	_check(Audio._lowpasses.size() == 2 and Audio._lowpasses[0].cutoff_hz == Audio.CUTOFF_PAUSED, "pausing muffles Music and Amb")
	Events.game_paused.emit(false)
	_check(Audio._lowpasses[1].cutoff_hz == Audio.CUTOFF_OPEN, "unpausing restores the filter")

	# event reactions
	_quiet()
	Events.unreality_spiked.emit(0.2, "t")
	_check(_busy() == 1, "a big unreality spike plays a low sting")
	Events.unreality_spiked.emit(0.2, "t")
	_check(_busy() == 1, "spike stings are rate-limited (400 ms)")
	Audio._last_ms.clear()   # headless timers run faster than the wall clock the limiter uses, so reset it explicitly
	_quiet()
	Events.unreality_spiked.emit(0.01, "t")
	_check(_busy() == 0, "a tiny spike is silent")
	Events.interacted.emit(null)
	_check(_busy() == 1, "interact plays a click")

	# chapter start resets reverb
	Audio.set_reverb("cave")
	Events.act_started.emit(3)
	_check(Audio.reverb_preset() == "none", "act_started resets reverb to none")

	print("RESULT: ALL PASS" if _fails == 0 else "RESULT: %d FAILED" % _fails)
	get_tree().quit(_fails)
