extends Node
## Headless integration test for the Dialogue autoload + box. Run: godot --headless --path . res://tests/test_dialogue_flow.tscn

var _fails := 0
var _c := {"started": 0, "ended": 0, "lines": 0, "blips": 0, "choices": 0}


func _check(cond: bool, what: String) -> void:
	print(("PASS " if cond else "FAIL ") + what)
	if not cond:
		_fails += 1


func _ready() -> void:
	Game.flea = 10.0
	Game.flags.clear()
	Events.dialogue_started.connect(func(_i: String) -> void: _c["started"] += 1)
	Events.dialogue_ended.connect(func(_i: String) -> void: _c["ended"] += 1)
	Events.dialogue_line.connect(func(_w: String, _t: String) -> void: _c["lines"] += 1)
	Events.speaker_blip.connect(func(_w: String, _ch: String) -> void: _c["blips"] += 1)
	Events.dialogue_choice_made.connect(func(_i: int, _t: String) -> void: _c["choices"] += 1)

	var box: DialogueBox = Dialogue.get_child(0)
	_check(not Dialogue.is_active(), "not active before play")
	var done := [false, false]
	_run(done)
	await get_tree().process_frame
	_check(Dialogue.is_active() and _c["started"] == 1, "play() activates and emits dialogue_started")
	_check(not await _second_play(), "second play() while active is refused")

	# let line 'a' type for a bit so blips fire, then skip, advance
	await get_tree().create_timer(0.5).timeout
	_check(_c["blips"] > 5, "typing emitted speaker_blip (%d)" % _c["blips"])
	var guard := 0
	while Dialogue.is_active() and guard < 40:
		guard += 1
		await get_tree().create_timer(0.25).timeout   # clears the input guard
		if box.is_typing():
			box.skip_typing()
		elif not box._choices.is_empty():
			box.choice_selected.emit(1)                 # the rude choice
		else:
			box.advance_requested.emit()
	_check(done[0], "await Dialogue.play() resumed after the last line")
	_check(_c["ended"] == 1 and not Dialogue.is_active(), "dialogue_ended emitted once, inactive again")
	_check(_c["lines"] == 4, "4 lines shown: a, b, c, d (got %d)" % _c["lines"])
	_check(_c["choices"] == 1, "one choice recorded")
	_check(is_equal_approx(Game.flea, 13.0) and Game.has_flag("demoRude") and Game.hearts["self"] == 5, "choice effects applied via Game")
	var lg := Dialogue.log()
	_check(lg.size() == 5 and lg[2]["who"] == "you", "log has 4 lines + the pick")
	_check(not await Dialogue.play("does_not_exist"), "missing file returns false")

	print("RESULT: %s" % ("ALL PASS" if _fails == 0 else "%d FAILED" % _fails))
	get_tree().quit(0 if _fails == 0 else 1)


func _run(done: Array) -> void:
	done[0] = await Dialogue.play("_sample")


func _second_play() -> bool:
	return await Dialogue.play("_sample")
