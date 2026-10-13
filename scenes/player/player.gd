extends CharacterBody3D
## First-person exploration controller with crouch, sprint, head bob, surface footsteps and stair stepping.
## Unreality camera sway remains subtle and obeys Reduced Motion.

@export var speed := 6.0
@export var sprint_multiplier := 1.35
@export var jump_velocity := 5.0
@export var mouse_sensitivity := 0.0025

const BASE_FOV := 75.0
const STANDING_HEIGHT := 2.0
const CROUCH_HEIGHT := 1.22
const HEAD_STANDING_Y := 1.6
const HEAD_CROUCH_Y := 1.02
const STEP_HEIGHT := 0.28
const CROUCH_STEP_HEIGHT := 0.13
const CarryControllerScript = preload("res://scenes/player/carry_controller.gd")
const HandsScript = preload("res://scenes/player/first_person_hands.gd")

@onready var head: Node3D = $Head
@onready var _collision_shape: CollisionShape3D = $CollisionShape3D
var _t := 0.0
var _bob_phase := 0.0
var _head_target_y := HEAD_STANDING_Y
var _crouching := false
var _footstep_distance := 0.0
var _carry_controller: Node3D
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	floor_snap_length = 0.32
	floor_constant_speed = true
	floor_stop_on_slope = true
	floor_max_angle = deg_to_rad(48.0)
	if _collision_shape.shape is CapsuleShape3D:
		_collision_shape.shape = _collision_shape.shape.duplicate()
		var capsule := _collision_shape.shape as CapsuleShape3D
		capsule.height = STANDING_HEIGHT
		_collision_shape.position.y = STANDING_HEIGHT * 0.5
	var camera := head.get_node("Camera3D") as Camera3D
	# Keep InteractionRay first: existing interaction tests and room scripts rely on this path.
	var interaction_ray := preload("res://scenes/interaction/interaction_ray.gd").new() as RayCast3D
	camera.add_child(interaction_ray)
	interaction_ray.call("setup", self)
	_carry_controller = CarryControllerScript.new()
	_carry_controller.name = "CarryController"
	camera.add_child(_carry_controller)
	var hands := HandsScript.new()
	hands.name = "FirstPersonHands"
	camera.add_child(hands)
	Events.player_spawned.emit(self)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and not Cutscene.is_active():
		rotate_y(-event.relative.x * _sensitivity())
		head.rotate_x(-event.relative.y * _sensitivity())
		head.rotation.x = clampf(head.rotation.x, -1.4, 1.4)


func _process(delta: float) -> void:
	_t += delta
	var motion_scale := Unreality.motion_scale()
	var wrongness := Unreality.ramp(0.35, 1.0) * motion_scale
	head.rotation.z = lerpf(head.rotation.z, sin(_t * 0.7) * 0.035 * wrongness + sin(_t * 0.31) * 0.02 * wrongness, 1.0 - exp(-delta * 2.0))
	var cam := head.get_node("Camera3D") as Camera3D
	cam.fov = lerpf(cam.fov, BASE_FOV + sin(_t * 0.5) * 3.0 * wrongness, 1.0 - exp(-delta * 2.0))
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	var bob := 0.0
	if is_on_floor() and horizontal_speed > 0.25:
		var bob_rate := 10.0 if Input.is_action_pressed("sprint") and not _crouching else 7.0
		_bob_phase += delta * bob_rate * clampf(horizontal_speed / maxf(speed, 0.1), 0.3, 1.6)
		bob = sin(_bob_phase) * 0.022 * motion_scale
	head.position.y = lerpf(head.position.y, _head_target_y + bob, 1.0 - exp(-delta * 12.0))


