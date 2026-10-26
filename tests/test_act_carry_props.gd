extends Node
## Integration checks: real CarryController pickups must drive the authored story beats.
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
	broom.use(first.get_node("Player") as Node3D)
	_check(broom.held, "broom pickup uses the real player carry controller")
	_check(not first.beats.is_done("broom"), "early broom pickup cannot skip story beats")
	for id in first.beats.ids():
		if id == "broom":
			break
		first.beats.complete(id)
	first_props.call("_try_complete_pickup", "broom")
	_check(first.beats.is_done("broom"), "held broom completes its beat after prerequisites")
	first.queue_free()

	var ninth: Node3D = (load("res://scenes/acts/act09_melting/act09_melting.tscn") as PackedScene).instantiate()
	add_child(ninth)
	var ninth_props: Node3D = ninth.get_node("StoryCarryProps")
	var axe: Carryable = ninth_props.get_node("Axe") as Carryable
	var pot: Carryable = ninth_props.get_node("Pot") as Carryable
	_check(axe != null and pot != null, "Act 9 spawns axe and giant pot")
	_check(axe.carry_weight < pot.carry_weight, "pot is heavier than axe")
	_check(axe.position.x <= 4.0 and axe.position.z >= 17.0 and axe.position.z <= 21.0, "temporary axe placement is reachable on the porch floor")
	ninth_props.call("_try_complete_pickup", "pot")
	_check(not ninth.beats.is_done("pot"), "unheld pot cannot skip the east-wing beat")
	for id in ninth.beats.ids():
		if id == "axe":
			break
		ninth.beats.complete(id)
	axe.use(ninth.get_node("Player") as Node3D)
	_check(axe.held and ninth.beats.is_done("axe"), "axe pickup completes its story beat")
	for id in ninth.beats.ids():
		if id == "pot":
			break
		ninth.beats.complete(id)
	var controller: CarryController = ninth.get_node("Player/Head/Camera3D/CarryController") as CarryController
	controller.drop_item()
	pot.use(ninth.get_node("Player") as Node3D)
	_check(pot.held and ninth.beats.is_done("pot"), "pot pickup completes its beat after the east wing")
	ninth.queue_free()
	print("RESULT: ALL PASS" if _fails == 0 else "RESULT: %d FAILED" % _fails)
	get_tree().quit(_fails)
