extends Node3D
## Per-source audio occlusion. Put physical blockers in the "audio_occluder" group;
## put closed door colliders in "audio_occluder_door" as well. The helper raycasts
## from listener to source and applies the result to one AudioStreamPlayer3D, never
## changing a shared bus (which would incorrectly muffle every sound in the room).

const MAX_BLOCKERS := 4
const OPEN_CUTOFF_HZ := 20500.0
const WALL_CUTOFF_HZ := 5200.0
const DOOR_CUTOFF_HZ := 1500.0
const MAX_ATTENUATION_DB := -20.0

@export var refresh_interval := 0.12

var _elapsed := 0.0
var _last_profile: Dictionary = {"volume_db": 0.0, "cutoff_hz": OPEN_CUTOFF_HZ, "blockers": 0, "doors": 0}


func _process(delta: float) -> void:
	_elapsed += delta


## Cast through up to MAX_BLOCKERS colliders and apply a per-player filter and gain.
## Returns the profile used; missing inputs fail open and do not throw.
func update_source(player: AudioStreamPlayer3D, listener: Node3D, source: Node3D) -> Dictionary:
	if not is_instance_valid(player) or not is_instance_valid(listener) or not is_instance_valid(source):
		return _last_profile.duplicate()
	if _elapsed < refresh_interval:
		return _last_profile.duplicate()
	_elapsed = 0.0
	var world := get_world_3d()
	if world == null:
		return _last_profile.duplicate()
	var from := listener.global_position
	var to := source.global_position
	var direction := to - from
	if direction.length_squared() < 0.0001:
		_last_profile = occlusion_profile(0, 0)
		_apply(player, _last_profile)
		return _last_profile.duplicate()
	var exclusions: Array[RID] = []
	if listener is CollisionObject3D:
		exclusions.append((listener as CollisionObject3D).get_rid())
	if source is CollisionObject3D:
		exclusions.append((source as CollisionObject3D).get_rid())
	var blockers := 0
	var doors := 0
	var state := world.direct_space_state
	for _i in MAX_BLOCKERS:
		var query := PhysicsRayQueryParameters3D.create(from, to, 0xFFFFFFFF, exclusions)
		query.collide_with_areas = false
		query.collide_with_bodies = true
		var hit := state.intersect_ray(query)
		if hit.is_empty():
			break
		var collider: Object = hit.get("collider")
		if collider is Node and (collider as Node).is_in_group("audio_occluder"):
			blockers += 1
			if (collider as Node).is_in_group("audio_occluder_door"):
				doors += 1
		if collider is CollisionObject3D:
			exclusions.append((collider as CollisionObject3D).get_rid())
		else:
			break
	_last_profile = occlusion_profile(blockers, doors)
	_apply(player, _last_profile)
	return _last_profile.duplicate()


## Pure, deterministic math so design and tests do not depend on physics timing.
static func occlusion_profile(blocker_count: int, closed_door_count: int = 0) -> Dictionary:
	var blockers := maxi(blocker_count, 0)
	var doors := clampi(closed_door_count, 0, blockers)
	if blockers == 0:
		return {"volume_db": 0.0, "cutoff_hz": OPEN_CUTOFF_HZ, "blockers": 0, "doors": 0}
	var gain := maxf(MAX_ATTENUATION_DB, -5.0 - (blockers - 1) * 4.0 - doors * 3.0)
	var cutoff := WALL_CUTOFF_HZ
	if doors > 0:
		cutoff = DOOR_CUTOFF_HZ
	else:
		cutoff = maxf(2200.0, WALL_CUTOFF_HZ - (blockers - 1) * 900.0)
	return {"volume_db": gain, "cutoff_hz": cutoff, "blockers": blockers, "doors": doors}


static func _apply(player: AudioStreamPlayer3D, profile: Dictionary) -> void:
	player.volume_db = float(profile.get("volume_db", 0.0))
	player.attenuation_filter_cutoff_hz = float(profile.get("cutoff_hz", OPEN_CUTOFF_HZ))
	player.attenuation_filter_db = -24.0 if int(profile.get("blockers", 0)) > 0 else 0.0
