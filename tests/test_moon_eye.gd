extends Node
## Headless test for F-07 (MoonEye). Run: godot --headless --path . res://tests/test_moon_eye.tscn

var _fails := 0

func _check(cond: bool, what: String) -> void:
	print(("PASS " if cond else "FAIL ") + what)
	if not cond:
		_fails += 1

func _ready() -> void:
	var moon := MoonEye.new()
	add_child(moon)
	await get_tree().process_frame
	_check(moon.openness == 0.0 and not moon.is_open(), "starts closed")
	_check(moon.get_node_or_null("EyeRoot/UpperLid") != null and moon.get_node_or_null("EyeRoot/Eyeball/Cornea") != null, "lids and cornea built")
	var t := moon.open(0.1)
	await t.finished
	_check(moon.is_open(), "open() reaches fully open")
	var blinked := [false]
	moon.blinked.connect(func() -> void: blinked[0] = true)
	await moon.blink(0.1).finished
	_check(blinked[0] and moon.is_open(), "blink() restores openness and emits blinked")
	moon.look_at_point(moon.to_global(Vector3(4, 0, 30)), 0.0)
	var eb: Node3D = moon.get_node("EyeRoot/Eyeball")
	_check((-eb.basis.z).x < 0.0 or (eb.basis.z).x > 0.0, "look_at_point turns the eyeball")
	moon.look_at_point(moon.to_global(Vector3(100, 0, 5)), 0.0)
	_check((eb.basis.z).angle_to(Vector3.BACK) <= deg_to_rad(33.0), "look angle is clamped")
	moon.set_pupil(1.0, 0.0)
	_check(is_equal_approx(moon.pupil_size, 1.0), "set_pupil instant")
	await moon.close(0.1).finished
	_check(moon.openness == 0.0, "close() closes")
	var blank := MoonEye.new()
	blank.eye_enabled = false
	add_child(blank)
	await get_tree().process_frame
	_check(blank.get_node_or_null("EyeRoot") == null and blank.open() == null, "eye_enabled=false is a blank moon")
	print("FAILED: %d" % _fails if _fails else "ALL PASSED")
	get_tree().quit(1 if _fails else 0)
