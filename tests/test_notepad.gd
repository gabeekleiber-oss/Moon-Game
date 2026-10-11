extends Node
## Headless test for NotepadView + PauseMenu notepad mode. Run: godot --headless --path . res://tests/test_notepad.tscn
var _fails := 0

func _check(cond: bool, what: String) -> void:
	print(("PASS " if cond else "FAIL ") + what)
	if not cond:
		_fails += 1

func _press(action: String) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	Input.parse_input_event(ev)
	await get_tree().process_frame
	await get_tree().process_frame

func _rows(v: NotepadView) -> int:
	var n := 0
	for c in v._list.get_children():
		if not c.is_queued_for_deletion():
			n += 1
	return n

func _ready() -> void:
	GameSettings.path = "user://_test_notepad.json"
	Game.notepad.clear()
	_check(NotepadView.format_value(0) == "0" and NotepadView.format_value(999) == "999" and NotepadView.format_value(12500) == "12,500" and NotepadView.format_value(1234567) == "1,234,567" and NotepadView.format_value(-4200) == "-4,200", "format_value thousands separators")

	var v := NotepadView.new()
	add_child(v)
	await get_tree().process_frame
	_check(_rows(v) == 1 and v._total.text == "0" and v._count.text == "0 items", "empty notepad shows placeholder, total 0")

	Game.add_notepad_item("vase", "Ming Vase", 12000, "Hall")
	Game.add_notepad_item("lamp", "Brass Lamp", 500, "Hall")
	Game.add_notepad_item("armor1", "Gilded Helm", 3000, "Gallery")
	await get_tree().process_frame
	_check(_rows(v) == 5, "2 room headers + 3 item rows after adding items (auto-refresh)")
	_check(v._total.text == "15,500" and v._count.text == "3 items", "total 15,500 and count 3 items")
	Game.add_notepad_item("vase", "Ming Vase", 12000, "Hall")
	await get_tree().process_frame
	_check(_rows(v) == 5 and v._total.text == "15,500", "duplicate id ignored")
	Game.add_notepad_item("brooch", "Brooch", 1, "Hall")
	await get_tree().process_frame
	_check(_rows(v) == 6, "new item in an existing room goes under that room's header")

	# PauseMenu integration
	_check(not PauseMenu.is_open(), "closed at start")
	await _press("notepad")
	_check(PauseMenu.is_open() and get_tree().paused and PauseMenu._notepad.visible and not PauseMenu._pause_box.visible, "Q opens the notepad and pauses")
	await _press("notepad")
	_check(not PauseMenu.is_open() and not get_tree().paused, "Q again closes it")
	await _press("notepad")
	await _press("pause")
	_check(not PauseMenu.is_open() and not get_tree().paused, "Esc closes the notepad")
	PauseMenu.open_pause()
	await _press("notepad")
	_check(PauseMenu._mode == "pause", "Q does nothing inside the pause menu")
	PauseMenu.close()

	# toast
	Game.add_notepad_item("toast", "Toast Item", 7, "Hall")
	await get_tree().process_frame
	_check(PauseMenu._toast.visible and "Toast Item" in PauseMenu._toast_label.text, "toast shows when an item is added")

	# cutscene guard
	var done := [false]
	_cut(done)
	await get_tree().process_frame
	await _press("notepad")
	_check(Cutscene.is_active() and not PauseMenu.is_open(), "Q ignored during a cutscene")
	PauseMenu.open_notepad()
	_check(not PauseMenu.is_open(), "open_notepad() refuses during a cutscene")
	Cutscene.request_skip()
	await get_tree().create_timer(0.2).timeout
	PauseMenu.open_notepad()
	_check(PauseMenu.is_open() and PauseMenu._notepad.visible, "open_notepad() works after the cutscene")
	PauseMenu.close()

	print("RESULT: ALL PASS" if _fails == 0 else "RESULT: %d FAILED" % _fails)
	get_tree().quit(_fails)

func _cut(done: Array) -> void:
	await Cutscene.play(func() -> void: await Cutscene.wait(30.0))
	done[0] = true
