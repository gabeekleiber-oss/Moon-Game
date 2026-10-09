extends Node
## Headless test for F-01 data + runner. Run: godot --headless --path . res://tests/test_dialogue.tscn

var _fails := 0


func _check(cond: bool, what: String) -> void:
	print(("PASS " if cond else "FAIL ") + what)
	if not cond:
		_fails += 1


func _ready() -> void:
	Game.flea = 0.0
	Game.flags.clear()
	var good := DialogueData.from_dict({"id": "t", "start": "a", "nodes": {
		"a": {"who": "moon", "text": "Hello.", "next": "c", "cam": "wide", "sfx": "ding"},
		"c": {"who": "moon", "text": "Well?", "choices": [
			{"text": "Be rude", "goto": "x", "flea": 3, "heart": {"self": -1}, "set": "rudeToMoon"},
			{"text": "Be nice", "goto": "d", "flea": -2, "canon": true}]},
		"x": {"who": "moon", "text": "Ouch.", "next": "d"},
		"d": {"who": "moon", "text": "TODO_VERBATIM"}}})
	_check(good.is_valid(), "good dialogue validates (errors: %s)" % str(good.errors))
	_check(good.warnings.is_empty(), "good dialogue has no warnings (%s)" % str(good.warnings))
	_check(good.todo_verbatim_count == 1, "TODO_VERBATIM counted")

	var r := DialogueRunner.new()
	var cues: Array = []
	var shown: Array = []
	var done := [false]
	r.cue.connect(func(k: String, v: Variant) -> void: cues.append([k, v]))
	r.line_shown.connect(func(nid: String, _n: Dictionary) -> void: shown.append(nid))
	r.finished.connect(func(_id: String) -> void: done[0] = true)
	_check(r.start(good), "runner starts")
	_check(shown == ["a"] and cues.size() == 2, "line a shown with 2 cues")
	r.advance()
	_check(r.has_choices() and r.choices().size() == 2, "fork shown with 2 choices")
	r.advance()
	_check(shown == ["a", "c"], "advance() is ignored at a fork")
	r.choose(0)
	_check(is_equal_approx(Game.flea, 3.0), "choice flea applied")
	_check(Game.has_flag("rudeToMoon"), "choice flag set")
	_check(Game.hearts["self"] == 5, "choice heart applied")
	_check(r.current_id == "x", "followed goto to x")
	r.advance()
	_check(r.current_id == "d", "x funnels back to canon d")
	r.advance()
	_check(done[0] and not r.running, "finished after the last node")
	_check(r.log.size() == 5 and r.log[2]["who"] == "you", "log has lines + the player's pick")

	# funnel + structural validation
	var bad := DialogueData.from_dict({"id": "b", "start": "a", "nodes": {
		"a": {"text": "?", "choices": [
			{"text": "one", "goto": "p", "canon": true},
			{"text": "two", "goto": "q"}]},
		"p": {"text": "p", "next": "z"}, "q": {"text": "q", "next": "r"},
		"r": {"text": "r", "next": "s"}, "s": {"text": "s", "next": "t"}, "t": {"text": "t"}, "z": {"text": "z"}}})
	_check(bad.is_valid(), "funnel-violating dialogue still valid structurally")
	_check(bad.warnings.size() >= 1 and str(bad.warnings[0]).contains("funnel"), "funnel violation warned")
	var broken := DialogueData.from_dict({"id": "x", "start": "nope", "nodes": {"a": {"text": "hi", "next": "ghost"}}})
	_check(not broken.is_valid() and broken.errors.size() == 2, "missing start + missing next are errors")
	_check(not DialogueRunner.new().start(broken), "runner refuses invalid data")

	# log cap
	var many := {}
	for i in 20:
		many["n%d" % i] = {"text": "line %d" % i, "next": "n%d" % (i + 1)} if i < 19 else {"text": "last"}
	var rr := DialogueRunner.new()
	rr.start(DialogueData.from_dict({"id": "m", "start": "n0", "nodes": many}))
	for i in 25:
		rr.advance()
	_check(rr.log.size() == DialogueRunner.LOG_SIZE and rr.log[-1]["text"] == "last", "log keeps only the last 12 lines")

	# typewriter timing (spec: 38 cps, 180 ms after . ? !, 90 ms after commas)
	var t := Typewriter.reveal_times("Hi, you.")
	_check(is_equal_approx(t[1], 1.0 / 38.0), "second char appears after 1/38 s")
	_check(is_equal_approx(t[3] - t[2], 1.0 / 38.0 + 0.09), "comma adds 90 ms before the next char")
	var ok := Typewriter.reveal_times("Ok. Go")
	_check(is_equal_approx(ok[3] - ok[2], 1.0 / 38.0 + 0.18), "period adds 180 ms before the next char")
	var el := Typewriter.reveal_times("Wait... go")
	_check(is_equal_approx(el[5] - el[4], 1.0 / 38.0) and is_equal_approx(el[6] - el[5], 1.0 / 38.0) and is_equal_approx(el[7] - el[6], 1.0 / 38.0 + 0.18), "a run of dots pauses once, after the last")
	_check(Typewriter.visible_count(t, 0.0) == 1 and Typewriter.visible_count(t, 10.0) == 8, "visible_count bounds")

	print("RESULT: %s" % ("ALL PASS" if _fails == 0 else "%d FAILED" % _fails))
	get_tree().quit(0 if _fails == 0 else 1)
