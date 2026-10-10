extends Node
## Dev tool: saves a screenshot after a few frames (optional --grade=ch01 --flea=80 through the PostFX autoload). Usage: godot --path . --rendering-method gl_compatibility res://tests/_shot.tscn -- --out=/tmp/x.png
func _ready() -> void:
	var out := "/tmp/shots/shot.png"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.get_slice("=", 1)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--grade="):
			PostFX.set_grade(a.get_slice("=", 1), 0.0)
		elif a.begins_with("--flea="):
			Game.set_flea(float(a.get_slice("=", 1)), "shot")
	var level := (load("res://scenes/levels/sandbox.tscn") as PackedScene).instantiate()
	add_child(level)
	for i in 8:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out)
	print("saved ", out)
	get_tree().quit()
