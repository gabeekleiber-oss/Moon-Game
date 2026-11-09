extends Node
## Dev tool: renders each Act 1 room from the player's view.
## bash scripts/tools/shot.sh res://tests/_act01_rooms_shot.tscn -- --out=/tmp/shots/rooms
const ActScene = preload("res://scenes/acts/act01_wisconsin/act01_wisconsin_alt.tscn")
## [name, position, yaw radians]
const VIEWS := [
	["living_tv", Vector3(5.2, 0.1, 2.5), PI * 0.5],
	["living_door", Vector3(2.0, 0.1, 2.5), -PI * 0.5],
	["kitchen", Vector3(5.2, 0.1, 5.8), PI * 0.5],
	["closet", Vector3(7.5, 0.1, 5.6), 0.0],
	["marysue", Vector3(0.8, 2.8, 2.0), -PI * 0.5],
	["yard", Vector3(11.0, 0.1, 2.5), -PI * 0.5],
]
func _ready() -> void:
	var out := "/tmp/shots/rooms"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out = a.get_slice("=", 1)
	DirAccess.make_dir_recursive_absolute(out)
	var act: Act01 = ActScene.instantiate()
	act.auto_advance = false
	act._intruded = true
	add_child(act)
	var cam := act.player.get_node("Head/Camera3D") as Camera3D
	cam.make_current()
	for i in 8: await get_tree().process_frame
	for v in VIEWS:
		act.player.global_position = v[1]
		act.player.rotation.y = v[2]
		for i in 6: await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, v[0]])
	print("saved shots")
	get_tree().quit()
