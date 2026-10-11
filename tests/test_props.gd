extends Node
## Headless test for F-10 (prop kit). Run: godot --headless --path . res://tests/test_props.tscn
var _fails := 0
func _check(cond: bool, what: String) -> void:
	print(("PASS " if cond else "FAIL ") + what)
	if not cond:
		_fails += 1

func _ready() -> void:
	for v in [Chandelier.Variant.BRASS, Chandelier.Variant.RUBY, Chandelier.Variant.MILKY]:
		var c := Chandelier.new()
		c.variant = v
		add_child(c)
		await get_tree().process_frame
		_check(c.candle_count() == 8, "chandelier variant %d has 8 candle arms" % v)
		var mm := (c.get_node("Body/Crystals") as MultiMeshInstance3D).multimesh
		_check(mm.instance_count >= 8 * 4, "variant %d has crystals (%d)" % [v, mm.instance_count])
	var c12 := Chandelier.new()
	c12.arms = 12
	add_child(c12)
	await get_tree().process_frame
	_check(c12.candle_count() == 12, "arms export respected (12)")
	c12.set_lit(false)
	_check(not (c12.get_node("Body/Glow") as OmniLight3D).visible, "set_lit(false) hides light")
	for f in [Armor.Finish.STEEL, Armor.Finish.BLACK, Armor.Finish.BRASS]:
		var a := Armor.new()
		a.finish = f
		a.halberd = (f == Armor.Finish.BRASS)
		add_child(a)
		await get_tree().process_frame
		_check(a.piece_count() >= 12, "armor finish %d has %d pieces (>=12)" % [f, a.piece_count()])
		if a.halberd:
			_check(a.piece_names().has("Halberd") and a.piece_count() == 17, "halberd adds a 17th piece")
	var ar := Armor.new()
	add_child(ar)
	await get_tree().process_frame
	ar.set_pose(Armor.Pose.SALUTE)
	_check(ar.get_node("ArmPivotR").rotation.x < -1.5, "SALUTE raises the right arm")
	print("FAILED: %d" % _fails if _fails else "ALL PASSED")
	get_tree().quit(1 if _fails else 0)
