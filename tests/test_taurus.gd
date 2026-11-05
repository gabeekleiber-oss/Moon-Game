extends Node
var _fails := 0


func _check(condition: bool, message: String) -> void:
	print(("PASS " if condition else "FAIL ") + message)
	if not condition:
		_fails += 1


func _ready() -> void:
	var car := Taurus.new()
	add_child(car)
	_check(car.get_meta("placeholder") == true and car.find_child("Shell", true, false) != null, "Taurus builds and is marked placeholder")
	for id in Taurus.DOOR_IDS:
		_check(car.door_interactable(id) != null, "%s has an interactable" % id)
	car.door_interactable("rear_left").use(null)
	_check(car.is_open("rear_left"), "using the rear-left door opens it")
	await get_tree().create_timer(Taurus.OPEN_SECONDS + 0.2).timeout
	var pivot := car.find_child("Door_rear_left", true, false) as Node3D
	_check(pivot.rotation.y < -0.9, "left door swings outward to -X")
	car.set_open("rear_left", false)
	car.set_open("trunk", true)
	_check(car.is_open("trunk") and not car.is_open("rear_left"), "trunk opens and the door closes")
	_check(not car.set_open("nonsense", true), "unknown door id is rejected")
	_check(not car.is_loaded(), "empty car is not loaded")
	car.load_passenger("mary_sue", "rear_left")
	car.load_passenger("frank", "rear_middle")
	var elsa := CharacterFallback.make("elsa_ray")
	add_child(elsa)
	car.seat_passenger(elsa, "rear_right")
	_check(car.passenger_count() == 3 and elsa.get_parent() == car, "three passengers seated (reparented)")
	_check(not car.is_loaded(), "not loaded until the letter is placed")
	var letter := car.place_letter()
	_check(car.place_letter() == letter and letter.position.x > 0.0, "letter sits once on the front passenger seat")
	_check(car.is_loaded(), "car is loaded with the family and the letter")
	_check(not car.find_child("DomeLight", true, false).visible, "dome light starts off")
	Game.settings["reduced_motion"] = true
	car.play_family_loaded_cue()
	var dome := car.find_child("DomeLight", true, false) as OmniLight3D
	_check(car.cue_played and dome.visible and dome.light_energy > 0.0, "cue turns the dome light on steadily under Reduced Motion")
	var lit := 0
	for h in car.find_children("Headlight_*", "SpotLight3D", true, false):
		if (h as SpotLight3D).visible:
			lit += 1
	_check(lit == 2, "both headlights are on after the cue")
	Game.settings["reduced_motion"] = false
	print("RESULT: %s" % ("PASS" if _fails == 0 else "FAIL"))
	get_tree().quit(1 if _fails > 0 else 0)
