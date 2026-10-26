class_name ThrowTarget
extends Area3D
## S-15: a volume that catches thrown props (the fish tank for the phone, the floor for the tank). Group `throw_target`.
## Connect `received` to run the story beat; the thrown prop is passed in so scripts can react to what landed.

signal received(prop: ThrownProp)

## Prop kinds this target accepts; empty = anything thrown.
@export var accepts_kinds: PackedStringArray = PackedStringArray()
@export var catch_sound: String = ""
@export var consume_prop: bool = false
var catches: int = 0


func _ready() -> void:
	add_to_group("throw_target")
	monitoring = true
	collision_layer = 0
	collision_mask = ThrownProp.PROP_LAYER
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if not (body is ThrownProp):
		return
	var prop := body as ThrownProp
	if prop.caught_by != null or (accepts_kinds.size() > 0 and not accepts_kinds.has(prop.kind)):
		return
	prop.caught_by = self
	catches += 1
	if catch_sound != "":
		Audio.play_sfx_at(catch_sound, global_position)
	received.emit(prop)
	if consume_prop:
		prop.queue_free()
