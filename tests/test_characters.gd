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
	var iris := img.get_pixel(45, 52)   # iris ring of the left eye in cell 0 (neutral); the pupil is dark
	_check(iris.b > 0.8 and iris.r < 0.4, "style eye_color shows in the iris (blue %s)" % str(iris))

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

	# --- Elsa Ray
	var elsa := ElsaRay.new()
	add_child(elsa)
	await get_tree().process_frame
	var epix := ((elsa.part("Face") as MeshInstance3D).material_override as StandardMaterial3D).albedo_texture.get_image().get_pixel(45, 52)
	_check(epix.b > 0.8 and epix.r < 0.4, "Elsa has blue eyes")
	_check(absf(elsa.height_m() - 1.68) < 0.001 and elsa.part("HairBack") != null, "Elsa: 1.68 m, long hair")
	elsa.glare()
	_check(elsa.expression == "glare", "Elsa glare() works (signature half-second)")
	await get_tree().create_timer(0.9).timeout
	_check(elsa.expression == "neutral", "Elsa's glare lasted only a moment and she is neutral again")

	# --- Mary Sue
	var ms := MarySue.new()
	add_child(ms)
	await get_tree().process_frame
	_check(ms.height_m() < elsa.height_m() and ms.part("Hair") != null, "Mary Sue is shorter than Elsa and has hair")
	var hair_mat := (ms.part("Hair") as MeshInstance3D).material_override as StandardMaterial3D
	_check(hair_mat.albedo_color.r > 0.9 and hair_mat.albedo_color.g > 0.7 and hair_mat.albedo_color.b < 0.4, "Mary Sue's hair is gold")
	var hat := ms.part("Hat") as MeshInstance3D
	_check(hat != null and (hat.mesh as CylinderMesh).top_radius == 0.0, "the hat is a cone")
	var spk := ms.part("HatSpeckles") as MultiMeshInstance3D
	_check(spk != null and spk.multimesh.instance_count >= 30, "the hat is speckled (%d gold dots)" % spk.multimesh.instance_count)
	var hh := (ms.part("Head") as Node3D).position.y
	_check(hat.position.y > hh, "the hat sits on top of her head")
	ms.set_hat(false)
	_check(not ms.hat_visible() and not spk.visible, "set_hat(false) hides hat and speckles")
	ms.set_hat(true)
	_check(ms.hat_visible(), "set_hat(true) shows it again")

	# --- Frank
	var fr := Frank.new()
	add_child(fr)
	await get_tree().process_frame
	_check(fr.expression == "stern", "Frank starts stern")
	fr.sly_smile()
	_check(fr.expression == "sly_smile", "Frank can sly_smile()")
	fr.stern()
	_check(fr.expression == "stern" and fr.height_m() < ms.height_m(), "back to stern; Frank is the smallest")
	var frank_before := fr.global_transform
	await get_tree().create_timer(0.3).timeout
	_check(fr.global_transform == frank_before and not fr.is_processing() and not fr.is_physics_processing(), "Frank is perfectly still (no processing, no motion)")
	# --- Sweaty Man
	Game.settings["reduced_motion"] = false
	var sm := SweatyMan.new()
	add_child(sm)
	await get_tree().process_frame
	_check(absf(sm.height_m() - 1.8) < 0.001 and sm.part("Robe") != null and sm.part("Belt") != null, "Sweaty Man: tall, in a bathrobe")
	var skin_c := ((sm.part("Head") as MeshInstance3D).material_override as StandardMaterial3D).albedo_color
	var foot_c := ((sm.part("FootL") as MeshInstance3D).material_override as StandardMaterial3D).albedo_color
	_check(foot_c.is_equal_approx(skin_c), "barefoot: his feet are skin-coloured")
	var strands := 0
	for n in sm.piece_names():
		if n.begins_with("BeardStrand"):
			strands += 1
	_check(strands >= 6 and sm.part("Beard") != null, "long scraggly beard (%d strands)" % strands)
	var finger := sm.part("FingerR") as MeshInstance3D
	var flen := (finger.mesh as CapsuleMesh).height
	_check(flen > 0.3, "very long finger (%.2f m, a normal finger is ~0.08)" % flen)
	var head_n := sm.part("Head") as Node3D
	var tip: Vector3 = finger.get_meta("tip")
	var lips := head_n.position + Vector3(0, -0.42 * 0.065 * 1.8, 0.065 * 1.8)
	_check(tip.distance_to(lips) < 0.05, "the finger tip reaches his lips (%.3f m away)" % tip.distance_to(lips))
	_check(not sm.part("ArmR").visible and sm.part("ForearmR") != null, "right arm is bent up to his face")
	var skin_rough := ((sm.part("Head") as MeshInstance3D).material_override as StandardMaterial3D).roughness
	_check(skin_rough < 0.3, "damp: glossy skin (roughness %.2f)" % skin_rough)
	var steam := sm.part("Steam") as CPUParticles3D
	_check(steam != null and steam.speed_scale > 0.0, "steam rises normally")
	Game.settings["reduced_motion"] = true
	sm.refresh_steam()
	_check(steam.speed_scale == 0.0, "steam freezes under Reduced Motion")
	Events.settings_changed.emit("reduced_motion")
	Game.settings["reduced_motion"] = false
	Events.settings_changed.emit("reduced_motion")
	_check(steam.speed_scale > 0.0, "steam resumes via settings_changed")
	sm.set_steam(false)
	_check(not steam.visible and not sm.part("SteamShell").visible, "set_steam(false) hides the steam")
	for n in [elsa, ms, fr, sm]:
		n.queue_free()
	print("RESULT: %s" % ("ALL PASS" if _fails == 0 else "%d FAILED" % _fails))
	get_tree().quit(0 if _fails == 0 else 1)
