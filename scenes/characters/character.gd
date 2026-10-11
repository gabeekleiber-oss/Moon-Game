class_name Character
extends Node3D
## Base class for every humanoid in the kit (Elsa Ray, Mary Sue, Frank, Sweaty Man, gold statues). (F-12)
##
## Builds a simple humanoid from primitives in _ready (faces local +Z, feet on y = 0) and gives it a swappable
## face: `set_expression("glare")`, `expressions()`. Subclasses override `_style()` (sizes/colours) and `_decorate()`
## (hats, robes, props). Parts are named children (`part(name)`, `piece_names()`).
## Style keys: height (m), build (1 = average), skin, shirt, pants, shoes, hair (Color or null), hair_style
## ("cap", "long", "none"), eye_color, brow_color, mouth_color, lash, head_scale, face (bool, default true).

## Emitted after the face changed.
signal expression_changed(expr: String)

## Current expression (one of FaceAtlas.EXPRESSIONS). Setting it at runtime swaps the face.
@export var expression: String = "neutral":
	set(v):
		expression = v
		if _face_mat != null:
			_apply_expression()

var _parts: Dictionary = {}
var _order: Array[String] = []
var _face_mat: StandardMaterial3D
var _head_r: float = 0.11
var _height: float = 1.7
var _glare_serial: int = 0


func _ready() -> void:
	var s := _base_style()
	s.merge(_style(), true)
	_height = float(s["height"])
	_build_body(s)
	_decorate(s)
	if _face_mat != null:
		_apply_expression()


## Override: return the style keys that differ from the defaults.
func _style() -> Dictionary:
	return {}


## Override: add hats, props, clothing details after the body exists.
func _decorate(_s: Dictionary) -> void:
	pass


## All expression names this character can show.
func expressions() -> Array[String]:
	return FaceAtlas.EXPRESSIONS


## Swaps the face to `expr`. Unknown names are ignored with a warning.
func set_expression(expr: String) -> void:
	if not FaceAtlas.has(expr):
		push_warning("Character: unknown expression '%s'" % expr)
		return
	expression = expr
	expression_changed.emit(expr)


## Shows "glare" for `seconds` (Elsa's signature is half a second), then returns to the previous expression.
func glare(seconds: float = 0.5) -> void:
	var back := expression
	_glare_serial += 1
	var mine := _glare_serial
	set_expression("glare")
	await get_tree().create_timer(seconds).timeout
	if mine == _glare_serial and is_inside_tree():
		set_expression(back)


## Turns the character (yaw only) to face a world point.
func face_toward(point: Vector3) -> void:
	var d := point - global_position
	if Vector2(d.x, d.z).length() > 0.001:
		rotation.y = atan2(d.x, d.z)


## Returns a named body part (Head, Torso, ArmL, ...), or null.
func part(part_name: String) -> Node3D:
	return _parts.get(part_name) as Node3D


## Names of all parts in build order.
func piece_names() -> Array[String]:
	return _order


## Number of named parts.
func piece_count() -> int:
	return _order.size()


## Standing height in metres (before any decoration such as hats).
func height_m() -> float:
	return _height


# ------------------------------------------------------------------ building

func _base_style() -> Dictionary:
	return {"height": 1.7, "build": 1.0, "skin": Color(0.93, 0.76, 0.64), "shirt": Color(0.45, 0.5, 0.6),
		"pants": Color(0.2, 0.22, 0.3), "shoes": Color(0.12, 0.1, 0.1), "hair": Color(0.25, 0.17, 0.1),
		"hair_style": "cap", "eye_color": Color(0.32, 0.22, 0.14), "brow_color": Color(0.16, 0.11, 0.08),
		"mouth_color": Color(0.45, 0.14, 0.14), "lash": false, "head_scale": 1.0, "face": true, "legs": true}


