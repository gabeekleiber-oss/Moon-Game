class_name Carryable
extends Interactable
## Interactable prop that can be picked up and held. Use on a StaticBody3D with mesh and collision.
@export_range(0.1, 8.0, 0.1) var carry_weight := 1.0
@export var hold_offset := Vector3(0.28, -0.25, -0.72)
@export var hold_rotation_degrees := Vector3(0.0, 0.0, 0.0)
var held := false


func _ready() -> void:
	super._ready()
	add_to_group("carryable")


func can_use() -> bool:
	return super.can_use() and not held


func _on_use(player: Node3D) -> void:
	if held or player == null:
		return
	var controller := player.get_node_or_null("Head/Camera3D/CarryController")
	if controller != null and controller.has_method("try_pickup"):
		controller.call("try_pickup", self)
