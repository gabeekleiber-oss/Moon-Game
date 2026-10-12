extends Node
## Headless test for LightBudget: counting, frustum culling of lights, and the 2-shadow / 24-light limits.

var _fails := 0

func _check(cond: bool, what: String) -> void:
	print(("PASS " if cond else "FAIL ") + what)
	if not cond:
		_fails += 1

func _omni(parent: Node3D, pos: Vector3, rng: float, shadow: bool, nm: String) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.name = nm
	l.omni_range = rng
	l.shadow_enabled = shadow
	l.position = pos
	parent.add_child(l)
	return l

func _ready() -> void:
	var root := Node3D.new()
	add_child(root)
	var cam := Camera3D.new()
	cam.far = 50.0
	root.add_child(cam)          # looks down -Z from the origin
	_omni(root, Vector3(0, 1, -5), 4.0, true, "ahead_shadow")
	var moon := DirectionalLight3D.new()
	moon.name = "moon"
	moon.shadow_enabled = true
	root.add_child(moon)
	await get_tree().process_frame
	var r := LightBudget.in_view(cam, root)
	_check(r["total"] == 2 and r["shadow"] == 2 and not r["over"], "two shadow casters in view is within budget (%s)" % LightBudget.describe(r))
	# A third shadow caster BEHIND the camera does not count in view, but does in the subtree total.
	_omni(root, Vector3(0, 1, 40), 3.0, true, "behind_shadow")
	var rv := LightBudget.in_view(cam, root)
	var rc := LightBudget.count(root)
	_check(rv["shadow"] == 2 and not rv["over"], "a shadowed light behind the camera is not in view")
	_check(rc["shadow"] == 3 and rc["over"], "...but the whole-subtree count sees 3 and flags it")
	# A third in view goes over budget.
	_omni(root, Vector3(2, 1, -8), 3.0, true, "third_in_view")
	var r3 := LightBudget.in_view(cam, root)
	_check(r3["shadow"] == 3 and r3["over"], "a third shadow caster in view is flagged (%s)" % LightBudget.describe(r3))
	# Hidden lights are ignored.
	for n in root.find_children("*", "OmniLight3D", true, false):
		if String(n.name) == "third_in_view":
			(n as Light3D).visible = false
	_check(LightBudget.in_view(cam, root)["shadow"] == 2, "hidden lights do not count")
	# Total light cap.
	for i in 30:
		_omni(root, Vector3(0, 1, -6), 2.0, false, "fill_%d" % i)
	var rt := LightBudget.in_view(cam, root)
	_check(rt["total"] > LightBudget.MAX_LIGHTS_IN_VIEW and rt["over"], "too many unshadowed lights is flagged (%d)" % rt["total"])
	print("DONE %d failures" % _fails)
	get_tree().quit(1 if _fails > 0 else 0)
