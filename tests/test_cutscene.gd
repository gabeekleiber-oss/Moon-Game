extends Node
## Headless test for the Cutscene autoload. Run: godot --headless --path . res://tests/test_cutscene.tscn
var _fails := 0
var _ev := {"started": 0, "ended": 0, "last_skipped": null}

func _check(cond: bool, what: String) -> void:
	print(("PASS " if cond else "FAIL ") + what)
	if not cond:
		_fails += 1

func _ready() -> void:
	Events.cutscene_started.connect(func(_i: String) -> void: _ev["started"] += 1)
	Events.cutscene_ended.connect(func(_i: String, s: bool) -> void: _ev["ended"] += 1; _ev["last_skipped"] = s)
	Game.flags.clear()
	_check(not Cutscene.is_active(), "inactive at start")

	# 1. normal run
	var mid := {}
	var skipped: bool = await Cutscene.play(func() -> void:
		mid["active"] = Cutscene.is_active()
		await Cutscene.letterbox(true, 0.15)
		mid["bars"] = Cutscene.letterbox_amount()
		await Cutscene.fade_out(0.15)
		mid["fade"] = Cutscene.fade_alpha()
		await Cutscene.wait(0.1)
		await Cutscene.fade_in(0.1)
		Game.set_flag("cs_normal_end"))
	_check(not skipped, "play() returns false when not skipped")
	_check(mid["active"], "active during the cutscene")
	_check(is_equal_approx(mid["bars"], 1.0) and is_equal_approx(mid["fade"], 1.0), "letterbox and fade completed (bars %.2f fade %.2f)" % [mid["bars"], mid["fade"]])
	_check(Game.has_flag("cs_normal_end") and not Cutscene.is_active(), "end-state set, inactive afterwards")
	_check(is_equal_approx(Cutscene.letterbox_amount(), 0.0) and is_equal_approx(Cutscene.fade_alpha(), 0.0), "bars out, fade clear")
	_check(_ev["started"] == 1 and _ev["ended"] == 1 and _ev["last_skipped"] == false, "started/ended events fired once, skipped=false")

	# 2. skip fast-forwards: long waits collapse, end-state still set
	var t0 := Time.get_ticks_msec()
	var timer := get_tree().create_timer(0.3)
	timer.timeout.connect(func() -> void: Cutscene.request_skip())
	var sk: bool = await Cutscene.play(func() -> void:
		await Cutscene.letterbox(true, 3.0)
		await Cutscene.fade_out(3.0)
		await Cutscene.wait(5.0)
		await Cutscene.fade_in(3.0)
		Game.set_flag("cs_skip_end"))
	var took := (Time.get_ticks_msec() - t0) / 1000.0
	_check(sk, "play() returns true when skipped")
	_check(took < 1.5, "skip fast-forwarded a 14 s cutscene in %.2f s" % took)
	_check(Game.has_flag("cs_skip_end"), "end-state flag still set after skip")
	_check(_ev["ended"] == 2 and _ev["last_skipped"] == true, "cutscene_ended skipped=true")
	await get_tree().process_frame
	_check(is_equal_approx(Cutscene.fade_alpha(), 0.0) and is_equal_approx(Cutscene.letterbox_amount(), 0.0), "screen clean after skipped cutscene")

	# 3. busy refusal
	var running := [true]
	_long(running)
	await get_tree().process_frame
	_check(Cutscene.is_active() and not await Cutscene.play(func() -> void: pass), "second play() while active is refused")
	Cutscene.request_skip()
	await get_tree().create_timer(0.2).timeout
	_check(not Cutscene.is_active(), "first cutscene finished after skip")

	# 4. skip stops a running dialogue
	var dlg_t := get_tree().create_timer(0.5)
	dlg_t.timeout.connect(func() -> void: Cutscene.request_skip())
	await Cutscene.play(func() -> void:
		Dialogue.play("_sample")
		await Cutscene.wait(10.0))
	await get_tree().process_frame
	_check(not Dialogue.is_active(), "skip stopped the running dialogue")

	# 5. hold Space (jump action) skips after ~1 s; a tap does not
	var hold_done := [false, false]
	_hold_run(hold_done)
	await get_tree().create_timer(0.2).timeout
	Input.action_press("jump")
	await get_tree().create_timer(0.3).timeout
	Input.action_release("jump")
	await get_tree().create_timer(0.1).timeout
	_check(Cutscene.is_active() and not Cutscene.is_skipping(), "a short tap does not skip")
	Input.action_press("jump")
	await get_tree().create_timer(1.4).timeout
	Input.action_release("jump")
	await get_tree().create_timer(0.2).timeout
	_check(hold_done[0] and hold_done[1], "holding Space ~1 s skipped the cutscene")

	# 6. act title card
	Cutscene.request_skip()   # no-op (inactive) - just proves it is safe
	var card_skipped: bool = await Cutscene.act_card(4, 0.2)
	_check(not card_skipped and not Cutscene.is_active(), "act_card(4) ran standalone and finished")
	_check(Cutscene._title_main.text == "The First Night of Rooms" and Cutscene._title_kicker.text == "ACT 4", "card shows act number and title")
	_check(is_equal_approx(Cutscene.fade_alpha(), 0.0) and not Cutscene._title_root.visible, "screen clear + card hidden afterwards")
	var cs_t := get_tree().create_timer(0.4)
	cs_t.timeout.connect(func() -> void: Cutscene.request_skip())
	var t1 := Time.get_ticks_msec()
	var card_sk: bool = await Cutscene.act_card(9, 10.0)
	_check(card_sk and (Time.get_ticks_msec() - t1) < 2500, "skipping a 10 s title card fast-forwards (%d ms)" % (Time.get_ticks_msec() - t1))
	_check(is_equal_approx(Cutscene.fade_alpha(), 0.0) and not Cutscene._title_root.visible, "skipped card leaves a clean screen")

	# 7. camera presets
	var pcam := Camera3D.new()
	add_child(pcam)
	pcam.global_position = Vector3(0, 1.6, 5)
	pcam.current = true
	var tgt := Node3D.new()
	add_child(tgt)
	tgt.global_position = Vector3(10, 0, 0)
	await Cutscene.play(func() -> void:
		await Cutscene.cam("close", tgt, 0.1)
		var cc: Camera3D = Cutscene._cam
		_check(cc.current and not pcam.current, "cam() takes over from the player camera")
		_check(cc.global_position.distance_to(Vector3(10.35, 1.6, -1.4)) < 0.01, "close preset is in front (-Z) of the target")
		var want := (Vector3(10, 1.6, 0) - cc.global_position).normalized()
		_check((-cc.global_transform.basis.z).dot(want) > 0.999 and is_equal_approx(cc.fov, 42.0), "camera aims at the target, fov 42")
		await Cutscene.cam("wide", tgt, 0.1, true)
		_check(cc.global_position.z > 5.9, "behind=true mirrors the offset to +Z")
		await Cutscene.cam("dutch", tgt, 0.1)
		_check(absf(cc.global_transform.basis.x.y) > 0.15, "dutch preset rolls the camera")
		await Cutscene.cam("top", tgt, 0.1)
		_check((-cc.global_transform.basis.z).y < -0.99, "top preset looks straight down")
		await Cutscene.cam("close", tgt, 0.0)
		cc.h_offset = 0.0
		Game.settings["reduced_motion"] = true
		await Cutscene.shake(1.0, 0.2)
		_check(is_equal_approx(cc.h_offset, 0.0), "shake is a no-op under Reduced Motion")
		Game.settings["reduced_motion"] = false)
	_check(pcam.current and not Cutscene._cam_active, "play() released the camera back to the player at the end")
	# dialogue cam cue on Cutscene.focus
	Cutscene.focus = tgt
	Events.dialogue_cue.emit("cam", "medium")
	await get_tree().create_timer(1.3).timeout
	_check(Cutscene._cam_active and Cutscene._cam.current, "dialogue cam cue frames Cutscene.focus")
	Events.dialogue_cue.emit("cam", "release")
	await get_tree().create_timer(1.1).timeout
	_check(pcam.current and not Cutscene._cam_active, "dialogue cam 'release' returns the player camera")

	print("RESULT: %s" % ("ALL PASS" if _fails == 0 else "%d FAILED" % _fails))
	get_tree().quit(0 if _fails == 0 else 1)

func _long(flag: Array) -> void:
	await Cutscene.play(func() -> void: await Cutscene.wait(20.0))
	flag[0] = false

func _hold_run(done: Array) -> void:
	var s: bool = await Cutscene.play(func() -> void: await Cutscene.wait(20.0))
	done[0] = true
	done[1] = s
