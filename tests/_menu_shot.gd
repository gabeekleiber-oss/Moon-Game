extends Node
## Dev tool: screenshots of the pause menu, settings and notepad. Usage: xvfb-run godot --path . --rendering-method gl_compatibility res://tests/_menu_shot.tscn
func _snap(name: String) -> void:
	for i in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/tmp/shots/%s.png" % name)
	print("saved ", name)

func _ready() -> void:
	GameSettings.path = "user://_shot_settings.json"
	var level := (load("res://scenes/levels/sandbox.tscn") as PackedScene).instantiate()
	add_child(level)
	Game.add_notepad_item("vase", "Ming Vase", 12000, "Entrance Hall")
	Game.add_notepad_item("lamp", "Brass Lamp", 500, "Entrance Hall")
	Game.add_notepad_item("helm", "Gilded Helm", 3000, "Military Gallery")
	Game.add_notepad_item("owl", "Stuffed Owl (very large, slightly alarming)", 850, "Bird Room")
	await _snap("toast")
	PauseMenu.open_pause()
	await _snap("pause")
	PauseMenu._show_mode("settings")
	await _snap("settings")
	PauseMenu._show_mode("notepad")
	await _snap("notepad")
	get_tree().quit()
