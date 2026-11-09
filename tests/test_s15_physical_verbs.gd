extends Node
## Unit tests for the remaining S-15 physical verbs components:
##  1. ChoppingLog (axe chop on logs, split into halves)
##  2. RollablePot (painted elephant pot, slope rolling, kick impulse, target detection)
##  3. MatchStriker (tactile match striking, flame lifecycle, target lighting)
##  4. CakeCutter (Act 5 Thirteen Candles cake, cutting slices for family and birds)

const ChoppingLogScript = preload("res://scenes/verbs/chopping_log.gd")
const RollablePotScript = preload("res://scenes/verbs/rollable_pot.gd")
const MatchStrikerScript = preload("res://scenes/verbs/match_striker.gd")
const CakeCutterScript = preload("res://scenes/verbs/cake_cutter.gd")


func _check(condition: bool, message: String) -> void:
	if not condition:
		push_error("FAILED: %s" % message)
		assert(false, message)


func _ready() -> void:
	print("Running test_s15_physical_verbs...")
	_test_chopping_log()
	_test_rollable_pot()
	_test_match_striker()
	_test_cake_cutter()
	print("ALL test_s15_physical_verbs checks passed.")


func _test_chopping_log() -> void:
	var log_prop := ChoppingLogScript.new()
	log_prop.hits_to_split = 2
	add_child(log_prop)

	_check(not log_prop.is_split(), "ChoppingLog starts un-split")
	_check(log_prop.accepts.has("swing"), "ChoppingLog accepts swing")
	_check(log_prop.accepts.has("chop"), "ChoppingLog accepts chop")

	var chopped_counts: Array[int] = []
	log_prop.log_chopped.connect(func(count: int, _rem: int) -> void:
		chopped_counts.append(count)
	)
	var split_emitted: Array[bool] = [false]
	log_prop.log_split.connect(func(_l: Node3D, _r: Node3D) -> void:
		split_emitted[0] = true
	)

	# First swing: chipped but not split
	var hit1: bool = log_prop.take_hit("swing", 1.0)
	_check(hit1, "ChoppingLog registered hit 1")
	_check(chopped_counts.size() == 1 and chopped_counts[0] == 1, "Chopped count is 1")
	_check(not log_prop.is_split(), "Log still un-split after 1 blow")

	# Second swing: split!
	var hit2: bool = log_prop.take_hit("chop", 1.0)
	_check(hit2, "ChoppingLog registered hit 2")
	_check(log_prop.is_split(), "Log is split after hits_to_split blows")
	_check(split_emitted[0], "log_split signal emitted")

	var halves: Array[RigidBody3D] = log_prop.get_halves()
	_check(halves.size() == 2, "ChoppingLog spawned two halves")
	_check(halves[0].visible and halves[1].visible, "Split halves are visible")
	_check(not halves[0].freeze and not halves[1].freeze, "Split halves have active physics")

	# Reset restores fresh log
	log_prop.reset_log()
	_check(not log_prop.is_split(), "Reset restores un-split state")
	_check(not halves[0].visible, "Halves hidden after reset")
	log_prop.queue_free()


func _test_rollable_pot() -> void:
	var pot := RollablePotScript.new()
	var woodpile := Node3D.new()
	woodpile.position = Vector3(10.0, 0.0, 10.0)
	add_child(woodpile)
	pot.target_woodpile = woodpile
	pot.target_reach_distance = 3.0
	add_child(pot)

	_check(pot.mass >= 25.0, "Pot has substantial heavy mass")
	_check(pot.pot_radius > 0.5, "Pot radius meets canon gimongous scale")

	var rolled_dist: Array[float] = []
	pot.rolled.connect(func(d: float) -> void:
		rolled_dist.append(d)
	)

	pot.roll_down_slope(Vector3(1.0, 0.0, 0.0), 10.0)
	_check(pot.linear_velocity.length() > 0.0 or pot.angular_velocity.length() > 0.0, "Slope roll applied velocity")

	# Test kick hit
	var kick_target: Hittable = pot.get_node_or_null("PotKickTarget") as Hittable
	_check(kick_target != null, "Pot has a kickable Hittable target")
	_check(kick_target.accepts.has("kick"), "KickTarget accepts kick")
	kick_target.take_hit("kick", 1.0)

	# Target proximity check
	pot.global_position = woodpile.global_position + Vector3(1.5, 0.0, 0.0)
	_check(pot.is_near_target(), "Pot detects proximity to woodpile target")

	woodpile.queue_free()
	pot.queue_free()


func _test_match_striker() -> void:
	var striker := MatchStrikerScript.new()
	add_child(striker)

	_check(striker.get_state() == MatchStrikerScript.State.UNLIT, "Match starts unlit")
	_check(not striker.is_lit(), "is_lit() returns false when unlit")

	var ignited_flag: Array[bool] = [false]
	striker.ignited.connect(func() -> void:
		ignited_flag[0] = true
	)

	var struck_ok: bool = striker.strike(1.0)
	_check(struck_ok, "strike() succeeds")
	_check(striker.is_lit(), "Match is lit after strike")
	_check(ignited_flag[0], "ignited signal emitted")

	# Ignite a flammable target
	var flammable_target := Node3D.new()
	flammable_target.add_to_group("flammable")
	flammable_target.set_meta("lit", false)
	add_child(flammable_target)

	var lit_emitted: Array[bool] = [false]
	striker.target_lit.connect(func(_t: Node3D) -> void:
		lit_emitted[0] = true
	)
	var lit_success: bool = striker.ignite_target(flammable_target)
	_check(lit_success, "ignite_target succeeds on flammable group")
	_check(lit_emitted[0], "target_lit signal emitted")

	# Extinguish
	striker.extinguish()
	_check(not striker.is_lit(), "Match is no longer lit after extinguish")
	_check(striker.get_state() == MatchStrikerScript.State.BURNT_OUT, "State is BURNT_OUT")

	flammable_target.queue_free()
	striker.queue_free()


func _test_cake_cutter() -> void:
	var cake := CakeCutterScript.new()
	add_child(cake)

	_check(cake.candle_count() == 13, "Act 5 cake has exactly thirteen candles")
	_check(cake.are_candles_lit(), "Candles start lit")
	_check(cake.slices_remaining() == 5, "Five canonical cake portions")

	var cut_recipients: Array[String] = []
	cake.slice_cut.connect(func(who: String, _idx: int, _node: Node3D) -> void:
		cut_recipients.append(who)
	)

	# Cut slice 1: Frank
	var slice1: Node3D = cake.cut_next_slice()
	_check(slice1 != null, "Slice 1 spawned")
	_check(cut_recipients.size() == 1 and cut_recipients[0] == "frank", "First slice cut for Frank")

	# Cut slice 2: Elsa Ray
	var slice2: Node3D = cake.cut_next_slice()
	_check(slice2 != null, "Slice 2 spawned")
	_check(cut_recipients[1] == "elsa_ray", "Second slice cut for Elsa Ray")

	# Cut slices for birds and Christopher
	cake.cut_next_slice() # birds_1
	cake.cut_next_slice() # birds_2
	cake.cut_next_slice() # christopher
	_check(cake.is_finished(), "Cake is finished after 5 slices")
	_check(not cake.are_candles_lit(), "Candles blown out upon cake completion")

	# Hittable cut trigger integration
	var cut_hit: Hittable = cake.get_node_or_null("CakeCutHittable") as Hittable
	_check(cut_hit != null, "Cake has cut Hittable component")
	_check(cut_hit.accepts.has("swing"), "Cake cut hittable accepts swing")

	cake.queue_free()
