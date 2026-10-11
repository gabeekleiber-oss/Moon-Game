class_name Boids
extends RefCounted
## Pure boids simulation (F-11): separation, alignment, cohesion, a soft box boundary and an optional attractor. No nodes, no renderer,
## deterministic for a given seed, so it is headless-testable. Units: metres, seconds.
##
##   var b := Boids.new(90, AABB(Vector3(-6, 1, -6), Vector3(12, 5, 12)), 7)
##   each frame: b.step(delta);  read b.positions[i], b.velocities[i]
##   b.set_attractor(Vector3(0, 3, 0)) / b.clear_attractor() steers the flock toward a point (e.g. a window or the player).
##   b.scare(from_point, radius, strength) flings nearby birds away from a point (the Ch6 chase / a startle).
## Cost is O(n^2); n <= ~120 is fine every frame.
var positions: PackedVector3Array = PackedVector3Array()
var velocities: PackedVector3Array = PackedVector3Array()
var bounds: AABB
var neighbor_radius: float = 1.6
var separation_radius: float = 0.55
var w_separation: float = 2.2
var w_alignment: float = 1.0
var w_cohesion: float = 0.7
var w_bounds: float = 3.0
var w_attractor: float = 0.8
var min_speed: float = 1.4
var max_speed: float = 3.2
var max_accel: float = 7.0
var has_attractor: bool = false
var attractor: Vector3 = Vector3.ZERO
var _rng := RandomNumberGenerator.new()

func _init(count: int = 90, box: AABB = AABB(Vector3(-6, 1, -6), Vector3(12, 5, 12)), seed_value: int = 1) -> void:
	bounds = box
	_rng.seed = seed_value
	positions.resize(count)
	velocities.resize(count)
	for i in count:
		positions[i] = box.position + Vector3(_rng.randf(), _rng.randf(), _rng.randf()) * box.size
		var dir := Vector3(_rng.randf_range(-1, 1), _rng.randf_range(-0.3, 0.3), _rng.randf_range(-1, 1)).normalized()
		velocities[i] = dir * _rng.randf_range(min_speed, max_speed)


## Number of birds.
func count() -> int:
	return positions.size()


## Steers the whole flock toward `point` (gently; the other rules still apply).
func set_attractor(point: Vector3) -> void:
	has_attractor = true
	attractor = point


## Removes the attractor.
func clear_attractor() -> void:
	has_attractor = false


## Flings every bird within `radius` of `from` away from it by up to `strength` m/s (falls off with distance).
func scare(from: Vector3, radius: float, strength: float) -> void:
	for i in positions.size():
		var away := positions[i] - from
		var d := away.length()
		if d < radius:
			if d < 0.001:
				away = Vector3.UP
			velocities[i] += away.normalized() * strength * (1.0 - d / radius)


## Advances the simulation by `delta` seconds (clamped to 0.1 so a hitch cannot explode it).
func step(delta: float) -> void:
	delta = clampf(delta, 0.0, 0.1)
	var n := positions.size()
	var accel := PackedVector3Array()
	accel.resize(n)
	var nr2 := neighbor_radius * neighbor_radius
	var sr2 := separation_radius * separation_radius
	for i in n:
		var pi := positions[i]
		var sep := Vector3.ZERO
		var ali := Vector3.ZERO
		var coh := Vector3.ZERO
		var seen := 0
		for j in n:
			if j == i:
				continue
			var off := positions[j] - pi
			var d2 := off.length_squared()
			if d2 > nr2:
				continue
			seen += 1
			ali += velocities[j]
			coh += positions[j]
			if d2 < sr2:
				sep -= off / maxf(d2, 0.0004)
		var a := Vector3.ZERO
		if seen > 0:
			a += (ali / seen - velocities[i]) * w_alignment
			a += ((coh / seen) - pi) * w_cohesion
		a += sep * w_separation * separation_radius
		a += _bounds_push(pi) * w_bounds
		if has_attractor:
			a += (attractor - pi).normalized() * w_attractor * max_speed
		if a.length() > max_accel:
			a = a.normalized() * max_accel
		accel[i] = a
	for i in n:
		var v := velocities[i] + accel[i] * delta
		var sp := v.length()
		if sp < 0.0001:
			v = Vector3.FORWARD * min_speed
		elif sp > max_speed:
			v = v / sp * max_speed
		elif sp < min_speed:
			v = v / sp * min_speed
		velocities[i] = v
		positions[i] += v * delta


## Speed of bird `i` in m/s.
func speed_of(i: int) -> float:
	return velocities[i].length()


## Distance from bird `i` to its nearest neighbour (diagnostics, tests).
func nearest_distance(i: int) -> float:
	var best := INF
	for j in positions.size():
		if j != i:
			best = minf(best, positions[i].distance_to(positions[j]))
	return best


## True if every bird is inside `bounds` grown by `slack` metres.
func all_inside(slack: float = 0.0) -> bool:
	var box := bounds.grow(slack)
	for p in positions:
		if not box.has_point(p):
			return false
	return true


## Soft push back toward the box when a bird is within 20% of an edge (or past it). Magnitude grows with depth.
func _bounds_push(p: Vector3) -> Vector3:
	var push := Vector3.ZERO
	var lo := bounds.position
	var hi := bounds.position + bounds.size
	var margin := bounds.size * 0.2
	for k in 3:
		if p[k] < lo[k] + margin[k]:
			push[k] = (lo[k] + margin[k] - p[k]) / margin[k]
		elif p[k] > hi[k] - margin[k]:
			push[k] = -(p[k] - (hi[k] - margin[k])) / margin[k]
	return push * max_speed
