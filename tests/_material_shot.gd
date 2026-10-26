extends Node
## Dev tool: renders the S-02 material preview at several Unreality levels and saves PNGs.
## bash scripts/tools/shot.sh res://tests/_material_shot.tscn -- --levels=0,0.4,0.8,1.0 --out=/tmp/shots/mat

func _ready() -> void:
	var levels: Array[float] = [0.0, 0.4, 0.8, 1.0]
	var out := "/tmp/shots/mat"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--levels="):
			levels.clear()
			for s in a.get_slice("=", 1).split(","):
				levels.append(float(s))
		elif a.begins_with("--out="):
			out = a.get_slice("=", 1)
	var preview: Node = load("res://scenes/assets/material_preview.tscn").instantiate()
	add_child(preview)
	for child in preview.get_children():
		if child is Camera3D:
			(child as Camera3D).make_current()
	DirAccess.make_dir_recursive_absolute(out)
	for level in levels:
		preview.call("_set_level", level)
		for i in 20:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var path := "%s/mat_%02d.png" % [out, int(round(level * 100.0))]
		get_viewport().get_texture().get_image().save_png(path)
		print("saved ", path)
	get_tree().quit()
