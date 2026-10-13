class_name CarryController
extends Node3D
## Owns one held Carryable, moves it with restrained sway, and restores its world collision on drop.

var held_item: Node3D
var _original_parent: Node
var _saved_layer := 0
var _saved_mask := 0
var _saved_shapes: Array[CollisionShape3D] = []
var _saved_shape_disabled: Array[bool] = []
var _time := 0.0


func _ready() -> void:
	add_to_group("carry_controller")


func _process(delta: float) -> void:
	_time += delta
	if not is_instance_valid(held_item):
		held_item = null
		return
	var weight := maxf(float(held_item.get("carry_weight")), 0.1)
	var offset: Vector3 = held_item.get("hold_offset")
	var rotation_degrees: Vector3 = held_item.get("hold_rotation_degrees")
	var sway := Vector3(sin(_time * 1.7) * 0.015 * weight, sin(_time * 2.4) * 0.01 * weight, sin(_time * 1.1) * 0.006 * weight)
	var follow := 1.0 - exp(-delta * 10.0 / (1.0 + weight * 0.35))
	held_item.position = held_item.position.lerp(offset + sway, follow)
	held_item.rotation = held_item.rotation.lerp(Vector3(deg_to_rad(rotation_degrees.x), deg_to_rad(rotation_degrees.y), deg_to_rad(rotation_degrees.z)) + Vector3(sway.y, sway.z, sway.x), follow)


func try_pickup(item: Node3D) -> bool:
	if not is_instance_valid(item) or held_item != null or not item.is_in_group("carryable"):
		return false
	_original_parent = item.get_parent()
	if item is CollisionObject3D:
		_saved_layer = (item as CollisionObject3D).collision_layer
		_saved_mask = (item as CollisionObject3D).collision_mask
	_saved_shapes.clear()
	_saved_shape_disabled.clear()
	for child in item.find_children("*", "CollisionShape3D", true, false):
		if child is CollisionShape3D:
			var shape := child as CollisionShape3D
			_saved_shapes.append(shape)
			_saved_shape_disabled.append(shape.disabled)
			shape.disabled = true
	if item is CollisionObject3D:
		(item as CollisionObject3D).collision_layer = 0
		(item as CollisionObject3D).collision_mask = 0
	item.set("held", true)
	item.reparent(self, true)
	held_item = item
	return true


func drop_item() -> Node3D:
	if not is_instance_valid(held_item):
		held_item = null
		return null
	var item := held_item
	var parent := _original_parent if is_instance_valid(_original_parent) else get_tree().current_scene
	if parent == null:
		parent = get_tree().root
	item.reparent(parent, true)
	if item is CollisionObject3D:
		(item as CollisionObject3D).collision_layer = _saved_layer
		(item as CollisionObject3D).collision_mask = _saved_mask
	for i in mini(_saved_shapes.size(), _saved_shape_disabled.size()):
		if is_instance_valid(_saved_shapes[i]):
			_saved_shapes[i].disabled = _saved_shape_disabled[i]
	item.set("held", false)
	held_item = null
	_original_parent = null
	_saved_shapes.clear()
	_saved_shape_disabled.clear()
	return item


func carried_weight() -> float:
	return float(held_item.get("carry_weight")) if is_instance_valid(held_item) else 0.0


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("drop_item") and not (event is InputEventKey and (event as InputEventKey).echo):
		drop_item()
		get_viewport().set_input_as_handled()


func _exit_tree() -> void:
	if is_instance_valid(held_item):
		drop_item()
