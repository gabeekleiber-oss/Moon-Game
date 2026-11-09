extends Node
## ALT Act 1 departure: with auto_advance on, getting into the loaded Taurus must carry the player into Act 2.
var failures := 0
func check(ok: bool, label: String) -> void:
	print(("PASS " if ok else "FAIL ") + label)
	if not ok:
		failures += 1

func _ready() -> void:
	await Acts.go_to(1, true)
	var act: Act01 = Acts._current as Act01
	check(act != null, "Acts loaded the ALT Act 1 scene")
	check(act.auto_advance, "auto_advance is on for a real run")
	for id in ["intruder", "finger", "letter", "shoo", "kitchen_items", "broom", "tv_hit_1", "tv_hit_2", "quit_call", "phone_throw", "tank_throw"]:
		act.beat(id)
	check(not act.beats.all_done(), "Act 1 is not complete before boarding the Taurus")
	check(Acts.current_id == 1, "still in Act 1 before boarding")
	act.board_car()
	await get_tree().create_timer(4.5).timeout
	check(Acts.current_id == 2, "Taurus departure transitions to Act 2")
	print("RESULT: ALL PASS" if failures == 0 else "RESULT: %d FAILED" % failures)
	get_tree().quit(failures)
