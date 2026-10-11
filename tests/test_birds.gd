extends Node
## Headless test for F-11 (birds). Run: godot --headless --path . res://tests/test_birds.tscn
var _fails := 0
func _check(cond: bool, what: String) -> void:
	print(("PASS " if cond else "FAIL ") + what)
	if not cond:
		_fails += 1

func _ready() -> void:
	_check(BirdSpecies.SPECIES.size() == 12 and BirdSpecies.COUNT == 12, "12 species")
	var seen := {}
	for i in 12:
		var s := BirdSpecies.get_species(i)
		seen[s["id"]] = true
		for k in ["body", "belly", "wing", "head", "beak", "eye"]:
			if not (s[k] is Color):
				_check(false, "species %d key %s is a Color" % [i, k])
	_check(seen.size() == 12, "all ids unique")
	_check(BirdSpecies.get_species(13)["id"] == BirdSpecies.get_species(1)["id"], "index wraps")
	_check(BirdSpecies.get_species(-1)["id"] == BirdSpecies.get_species(11)["id"], "negative index wraps")
	_check(BirdSpecies.index_of("ink_wren") == 1 and BirdSpecies.index_of("nope") == -1, "index_of")
	for i in 12:
		var sp := BirdSpecies.get_species(i)
		var d := BirdMesh.vertex_data(sp)
		var pos: PackedVector3Array = d["positions"]
		var col: PackedColorArray = d["colors"]
		_check(pos.size() > 0 and pos.size() % 3 == 0 and pos.size() == col.size(), "species %d mesh is whole triangles with colours" % i)
		_check(pos.size() / 3 < 600, "species %d under 600 tris (%d)" % [i, pos.size() / 3])
		var zmin := 1e9
		var zmax := -1e9
		var wing_max := 0.0
		for k in pos.size():
			zmin = minf(zmin, pos[k].z)
			zmax = maxf(zmax, pos[k].z)
			wing_max = maxf(wing_max, col[k].a)
		var len := zmax - zmin
		var want: float = BirdMesh.LENGTH * float(sp["size"])
		_check(len > want * 0.6 and len < want * 1.3, "species %d length %.3f near %.3f" % [i, len, want])
		_check(wing_max > 0.9, "species %d has wing weights" % i)
	var m := BirdMesh.build(BirdSpecies.get_species(0))
	_check(m != null and m.get_surface_count() == 1, "build() makes one surface")
	# boids
	var b1 := Boids.new(90, AABB(Vector3(-6, 1, -6), Vector3(12, 5, 12)), 5)
	var b2 := Boids.new(90, AABB(Vector3(-6, 1, -6), Vector3(12, 5, 12)), 5)
	for k in 600:
		b1.step(1.0 / 60.0)
		b2.step(1.0 / 60.0)
	_check(b1.positions == b2.positions, "boids deterministic for same seed")
	_check(b1.all_inside(1.5), "boids stay inside bounds (+1.5 m) after 10 s")
	var ok_speed := true
	var near_sum := 0.0
	var near_min := INF
	for i in b1.count():
		var sp := b1.speed_of(i)
		if sp < b1.min_speed - 0.01 or sp > b1.max_speed + 0.01:
			ok_speed = false
		var nd := b1.nearest_distance(i)
		near_sum += nd
		near_min = minf(near_min, nd)
	_check(ok_speed, "boid speeds stay within min/max")
	_check(near_min > 0.02, "no two boids collapse onto each other (min gap %.3f)" % near_min)
	_check(near_sum / b1.count() < 1.5, "flock stays grouped (mean nearest %.2f m)" % (near_sum / b1.count()))
	b1.set_attractor(Vector3(5, 3, 5))
	var c0 := Vector3.ZERO
	for p in b1.positions:
		c0 += p
	c0 /= b1.count()
	for k in 300:
		b1.step(1.0 / 60.0)
	var c1 := Vector3.ZERO
	for p in b1.positions:
		c1 += p
	c1 /= b1.count()
	_check(c1.distance_to(Vector3(5, 3, 5)) < c0.distance_to(Vector3(5, 3, 5)), "attractor pulls the flock closer")
	var vb := b1.velocities[0]
	b1.scare(b1.positions[0] + Vector3(0.1, 0, 0), 2.0, 5.0)
	_check(b1.velocities[0] != vb, "scare changes velocity of nearby birds")
	# flock
	for n in [10, 90, 500]:
		var f := Flock.new()
		f.count = n
		add_child(f)
		await get_tree().process_frame
		await get_tree().process_frame
		var want := clampi(n, 60, 120)
		_check(f.bird_count() == want, "flock count %d clamps to %d" % [n, want])
		var total := 0
		var mmis := 0
		for c in f.get_children():
			if c is MultiMeshInstance3D:
				mmis += 1
				total += (c as MultiMeshInstance3D).multimesh.instance_count
		_check(mmis == 12 and total == want, "flock has 12 MultiMeshes covering %d birds (got %d/%d)" % [want, mmis, total])
		var moved := f.bird_position(0)
		await get_tree().create_timer(0.2).timeout
		_check(f.bird_position(0) != moved, "flock simulation moves birds")
		f.set_active(false)
		var frozen := f.bird_position(0)
		await get_tree().process_frame
		_check(f.bird_position(0) == frozen, "set_active(false) pauses the sim")
		f.queue_free()
	# hero bird
	var h := HeroBird.new()
	h.species = 5
	add_child(h)
	await get_tree().process_frame
	_check(h.species_id() == "milk_owlet" and not h.is_flying(), "hero bird starts perched with species 5")
	h.fly(true)
	_check(h.is_flying(), "hero fly(true)")
	h.fly(false)
	_check(not h.is_flying(), "hero fly(false) perches")
	h.set_species(14)
	_check(h.species == 2, "hero set_species wraps")
	h.look_at_point(Vector3(0, 0, -5), 0.0)
	_check(absf(h.rotation.y) < 0.01, "hero looks toward -Z with yaw 0")
	h.look_at_point(Vector3(5, 0, 0), 0.0)
	_check(absf(h.rotation.y + PI / 2.0) < 0.01, "hero looks toward +X with yaw -90 deg")
	print("FAILED: %d" % _fails if _fails else "ALL PASSED")
	get_tree().quit(1 if _fails else 0)
