extends Node

const OcclusionScript = preload("res://scenes/audio/audio_occlusion.gd")

var _fails := 0


func _check(condition: bool, message: String) -> void:
	print(("PASS " if condition else "FAIL ") + message)
	if not condition:
		_fails += 1


func _ready() -> void:
	var open := OcclusionScript.occlusion_profile(0)
	_check(open.volume_db == 0.0 and open.cutoff_hz == 20500.0, "clear line of sight stays unfiltered")
	var wall := OcclusionScript.occlusion_profile(1)
	_check(wall.volume_db == -5.0 and wall.cutoff_hz == 5200.0, "one wall gently reduces gain and high frequencies")
	var multiple := OcclusionScript.occlusion_profile(3)
	_check(multiple.volume_db < wall.volume_db and multiple.cutoff_hz < wall.cutoff_hz, "additional walls progressively muffle the source")
	var door := OcclusionScript.occlusion_profile(1, 1)
	_check(door.volume_db < wall.volume_db and door.cutoff_hz == 1500.0, "closed door receives stronger low-pass treatment")
	var saturated := OcclusionScript.occlusion_profile(100, 100)
	_check(saturated.volume_db == -20.0 and saturated.cutoff_hz == 1500.0, "attenuation is bounded for many blockers")
	var negative := OcclusionScript.occlusion_profile(-2, -4)
	_check(negative.volume_db == 0.0 and negative.blockers == 0, "negative counts safely clamp to open line of sight")
	var player := AudioStreamPlayer3D.new()
	add_child(player)
	OcclusionScript._apply(player, wall)
	_check(player.volume_db == -5.0 and player.attenuation_filter_cutoff_hz == 5200.0 and player.attenuation_filter_db == -24.0, "profile applies to the individual 3D audio source")
	OcclusionScript._apply(player, open)
	_check(player.volume_db == 0.0 and player.attenuation_filter_db == 0.0, "clear path restores source filter and gain")
	player.queue_free()
	print("RESULT: ALL PASS" if _fails == 0 else "RESULT: %d FAILED" % _fails)
	get_tree().quit(_fails)
