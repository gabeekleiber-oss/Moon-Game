extends Node3D
## Story-specific code-built carry props. Real art can replace these placeholders without
## changing pickup or beat connections; coordinates use the authored world metre grid.

const CarryPropsScript = preload("res://scenes/player/props/carry_props.gd")

@export_range(1, 9) var story_act: int = 1
var _act: Node3D
var _props: Dictionary = {}


func _ready() -> void:
	_act = get_parent() as Node3D
	if _act == null or not _act.has_method("beat"):
		push_warning("ActCarryProps must be a child of an ActBase scene")
		return
	match story_act:
		1:
			_add_prop("broom", Vector3(7.5, 0.72, 7.0), "broom")
		9:
			# TODO(resume): relocate behind the shed when the exterior clearing is built.
			_add_prop("axe", Vector3(3.2, 0.48, 19.0), "axe")
			_add_prop("pot", Vector3(32.0, 0.48, 4.5), "pot")
	Events.beat_completed.connect(_on_beat_completed)


## Adds a factory-built carryable and connects successful pickup to its story beat.
func _add_prop(kind: String, at: Vector3, beat_id: String) -> void:
	var item: Carryable = CarryPropsScript.make(kind)
	if item == null:
		return
	item.position = at
	add_child(item)
	_decorate_placeholder(item, kind)
	_props[beat_id] = item
	item.used.connect(func(_player: Node3D) -> void: _try_complete_pickup(beat_id))


## Adds identifiable low-poly details until properly sourced art arrives.
func _decorate_placeholder(item: Carryable, kind: String) -> void:
	match kind:
		"broom":
			_add_box(item, "Bristles", Vector3(0.26, 0.25, 0.13), Vector3(0, -0.60, 0), Color(0.58, 0.45, 0.23))
			_add_box(item, "Binding", Vector3(0.28, 0.08, 0.15), Vector3(0, -0.48, 0), Color(0.32, 0.26, 0.20))
		"axe":
			_add_box(item, "SteelHead", Vector3(0.36, 0.18, 0.09), Vector3(0.12, 0.34, 0), Color(0.49, 0.52, 0.54))
			_add_box(item, "CuttingEdge", Vector3(0.06, 0.24, 0.11), Vector3(0.30, 0.34, 0), Color(0.72, 0.74, 0.73))
		"pot":
			_add_box(item, "LeftHandle", Vector3(0.16, 0.13, 0.24), Vector3(-0.50, 0.27, 0), Color(0.26, 0.27, 0.30))
			_add_box(item, "RightHandle", Vector3(0.16, 0.13, 0.24), Vector3(0.50, 0.27, 0), Color(0.26, 0.27, 0.30))
			var rim := MeshInstance3D.new()
			rim.name = "PotRim"
			var torus := TorusMesh.new()
			torus.inner_radius = 0.38
			torus.outer_radius = 0.47
			rim.mesh = torus
			rim.position.y = 0.45
			var metal := StandardMaterial3D.new()
			metal.albedo_color = Color(0.28, 0.29, 0.32)
			metal.metallic = 0.35
			metal.roughness = 0.7
			rim.material_override = metal
			item.add_child(rim)


## Builds one simple mesh detail; placeholder visuals never alter collision or pickup physics.
func _add_box(item: Carryable, part: String, size: Vector3, offset: Vector3, color: Color) -> void:
	var visual := MeshInstance3D.new()
	visual.name = part
	var mesh := BoxMesh.new()
	mesh.size = size
	visual.mesh = mesh
	visual.position = offset
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.8
	visual.material_override = mat
	item.add_child(visual)


## Failed pickup (already holding something) must not advance the story.
func _try_complete_pickup(beat_id: String) -> void:
	var item: Carryable = _props.get(beat_id) as Carryable
	if item != null and item.held and is_instance_valid(_act):
		_act.call("beat", beat_id)


## If an item was picked up early, count that action once prerequisites are complete.
func _on_beat_completed(act_id: int, _beat_id: String) -> void:
	if act_id != story_act:
		return
	for beat_id in _props:
		_try_complete_pickup(str(beat_id))
