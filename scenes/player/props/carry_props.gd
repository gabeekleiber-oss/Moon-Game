class_name CarryProps
extends RefCounted
## Code-built placeholder carryables (broom, axe, pot, Mary Sue proxy) so room scenes can drop them in
## and wire story beats before real models exist. PLACEHOLDER: swap meshes, keep ids/weights.

const CarryableScript = preload("res://scenes/player/carryable.gd")

## Weights and hold poses per kind. Weight slows the player (see CarryController).
const KINDS := {
	"broom": {"weight": 0.8, "size": Vector3(0.05, 1.4, 0.05), "color": Color(0.45, 0.33, 0.2), "hold": Vector3(0.3, -0.2, -0.7), "rot": Vector3(-20, 0, 8), "prompt": "Take the broom"},
	"axe": {"weight": 2.0, "size": Vector3(0.12, 0.9, 0.05), "color": Color(0.3, 0.25, 0.2), "hold": Vector3(0.3, -0.3, -0.7), "rot": Vector3(-30, 0, 10), "prompt": "Take the axe"},
	"pot": {"weight": 6.0, "size": Vector3(0.9, 0.9, 0.9), "color": Color(0.22, 0.22, 0.24), "hold": Vector3(0.0, -0.55, -0.9), "rot": Vector3.ZERO, "prompt": "Lift the pot"},
	"mary_sue": {"weight": 4.0, "size": Vector3(0.4, 1.3, 0.25), "color": Color(0.6, 0.5, 0.5), "hold": Vector3(0.1, -0.5, -0.8), "rot": Vector3(-70, 0, 0), "prompt": "Pick her up"},
}


## Returns a ready Carryable of the given kind ("broom", "axe", "pot", "mary_sue") or null if unknown.
static func make(kind: String) -> Carryable:
	if not KINDS.has(kind):
		return null
	var def: Dictionary = KINDS[kind]
	var item: Carryable = CarryableScript.new()
	item.name = kind.capitalize().replace(" ", "")
	item.prompt = def["prompt"]
	item.carry_weight = def["weight"]
	item.hold_offset = def["hold"]
	item.hold_rotation_degrees = def["rot"]
	var size: Vector3 = def["size"]
	var mesh := MeshInstance3D.new()
	if kind == "pot":
		var cyl := CylinderMesh.new()
		cyl.top_radius = size.x * 0.5
		cyl.bottom_radius = size.x * 0.4
		cyl.height = size.y
		mesh.mesh = cyl
	else:
		var box := BoxMesh.new()
		box.size = size
		mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = def["color"]
	mat.roughness = 0.85
	mesh.material_override = mat
	item.add_child(mesh)
	var shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = size
	shape.shape = box_shape
	item.add_child(shape)
	return item
