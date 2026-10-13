class_name RoomBuilder
extends Node3D
## Builds a structural blockout from one data/world/*.json room definition.
## Geometry is deliberately code-built and marked as a placeholder until the room is dressed.
## Coordinates are the shared WORLD_BIBLE metre grid; mansion upper levels start at y=5 and dome at y=10.

const AssetCatalogScript = preload("res://scenes/assets/asset_catalog.gd")
const WALL_THICKNESS := 0.30
const FLOOR_THICKNESS := 0.20
const DEFAULT_DOOR_HEIGHT := 2.1
const DOUBLE_DOOR_HEIGHT := 2.4
const UPPER_LEVEL_STEP := 5.0

var _locked_doors: Array[Dictionary] = []
var current_act_id: int = 0


func _ready() -> void:
	if not Events.beat_completed.is_connected(_on_beat_completed):
		Events.beat_completed.connect(_on_beat_completed)


func _exit_tree() -> void:
	if Events.beat_completed.is_connected(_on_beat_completed):
		Events.beat_completed.disconnect(_on_beat_completed)


## Creates and parents a room node. Rectangular rooms get floor, ceiling, wall segments, trim,
## door/window openings, a nav polygon and any prop placeholders. Non-rectangular frames get a marked pad.
func build_room(room_data: Dictionary, state_name: String = "night") -> Node3D:
	var room_id := str(room_data.get("id", "unknown_room"))
	var root := Node3D.new()
	root.name = room_id
	root.set_meta("room_id", room_id)
	root.set_meta("frame", str(room_data.get("frame", "")))
	root.set_meta("state", state_name)
	root.set_meta("placeholder", true)
	add_child(root)

	var footprint: Variant = room_data.get("footprint", null)
	if footprint is Array and (footprint as Array).size() >= 4:
		_build_rect_room(root, room_data, footprint as Array)
	else:
		_build_frame_pad(root, room_data)
	_build_props(root, room_data)
	return root


