extends Node
## Autoload `Acts`: loads one act scene at a time and tracks which acts are unlocked. Strict story order: act N+1 only
## unlocks when act N completes (ActBase.finish). The unlock itself comes with a world cue (see ActBase._fire_unlock_cue).
## (Replaces the old ChapterManager. Add an act by editing ACTS below, never reorder.)
## API: Acts.go_to(id), Acts.go_to_next(), Acts.unlock(id), Acts.is_unlocked(id), Acts.title_of(id), Acts.transition_to(id, fade_s).

const ACTS := [
	{"id": 1, "title": "The Fourteenth of September", "path": "res://scenes/acts/act01_wisconsin/act01_wisconsin.tscn"},
	{"id": 2, "title": "The Road South", "path": "res://scenes/acts/act02_road/act02_road.tscn"},
	{"id": 3, "title": "The Moon With an Eye", "path": "res://scenes/acts/act03_dome/act03_dome.tscn"},
	{"id": 4, "title": "The First Night of Rooms", "path": "res://scenes/acts/act04_dark_rooms/act04_dark_rooms.tscn"},
	{"id": 5, "title": "Thirteen Candles", "path": "res://scenes/acts/act05_birthday/act05_birthday.tscn"},
	{"id": 6, "title": "The Lake", "path": "res://scenes/acts/act06_lake/act06_lake.tscn"},
	{"id": 7, "title": "Morning at the Gronfiser's", "path": "res://scenes/acts/act07_morning/act07_morning.tscn"},
	{"id": 8, "title": "The Inventory", "path": "res://scenes/acts/act08_inventory/act08_inventory.tscn"},
	{"id": 9, "title": "The Melting Spree", "path": "res://scenes/acts/act09_melting/act09_melting.tscn"},
]

var current_id: int = 0
var _current: Node = null


## Highest act the player may enter.
func unlocked_through() -> int:
	return Game.furthest_act


func is_unlocked(id: int) -> bool:
	return id <= Game.furthest_act


## Marks `id` (and everything before it) as available. Emits Events.act_unlocked once.
func unlock(id: int) -> void:
	if id > ACTS.size() or id <= Game.furthest_act:
		return
	Game.furthest_act = id
	Events.act_unlocked.emit(id)


## Loads act `id` immediately (debug and tests may jump anywhere with `force`; normal play must respect unlocks).
func go_to(id: int, force: bool = false) -> void:
	var entry := _find(id)
	if entry.is_empty():
		push_warning("No act %d" % id)
		return
	if not force and not is_unlocked(id):
		push_warning("Act %d is not unlocked yet" % id)
		return
	if force:
		unlock(id)
	if _current:
		_current.queue_free()
		_current = null
		await get_tree().process_frame
	var packed: PackedScene = load(entry["path"])
	if packed == null:
		push_error("Failed to load act %d: %s" % [id, entry["path"]])
		return
	_current = packed.instantiate()
	add_child(_current)
	current_id = id


## Fade to black, load, fade in (what a doorway/car/staircase trigger should call).
func transition_to(id: int, fade_s: float = 1.2) -> void:
	await Cutscene.fade_out(fade_s)
	await go_to(id)
	await Cutscene.fade_in(fade_s)


func go_to_next() -> void:
	if current_id < ACTS.size():
		await transition_to(current_id + 1)
	else:
		Events.show_message.emit("(end of this part)")


func title_of(id: int) -> String:
	return _find(id).get("title", "")


func count() -> int:
	return ACTS.size()


func _find(id: int) -> Dictionary:
	for a in ACTS:
		if a["id"] == id:
			return a
	return {}
