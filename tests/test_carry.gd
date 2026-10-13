extends Node
const CarryableScript = preload("res://scenes/player/carryable.gd")
const CarryControllerScript = preload("res://scenes/player/carry_controller.gd")
const PlayerScript = preload("res://scenes/player/player.gd")
var _fails := 0

func _check(condition: bool, message: String) -> void:
	print(("PASS " if condition else "FAIL ") + message)
	if not condition:
		_fails += 1

func _ready() -> void:
	var controller := CarryControllerScript.new()
	add_child(controller)
	var item: Node3D = CarryableScript.new()
	item.name = "TestPot"
	item.carry_weight = 2.0
	var collision := CollisionShape3D.new()
	collision.shape = BoxShape3D.new()
	item.add_child(collision)
	add_child(item)
	var saved_layer := (item as CollisionObject3D).collision_layer
	_check(controller.try_pickup(item), "carry controller accepts a carryable item")
	_check(controller.held_item == item and item.get_parent() == controller, "picked-up item is parented to the carry anchor")
	_check((item as CollisionObject3D).collision_layer == 0 and collision.disabled, "held item stops colliding with the world")
	_check(is_equal_approx(controller.carried_weight(), 2.0), "held item contributes its weight to movement")
	_check(not controller.try_pickup(CarryableScript.new()), "controller refuses a second held item")
	var dropped := controller.drop_item()
	_check(dropped == item and item.get_parent() == self, "drop restores the original parent")
	_check((item as CollisionObject3D).collision_layer == saved_layer and not collision.disabled, "drop restores collision state")
	_check(is_zero_approx(controller.carried_weight()), "dropping clears carried weight")

	var wood := Node.new()
	wood.add_to_group("surface_wood")
	var tile := Node.new()
	tile.add_to_group("surface_tile")
	var grass := Node.new()
	grass.add_to_group("surface_grass")
	var carpet := Node.new()
	carpet.add_to_group("surface_carpet")
	_check(PlayerScript.footstep_recipe_for(wood) == "footstep_wood", "wood surface selects wooden footsteps")
	_check(PlayerScript.footstep_recipe_for(tile) == "footstep_tile", "tile surface selects hard footsteps")
	_check(PlayerScript.footstep_recipe_for(grass) == "footstep_grass", "grass surface selects soft footsteps")
	_check(PlayerScript.footstep_recipe_for(carpet) == "footstep_carpet", "carpet surface selects muffled footsteps")
	_check(PlayerScript.footstep_recipe_for(null) == "footstep", "unknown surface falls back safely")

	var player_scene := load("res://scenes/player/player.tscn") as PackedScene
	var player := player_scene.instantiate() as CharacterBody3D
	add_child(player)
	player.set_physics_process(false)
	var capsule := (player.get_node("CollisionShape3D").shape as CapsuleShape3D)
	player.call("_update_crouch", 1.0, true)
	player.call("_process", 1.0)
	_check(capsule.height < 1.3 and player.get_node("Head").position.y < 1.2, "crouch lowers collision capsule and camera")
	_check(player.floor_snap_length >= 0.3 and player.floor_constant_speed, "controller configures floor snapping for stairs")
	player.queue_free()
	controller.queue_free()
	item.queue_free()
	wood.free()
	tile.free()
	grass.free()
	carpet.free()
	print("RESULT: ALL PASS" if _fails == 0 else "RESULT: %d FAILED" % _fails)
	get_tree().quit(_fails)
