extends Node

const SynthScript = preload("res://scenes/audio/synth.gd")
const SfxRecipesScript = preload("res://scenes/audio/sfx_recipes.gd")
## Headless test for Synth + SfxRecipesScript. Run: godot --headless --path . res://tests/test_audio_synth.tscn
var _fails := 0

func _check(cond: bool, what: String) -> void:
	print(("PASS " if cond else "FAIL ") + what)
	if not cond:
		_fails += 1

func _ready() -> void:
	var t := SynthScript.tone(440, 0.5)
	_check(t.size() == int(0.5 * SynthScript.RATE), "tone length = duration * rate")
	_check(SynthScript.peak(t) > 0.1 and SynthScript.peak(t) <= 0.5, "tone peak within volume")
	_check(absf(t[t.size() - 1]) < 0.01, "tone fades to silence")
	_check(SynthScript.tone(440, 0.1) == SynthScript.tone(440, 0.1), "tone is deterministic")
	_check(SynthScript.noise(0.1) == SynthScript.noise(0.1), "noise is deterministic (fixed seed)")
	_check(SynthScript.noise(0.1, 0.4, 0.0, 1.0, 0.0, 1) != SynthScript.noise(0.1, 0.4, 0.0, 1.0, 0.0, 2), "different seeds give different noise")
	var m := SynthScript.mix(SynthScript.tone(440, 0.1), SynthScript.tone(440, 0.1), 0.2)
	_check(is_equal_approx(SynthScript.duration(m), 0.3), "mix extends to cover the offset buffer")
	_check(SynthScript.scaled(t, 0.5).size() == t.size() and absf(SynthScript.scaled(t, 0.5)[100] - t[100] * 0.5) < 0.0001, "scaled halves samples")
	var w := SynthScript.to_stream(t)
	_check(w.mix_rate == SynthScript.RATE and w.format == AudioStreamWAV.FORMAT_16_BITS and w.data.size() == t.size() * 2, "to_stream makes 16-bit mono WAV")
	_check(SynthScript.to_stream(t, true).loop_mode == AudioStreamWAV.LOOP_FORWARD, "loop flag sets loop mode")
	for kind in ["sine", "triangle", "square", "saw"]:
		var b := SynthScript.tone(200, 0.05, kind, 0.5, 0.0, 0.0)
		_check(SynthScript.peak(b) > 0.3 and SynthScript.peak(b) <= 0.5001, "waveform '%s' is audible and bounded" % kind)

	var pulsed := Synth.pulsed(Synth.noise(1.0, 0.5, 0.0, 0.0), 4.0, 1.0)
	_check(pulsed.size() == Synth.noise(1.0).size() and absf(pulsed[0]) < 0.01 and Synth.peak(pulsed) > 0.2, "pulsed gates a buffer like syllables")
	_check(SfxRecipes.has("whisper") and Synth.peak(SfxRecipes._build("whisper")) < 0.6, "whisper recipe exists and is soft")
	var bad: Array[String] = []
	var loud: Array[String] = []
	var long: Array[String] = []
	for n in SfxRecipesScript.NAMES:
		var s := SfxRecipesScript.get_stream(n)
		if s == null or s.data.size() < 100:
			bad.append(n)
			continue
		var buf := SfxRecipesScript._build(n)
		if SynthScript.peak(buf) < 0.05 or SynthScript.peak(buf) > 1.0:
			loud.append(n)
		if SynthScript.duration(buf) > 1.5:
			long.append(n)
	_check(bad.is_empty(), "every recipe builds a stream %s" % [bad])
	_check(loud.is_empty(), "every recipe is audible and unclipped (peak 0.05..1.0) %s" % [loud])
	_check(long.is_empty(), "every recipe is under 1.5 s %s" % [long])
	_check(SfxRecipesScript.get_stream("click") == SfxRecipesScript.get_stream("click"), "streams are cached")
	_check(SfxRecipesScript.has("pickup") and not SfxRecipesScript.has("nope"), "has() works")

	print("RESULT: ALL PASS" if _fails == 0 else "RESULT: %d FAILED" % _fails)
	get_tree().quit(_fails)
