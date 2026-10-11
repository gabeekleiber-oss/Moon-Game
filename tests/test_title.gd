extends Node
## Headless test for F-13 (title screen). Run: godot --headless --path . res://tests/test_title.tscn
var _fails := 0
var _chosen := -1
func _check(cond: bool, what: String) -> void:
	print(("PASS " if cond else "FAIL ") + what)
	if not cond:
		_fails += 1

func _on_chosen(id: int) -> void:
	_chosen = id

func _ready() -> void:
	var t := TitleScreen.new()
	t.fade_seconds = 0.0
	add_child(t)
	await get_tree().process_frame
	_check(t.current_panel() == "menu", "starts on the menu")
	_check(t.menu_labels() == PackedStringArray(["Begin", "Chapters", "Settings", "Quit"]), "menu has Begin/Chapters/Settings/Quit")
	_check(not Hud.is_hud_visible(), "HUD is hidden while the title is up")
	var labels := t.chapter_labels()
	_check(labels.size() == 12 and labels[0].begins_with("1  ") and labels[10].begins_with("11  ") and labels[11] == "Back", "chapter list: 11 chapters + Back")
	t.show_panel("chapters")
	_check(t.current_panel() == "chapters", "show_panel(chapters)")
	t.show_panel("settings")
	_check(t.current_panel() == "settings", "show_panel(settings)")
	t.show_panel("nope")
	_check(t.current_panel() == "settings", "unknown panel ignored")
	var ev := InputEventAction.new()
	ev.action = "ui_cancel"
	ev.pressed = true
	Input.parse_input_event(ev)
	await get_tree().process_frame
	await get_tree().process_frame
	_check(t.current_panel() == "menu", "ui_cancel returns to the menu")
	t.chapter_chosen.connect(_on_chosen)
	t.choose_chapter(5)
	t.choose_chapter(7)   # ignored: already leaving
	for i in 6:
		await get_tree().process_frame
	_check(_chosen == 5, "choose_chapter(5) emits chapter_chosen(5) once (got %d)" % _chosen)
	t.free()
	await get_tree().process_frame
	_check(Hud.is_hud_visible(), "HUD restored when the title leaves")
	# standalone (no listener): fades back in and stays usable
	var s := TitleScreen.new()
	s.fade_seconds = 0.0
	add_child(s)
	await get_tree().process_frame
	s.choose_chapter(2)
	for i in 6:
		await get_tree().process_frame
	_check(Cutscene.fade_alpha() < 0.01, "standalone choice fades back in")
	s.queue_free()
	print("FAILED: %d" % _fails if _fails else "ALL PASSED")
	get_tree().quit(1 if _fails else 0)
