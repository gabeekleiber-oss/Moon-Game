extends Node
## Validates data/sensory/spaces.json against data/world/*.json. Run: godot --headless --path . res://tests/test_sensory.tscn
var _fails := 0

func _check(cond: bool, what: String) -> void:
	print(("PASS " if cond else "FAIL ") + what)
	if not cond:
		_fails += 1

func _ready() -> void:
	var sheet: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/sensory/spaces.json"))
	var sp: Dictionary = sheet["spaces"]
	var presets: Array = sheet["reverb_presets"]
	var surfaces: Array = sheet["surfaces"]
	var missing: Array = []
	var bad_rv := 0
	var bad_su := 0
	var state_gap: Array = []
	var empty := 0
	var world_ids := {}
	for f in DirAccess.get_files_at("res://data/world"):
		if not f.ends_with(".json") or f.begins_with("_"):
			continue
		var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/world/" + f))
		var id := str(d["id"])
		world_ids[id] = true
		if not sp.has(id):
			missing.append(id)
			continue
		for s in d.get("states", {}):
			if not (sp[id]["light"] as Dictionary).has(s):
				state_gap.append("%s:%s" % [id, s])
	for id in sp:
		var e: Dictionary = sp[id]
		if not presets.has(e["reverb"]) or not ["none", "room", "hall", "dome", "cave"].has(e["reverb"]):
			bad_rv += 1
		if not surfaces.has(e["surface"]):
			bad_su += 1
		if str(e["tone"]) == "" or (e["sources"] as Array).is_empty() or str(e["wayfinding"]) == "":
			empty += 1
	_check(missing.is_empty(), "every world space has a sensory entry %s" % [missing])
	_check(not (sp.keys().any(func(k: String) -> bool: return not world_ids.has(k))), "no entry for an unknown space")
	_check(bad_rv == 0, "reverb names are valid Audio presets")
	_check(bad_su == 0, "footstep surfaces are from the allowed list")
	_check(empty == 0, "every entry has tone, at least one source and a wayfinding landmark")
	_check(state_gap.is_empty(), "every state a room defines has a key light line %s" % [state_gap])
	print("RESULT: %s" % ("ALL PASS" if _fails == 0 else "%d FAILED" % _fails))
	get_tree().quit(0 if _fails == 0 else 1)
