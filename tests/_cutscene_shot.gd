extends Node
## Dev tool: renders a cutscene frame. godot --path . --rendering-method gl_compatibility res://tests/_cutscene_shot.tscn -- --mode=cam|card --out=x.png
func _ready() -> void:
	var mode := "cam"
	var out := "/tmp/shots/cs.png"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--mode="):
			mode = a.get_slice("=", 1)
		elif a.begins_with("--out="):
			out = a.get_slice("=", 1)
	var level := (load("res://scenes/levels/sandbox.tscn") as PackedScene).instantiate()
	add_child(level)
	await get_tree().process_frame
	var pillar := Node3D.new()      # floor-level anchor: presets frame from the target's origin
	pillar.position = Vector3(0, 0, -2.2)
	level.add_child(pillar)
	var shot := func() -> void:
		for i in 6:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(out)
		print("saved ", out)
		get_tree().quit()
	if mode == "cam":
		Cutscene.play(func() -> void:
			await Cutscene.letterbox(true, 0.1)
			await Cutscene.cam("close", pillar, 0.1)
			await shot.call())
	else:
		Cutscene.chapter_card(5, 6.0)
		await get_tree().create_timer(1.9).timeout
		await shot.call()
