extends Node
## Validates data/wrongness/catalog.json against data/world/*.json. Run: godot --headless --path . res://tests/test_wrongness_catalog.tscn
var _fails := 0

func _check(cond: bool, what: String) -> void:
	print(("PASS " if cond else "FAIL ") + what)
	if not cond:
		_fails += 1

func _ready() -> void:
	var cat: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/wrongness/catalog.json"))
	var behaviours: Dictionary = cat["behaviours"]
	var spaces := {}
	for f in DirAccess.get_files_at("res://data/world"):
		if f.ends_with(".json") and not f.begins_with("_"):
			var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/world/" + f))
			spaces[str(d["id"])] = d
	var seen := {}
	var dup := 0
	var bad_space := 0
	var bad_beh := 0
	var bad_acts := 0
	var bad_tier := 0
	var by_space := {}
	var used_beh := {}
	for e: Dictionary in cat["instances"]:
		var id := str(e["id"])
		if seen.has(id):
			dup += 1
			print("  duplicate id ", id)
		seen[id] = true
		var sp := str(e["space"])
		if not spaces.has(sp):
			bad_space += 1
			print("  unknown space ", sp, " in ", id)
			continue
		by_space[sp] = int(by_space.get(sp, 0)) + 1
		used_beh[str(e["behaviour"])] = true
		if not behaviours.has(str(e["behaviour"])):
			bad_beh += 1
			print("  unknown behaviour in ", id)
		var lo := int((e["acts"] as Array)[0])
		var hi := int((e["acts"] as Array)[1])
		var overlap := false
		for a in spaces[sp]["acts"]:
			if int(a) >= lo and int(a) <= hi:
				overlap = true
		if lo > hi or not overlap:
			bad_acts += 1
			print("  acts ", e["acts"], " do not overlap space ", sp, " acts ", spaces[sp]["acts"], " (", id, ")")
		if int(e["tier"]) < 1 or int(e["tier"]) > 3:
			bad_tier += 1
	_check(dup == 0, "instance ids are unique (%d instances)" % seen.size())
	_check(bad_space == 0, "every instance's space exists in data/world")
	_check(bad_beh == 0, "every instance uses a defined behaviour")
	_check(bad_acts == 0, "every instance's act range overlaps its space's acts")
	_check(bad_tier == 0, "tiers are 1..3")
	var uncovered: Array = []
	for sp in spaces:
		if not by_space.has(sp):
			uncovered.append(sp)
	_check(uncovered.is_empty(), "every world space has at least one wrongness %s" % [uncovered])
	var unused: Array = []
	for b in behaviours:
		if not used_beh.has(b):
			unused.append(b)
	print("INFO behaviours defined but not yet used by any instance: ", unused)
	print("RESULT: %s" % ("ALL PASS" if _fails == 0 else "%d FAILED" % _fails))
	get_tree().quit(0 if _fails == 0 else 1)
