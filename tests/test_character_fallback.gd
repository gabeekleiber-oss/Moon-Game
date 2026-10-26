extends Node
const CharacterFallbackScript = preload("res://scenes/characters/character_fallback.gd")
var _fails := 0

func _check(condition: bool, message: String) -> void:
	print(("PASS " if condition else "FAIL ") + message)
	if not condition:
		_fails += 1

func _ready() -> void:
	for id in CharacterFallbackScript.IDS:
		var c: CharacterFallback = CharacterFallbackScript.make(id)
		add_child(c)
		_check(c.get_meta("placeholder") == true and c.character_id == id, "%s builds and is marked placeholder" % id)
		if id == "primo_statue":
			_check(c.find_child("Plinth", true, false) != null and c.find_child("Collision", true, false) != null, "statue base has plinth and collision")
			continue
		_check(c.find_child("Head", true, false) != null and c.find_child("Torso", true, false) != null, "%s has head and torso" % id)
		_check(c.find_child("Nose", true, false) == null and c.find_child("Lips", true, false) == null, "%s face is unfinished (no nose or lips)" % id)
	var sweaty: CharacterFallback = CharacterFallbackScript.make("sweaty_man")
	add_child(sweaty)
	_check(sweaty.find_child("LongFinger", true, false) != null and sweaty.find_child("Beard", true, false) != null, "Sweaty Man has the long finger and beard")
	_check(sweaty.find_child("Foot_L", true, false) != null, "Sweaty Man is barefoot")
	var elsa: CharacterFallback = CharacterFallbackScript.make("elsa_ray")
	add_child(elsa)
	elsa.hold_expression("glare", 0.2)
	_check(elsa.expression == "glare", "Elsa holds the glare expression")
	await get_tree().create_timer(0.5).timeout
	_check(elsa.expression == "neutral", "a held expression returns to neutral")
	elsa.set_expression("nonsense")
	_check(elsa.expression == "neutral", "unknown expression falls back to neutral")
	elsa.set_pose("sit")
	var sit_y := (elsa.find_child("Body", true, false) as Node3D).position.y
	elsa.set_pose("stand")
	_check(sit_y < 0.0 and (elsa.find_child("Body", true, false) as Node3D).position.y == 0.0, "sit lowers the body and stand restores it")
	elsa.set_silhouette(true)
	var torso := elsa.find_child("Torso", true, false) as MeshInstance3D
	_check((torso.material_override as StandardMaterial3D).shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED, "silhouette mode flattens materials")
	elsa.set_silhouette(false)
	_check((torso.material_override as StandardMaterial3D).shading_mode != BaseMaterial3D.SHADING_MODE_UNSHADED, "silhouette mode reverts")
	var mouth := elsa.find_child("MouthMark", true, false) as MeshInstance3D
	Events.speaker_blip.emit("Elsa Ray", "a")
	elsa._process(0.001)
	sweaty._process(0.001)
	_check(mouth.scale.y > 1.0, "voice blip pulses the mouth mark")
	var other_mouth := (sweaty.find_child("MouthMark", true, false) as MeshInstance3D)
	_check(is_equal_approx(other_mouth.scale.y, 1.0), "another character's blip does not move this mouth")
	var unknown: CharacterFallback = CharacterFallbackScript.make("not_a_person")
	_check(unknown.character_id == "elsa_ray", "unknown id falls back without crashing")
	unknown.free()
	print("RESULT: %s" % ("ALL PASS" if _fails == 0 else "%d FAILED" % _fails))
	get_tree().quit(0 if _fails == 0 else 1)
