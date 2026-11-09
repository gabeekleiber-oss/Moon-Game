class_name RollablePot
extends RigidBody3D
## S-15 component: the great painted-elephant melting pot (Act 9).
## Can be rolled down slopes or kicked/pushed toward a woodpile target.
## Detects target arrival and emits progress signals.

signal roll_started
signal rolled(distance: float)
signal reached_target(target: Node3D)
signal settled

@export var pot_radius: float = 0.65
@export var pot_height: float = 0.95
@export var pot_mass: float = 30.0
@export var target_woodpile: Node3D = null
@export var target_reach_distance: float = 2.8

var _kick_hittable: Hittable
var _start_position: Vector3
var _distance_rolled: float = 0.0
var _is_rolling: bool = false
var _reached: bool = false


func _ready() -> void:
	mass = pot_mass
	_start_position = global_position
	_build_pot_visuals()
	_build_kick_target()


func _physics_process(_delta: float) -> void:
	var speed := linear_velocity.length()
	var dist := global_position.distance_to(_start_position)
	if dist > _distance_rolled:
		_distance_rolled = dist
		rolled.emit(_distance_rolled)

	if speed > 0.3 and not _is_rolling:
		_is_rolling = true
		roll_started.emit()
	elif speed <= 0.1 and _is_rolling:
		_is_rolling = false
		settled.emit()

	if not _reached and target_woodpile and is_instance_valid(target_woodpile):
		if global_position.distance_to(target_woodpile.global_position) <= target_reach_distance:
			_reached = true
			reached_target.emit(target_woodpile)


## Rolls the pot along a slope vector with initial linear and angular impulse.
func roll_down_slope(slope_dir: Vector3 = Vector3(1.0, -0.15, 1.0).normalized(), force: float = 20.0) -> void:
	_is_rolling = true
	roll_started.emit()
	var roll_axis := Vector3.UP.cross(slope_dir).normalized()
	apply_central_impulse(slope_dir * force)
	apply_torque_impulse(roll_axis * (force * 0.4))


## Kicks the pot from an impact point.
func roll_kick(kick_dir: Vector3, force: float = 14.0) -> void:
	var dir := Vector3(kick_dir.x, 0.1, kick_dir.z).normalized()
	apply_central_impulse(dir * force)
	var roll_axis := Vector3.UP.cross(dir).normalized()
	apply_torque_impulse(roll_axis * (force * 0.3))


func is_near_target() -> bool:
	if not target_woodpile or not is_instance_valid(target_woodpile):
		return false
	return global_position.distance_to(target_woodpile.global_position) <= target_reach_distance


func get_distance_rolled() -> float:
	return _distance_rolled


func _build_kick_target() -> void:
	_kick_hittable = Hittable.new()
	_kick_hittable.name = "PotKickTarget"
	_kick_hittable.accepts = PackedStringArray(["kick"])
	_kick_hittable.kick_sound = "kick"
	var kick_col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = pot_radius * 1.15
	kick_col.shape = shape
	_kick_hittable.add_child(kick_col)
	_kick_hittable.hit.connect(func(_kind: String, strength: float, _count: int) -> void:
		roll_kick(Vector3.FORWARD, 12.0 * strength)
	)
	add_child(_kick_hittable)


func _build_pot_visuals() -> void:
	# Main collision shape
	var col := CollisionShape3D.new()
	var c_shape := CylinderShape3D.new()
	c_shape.radius = pot_radius
	c_shape.height = pot_height
	col.shape = c_shape
	add_child(col)

	# Bronze / iron pot body
	var body_inst := MeshInstance3D.new()
	body_inst.name = "PotBody"
	var body_mesh := CylinderMesh.new()
	body_mesh.top_radius = pot_radius
	body_mesh.bottom_radius = pot_radius * 0.82
	body_mesh.height = pot_height
	var pot_mat := StandardMaterial3D.new()
	pot_mat.albedo_color = Color(0.24, 0.22, 0.20)
	pot_mat.metallic = 0.7
	pot_mat.roughness = 0.45
	body_inst.mesh = body_mesh
	body_inst.material_override = pot_mat
	add_child(body_inst)

	# Decorative painted elephant bands (CANON: painted with elephants)
	var band_inst := MeshInstance3D.new()
	band_inst.name = "ElephantBand"
	var band_mesh := TorusMesh.new()
	band_mesh.inner_radius = pot_radius * 0.96
	band_mesh.outer_radius = pot_radius * 1.04
	var band_mat := StandardMaterial3D.new()
	band_mat.albedo_color = Color(0.85, 0.78, 0.55)
	band_mat.metallic = 0.4
	band_mat.roughness = 0.5
	band_inst.mesh = band_mesh
	band_inst.material_override = band_mat
	band_inst.position = Vector3(0.0, pot_height * 0.15, 0.0)
	add_child(band_inst)

	# Handles
	for x_side in [-1.0, 1.0]:
		var handle := MeshInstance3D.new()
		var h_mesh := TorusMesh.new()
		h_mesh.inner_radius = 0.08
		h_mesh.outer_radius = 0.16
		handle.mesh = h_mesh
		handle.material_override = pot_mat
		handle.position = Vector3(x_side * (pot_radius + 0.08), pot_height * 0.3, 0.0)
		handle.rotation_degrees = Vector3(0.0, 0.0, 90.0)
		add_child(handle)
