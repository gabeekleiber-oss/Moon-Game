extends Node
## Dev tool (S-12): loads one scene, finds its Camera3D (adds one at head height if none), saves a PNG. Used by scripts/tools/strip.sh.
## Software GL: proves the scene renders, not the final look (unverified in a real window).
func _ready() -> void:
	var scene := ""
	var out := "/tmp/strip/x.png"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--scene="): scene = a.get_slice("=", 1)
		elif a.begins_with("--out="): out = a.get_slice("=", 1)
	var ps := load(scene) as PackedScene
	if ps == null:
		printerr("FAIL cannot load ", scene)
		get_tree().quit(1)
		return
	var inst := ps.instantiate()
	add_child(inst)
	var cam := _find_cam(inst)
	if cam == null:
		cam = Camera3D.new()
		inst.add_child(cam)
		cam.position = Vector3(0.0, 1.6, 4.0)
	cam.make_current()
	for i in 12:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(out.get_base_dir())
	get_viewport().get_texture().get_image().save_png(out)
	print("saved ", out)
	get_tree().quit()

func _find_cam(n: Node) -> Camera3D:
	if n is Camera3D:
		return n
	for c in n.get_children():
		var r := _find_cam(c)
		if r:
			return r
	return null
