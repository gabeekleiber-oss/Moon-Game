extends Node
## Headless integration checks for the authored carry props in Act 1 and Act 9.
var _fails := 0


func _check(ok: bool, what: String) -> void:
	print(("PASS " if ok else "FAIL ") + what)
	if not ok:
		_fails += 1


func _ready() -> void:
	var first: Node3D = (load("res://scenes/acts/act01_wisconsin/act01_wisconsin.tscn") as PackedScene).instantiate()
	add_child(first)
	var first_props: Node3D = first.get_node("StoryCarryProps")
	var broom: Carryable = first_props.get_node("Broom") as Carryable
	_check(broom != null and broom.is_in_group("carryable"), "Act 1 closet contains a carryable broom")
	_check(broom.position == Vector3(7.5, 0.72, 7.0), "broom is inside the authored closet footprint")
	first_props.call("_try_complete_pickup", "broom")
	_check(not first.beats.is_done("broom"), "not holding the broom does not complete its beat")
	broom.held = true
	first_props.call("_try_complete_pickup", "broom")
	_check(not first.beats.is_done("broom"), "early broom pickup cannot skip earlier story beats")
	for id in first.beats.ids():
		if id == "broom":
			break
		first.beats.complete(id)
	first_props.call("_try_complete_pickup", "broom")
	_check(first.beats.is_done("broom"), "held broom completes the beat after prerequisites")
	first.queue_free()

	var ninth: Node3D = (load("res://scenes/acts/act09_melting/act09_melting.tscn") as PackedScene).instantiate()
	add_child(ninth)
	var ninth_props: Node3D = ninth.get_node("StoryCarryProps")
	var axe: Carryable = ninth_props.get_node("Axe") as Carryable
	var pot: Carryable = ninth_props.get_node("Pot") as Carryable
	_check(axe != null and pot != null, "Act 9 spawns the axe and giant pot")
	_check(axe.carry_weight < pot.carry_weight, "giant pot has the heavier carry penalty")
	pot.held = true
	ninth_props.call("_try_complete_pickup", "pot")
	_check(not ninth.beats.is_done("pot"), "pot pickup cannot skip the east-wing story beat")
	for id in ninth.beats.ids():
		if id == "axe":
			break
		ninth.beats.complete(id)
	axe.held = true
	ninth_props.call("_try_complete_pickup", "axe")
	_check(ninth.beats.is_done("axe"), "held axe completes the Act 9 axe beat")
	for id in ninth.beats.ids():
		if id == "pot":
			break
		ninth.beats.complete(id)
	ninth_props.call("_try_complete_pickup", "pot")
	_check(ninth.beats.is_done("pot"), "held pot completes its beat after the east wing")
	ninth.queue_free()
	print("RESULT: ALL PASS" if _fails == 0 else "RESULT: %d FAILED" % _fails)
	get_tree().quit(_fails)
