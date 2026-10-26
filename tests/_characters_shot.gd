extends Node
## Dev tool: lines up the S-08a cast. bash scripts/tools/shot.sh res://tests/_characters_shot.tscn -- --out=/tmp/shots/cast.png
func _ready() -> void:
	var out := "/tmp/shots/cast.png"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.get_slice("=", 1)
	var world := Node3D.new()
	add_child(world)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.12, 0.13, 0.16)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.5, 0.5, 0.55)
	world.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35.0, 25.0, 0.0)
	world.add_child(sun)
	var floor_mesh := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(14.0, 6.0)
	floor_mesh.mesh = pm
	world.add_child(floor_mesh)
	var x := -3.6
	for id in CharacterFallback.IDS:
		var c := CharacterFallback.make(id)
		c.position = Vector3(x, 0.0, 0.0)
		world.add_child(c)
		x += 1.2
	var cam := Camera3D.new()
	cam.position = Vector3(0.0, 1.3, 6.4)
	cam.fov = 55.0
	world.add_child(cam)
	cam.make_current()
	for i in 8:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(out.get_base_dir())
	get_viewport().get_texture().get_image().save_png(out)
	print("saved ", out)
	get_tree().quit()
