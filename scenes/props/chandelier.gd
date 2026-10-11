class_name Chandelier
extends Node3D
## Reusable chandelier prop (F-10). Hangs from y=0 (the ceiling point) down by `drop` metres; build by `add_child(Chandelier.new())`
## after setting exports. Variants: BRASS (gold), RUBY (red, the "wrong reality" colour) and MILKY (pale glass).
## `arms` (>=3, default 8) curved tube arms each end in a candle; crystals hang from every arm and the lower ring (one MultiMesh).
## `lit` adds a warm OmniLight3D (no shadows) and glowing flames. `sway(amount)` gives a gentle swing; `set_lit(on)` toggles at runtime.
## Chapter 9 can `duck` under these; the collision-free visual only. Add your own StaticBody if needed.

enum Variant { BRASS, RUBY, MILKY }

@export var variant: Variant = Variant.BRASS
@export_range(3, 24) var arms: int = 8
@export var radius: float = 0.9
@export var drop: float = 1.1
@export var lit: bool = true
@export var crystals_per_arm: int = 4

var _flames: Array[MeshInstance3D] = []
var _light: OmniLight3D
var _body: Node3D
var _flame_mat: StandardMaterial3D
var _sway_tween: Tween


func _ready() -> void:
	_build()


## Turn candle flames and light on/off.
func set_lit(on: bool) -> void:
	lit = on
	if _light != null:
		_light.visible = on
	if _flame_mat != null:
		_flame_mat.emission_energy_multiplier = 3.0 if on else 0.0


