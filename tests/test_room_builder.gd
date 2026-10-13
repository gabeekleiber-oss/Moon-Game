extends Node
const RoomBuilderScript = preload("res://scenes/world/room_builder.gd")
var _fails := 0

func _check(condition: bool, message: String) -> void:
	print(("PASS " if condition else "FAIL ") + message)
	if not condition:
		_fails += 1

func _ready() -> void:
	var foyer_data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/world/foyer.json"))
	var builder := RoomBuilderScript.new()
	add_child(builder)
	var foyer := builder.build_room(foyer_data, "night")
	_check(foyer.name == "foyer" and foyer.get_meta("state") == "night", "room root keeps id and selected state")
	_check(foyer.get_node_or_null("Floor") != null and foyer.get_node_or_null("Ceiling") != null, "rectangular room gets floor and ceiling")
	_check(foyer.get_node_or_null("NavigationRegion") is NavigationRegion3D, "room gets a navigation region")
	_check(foyer.find_children("Wall_*", "StaticBody3D", true, false).size() >= 4, "room builds segmented walls with collision")
	var locked := foyer.find_child("LockedDoor_to_bird_hall", true, false) as StaticBody3D
	_check(locked != null and locked.get_meta("locked_until") == "act3.eye_vanishes", "locked story door records its beat gate")
	var barrier_shape := locked.get_node_or_null("CollisionShape") as CollisionShape3D if locked != null else null
	_check(barrier_shape != null and not barrier_shape.disabled, "locked door blocks the opening before its story beat")
	Events.beat_completed.emit(3, "eye_vanishes")
	await get_tree().process_frame
	_check(barrier_shape != null and barrier_shape.disabled, "matching story beat releases the locked door collision")

	var upper_data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/world/master_bedroom.json"))
	var upper := builder.build_room(upper_data, "day")
	var floor_body := upper.get_node("Floor") as StaticBody3D
	_check(is_equal_approx(floor_body.position.y, 4.9), "upper-floor room uses the shared five-metre level step")
	_check(upper.get_meta("state") == "day", "day state is recorded for later dressing and lighting")
	var road_data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/world/road_straight.json"))
	var road := builder.build_room(road_data)
	_check(bool(road.get_meta("placeholder_frame")) and road.get_node_or_null("PlaceholderGround") != null, "non-rectangular set-piece gets an explicit safe placeholder pad")
	var window_room_data := {"id": "window_test", "frame": "test", "level": 0, "footprint": [[0, 0], [4, 0], [4, 4], [0, 4]], "ceiling": 2.8, "floor": "linoleum", "walls": "plaster", "doors": [], "windows": [{"id": "north_window", "wall": "N", "offset": 2.0, "width": 1.2, "sill": 0.9, "height": 1.1}], "props": []}
	var window_room := builder.build_room(window_room_data)
	_check(window_room.find_child("Window_north_window", true, false) is MeshInstance3D, "window data creates a visible pane and a wall opening")
	var base_trim := window_room.find_child("BaseTrim_N", true, false) as StaticBody3D
	_check(base_trim != null and base_trim.get_node_or_null("CollisionShape") == null, "decorative trim does not add blocking collision")
	_check(foyer.get_meta("placeholder"), "generated room is explicitly marked as blockout placeholder")
	var later_builder := RoomBuilderScript.new()
	later_builder.current_act_id = 4
	add_child(later_builder)
	var foyer_later := later_builder.build_room(foyer_data, "night")
	_check(foyer_later.find_child("LockedDoor_to_bird_hall", true, false) == null, "a lock from a previous act does not reappear in a later act")
	print("RESULT: %s" % ("ALL PASS" if _fails == 0 else "%d FAILED" % _fails))
	get_tree().quit(0 if _fails == 0 else 1)
