extends Node
## Dev tool: screenshot of the title screen. Usage: bash scripts/tools/shot.sh res://tests/_title_shot.tscn -- --out=/tmp/title.png
func _ready() -> void:
	var out := "/tmp/title.png"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.get_slice("=", 1)
	var title: TitleScreen = (load("res://scenes/title/title_screen.tscn") as PackedScene).instantiate()
	add_child(title)
	for i in 160:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out)
	print("saved ", out)
	get_tree().quit()
