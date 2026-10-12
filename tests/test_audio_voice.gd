extends Node

const VoiceProfilesScript = preload("res://scenes/audio/voice_profiles.gd")
## Headless test for voice blips and dialogue sfx cues. Run: godot --headless --path . res://tests/test_audio_voice.tscn
var _fails := 0

func _check(cond: bool, what: String) -> void:
	print(("PASS " if cond else "FAIL ") + what)
	if not cond:
		_fails += 1

func _ready() -> void:
	var e := VoiceProfilesScript.for_speaker("elsa_ray")
	_check(e == VoiceProfilesScript.for_speaker("Elsa Ray") and e == VoiceProfilesScript.for_speaker("ELSA"), "elsa matches by keyword in any spelling")
	_check(VoiceProfilesScript.for_speaker("self") == VoiceProfilesScript.for_speaker("christopher"), "'self' is the player voice")
	_check(VoiceProfilesScript.for_speaker("joshua_primo")["wave"] == "saw" and VoiceProfilesScript.for_speaker("the_moon")["base"] < 120.0, "gronfiser/moon profiles found")
	var u1 := VoiceProfilesScript.for_speaker("demo_speaker")
	_check(u1 == VoiceProfilesScript.for_speaker("demo_speaker") and u1["base"] >= 150.0 and u1["base"] < 430.0, "unknown speakers get a stable derived profile")
	_check(VoiceProfilesScript.for_speaker("zzz_a")["base"] != VoiceProfilesScript.for_speaker("zzz_bbb")["base"] or VoiceProfilesScript.for_speaker("zzz_a")["wave"] != VoiceProfilesScript.for_speaker("zzz_bbb")["wave"], "different unknown speakers sound different")
	var all_ok := true
	for k in VoiceProfilesScript.PROFILES:
		var p: Dictionary = VoiceProfilesScript.PROFILES[k]
		for key in ["base", "wave", "vary", "every", "vol", "len"]:
			all_ok = all_ok and p.has(key)
		all_ok = all_ok and int(p["every"]) >= 1 and float(p["vol"]) <= 0.5 and float(p["len"]) <= 0.15
	_check(all_ok, "every profile is complete, quiet and short")
	var pit := VoiceProfilesScript.pitch_for(e, "a")
	_check(pit == VoiceProfilesScript.pitch_for(e, "a") and pit > 0.77 and pit < 1.3, "pitch_for is stable and within a few semitones")
	_check(VoiceProfilesScript.is_voiced("a") and VoiceProfilesScript.is_voiced("7") and VoiceProfilesScript.is_voiced("é") and not VoiceProfilesScript.is_voiced(".") and not VoiceProfilesScript.is_voiced(",") and not VoiceProfilesScript.is_voiced("") and not VoiceProfilesScript.is_voiced("'"), "letters/digits voiced, punctuation silent")

	# live blips via the event bus (elsa: every 2nd letter)
	Audio._blip_player.stop()
	Events.speaker_blip.emit("elsa_ray", "H")
	_check(not Audio._blip_player.playing, "1st letter of a line is skipped (every 2)")
	Events.speaker_blip.emit("elsa_ray", "e")
	_check(Audio._blip_player.playing and Audio._blip_player.bus == &"Voice", "2nd letter plays a blip on the Voice bus")
	_check(Audio._blip_player.stream is AudioStreamWAV and is_equal_approx(Audio._blip_player.volume_db, linear_to_db(0.32)), "blip stream and volume come from the profile")
	Audio._blip_player.stop()
	Events.speaker_blip.emit("elsa_ray", ".")
	Events.speaker_blip.emit("elsa_ray", ",")
	_check(not Audio._blip_player.playing, "punctuation never blips")
	Events.speaker_blip.emit("frank", "F")
	Events.speaker_blip.emit("frank", "r")
	_check(not Audio._blip_player.playing, "switching speaker resets the counter (frank: every 3)")
	Events.speaker_blip.emit("frank", "a")
	_check(Audio._blip_player.playing, "frank blips on his 3rd letter")
	var n := Audio._blip_streams.size()
	for i in 12:
		Events.speaker_blip.emit("frank", "x")
	_check(Audio._blip_streams.size() == n, "blip streams are cached, not rebuilt")

	# dialogue sfx cues
	var before := _busy()
	Events.dialogue_cue.emit("sfx", "door_creak")
	_check(_busy() == before + 1, "sfx cue plays the named recipe")
	Events.dialogue_cue.emit("sfx", ["click", "thud"])
	_check(_busy() == before + 3, "sfx cue accepts a list of names")
	# Stop prior short sounds so this assertion cannot pass/fail due to playback timing.
	for p in Audio._pool:
		p.stop()
	# Use valid SFX names: if Audio accidentally handles non-SFX cue types, these would start playback.
	Events.dialogue_cue.emit("cam", "click")
	Events.dialogue_cue.emit("emote", "thud")
	_check(_busy() == 0, "cam/emote cues are ignored by Audio")

	print("RESULT: ALL PASS" if _fails == 0 else "RESULT: %d FAILED" % _fails)
	get_tree().quit(_fails)

func _busy() -> int:
	var n := 0
	for p in Audio._pool:
		if p.playing:
			n += 1
	return n
