extends Node
## Loads/unloads chapter scenes, one at a time. Owner: Lead.
## Add a chapter by appending to CHAPTERS (do not reorder).

const CHAPTERS := [
	{"id": 1,  "title": "The Fourteenth of September",   "path": "res://scenes/chapters/ch01_wisconsin/ch01_wisconsin.tscn"},
	{"id": 2,  "title": "Burning Bridges, Drowning Phones", "path": "res://scenes/chapters/ch02_departure/ch02_departure.tscn"},
	{"id": 3,  "title": "The Road South",                "path": "res://scenes/chapters/ch03_road/ch03_road.tscn"},
	{"id": 4,  "title": "The House in the Clearing",     "path": "res://scenes/chapters/ch04_house/ch04_house.tscn"},
	{"id": 5,  "title": "The Moon With an Eye",          "path": "res://scenes/chapters/ch05_dome/ch05_dome.tscn"},
	{"id": 6,  "title": "The First Night of Rooms",      "path": "res://scenes/chapters/ch06_dark_rooms/ch06_dark_rooms.tscn"},
	{"id": 7,  "title": "Thirteen Candles",              "path": "res://scenes/chapters/ch07_kitchen/ch07_kitchen.tscn"},
	{"id": 8,  "title": "The Lake",                      "path": "res://scenes/chapters/ch08_lake/ch08_lake.tscn"},
	{"id": 9,  "title": "Morning at the Gronfiser's",    "path": "res://scenes/chapters/ch09_morning/ch09_morning.tscn"},
	{"id": 10, "title": "The Inventory",                 "path": "res://scenes/chapters/ch10_inventory/ch10_inventory.tscn"},
	{"id": 11, "title": "The Melting Spree",             "path": "res://scenes/chapters/ch11_melting/ch11_melting.tscn"},
]

var current_id: int = 0
var _current: Node = null

func go_to(id: int) -> void:
	var entry := _find(id)
	if entry.is_empty():
		push_warning("No chapter %d" % id)
		return
	if _current:
		_current.queue_free()
		_current = null
		await get_tree().process_frame
	var packed: PackedScene = load(entry["path"])
	if packed == null:
		push_error("Failed to load chapter %d: %s" % [id, entry["path"]])
		return
	_current = packed.instantiate()
	add_child(_current)
	current_id = id
	Events.chapter_started.emit(id)

func next() -> void:
	if current_id < CHAPTERS.size():
		go_to(current_id + 1)
	else:
		Events.show_message("The End.")

func title_of(id: int) -> String:
	return _find(id).get("title", "")

func _find(id: int) -> Dictionary:
	for c in CHAPTERS:
		if c["id"] == id:
			return c
	return {}
