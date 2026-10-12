extends Node
## Headless test for PostFX + UnrealGrade (the picture degrading with the hidden Unreality value).

var _fails := 0

func _check(cond: bool, what: String) -> void:
	print(("PASS " if cond else "FAIL ") + what)
	if not cond:
		_fails += 1

func _ready() -> void:
	_check(is_instance_valid(PostFX) and PostFX.is_enabled(), "PostFX autoload exists and is enabled")
	for n in UnrealGrade.names():
		var g := UnrealGrade.get_base(n)
		_check(g.has("tint") and g.has("saturation") and float(g["saturation"]) > 0.0, "base grade '%s' is complete" % n)
	for act in Acts.ACTS:
		pass
	var neutral := UnrealGrade.compose(UnrealGrade.NEUTRAL, 0.0)
	_check(is_equal_approx(float(neutral["saturation"]), 1.0) and float(neutral["warp"]) == 0.0 and float(neutral["ghost"]) == 0.0, "level 0 adds no distortion")
	var ruin := UnrealGrade.compose(UnrealGrade.NEUTRAL, 1.0)
	_check(float(ruin["warp"]) > 0.05 and float(ruin["ghost"]) > 0.4 and float(ruin["chroma_mult"]) > 4.0 and float(ruin["specks"]) > 0.5, "level 1 warps, doubles, splits colour and spawns fleas")
	var mid := UnrealGrade.compose(UnrealGrade.NEUTRAL, 0.55)
	_check(float(mid["saturation"]) < 0.8, "mid levels drain colour (%.2f)" % float(mid["saturation"]))
	_check(float(ruin["saturation"]) > float(mid["saturation"]) and float(ruin["saturation"]) > 1.2, "ruin over-saturates")
	var still := UnrealGrade.compose(UnrealGrade.NEUTRAL, 1.0, 0.0)
	_check(float(still["wobble"]) == 0.0 and float(still["specks"]) == 0.0, "motion 0 (Reduced Motion) removes wobble and specks")
	var prev := -1.0
	var monotonic := true
	for i in 11:
		var v := float(UnrealGrade.compose(UnrealGrade.NEUTRAL, i / 10.0)["vignette_strength"])
		monotonic = monotonic and v >= prev
		prev = v
	_check(monotonic, "the vignette only ever closes in as unreality rises")
	PostFX.set_base_grade("lake_dusk", 0.0)
	_check(PostFX.get_grade_name() == "lake_dusk", "set_base_grade by name")
	var mat: ShaderMaterial = PostFX._mat
	Unreality.force(0.8)
	await get_tree().process_frame
	await get_tree().process_frame
	_check(float(mat.get_shader_parameter("unreal")) > 0.7 and float(mat.get_shader_parameter("warp")) > 0.02, "shader uniforms follow Unreality.level")
	PostFX.set_base_grade({"saturation": 0.4}, 0.0)
	_check(PostFX.get_grade_name() == "custom", "partial grade dictionary")
	Game.settings["reduced_motion"] = true
	PostFX.apply_settings()
	await get_tree().process_frame
	_check(is_equal_approx(float(mat.get_shader_parameter("chroma_amount")), 0.0) and float(mat.get_shader_parameter("specks")) == 0.0, "Reduced Motion: chroma 0, no specks")
	Game.settings["reduced_motion"] = false
	Game.settings["quality"] = "low"
	PostFX.apply_settings()
	_check(not PostFX.is_enabled(), "quality low disables the pass")
	Game.settings["quality"] = "auto"
	PostFX.apply_settings()
	_check(PostFX.is_enabled(), "quality auto re-enables it")
	Unreality.force(0.0)
	print("FAILED: %d" % _fails if _fails else "ALL PASSED")
	get_tree().quit(1 if _fails else 0)
