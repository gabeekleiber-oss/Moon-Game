extends Node
## Validates data/story/story_map.json against docs/source/STORY.md and data/story/beats.json.
## Run: godot --headless --path . res://tests/test_story_map.tscn   (regenerate the map with scripts/tools/gen_story_map.py)
var _fails := 0

func _check(cond: bool, what: String) -> void:
	print(("PASS " if cond else "FAIL ") + what)
	if not cond:
		_fails += 1

func _line_in_beat_act(e: Dictionary, beat_acts: Array) -> bool:
	var acts: Array[int] = [int(e["act"])]
	for a in e.get("also_acts", []):
		acts.append(int(a))
	for a in acts:
		if beat_acts.has(a):
			return true
	return false


func _ready() -> void:
	var story: PackedStringArray = []
	for l in FileAccess.get_file_as_string("res://docs/source/STORY.md").replace("\r", "").split("\n"):
		if l.strip_edges() != "":
			story.append(l.strip_edges())
	var map: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/story/story_map.json"))
	var beats: Dictionary = (JSON.parse_string(FileAccess.get_file_as_string("res://data/story/beats.json")) as Dictionary)["acts"]
	var known := {}
	for a in beats:
		for b in beats[a]["beats"]:
			var key := str(b["id"])
			if not known.has(key):
				known[key] = []
			known[key].append(int(a))                      # beat ids are NOT unique across acts ('bed' is in 7 and 9): always qualify as actN.beat
	var lines: Array = map["lines"]
	_check(lines.size() == story.size() - 3, "one entry per story line after the 3-line header (%d)" % lines.size())
	var bad_start := 0
	var bad_beat := 0
	var bad_act := 0
	var used := {}
	var last_act := 1
	var order_ok := true
	for e: Dictionary in lines:
		var n := int(e["n"])
		var norm := " ".join(story[n - 1].split(" ", false))
		if not norm.begins_with(str(e["starts"])):
			bad_start += 1
			print("  start mismatch at ", e["id"])
		if int(e["act"]) < last_act:
			order_ok = false
		last_act = int(e["act"])
		for b in e["beats"]:
			used[b] = true
			if not known.has(b):
				bad_beat += 1
				print("  unknown beat ", b)
			elif not _line_in_beat_act(e, known[b]):
				bad_act += 1
				print("  beat ", b, " is in act(s) ", known[b], " but line ", e["id"], " says ", e["act"])
	_check(bad_start == 0, "every entry's first 48 chars match STORY.md (STORY.md unchanged)")
	_check(bad_beat == 0 and bad_act == 0, "every beat id exists and sits in the right act")
	_check(order_ok, "acts never go backwards through the story")
	var missing: Array = []
	for b in known:
		if not used.has(b) and b != "dawn":
			missing.append(b)
	_check(missing.is_empty(), "every beat (except world-only 'dawn') has at least one source line %s" % [missing])
	print("RESULT: %s" % ("ALL PASS" if _fails == 0 else "%d FAILED" % _fails))
	get_tree().quit(0 if _fails == 0 else 1)
