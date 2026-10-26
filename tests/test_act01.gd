extends Node
## Plays Act 1 start to finish through its real interactions (placeholder props) and checks every beat completes in order.
const ActScene = preload("res://scenes/acts/act01_wisconsin/act01_wisconsin_alt.tscn")
var _fails := 0
var act: Act01

func _check(condition: bool, message: String) -> void:
	print(("PASS " if condition else "FAIL ") + message)
	if not condition:
		_fails += 1

func _settle(frames: int = 3) -> void:
	for i in frames:
		await get_tree().process_frame

func _wait_for(cond: Callable, seconds: float) -> bool:
	var t := 0.0
	while t < seconds:
		if cond.call():
			return true
		await get_tree().create_timer(0.1).timeout
		t += 0.1
	return cond.call()

func _carry() -> Node:
	return act.player.get_node("Head/Camera3D/CarryController")

func _ready() -> void:
	act = ActScene.instantiate()
	act.auto_advance = false
	add_child(act)
	await _settle()
	_check(act.player != null, "player spawned")
	_check(act.beats.count() == 12, "act 1 has 12 beats")
	# 1-2 intruder + finger
	act.start_intruder()
	_check(await _wait_for(func() -> bool: return act.beats.is_done("finger"), 8.0), "intruder and finger beats complete")
	_check(Dialogue.is_active(), "finger dialogue is running")
	Dialogue.stop()
	await _wait_for(func() -> bool: return act.letter_item.enabled, 3.0)
	_check(act.letter_item.enabled, "letter becomes readable after the finger")
	# 3 letter (skip the UI paging, exercise the completion path)
	act.finish_letter()
	_check(act.beats.is_done("letter"), "letter beat")
	# 4 shoo
	act.kick_out()
	_check(act.beats.is_done("shoo"), "shoo beat")
	await _settle()
	# 5 kitchen items
	act.player.global_position = Vector3(1.5, 0.1, 7.5)
	for item in [act.yam, act.solution]:
		_check(item.can_use(), item.name + " usable after shoo")
		item.use(act.player)
		await _settle()
		_check(item.held, item.name + " picked up")
		_carry().call("drop_item")
		await _settle()
	_check(await _wait_for(func() -> bool: return act.beats.is_done("kitchen_items"), 2.0), "kitchen_items beat after both set on the floor")
	await _settle()
	# 6 broom
	_check(act.broom.can_use(), "broom usable after kitchen items")
	act.broom.use(act.player)
	await _settle()
	_check(act.beats.is_done("broom"), "broom beat")
	# 7-8 TV twice
	act.hit_tv()
	_check(act.beats.is_done("tv_hit_1"), "first TV hit")
	_check(not act.beats.is_done("tv_hit_2"), "TV still standing after one hit")
	act.hit_tv()
	_check(act.beats.is_done("tv_hit_2"), "second TV hit")
	# 9 quit call
	_carry().call("drop_item")
	await _settle(4)
	_check(act.phone.can_use(), "phone usable after the TV")
	act.phone.use(act.player)
	await _settle()
	_check(act.beats.is_done("quit_call"), "quit_call beat")
	# 10 phone throw (aim at the tank)
	act.player.global_position = Vector3(1.0, 5.1, 3.0)
	act.player.rotation.y = 0.0
	act.player.get_node("Head").rotation.x = -0.3
	await _settle()
	act.throw_held()
	_check(await _wait_for(func() -> bool: return act.beats.is_done("phone_throw"), 2.0), "phone thrown into the tank")
	# 11 tank throw
	await _settle(4)
	_check(act.tank.can_use(), "tank usable after the phone")
	act.tank.use(act.player)
	await _settle()
	act.throw_held()
	_check(await _wait_for(func() -> bool: return act.beats.is_done("tank_throw"), 2.0), "tank thrown")
	# 12 family loaded
	await act.board_car()
	_check(act.beats.is_done("family_loaded"), "family_loaded beat")
	_check(act.beats.all_done(), "all 12 beats done")
	_check(Acts.is_unlocked(2), "Act 2 unlocked")
	print("---- act01 playthrough: %d failure(s)" % _fails)
	get_tree().quit(1 if _fails > 0 else 0)