func _build_rect_room(root: Node3D, data: Dictionary, footprint: Array) -> void:
	var a: Array = footprint[0]
	var c: Array = footprint[2]
	var x0 := minf(float(a[0]), float(c[0]))
	var x1 := maxf(float(a[0]), float(c[0]))
	var z0 := minf(float(a[1]), float(c[1]))
	var z1 := maxf(float(a[1]), float(c[1]))
	var floor_y := float(data.get("level", 0)) * UPPER_LEVEL_STEP
	var ceiling := maxf(float(data.get("ceiling", 2.4)), 2.2)
	var floor_mat := _surface_material(str(data.get("floor", "")), true)
	var wall_mat := _surface_material(str(data.get("walls", "")), false)
	var ceiling_mat := _surface_material("ceiling", false)

	_box_body(root, "Floor", Vector3((x0 + x1) * 0.5, floor_y - FLOOR_THICKNESS * 0.5, (z0 + z1) * 0.5), Vector3(x1 - x0, FLOOR_THICKNESS, z1 - z0), floor_mat)
	_box_body(root, "Ceiling", Vector3((x0 + x1) * 0.5, floor_y + ceiling + FLOOR_THICKNESS * 0.5, (z0 + z1) * 0.5), Vector3(x1 - x0, FLOOR_THICKNESS, z1 - z0), ceiling_mat)

	var nav_region := NavigationRegion3D.new()
	nav_region.name = "NavigationRegion"
	var nav := NavigationMesh.new()
	nav.vertices = PackedVector3Array([
		Vector3(x0 + 0.2, floor_y + 0.02, z0 + 0.2),
		Vector3(x1 - 0.2, floor_y + 0.02, z0 + 0.2),
		Vector3(x1 - 0.2, floor_y + 0.02, z1 - 0.2),
		Vector3(x0 + 0.2, floor_y + 0.02, z1 - 0.2)
	])
	nav.add_polygon(PackedInt32Array([0, 1, 2, 3]))
	nav_region.navigation_mesh = nav
	root.add_child(nav_region)

	var doors: Array = data.get("doors", [])
	var windows: Array = data.get("windows", [])
	for wall in ["N", "E", "S", "W"]:
		var start := x0 if wall in ["N", "S"] else z0
		var finish := x1 if wall in ["N", "S"] else z1
		var plane := z0 if wall == "N" else (z1 if wall == "S" else (x0 if wall == "W" else x1))
		var openings: Array[Dictionary] = []
		for door_variant in doors:
			var door: Dictionary = door_variant
			if str(door.get("wall", "")) != wall:
				continue
			var kind := str(door.get("kind", "door"))
			var width := maxf(float(door.get("width", 1.0)), 0.0)
			var height := ceiling if kind == "opening" else (DOUBLE_DOOR_HEIGHT if kind == "double" else DEFAULT_DOOR_HEIGHT)
			openings.append({"center": float(door.get("offset", (start + finish) * 0.5)), "width": width, "sill": 0.0, "top": height, "kind": "door", "data": door})
		for window_variant in windows:
			var window: Dictionary = window_variant
			if str(window.get("wall", "")) != wall:
				continue
			var sill := maxf(float(window.get("sill", 0.9)), 0.0)
			var height := maxf(float(window.get("height", 1.2)), 0.1)
			openings.append({"center": float(window.get("offset", (start + finish) * 0.5)), "width": maxf(float(window.get("width", 1.2)), 0.1), "sill": sill, "top": minf(sill + height, ceiling), "kind": "window", "data": window})
		openings.sort_custom(func(left: Dictionary, right: Dictionary) -> bool: return float(left["center"]) < float(right["center"]))
		_build_wall_segments(root, wall, plane, start, finish, floor_y, ceiling, openings, wall_mat)
		_build_trim(root, wall, plane, start, finish, floor_y, ceiling)

	for window_variant in windows:
		var window: Dictionary = window_variant
		var wall := str(window.get("wall", "N"))
		if wall not in ["N", "E", "S", "W"]:
			continue
		var center := float(window.get("offset", 0.0))
		var sill := float(window.get("sill", 0.9))
		var height := float(window.get("height", 1.2))
		var width := float(window.get("width", 1.2))
		var glass := StandardMaterial3D.new()
		glass.albedo_color = Color(0.32, 0.42, 0.47, 0.24)
		glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		glass.roughness = 0.18
		var pos: Vector3
		var size: Vector3
		if wall in ["N", "S"]:
			pos = Vector3(center, floor_y + sill + height * 0.5, plane_for_wall(wall, x0, x1, z0, z1))
			size = Vector3(width, height, 0.035)
		else:
			pos = Vector3(plane_for_wall(wall, x0, x1, z0, z1), floor_y + sill + height * 0.5, center)
			size = Vector3(0.035, height, width)
		var pane := MeshInstance3D.new()
		pane.name = "Window_" + str(window.get("id", "pane"))
		var mesh := BoxMesh.new()
		mesh.size = size
		pane.mesh = mesh
		pane.position = pos
		pane.material_override = glass
		root.add_child(pane)


func plane_for_wall(wall: String, x0: float, x1: float, z0: float, z1: float) -> float:
	return z0 if wall == "N" else (z1 if wall == "S" else (x0 if wall == "W" else x1))


func _build_wall_segments(root: Node3D, wall: String, plane: float, start: float, finish: float, floor_y: float, ceiling: float, openings: Array[Dictionary], material: Material) -> void:
	var cursor := start
	for opening in openings:
		var width := float(opening["width"])
		if width <= 0.0:
			continue
		var left := clampf(float(opening["center"]) - width * 0.5, start, finish)
		var right := clampf(float(opening["center"]) + width * 0.5, start, finish)
		if right <= cursor or right <= left:
			continue
		left = maxf(left, cursor)
		if left > cursor:
			_add_wall_segment(root, wall, plane, cursor, left, floor_y, ceiling, material, "Wall")
		var sill := clampf(float(opening["sill"]), 0.0, ceiling)
		var top := clampf(float(opening["top"]), sill, ceiling)
		if sill > 0.02:
			_add_wall_segment(root, wall, plane, left, right, floor_y, sill, material, "WallBelowOpening")
		if top < ceiling - 0.02:
			_add_wall_segment(root, wall, plane, left, right, floor_y + top, ceiling - top, material, "WallAboveOpening")
		if str(opening["kind"]) == "door":
			var door: Dictionary = opening["data"]
			if door.has("locked_until") and _lock_is_pending(str(door["locked_until"])):
				_create_locked_door(root, wall, plane, float(opening["center"]), width, top, floor_y, door)
		cursor = maxf(cursor, right)
	if cursor < finish:
		_add_wall_segment(root, wall, plane, cursor, finish, floor_y, ceiling, material, "Wall")


