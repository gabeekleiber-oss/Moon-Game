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
	var gameplay_camera: Camera3D = player.get_node("Head/Camera3D") as Camera3D
	check(get_viewport().get_camera_3d() == gameplay_camera, "player camera is active instead of cutscene autoload camera")
	check(gameplay_camera.global_position.y < 2.35, "first-person camera starts below Wisconsin ceiling")
	check(not (player.get_node("MeshInstance3D") as MeshInstance3D).visible, "player body mesh cannot occlude first-person view")
	var bedroom: Node3D = act.get_node("RoomBuilder/wi_marysue_room") as Node3D
	check(bedroom.position.x == 12.0, "Mary Sue bedroom does not overlap living room")
	check(act.beats.count() == 12, "all twelve canonical Act 1 beats registered")
	check(story.get_node("Story_intruder").enabled, "intruder interaction available on start")
	var camera: Camera3D = player.get_node("Head/Camera3D") as Camera3D
	var ray: InteractionRay = null
	for child in camera.get_children():
		if child is InteractionRay:
			ray = child
	ray.require_captured_mouse = false
	player.position = Vector3(2.5, 0.2, 3.5)
	camera.look_at((story.get_node("Story_intruder") as Node3D).global_position, Vector3.UP)
	ray.force_raycast_update()
	check(ray.call("_find_target") == story.get_node("Story_intruder"), "player can aim at and interact with the opening intruder")
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
	check(story.get_node("Story_downstairs").enabled, "player can leave the bedroom after throwing the tank")
	check(story.get_node("Story_outside").enabled, "front door opens the route to the driveway")
	check(story.get_node("Story_family_loaded").enabled, "Taurus remains interactable for departure")
	var controller: CarryController = player.get_node("Head/Camera3D/CarryController") as CarryController
	controller.drop_item()
	print("RESULT: ALL PASS" if failures == 0 else "RESULT: %d FAILED" % failures)
	get_tree().quit(failures)
