extends Node
## Headless test for GameSettings. Run: godot --headless --path . res://tests/test_settings.tscn
var _fails := 0
const TMP := "user://_test_settings.json"

func _check(cond: bool, what: String) -> void:
	print(("PASS " if cond else "FAIL ") + what)
	if not cond:
		_fails += 1

func _ready() -> void:
	GameSettings.path = TMP
	DirAccess.remove_absolute(TMP)
	_check(GameSettings.sanitize("volume", 5) == 1.0 and GameSettings.sanitize("volume", -1) == 0.0, "volume clamps to 0..1")
	_check(GameSettings.sanitize("quality", "ultra") == "auto" and GameSettings.sanitize("quality", "low") == "low", "quality validates")
	_check(GameSettings.sanitize("quality", "medium") == "medium", "medium quality accepted")
	_check(GameSettings.sanitize("sensitivity", 99.0) == GameSettings.SENSITIVITY_MAX and GameSettings.sanitize("sensitivity", "x") == GameSettings.DEFAULTS["sensitivity"], "sensitivity clamps / rejects junk")
	_check(GameSettings.sanitize("assist", "yes") == false and GameSettings.sanitize("assist", true) == true and GameSettings.sanitize("nope", 1) == null, "bools strict, unknown key null")

	var changed: Array = []
	Events.settings_changed.connect(func(k: String) -> void: changed.append(k))
	_check(GameSettings.needs_first_run_setup(), "fresh installation needs initial settings check")
	GameSettings.load_and_apply()
	_check(not GameSettings.needs_first_run_setup(), "first-run setup clears after defaults are saved")
	_check(Game.settings["volume"] == 0.8 and not Game.settings["reduced_motion"], "missing file -> defaults")
	_check(FileAccess.file_exists(TMP), "first run writes validated default settings file")

	GameSettings.set_value("volume", 0.5)
	_check(is_equal_approx(float(Game.settings["volume"]), 0.5) and changed == ["volume"], "set_value stores + emits settings_changed")
	var bus := AudioServer.get_bus_index("Master")
	_check(absf(AudioServer.get_bus_volume_db(bus) - linear_to_db(0.5)) < 0.01, "volume applied to the Master bus (%.1f dB)" % AudioServer.get_bus_volume_db(bus))
	GameSettings.set_value("volume", 0.0)
	_check(AudioServer.is_bus_mute(bus), "volume 0 mutes the bus")
	GameSettings.set_value("quality", "medium")
	_check(is_equal_approx(get_tree().root.scaling_3d_scale, 0.85), "quality medium -> 3D scale 0.85")
	GameSettings.set_value("quality", "low")
	_check(is_equal_approx(get_tree().root.scaling_3d_scale, 0.67), "quality low -> 3D scale 0.67")
	GameSettings.set_value("reduced_motion", true)
	GameSettings.set_value("assist", true)
	GameSettings.set_value("sensitivity", 0.004)
	GameSettings.set_value("bogus", 1)
	_check(not Game.settings.has("bogus"), "unknown key ignored")

	# round trip through disk
	Game.settings["volume"] = 0.1
	Game.settings["quality"] = "high"
	GameSettings.load_and_apply()
	_check(Game.settings["quality"] == "low" and Game.settings["reduced_motion"] and Game.settings["assist"] and is_equal_approx(float(Game.settings["sensitivity"]), 0.004) and is_equal_approx(float(Game.settings["volume"]), 0.0), "settings survive a reload from disk")

	# hand-edited / corrupt files never crash
	var f := FileAccess.open(TMP, FileAccess.WRITE)
	f.store_string('{"volume": 7, "quality": "ultra", "assist": "maybe", "mystery": 1}')
	f.close()
	GameSettings.load_and_apply()
	_check(Game.settings["volume"] == 1.0 and Game.settings["quality"] == "auto" and Game.settings["assist"] == false, "bad values in the file are sanitised")
	f = FileAccess.open(TMP, FileAccess.WRITE)
	f.store_string("not json at all {{{")
	f.close()
	GameSettings.load_and_apply()
	_check(Game.settings["volume"] == 0.8 and Game.settings["quality"] == "auto", "garbage file -> defaults")

	GameSettings.reset_to_defaults()
	_check(Game.settings["volume"] == 0.8 and is_equal_approx(get_tree().root.scaling_3d_scale, 1.0), "reset_to_defaults restores and applies")
	# leave the real settings file untouched
	DirAccess.remove_absolute(TMP)
	GameSettings.path = "user://settings.json"
	print("RESULT: %s" % ("ALL PASS" if _fails == 0 else "%d FAILED" % _fails))
	get_tree().quit(0 if _fails == 0 else 1)
