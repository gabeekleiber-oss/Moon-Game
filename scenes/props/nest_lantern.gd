class_name NestLantern
extends Node3D
## The Ch6 bird-nest lantern (F-10): a hanging hub with `arms` (default 12, CANON: twelve bird-nest arms) curved arms, each holding a small
## BirdNest with glowing eggs. Hangs from y=0 downward. `set_lit(on)` toggles egg glow + the warm OmniLight3D; `nests()` returns the BirdNest nodes;
## `arm_count()` the number of arms. `sway(amount)` gives a slow swing (set 0 to stop).

@export_range(3, 24) var arms: int = 12
@export var radius: float = 1.0
@export var lit: bool = true

var _nests: Array[BirdNest] = []
var _light: OmniLight3D
var _body: Node3D
var _sway_tween: Tween


func _ready() -> void:
	_build()


## Number of arms (== nests).
func arm_count() -> int:
	return _nests.size()


## The nest nodes, one per arm.
func nests() -> Array[BirdNest]:
	return _nests


## Turn the warm light and glowing eggs on or off.
func set_lit(on: bool) -> void:
	lit = on
	if _light != null:
		_light.visible = on
	for n in _nests:
		for c in n.get_children():
			var mi := c as MeshInstance3D
			if mi != null and mi.name.begins_with("Egg"):
				var m := mi.material_override as StandardMaterial3D
				m.emission_energy_multiplier = 2.2 if on else 0.0


## Swing gently (radians). 0 stops.
func sway(amount: float = 0.05, period: float = 4.0) -> void:
	if _sway_tween != null and _sway_tween.is_valid():
		_sway_tween.kill()
	if amount <= 0.0:
		_body.rotation = Vector3.ZERO
		return
	_sway_tween = create_tween().set_loops()
	_sway_tween.tween_property(_body, "rotation:x", amount, period * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_sway_tween.tween_property(_body, "rotation:x", -amount, period * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _build() -> void:
	_body = Node3D.new()
	_body.name = "Body"
	add_child(_body)
	var iron := PropUtil.mat(Color(0.18, 0.14, 0.1), 0.7, 0.5)
	var chain := CylinderMesh.new()
	chain.top_radius = 0.02
	chain.bottom_radius = 0.02
	chain.height = 0.8
	PropUtil.add_mesh(_body, chain, iron, Vector3(0, -0.4, 0), "Chain")
	var hub := SphereMesh.new()
	hub.radius = 0.16
	hub.height = 0.32
	var hub_y := -0.95
	PropUtil.add_mesh(_body, hub, iron, Vector3(0, hub_y, 0), "Hub")
	for i in arms:
		var ang := TAU * float(i) / arms
		var dir := Vector3(cos(ang), 0, sin(ang))
		var tip_h := 0.15 + 0.12 * float(i % 2)          # alternate heights so nests do not collide
		var start := Vector3(0, hub_y, 0) + dir * 0.1
		var tip := Vector3(0, hub_y - 0.1 + tip_h, 0) + dir * radius
		var ctrl := Vector3(0, hub_y - 0.3, 0) + dir * radius * 0.65
		var pts := PropUtil.bezier(start, ctrl, tip, 10)
		PropUtil.add_mesh(_body, PropUtil.tube(pts, 0.022, 6, 0.014), iron, Vector3.ZERO, "Arm%d" % i)
		var nest := BirdNest.new()
		nest.radius = 0.13
		nest.eggs = 1 + (i % 3)
		nest.seed_value = 100 + i
		nest.glowing_eggs = true
		nest.position = tip + Vector3(0, 0.01, 0)
		_body.add_child(nest)
		_nests.append(nest)
	_light = OmniLight3D.new()
	_light.name = "Glow"
	_light.position = Vector3(0, hub_y + 0.25, 0)
	_light.light_color = Color(1.0, 0.8, 0.5)
	_light.light_energy = 1.4
	_light.omni_range = 6.0
	_light.shadow_enabled = false
	_body.add_child(_light)
	set_lit(lit)
