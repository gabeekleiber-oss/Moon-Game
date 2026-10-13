extends Node
## Smoke test (S-12): every scene under res://scenes/ loads, instantiates, enters the tree for a few frames and frees cleanly.
## Also prints SceneStats per scene and fails if a scene breaks the scene-wide budgets.

## Scenes that replace the whole tree or need a real window; loaded but not entered.
const LOAD_ONLY := ["res://scenes/main/main.tscn"]

var _fails := 0

func _check(cond: bool, what: String) -> void:
	print(("PASS " if cond else "FAIL ") + what)
	if not cond:
		_fails += 1

func _find(dir: String, out: Array[String]) -> void:
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".tscn"):
			out.append(dir.path_join(f))
	for d in DirAccess.get_directories_at(dir):
		_find(dir.path_join(d), out)

func _ready() -> void:
	var paths: Array[String] = []
	_find("res://scenes", paths)
	paths.sort()
	_check(paths.size() >= 16, "found scenes (%d)" % paths.size())
	for p in paths:
		var ps := load(p) as PackedScene
		if ps == null:
			_check(false, "loads: " + p)
			continue
		if p in LOAD_ONLY:
			_check(ps.can_instantiate(), "can instantiate: " + p)
			continue
		var inst := ps.instantiate()
		_check(inst != null, "instantiates: " + p)
		if inst == null:
			continue
		add_child(inst)
		await get_tree().process_frame
		await get_tree().process_frame
		var st := SceneStats.collect(inst)
		var bad := SceneStats.violations(st)
		print("     ", p.get_file(), ": ", SceneStats.describe(st))
		_check(bad.is_empty(), "within scene budgets: %s %s" % [p.get_file(), bad])
		inst.queue_free()
		await get_tree().process_frame
	print("---- smoke: %d failures" % _fails)
	get_tree().quit(1 if _fails > 0 else 0)
