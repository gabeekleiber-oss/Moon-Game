extends Node
## Headless test for MusicScore data. Run: godot --headless --path . res://tests/test_music_score.tscn
var _fails := 0

func _check(cond: bool, what: String) -> void:
	print(("PASS " if cond else "FAIL ") + what)
	if not cond:
		_fails += 1

func _ready() -> void:
	_check(MusicScore.MELODY.size() == MusicScore.BARS and MusicScore.PROGRESSION.size() == MusicScore.BARS, "16 bars of melody and 16 chords")
	var bad_bars: Array[int] = []
	for i in MusicScore.MELODY.size():
		var total := 0
		for n in MusicScore.MELODY[i]:
			total += int(n[1])
		if total != MusicScore.STEPS_PER_BAR:
			bad_bars.append(i + 1)
	_check(bad_bars.is_empty(), "every melody bar adds up to 6 eighths %s" % [bad_bars])
	var in_range := true
	for bar in MusicScore.MELODY:
		for n in bar:
			in_range = in_range and (int(n[0]) == -1 or (int(n[0]) >= 55 and int(n[0]) <= 90))
	_check(in_range, "melody notes are in a singable/playable range (55..90)")
	var chords_ok := true
	for c in MusicScore.PROGRESSION:
		chords_ok = chords_ok and MusicScore.CHORDS.has(c) and (MusicScore.CHORDS[c]["triad"] as Array).size() == 3
	_check(chords_ok, "every progression chord exists with a 3-note triad")
	_check(MusicScore.MELODY[15] == [[69, 6]] and MusicScore.PROGRESSION[15] == "Am", "theme resolves to A over Am")

	var defaults_ok := true
	for k in MusicScore.VARIATIONS:
		var v := MusicScore.variation(k)
		for key in MusicScore.DEFAULT_VARIATION:
			defaults_ok = defaults_ok and v.has(key)
		defaults_ok = defaults_ok and Instruments.NAMES.has(v["melody"]) and Instruments.NAMES.has(v["accomp"])
		defaults_ok = defaults_ok and ["waltz", "pad", "none"].has(v["accomp_style"]) and int(v["bars"]) >= 1 and int(v["bars"]) <= 16
		defaults_ok = defaults_ok and float(v["bpm"]) >= 40.0 and float(v["bpm"]) <= 160.0 and float(v["sparse"]) >= 0.0 and float(v["sparse"]) <= 1.0
	_check(defaults_ok, "every variation is complete and uses real instruments, valid style, sane tempo")
	var all_ch := true
	for id in range(0, 12):
		all_ch = all_ch and MusicScore.CHAPTER_VARIATION.has(id) and MusicScore.VARIATIONS.has(MusicScore.CHAPTER_VARIATION[id])
	_check(all_ch, "title (0) and chapters 1-11 all map to a defined variation")
	_check(float(MusicScore.variation_for_chapter(8)["silent_first"]) == 60.0, "chapter 8 stays silent for its first 60 s (CHAPTERS.md)")
	_check(MusicScore.variation_for_chapter(99) == MusicScore.DEFAULT_VARIATION, "unknown chapter id gives the default treatment")
	_check(MusicScore.loop_steps(MusicScore.variation("moon")) == 48 and MusicScore.loop_steps(MusicScore.DEFAULT_VARIATION) == 96, "loop_steps = bars * 6")
	_check(is_equal_approx(MusicScore.step_seconds({"bpm": 120.0}), 0.25), "step_seconds at 120 bpm = 0.25 s")

	print("RESULT: ALL PASS" if _fails == 0 else "RESULT: %d FAILED" % _fails)
	get_tree().quit(_fails)
