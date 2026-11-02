extends Node
## Dev tool: renders Act 1 from fixed viewpoints. bash scripts/tools/shot.sh res://tests/_wi_shots.tscn -- --out=/tmp/shots
const VIEWS := [
	["living_door", Vector3(5.6, 1.55, 2.5), Vector3(0.5, 1.0, 2.5)],
	["living_corner", Vector3(0.6, 1.7, 4.7), Vector3(4.6, 0.8, 1.2)],
	["kitchen", Vector3(3.0, 1.7, 5.3), Vector3(3.0, 0.9, 8.8)],
	["entry", Vector3(6.3, 1.6, 4.6), Vector3(8.3, 1.0, 0.8)],
	["closet", Vector3(6.3, 1.7, 5.4), Vector3(8.2, 1.0, 8.6)],
	["marysue", Vector3(4.4, 6.5, 3.4), Vector3(1.0, 5.8, 0.8)],
	["marysue_bed", Vector3(1.0, 6.5, 1.4), Vector3(3.6, 5.5, 3.3)],
	["yard", Vector3(10.8, 1.7, 5.5), Vector3(16.0, 0.9, 2.5)],
]
func _ready() -> void:
	var out := "/tmp/shots"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.get_slice("=", 1)
	DirAccess.make_dir_recursive_absolute(out)
	var act: Node = load("res://scenes/acts/act01_wisconsin/act01_wisconsin_alt.tscn").instantiate()   # world-frame Act 1 (act01.gd)
	add_child(act)
	for i in 20:
		await get_tree().process_frame
	var player := act.get("player") as Node3D
	if player != null:
		player.process_mode = Node.PROCESS_MODE_DISABLED
	var cam := Camera3D.new()
	cam.fov = 75.0
	act.add_child(cam)
	var torch := OmniLight3D.new()   # dev-only fill so props are judgeable under the act's very dim night lighting
	torch.omni_range = 14.0
	torch.light_energy = 2.2
	torch.shadow_enabled = false
	cam.add_child(torch)
	cam.make_current()
	for v in VIEWS:
		cam.global_position = v[1]
		cam.look_at(v[2], Vector3.UP)
		for i in 6:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("%s/wi_%s.png" % [out, v[0]])
	print("saved shots to ", out)
	get_tree().quit()
