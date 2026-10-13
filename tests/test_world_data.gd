extends Node
## Validates data/world/*.json against docs/WORLD_BIBLE.md rules: schema, no overlapping rooms, reciprocal doors, door positions on real walls,
## locks reference real story beats, and every route is connected. Run after editing ANY room file. Headless: godot --headless --path . res://tests/test_world_data.tscn

var _fails := 0
var rooms: Dictionary = {}

func _check(cond: bool, what: String) -> void:
	if not cond:
		print("FAIL " + what)
		_fails += 1

func _load_json(path: String) -> Variant:
	var f := FileAccess.open(path, FileAccess.READ)
	return JSON.parse_string(f.get_as_text()) if f != null else null

func _ready() -> void:
	var idx: Dictionary = _load_json("res://data/world/_index.json")
	_check(idx != null and idx.has("rooms"), "index exists")
	var beats: Dictionary = _load_json("res://data/story/beats.json")["acts"]
	for id: String in idx["rooms"]:
		var r = _load_json("res://data/world/%s.json" % id)
		_check(r is Dictionary, "room %s loads" % id)
		if not (r is Dictionary):
			continue
		rooms[id] = r
		for k in ["id", "name", "frame", "level", "footprint", "ceiling", "floor", "walls", "acts", "states", "doors", "props", "notes", "status"]:
			_check(r.has(k), "%s has key %s" % [id, k])
		_check(r["id"] == id, "%s id matches file" % id)
		for a in r["acts"]:
			_check(int(a) >= 1 and int(a) <= 9, "%s act %s in 1..9" % [id, str(a)])
		for k in ["use", "wear", "wrong"]:
			_check(str(r["notes"].get(k, "")).length() > 20, "%s notes.%s is written" % [id, k])
	# overlap per frame+level
	var ids: Array = rooms.keys()
	for i in ids.size():
		for j in range(i + 1, ids.size()):
			var a: Dictionary = rooms[ids[i]]
			var b: Dictionary = rooms[ids[j]]
			if a["footprint"] == null or b["footprint"] == null or a["frame"] != b["frame"] or int(a["level"]) != int(b["level"]):
				continue
			var ra := _rect(a)
			var rb := _rect(b)
			var overlap: bool = ra[0] < rb[2] and rb[0] < ra[2] and ra[1] < rb[3] and rb[1] < ra[3]
			_check(not overlap, "rooms %s and %s overlap" % [a["id"], b["id"]])
	# doors
	for id: String in rooms:
		var r: Dictionary = rooms[id]
		for d: Dictionary in r["doors"]:
			var t: String = d["to"]
			_check(rooms.has(t), "%s door to unknown room %s" % [id, t])
			if not rooms.has(t):
				continue
			var back := false
			for d2: Dictionary in rooms[t]["doors"]:
				if d2["to"] == id:
					back = true
			_check(back, "door %s -> %s has no partner" % [id, t])
			if d.has("wall") and r["footprint"] != null:
				var rc := _rect(r)
				var off := float(d["offset"])
				var width := maxf(float(d.get("width", 1.0)), 0.0)
				var low := rc[1] if d["wall"] in ["E", "W"] else rc[0]
				var high := rc[3] if d["wall"] in ["E", "W"] else rc[2]
				var on_wall: bool = off - width * 0.5 >= low - 0.01 and off + width * 0.5 <= high + 0.01
				_check(on_wall, "%s door to %s opening (center %s, width %s) exceeds its wall bounds" % [id, t, str(off), str(width)])
				var back_door: Dictionary = {}
				for candidate: Dictionary in rooms[t]["doors"]:
					if candidate["to"] == id:
						back_door = candidate
						break
				if not back_door.is_empty() and back_door.has("wall") and rooms[t]["footprint"] != null and r["frame"] == rooms[t]["frame"]:
					var opposite := {"N": "S", "S": "N", "E": "W", "W": "E"}
					_check(opposite.get(str(d["wall"]), "") == str(back_door["wall"]), "%s -> %s has matching opposite wall labels" % [id, t])
					_check(is_equal_approx(_wall_plane(r, str(d["wall"])), _wall_plane(rooms[t], str(back["wall"]))), "%s -> %s door planes meet" % [id, t])
					_check(is_equal_approx(off, float(back_door.get("offset", INF))), "%s -> %s reciprocal door centers align" % [id, t])
			if d.has("locked_until"):
				var parts: PackedStringArray = String(d["locked_until"]).split(".")
				var ok: bool = parts.size() == 2 and beats.has(parts[0].trim_prefix("act"))
				if ok:
					var found := false
					for b: Dictionary in beats[parts[0].trim_prefix("act")]["beats"]:
						if b["id"] == parts[1]:
							found = true
					ok = found
				_check(ok, "%s door to %s: locked_until '%s' is not a real beat" % [id, t, d["locked_until"]])
	# Connectivity must stay inside each authored frame. Otherwise a door to a different frame
	# could accidentally make a disconnected room appear reachable through an unrelated world graph.
	for start in [["foyer", "mansion"], ["wi_entry", "wi"], ["road_straight", "road"], ["maroon_hall", "dream"], ["ext_path", "ext"]]:
		var seen := {start[0]: true}
		var queue: Array = [start[0]]
		while not queue.is_empty():
			var cur: String = queue.pop_front()
			for d: Dictionary in rooms[cur]["doors"]:
				var next_id := str(d["to"])
				if not rooms.has(next_id) or seen.has(next_id):
					continue
				var next_room: Dictionary = rooms[next_id]
				if next_room["frame"] != start[1] and not (start[1] == "mansion" and next_id == "porch"):
					continue
				seen[next_id] = true
				queue.append(next_id)
		for id: String in rooms:
			if rooms[id]["frame"] == start[1] or (start[1] == "mansion" and id == "porch"):
				_check(seen.has(id), "%s unreachable from %s within frame %s" % [id, start[0], start[1]])
	print("rooms checked: %d" % rooms.size())
	print("FAILED: %d" % _fails if _fails else "ALL PASSED")
	get_tree().quit(1 if _fails else 0)

func _wall_plane(r: Dictionary, wall: String) -> float:
	var rc := _rect(r)
	match wall:
		"N": return rc[1]
		"S": return rc[3]
		"W": return rc[0]
		"E": return rc[2]
	return INF

func _rect(r: Dictionary) -> Array:
	var f: Array = r["footprint"]
	return [float(f[0][0]), float(f[0][1]), float(f[2][0]), float(f[2][1])]
