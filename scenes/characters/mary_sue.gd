class_name MarySue
extends Character
## Mary Sue (F-12): turning 13, shimmering gold hair, and the gold-speckled cone hat Elsa Ray gives her. ~1.52 m.
## `set_hat(false)` hides the hat (and its speckles) for scenes before the party. Parts: Hat, HatSpeckles (a MultiMesh of gold dots).
## Hat base colour and clothing are assumed (the story only says gold-speckled cone hat).

const HAT_HEIGHT := 0.3
const HAT_RADIUS := 0.1
const SPECKLES := 48

var _hat: MeshInstance3D
var _speckles: MultiMeshInstance3D


func _style() -> Dictionary:
	return {"height": 1.52, "build": 0.85, "head_scale": 1.12, "skin": Color(0.96, 0.81, 0.70),
		"shirt": Color(0.55, 0.7, 0.85), "pants": Color(0.28, 0.3, 0.5), "hair": Color(0.96, 0.78, 0.22),
		"hair_style": "long", "eye_color": Color(0.35, 0.25, 0.15), "lash": true}


## Shows or hides the party hat.
func set_hat(on: bool) -> void:
	if _hat != null:
		_hat.visible = on
		_speckles.visible = on


## True if the hat is currently shown.
func hat_visible() -> bool:
	return _hat != null and _hat.visible


func _decorate(_s: Dictionary) -> void:
	var head := part("Head") as Node3D
	var top := head.position + Vector3(0, _head_r * 0.82, -_head_r * 0.05)
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = HAT_RADIUS
	cone.height = HAT_HEIGHT
	_hat = PropUtil.add_mesh(self, cone, PropUtil.mat(Color(0.97, 0.93, 0.82), 0.0, 0.7), top + Vector3(0, HAT_HEIGHT * 0.5, 0), "Hat")
	_hat.rotation_degrees = Vector3(-6, 0, 0)
	_parts["Hat"] = _hat
	_order.append("Hat")

	var dot := SphereMesh.new()
	dot.radius = 0.007
	dot.height = 0.014
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = dot
	mm.instance_count = SPECKLES
	var rng := RandomNumberGenerator.new()
	rng.seed = 13                                   # deterministic speckles
	for i in SPECKLES:
		var t := rng.randf_range(0.06, 0.94)         # 0 = base, 1 = tip
		var ang := rng.randf() * TAU
		var r := HAT_RADIUS * (1.0 - t) + 0.004
		mm.set_instance_transform(i, Transform3D(Basis.IDENTITY, Vector3(cos(ang) * r, (t - 0.5) * HAT_HEIGHT, sin(ang) * r)))
	_speckles = MultiMeshInstance3D.new()
	_speckles.name = "HatSpeckles"
	_speckles.multimesh = mm
	_speckles.material_override = PropUtil.mat(Color(1.0, 0.82, 0.25), 0.9, 0.25, Color(1.0, 0.75, 0.2), 0.4)
	_hat.add_child(_speckles)
	_parts["HatSpeckles"] = _speckles
	_order.append("HatSpeckles")
