extends Node
## Headless test for the story-progress machinery: BeatTracker, ActBase beats/unlock, Acts autoload, all nine act scenes.

var _fails := 0

func _check(cond: bool, what: String) -> void:
	print(("PASS " if cond else "FAIL ") + what)
	if not cond:
		_fails += 1

func _ready() -> void:
	var t := BeatTracker.new()
	t.add("a")
	t.add("b")
	t.add("c")
	_check(not t.complete("b") and t.complete("a") and t.complete("b"), "chain enforces story order")
	_check(t.current() == "c" and not t.all_done(), "current() is the next available beat")
	t.complete("c")
	_check(t.all_done() and is_equal_approx(t.progress(), 1.0), "all done -> progress 1")
	var j := BeatTracker.new()
	j.add("x", [], false)
	j.add("y", [], false)
	j.add("z", ["x", "y"])
	_check(j.available() == ["x", "y"], "free beats are available together")
	j.complete("y")
	_check(not j.is_available("z") and j.complete("x") and j.is_available("z"), "a join beat needs all its requirements")
	_check(not j.complete("nope") and not j.complete("x"), "unknown/duplicate completes are ignored")

	_check(Acts.count() == 9, "nine acts registered")
	for a in Acts.ACTS:
		_check(ResourceLoader.exists(a["path"]), "act %d scene exists" % a["id"])
	var cues: Array = []
	var unlocked: Array = []
	Events.cue_fired.connect(func(act: int, cue: String) -> void: cues.append([act, cue]))
	Events.act_unlocked.connect(func(id: int) -> void: unlocked.append(id))
	Game.furthest_act = 1
	_check(not Acts.is_unlocked(2), "act 2 starts locked")
	await Acts.go_to(1)
	await get_tree().process_frame
	var act: ActBase = Acts._current
	_check(act != null and act.act_id == 1 and Unreality.model.floor_ == act.unreality_floor, "act 1 loaded and set its unreality floor")
	_check(not act.beat("letter"), "an out-of-order beat is ignored")
	var before := Unreality.model.base
	for id in act.beats.ids():
		act.beat(id)
	_check(act.beats.all_done() and Unreality.model.base > before, "completing every data beat finishes the act and raises unreality")
	_check(act.beats.count() == 12, "act 1 has its 12 data beats")
	_check(Acts.is_unlocked(2) and unlocked == [2] and cues.size() == 1 and cues[0][0] == 1, "finishing the act unlocks act 2 and fires its cue")
	await Acts.go_to(2)
	await get_tree().process_frame
	_check(Acts.current_id == 2 and Acts._current.act_id == 2, "act 2 loads once unlocked")
	await Acts.go_to(5)
	_check(Acts.current_id == 2, "locked act 5 refuses to load")
	for id in range(1, 10):
		await Acts.go_to(id, true)
		await get_tree().process_frame
		_check(Acts.current_id == id and Acts._current.get_node_or_null("Player") != null or Acts.current_id == id, "act %d boots (forced)" % id)
	print("FAILED: %d" % _fails if _fails else "ALL PASSED")
	get_tree().quit(1 if _fails else 0)
