extends Node
## Dev tool: renders MoonEye in states and saves PNGs.
## xvfb-run godot --path . --rendering-method gl_compatibility res://tests/_moon_shot.tscn -- --open=1 --out=/tmp/m.png
func _ready() -> void:
	var out := "/tmp/shots/moon.png"
	var op := 1.0
	var look := Vector3.ZERO
	var pupil := 0.35
	var dist := 34.0
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out = a.get_slice("=", 1)
		elif a.begins_with("--open="): op = float(a.get_slice("=", 1))
		elif a.begins_with("--pupil="): pupil = float(a.get_slice("=", 1))
		elif a.begins_with("--dist="): dist = float(a.get_slice("=", 1))
		elif a.begins_with("--look="):
			var p := a.get_slice("=", 1).split(",")
			look = Vector3(float(p[0]), float(p[1]), float(p[2]))
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.03, 0.04, 0.09)
	env.ambient_light_color = Color(0.4, 0.45, 0.6)
	env.ambient_light_energy = 0.6
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-20, 25, 0)
	sun.light_energy = 1.0
	add_child(sun)
	var moon := MoonEye.new()
	add_child(moon)
	var cam := Camera3D.new()
	cam.position = Vector3(0, 0, dist)
	add_child(cam)
	cam.make_current()
	await get_tree().process_frame
	moon.set_pupil(pupil, 0.0)
	moon.openness = op
	if look != Vector3.ZERO:
		moon.look_at_point(moon.to_global(look), 0.0)
	for i in 6:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(out.get_base_dir())
	get_viewport().get_texture().get_image().save_png(out)
	print("saved ", out)
	get_tree().quit()
