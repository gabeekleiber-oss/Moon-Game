class_name InteractionRay
extends RayCast3D
## Camera raycast that finds the Interactable the player is looking at. (F-02)
##
## Attach as a child of the player's Camera3D and call `setup(player)` (player.gd does this).
## It tracks the focused target, highlights it (InteractOutline), shows the reticle + "[E] prompt"
## (InteractionHud), and calls `target.use(player)` on the `interact` action (E).
## Emits Events.interact_focus_changed / Events.interacted. Focus is suppressed while a dialogue runs.

const OUTLINE := preload("res://scenes/interaction/interact_outline.gd")
const HUD := preload("res://scenes/interaction/interaction_hud.gd")

## Ray length in metres; each Interactable's own `range` can only shorten this.
@export var max_distance: float = 4.0
## Ignore interactables while the mouse is released (pause/menus). Tests turn this off (headless has no mouse capture).
@export var require_captured_mouse: bool = true

var focus: Node3D = null
var _player: Node3D = null
var _outline := OUTLINE.new()
var _dialogue_depth: int = 0


func _ready() -> void:
	# Hit world (layer 1) so walls block the ray, and interactables (layer 4).
	collision_mask = 1 | Interactable.INTERACT_LAYER
	collide_with_areas = false
	collide_with_bodies = true
	target_position = Vector3(0.0, 0.0, -max_distance)
	enabled = true
	add_child(HUD.new())
	Events.dialogue_started.connect(func(_id: String) -> void: _dialogue_depth += 1)
	Events.dialogue_ended.connect(func(_id: String) -> void: _dialogue_depth = maxi(0, _dialogue_depth - 1))


## Gives the ray its owner (excluded from hits and passed to `use()`).
func setup(player: Node3D) -> void:
	_player = player
	if player is CollisionObject3D:
		add_exception(player)


func _physics_process(_delta: float) -> void:
	_set_focus(_find_target())


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and focus != null and is_instance_valid(focus):
		var target := focus
		target.call("use", _player)
		Events.interacted.emit(target)
		get_viewport().set_input_as_handled()


## Returns the usable interactable under the reticle, or null.
func _find_target() -> Node3D:
	if _dialogue_depth > 0 or (require_captured_mouse and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED):
		return null
	if not is_colliding():
		return null
	var hit := get_collider() as Node
	var target: Node3D = null
	if hit != null and hit.is_in_group("interactable"):
		target = hit as Node3D
	elif hit != null and hit.get_parent() != null and hit.get_parent().is_in_group("interactable"):
		target = hit.get_parent() as Node3D
	if target == null or not target.call("can_use"):
		return null
	var reach: float = target.get("range")
	if global_position.distance_to(get_collision_point()) > reach:
		return null
	return target


func _set_focus(target: Node3D) -> void:
	if target == focus:
		return
	focus = target
	_outline.apply(focus)
	Events.interact_focus_changed.emit(focus)
