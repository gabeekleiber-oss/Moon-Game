class_name Armor
extends Node3D
## Suit of armour on a plinth (F-10) for the Military Gallery (Ch10). Standing on y=0 (plinth is just below), about 1.85 m tall, faces local +Z.
## Built from 16 named pieces (`piece_count()`): Plinth, SabatonL/R, GreaveL/R, Tassets, Breastplate, Gorget, PauldronL/R, VambraceL/R,
## GauntletL/R, Helm, Plume. `halberd` adds a 17th. Exports: `finish` (STEEL, BLACK, BRASS), `pose` (REST, SALUTE, GUARD), `plume_color`.
## `set_pose(p)` changes arms at runtime. `piece_names()` lists them (Notepad rows can count them).

enum Finish { STEEL, BLACK, BRASS }
enum Pose { REST, SALUTE, GUARD }

@export var finish: Finish = Finish.STEEL
@export var pose: Pose = Pose.REST
@export var halberd: bool = false
@export var plume_color: Color = Color(0.75, 0.1, 0.12)

var _metal: StandardMaterial3D
var _pieces: Array[Node3D] = []
var _arm_l: Node3D
var _arm_r: Node3D


func _ready() -> void:
	_build()
	set_pose(pose)


## Number of separate named armour pieces.
func piece_count() -> int:
	return _pieces.size()


## Names of all pieces, in build order.
func piece_names() -> PackedStringArray:
	var out := PackedStringArray()
	for p in _pieces:
		out.append(p.name)
	return out


## Set the arm pose (REST, SALUTE with right arm raised, GUARD with both arms forward).
func set_pose(p: Pose) -> void:
	pose = p
	if _arm_l == null:
		return
	match p:
		Pose.SALUTE:
			_arm_l.rotation = Vector3(0, 0, deg_to_rad(8))
			_arm_r.rotation = Vector3(deg_to_rad(-150), 0, deg_to_rad(-10))
		Pose.GUARD:
			_arm_l.rotation = Vector3(deg_to_rad(-55), 0, deg_to_rad(10))
			_arm_r.rotation = Vector3(deg_to_rad(-55), 0, deg_to_rad(-10))
		_:
			_arm_l.rotation = Vector3(0, 0, deg_to_rad(6))
			_arm_r.rotation = Vector3(0, 0, deg_to_rad(-6))


func _build() -> void:
	match finish:
		Finish.BLACK: _metal = PropUtil.mat(Color(0.2, 0.2, 0.26), 0.55, 0.4)
		Finish.BRASS: _metal = PropUtil.mat(Color(0.8, 0.6, 0.22), 0.95, 0.3)
		_: _metal = PropUtil.mat(Color(0.72, 0.74, 0.78), 0.95, 0.28)
	var dark := PropUtil.mat(Color(0.08, 0.07, 0.07), 0.3, 0.8)

	var plinth := _piece("Plinth")
	PropUtil.add_mesh(plinth, _box(0.8, 0.12, 0.8), PropUtil.mat(Color(0.28, 0.2, 0.16), 0.0, 0.7), Vector3(0, -0.06, 0))
	for sx in [-1.0, 1.0]:
		var side := "L" if sx < 0 else "R"
		var x: float = sx * 0.11
		# sabaton (foot) + greave (shin+knee)
		var sab := _piece("Sabaton" + side)
		PropUtil.add_mesh(sab, _box(0.12, 0.07, 0.3), _metal, Vector3(x, 0.035, 0.05))
		var gr := _piece("Greave" + side)
		PropUtil.add_mesh(gr, _cyl(0.07, 0.055, 0.4), _metal, Vector3(x, 0.3, 0))
		PropUtil.add_mesh(gr, _sph(0.075), _metal, Vector3(x, 0.52, 0.02))
	var tas := _piece("Tassets")
	PropUtil.add_mesh(tas, _cyl(0.2, 0.17, 0.36), _metal, Vector3(0, 0.72, 0))
	for i in 3:
		PropUtil.add_mesh(tas, _box(0.34 - i * 0.02, 0.05, 0.22), _metal, Vector3(0, 0.88 - i * 0.07, 0.02))
	var bp := _piece("Breastplate")
	var chest := _sph(0.22)
	PropUtil.add_mesh(bp, chest, _metal, Vector3(0, 1.2, 0)).scale = Vector3(1.1, 1.25, 0.8)
	PropUtil.add_mesh(bp, _cyl(0.17, 0.2, 0.3), _metal, Vector3(0, 1.0, 0))
	var gor := _piece("Gorget")
	PropUtil.add_mesh(gor, _cyl(0.1, 0.13, 0.1), _metal, Vector3(0, 1.5, 0))
	var helm := _piece("Helm")
	PropUtil.add_mesh(helm, _sph(0.14), _metal, Vector3(0, 1.66, 0)).scale = Vector3(1.0, 1.15, 1.1)
	PropUtil.add_mesh(helm, _box(0.22, 0.03, 0.04), dark, Vector3(0, 1.67, 0.145))
	PropUtil.add_mesh(helm, _box(0.03, 0.12, 0.05), _metal, Vector3(0, 1.62, 0.15))
	var plume := _piece("Plume")
	PropUtil.add_mesh(plume, _sph(0.06), PropUtil.mat(plume_color, 0.0, 0.9), Vector3(0, 1.84, -0.02)).scale = Vector3(0.7, 1.7, 2.4)
	for sx in [-1.0, 1.0]:
		var side := "L" if sx < 0 else "R"
		var pivot := Node3D.new()
		pivot.name = "ArmPivot" + side
		pivot.position = Vector3(sx * 0.29, 1.4, 0)
		add_child(pivot)
		var pa := _piece("Pauldron" + side, pivot)
		PropUtil.add_mesh(pa, _sph(0.11), _metal, Vector3(sx * 0.02, 0.0, 0)).scale = Vector3(1.2, 0.8, 1.1)
		var vb := _piece("Vambrace" + side, pivot)
		PropUtil.add_mesh(vb, _cyl(0.055, 0.045, 0.3), _metal, Vector3(0, -0.2, 0))
		PropUtil.add_mesh(vb, _sph(0.055), _metal, Vector3(0, -0.36, 0))
		var ga := _piece("Gauntlet" + side, pivot)
		PropUtil.add_mesh(ga, _box(0.07, 0.12, 0.05), _metal, Vector3(0, -0.5, 0))
		if sx < 0:
			_arm_l = pivot
		else:
			_arm_r = pivot
	if halberd:
		var h := _piece("Halberd")
		PropUtil.add_mesh(h, _cyl(0.015, 0.015, 2.1), PropUtil.mat(Color(0.3, 0.2, 0.12), 0.0, 0.8), Vector3(0.38, 1.0, 0.12))
		PropUtil.add_mesh(h, _box(0.16, 0.2, 0.012), _metal, Vector3(0.45, 2.0, 0.12))
		PropUtil.add_mesh(h, _cyl(0.0, 0.025, 0.2), _metal, Vector3(0.38, 2.15, 0.12))


func _piece(piece_name: String, parent: Node3D = null) -> Node3D:
	var n := Node3D.new()
	n.name = piece_name
	(parent if parent != null else self).add_child(n)
	_pieces.append(n)
	return n


func _box(x: float, y: float, z: float) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = Vector3(x, y, z)
	return b


func _sph(r: float) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	s.radial_segments = 20
	s.rings = 10
	return s


func _cyl(top: float, bottom: float, h: float) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = top
	c.bottom_radius = bottom
	c.height = h
	c.radial_segments = 16
	return c
