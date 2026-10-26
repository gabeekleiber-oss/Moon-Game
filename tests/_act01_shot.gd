extends Node
## Dev tool: loads Act 1 and saves PNGs from the player's view.
## bash scripts/tools/shot.sh res://tests/_act01_shot.tscn -- --out=/tmp/shots/act01
const ActScene = preload("res://scenes/acts/act01_wisconsin/act01_wisconsin.tscn")
func _ready() -> void:
	var out := "/tmp/shots/act01"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out = a.get_slice("=", 1)
	DirAccess.make_dir_recursive_absolute(out)
	var act: Act01 = ActScene.instantiate()
	act.auto_advance = false
	add_child(act)
	var cam := act.player.get_node("Head/Camera3D") as Camera3D
	cam.make_current()
	for i in 10: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out + "/start.png")
	act.start_intruder()
	await get_tree().create_timer(3.4).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out + "/finger.png")
	print("saved shots")
	get_tree().quit()
