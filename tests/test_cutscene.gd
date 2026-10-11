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
		mid["hud_hidden"] = not Hud.is_hud_visible()
		await Cutscene.letterbox(true, 0.15)
		mid["bars"] = Cutscene.letterbox_amount()
		await Cutscene.fade_out(0.15)
		mid["fade"] = Cutscene.fade_alpha()
		await Cutscene.wait(0.1)
		await Cutscene.fade_in(0.1)
		Game.set_flag("cs_normal_end"))
	_check(not skipped, "play() returns false when not skipped")
	_check(mid["active"] and mid["hud_hidden"], "active + HUD hidden during the cutscene")
	_check(is_equal_approx(mid["bars"], 1.0) and is_equal_approx(mid["fade"], 1.0), "letterbox and fade completed (bars %.2f fade %.2f)" % [mid["bars"], mid["fade"]])
	_check(Game.has_flag("cs_normal_end") and not Cutscene.is_active(), "end-state set, inactive afterwards")
	_check(Hud.is_hud_visible() and is_equal_approx(Cutscene.letterbox_amount(), 0.0) and is_equal_approx(Cutscene.fade_alpha(), 0.0), "HUD restored, bars out, fade clear")
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

	print("RESULT: %s" % ("ALL PASS" if _fails == 0 else "%d FAILED" % _fails))
	get_tree().quit(0 if _fails == 0 else 1)

func _long(flag: Array) -> void:
	await Cutscene.play(func() -> void: await Cutscene.wait(20.0))
	flag[0] = false

func _hold_run(done: Array) -> void:
	var s: bool = await Cutscene.play(func() -> void: await Cutscene.wait(20.0))
	done[0] = true
	done[1] = s
