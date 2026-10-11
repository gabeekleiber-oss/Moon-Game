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
	print("FAILED: %d" % _fails if _fails else "ALL PASSED")
	get_tree().quit(1 if _fails else 0)
