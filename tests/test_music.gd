extends Node
## Headless test for the Music autoload. Run: godot --headless --path . res://tests/test_music.tscn
var _fails := 0

func _check(cond: bool, what: String) -> void:
	print(("PASS " if cond else "FAIL ") + what)
	if not cond:
		_fails += 1

## Waits (real time, background threads need it) until Music reaches a state; false on timeout.
func _wait_state(st: String, max_ms: int = 40000) -> bool:
	var t0 := Time.get_ticks_msec()
	while Music.state() != st:
		if Time.get_ticks_msec() - t0 > max_ms:
			return false
		OS.delay_msec(15)
		await get_tree().process_frame
	return true

func _sounding() -> int:
	var n := 0
	for p in Music._players:
		if p.playing:
			n += 1
	return n

func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame

func _ready() -> void:
	_check(Music.state() == "idle" and not Music.is_playing() and Music.current() == "", "idle at start")
	var bus := AudioServer.get_bus_index("Music")
	var has_fader := false
	for i in AudioServer.get_bus_effect_count(bus):
		has_fader = has_fader or AudioServer.get_bus_effect(bus, i) == Music._fader
	_check(has_fader and Music._players.size() == Music.VOICES and Music._players[0].bus == &"Music", "fader effect and voice pool are on the Music bus")

	Music.play("zzz_nope")
	_check(Music.state() == "idle" and Music.current() == "", "unknown variation is ignored")

	var t0 := Time.get_ticks_msec()
	Music.play("tv_waltz", 0.05)
	_check(Music.state() == "warming" and Music.current() == "tv_waltz", "play() starts by warming up notes in the background")
	var frame_ms_max := 0
	var ok := false
	var wall := Time.get_ticks_msec()
	while Music.state() == "warming" and Time.get_ticks_msec() - wall < 40000:
		var f0 := Time.get_ticks_msec()
		await get_tree().process_frame
		frame_ms_max = maxi(frame_ms_max, Time.get_ticks_msec() - f0)
		OS.delay_msec(5)
	ok = Music.state() == "playing"
	_check(ok, "warm-up finishes and playback starts (%d ms)" % (Time.get_ticks_msec() - t0))
	_check(frame_ms_max < 120, "main thread never blocks while warming (worst frame %d ms)" % frame_ms_max)
	await _frames(40)
	_check(_sounding() >= 2 and Music.is_playing(), "notes are sounding (%d voices)" % _sounding())
	var cached_before := Instruments.cache_size()
	await _frames(300)
	_check(Instruments.cache_size() == cached_before, "no new notes rendered while playing (all were pre-warmed)")

	# intensity (manual)
	Music.set_intensity(1.0)
	_check(is_equal_approx(Music.intensity(), 1.0) and is_equal_approx(Music._seq.intensity, 1.0), "set_intensity(1) reaches the sequencer")
	Music.set_intensity(-3.0)
	_check(is_equal_approx(Music.intensity(), 0.0), "intensity is clamped to 0..1")

	# unreality detune
	Events.unreality_changed.emit(0.6, 0.1, "t")
	_check(is_equal_approx(Music.unreality(), 0.6) and is_equal_approx(Music._seq.unreality, 0.6), "unreality_changed feeds the music")
	Events.unreality_changed.emit(0.1, -0.5, "t")
	_check(is_equal_approx(Music.unreality(), 0.1), "unreality can fall back")
	Music.unreality_drives_detune = false
	Events.unreality_changed.emit(0.9, 0.8, "t")
	_check(is_equal_approx(Music.unreality(), 0.1), "unreality_drives_detune=false is respected")
	Music.unreality_drives_detune = true

	# uncached note is skipped, not rendered synchronously
	var inst_n := Instruments.cache_size()
	Music._play_event({"inst": "flute", "midi": 33, "dur": 0.5, "detune": 0.0, "vol_db": 0.0})
	_check(Instruments.cache_size() == inst_n, "an unwarmed note is skipped instead of rendered on the main thread")

	# act hook + crossfade
	Events.act_started.emit(2)
	_check(Music.current() == "night_drive" and Music.state() == "fading_out", "act_started crossfades to the act's music")
	_check(await _wait_state("playing"), "new music begins after fade-out and warm-up")
	Music.auto_act = false
	Events.act_started.emit(4)
	_check(Music.current() == "night_drive", "auto_act=false ignores act_started")
	Music.auto_act = true
	var same := Music.state()
	Music.play("night_drive")
	_check(Music.state() == same, "playing the same variation again does nothing")

	# stop
	Music.stop(0.05)
	_check(Music.current() == "" and Music.state() == "fading_out", "stop() fades out")
	_check(await _wait_state("idle", 5000) and not Music.is_playing(), "stop() ends idle")

	# act 6 silence
	Music.play_act(6, 0.05)
	_check(await _wait_state("playing"), "act 6 starts (silently)")
	for p in Music._players:
		p.stop()
	await _frames(60)
	_check(_sounding() == 0 and Music._seq.silence_left() > 50.0, "act 6 plays no notes in its first 60 s")
	Music.stop(0.05)
	await _wait_state("idle", 5000)

	print("RESULT: ALL PASS" if _fails == 0 else "RESULT: %d FAILED" % _fails)
	get_tree().quit(_fails)
