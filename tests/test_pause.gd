extends Node
## Headless test for PauseMenu. Run: godot --headless --path . res://tests/test_pause.tscn
var _fails := 0
var _events: Array = []

func _check(cond: bool, what: String) -> void:
	print(("PASS " if cond else "FAIL ") + what)
	if not cond:
		_fails += 1

func _esc() -> void:
	var ev := InputEventAction.new()
	ev.action = "pause"
	ev.pressed = true
	Input.parse_input_event(ev)
	await get_tree().process_frame
	await get_tree().process_frame

func _ready() -> void:
	GameSettings.path = "user://_test_pause.json"
	Events.game_paused.connect(func(p: bool) -> void: _events.append(p))
	_check(not PauseMenu.is_open() and not get_tree().paused, "closed and running at start")
	await _esc()
	_check(PauseMenu.is_open() and get_tree().paused, "Esc opens the menu and pauses the tree")
	_check(PauseMenu._pause_box.visible and not PauseMenu._settings.visible, "pause buttons visible, settings hidden")
	await _esc()
	_check(not PauseMenu.is_open() and not get_tree().paused, "Esc again resumes")
	_check(_events == [true, false], "Events.game_paused fired true then false")

	# settings flow: Esc from settings goes back to the menu, not out of it
	PauseMenu.open_pause()
	(PauseMenu._pause_box.get_child(2) as Button).pressed.emit()   # Settings
	_check(PauseMenu._settings.visible and not PauseMenu._pause_box.visible, "Settings button shows the settings panel")
	await _esc()
	_check(PauseMenu.is_open() and PauseMenu._pause_box.visible and get_tree().paused, "Esc inside Settings steps back to the pause menu")
	(PauseMenu._pause_box.get_child(1) as Button).pressed.emit()   # Resume
	_check(not PauseMenu.is_open() and not get_tree().paused, "Resume button closes")

	# Esc ignored during a cutscene (P-F-05-1)
	var done := [false]
	_cut(done)
	await get_tree().process_frame
	await _esc()
	_check(Cutscene.is_active() and not PauseMenu.is_open() and not get_tree().paused, "Esc is ignored while a cutscene runs")
	PauseMenu.open_pause()
	_check(not PauseMenu.is_open(), "open_pause() refuses during a cutscene")
	Cutscene.request_skip()
	await get_tree().create_timer(0.2).timeout
	await _esc()
	_check(PauseMenu.is_open(), "Esc works again after the cutscene")
	PauseMenu.close()

	# the menu itself works while paused (process_mode ALWAYS)
	_check(PauseMenu.process_mode == Node.PROCESS_MODE_ALWAYS, "menu keeps processing while paused")
	DirAccess.remove_absolute("user://_test_pause.json")
	GameSettings.path = "user://settings.json"
	print("RESULT: %s" % ("ALL PASS" if _fails == 0 else "%d FAILED" % _fails))
	get_tree().quit(0 if _fails == 0 else 1)

func _cut(done: Array) -> void:
	await Cutscene.play(func() -> void: await Cutscene.wait(30.0))
	done[0] = true
