extends Node

const AmbienceScript = preload("res://scenes/audio/ambience.gd")

var _fails := 0


func _check(condition: bool, message: String) -> void:
	print(("PASS " if condition else "FAIL ") + message)
	if not condition:
		_fails += 1


func _ready() -> void:
	var wind_layers := AmbienceScript.classify_tone("wind in bare branches, distant highway")
	_check(wind_layers.has("wind") and wind_layers.has("mechanical"), "tone classification finds wind and distant mechanical hum")
	var nature_layers := AmbienceScript.classify_tone("cicadas already screaming, first birds, water and reeds")
	_check(nature_layers.has("insects") and nature_layers.has("birds") and nature_layers.has("water"), "tone classification finds distinct nature layers")
	_check(AmbienceScript.classify_tone("an unmarked quiet room").is_empty(), "quiet descriptions fall back to a neutral bed")

	var ambience := AmbienceScript.new()
	add_child(ambience)
	_check(ambience.enter_space("wi_living_room", 0.0), "known space enters successfully")
	_check(ambience.active_space() == "wi_living_room", "active space ID is retained")
	_check(ambience.active_layer_count() > 0 and ambience.active_layer_count() <= 3, "space creates a bounded number of ambience layers")
	_check(Audio.reverb_preset() == "room", "space applies its sensory-sheet reverb preset")
	var active_players: Array[AudioStreamPlayer] = []
	for child in ambience.get_children():
		if child is AudioStreamPlayer:
			active_players.append(child)
	_check(not active_players.is_empty() and active_players.all(func(p: AudioStreamPlayer) -> bool: return p.stream is AudioStreamWAV and p.stream.loop_mode == AudioStreamWAV.LOOP_FORWARD), "ambience layers use looping generated WAV streams")
	_check(ambience.enter_space("not_a_real_space", 0.0) == false, "unknown space is rejected")
	_check(ambience.active_space() == "wi_living_room", "unknown space leaves current ambience intact")
	_check(ambience.enter_space("wi_living_room"), "entering the current space is safe")
	ambience.enter_space("wi_yard", 0.0)
	_check(ambience.active_space() == "wi_yard" and Audio.reverb_preset() == "none", "changing spaces updates ambience and reverb")
	ambience.queue_free()

	print("RESULT: ALL PASS" if _fails == 0 else "RESULT: %d FAILED" % _fails)
	get_tree().quit(_fails)
