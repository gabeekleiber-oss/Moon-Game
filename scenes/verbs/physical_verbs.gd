class_name PhysicalVerbs
extends Node
## S-15: forgiving, tactile physical verbs for the first-person player. Child of the player's Camera3D, next to CarryController.
## Swing (hold broom or axe, left mouse), Kick (F), Throw (G, whatever is held). No meters, no HUD, no timing windows:
## each verb finds its target in a wide cone and throws aim-assist toward a ThrowTarget. Story scripts only connect signals on
## Hittable / ThrowTarget; they never read input. Sounds come from Audio; motion amplitude scales by Unreality.motion_scale().

signal swung(hit_any: bool)
signal kicked(hit_any: bool)
signal thrown(prop: ThrownProp)

const REACH := 2.2                  ## metres from the camera
const CONE_DOT := 0.5               ## cos of the half-angle: ~60 degrees, deliberately generous
const SWING_COOLDOWN := 0.5
const KICK_COOLDOWN := 0.7
const ASSIST_DOT := 0.82            ## throws within ~35 degrees of a ThrowTarget curve into it
const ASSIST_RANGE := 9.0

var carry: CarryController
var camera: Camera3D
var _cooldown := 0.0
var _tween: Tween


func _ready() -> void:
	camera = get_parent() as Camera3D
	if camera != null:
		carry = camera.get_node_or_null("CarryController") as CarryController
	_ensure_action("swing", MOUSE_BUTTON_LEFT)
	_ensure_action("kick", KEY_F)
	_ensure_action("throw_item", KEY_G)


static func _ensure_action(action: String, button_or_key: int) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action)
	if action == "swing":
		var m := InputEventMouseButton.new()
		m.button_index = button_or_key as MouseButton
		InputMap.action_add_event(action, m)
	else:
		var k := InputEventKey.new()
		k.physical_keycode = button_or_key as Key
		InputMap.action_add_event(action, k)


func _process(delta: float) -> void:
	_cooldown = maxf(0.0, _cooldown - delta)


func _unhandled_input(event: InputEvent) -> void:
	if Cutscene.is_active() or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	if event.is_action_pressed("swing"):
		swing()
	elif event.is_action_pressed("kick"):
		kick()
	elif event.is_action_pressed("throw_item"):
		throw_held()


## True for things worth swinging: broom, axe, or any prop with meta `swingable`.
static func is_swingable(item: Node) -> bool:
	if item == null:
		return false
	var n := item.name.to_lower()
	return bool(item.get_meta("swingable", false)) or n.contains("broom") or n.contains("axe")


## Swings the held broom/axe. Returns true if it connected. Always plays the whoosh and a short arm animation.
func swing() -> bool:
	if _cooldown > 0.0 or carry == null or not is_swingable(carry.held_item):
		return false
	_cooldown = SWING_COOLDOWN
	var weight := carry.carried_weight()
	var strength := clampf(0.5 + weight * 0.25, 0.4, 1.0)
	Audio.play_sfx("whoosh", -8.0, clampf(1.5 - weight * 0.15, 0.9, 1.5))
	_animate_swing()
	var connected := _strike("swing", strength)
	swung.emit(connected)
	return connected


## Kicks the nearest Hittable (or shoves a loose RigidBody3D). Returns true if something was hit.
func kick() -> bool:
	if _cooldown > 0.0 or camera == null:
		return false
	_cooldown = KICK_COOLDOWN
	var connected := _strike("kick", 1.0)
	if not connected:
		Audio.play_sfx("whoosh", -12.0, 1.1)
	kicked.emit(connected)
	return connected


## Throws whatever is held. Aim-assists into a ThrowTarget near the line of sight. Returns the new prop or null.
func throw_held() -> ThrownProp:
	if carry == null or camera == null or not is_instance_valid(carry.held_item):
		return null
	var item := carry.drop_item()
	if item == null:
		return null
	var kind := String(item.get_meta("throw_kind", item.name.to_lower()))
	return throw_object(item, kind, carry.carried_weight_of(item))