func _add_wall_segment(root: Node3D, wall: String, plane: float, start: float, finish: float, base_y: float, height_or_top: float, material: Material, label: String, top_height: float = -1.0) -> void:
	# If top_height is omitted, the sixth argument is the wall height from floor. The explicit
	# base_y/height pair also lets us build the lintel above a door/window opening.
	var segment_base := base_y
	var segment_height := height_or_top
	if top_height >= 0.0:
		segment_base = height_or_top
		segment_height = top_height
	if segment_height <= 0.02 or finish <= start:
		return
	var length := finish - start
	var pos: Vector3
	var size: Vector3
	if wall in ["N", "S"]:
		pos = Vector3((start + finish) * 0.5, segment_base + segment_height * 0.5, plane)
		size = Vector3(length, segment_height, WALL_THICKNESS)
	else:
		pos = Vector3(plane, segment_base + segment_height * 0.5, (start + finish) * 0.5)
		size = Vector3(WALL_THICKNESS, segment_height, length)
	_box_body(root, "%s_%s_%0.1f" % [label, wall, start], pos, size, material)


func _build_trim(root: Node3D, wall: String, plane: float, start: float, finish: float, floor_y: float, ceiling: float) -> void:
	var length := finish - start
	var trim := StandardMaterial3D.new()
	trim.albedo_color = Color(0.24, 0.19, 0.15)
	trim.roughness = 0.82
	var base_pos: Vector3
	var crown_pos: Vector3
	var size: Vector3
	if wall in ["N", "S"]:
		base_pos = Vector3((start + finish) * 0.5, floor_y + 0.075, plane - (WALL_THICKNESS * 0.5 + 0.01))
		crown_pos = Vector3((start + finish) * 0.5, floor_y + ceiling - 0.08, plane - (WALL_THICKNESS * 0.5 + 0.01))
		size = Vector3(length, 0.15, 0.05)
	else:
		base_pos = Vector3(plane - (WALL_THICKNESS * 0.5 + 0.01), floor_y + 0.075, (start + finish) * 0.5)
		crown_pos = Vector3(plane - (WALL_THICKNESS * 0.5 + 0.01), floor_y + ceiling - 0.08, (start + finish) * 0.5)
		size = Vector3(0.05, 0.15, length)
	_box_body(root, "BaseTrim_" + wall, base_pos, size, trim, false)
	_box_body(root, "CrownTrim_" + wall, crown_pos, Vector3(size.x, 0.12, size.z), trim, false)


func _create_locked_door(root: Node3D, wall: String, plane: float, center: float, width: float, height: float, floor_y: float, data: Dictionary) -> void:
	var barrier := StaticBody3D.new()
	barrier.name = "LockedDoor_" + str(data.get("id", data.get("to", "door")))
	barrier.set_meta("locked_until", str(data.get("locked_until", "")))
	barrier.set_meta("to_room", str(data.get("to", "")))
	barrier.set_meta("door_id", str(data.get("id", "")))
	var panel := MeshInstance3D.new()
	panel.name = "DoorPanel"
	var mesh := BoxMesh.new()
	var pos: Vector3
	if wall in ["N", "S"]:
		mesh.size = Vector3(width, height, 0.10)
		pos = Vector3(center, floor_y + height * 0.5, plane)
	else:
		mesh.size = Vector3(0.10, height, width)
		pos = Vector3(plane, floor_y + height * 0.5, center)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.20, 0.13, 0.09)
	material.roughness = 0.72
	panel.mesh = mesh
	panel.material_override = material
	barrier.position = pos
	barrier.add_child(panel)
	var collision := CollisionShape3D.new()
	collision.name = "CollisionShape"
	var shape := BoxShape3D.new()
	shape.size = mesh.size
	collision.shape = shape
	barrier.add_child(collision)
	root.add_child(barrier)
	_locked_doors.append({"body": barrier, "panel": panel, "lock": str(data.get("locked_until", "")), "wall": wall, "width": width})


