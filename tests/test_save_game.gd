extends Node
const TEST_PATH := "user://test_savegame.json"
var _fails := 0

func _check(condition: bool, message: String) -> void:
	print(("PASS " if condition else "FAIL ") + message)
	if not condition:
		_fails += 1

func _write(p: String, text: String) -> void:
	var f := FileAccess.open(p, FileAccess.WRITE)
	f.store_string(text)
	f.close()

func _ready() -> void:
	var real_path: String = SaveGame.path
	SaveGame.path = TEST_PATH
	SaveGame.delete_save()
	SaveGame.session_active = false
	_check(not SaveGame.has_save(), "no save at start")
	_check(not await SaveGame.continue_game(), "continue with no save returns false and changes nothing")

	# Build some state and save it.
	SaveGame.reset_state()
	Acts.current_id = 1
	Game.set_flag("took_letter")
	Game.bump("shoo_kicks", 3.0)
	Game.furthest_act = 2
	Unreality.force(0.4, true)
	Events.beat_completed.emit(1, "intruder")
	Events.beat_completed.emit(1, "finger")
	_check(SaveGame.save_now("test") == OK, "save_now succeeds")
	var data := SaveGame.read_save()
	_check(not data.is_empty() and data["flags"].has("took_letter") and int(data["furthest_act"]) == 2, "save round-trips flags and furthest act")
	_check(data["beats"]["1"] == ["intruder", "finger"], "completed beats are recorded per act in order")
	_check(is_equal_approx(float(data["unreality"]["base"]), 0.4), "unreality is recorded")

	# Backup and corruption handling.
	_check(SaveGame.save_now("second") == OK and FileAccess.file_exists(TEST_PATH + ".bak"), "second save keeps a .bak of the previous one")
	_write(TEST_PATH, "{ this is not json")
	_check(not SaveGame.read_save().is_empty(), "corrupt main file falls back to the backup")
	_write(TEST_PATH + ".bak", "[]")
	_check(SaveGame.read_save().is_empty() and not SaveGame.has_save(), "corrupt main and backup read as no save")
	var good := data.duplicate(true)
	var bad_version := good.duplicate(true)
	bad_version["version"] = 99
	_write(TEST_PATH, JSON.stringify(bad_version))
	_write(TEST_PATH + ".bak", "")
	_check(SaveGame.read_save().is_empty(), "unknown save version is rejected")
	var bad_act := good.duplicate(true)
	bad_act["act"] = 99
	_write(TEST_PATH, JSON.stringify(bad_act))
	_check(SaveGame.read_save().is_empty(), "out-of-range act is rejected")
	var bad_shape := good.duplicate(true)
	bad_shape["flags"] = [1, 2]
	_write(TEST_PATH, JSON.stringify(bad_shape))
	_check(SaveGame.read_save().is_empty(), "wrong-shaped fields are rejected")

	# Full Continue: reset everything, then restore through the real act scene.
	_write(TEST_PATH, JSON.stringify(good))
	SaveGame.reset_state()
	_check(Game.flags.is_empty() and Game.furthest_act == 1 and Unreality.model.base == 0.0, "reset_state clears flags, acts and unreality")
	_check(await SaveGame.continue_game(), "continue succeeds with a valid save")
	var act: Node = Acts._current
	_check(act != null and Acts.current_id == 1, "continue re-enters the saved act")
	_check(act.beats.is_done("intruder") and act.beats.is_done("finger") and not act.beats.is_done("letter"), "continue restores completed beats before the act builds")
	_check(Game.has_flag("took_letter") and is_equal_approx(Game.counters.get("shoo_kicks", 0.0), 3.0) and Game.furthest_act == 2, "continue restores flags, counters, furthest act")
	_check(absf(Unreality.level - 0.4) < 0.05, "continue restores the hidden unreality value")
	_check(SaveGame._pending_beats.is_empty(), "queued beats are applied once, not reused by a later act load")
	_check(SaveGame.session_active, "continue turns autosave on")

	# Autosave is gated by session_active.
	SaveGame.delete_save()
	SaveGame.session_active = false
	Events.beat_completed.emit(1, "letter")
	await get_tree().process_frame
	await get_tree().process_frame
	_check(not FileAccess.file_exists(TEST_PATH), "no autosave outside a session (direct scene launches never touch saves)")
	SaveGame.begin_session()
	Events.beat_completed.emit(1, "shoo")
	Events.beat_completed.emit(1, "kitchen_items")
	await get_tree().process_frame
	await get_tree().process_frame
	var auto := SaveGame.read_save()
	_check(not auto.is_empty() and (auto["beats"]["1"] as Array).has("shoo"), "autosave writes after beats once a session is active")

	# Cleanup.
	SaveGame.delete_save()
	SaveGame.session_active = false
	SaveGame.reset_state()
	SaveGame.path = real_path
	if act != null:
		act.queue_free()
	print("RESULT: %s" % ("ALL PASS" if _fails == 0 else "%d FAILED" % _fails))
	get_tree().quit(0 if _fails == 0 else 1)
