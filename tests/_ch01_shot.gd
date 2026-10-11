extends Node
## Dev tool: renders Chapter 1. Usage: bash scripts/tools/shot.sh res://tests/_ch01_shot.tscn -- --view=player|overview|tv|door|letter --out=/tmp/shots/ch01.png
func _ready() -> void:
	var out := "/tmp/shots/ch01.png"
	var view := "player"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.get_slice("=", 1)
		elif a.begins_with("--view="):
			view = a.get_slice("=", 1)
	var ch := (load("res://scenes/chapters/ch01_wisconsin/ch01_wisconsin.tscn") as PackedScene).instantiate()
	ch.set("show_title_card", false)
	ch.set("tutorial_seconds", 9999.0)
	add_child(ch)
	for i in 4:
		await get_tree().process_frame
	var cam := Camera3D.new()
	add_child(cam)
	match view:
		"overview":
			cam.transform = Transform3D(Basis.IDENTITY, Vector3(2.7, 2.5, 3.3)).looking_at(Vector3(-0.5, 0.8, -1.0), Vector3.UP)
			cam.fov = 75.0
		"tv":
			cam.transform = Transform3D(Basis.IDENTITY, Vector3(0.0, 1.5, 0.8)).looking_at(Vector3(0.0, 0.9, -3.0), Vector3.UP)
			cam.fov = 60.0
		"door":
			var sw := ch.get("_sweaty") as Node3D
			sw.visible = true
			sw.position = Vector3(-2.2, 0, 1.4)
			sw.call("face_toward", Vector3(0, 0, 2.6))
			cam.transform = Transform3D(Basis.IDENTITY, Vector3(1.4, 1.7, 3.1)).looking_at(Vector3(-1.6, 1.1, 1.3), Vector3.UP)
			cam.fov = 66.0
		"kick":
			var km := KickMeter.new()
			ch.add_child(km)
			km.start(100.0, 0.62, 0.11)
			km._t = 62.0
			cam.transform = Transform3D(Basis.IDENTITY, Vector3(0, 1.65, 2.6)).looking_at(Vector3(0, 1.4, -3.0), Vector3.UP)
		"letter":
			var ui := LetterUI.new()
			ui.reveal_seconds = 0.0
			ch.add_child(ui)
			ui.open()
			cam.transform = Transform3D(Basis.IDENTITY, Vector3(0, 1.6, 2.6))
		_:
			cam.transform = Transform3D(Basis.IDENTITY, Vector3(0, 1.65, 2.6)).looking_at(Vector3(0, 1.2, -3.0), Vector3.UP)
			cam.fov = 75.0
	cam.make_current()
	for i in 10:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(out.get_base_dir())
	get_viewport().get_texture().get_image().save_png(out)
	print("saved ", out)
	get_tree().quit()
