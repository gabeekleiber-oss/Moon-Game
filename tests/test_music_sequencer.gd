extends Node
## Headless test for MusicSequencer. Run: godot --headless --path . res://tests/test_music_sequencer.tscn
var _fails := 0

func _check(cond: bool, what: String) -> void:
	print(("PASS " if cond else "FAIL ") + what)
	if not cond:
		_fails += 1

## Runs the sequencer for `seconds` in 1/60 s frames and returns every event.
func _run(seq: MusicSequencer, seconds: float) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var t := 0.0
	while t < seconds:
		out.append_array(seq.advance(1.0 / 60.0))
		t += 1.0 / 60.0
	return out

func _count(evs: Array[Dictionary], layer: String) -> int:
	var n := 0
	for e in evs:
		if e["layer"] == layer:
			n += 1
	return n

func _ready() -> void:
	var v := MusicScore.DEFAULT_VARIATION
	var seq := MusicSequencer.new(v)
	var first := seq.advance(0.0)
	var first_melody := first.filter(func(e: Dictionary) -> bool: return e["layer"] == "melody")
	_check(first_melody.size() == 1 and first_melody[0]["midi"] == 76 and _count(first, "bass") == 1, "first advance fires step 0 immediately (melody E5 + bass)")
	var bass_first := first.filter(func(e: Dictionary) -> bool: return e["layer"] == "bass")
	_check(bass_first.size() == 1 and bass_first[0]["midi"] == 45 and bass_first[0]["inst"] == "pump_organ", "bar 1 starts on the A2 bass played by the organ")
	_check(first.filter(func(e: Dictionary) -> bool: return e["layer"] == "melody")[0]["inst"] == "music_box", "default melody is the music box")
	_check(seq.advance(0.0).is_empty(), "no event is repeated on the next advance")

	# one full loop at 100 bpm: 96 steps * 0.3 s = 28.8 s
	var seq2 := MusicSequencer.new(v)
	var evs := _run(seq2, 28.8 - 0.05)
	var melody_notes := 0
	for bar in MusicScore.MELODY:
		melody_notes += bar.size()
	_check(_count(evs, "melody") == melody_notes, "one loop plays every melody note once (%d)" % melody_notes)
	_check(_count(evs, "bass") == 16, "one loop plays 16 bass notes (one per bar)")
	_check(_count(evs, "chord") == 16 * 2 * 3, "one loop plays 2 chord hits of 3 notes per bar")
	_check(_count(evs, "double") == 0, "no octave double at intensity 0")
	var steps_ok := true
	var last := -1
	for e in evs:
		steps_ok = steps_ok and e["step"] >= last
		last = e["step"]
	_check(steps_ok, "events come out in step order")
	var more := _run(seq2, 0.2)
	_check(seq2.loops_done() == 1 and _count(more, "melody") >= 1 and more[0]["midi"] == 76 + 0, "after a full loop the theme starts again")

	# hitch protection
	var seq3 := MusicSequencer.new(v)
	var big := seq3.advance(10.0)
	_check(seq3._next <= 4 and big.size() < 40, "a 10 s frame hitch only advances 0.25 s (no note flood)")

	# tempo
	var fast := MusicSequencer.new(MusicScore.variation("melting"))
	var slow := MusicSequencer.new(MusicScore.variation("moon"))
	_check(fast.step_seconds() < slow.step_seconds(), "melting is faster than moon")
	var s_a := MusicSequencer.new(v)
	var base_step := s_a.step_seconds()
	s_a.set_intensity(1.0)
	_check(is_equal_approx(s_a.step_seconds(), base_step / 1.3), "intensity 1 is 30% faster")
	s_a.set_intensity(7.0)
	_check(s_a.intensity == 1.0, "intensity is clamped to 1")

	# intensity layers
	var s_b := MusicSequencer.new(v)
	s_b.set_intensity(0.8)
	var evs_b := _run(s_b, 5.0)
	_check(_count(evs_b, "double") > 0 and evs_b.filter(func(e: Dictionary) -> bool: return e["layer"] == "double")[0]["midi"] == 88, "intensity >= 0.5 adds the octave double (E6)")
	_check(is_equal_approx(float(evs_b[0]["detune"]), 0.0), "intensity alone never detunes")
	var s_u := MusicSequencer.new(v)
	s_u.set_unreality(0.6)
	_check(is_equal_approx(float(s_u.advance(0.0)[0]["detune"]), 16.0), "unreality 0.6 is band 2: +16 cents")
	_check(MusicSequencer.band_for(0.0) == 0 and MusicSequencer.band_for(0.3) == 1 and MusicSequencer.band_for(0.74) == 2 and MusicSequencer.band_for(1.0) == 3 and MusicSequencer.band_for(-1.0) == 0, "bands step at 0.25 / 0.5 / 0.75 and clamp")
	var s_t := MusicSequencer.new(v)
	var t0 := s_t.step_seconds()
	s_t.set_unreality(1.0)
	_check(is_equal_approx(s_t.step_seconds(), t0), "unreality never changes the tempo")
	_check(is_equal_approx(float(MusicSequencer.new(v).loop_events(0.0, 0.8)[0]["detune"]), 24.0), "loop_events honours the unreality band (0.8 -> +24 cents)")
	var le0 := MusicSequencer.new(v).loop_events(0.0)
	var le1 := MusicSequencer.new(v).loop_events(0.9)
	_check(le0.size() == 45 + 16 + 96 and le1.size() == le0.size() + 45, "loop_events lists one loop (and the extra double layer at high intensity)")
	_check(is_equal_approx(float(le0[0]["dur"]), 0.9), "loop_events durations use the base tempo (3 steps * 0.3 s)")

	# variations: transpose, sparse, styles
	var tv := MusicSequencer.new(MusicScore.variation("tv_waltz")).advance(0.0)
	_check(tv.filter(func(e: Dictionary) -> bool: return e["layer"] == "melody")[0]["midi"] == 79, "tv_waltz is transposed up 3 semitones (E5 -> G5)")
	var full := _run(MusicSequencer.new(MusicScore.variation("candles")), 28.0)
	var thin := MusicSequencer.new(MusicScore.variation("dark_rooms"))
	var thin_evs := _run(thin, 30.0)
	_check(_count(thin_evs, "melody") < _count(full, "melody"), "sparse variation plays fewer melody notes")
	var thin2 := _run(MusicSequencer.new(MusicScore.variation("dark_rooms")), 30.0)
	_check(_count(thin2, "melody") == _count(thin_evs, "melody"), "sparseness is deterministic")
	var pad := _run(MusicSequencer.new(MusicScore.variation("night_drive")), 10.0)
	_check(_count(pad, "chord") > 0 and pad.filter(func(e: Dictionary) -> bool: return e["layer"] == "chord")[0]["dur"] > 1.5, "pad style holds chords for a whole bar")
	var none := _run(MusicSequencer.new(MusicScore.variation("lake")), 5.0)
	_check(_count(none, "chord") == 0 and _count(none, "bass") == 0, "accomp_style none plays no accompaniment")

	# silence (act 6, the lake: 60 s)
	var lake := MusicSequencer.new(MusicScore.variation_for_act(6))
	_check(is_equal_approx(lake.silence_left(), 60.0), "lake starts with 60 s of silence")
	var quiet := _run(lake, 59.0)
	_check(quiet.is_empty() and lake.silence_left() > 0.5, "no notes during the first 59 s")
	var after := _run(lake, 3.0)
	_check(not after.is_empty() and lake.silence_left() == 0.0, "music begins once the silence is over")
	var s_c := MusicSequencer.new(v)
	s_c.silence(2.0)
	_check(s_c.advance(0.1).is_empty() and is_equal_approx(s_c.silence_left(), 1.9), "silence(seconds) holds the music back")

	# dropouts (unreality >= 0.6); bass never drops, deterministic, none below 0.6
	_check(is_zero_approx(MusicSequencer.dropout_chance(0.5)) and is_zero_approx(MusicSequencer.dropout_chance(0.6)) and is_equal_approx(MusicSequencer.dropout_chance(1.0), 0.5), "dropout chance: 0 up to 0.6, 50% at 1.0")
	var calm := MusicSequencer.new(v)
	calm.set_unreality(0.55)
	var calm_evs := _run(calm, 20.0)
	var eerie := MusicSequencer.new(v)
	eerie.set_unreality(1.0)
	var eerie_evs := _run(eerie, 20.0)
	var eerie2 := MusicSequencer.new(v)
	eerie2.set_unreality(1.0)
	var eerie_evs2 := _run(eerie2, 20.0)
	_check(_count(eerie_evs, "melody") < _count(calm_evs, "melody") and _count(eerie_evs, "chord") < _count(calm_evs, "chord"), "high unreality drops melody and chord notes")
	_check(_count(eerie_evs, "bass") == _count(calm_evs, "bass"), "the bass never drops out")
	_check(eerie_evs.size() == eerie_evs2.size(), "dropouts are deterministic")
	_check(float(_count(eerie_evs, "melody")) > 0.3 * float(_count(calm_evs, "melody")), "enough melody survives to stay recognisable")

	# restart
	var s_d := MusicSequencer.new(v)
	_run(s_d, 5.0)
	s_d.restart()
	_check(s_d.advance(0.0).size() == first.size(), "restart() replays step 0")
	_check(s_d.bar() == 0 and s_d.loops_done() == 0, "bar()/loops_done() after restart")

	print("RESULT: ALL PASS" if _fails == 0 else "RESULT: %d FAILED" % _fails)
	get_tree().quit(_fails)
