extends Node
## Dev tool: renders props side by side. xvfb-run godot --path . --rendering-method gl_compatibility res://tests/_prop_shot.tscn -- --set=chandelier --out=/tmp/p.png
func _ready() -> void:
	var out := "/tmp/shots/props.png"
	var which := "chandelier"
	var cam_pos := Vector3(0, -1.2, 5.5)
	var look_at_y := -1.0
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out = a.get_slice("=", 1)
		elif a.begins_with("--set="): which = a.get_slice("=", 1)
		elif a.begins_with("--cam="):
			var p := a.get_slice("=", 1).split(",")
			cam_pos = Vector3(float(p[0]), float(p[1]), float(p[2]))
		elif a.begins_with("--y="): look_at_y = float(a.get_slice("=", 1))
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.1, 0.07, 0.09)
	env.ambient_light_color = Color(0.5, 0.45, 0.5)
	env.ambient_light_energy = 0.7
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35, 30, 0)
	sun.light_energy = 0.8
	add_child(sun)
	match which:
		"chandelier":
			var x := -2.2
			for v in [Chandelier.Variant.BRASS, Chandelier.Variant.RUBY, Chandelier.Variant.MILKY]:
				var c := Chandelier.new()
				c.variant = v
				c.position = Vector3(x, 0.6, 0)
				add_child(c)
				x += 2.2
		"armor":
			var x := -1.8
			for cfg in [[Armor.Finish.STEEL, Armor.Pose.REST, false], [Armor.Finish.BLACK, Armor.Pose.SALUTE, false], [Armor.Finish.BRASS, Armor.Pose.GUARD, true]]:
				var a := Armor.new()
				a.finish = cfg[0]
				a.pose = cfg[1]
				a.halberd = cfg[2]
				a.position = Vector3(x, -0.9, 0)
				add_child(a)
				x += 1.8
	var cam := Camera3D.new()
	cam.position = cam_pos
	add_child(cam)
	cam.make_current()
	cam.look_at(Vector3(cam_pos.x, look_at_y, 0))
	for i in 8:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(out.get_base_dir())
	get_viewport().get_texture().get_image().save_png(out)
	print("saved ", out)
	get_tree().quit()
