extends Node

const AudioZoneScript = preload("res://scenes/audio/audio_zone.gd")

var _fails := 0


func _check(condition: bool, message: String) -> void:
	print(("PASS " if condition else "FAIL ") + message)
	if not condition:
		_fails += 1


func _ready() -> void:
	Audio.set_reverb("cave")
	var zone: Area3D = AudioZoneScript.new()
	zone.space_id = "wi_living_room"
	add_child(zone)
	var player := Node3D.new()
	player.add_to_group("player")
	add_child(player)
	zone._on_body_entered(player)
	_check(zone.active_player_count() == 1, "player entering zone is tracked")
	_check(Audio.reverb_preset() == "room", "zone applies reverb from sensory sheet")
	zone._on_body_entered(player)
	_check(zone.active_player_count() == 1, "duplicate enter does not stack")
	var other := Node3D.new()
	add_child(other)
	zone._on_body_entered(other)
	_check(zone.active_player_count() == 1, "non-player bodies do not affect room reverb")
	zone._on_body_exited(player)
	_check(zone.active_player_count() == 0 and Audio.reverb_preset() == "cave", "leaving zone restores the prior reverb")
	_check(AudioZoneScript._reverb_for_space("wi_yard") == "none", "outdoor space resolves to dry reverb")
	_check(AudioZoneScript._reverb_for_space("not_a_real_space") == "", "unknown spaces have no reverb mapping")
	zone.queue_free()
	player.queue_free()
	other.queue_free()
	print("RESULT: ALL PASS" if _fails == 0 else "RESULT: %d FAILED" % _fails)
	get_tree().quit(_fails)
