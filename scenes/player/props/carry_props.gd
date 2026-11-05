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
	_swap_in_model(item, mesh, kind, size)
	var shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = size
	shape.shape = box_shape
	item.add_child(shape)
	return item


## Fetched CC0 models that replace the placeholder box visuals (collision and carry behaviour stay on the box).
const MODELS := {
	"broom": "res://assets/models/props/broom/wooden_broom/wooden_broom_1k.gltf",
}


## If a model exists for `kind`, stands it up along Y, scales it to the box height and centres it on the box; hides the box mesh.
static func _swap_in_model(item: Node3D, placeholder: MeshInstance3D, kind: String, size: Vector3) -> void:
	var path: String = MODELS.get(kind, "")
	if path == "" or not ResourceLoader.exists(path):
		return
	var packed := load(path) as PackedScene
	var inst := packed.instantiate() as Node3D if packed != null else null
	if inst == null:
		return
	var wrapper := Node3D.new()
	wrapper.name = "Model"
	wrapper.add_child(inst)
	var raw := _aabb(inst, Transform3D.IDENTITY)
	if raw.size == Vector3.ZERO:
		wrapper.free()
		return
	if raw.size.x >= raw.size.y and raw.size.x >= raw.size.z:
		inst.rotation.z = PI * 0.5
	elif raw.size.z >= raw.size.y and raw.size.z >= raw.size.x:
		inst.rotation.x = -PI * 0.5
	var box := _aabb(wrapper, Transform3D.IDENTITY)
	var k := size.y / box.size.y
	wrapper.scale = Vector3.ONE * k
	wrapper.position = -(box.position + box.size * 0.5) * k
	item.add_child(wrapper)
	placeholder.visible = false


static func _aabb(node: Node, to_local: Transform3D) -> AABB:
	var result := AABB()
	var first := true
	if node is MeshInstance3D:
		result = to_local * (node as MeshInstance3D).get_aabb()
		first = false
	for child in node.get_children():
		if child is Node3D:
			var sub := _aabb(child, to_local * (child as Node3D).transform)
			if sub.size != Vector3.ZERO:
				result = sub if first else result.merge(sub)
				first = false
	return result
