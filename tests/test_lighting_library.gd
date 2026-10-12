extends Node
## Headless contract test for the lighting preset library and practical light budgets.

const Lighting = preload("res://scenes/world/lighting/lighting_library.gd")

var _fails: int = 0

func _check(condition: bool, message: String) -> void:
	print(("PASS " if condition else "FAIL ") + message)
	if not condition:
		_fails += 1

func _ready() -> void:
	for preset: String in Lighting.PRESETS:
		var env: Environment = Lighting.make_environment(preset)
		_check(env != null, "%s environment exists" % preset)
		_check(env.ssao_enabled, "%s enables SSAO" % preset)
		_check(env.glow_enabled, "%s enables restrained glow" % preset)
		_check(env.tonemap_mode == Environment.TONE_MAPPER_FILMIC, "%s uses filmic tonemapping" % preset)
	var warm: OmniLight3D = Lighting.practical_warm_light()
	var cool: SpotLight3D = Lighting.window_cool_light()
	var tv: OmniLight3D = Lighting.tv_glow()
	var candle: OmniLight3D = Lighting.candle_light()
	var moon: DirectionalLight3D = Lighting.moon_light()
	_check(not warm.shadow_enabled and not cool.shadow_enabled, "practical lights default to no dynamic shadows")
	_check(warm.omni_range > 0.0 and cool.spot_range > 0.0 and tv.omni_range > 0.0, "practical lights have positive ranges")
	_check(warm.light_color.r > warm.light_color.b, "warm practical light has a warm colour")
	_check(cool.light_color.b > cool.light_color.r, "window light has a cool colour")
	_check(not tv.shadow_enabled, "TV glow does not cast dynamic shadows")
	_check(candle.omni_range < warm.omni_range and candle.light_energy > 0.0, "candle is warm and close-range")
	_check(moon.light_color.b > moon.light_color.r and moon.shadow_enabled, "moon key is cool and casts shadows by default")
	warm.free()
	cool.free()
	tv.free()
	candle.free()
	moon.free()
	print("FAILED: %d" % _fails if _fails else "ALL PASSED")
	get_tree().quit(1 if _fails else 0)
