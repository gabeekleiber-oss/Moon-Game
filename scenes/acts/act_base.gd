class_name ActBase
extends Node3D
## Base class for every act scene (docs/ACTS.md lists the nine acts and their beats).
##
## Contract for act authors:
##  1. Subclass (or extend) ActBase; set `act_id` (1-9), `unreality_floor` and `base_grade` (a name from UnrealGrade.BASE).
##  2. Override `_define_beats(t: BeatTracker)` to list the act's beats IN STORY ORDER (ids from docs/ACTS.md).
##  3. When the player does a thing, call `beat("id")`. Out-of-order calls are ignored, so triggers can be generous.
##  4. When the last beat completes the act fires its unlock cue (`_fire_unlock_cue()`: override it to make the world
##     show the player where to go next: a light, a sound, a door unlocking) and tells `Acts` the next act is unlocked.
##  5. `Acts.go_to_next()` (or walking through the act's exit trigger, your choice) moves on.
## 6. The player chooses WHEN the next act begins: after the cue, the world offers an exit (get in the car, climb into the dome, lie down
##    in the bed). Build it with `make_exit(position, size)`: it is inert until the act is complete, then the player walking into/using it
##    starts `Acts.transition_to(next)`. The cue (light/sound/open door) must make the exit *noticeable but not shouting*.
## Debug builds: press N to complete the current act instantly.

@export var act_id: int = 0
@export var act_title: String = ""
## The minimum Unreality while this act is running (the story only ever gets stranger).
@export_range(0.0, 1.0) var unreality_floor: float = 0.0
## Location mood (a name from UnrealGrade.BASE). Unreality is layered on top of it.
@export var base_grade: String = "neutral"
## Name of the cue fired when the act completes (for tests/audio hooks).
@export var unlock_cue: String = "next_act"

var beats := BeatTracker.new()
var _leaving: bool = false


func _ready() -> void:
	_define_beats(beats)
	Unreality.set_floor(unreality_floor)
	PostFX.set_base_grade(base_grade, 1.5)
	Events.act_started.emit(act_id)
	_act_ready()


const BEATS_PATH := "res://data/story/beats.json"
static var _beats_cache: Dictionary = {}

## Registers this act's beats in story order from data/story/beats.json (ids match docs/ACTS.md). Override only for special cases.
func _define_beats(t: BeatTracker) -> void:
	for b in _beat_infos():
		t.add(str(b["id"]), b.get("requires", []), b.get("requires", []).is_empty())


## The data dictionaries for this act's beats (id, text, verb, systems, unreality, spike, shock, requires).
func _beat_infos() -> Array:
	if _beats_cache.is_empty():
		var f := FileAccess.open(BEATS_PATH, FileAccess.READ)
		if f != null:
			_beats_cache = JSON.parse_string(f.get_as_text())
	var act: Dictionary = _beats_cache.get("acts", {}).get(str(act_id), {})
	return act.get("beats", [])


## Data for one beat (empty dictionary if unknown).
func beat_info(id: String) -> Dictionary:
	for b in _beat_infos():
		if b["id"] == id:
			return b
	return {}


## Override: build/dress the act.
func _act_ready() -> void:
	pass


## Override: make the world show the way to the next act (subtle but noticeable). Default just emits the signal.
func _fire_unlock_cue() -> void:
	Events.cue_fired.emit(act_id, unlock_cue)


## Completes a story beat (ignored if unknown/out of order). Returns true if it newly completed.
func beat(id: String) -> bool:
	if not beats.complete(id):
		return false
	var info := beat_info(id)
	if float(info.get("unreality", 0.0)) > 0.0:
		Unreality.raise(float(info["unreality"]), "beat " + id)
	if float(info.get("spike", 0.0)) > 0.0:
		Unreality.spike(float(info["spike"]), "shock " + id)
	Events.beat_completed.emit(act_id, id)
	if beats.all_done():
		finish()
	return true


## Completes the act right now: unlock cue + next act unlocked.
func finish() -> void:
	Events.act_completed.emit(act_id)
	_fire_unlock_cue()
	Acts.unlock(act_id + 1)


## Creates the exit trigger the cue points at. Inert until `finish()` ran; then walking into it moves to the next act.
func make_exit(pos: Vector3, size: Vector3 = Vector3(2, 2.4, 2)) -> Area3D:
	var area := Area3D.new()
	area.name = "ExitTrigger"
	area.position = pos
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	area.add_child(shape)
	area.body_entered.connect(func(body: Node3D) -> void:
		if body is CharacterBody3D and Acts.is_unlocked(act_id + 1) and not _leaving:
			_leaving = true
			Acts.go_to_next())
	add_child(area)
	return area


func _unhandled_input(event: InputEvent) -> void:
	if OS.is_debug_build() and event is InputEventKey and event.pressed and event.keycode == KEY_N:
		finish()
