extends Node
## Headless test for SettingsPanel + the places that read settings. Run: godot --headless --path . res://tests/test_settings_panel.tscn
var _fails := 0
const TMP := "user://_test_settings_panel.json"

func _check(cond: bool, what: String) -> void:
	print(("PASS " if cond else "FAIL ") + what)
	if not cond:
		_fails += 1

func _ready() -> void:
	GameSettings.path = TMP
	GameSettings.reset_to_defaults()
	var panel := SettingsPanel.new()
	add_child(panel)
	await get_tree().process_frame
	_check(is_equal_approx(panel._volume.value, 0.8) and panel._volume_val.text == "80%", "panel shows the current volume")
	panel._volume.value = 0.3
	_check(is_equal_approx(float(Game.settings["volume"]), 0.3), "moving the volume slider changes Game.settings")
	panel._quality.select(2)
	panel._quality.item_selected.emit(2)
	_check(Game.settings["quality"] == "low", "quality dropdown -> low")
	panel._reduced.button_pressed = true
	_check(Game.settings["reduced_motion"] == true, "Reduced Motion checkbox")
	panel._assist.button_pressed = true
	_check(Game.settings["assist"] == true, "Assist checkbox")
	panel._sens.value = 0.0044
	_check(panel._sens_val.text == "2.0×", "sensitivity label shows 2.0x (%s)" % panel._sens_val.text)
	# external change refreshes the UI
	GameSettings.set_value("volume", 1.0)
	_check(is_equal_approx(panel._volume.value, 1.0) and panel._volume_val.text == "100%", "external set_value refreshes the panel")
	var got := [false]
	panel.back_requested.connect(func() -> void: got[0] = true)
	(panel.get_child(panel.get_child_count() - 1).get_child(1) as Button).pressed.emit()
	_check(got[0], "Back button emits back_requested")
	(panel.get_child(panel.get_child_count() - 1).get_child(0) as Button).pressed.emit()
	_check(Game.settings["volume"] == 0.8 and Game.settings["quality"] == "auto" and not Game.settings["assist"], "Reset to defaults button")

	# consumers: player sensitivity + assist reach
	GameSettings.set_value("sensitivity", 0.005)
	var player := (load("res://scenes/player/player.tscn") as PackedScene).instantiate()
	add_child(player)
	_check(is_equal_approx(player._sensitivity(), 0.005), "player.gd uses the settings sensitivity")
	var ray: InteractionRay = player.get_node("Head/Camera3D").get_child(0)
	ray.require_captured_mouse = false
	var floor_body := StaticBody3D.new()
	var fs := CollisionShape3D.new()
	var fb := BoxShape3D.new()
	fb.size = Vector3(40, 1, 40)
	fs.shape = fb
	floor_body.add_child(fs)
	floor_body.position = Vector3(0, -0.5, 0)
	add_child(floor_body)
	var it := Interactable.new()
	var cs := CollisionShape3D.new()
	var bx := BoxShape3D.new()
	bx.size = Vector3(0.6, 0.6, 0.6)
	cs.shape = bx
	it.add_child(cs)
	it.position = Vector3(0, 1.6, -3.3)    # camera at y=1.6; face of the box is ~3.0 m away (> range 2.4, < 2.4*1.5)
	add_child(it)
	await get_tree().create_timer(0.2).timeout
	_check(ray.focus == null, "out of reach without Assist (3.0 m > 2.4 m)")
	GameSettings.set_value("assist", true)
	await get_tree().create_timer(0.2).timeout
	_check(ray.focus == it, "Assist extends reach x1.5 so the same object is focusable")

	GameSettings.reset_to_defaults()
	DirAccess.remove_absolute(TMP)
	GameSettings.path = "user://settings.json"
	print("RESULT: %s" % ("ALL PASS" if _fails == 0 else "%d FAILED" % _fails))
	get_tree().quit(0 if _fails == 0 else 1)
