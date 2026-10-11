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
	print("FAILED: %d" % _fails if _fails else "ALL PASSED")
	get_tree().quit(1 if _fails else 0)
