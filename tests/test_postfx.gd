extends Node
## Headless logic test for the PostFX autoload (shader visuals are checked with tests/_post_shot.tscn under xvfb).
## Run: godot --headless --path . res://tests/test_postfx.tscn
var _fails := 0

func _check(cond: bool, what: String) -> void:
	print(("PASS " if cond else "FAIL ") + what)
	if not cond:
		_fails += 1

func _ready() -> void:
	_check(is_instance_valid(PostFX) and PostFX.is_enabled(), "PostFX autoload exists and is enabled")
	for id in range(1, 12):
		var g := GradeTable.for_chapter(id)
		_check(g.has("tint") and g.has("saturation") and g["saturation"] > 0.0, "chapter %d has a complete grade" % id)
	for n in GradeTable.names():
		var g2 := GradeTable.get_grade(n)
		for k in GradeTable.NEUTRAL:
			if not g2.has(k):
				_check(false, "grade %s missing %s" % [n, k])
	_check(GradeTable.get_grade("ch07_kitchen")["tint"] != GradeTable.get_grade("ch07_hall")["tint"], "ch07 hall and kitchen differ")
	PostFX.set_grade("ch11", 0.0)
	_check(PostFX.get_grade_name() == "ch11", "set_grade by name (instant)")
	var mat := (PostFX._mat as ShaderMaterial)
	_check(is_equal_approx(float(mat.get_shader_parameter("tint_amount")), 0.35), "ch11 uniforms pushed to shader")
	PostFX.set_grade({"saturation": 0.4}, 0.0)
	_check(is_equal_approx(float(mat.get_shader_parameter("saturation")), 0.4) and PostFX.get_grade_name() == "custom", "partial grade dictionary")
	Events.chapter_started.emit(3)
	await get_tree().create_timer(1.8).timeout
	_check(PostFX.get_grade_name() == "ch03" and is_equal_approx(float(mat.get_shader_parameter("saturation")), 0.70), "chapter_started eases to the chapter grade")
	Game.set_flea(80.0, "test")
	await get_tree().create_timer(1.5).timeout
	_check(float(mat.get_shader_parameter("flea")) > 0.7, "flea overlay follows Game.flea (%.2f)" % float(mat.get_shader_parameter("flea")))
	Game.settings["reduced_motion"] = true
	PostFX.apply_settings()
	_check(is_equal_approx(float(mat.get_shader_parameter("chroma_amount")), 0.0) and is_equal_approx(float(mat.get_shader_parameter("flea_motion")), 0.0), "Reduced Motion: chroma 0, no flea motion")
	Game.settings["reduced_motion"] = false
	Game.settings["quality"] = "low"
	PostFX.apply_settings()
	_check(not PostFX.is_enabled(), "quality low disables the pass")
	Game.settings["quality"] = "auto"
	PostFX.apply_settings()
	_check(PostFX.is_enabled(), "quality auto re-enables it")
	print("RESULT: %s" % ("ALL PASS" if _fails == 0 else "%d FAILED" % _fails))
	get_tree().quit(0 if _fails == 0 else 1)
