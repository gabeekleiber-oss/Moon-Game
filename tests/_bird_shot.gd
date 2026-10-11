extends Node
## Dev tool: renders all 12 bird species in two rows. bash scripts/tools/shot.sh res://tests/_bird_shot.tscn -- --out=/tmp/shots/birds.png
func _ready() -> void:
	var out := "/tmp/shots/birds.png"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out = a.get_slice("=", 1)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.55, 0.6, 0.7)
	env.ambient_light_color = Color(0.8, 0.8, 0.85)
	env.ambient_light_energy = 0.7
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40, 35, 0)
	add_child(sun)
	for i in 12:
		var mi := MeshInstance3D.new()
		mi.mesh = BirdMesh.build(BirdSpecies.get_species(i))
		mi.position = Vector3((i % 6 - 2.5) * 0.3, 0.0 - (i / 6) * 0.3, 0)
		mi.rotation_degrees = Vector3(0, 40, 0)
		add_child(mi)
	var cam := Camera3D.new()
	cam.position = Vector3(0, 0.0, 1.4)
	add_child(cam)
	cam.make_current()
	cam.look_at(Vector3(0, -0.12, 0))
	for i in 5:
		await get_tree().process_frame
	DirAccess.make_dir_recursive_absolute(out.get_base_dir())
	get_viewport().get_texture().get_image().save_png(out)
	print("saved ", out)
	get_tree().quit()
