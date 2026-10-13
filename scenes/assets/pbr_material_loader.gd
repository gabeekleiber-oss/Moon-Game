class_name PBRMaterialLoader
extends RefCounted
## Loads PBR maps from res://assets/textures/<id>/. Supported maps: albedo, normal, roughness, AO, height.
const UnrealSurfaceScript = preload("res://scenes/assets/unreal_surface.gd")

static func load_material(material_id: String, fallback_color: Color = Color(0.42, 0.40, 0.36), surface_effect: String = "") -> Material:
	var root := "res://assets/textures/%s/" % material_id.strip_edges().replace("..", "")
	var albedo := _texture(root, ["albedo.png", "basecolor.png", "color.png", "diffuse.png"])
	var normal := _texture(root, ["normal.png", "normal_gl.png", "normal_dx.png"])
	var roughness := _texture(root, ["roughness.png", "rough.png"])
	var ao := _texture(root, ["ao.png", "ambient_occlusion.png"])
	var height := _texture(root, ["height.png", "displacement.png"])
	var standard: StandardMaterial3D
	if not albedo and not normal and not roughness and not ao and not height:
		standard = _fallback(fallback_color, material_id)
	else:
		standard = StandardMaterial3D.new()
		standard.albedo_color = Color.WHITE
		standard.albedo_texture = albedo
		if normal:
			standard.normal_enabled = true
			standard.normal_texture = normal
		if roughness:
			standard.roughness_texture = roughness
		if ao:
			standard.ao_enabled = true
			standard.ao_texture = ao
		if height:
			standard.heightmap_enabled = true
			standard.heightmap_texture = height
		standard.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	if surface_effect.is_empty():
		return standard
	return UnrealSurfaceScript.make(surface_effect, standard)

static func _texture(root: String, candidates: Array[String]) -> Texture2D:
	for filename in candidates:
		var path := root + filename
		if ResourceLoader.exists(path):
			var resource: Resource = load(path)
			if resource is Texture2D:
				return resource as Texture2D
	return null

static func _fallback(color: Color, material_id: String) -> StandardMaterial3D:
	# PLACEHOLDER: named so missing real maps are visible in the inspector.
	var mat := StandardMaterial3D.new()
	mat.resource_name = "PLACEHOLDER_" + material_id
	mat.albedo_color = color
	mat.roughness = 0.78
	return mat
