extends Node

const SfxRecipesScript = preload("res://scenes/audio/sfx_recipes.gd")
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
	var first_spike_ms: int = int(Audio._last_ms.get("spike", -1))
	Events.unreality_spiked.emit(0.2, "t")
	_check(int(Audio._last_ms.get("spike", -2)) == first_spike_ms, "spike stings are rate-limited (400 ms)")
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

	# unreality: whispers and doubled voices
	_check(Audio.whisper_interval(0.1) == INF and Audio.whisper_interval(0.24) == INF, "no whispers below unreality 0.25")
	_check(Audio.whisper_interval(0.3) < 70.0 and Audio.whisper_interval(1.0) == 18.0 and Audio.whisper_interval(0.9) < Audio.whisper_interval(0.4), "whispers come faster as unreality rises")
	Events.unreality_changed.emit(0.7, 0.1, "t")
	_check(is_equal_approx(Audio.unreality(), 0.7), "unreality_changed reaches Audio")
	_quiet()
	var w := Audio.whisper_now()
	_check(w != null and w.bus == &"Voice" and w.volume_db < -20.0, "whisper_now plays very quietly on the Voice bus")
	Audio._blip_double.stop()
	Audio._blip_who = ""
	Events.speaker_blip.emit("elsa_ray", "H")
	Events.speaker_blip.emit("elsa_ray", "e")
	_check(Audio._blip_double.playing and Audio._blip_double.pitch_scale < Audio._blip_player.pitch_scale and Audio._blip_double.volume_db < Audio._blip_player.volume_db, "at unreality 0.7 each blip gets a quieter, flatter double")
	Events.unreality_changed.emit(0.2, -0.5, "t")
	Audio._blip_double.stop()
	Events.speaker_blip.emit("elsa_ray", "l")
	Events.speaker_blip.emit("elsa_ray", "l")
	_check(not Audio._blip_double.playing, "no voice double at low unreality")
	Audio._whisper_left = 0.0
	Events.unreality_changed.emit(0.9, 0.7, "t")
	_quiet()
	Audio._process(0.1)
	var whispered := false
	for pl in Audio._pool:
		whispered = whispered or pl.stream == SfxRecipesScript.get_stream("whisper")
	_check(whispered and Audio._whisper_left > 5.0, "the whisper timer fires and reschedules")
	Events.unreality_changed.emit(0.0, -0.9, "t")

	print("RESULT: ALL PASS" if _fails == 0 else "RESULT: %d FAILED" % _fails)
	get_tree().quit(_fails)
