extends Node
var failures := 0
func check(ok: bool, label: String) -> void:
	print(("PASS " if ok else "FAIL ") + label)
	if not ok:
		failures += 1

func _ready() -> void:
	await Acts.go_to(1, true)
	var act: Node3D = Acts._current as Node3D
	var story: Node3D = act.get_node("Act01Story")
	var player: Node3D = act.get_node("Player")
	for id in ["intruder", "finger", "letter", "shoo", "kitchen_items"]:
		story.call("_interact", id, player)
	var broom: Carryable = act.get_node("StoryCarryProps/Broom") as Carryable
	broom.use(player)
	for id in ["tv_hit_1", "tv_hit_2", "quit_call", "phone_throw", "tank_throw", "family_loaded"]:
		story.call("_interact", id, player)
	check(act.beats.all_done(), "Act 1 completes before departure")
	story.call("_interact", "family_loaded", player)
	await get_tree().create_timer(3.6).timeout
	check(Acts.current_id == 2, "Taurus departure transitions to Act 2")
	print("RESULT: ALL PASS" if failures == 0 else "RESULT: %d FAILED" % failures)
	get_tree().quit(failures)