func _build_body(s: Dictionary) -> void:
	var h := _height
	var b: float = s["build"]
	var skin: StandardMaterial3D = PropUtil.mat(s["skin"], 0.0, 0.8)
	var shirt: StandardMaterial3D = PropUtil.mat(s["shirt"], 0.0, 0.85)
	var pants: StandardMaterial3D = PropUtil.mat(s["pants"], 0.0, 0.85)
	var shoes: StandardMaterial3D = PropUtil.mat(s["shoes"], 0.0, 0.7)
	var leg_len := 0.46 * h
	var torso_len := 0.30 * h
	var torso_r := 0.085 * h * b
	_head_r = 0.065 * h * float(s["head_scale"])

	if s["legs"]:
		for side in [-1, 1]:
			var sx: float = float(side) * torso_r * 0.55
			_part("Leg" + ("L" if side < 0 else "R"), _capsule(0.045 * h * b, leg_len), pants, Vector3(sx, leg_len * 0.5 + 0.03 * h, 0))
			_part("Foot" + ("L" if side < 0 else "R"), _box_mesh(Vector3(0.07 * h * b, 0.035 * h, 0.14 * h)), shoes, Vector3(sx, 0.0175 * h, 0.025 * h))
	_part("Torso", _capsule(torso_r, torso_len), shirt, Vector3(0, leg_len + 0.03 * h + torso_len * 0.5 - 0.01 * h, 0))
	_part("Neck", _cyl(0.032 * h, 0.05 * h), skin, Vector3(0, leg_len + torso_len + 0.04 * h, 0))
	var head_y := leg_len + torso_len + 0.06 * h + _head_r * 0.9
	_part("Head", _sphere(_head_r), skin, Vector3(0, head_y, 0))
	for side in [-1, 1]:
		var shoulder := Vector3(side * (torso_r + 0.025 * h), leg_len + torso_len * 0.92, 0)
		var n: String = "L" if side < 0 else "R"
		_part("Arm" + n, _capsule(0.03 * h * b, 0.28 * h), shirt, shoulder + Vector3(0, -0.14 * h, 0))
		_part("Hand" + n, _sphere(0.03 * h), skin, shoulder + Vector3(0, -0.3 * h, 0))
	var hair: Variant = s["hair"]
	var style: String = s["hair_style"]
	if hair is Color and style != "none":
		var hm := PropUtil.mat(hair, 0.0, 0.9)
		if style == "long":
			_part("Hair", _sphere(_head_r * 1.08), hm, Vector3(0, head_y + _head_r * 0.08, -_head_r * 0.12))
			_part("HairBack", _capsule(_head_r * 0.9, _head_r * 3.6), hm, Vector3(0, head_y - _head_r * 1.2, -_head_r * 0.45))
		else:
			_part("Hair", _sphere(_head_r * 1.06), hm, Vector3(0, head_y + _head_r * 0.12, -_head_r * 0.1))
	if s["face"]:
		_build_face(s, head_y)


func _build_face(s: Dictionary, head_y: float) -> void:
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE * _head_r * 1.7
	_face_mat = StandardMaterial3D.new()
	_face_mat.albedo_texture = FaceAtlas.build({"eye_color": s["eye_color"], "brow_color": s["brow_color"],
		"mouth_color": s["mouth_color"], "lash": s["lash"]})
	_face_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_face_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	_face_mat.roughness = 0.9
	_face_mat.cull_mode = BaseMaterial3D.CULL_BACK
	_part("Face", quad, _face_mat, Vector3(0, head_y - _head_r * 0.05, _head_r * 0.93))


func _apply_expression() -> void:
	var r := FaceAtlas.cell_uv(expression)
	_face_mat.uv1_scale = Vector3(r.size.x, r.size.y, 1.0)
	_face_mat.uv1_offset = Vector3(r.position.x, r.position.y, 0.0)


func _part(part_name: String, mesh: Mesh, mat: Material, pos: Vector3) -> MeshInstance3D:
	var mi := PropUtil.add_mesh(self, mesh, mat, pos, part_name)
	_parts[part_name] = mi
	_order.append(part_name)
	return mi


func _capsule(radius: float, length: float) -> CapsuleMesh:
	var m := CapsuleMesh.new()
	m.radius = radius
	m.height = maxf(length, radius * 2.0 + 0.001)
	return m


func _sphere(radius: float) -> SphereMesh:
	var m := SphereMesh.new()
	m.radius = radius
	m.height = radius * 2.0
	return m


func _cyl(radius: float, length: float) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius = radius
	m.bottom_radius = radius
	m.height = length
	return m


func _box_mesh(size: Vector3) -> BoxMesh:
	var m := BoxMesh.new()
	m.size = size
	return m
