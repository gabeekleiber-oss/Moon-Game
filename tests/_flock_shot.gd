extends Node3D
## Dev tool: hero bird close-up + a flock. bash scripts/tools/shot.sh res://tests/_flock_shot.tscn -- --out=/tmp/shots/flock.png --mode=flock|hero
func _ready() -> void:
	var out := "/tmp/shots/flock.png"
	var mode := "flock"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out = a.get_slice("=", 1)
		elif a.begins_with("--mode="): mode = a.get_slice("=", 1)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.16, 0.14, 0.22)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.7, 0.7, 0.8)
	env.ambient_light_energy = 1.0
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35, -25, 0)
	sun.light_energy = 1.4
	add_child(sun)
	var cam := Camera3D.new()
	add_child(cam)
	if mode == "hero":
		var h := HeroBird.new()
		h.species = 4
		h.hero_scale = 6.0
		add_child(h)
		h.rotation_degrees.y = 35
		cam.position = Vector3(0, 0.5, 1.6)
		cam.look_at(Vector3(0, 0.45, 0))
	else:
		var f := Flock.new()
		f.count = 100
		add_child(f)
		cam.position = Vector3(0, 3.5, 13)
		cam.look_at(Vector3(0, 3.5, 0))
	cam.make_current()
	for i in 90:
		await get_tree().process_frame
	DirAccess.make_dir_recursive_absolute(out.get_base_dir())
	get_viewport().get_texture().get_image().save_png(out)
	print("saved ", out)
	get_tree().quit()