func _lock_is_pending(lock_id: String) -> bool:
	var parts := lock_id.split(".")
	if parts.size() != 2 or not parts[0].begins_with("act"):
		return true
	var gate_act := int(parts[0].trim_prefix("act"))
	var running_act := current_act_id if current_act_id > 0 else Acts.current_id
	return running_act <= gate_act


func _on_beat_completed(act: int, beat: String) -> void:
	var target := "act%d.%s" % [act, beat]
	for entry in _locked_doors:
		if str(entry["lock"]) != target:
			continue
		var body: StaticBody3D = entry["body"]
		var panel: MeshInstance3D = entry["panel"]
		if not is_instance_valid(body) or not is_instance_valid(panel):
			continue
		for child in body.get_children():
			if child is CollisionShape3D:
				(child as CollisionShape3D).set_deferred("disabled", true)
		var amount := float(entry["width"]) * 0.8
		var shift := Vector3(amount, 0.0, 0.0) if str(entry["wall"]) in ["N", "S"] else Vector3(0.0, 0.0, amount)
		var tween := create_tween()
		tween.tween_property(panel, "position", panel.position + shift, 0.65)
		entry["lock"] = ""


func _build_props(root: Node3D, data: Dictionary) -> void:
	for prop_variant in data.get("props", []):
		if not prop_variant is Dictionary:
			continue
		var prop: Dictionary = prop_variant
		var kind := str(prop.get("kind", "box"))
		var asset_path := str(prop.get("path", ""))
		if asset_path.is_empty():
			asset_path = "res://assets/models/%s.glb" % kind
		var instance := AssetCatalogScript.instantiate_or_fallback(asset_path, kind)
		instance.name = "Prop_" + kind
		var p: Array = prop.get("pos", [0.0, 0.0, 0.0])
		if p.size() >= 3:
			instance.position = Vector3(float(p[0]), float(p[1]), float(p[2]))
		var rotation_value: Variant = prop.get("rot", 0.0)
		if rotation_value is Array and (rotation_value as Array).size() >= 3:
			var r: Array = rotation_value
			instance.rotation_degrees = Vector3(float(r[0]), float(r[1]), float(r[2]))
		else:
			instance.rotation_degrees.y = float(rotation_value)
		if prop.has("wrong_id"):
			instance.set_meta("wrong_id", str(prop["wrong_id"]))
		instance.set_meta("placeholder", str(instance.name).begins_with("Placeholder_"))
		root.add_child(instance)


func _build_frame_pad(root: Node3D, data: Dictionary) -> void:
	# Road and exterior set-pieces have path-specific geometry; this pad is only a safe visible fallback.
	root.name = "PlaceholderFrame_" + str(data.get("id", "unknown"))
	root.set_meta("placeholder_frame", true)
	var material := _surface_material(str(data.get("floor", "ground")), true)
	_box_body(root, "PlaceholderGround", Vector3(0.0, -0.1, 0.0), Vector3(20.0, 0.2, 20.0), material)


func _box_body(parent: Node3D, node_name: String, pos: Vector3, size: Vector3, material: Material, with_collision: bool = true) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = pos
	body.set_meta("placeholder_geometry", true)
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "Mesh"
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.material_override = material
	body.add_child(mesh_instance)
	if with_collision:
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		collision.shape = shape
		collision.name = "CollisionShape"
		body.add_child(collision)
	parent.add_child(body)
	return body


func _surface_material(surface_id: String, is_floor: bool) -> StandardMaterial3D:
	var key := surface_id.to_lower()
	var color := Color(0.36, 0.32, 0.28)
	if "oak" in key or "wood" in key or "board" in key or "panel" in key:
		color = Color(0.28, 0.20, 0.14) if is_floor else Color(0.35, 0.29, 0.23)
	elif "marble" in key or "stone" in key or "tile" in key:
		color = Color(0.40, 0.39, 0.36) if is_floor else Color(0.62, 0.59, 0.52)
	elif "dirt" in key or "grass" in key or "ground" in key:
		color = Color(0.20, 0.19, 0.13) if is_floor else Color(0.30, 0.28, 0.23)
	elif "linoleum" in key:
		color = Color(0.42, 0.40, 0.34)
	elif "plaster" in key or "paper" in key or "ceiling" in key:
		color = Color(0.55, 0.51, 0.43)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.86
	return mat
