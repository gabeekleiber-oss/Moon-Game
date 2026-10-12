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


func _ready() -> void:
	_define_beats(beats)
	Unreality.set_floor(unreality_floor)
	PostFX.set_base_grade(base_grade, 1.5)
	Events.act_started.emit(act_id)
	_act_ready()


## Override: register this act's beats in story order.
func _define_beats(_t: BeatTracker) -> void:
	pass


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
	Events.beat_completed.emit(act_id, id)
	if beats.all_done():
		finish()
	return true


## Completes the act right now: unlock cue + next act unlocked.
func finish() -> void:
	Events.act_completed.emit(act_id)
	_fire_unlock_cue()
	Acts.unlock(act_id + 1)


func _unhandled_input(event: InputEvent) -> void:
	if OS.is_debug_build() and event is InputEventKey and event.pressed and event.keycode == KEY_N:
		finish()
