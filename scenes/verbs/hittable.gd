class_name Hittable
extends StaticBody3D
## S-15: something the player can strike (broom swing) or kick (shoo). Forgiving by design: the swing finds it inside a wide cone.
## Group `hittable`. Attach to a prop root with a CollisionShape3D. Connect `hit` for per-blow reactions and `broken` for the final one.
##
## Example: the TV needs two broom blows: `hits_required = 2, accepts = ["swing"]`, then `hit` plays the sound and `broken` topples it.

## Emitted for every accepted blow. `count` is 1-based; `kind` is "swing" or "kick"; `strength` 0..1.
signal hit(kind: String, strength: float, count: int)
## Emitted once when `hits_required` blows have landed.
signal broken
## Emitted when a blow of an unaccepted kind lands (so a script can show a light response, never an error).
signal ignored(kind: String)

@export var accepts: PackedStringArray = PackedStringArray(["swing", "kick"])
@export_range(1, 10) var hits_required: int = 1
## Sfx name per accepted kind on every blow ("" = silent). `final_sound` overrides on the last blow ("" = use the normal one).
@export var swing_sound: String = "thud"
@export var kick_sound: String = "kick"
@export var final_sound: String = ""
@export var enabled: bool = true

var hit_count: int = 0


func _ready() -> void:
	add_to_group("hittable")


## Applies one blow. Returns true when it counted. Safe to call from tests or scripts directly.
func take_hit(kind: String, strength: float = 1.0) -> bool:
	if not enabled or hit_count >= hits_required:
		return false
	if not accepts.has(kind):
		ignored.emit(kind)
		return false
	hit_count += 1
	var last := hit_count >= hits_required
	var sound := final_sound if (last and final_sound != "") else (swing_sound if kind == "swing" else kick_sound)
	if sound != "" and is_inside_tree():
		Audio.play_sfx_at(sound, global_position, 0.0, clampf(0.9 + strength * 0.2, 0.8, 1.2))
	hit.emit(kind, strength, hit_count)
	if last:
		broken.emit()
	return true


func reset_hits() -> void:
	hit_count = 0
