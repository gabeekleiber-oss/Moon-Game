extends Node
## Headless test for the S-01 light helpers and LightFlicker (no strobing, Reduced Motion, Unreality, shadow budget defaults).

var _fails := 0

func _check(cond: bool, what: String) -> void:
	print(("PASS " if cond else "FAIL ") + what)
	if not cond:
		_fails += 1

func _sample(fn: Callable, seconds: float, dt: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	var n := int(seconds / dt)
	for i in n:
		out.append(float(fn.call(i * dt)))
	return out

func _ready() -> void:
	Unreality.force(0.0)
	# ---- pure maths
	var worst_tv := 0
	var tv_min := 9.0
	var tv_max := 0.0
	for s in [0, 1, 7, 42, 1234]:
		var smp := _sample(func(t: float) -> float: return float(LightFlicker.tv(t, s)["energy"]), 30.0, 1.0 / 60.0)
		worst_tv = maxi(worst_tv, LightFlicker.max_changes_per_second(smp, 1.0 / 60.0, 0.1))
		for v in smp:
			tv_min = minf(tv_min, v)
			tv_max = maxf(tv_max, v)
	_check(worst_tv <= 3, "the TV never changes level more than 3 times a second (worst %d)" % worst_tv)
	_check(tv_max - tv_min > 0.3, "the TV still visibly flickers (swing %.2f)" % (tv_max - tv_min))
	var worst_c := 0
	var c_min := 9.0
	var c_max := 0.0
	for s in [0, 3, 9]:
		var smp := _sample(func(t: float) -> float: return LightFlicker.candle(t, s), 30.0, 1.0 / 60.0)
		worst_c = maxi(worst_c, LightFlicker.max_changes_per_second(smp, 1.0 / 60.0, 0.1))
		for v in smp:
			c_min = minf(c_min, v)
			c_max = maxf(c_max, v)
	_check(worst_c <= 3 and c_min > 0.9 and c_max < 1.1, "a candle is alive but gentle (%.3f..%.3f)" % [c_min, c_max])
	var still_tv := LightFlicker.tv(3.3, 5, 0.0)
	_check(is_equal_approx(float(still_tv["energy"]), 1.0) and LightFlicker.candle(3.3, 5, 0.0) == 1.0, "Reduced Motion (motion 0): TV and candle are steady")
	_check(LightFlicker.lamp(2.2, 0.0, 0.0) == 1.0 and LightFlicker.lamp(2.2, 1.0, 1.0, 0, 0.0) == 1.0, "a lamp at level 0, or in Reduced Motion, is exactly steady")
	var lamp_smp := _sample(func(t: float) -> float: return LightFlicker.lamp(t, 1.0, 1.0, 2), 30.0, 1.0 / 60.0)
	var lamp_min := 9.0
	for v in lamp_smp:
		lamp_min = minf(lamp_min, v)
	_check(lamp_min < 0.6 and LightFlicker.max_changes_per_second(lamp_smp, 1.0 / 60.0, 0.1) <= 3, "a 'wrong' lamp drops out (min %.2f) but never strobes" % lamp_min)
	_check(LightFlicker.tv(1.234, 9) == LightFlicker.tv(1.234, 9), "the flicker is deterministic")
	# The detector itself catches a strobe.
	var strobe := PackedFloat32Array()
	for i in 120:
		strobe.append(1.0 if (i / 5) % 2 == 0 else 0.4)   # 60 fps, flips every 5 frames = 12 per second
	_check(LightFlicker.max_changes_per_second(strobe, 1.0 / 60.0, 0.1) > 3, "the detector flags a real strobe")
	# ---- nodes
	var root := Node3D.new()
	add_child(root)
	var lamp := PracticalLamp.new()
	lamp.wrong_id = "lamp_test"
	root.add_child(lamp)
	var candle := CandleLight.new()
	root.add_child(candle)
	var tv := TVLight.new()
	root.add_child(tv)
	var win := WindowLight.new()
	root.add_child(win)
	var moon := MoonLight.new()
	root.add_child(moon)
	await get_tree().process_frame
	await get_tree().process_frame
	_check(lamp.light is OmniLight3D and lamp.bulb != null and not lamp.light.shadow_enabled, "lamp: omni light, visible bulb, no shadows by default")
	_check(not candle.light.shadow_enabled and candle.flame != null, "candle: unshadowed with a flame")
	_check(not tv.light.shadow_enabled and tv.light.light_color.b > tv.light.light_color.r, "tv: unshadowed, cold blue")
	_check(win.light is SpotLight3D and win.light.shadow_enabled, "window: spot light that casts shadows")
	_check(moon.light is DirectionalLight3D and moon.light.shadow_enabled and moon.light.light_color.b > moon.light.light_color.r, "moon: directional, shadowed, cool and milky")
	win.set_kind("night")
	_check(win.light.light_color.b > win.light.light_color.r and win.light.light_energy < 2.0, "window kind 'night' is cold and dim")
	win.set_kind("dawn")
	_check(win.light.light_color.r > win.light.light_color.b, "window kind 'dawn' is warm")
	win.set_kind("bogus")
	_check(win.kind == "day", "unknown window kind falls back to day")
	moon.elevation_deg = 30.0
	_check(is_equal_approx(moon.light.rotation_degrees.x, -30.0), "the moon aims by elevation")
	# Shadow budget by default: window + moon = 2 (ART_BIBLE 4 limit); nothing else casts.
	var casters := 0
	for n in root.find_children("*", "Light3D", true, false):
		if (n as Light3D).shadow_enabled:
			casters += 1
	_check(casters == 2, "default shadow casters = 2 (window + moon), within the budget")
	# Unreality
	Unreality.force(0.0)
	_check(lamp.coldness() == 0.0 and moon.warmth() == 0.0, "no cold lamp / warm moon at level 0")
	Unreality.force(0.95)
	await get_tree().process_frame
	_check(Unreality.wrongs("lamp_test") and lamp.coldness() > 0.9, "at ruin the lamp with a wrong_id has gone cold (%.2f)" % lamp.coldness())
	_check(moon.warmth() > 0.9, "at ruin the moon has gone warm (%.2f)" % moon.warmth())
	var plain := PracticalLamp.new()   # no wrong_id: never goes cold
	root.add_child(plain)
	_check(plain.coldness() == 0.0, "a lamp without a wrong_id never goes cold")
	var min_f := 9.0
	for i in 600:
		min_f = minf(min_f, lamp.factor_at(i * 0.05))
	_check(min_f < 0.7, "at high Unreality the lamp node drops out (min %.2f)" % min_f)
	Unreality.force(0.0)
	print("DONE %d failures" % _fails)
	get_tree().quit(1 if _fails > 0 else 0)