func _physics_process(delta: float) -> void:
	var locked := _locked()
	var wants_crouch := not locked and Input.is_action_pressed("crouch")
	if not wants_crouch and _is_crouched() and test_move(global_transform, Vector3.UP * (STANDING_HEIGHT - (_collision_shape.shape as CapsuleShape3D).height)):
		wants_crouch = true
	_update_crouch(delta, wants_crouch)

	if not is_on_floor():
		velocity.y -= _gravity * delta
	elif Input.is_action_just_pressed("jump") and not locked and not _crouching:
		velocity.y = jump_velocity

	var input_dir := Vector2.ZERO if locked else Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
	var sprinting := not locked and not _crouching and Input.is_action_pressed("sprint") and input_dir.length_squared() > 0.01
	var movement_speed := speed * (sprint_multiplier if sprinting else 1.0)
	if _crouching:
		movement_speed *= 0.52
	var carried_weight := float(_carry_controller.call("carried_weight")) if is_instance_valid(_carry_controller) else 0.0
	movement_speed *= maxf(0.58, 1.0 - carried_weight * 0.10)
	velocity.x = direction.x * movement_speed
	velocity.z = direction.z * movement_speed

	var stepped := false
	if is_on_floor() and not locked:
		stepped = _try_step_up(Vector3(velocity.x, 0.0, velocity.z) * delta)
	if stepped:
		velocity.y = 0.0
		velocity.x = 0.0
		velocity.z = 0.0
	move_and_slide()
	_update_footsteps(delta, sprinting)


func _update_crouch(delta: float, crouch: bool) -> void:
	_crouching = crouch
	_head_target_y = HEAD_CROUCH_Y if crouch else HEAD_STANDING_Y
	if _collision_shape.shape is CapsuleShape3D:
		var capsule := _collision_shape.shape as CapsuleShape3D
		capsule.height = move_toward(capsule.height, CROUCH_HEIGHT if crouch else STANDING_HEIGHT, delta * 4.0)
		_collision_shape.position.y = capsule.height * 0.5


func _is_crouched() -> bool:
	return _crouching or (_collision_shape.shape is CapsuleShape3D and (_collision_shape.shape as CapsuleShape3D).height < STANDING_HEIGHT - 0.02)


## Steps up small stair lips only when the body is blocked at floor level and has clear headroom.
func _try_step_up(horizontal_motion: Vector3) -> bool:
	if horizontal_motion.length_squared() < 0.00001:
		return false
	if not test_move(global_transform, horizontal_motion):
		return false
	var step_height := CROUCH_STEP_HEIGHT if _crouching else STEP_HEIGHT
	var up_motion := Vector3.UP * step_height
	if test_move(global_transform, up_motion):
		return false
	var raised := global_transform
	raised.origin += up_motion
	if test_move(raised, horizontal_motion):
		return false
	var forward := raised
	forward.origin += horizontal_motion
	var collision := KinematicCollision3D.new()
	if not test_move(forward, Vector3.DOWN * (step_height + floor_snap_length + 0.02), collision):
		return false
	if collision.get_normal().dot(Vector3.UP) < cos(floor_max_angle):
		return false
	global_position = forward.origin + collision.get_travel()
	return true


func _update_footsteps(delta: float, sprinting: bool) -> void:
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	if not is_on_floor() or horizontal_speed < 0.8:
		return
	_footstep_distance += horizontal_speed * delta
	var stride := 1.05 if sprinting else (1.75 if not _crouching else 2.0)
	if _footstep_distance >= stride:
		_footstep_distance = 0.0
		var recipe := footstep_recipe_for(_ground_collider())
		Audio.play_sfx(recipe, -11.0 if not _crouching else -14.0, randf_range(0.92, 1.06))


func _ground_collider() -> Node:
	var state := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 0.15, global_position + Vector3.DOWN * 0.9)
	query.exclude = [get_rid()]
	query.collide_with_areas = false
	var hit := state.intersect_ray(query)
	return hit.get("collider") as Node if not hit.is_empty() else null


static func footstep_recipe_for(collider: Node) -> String:
	if collider == null:
		return "footstep"
	if collider.is_in_group("surface_wood"):
		return "footstep_wood"
	if collider.is_in_group("surface_tile"):
		return "footstep_tile"
	if collider.is_in_group("surface_grass"):
		return "footstep_grass"
	if collider.is_in_group("surface_carpet"):
		return "footstep_carpet"
	return "footstep"


## True while a dialogue or cutscene owns the player (no walking, jumping or (cutscene) looking).
func _locked() -> bool:
	return Dialogue.is_active() or Cutscene.is_active()


## Mouse sensitivity from the settings menu (falls back to the exported value).
func _sensitivity() -> float:
	return float(Game.settings.get("sensitivity", mouse_sensitivity))
