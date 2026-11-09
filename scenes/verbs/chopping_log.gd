class_name ChoppingLog
extends Hittable
## S-15 component: chopping stump and log for Act 9.
## Accepts axe swings ("swing", "chop") and splits the log down the middle after
## hits_to_split blows, separating into two physics-driven log halves with sound.

signal log_chopped(count: int, remaining: int)
signal log_split(half_left: Node3D, half_right: Node3D)

@export_range(1, 8) var hits_to_split: int = 2
@export var log_length: float = 0.85
@export var log_radius: float = 0.18
@export var stump_height: float = 0.6
@export var stump_radius: float = 0.32

var _whole_log: MeshInstance3D
var _whole_col: CollisionShape3D
var _half_left: RigidBody3D
var _half_right: RigidBody3D
var _stump: StaticBody3D
var _split_done: bool = false


func _ready() -> void:
	accepts = PackedStringArray(["swing", "chop"])
	hits_required = hits_to_split
	swing_sound = "thud"
	final_sound = "thud"
	super._ready()
	_build_visuals()
	hit.connect(_on_log_hit)
	broken.connect(_on_log_broken)


## Resets the chopping block to a fresh, un-split log.
func reset_log() -> void:
	reset_hits()
	_split_done = false
	if _whole_log:
		_whole_log.visible = true
	if _whole_col:
		_whole_col.disabled = false
	if _half_left:
		_half_left.visible = false
		_half_left.freeze = true
		_half_left.position = Vector3(-0.08, stump_height + log_radius, 0.0)
		_half_left.rotation = Vector3.ZERO
	if _half_right:
		_half_right.visible = false
		_half_right.freeze = true
		_half_right.position = Vector3(0.08, stump_height + log_radius, 0.0)
		_half_right.rotation = Vector3.ZERO


func is_split() -> bool:
	return _split_done


func get_halves() -> Array[RigidBody3D]:
	return [_half_left, _half_right]


func _on_log_hit(_kind: String, _strength: float, count: int) -> void:
	var remaining: int = maxi(0, hits_required - count)
	log_chopped.emit(count, remaining)
	if _whole_log and count < hits_required:
		var tween := create_tween()
		tween.tween_property(_whole_log, "position:y", stump_height + log_radius - 0.03, 0.05)
		tween.tween_property(_whole_log, "position:y", stump_height + log_radius, 0.08)


func _on_log_broken() -> void:
	if _split_done:
		return
	_split_done = true
	if _whole_log:
		_whole_log.visible = false
	if _whole_col:
		_whole_col.disabled = true

	if _half_left and _half_right:
		_half_left.visible = true
		_half_left.freeze = false
		_half_right.visible = true
		_half_right.freeze = false
		_half_left.apply_impulse(Vector3(-1.6, 1.2, 0.0))
		_half_right.apply_impulse(Vector3(1.6, 1.2, 0.0))
		log_split.emit(_half_left, _half_right)


func _build_visuals() -> void:
	# Stump base
	_stump = StaticBody3D.new()
	_stump.name = "Stump"
	add_child(_stump)
	var stump_mesh := CylinderMesh.new()
	stump_mesh.top_radius = stump_radius
	stump_mesh.bottom_radius = stump_radius * 1.1
	stump_mesh.height = stump_height
	var stump_mat := StandardMaterial3D.new()
	stump_mat.albedo_color = Color(0.38, 0.28, 0.18)
	stump_mat.roughness = 0.9
	stump_mesh.material = stump_mat
	var stump_inst := MeshInstance3D.new()
	stump_inst.mesh = stump_mesh
	stump_inst.position = Vector3(0.0, stump_height * 0.5, 0.0)
	_stump.add_child(stump_inst)

	# Whole log resting on top of stump
	_whole_log = MeshInstance3D.new()
	_whole_log.name = "WholeLog"
	var log_mesh := CylinderMesh.new()
	log_mesh.top_radius = log_radius
	log_mesh.bottom_radius = log_radius
	log_mesh.height = log_length
	var log_mat := StandardMaterial3D.new()
	log_mat.albedo_color = Color(0.52, 0.41, 0.26)
	log_mat.roughness = 0.85
	_whole_log.mesh = log_mesh
	_whole_log.material_override = log_mat
	_whole_log.rotation_degrees = Vector3(0.0, 0.0, 90.0)
	_whole_log.position = Vector3(0.0, stump_height + log_radius, 0.0)
	add_child(_whole_log)

	_whole_col = CollisionShape3D.new()
	_whole_col.name = "WholeLogCollision"
	var col_shape := BoxShape3D.new()
	col_shape.size = Vector3(log_length, log_radius * 2.2, log_radius * 2.2)
	_whole_col.shape = col_shape
	_whole_col.position = Vector3(0.0, stump_height + log_radius, 0.0)
	add_child(_whole_col)

	# Split half left
	_half_left = _create_half("LogHalfLeft", Vector3(-0.08, stump_height + log_radius, 0.0), log_mat)
	# Split half right
	_half_right = _create_half("LogHalfRight", Vector3(0.08, stump_height + log_radius, 0.0), log_mat)


func _create_half(half_name: String, pos: Vector3, mat: Material) -> RigidBody3D:
	var body := RigidBody3D.new()
	body.name = half_name
	body.mass = 2.5
	body.freeze = true
	body.visible = false
	body.position = pos
	var inst := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(log_length, log_radius * 1.8, log_radius * 0.9)
	mesh.material = mat
	inst.mesh = mesh
	body.add_child(inst)
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = mesh.size
	col.shape = box
	body.add_child(col)
	add_child(body)
	return body
