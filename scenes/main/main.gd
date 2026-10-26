extends Node
## Entry. Starts Act 1 (a title screen is a task in docs/TASKS.md), or jumps to the act given via `-- --act=N`
## (optionally `--unreality=0.6` to start at that hidden level).

func _ready() -> void:
	var start := 1
	var level := -1.0
	var quality_override := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--act="):
			start = int(arg.get_slice("=", 1))
		elif arg.begins_with("--quality="):
			quality_override = arg.get_slice("=", 1)
		elif arg.begins_with("--unreality="):
			level = float(arg.get_slice("=", 1))
	if quality_override in ["auto", "high", "medium", "low"]:
		Game.settings["quality"] = quality_override
		GameSettings.apply("quality")
	await Acts.go_to(start, true)
	if OS.get_cmdline_user_args().has("--verify-export"):
		await get_tree().process_frame
		var rooms := Acts._current.get_node_or_null("RoomBuilder")
		var player := Acts._current.get_node_or_null("Player")
		var ok: bool = rooms != null and rooms.get_child_count() >= 5 and player != null and not player.call("_locked") and not get_tree().paused and player.global_position.x > 1.0 and player.global_position.x < 5.0
		var before: Vector3 = player.global_position
		Input.action_press("move_forward")
		for frame in 18:
			await get_tree().physics_frame
		Input.action_release("move_forward")
		var moved: bool = player.global_position.distance_to(before) > 0.15
		print("EXPORT ACT1 MOVEMENT: " + ("PASS" if moved else "FAIL") + " displacement=" + str(player.global_position.distance_to(before)))
		ok = ok and moved
		print("EXPORT ACT1 ROOMS AND INPUT: " + ("PASS" if ok else "FAIL"))
		get_tree().quit(0 if ok else 1)
		return
	if level >= 0.0:
		Unreality.force(level)
