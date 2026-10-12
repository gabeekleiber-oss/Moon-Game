extends Node
## Validates data/assets/requests.json (shape, unique ids, targets under assets/). Run: godot --headless --path . res://tests/test_asset_requests.tscn
var _fails := 0

func _check(cond: bool, what: String) -> void:
	print(("PASS " if cond else "FAIL ") + what)
	if not cond:
		_fails += 1

func _ready() -> void:
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/assets/requests.json"))
	var seen := {}
	var bad := 0
	var bad_target := 0
	var kinds := ["material", "texture", "hdri", "model", "audio", "font", "character"]
	for r: Dictionary in d["requests"]:
		var ok := true
		for k in ["id", "title", "kind", "need", "why", "priority", "search", "sources", "accept", "target", "status"]:
			if not r.has(k):
				ok = false
		if not ok or seen.has(r.get("id")) or not kinds.has(r.get("kind")) or not ["requested", "received"].has(r.get("status")) or not [1, 2, 3].has(int(r.get("priority", 0))):
			bad += 1
			print("  bad request ", r.get("id"))
		seen[r.get("id")] = true
		if not str(r.get("target", "")).begins_with("assets/"):
			bad_target += 1
	_check(not d["requests"].is_empty() and bad == 0, "all %d requests are well-formed with unique ids" % d["requests"].size())
	_check(bad_target == 0, "targets are under assets/")
	_check(FileAccess.file_exists("res://docs/ASSET_REQUESTS.md"), "the human checklist has been generated (run assets.py checklist)")
	print("RESULT: %s" % ("ALL PASS" if _fails == 0 else "%d FAILED" % _fails))
	get_tree().quit(0 if _fails == 0 else 1)
