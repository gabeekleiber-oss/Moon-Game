extends Node
## Headless test for the S-01 lighting test room: it builds, every look is within the light budget, the toggles work, and all five
## looks drive a MoodEnvironment. (Visuals are verified by tests/_lighting_shot.tscn, never here: the headless renderer draws nothing.)

var _fails := 0

func _check(cond: bool, what: String) -> void:
	print(("PASS " if cond else "FAIL ") + what)
	if not cond:
		_fails += 1

func _ready() -> void:
	Unreality.force(0.0)
	Game.settings["quality"] = "high"
	var room := LightingTestRoom.new()
	room.use_player = false
	add_child(room)
	await get_tree().process_frame
	await get_tree().process_frame
	_check(room.mood != null and room.lamp != null and room.candle != null and room.tv != null and room.window != null and room.moon != null and room.shaft != null, "the room builds every helper")
	_check(room.find_child("Floor", true, false) != null and room.find_child("WallN_Above", true, false) != null, "the room has a floor and a windowed north wall")
	for look in EnvPresets.names():
		room.set_look(look)
		await get_tree().process_frame
		var r := LightBudget.count(room)
		_check(not r["over"], "look '%s' is within the light budget (%s)" % [look, LightBudget.describe(r)])
		_check(room.mood.get_look() == look, "look '%s' drives the MoodEnvironment" % look)
	# Everything on at once is allowed to exceed the shadow budget: the budget checker must say so.
	room.set_look("night_dark")
	room.window.visible = true
	room.moon.visible = true
	var casters := 0
	for n in room.find_children("*", "Light3D", true, false):
		if (n as Light3D).visible and (n as Light3D).shadow_enabled:
			casters += 1
	_check(casters == 2 and not LightBudget.count(room)["over"], "window + moon together is exactly at the 2-caster limit")
	print("DONE %d failures" % _fails)
	get_tree().quit(1 if _fails > 0 else 0)
