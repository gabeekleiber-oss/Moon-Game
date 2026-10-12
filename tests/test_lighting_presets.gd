extends Node
## Headless test for the S-01 environment preset library (EnvPresets): completeness, darkness, quality ladder, Unreality, easing.

var _fails := 0

func _check(cond: bool, what: String) -> void:
	print(("PASS " if cond else "FAIL ") + what)
	if not cond:
		_fails += 1

## Environment stores 32-bit floats, so compare numbers and colours approximately.
func _same(a: Variant, b: Variant) -> bool:
	if a is float and b is float:
		return absf(a - b) < 0.0001
	if a is Color and b is Color:
		return (a as Color).is_equal_approx(b)
	return a == b

func _ready() -> void:
	var looks := EnvPresets.names()
	_check(looks.size() == 5 and "night_dark" in looks and "dawn" in looks and "dream" in looks and "day" in looks and "fire" in looks, "five looks: night_dark, dawn, dream, day, fire")
	for n in looks:
		var env := EnvPresets.build(n)
		_check(env.ssao_enabled and env.glow_enabled and env.fog_enabled and env.adjustment_enabled, "'%s' has SSAO, glow, fog and adjustment on" % n)
		_check(env.tonemap_mode != Environment.TONE_MAPPER_LINEAR, "'%s' uses a filmic/ACES tonemap" % n)
		var p := EnvPresets.get_preset(n)
		var mismatch := ""
		for k in p:
			if String(k) in EnvPresets.SPECIAL_KEYS:
				continue
			if not _same(env.get(k), p[k]):
				mismatch = String(k)
				break
		_check(mismatch == "", "'%s': every parameter really lands on the Environment %s" % [n, mismatch])
	# Real darkness (ART_BIBLE 4): night looks do not ambient-fill.
	for n in ["night_dark", "fire"]:
		_check(float(EnvPresets.get_preset(n)["ambient_light_energy"]) <= 0.08, "'%s' keeps ambient light tiny (real darkness)" % n)
	_check(EnvPresets.build("dawn").sky != null and EnvPresets.build("day").sky != null, "dawn and day have a procedural sky")
	_check(EnvPresets.build("fire").volumetric_fog_emission_energy > 0.0, "fire's air glows (volumetric emission)")
	# Every location mood maps to a look.
	for g in UnrealGrade.names():
		_check(EnvPresets.names().has(EnvPresets.for_grade(g)), "grade '%s' maps to a look (%s)" % [g, EnvPresets.for_grade(g)])
	# Quality ladder.
	var hi := EnvPresets.for_quality(EnvPresets.get_preset("dawn"), "high")
	var lo := EnvPresets.for_quality(EnvPresets.get_preset("dawn"), "low")
	_check(bool(hi["volumetric_fog_enabled"]) and not bool(lo["volumetric_fog_enabled"]) and not bool(lo["ssao_enabled"]), "low quality drops volumetric fog and SSAO")
	_check(EnvPresets.for_quality(EnvPresets.get_preset("dawn"), "auto") == hi, "'auto' behaves like high")
	# Unreality: thicker, never brighter.
	var base := EnvPresets.get_preset("night_dark")
	var prev_fog := 0.0
	var mono := true
	for i in 11:
		var q := EnvPresets.with_unreality(base, i / 10.0)
		mono = mono and float(q["fog_density"]) >= prev_fog
		prev_fog = float(q["fog_density"])
	_check(mono, "fog only ever thickens as Unreality rises")
	var zero := EnvPresets.with_unreality(base, 0.0)
	_check(zero["fog_density"] == base["fog_density"] and zero["glow_intensity"] == base["glow_intensity"], "level 0 changes nothing")
	var ruin := EnvPresets.with_unreality(base, 1.0)
	_check(float(ruin["tonemap_exposure"]) <= float(base["tonemap_exposure"]) and float(ruin["fog_density"]) > 2.0 * float(base["fog_density"]), "ruin is thicker and not brighter")
	# Easing.
	var mid := EnvPresets.lerp_params(EnvPresets.get_preset("night_dark"), EnvPresets.get_preset("day"), 0.5)
	var a := float(EnvPresets.get_preset("night_dark")["ambient_light_energy"])
	var b := float(EnvPresets.get_preset("day")["ambient_light_energy"])
	_check(is_equal_approx(float(mid["ambient_light_energy"]), (a + b) * 0.5), "lerp_params blends floats")
	_check(EnvPresets.lerp_params(base, EnvPresets.get_preset("day"), 0.0)["background_mode"] == base["background_mode"], "lerp_params t=0 is the start")
	print("DONE %d failures" % _fails)
	get_tree().quit(1 if _fails > 0 else 0)
