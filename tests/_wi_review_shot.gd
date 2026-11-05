extends Node
## Dev tool: free-camera review shots of Act 1 (layout from above, living room toward the couch).
## bash scripts/tools/shot.sh res://tests/_wi_review_shot.tscn -- --out=/tmp/shots/review
const ActScene = preload("res://scenes/acts/act01_wisconsin/act01_wisconsin_alt.tscn")
func _shot(path: String) -> void:
	for i in 6: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
func _ready() -> void:
	var out := "/tmp/shots/review"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out = a.get_slice("=", 1)
	DirAccess.make_dir_recursive_absolute(out)
	var act: Act01 = ActScene.instantiate()
	act.auto_advance = false
	add_child(act)
	var cam := Camera3D.new()
	act.add_child(cam)
	cam.make_current()
	cam.fov = 70
	if "--noceil" in OS.get_cmdline_user_args():
		_hide_ceilings(act)
	var views := {
		"top": [Vector3(9, 30, 6), Vector3(9, 0, 5.5)],
		"side": [Vector3(8, 6, 30), Vector3(8, 2.5, 0)],
		"mary": [Vector3(14.5, 7.5, 4.5), Vector3(12.5, 5.0, 2.0)],
		"couch": [Vector3(6.0, 1.6, 2.6), Vector3(3.5, 0.6, 2.5)],
		"couch_side": [Vector3(3.6, 1.8, 5.5), Vector3(3.5, 0.5, 2.3)],
		"living_wide": [Vector3(0.6, 2.0, 0.6), Vector3(4.5, 0.8, 4.0)],
	}
	for k in views:
		cam.global_position = views[k][0]
		cam.look_at(views[k][1], Vector3.UP if k != "top" else Vector3(0, 0, -1))
		await _shot(out + "/" + k + ".png")
	print("saved review shots")
	get_tree().quit()

func _hide_ceilings(n: Node) -> void:
	for c in n.get_children():
		if c is MeshInstance3D and (str(c.name).begins_with("Ceiling") or str(c.name).begins_with("Roof")):
			(c as MeshInstance3D).visible = false
		_hide_ceilings(c)
