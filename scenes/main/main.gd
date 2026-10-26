extends Node
## Entry. Starts Act 1 (a title screen is a task in docs/TASKS.md), or jumps to the act given via `-- --act=N`
## (optionally `--unreality=0.6` to start at that hidden level).

func _ready() -> void:
	var start := 1
	var level := -1.0
	var quality_override := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--act="):
			start = int(arg.get_slice("=", 1))
		elif arg.begins_with("--quality="):
			quality_override = arg.get_slice("=", 1)
		elif arg.begins_with("--unreality="):
			level = float(arg.get_slice("=", 1))
	if quality_override in ["auto", "high", "medium", "low"]:
		Game.settings["quality"] = quality_override
		GameSettings.apply("quality")
	await Acts.go_to(start, true)
	if level >= 0.0:
		Unreality.force(level)
