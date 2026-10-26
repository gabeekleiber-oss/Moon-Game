extends Node
## S-11 title screen: Continue state follows the save, Begin asks before replacing a save, both enter Act 1.
const TEST_PATH := "user://test_title_save.json"
const TitleScene := preload("res://scenes/title/title_screen.tscn")
var _fails := 0


func _check(condition: bool, message: String) -> void:
	print(("PASS " if condition else "FAIL ") + message)
	if not condition:
		_fails += 1


func _clean() -> void:
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(TEST_PATH + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH + suffix))


func _ready() -> void:
	var real_path: String = SaveGame.path
	SaveGame.path = TEST_PATH
	_clean()
	SaveGame.session_active = false

	# 1. No save: Continue disabled, Begin goes straight into Act 1 with no confirmation.
	var title: TitleScreen = TitleScene.instantiate()
	add_child(title)
	await get_tree().process_frame
	_check(title.panel() == "menu", "title opens on the main menu")
	_check(title._continue_button.disabled, "Continue is disabled with no save")
	_check(not await title.continue_pressed(), "continue_pressed with no save returns false and stays on the title")
	_check(is_instance_valid(title) and not title.is_queued_for_deletion(), "title is still there after a failed Continue")
	title.begin_pressed()
	for i in 20:
		await get_tree().process_frame
	_check(Acts.current_id == 1 and Acts._current != null, "Begin with no save enters Act 1")
	_check(not is_instance_valid(title) or title.is_queued_for_deletion(), "title frees itself after Begin")
	_check(SaveGame.has_save(), "Begin writes the first save")

	# 2. With a save: Continue enabled, Begin asks first and 'Keep my save' returns to the menu.
	Events.beat_completed.emit(1, "intruder")
	await get_tree().process_frame
	await get_tree().process_frame
	SaveGame.save_now("test")
	var again: TitleScreen = TitleScene.instantiate()
	add_child(again)
	await get_tree().process_frame
	_check(not again._continue_button.disabled, "Continue is enabled when a save exists")
	again.begin_pressed()
	_check(again.panel() == "confirm", "Begin asks for confirmation when a save exists")
	again._show_panel("menu")
	_check(again.panel() == "menu" and SaveGame.has_save(), "backing out of the confirmation keeps the save")
	again._show_panel("settings")
	_check(again.panel() == "settings", "Settings panel opens")
	again._show_panel("credits")
	_check(again.panel() == "credits", "Credits panel opens")
	again._show_panel("menu")

	# 3. Continue restores the saved beats in Act 1.
	Acts.current_id = 0
	if Acts._current != null:
		Acts._current.queue_free()
		Acts._current = null
	await get_tree().process_frame
	SaveGame.reset_state()
	var ok: bool = await again.continue_pressed()
	for i in 10:
		await get_tree().process_frame
	_check(ok and Acts.current_id == 1, "Continue re-enters the saved act")
	var tracker: Variant = Acts._current.get("beats") if Acts._current != null else null
	_check(tracker != null and tracker.is_done("intruder"), "Continue restores the completed beat")

	_clean()
	SaveGame.path = real_path
	SaveGame.session_active = false
	print("RESULT: %s" % ("PASS" if _fails == 0 else "FAIL (%d)" % _fails))
	get_tree().quit(0 if _fails == 0 else 1)
