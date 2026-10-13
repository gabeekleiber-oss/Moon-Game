extends Node
const AssetCatalogScript = preload("res://scenes/assets/asset_catalog.gd")
const PBRLoaderScript = preload("res://scenes/assets/pbr_material_loader.gd")
const DecalUtilScript = preload("res://scenes/assets/decal_util.gd")
var _fails := 0
func _check(condition: bool, message: String) -> void:
	print(("PASS " if condition else "FAIL ") + message)
	if not condition: _fails += 1
func _ready() -> void:
	var fallback := AssetCatalogScript.instantiate_or_fallback("res://assets/models/not-imported.glb", "box")
	_check(fallback is Node3D and fallback.get_child_count() == 1, "missing model returns a code-built placeholder")
	_check(fallback.name.begins_with("Placeholder_"), "fallback is visibly marked as a placeholder")
	var sphere := AssetCatalogScript.instantiate_or_fallback("res://assets/models/no-moon.glb", "moon")
	_check(sphere.get_child(0) is MeshInstance3D and sphere.get_child(0).mesh is SphereMesh, "moon fallback is a sphere mesh")
	var material := PBRLoaderScript.load_material("not_imported_yet", Color(0.3, 0.4, 0.5))
	_check(material is StandardMaterial3D and material.resource_name == "PLACEHOLDER_not_imported_yet", "missing PBR set returns a named fallback material")
	for shader_path in ["res://scenes/assets/materials/damp.gdshader", "res://scenes/assets/materials/rot.gdshader", "res://scenes/assets/materials/swim.gdshader", "res://scenes/assets/materials/crawl.gdshader"]:
		_check(ResourceLoader.exists(shader_path), "surface shader exists: " + shader_path)
	var decal_texture := GradientTexture2D.new()
	var decal := DecalUtilScript.create_grime_decal(decal_texture, Vector3(1.0, 0.8, 0.1), 0.25)
	_check(decal.size == Vector3(1.0, 0.8, 0.1) and is_equal_approx(decal.modulate.a, 0.25), "decal helper clamps dimensions and opacity")
	fallback.queue_free()
	sphere.queue_free()
	decal.free()
	print("RESULT: ALL PASS" if _fails == 0 else "RESULT: %d FAILED" % _fails)
	get_tree().quit(_fails)
