extends Node
## Dev tool: loads an act (stub or real) at a given hidden Unreality level and saves a PNG.
## bash scripts/tools/shot.sh res://tests/_unreal_shot.tscn -- --act=3 --unreality=0.7 --out=/tmp/shots/u.png
func _ready() -> void:
	var act := 1
	var level := 0.0
	var out := "/tmp/shots/unreal.png"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--act="): act = int(a.get_slice("=", 1))
		elif a.begins_with("--unreality="): level = float(a.get_slice("=", 1))
		elif a.begins_with("--out="): out = a.get_slice("=", 1)
	await Acts.go_to(act, true)
	Unreality.frozen = true
	Unreality.force(level)
	for i in 10:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(out.get_base_dir())
	get_viewport().get_texture().get_image().save_png(out)
	print("saved ", out)
	get_tree().quit()
