extends Node

const BakeHelperScript = preload("res://scenes/lighting/bake_helper.gd")
## Headless test for BakeHelper (probe placement, UV2, static/dynamic marking). The bake itself is editor-only and not tested here.

var _fails := 0

func _check(cond: bool, what: String) -> void:
	print(("PASS " if cond else "FAIL ") + what)
	if not cond:
		_fails += 1

func _ready() -> void:
	var root := Node3D.new()
	add_child(root)
	var box := MeshInstance3D.new()
	box.mesh = BoxMesh.new()
	root.add_child(box)
	var imported := MeshInstance3D.new()
	imported.mesh = ArrayMesh.new()
	root.add_child(imported)
	var bounds := AABB(Vector3(-3, 0, -2.5), Vector3(6, 3, 5))
	var p := BakeHelperScript.add_room_probes(root, bounds, "test_room")
	var gi: LightmapGI = p["lightmap"]
	var rp: ReflectionProbe = p["reflection"]
	_check(gi.get_parent() == root and gi.name == "test_room_lightmap" and gi.interior and gi.bounces == 3 and gi.max_texture_size == 4096, "LightmapGI added with the interior defaults")
	_check(gi.environment_mode == LightmapGI.ENVIRONMENT_MODE_DISABLED, "interior lightmaps ignore the sky")
	_check(rp.interior and rp.box_projection and rp.size == bounds.size and rp.update_mode == ReflectionProbe.UPDATE_ONCE, "ReflectionProbe is an interior box-projected probe sized to the room")
	_check(gi.position.is_equal_approx(bounds.get_center()) and rp.position.is_equal_approx(bounds.get_center()), "both are centred on the room")
	_check(BakeHelperScript.ensure_uv2(root) == 1 and (box.mesh as PrimitiveMesh).add_uv2, "ensure_uv2 fixes primitive meshes (1 changed)")
	_check(BakeHelperScript.ensure_uv2(root) == 0, "ensure_uv2 is idempotent")
	BakeHelperScript.mark_dynamic(box)
	_check(box.gi_mode == GeometryInstance3D.GI_MODE_DYNAMIC, "mark_dynamic excludes a prop from baking")
	BakeHelperScript.mark_static(root)
	_check(box.gi_mode == GeometryInstance3D.GI_MODE_STATIC and imported.gi_mode == GeometryInstance3D.GI_MODE_STATIC, "mark_static bakes everything below")
	var l := OmniLight3D.new()
	root.add_child(l)
	BakeHelperScript.set_light_baked(l, true)
	_check(l.light_bake_mode == Light3D.BAKE_STATIC, "a fixture can be baked")
	BakeHelperScript.set_light_baked(l, false)
	_check(l.light_bake_mode == Light3D.BAKE_DYNAMIC, "a flickering light stays dynamic")
	print("DONE %d failures" % _fails)
	get_tree().quit(1 if _fails > 0 else 0)
