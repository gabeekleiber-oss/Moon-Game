extends Node
## Unit test for SceneStats (S-12): counting and limit checks on synthetic node trees.

var _fails := 0

func _check(cond: bool, what: String) -> void:
	print(("PASS " if cond else "FAIL ") + what)
	if not cond:
		_fails += 1

func _ready() -> void:
	var root := Node3D.new()
	for i in 3:
		var l := OmniLight3D.new()
		l.shadow_enabled = (i == 0)
		root.add_child(l)
	var m := MeshInstance3D.new()
	m.mesh = BoxMesh.new()
	root.add_child(m)
	var hidden := MeshInstance3D.new()
	hidden.mesh = BoxMesh.new()
	hidden.visible = false
	root.add_child(hidden)
	var cp := CPUParticles3D.new()
	cp.amount = 50
	root.add_child(cp)
	var s := SceneStats.collect(root)
	_check(s["lights"] == 3 and s["shadow_lights"] == 1, "counts lights and shadow lights")
	_check(s["meshes"] == 1 and s["surfaces"] == 1, "hidden meshes are not counted")
	_check(s["particles"] == 50, "counts CPU particles")
	_check(s["nodes"] == 7, "counts all nodes including root")
	_check(SceneStats.violations(s).is_empty(), "small scene is within limits")
	var bad := SceneStats.violations(s, {"lights": 2, "particles": 50})
	_check(bad.size() == 1 and bad[0].begins_with("lights"), "limit is exclusive: equal passes, over fails")
	_check(SceneStats.describe(s).contains("lights=3"), "describe formats stats")
	root.free()
	print("---- scene_stats: %d failures" % _fails)
	get_tree().quit(1 if _fails > 0 else 0)
