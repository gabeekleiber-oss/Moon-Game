extends Node

const SfxRecipesScript = preload("res://scenes/audio/sfx_recipes.gd")
## Headless test for the Audio autoload. Run: godot --headless --path . res://tests/test_audio.tscn
var _fails := 0

func _check(cond: bool, what: String) -> void:
	print(("PASS " if cond else "FAIL ") + what)
	if not cond:
		_fails += 1

func _ready() -> void:
	for b in ["Music", "SFX", "Amb", "Voice"]:
		var i := AudioServer.get_bus_index(b)
		_check(i != -1 and AudioServer.get_bus_send(i) == &"Master", "bus %s exists and sends to Master" % b)
	_check(Audio._reverbs.size() == 3 and AudioServer.get_bus_effect_count(AudioServer.get_bus_index("SFX")) >= 1, "SFX/Amb/Voice carry a reverb effect")
	_check(Audio.reverb_preset() == "none" and is_zero_approx(Audio._reverbs[0].wet), "reverb starts dry")
	Audio.set_reverb("dome")
	_check(Audio.reverb_preset() == "dome" and Audio._reverbs[0].wet > 0.3 and Audio._reverbs[2].room_size > 0.8, "dome preset applied to every reverb")
	Audio.set_reverb("bogus")
	_check(Audio.reverb_preset() == "none" and is_zero_approx(Audio._reverbs[1].wet), "unknown preset falls back to none")

	var p := Audio.play_sfx("pickup", -3.0, 1.2)
	_check(p != null and p.playing and p.bus == &"SFX" and is_equal_approx(p.pitch_scale, 1.2) and is_equal_approx(p.volume_db, -3.0), "play_sfx plays on the SFX bus with pitch and volume")
	_check(Audio.play_sfx("no_such_sound") == null, "unknown sfx returns null")
	var q := Audio.play_stream(SfxRecipesScript.get_stream("chime"), "Nope")
	_check(q.bus == &"SFX", "unknown bus falls back to SFX")
	var m := Audio.play_stream(SfxRecipesScript.get_stream("chime"), "Music")
	_check(m.bus == &"Music", "play_stream honours the Music bus")
	for i in 20:
		Audio.play_sfx("thud")
	_check(Audio._pool.size() == Audio.POOL_SIZE, "pool never grows past its size when flooded")

	Audio.set_bus_volume("Music", 0.5)
	_check(absf(Audio.get_bus_volume("Music") - 0.5) < 0.01, "set/get bus volume round-trips")
	Audio.set_bus_volume("Music", 0.0)
	_check(AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")), "volume 0 mutes the bus")
	Audio.set_bus_volume("Music", 1.0)
	_check(not AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")), "volume 1 unmutes")

	var n3 := Audio.play_sfx_at("thud", Vector3(2, 0, 4))
	_check(n3 != null and n3.is_inside_tree() and n3.global_position.is_equal_approx(Vector3(2, 0, 4)) and n3.bus == &"SFX", "play_sfx_at places a 3D player")
	_check(Audio.play_sfx_at("no_such_sound", Vector3.ZERO) == null, "play_sfx_at unknown returns null")

	get_tree().paused = true
	var pp := Audio.play_sfx("click")
	await get_tree().process_frame
	_check(pp.can_process(), "audio keeps working while the tree is paused")
	get_tree().paused = false

	print("RESULT: ALL PASS" if _fails == 0 else "RESULT: %d FAILED" % _fails)
	get_tree().quit(_fails)
