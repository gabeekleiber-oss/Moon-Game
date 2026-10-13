class_name AssetCatalog
extends RefCounted
## Runtime asset access with code-built placeholders so missing art never blocks a scene.
const PBRLoader = preload("res://scenes/assets/pbr_material_loader.gd")

static func instantiate_or_fallback(path: String, fallback_kind: String = "box", tint: Color = Color(0.45, 0.42, 0.38)) -> Node3D:
	if ResourceLoader.exists(path):
		var resource: Resource = load(path)
		if resource is PackedScene:
			var instance := (resource as PackedScene).instantiate()
			if instance is Node3D:
				return instance
			instance.free()
	return _placeholder_mesh(fallback_kind, tint)

static func material(material_id: String, fallback_color: Color = Color(0.42, 0.40, 0.36), surface_effect: String = "") -> Material:
	return PBRLoader.load_material(material_id, fallback_color, surface_effect)

static func texture(path: String) -> Texture2D:
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D

static func _placeholder_mesh(kind: String, tint: Color) -> Node3D:
	# PLACEHOLDER: deterministic, zero-download fallback until licensed art is imported.
	var root := Node3D.new()
	root.name = "Placeholder_" + kind
	var instance := MeshInstance3D.new()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = tint
	mat.roughness = 0.82
	instance.material_override = mat
	match kind.to_lower():
		"sphere", "moon":
			var mesh := SphereMesh.new()
			mesh.radius = 0.5
			mesh.height = 1.0
			instance.mesh = mesh
		"cylinder", "pot":
			instance.mesh = CylinderMesh.new()
		"capsule", "person":
			instance.mesh = CapsuleMesh.new()
		_:
			instance.mesh = BoxMesh.new()
	root.add_child(instance)
	return root
