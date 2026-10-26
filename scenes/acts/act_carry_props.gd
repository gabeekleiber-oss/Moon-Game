extends Node3D
## Story-specific code-built carry props. The real room dressing can replace the meshes without
## changing these pickup/beat connections. Placement is temporary until the authored spaces land.

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
			# Inside the Wisconsin hall closet (data/world/wi_hall_closet.json).
			_add_prop("broom", Vector3(7.5, 0.72, 7.0), "broom")
		9:
			# TODO(resume): move the axe behind the shed when the clearing is built. For now it rests on the porch floor.
			_add_prop("axe", Vector3(3.2, 0.48, 19.0), "axe")
			# East storage: the giant pot is acquired after the east-wing beat.
			_add_prop("pot", Vector3(32.0, 0.48, 4.5), "pot")
	Events.beat_completed.connect(_on_beat_completed)


## Adds a factory-built carryable and connects its successful pickup to the story beat.
func _add_prop(kind: String, at: Vector3, beat_id: String) -> void:
	var item: Carryable = CarryPropsScript.make(kind)
	if item == null:
		return
	item.position = at
	add_child(item)
	_props[beat_id] = item
	item.used.connect(func(_player: Node3D) -> void: _try_complete_pickup(beat_id))


## A failed pickup (already carrying another object) must never advance the story.
func _try_complete_pickup(beat_id: String) -> void:
	var item: Carryable = _props.get(beat_id) as Carryable
	if item != null and item.held and is_instance_valid(_act):
		_act.call("beat", beat_id)


## If a player picked an item up early, honor that action when prior beats become complete.
func _on_beat_completed(act_id: int, _beat_id: String) -> void:
	if act_id != story_act:
		return
	for beat_id in _props:
		_try_complete_pickup(str(beat_id))
