extends Node
## Dev tool: screenshots of the in-world toast, pause menu and settings. Usage: xvfb-run godot --path . --rendering-method gl_compatibility res://tests/_menu_shot.tscn
func _snap(name: String) -> void:
	for i in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/tmp/shots/%s.png" % name)
	print("saved ", name)

func _ready() -> void:
	GameSettings.path = "user://_shot_settings.json"
	await Acts.go_to(1, true)
	Events.show_message.emit("The house is quiet. Too quiet, in my opinion.")
	Events.show_message.emit("A quiet in-world line.")
	await _snap("toast")
	PauseMenu.open_pause()
	await _snap("pause")
	PauseMenu._show_mode("settings")
	await _snap("settings")
	get_tree().quit()