## Throws any node from where it is. Use for story props that are not carried (the telephone, the fish tank).
func throw_object(item: Node3D, kind: String, weight: float = 1.0) -> ThrownProp:
	var forward := -camera.global_transform.basis.z
	var speed := clampf(10.0 / (1.0 + weight * 0.25), 4.0, 10.0)
	var velocity := forward * speed + Vector3.UP * 1.5
	var target := _assist_target(forward)
	if target != null:
		velocity = ballistic_velocity(item.global_position, target.global_position, 0.7)
	var prop := ThrownProp.launch(item, velocity, kind, _world_parent(), maxf(weight, 0.2))
	prop.impact_sound = "smash" if kind in ["fish_tank", "tank", "tv"] else "thud"
	Audio.play_sfx("whoosh", -6.0, 1.3)
	thrown.emit(prop)
	return prop


## Velocity that carries a projectile from `from` to `to` in `flight_time` seconds under project gravity.
static func ballistic_velocity(from: Vector3, to: Vector3, flight_time: float = 0.7) -> Vector3:
	var g: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)
	var t := maxf(flight_time, 0.1)
	return (to - from) / t - Vector3(0.0, -g, 0.0) * 0.5 * t


func _world_parent() -> Node:
	var scene := get_tree().current_scene
	return scene if scene != null else get_tree().root


func _assist_target(forward: Vector3) -> Node3D:
	var best: Node3D = null
	var best_dot := ASSIST_DOT
	for node in get_tree().get_nodes_in_group("throw_target"):
		var t := node as Node3D
		if t == null:
			continue
		var offset := t.global_position - camera.global_position
		if offset.length() > ASSIST_RANGE:
			continue
		var d := forward.dot(offset.normalized())
		if d > best_dot:
			best_dot = d
			best = t
	return best


func _strike(kind: String, strength: float) -> bool:
	var space := camera.get_world_3d().direct_space_state
	var forward := -camera.global_transform.basis.z
	var query := PhysicsShapeQueryParameters3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.9
	query.shape = sphere
	query.transform = Transform3D(Basis.IDENTITY, camera.global_position + forward * (REACH * 0.55))
	query.collision_mask = 0xFFFFFFFF
	query.collide_with_areas = false
	var best: Node3D = null
	var best_score := -1.0
	for r in space.intersect_shape(query, 16):
		var body := r["collider"] as Node3D
		if body == null or body.is_ancestor_of(camera):
			continue
		var offset := body.global_position - camera.global_position
		if offset.length() > REACH + 1.2:
			continue
		var d := forward.dot(offset.normalized())
		if d < CONE_DOT:
			continue
		var score := d + (1.0 if body is Hittable else 0.0)
		if score > best_score:
			best_score = score
			best = body
	if best == null:
		return false
	if best is Hittable:
		return (best as Hittable).take_hit(kind, strength)
	if best is RigidBody3D:
		(best as RigidBody3D).apply_central_impulse(forward * 5.0 * strength + Vector3.UP * 1.0)
		Audio.play_sfx_at("kick" if kind == "kick" else "thud", best.global_position)
		return true
	return false


func _animate_swing() -> void:
	if carry == null:
		return
	if _tween != null and _tween.is_valid():
		_tween.kill()
	var amp := Unreality.motion_scale() * 0.75 + 0.25   # Reduced Motion keeps a small, slow swing
	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_property(carry, "action_rotation", Vector3(-70.0 * amp, 0.0, -20.0 * amp), 0.12).set_ease(Tween.EASE_OUT)
	_tween.tween_property(carry, "action_offset", Vector3(-0.05, 0.12, -0.25) * amp, 0.12).set_ease(Tween.EASE_OUT)
	_tween.chain().set_parallel(true)
	_tween.tween_property(carry, "action_rotation", Vector3.ZERO, 0.3).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_property(carry, "action_offset", Vector3.ZERO, 0.3).set_ease(Tween.EASE_IN_OUT)
