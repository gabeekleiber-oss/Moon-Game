class_name ThrowMath
extends RefCounted
## Throw physics shared by the Ch2 phone and tank throws (C-02). Pure functions, no nodes (so tests can use them).
##
## A throw leaves along the camera forward, lofted `LOFT_DEG` upward, at a speed that grows with the meter `power` (0..1).
## `ideal_window()` scans the power range for throws that would drop into a target mouth, which drives the meter's green zone.

const MIN_SPEED := 4.0
const MAX_SPEED := 12.0
const LOFT_DEG := 20.0
const GRAVITY := 9.8


## Launch speed in m/s for a meter power.
static func speed(power: float) -> float:
	return lerpf(MIN_SPEED, MAX_SPEED, clampf(power, 0.0, 1.0))


## Launch velocity for a camera `forward` and meter `power`.
static func velocity(forward: Vector3, power: float) -> Vector3:
	var f := forward.normalized()
	var flat := Vector3(f.x, 0.0, f.z)
	if flat.length() < 0.001:
		flat = Vector3(0, 0, -1)
	flat = flat.normalized()
	var pitch := asin(clampf(f.y, -1.0, 1.0)) + deg_to_rad(LOFT_DEG)
	var s := speed(power)
	return flat * (s * cos(pitch)) + Vector3.UP * (s * sin(pitch))


## Velocity that lands exactly on `to` after `flight` seconds (used as the gentle assist after repeated misses).
static func assisted(from: Vector3, to: Vector3, flight: float = 0.9) -> Vector3:
	return (to - from) / flight + Vector3(0, 0.5 * GRAVITY * flight, 0)


## True if a projectile launched from `from` with `v` comes down inside the box (half sizes hx, hz) around `mouth`.
static func lands_in(from: Vector3, v: Vector3, mouth: Vector3, hx: float, hz: float) -> bool:
	var p := from
	var vel := v
	var dt := 1.0 / 120.0
	for i in 600:
		vel.y -= GRAVITY * dt
		p += vel * dt
		if vel.y < 0.0 and p.y <= mouth.y:
			return absf(p.x - mouth.x) <= hx and absf(p.z - mouth.z) <= hz
	return false


## The power range that hits: {"center": float, "half": float}, or {} if no power would hit from this aim.
static func ideal_window(from: Vector3, forward: Vector3, mouth: Vector3, hx: float, hz: float) -> Dictionary:
	var lo := -1.0
	var hi := -1.0
	for i in 51:
		var p := i / 50.0
		if lands_in(from, velocity(forward, p), mouth, hx, hz):
			if lo < 0.0:
				lo = p
			hi = p
	if lo < 0.0:
		return {}
	return {"center": (lo + hi) * 0.5, "half": maxf(0.03, (hi - lo) * 0.5)}
