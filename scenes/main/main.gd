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
	if _show_title():
		var title: Node = load("res://scenes/title/title_screen.tscn").instantiate()
		add_child(title)
		return
	await Acts.go_to(start, true)
	if OS.get_cmdline_user_args().has("--capture-act1"):
		for frame in 30:
			await get_tree().process_frame
		var capture := get_viewport().get_texture().get_image()
		var path := "user://act1_visual.png"
		print("VISUAL CAPTURE: " + str(capture.save_png(path)) + " " + ProjectSettings.globalize_path(path))
		get_tree().quit()
		return
	if OS.get_cmdline_user_args().has("--verify-export"):
		await get_tree().process_frame
		var rooms := Acts._current.get_node_or_null("RoomBuilder")
		var player := Acts._current.get_node_or_null("Player")
		var ok: bool = rooms != null and rooms.get_child_count() >= 5 and player != null and not player.call("_locked") and not get_tree().paused and player.global_position.x > 1.0 and player.global_position.x < 5.0 and player.get_node("Head/Camera3D").global_position.y < 2.35 and get_viewport().get_camera_3d() == player.get_node("Head/Camera3D")
		var before: Vector3 = player.global_position
		Input.action_press("move_forward")
		for frame in 18:
			await get_tree().physics_frame
		Input.action_release("move_forward")
		var moved: bool = player.global_position.distance_to(before) > 0.15
		print("EXPORT ACT1 MOVEMENT: " + ("PASS" if moved else "FAIL") + " displacement=" + str(player.global_position.distance_to(before)))
		ok = ok and moved
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		var yaw_before: float = player.rotation.y
		var motion := InputEventMouseMotion.new()
		motion.relative = Vector2(120.0, 0.0)
		player._apply_mouse_look(motion.relative)
		await get_tree().process_frame
		var looked: bool = absf(player.rotation.y - yaw_before) > 0.01
		print("EXPORT ACT1 MOUSE LOOK: " + ("PASS" if looked else "FAIL"))
		ok = ok and looked
		print("EXPORT ACT1 ROOMS AND INPUT: " + ("PASS" if ok else "FAIL"))
		get_tree().quit(0 if ok else 1)
		return
	if level >= 0.0:
		Unreality.force(level)


## The title screen is the default entry. Any debug or verification flag skips it and starts the act directly.
func _show_title() -> bool:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--act=") or arg in ["--capture-act1", "--verify-export", "--skip-title"]:
			return false
	return true