## Swing gently around the hanging point (radians). amount 0 stops it.
func sway(amount: float = 0.06, period: float = 3.0) -> void:
	if _sway_tween != null and _sway_tween.is_valid():
		_sway_tween.kill()
	if amount <= 0.0:
		_body.rotation = Vector3.ZERO
		return
	_sway_tween = create_tween().set_loops()
	_sway_tween.tween_property(_body, "rotation:z", amount, period * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_sway_tween.tween_property(_body, "rotation:z", -amount, period * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


## Number of candle holders (== arms).
func candle_count() -> int:
	return _flames.size()


func _palette() -> Dictionary:
	match variant:
		Variant.RUBY:
			return {"metal": PropUtil.mat(Color(0.45, 0.04, 0.07), 0.85, 0.3), "crystal": Color(0.9, 0.1, 0.18, 0.78), "light": Color(1.0, 0.45, 0.4)}
		Variant.MILKY:
			return {"metal": PropUtil.mat(Color(0.93, 0.92, 0.88), 0.2, 0.25), "crystal": Color(0.95, 0.96, 1.0, 0.7), "light": Color(0.85, 0.9, 1.0)}
		_:
			return {"metal": PropUtil.mat(Color(0.83, 0.62, 0.22), 0.95, 0.28), "crystal": Color(1.0, 0.97, 0.88, 0.55), "light": Color(1.0, 0.8, 0.5)}


func _build() -> void:
	var pal := _palette()
	var metal: StandardMaterial3D = pal["metal"]
	_body = Node3D.new()
	_body.name = "Body"
	add_child(_body)
	# chain + canopy
	PropUtil.add_mesh(_body, _cyl(0.02, 0.02, 0.5), metal, Vector3(0, -0.25, 0), "Chain")
	PropUtil.add_mesh(_body, _cyl(0.12, 0.05, 0.08), metal, Vector3(0, -0.02, 0), "Canopy")
	var top_y := -0.5
	# central column: stacked beads
	var y := top_y
	for i in 3:
		var s := SphereMesh.new()
		s.radius = 0.11 - i * 0.015
		s.height = s.radius * 2.0
		PropUtil.add_mesh(_body, s, metal, Vector3(0, y - 0.08, 0), "Bead%d" % i)
		y -= 0.17
	var ring_y := y - 0.02
	var finial := SphereMesh.new()
	finial.radius = 0.06
	finial.height = 0.12
	PropUtil.add_mesh(_body, finial, metal, Vector3(0, ring_y - 0.1, 0), "Finial")
	# lower ring
	var ring := TorusMesh.new()
	ring.inner_radius = radius * 0.34
	ring.outer_radius = radius * 0.38
	PropUtil.add_mesh(_body, ring, metal, Vector3(0, ring_y, 0), "Ring")
	# arms + candles
	var cup_mesh := _cyl(0.05, 0.03, 0.05)
	var candle_mesh := _cyl(0.022, 0.022, 0.16)
	var flame := SphereMesh.new()
	flame.radius = 0.028
	flame.height = 0.08
	_flame_mat = PropUtil.mat(Color(1, 0.85, 0.5), 0.0, 0.5, Color(1.0, 0.7, 0.3), 3.0 if lit else 0.0)
	var drops: Array[Transform3D] = []
	for i in arms:
		var ang := TAU * float(i) / arms
		var dir := Vector3(cos(ang), 0, sin(ang))
		var start := Vector3(0, ring_y + 0.02, 0) + dir * 0.06
		var tip := Vector3(0, ring_y + 0.22, 0) + dir * radius
		var ctrl := Vector3(0, ring_y - 0.18, 0) + dir * radius * 0.7
		var pts := PropUtil.bezier(start, ctrl, tip, 12)
		var arm := PropUtil.add_mesh(_body, PropUtil.tube(pts, 0.022, 6, 0.016), metal, Vector3.ZERO, "Arm%d" % i)
		arm.set_meta("arm", true)
		PropUtil.add_mesh(_body, cup_mesh, metal, tip + Vector3(0, 0.025, 0), "Cup%d" % i)
		PropUtil.add_mesh(_body, candle_mesh, PropUtil.mat(Color(0.95, 0.92, 0.82), 0.0, 0.8), tip + Vector3(0, 0.13, 0), "Candle%d" % i)
		var f := PropUtil.add_mesh(_body, flame, _flame_mat, tip + Vector3(0, 0.25, 0), "Flame%d" % i)
		f.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_flames.append(f)
		for c in crystals_per_arm:
			var t := (c + 1.0) / (crystals_per_arm + 1.0)
			var p := pts[int(t * (pts.size() - 1))]
			drops.append(Transform3D(Basis.IDENTITY, p + Vector3(0, -0.07, 0)))
	# ring crystals
	var ring_n := arms * 2
	for i in ring_n:
		var a := TAU * float(i) / ring_n
		drops.append(Transform3D(Basis.IDENTITY.scaled(Vector3(1.4, 1.4, 1.4)), Vector3(cos(a), 0, sin(a)) * radius * 0.36 + Vector3(0, ring_y - 0.11, 0)))
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = PropUtil.drop_mesh(0.12, 0.028)
	mm.instance_count = drops.size()
	for i in drops.size():
		mm.set_instance_transform(i, drops[i])
	var cm := StandardMaterial3D.new()
	cm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cm.albedo_color = pal["crystal"]
	cm.roughness = 0.04
	cm.metallic_specular = 1.0
	cm.emission_enabled = true
	cm.emission = (pal["crystal"] as Color)
	cm.emission_energy_multiplier = 0.25
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "Crystals"
	mmi.multimesh = mm
	mmi.material_override = cm
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_body.add_child(mmi)
	# light
	_light = OmniLight3D.new()
	_light.name = "Glow"
	_light.position = Vector3(0, ring_y + 0.2, 0)
	_light.light_color = pal["light"]
	_light.light_energy = 1.6
	_light.omni_range = 7.0
	_light.shadow_enabled = false
	_light.visible = lit
	_body.add_child(_light)


func _cyl(top: float, bottom: float, h: float) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = top
	c.bottom_radius = bottom
	c.height = h
	c.radial_segments = 12
	return c
