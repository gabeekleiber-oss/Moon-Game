extends Node
## Headless test for Instruments. Run: godot --headless --path . res://tests/test_instruments.tscn
var _fails := 0

func _check(cond: bool, what: String) -> void:
	print(("PASS " if cond else "FAIL ") + what)
	if not cond:
		_fails += 1

func _dur(w: AudioStreamWAV) -> float:
	return float(w.data.size() / 2) / float(w.mix_rate)

func _ready() -> void:
	_check(is_equal_approx(Instruments.midi_to_hz(69), 440.0) and is_equal_approx(Instruments.midi_to_hz(81), 880.0) and is_equal_approx(Instruments.midi_to_hz(60), 261.6256), "midi_to_hz (A4=440, octave doubles, middle C)")
	_check(absf(Instruments.midi_to_hz(69, 100.0) / 440.0 - pow(2.0, 100.0 / 1200.0)) < 0.0001, "detune cents bend the pitch")
	var bad: Array[String] = []
	for inst in Instruments.NAMES:
		var w := Instruments.stream(inst, 69, 0.5)
		if w == null or w.data.size() < 1000:
			bad.append(inst)
	_check(bad.is_empty(), "every instrument renders a note %s" % [bad])
	_check(_dur(Instruments.stream("music_box", 72, 0.1)) == _dur(Instruments.stream("music_box", 72, 2.0)), "music box length ignores the requested duration")
	_check(absf(_dur(Instruments.stream("pump_organ", 60, 0.9)) - 1.0) < 0.01, "organ duration rounds up to 0.25 s (0.9 -> 1.0)")
	_check(_dur(Instruments.stream("flute", 60, 99.0)) <= Instruments.MAX_HELD + 0.01, "held notes are capped at MAX_HELD")
	_check(Instruments.stream("pump_organ", 60, 0.9) == Instruments.stream("pump_organ", 60, 0.95), "same quantised note is cached once")
	_check(Instruments.stream("nope", 60) == Instruments.stream("music_box", 60), "unknown instrument falls back to the music box")
	var n0 := Instruments.cache_size()
	Instruments.stream("bell_pad", 64, 1.0, 35.0)
	Instruments.stream("bell_pad", 64, 1.0, 0.0)
	_check(Instruments.cache_size() == n0 + 2, "detuned and plain notes are cached separately")
	var peaks_ok := true
	for inst in Instruments.NAMES:
		var buf := Instruments._render(inst, 72, 1.0, 0.0)
		var p := Synth.peak(buf)
		peaks_ok = peaks_ok and p > 0.1 and p < 0.9
	_check(peaks_ok, "every instrument is audible and leaves headroom for mixing (peak 0.1..0.9)")
	var held := Synth.held(440.0, 1.0, "sine", 0.4, 0.1, 0.2)
	_check(absf(held[0]) < 0.01 and absf(held[held.size() - 1]) < 0.01 and Synth.peak(held) > 0.35, "Synth.held fades in and out around a sustained middle")
	var t0 := Time.get_ticks_msec()
	for m in range(48, 85):
		Instruments.stream("music_box", m)
	_check(Time.get_ticks_msec() - t0 < 4000, "37 music-box notes render in under 4 s (%d ms)" % (Time.get_ticks_msec() - t0))

	print("RESULT: ALL PASS" if _fails == 0 else "RESULT: %d FAILED" % _fails)
	get_tree().quit(_fails)
