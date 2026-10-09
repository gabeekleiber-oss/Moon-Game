class_name InteractOutline
extends RefCounted
## Highlights an Interactable by putting an inverted-hull shader on every mesh below it. (F-02)
##
## Usage: `var o := InteractOutline.new(); o.apply(target)` to highlight, `o.apply(null)` to clear.
## Uses GeometryInstance3D.material_overlay, so the object's own materials are never modified.

const SHADER := preload("res://scenes/interaction/interact_outline.gdshader")

var _material: ShaderMaterial = ShaderMaterial.new()
var _meshes: Array[GeometryInstance3D] = []


func _init() -> void:
	_material.shader = SHADER


## Highlights `target` (and all GeometryInstance3D descendants); clears the previous one. Pass null to clear.
func apply(target: Node) -> void:
	for m in _meshes:
		if is_instance_valid(m):
			m.material_overlay = null
	_meshes.clear()
	if target == null:
		return
	_material.set_shader_parameter("pulse", 0.0 if Game.settings.get("reduced_motion", false) else 1.0)
	_collect(target)
	for m in _meshes:
		m.material_overlay = _material


func _collect(node: Node) -> void:
	if node is GeometryInstance3D:
		_meshes.append(node as GeometryInstance3D)
	for child in node.get_children():
		_collect(child)
