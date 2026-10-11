extends Node
## Headless test for the character kit. Run: godot --headless --path . res://tests/test_characters.tscn
var _fails := 0

func _check(cond: bool, what: String) -> void:
	print(("PASS " if cond else "FAIL ") + what)
	if not cond:
		_fails += 1

func _cell_pixels(img: Image, expr: String) -> int:
	var r := FaceAtlas.cell_uv(expr)
	var x0 := int(r.position.x * img.get_width())
	var y0 := int(r.position.y * img.get_height())
	var n := 0
	for y in FaceAtlas.CELL:
		for x in FaceAtlas.CELL:
			if img.get_pixel(x0 + x, y0 + y).a > 0.5:
				n += 1
	return n

func _ready() -> void:
	# --- atlas
	var tex := FaceAtlas.build({"eye_color": Color(0.2, 0.5, 0.95)})
	var img := tex.get_image()
	_check(img.get_width() == 512 and img.get_height() == 384, "atlas is 512x384")
	var all_drawn := true
	for e in FaceAtlas.EXPRESSIONS:
		if _cell_pixels(img, e) < 200:
			all_drawn = false
			print("   empty cell: ", e)
	_check(all_drawn, "all %d expressions drew something" % FaceAtlas.EXPRESSIONS.size())
	_check(_cell_pixels(img, "glare") != _cell_pixels(img, "neutral") and _cell_pixels(img, "surprised") != _cell_pixels(img, "eyes_closed"), "expressions are visibly different")
	_check(FaceAtlas.has("sly_smile") and not FaceAtlas.has("nope"), "has() validates names")
	var uv := FaceAtlas.cell_uv("glare")
	_check(is_equal_approx(uv.size.x, 0.25) and is_equal_approx(uv.size.y, 1.0 / 3.0) and uv.position.x < 1.0, "cell_uv is a valid quarter x third rect")
	var iris := img.get_pixel(int(64 - 24) + 0, 52)   # centre of the left eye in cell 0 (neutral)
	_check(iris.b > iris.r, "style eye_color shows in the iris (blue)")

	# --- base character
	var c := Character.new()
	add_child(c)
	await get_tree().process_frame
	_check(c.piece_count() >= 12 and c.part("Head") != null and c.part("Face") != null, "base humanoid built (%d parts)" % c.piece_count())
	var head := c.part("Head") as Node3D
	_check(head.position.y > 1.4 and head.position.y < 1.8, "head sits at a human height (%.2f m)" % head.position.y)
	_check(c.part("FootL").position.y < 0.05, "feet on the floor")
	var mat := (c.part("Face") as MeshInstance3D).material_override as StandardMaterial3D
	var before := mat.uv1_offset
	c.set_expression("glare")
	_check(c.expression == "glare" and mat.uv1_offset != before, "set_expression swaps the UV window")
	var seen := []
	c.expression_changed.connect(func(e: String) -> void: seen.append(e))
	c.set_expression("not_real")
	_check(c.expression == "glare" and seen.is_empty(), "unknown expression ignored")
	c.set_expression("smile")
	_check(seen == ["smile"], "expression_changed fires")
	c.set_expression("worried")
	c.glare(0.3)
	_check(c.expression == "glare", "glare() switches to the glare face immediately")
	await get_tree().create_timer(0.8).timeout
	_check(c.expression == "worried", "glare() returns to the previous expression afterwards")
	c.face_toward(Vector3(5, 0, 0))
	_check(absf(c.rotation.y - PI / 2.0) < 0.01, "face_toward turns the character")
	c.queue_free()
	print("RESULT: %s" % ("ALL PASS" if _fails == 0 else "%d FAILED" % _fails))
	get_tree().quit(0 if _fails == 0 else 1)
