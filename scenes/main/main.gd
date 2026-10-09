extends Node
## Entry. Starts Chapter 1 (or the chapter given via `-- --chapter=N`).

func _ready() -> void:
	var start := 1
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--chapter="):
			start = int(arg.get_slice("=", 1))
	ChapterManager.go_to(start)
