extends Node
## Headless test for F-03 (HUD). Run: godot --headless --path . res://tests/test_hud.tscn
## Drives the Events bus / Game meters and checks the Hud autoload reacts.

var _fails := 0


func _check(cond: bool, what: String) -> void:
	print(("PASS " if cond else "FAIL ") + what)
	if not cond:
		_fails += 1


func _ready() -> void:
	await get_tree().process_frame
	_check(Hud != null and Hud.layer == 8, "Hud autoload exists on layer 8")
	var root: Control = Hud.get_node("HudRoot")
	var jar: Control = root.get_node("Meters/FleaJar")
	var hearts: Control = root.get_node("Meters/Hearts")
	_check(jar != null and hearts != null, "flea jar and hearts built")
	_check(hearts.value_of("elsa") == 6 and hearts.value_of("self") == 6, "hearts start at Game's values (6)")

	# objective + toast
	Events.objective_set.emit("Find the broom")
	_check(Hud.objective_text() == "Find the broom" and root.get_node("Objective").visible, "objective line shows text")
	Events.objective_set.emit("")
	_check(not root.get_node("Objective").visible, "empty objective hides the line")
	Events.show_message.emit("It opens. It regrets it.")
	_check(root.get_node("Toast").text == "It opens. It regrets it.", "toast shows the message")

	# flea jar + ticks
	var ticks: Control = root.get_node("Ticks")
	Game.set_flea(0.0, "test reset")
	await get_tree().process_frame
	var before := ticks.get_child_count()
	Game.add_flea(25.0, "test")
	await get_tree().process_frame
	_check(is_equal_approx(jar.target, 25.0), "jar target follows Game.flea (25)")
	_check(ticks.get_child_count() == before + 1, "a floating flea tick spawned")
	_check((ticks.get_child(ticks.get_child_count() - 1) as Label).text == "+25 fleas", "tick text is '+25 fleas'")
	Game.add_flea(0.2, "tiny")
	await get_tree().process_frame
	_check(ticks.get_child_count() == before + 1, "sub-0.5 flea changes spawn no tick")
	for i in 20:
		await get_tree().process_frame
	_check(jar.shown > 0.0, "jar fill animates upward")

	# hearts
	Game.add_heart("frank", -2)
	await get_tree().process_frame
	_check(hearts.value_of("frank") == 4, "frank heart now 4")
	_check((ticks.get_child(ticks.get_child_count() - 1) as Label).text == "-2 Frank", "heart tick text is '-2 Frank'")
	Game.add_heart("mary_sue", 99)
	_check(hearts.value_of("mary_sue") == Game.HEART_MAX, "heart clamps at max")

	# reduced motion: ticks fade without moving
	Game.settings["reduced_motion"] = true
	var count := ticks.get_child_count()
	Game.add_flea(5.0, "rm")
	await get_tree().process_frame
	var tick := ticks.get_child(ticks.get_child_count() - 1) as Label
	var y0 := tick.position.y
	for i in 5:
		await get_tree().process_frame
	_check(ticks.get_child_count() >= count and is_equal_approx(tick.position.y, y0), "reduced motion: tick does not move")
	Game.settings["reduced_motion"] = false

	# tick cap
	for i in 15:
		Game.add_flea(1.0, "spam")
	await get_tree().process_frame
	_check(ticks.get_child_count() <= Hud.MAX_TICKS, "tick count is capped")

	# caption box
	Hud.caption("elsa_ray", "Christopher, I worry about you.", 0.3)
	await get_tree().process_frame
	_check(Hud.is_caption_visible(), "caption visible")
	_check((root.get_node("CaptionBox").find_children("*", "Label", true, false)[0] as Label).text == "Elsa Ray", "speaker tag is 'Elsa Ray'")
	await get_tree().create_timer(0.5).timeout
	_check(not Hud.is_caption_visible(), "caption hides after its time")
	Events.caption.emit("moon", "A narrated caption")
	await get_tree().process_frame
	_check(Hud.is_caption_visible(), "Events.caption shows the box when no dialogue is active")
	Hud.clear_caption()
	_check(not Hud.is_caption_visible(), "clear_caption hides it")

	# caption suppressed while a dialogue box is up, and cleared when one starts
	Events.caption.emit("moon", "again")
	Events.dialogue_started.emit("x")
	_check(not Hud.is_caption_visible(), "dialogue_started clears the caption")

	# visibility toggle
	Hud.set_hud_visible(false)
	_check(not root.visible, "set_hud_visible(false) hides the HUD")
	Hud.set_hud_visible(true)

	print("F-03 HUD test: %s" % ("ALL PASSED" if _fails == 0 else "%d FAILED" % _fails))
	get_tree().quit(1 if _fails > 0 else 0)
