extends Node
## Entry. Shows the title screen (F-13), or jumps straight to the chapter given via `-- --chapter=N`.

func _ready() -> void:
	var start := 0
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--chapter="):
			start = int(arg.get_slice("=", 1))
	if start > 0:
		ChapterManager.go_to(start)
		return
	var title := TitleScreen.new()
	add_child(title)
	title.chapter_chosen.connect(_on_chapter_chosen.bind(title))


func _on_chapter_chosen(id: int, title: TitleScreen) -> void:
	title.queue_free()
	await get_tree().process_frame
	await ChapterManager.go_to(id)
	await Cutscene.fade_in(0.8)
