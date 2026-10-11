extends Node
## Dev tool: renders the title screen. bash scripts/tools/shot.sh res://tests/_title_shot.tscn -- --out=/tmp/shots/title.png [--panel=chapters|settings]
func _ready() -> void:
	var out := "/tmp/shots/title.png"
	var panel := "menu"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out = a.get_slice("=", 1)
		elif a.begins_with("--panel="): panel = a.get_slice("=", 1)
	var t := TitleScreen.new()
	add_child(t)
	t.show_panel(panel)
	await get_tree().create_timer(4.5).timeout
	DirAccess.make_dir_recursive_absolute(out.get_base_dir())
	get_viewport().get_texture().get_image().save_png(out)
	print("saved ", out)
	get_tree().quit()
