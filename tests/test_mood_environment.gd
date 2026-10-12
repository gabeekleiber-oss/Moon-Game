extends Node
## Headless test for MoodEnvironment: looks, easing, grade following, Unreality and the quality ladder.

var _fails := 0

func _check(cond: bool, what: String) -> void:
	print(("PASS " if cond else "FAIL ") + what)
	if not cond:
		_fails += 1

func _ready() -> void:
	Unreality.force(0.0)
	Game.settings["quality"] = "high"
	var m := MoodEnvironment.new()
	m.look = "night_dark"
	add_child(m)
	await get_tree().process_frame
	_check(m.environment != null and m.get_look() == "night_dark", "creates its own Environment and starts in night_dark")
	_check(m.environment.volumetric_fog_enabled and m.environment.ssao_enabled, "night_dark shows volumetric fog and SSAO at high quality")
	var dark_ambient := m.environment.ambient_light_energy
	m.set_look("day", 0.0)
	await get_tree().process_frame
	_check(m.get_look() == "day" and m.environment.ambient_light_energy > dark_ambient + 0.3 and m.environment.sky != null, "set_look(day, 0) switches at once (sky, brighter)")
	m.set_look("fire", 1.0)
	await get_tree().process_frame
	_check(m.get_look() == "fire" and m.environment.ambient_light_energy > 0.06, "an eased look is mid-way after one frame")
	await get_tree().create_timer(1.3).timeout   # headless frames run uncapped, so wait in real time
	await get_tree().process_frame
	_check(absf(m.environment.ambient_light_energy - 0.06) < 0.02, "an eased look arrives at its target")
	m.set_look("nonsense", 0.0)
	_check(m.get_look() == "fire", "unknown look names are ignored")
	# Unreality.
	m.set_look("night_dark", 0.0)
	Unreality.force(0.0)
	await get_tree().process_frame
	var fog0 := m.environment.fog_density
	Unreality.force(0.9)
	await get_tree().process_frame
	await get_tree().process_frame
	_check(m.environment.fog_density > fog0 * 2.0, "Unreality thickens the fog (%.4f -> %.4f)" % [fog0, m.environment.fog_density])
	Unreality.force(0.0)
	# Quality ladder.
	Game.settings["quality"] = "low"
	await get_tree().process_frame
	await get_tree().process_frame
	_check(not m.environment.ssao_enabled and not m.environment.volumetric_fog_enabled, "quality low drops SSAO and volumetric fog")
	Game.settings["quality"] = "high"
	await get_tree().process_frame
	await get_tree().process_frame
	_check(m.environment.ssao_enabled, "back to high restores them")
	# Follow the PostFX grade.
	m.follow_grade = true
	PostFX.set_base_grade("fire_night", 0.0)
	await get_tree().process_frame
	await get_tree().process_frame
	_check(m.get_look() == "fire", "follow_grade: fire_night grade -> fire look")
	PostFX.set_base_grade("dawn_dome", 0.0)
	await get_tree().process_frame
	await get_tree().process_frame
	_check(m.get_look() == "dawn", "follow_grade: dawn_dome grade -> dawn look")
	PostFX.set_base_grade("neutral", 0.0)
	Unreality.force(0.0)
	print("DONE %d failures" % _fails)
	get_tree().quit(1 if _fails > 0 else 0)
