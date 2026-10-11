extends Node
## Headless test for Synth + SfxRecipes. Run: godot --headless --path . res://tests/test_audio_synth.tscn
var _fails := 0

func _check(cond: bool, what: String) -> void:
	print(("PASS " if cond else "FAIL ") + what)
	if not cond:
		_fails += 1

func _ready() -> void:
	var t := Synth.tone(440, 0.5)
	_check(t.size() == int(0.5 * Synth.RATE), "tone length = duration * rate")
	_check(Synth.peak(t) > 0.1 and Synth.peak(t) <= 0.5, "tone peak within volume")
	_check(absf(t[t.size() - 1]) < 0.01, "tone fades to silence")
	_check(Synth.tone(440, 0.1) == Synth.tone(440, 0.1), "tone is deterministic")
	_check(Synth.noise(0.1) == Synth.noise(0.1), "noise is deterministic (fixed seed)")
	_check(Synth.noise(0.1, 0.4, 0.0, 1.0, 0.0, 1) != Synth.noise(0.1, 0.4, 0.0, 1.0, 0.0, 2), "different seeds give different noise")
	var m := Synth.mix(Synth.tone(440, 0.1), Synth.tone(440, 0.1), 0.2)
	_check(is_equal_approx(Synth.duration(m), 0.3), "mix extends to cover the offset buffer")
	_check(Synth.scaled(t, 0.5).size() == t.size() and absf(Synth.scaled(t, 0.5)[100] - t[100] * 0.5) < 0.0001, "scaled halves samples")
	var w := Synth.to_stream(t)
	_check(w.mix_rate == Synth.RATE and w.format == AudioStreamWAV.FORMAT_16_BITS and w.data.size() == t.size() * 2, "to_stream makes 16-bit mono WAV")
	_check(Synth.to_stream(t, true).loop_mode == AudioStreamWAV.LOOP_FORWARD, "loop flag sets loop mode")
	for kind in ["sine", "triangle", "square", "saw"]:
		var b := Synth.tone(200, 0.05, kind, 0.5, 0.0, 0.0)
		_check(Synth.peak(b) > 0.3 and Synth.peak(b) <= 0.5001, "waveform '%s' is audible and bounded" % kind)

	var bad: Array[String] = []
	var loud: Array[String] = []
	var long: Array[String] = []
	for n in SfxRecipes.NAMES:
		var s := SfxRecipes.get_stream(n)
		if s == null or s.data.size() < 100:
			bad.append(n)
			continue
		var buf := SfxRecipes._build(n)
		if Synth.peak(buf) < 0.05 or Synth.peak(buf) > 1.0:
			loud.append(n)
		if Synth.duration(buf) > 1.5:
			long.append(n)
	_check(bad.is_empty(), "every recipe builds a stream %s" % [bad])
	_check(loud.is_empty(), "every recipe is audible and unclipped (peak 0.05..1.0) %s" % [loud])
	_check(long.is_empty(), "every recipe is under 1.5 s %s" % [long])
	_check(SfxRecipes.get_stream("click") == SfxRecipes.get_stream("click"), "streams are cached")
	_check(SfxRecipes.has("pickup") and not SfxRecipes.has("nope"), "has() works")

	print("RESULT: ALL PASS" if _fails == 0 else "RESULT: %d FAILED" % _fails)
	get_tree().quit(_fails)
