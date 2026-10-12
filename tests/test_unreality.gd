extends Node
## Headless test for the hidden insanity value (UnrealityModel maths + the Unreality autoload).

var _fails := 0

func _check(cond: bool, what: String) -> void:
	print(("PASS " if cond else "FAIL ") + what)
	if not cond:
		_fails += 1

func _ready() -> void:
	var m := UnrealityModel.new()
	m.drift_per_minute = 0.0
	m.raise(0.3)
	for i in 600:
		m.step(0.1)
	_check(absf(m.level - 0.3) < 0.01, "level eases to the raised base (%.3f)" % m.level)
	m.raise(-0.2)
	_check(m.base >= 0.3, "raise never lowers the base")
	m.jolt(0.4)
	_check(m.target() > 0.65, "a jolt lifts the target")
	for i in 3000:
		m.step(0.1)
	_check(m.spike < 0.01 and absf(m.level - 0.3) < 0.02, "the jolt decays back to the base")
	var d := UnrealityModel.new()
	d.drift_per_minute = 0.06
	for i in 6000:                    # 10 simulated minutes
		d.step(0.1)
	_check(d.base > 0.5 and d.base < 0.7, "slow drift creeps the base up (%.2f after 10 min)" % d.base)
	var f := UnrealityModel.new()
	f.drift_per_minute = 0.0
	f.floor_ = 0.4
	f.step(0.1)
	_check(f.base >= 0.4, "the act floor lifts the base")
	_check(UnrealityModel.band_of(0.0) == 0 and UnrealityModel.band_of(0.2) == 1 and UnrealityModel.band_of(0.4) == 2 and UnrealityModel.band_of(0.6) == 3 and UnrealityModel.band_of(0.8) == 4 and UnrealityModel.band_of(0.95) == 5, "band edges")
	_check(is_equal_approx(UnrealityModel.ramp_of(0.2, 0.3, 0.7), 0.0) and is_equal_approx(UnrealityModel.ramp_of(0.9, 0.3, 0.7), 1.0), "ramp remaps and clamps")
	_check(UnrealityModel.hash01("a") == UnrealityModel.hash01("a") and UnrealityModel.hash01("a") != UnrealityModel.hash01("b"), "hash01 is stable and varies")
	# autoload
	Unreality.force(0.0)
	Unreality.frozen = false
	var heard := [0]
	Events.unreality_changed.connect(func(_l: float, _d: float, _r: String) -> void: heard[0] += 1)
	var bands: Array = []
	Events.unreality_band_changed.connect(func(b: int, _n: String) -> void: bands.append(b))
	Unreality.raise_to(0.5, "test")
	for i in 120:
		await get_tree().process_frame
	_check(heard[0] > 0 and Unreality.level > 0.2, "the autoload eases up and announces changes (level %.2f)" % Unreality.level)
	_check(not bands.is_empty() and Unreality.band() >= 1, "band_changed fires (bands %s)" % str(bands))
	Unreality.force(0.6)
	_check(Unreality.wrongs("zzz_low", -0.9) and not Unreality.wrongs("zzz_high", 0.9), "wrongs() is per-object and bias works")
	var order := []
	for id in ["a", "b", "c", "d", "e", "f"]:
		order.append(UnrealityModel.hash01(id))
	_check(order.size() == 6, "thresholds exist for each object")
	Game.settings["reduced_motion"] = true
	_check(Unreality.motion_scale() == 0.0, "Reduced Motion zeroes motion_scale")
	Game.settings["reduced_motion"] = false
	_check(Unreality.motion_scale() == 1.0, "motion_scale is 1 normally")
	Unreality.force(0.0)
	print("FAILED: %d" % _fails if _fails else "ALL PASSED")
	get_tree().quit(1 if _fails else 0)
