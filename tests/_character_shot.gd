extends Node
## Dev tool: renders characters in a row. bash scripts/tools/shot.sh res://tests/_character_shot.tscn -- --who=elsa,mary,frank --expr=neutral --out=/tmp/x.png [--close]
func _make(who: String) -> Node3D:
	match who:
		"elsa": return ElsaRay.new()
		"mary": return MarySue.new()
		"frank": return Frank.new()
		"sweaty": return ClassDB.instantiate("Node3D") if not ResourceLoader.exists("res://scenes/characters/sweaty_man.gd") else (load("res://scenes/characters/sweaty_man.gd") as GDScript).new()
		"statue_joshua", "statue_crumpis", "statue_crumpalump", "statue_curt":
			var st = (load("res://scenes/characters/gold_statue.gd") as GDScript).new()
			st.kind = {"statue_joshua": 0, "statue_crumpis": 1, "statue_crumpalump": 2, "statue_curt": 3}[who]
			return st
		"hands": return (load("res://scenes/characters/christopher_hands.gd") as GDScript).new()
	return Node3D.new()

func _ready() -> void:
	var who := "elsa,mary,frank"
	var expr := ""
	var out := "/tmp/shots/chars.png"
	var close := false
	var gap := 1.4
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--who="): who = a.get_slice("=", 1)
		elif a.begins_with("--expr="): expr = a.get_slice("=", 1)
		elif a.begins_with("--out="): out = a.get_slice("=", 1)
		elif a.begins_with("--gap="): gap = float(a.get_slice("=", 1))
		elif a == "--close": close = true
	var root := Node3D.new()
	add_child(root)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.2, 0.22, 0.3)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.75, 0.75, 0.85)
	root.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40, 30, 0)
	root.add_child(sun)
	var floor_mi := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(30, 30)
	floor_mi.mesh = plane
	var fm := StandardMaterial3D.new()
	fm.albedo_color = Color(0.35, 0.3, 0.3)
	floor_mi.material_override = fm
	root.add_child(floor_mi)
	var names := who.split(",")
	var x := -(names.size() - 1) * gap * 0.5
	var tallest := 1.0
	for n in names:
		var c := _make(n)
		c.position = Vector3(x, 0, 0)
		root.add_child(c)
		if expr != "" and c.has_method("set_expression"):
			c.set_expression(expr)
		x += gap
	await get_tree().process_frame
	var cam := Camera3D.new()
	root.add_child(cam)
	if close:
		cam.position = Vector3(0, 1.55, 1.1)
		cam.look_at(Vector3(0, 1.45, 0))
	else:
		cam.position = Vector3(0, 1.3, 2.0 + names.size() * 0.9)
		cam.look_at(Vector3(0, 1.0, 0))
	cam.make_current()
	for i in 6:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out)
	print("saved ", out)
	get_tree().quit()
