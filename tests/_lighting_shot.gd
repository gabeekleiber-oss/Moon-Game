extends Node
## Dev tool: renders the lighting test room and saves a PNG (software GL: no volumetric fog or SSAO here, so this proves the room
## renders and the lights read, not the final look; verify the look in a real window).
## bash scripts/tools/shot.sh res://tests/_lighting_shot.tscn -- --look=dawn --unreality=0.0 --out=/tmp/shots/dawn.png
func _ready() -> void:
	var look := "night_dark"
	var level := 0.0
	var out := "/tmp/shots/lighting.png"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--look="): look = a.get_slice("=", 1)
		elif a.begins_with("--unreality="): level = float(a.get_slice("=", 1))
		elif a.begins_with("--out="): out = a.get_slice("=", 1)
	var room := LightingTestRoom.new()
	room.use_player = false
	room.look = look
	add_child(room)
	var cam := Camera3D.new()
	cam.fov = 75.0
	room.add_child(cam)
	cam.position = Vector3(0.0, 1.6, 2.3)
	cam.look_at(Vector3(-0.2, 1.0, -1.0))
	cam.make_current()
	Unreality.frozen = true
	Unreality.force(level)
	for i in 10:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(out.get_base_dir())
	get_viewport().get_texture().get_image().save_png(out)
	print("saved ", out, "  ", LightBudget.describe(room.budget(cam)))
	get_tree().quit()
