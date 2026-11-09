extends Node
## L-01: the Wisconsin dressing is dense, tagged placeholder, stays inside each space and never blocks a beat lane.
var _fails := 0

func _check(condition: bool, message: String) -> void:
	print(("PASS " if condition else "FAIL ") + message)
	if not condition:
		_fails += 1

## Conservative world AABB (min, max) of a solid body's collision shape.
func _aabb_of(body: StaticBody3D) -> AABB:
	var cs := body.get_child(0) as CollisionShape3D
	var half := Vector3.ZERO
	if cs.shape is BoxShape3D:
		half = (cs.shape as BoxShape3D).size * 0.5
	elif cs.shape is CylinderShape3D:
		var c := cs.shape as CylinderShape3D
		half = Vector3(c.radius, c.height * 0.5, c.radius)
	elif cs.shape is SphereShape3D:
		var r := (cs.shape as SphereShape3D).radius
		half = Vector3(r, r, r)
	var lo := Vector3(INF, INF, INF)
	var hi := Vector3(-INF, -INF, -INF)
	for sx in [-1.0, 1.0]:
		for sy in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				var corner := body.transform * (Vector3(sx, sy, sz) * half)
				lo = lo.min(corner)
				hi = hi.max(corner)
	return AABB(lo, hi - lo)

func _solids(room: Node) -> Array:
	var out: Array = []
	for c in room.get_children():
		if c is StaticBody3D:
			out.append(c)
	return out

func _ready() -> void:
	var root := Node3D.new()
	add_child(root)
	# Stand-in for Act01's carryable fish tank so the tank dressing is exercised.
	var tank := Node3D.new()
	tank.name = "FishTank"
	var glass := MeshInstance3D.new()
	glass.name = "Mesh"
	glass.mesh = BoxMesh.new()
	var gm := StandardMaterial3D.new()
	glass.material_override = gm
	tank.add_child(glass)
	root.add_child(tank)
	var dressing := WiDressing.dress_all(root)

	var minimums := {"living_room": 45, "kitchen": 40, "entry": 28, "hall_closet": 18, "marysue_room": 30, "yard": 50}
	var total := 0
	for room_name in minimums:
		var room := dressing.get_node(room_name)
		var n := room.get_child_count()
		total += n
		_check(n >= int(minimums[room_name]), "%s is dressed (%d objects, need %d)" % [room_name, n, minimums[room_name]])
	_check(total >= 250, "the house has at least 250 dressed objects (%d)" % total)
	var untagged := 0
	for room in dressing.get_children():
		for c in room.get_children():
			if not c.has_meta("placeholder"):
				untagged += 1
	_check(untagged == 0, "every dressing node is tagged placeholder")

	# Solids stay inside their space (a small tolerance for wall faces).
	for room_name in WiDressing.BOUNDS:
		var rect: Rect2 = WiDressing.BOUNDS[room_name]
		var bad: Array[String] = []
		for body in _solids(dressing.get_node(room_name)):
			var a := _aabb_of(body)
			if a.position.x < rect.position.x - 0.05 or a.end.x > rect.end.x + 0.05 or a.position.z < rect.position.y - 0.05 or a.end.z > rect.end.y + 0.05:
				bad.append(String(body.name))
		_check(bad.is_empty(), "%s solids stay inside the space %s" % [room_name, str(bad)])

	# Beat lanes: [name, x0, z0, x1, z1, y0, y1]. No solid dressing may overlap any of them.
	var lanes := [
		["living room door lane and player spawn", 3.95, 1.5, 6.0, 3.5, 0.0, 2.0],
		["entry lane (Sweaty Man walk, front door)", 6.0, 1.6, 9.0, 3.4, 0.0, 2.0],
		["stairs portal", 7.7, 4.1, 8.7, 5.1, 0.0, 2.0],
		["kitchen opening", 2.1, 5.0, 3.9, 5.9, 0.0, 2.0],
		["kitchen to closet door", 5.0, 6.4, 7.0, 7.6, 0.0, 2.0],
		["closet entry door", 7.0, 5.0, 8.0, 5.9, 0.0, 2.0],
		["broom spot", 8.45, 8.55, 8.75, 8.85, 0.0, 2.0],
		["kitchen carry items on the counter", 0.9, 8.3, 2.3, 8.9, 0.9, 1.6],
		["Mary Sue room spawn", 2.0, 1.5, 3.0, 2.5, MARY_Y_MIN, 4.6],
		["Mary Sue room stair portal", 4.0, 1.4, 5.0, 2.6, MARY_Y_MIN, 4.6],
		["Mary Sue desk and tank", 0.2, 0.3, 1.8, 1.1, MARY_Y_MIN, 4.6],
		["yard spawn", 10.5, 2.0, 11.5, 3.0, 0.0, 2.0],
		["driveway lane to the car", 9.0, 1.7, 15.1, 3.3, 0.0, 2.0],
		["car body", 15.1, 0.25, 16.9, 4.75, 0.0, 2.0],
	]
	for lane in lanes:
		var hits: Array[String] = []
		for room in dressing.get_children():
			for body in _solids(room):
				var a := _aabb_of(body)
				if a.position.x < lane[3] and a.end.x > lane[1] and a.position.z < lane[4] and a.end.z > lane[2] and a.position.y < lane[6] and a.end.y > lane[5]:
					hits.append(String(body.name))
		_check(hits.is_empty(), "lane stays clear: %s %s" % [lane[0], str(hits)])

	# Tank dressing: see-through glass, details are direct mesh children (so a throw copies them).
	_check(gm.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED, "original tank material is not mutated")
	var new_mat := glass.material_override as StandardMaterial3D
	_check(new_mat.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA and new_mat.albedo_color.a < 0.5, "tank glass is see-through")
	_check(tank.find_child("Gravel", false, false) is MeshInstance3D and tank.find_child("Fish0", false, false) is MeshInstance3D, "tank has gravel and fish as direct mesh children")
	print("RESULT: %s" % ("ALL PASS" if _fails == 0 else "%d FAILED" % _fails))
	get_tree().quit(0 if _fails == 0 else 1)

const MARY_Y_MIN := 2.6
