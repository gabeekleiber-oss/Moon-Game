extends Node
var failures := 0
func check(ok: bool, label: String) -> void:
	print(("PASS " if ok else "FAIL ") + label)
	if not ok:
		failures += 1

func _ready() -> void:
	var act: Node3D = (load("res://scenes/acts/act01_wisconsin/act01_wisconsin.tscn") as PackedScene).instantiate()
	add_child(act)
	await get_tree().process_frame
	var story: Node3D = act.get_node("Act01Story")
	var player: Node3D = act.get_node("Player")
	var bedroom: Node3D = act.get_node("RoomBuilder/wi_marysue_room") as Node3D
	check(bedroom.position.x == 12.0, "Mary Sue bedroom does not overlap living room")
	check(act.beats.count() == 12, "all twelve canonical Act 1 beats registered")
	check(story.get_node("Story_intruder").enabled, "intruder interaction available on start")
	check(not story.get_node("Story_tv_hit_1").enabled, "television cannot be struck before broom")
	for id in ["intruder", "finger", "letter", "shoo", "kitchen_items"]:
		story.call("_interact", id, player)
		check(act.beats.is_done(id), "story interaction completes " + id)
	check(not act.beats.is_done("broom"), "broom must be physically picked up")
	story.call("_interact", "stairs", player)
	check(player.global_position.x > 12.0, "stair portal reaches Mary Sue's bedroom")
	story.call("_interact", "downstairs", player)
	check(player.global_position.x < 9.0, "return portal reaches the entry hall")
	var broom: Carryable = act.get_node("StoryCarryProps/Broom") as Carryable
	broom.use(player)
	check(broom.held and act.beats.is_done("broom"), "real carry pickup completes broom beat")
	story.call("_interact", "tv_hit_1", player)
	story.call("_interact", "tv_hit_2", player)
	check(act.beats.is_done("tv_hit_2"), "two separate TV blows complete in order")
	for id in ["quit_call", "phone_throw", "tank_throw", "family_loaded"]:
		story.call("_interact", id, player)
		check(act.beats.is_done(id), "story interaction completes " + id)
	check(act.beats.all_done() and Acts.is_unlocked(2), "Act 1 finishes and unlocks Act 2")
	check(story.get_node("Story_family_loaded").enabled, "Taurus remains interactable for departure")
	var controller: CarryController = player.get_node("Head/Camera3D/CarryController") as CarryController
	controller.drop_item()
	print("RESULT: ALL PASS" if failures == 0 else "RESULT: %d FAILED" % failures)
	get_tree().quit(failures)
