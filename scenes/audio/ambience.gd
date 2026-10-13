extends Node
## Data-driven, procedural ambience beds for the current room.
##
## Attach one instance to a room controller and call enter_space(space_id) when the player
## enters a space. Beds are generated from data/sensory/spaces.json and use the existing
## Synth and Audio bus/reverb APIs; no external samples or extra autoloads are required.

const SynthScript = preload("res://scenes/audio/synth.gd")
const SPACE_DATA_PATH := "res://data/sensory/spaces.json"
const LOOP_SECONDS := 3.0
const MAX_LAYERS := 3
const FADE_DB := -60.0

var _spaces: Dictionary = {}
var _active_space := ""
var _players: Array[AudioStreamPlayer] = []
var _fade_tweens: Array[Tween] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_spaces()


func _exit_tree() -> void:
	for tween in _fade_tweens:
		if tween != null and tween.is_valid():
			tween.kill()
	for player in _players:
		if is_instance_valid(player):
			player.stop()


## Begin the ambience and reverb for a known space. Returns false for unknown IDs without
## disturbing the currently playing room. Re-entering the same space is a no-op.
func enter_space(space_id: String, fade_seconds: float = 1.2) -> bool:
	if _spaces.is_empty():
		_load_spaces()
	if not _spaces.has(space_id):
		return false
	if _active_space == space_id:
		return true

	var space: Dictionary = _spaces[space_id]
	_active_space = space_id
	Audio.set_reverb(String(space.get("reverb", "none")))
	_retire_current(maxf(fade_seconds, 0.0))

	var description := String(space.get("tone", ""))
	for source in space.get("sources", []):
		description += " " + String(source)
	var kinds := classify_tone(description)
	if kinds.is_empty():
		kinds.append("quiet")

	for i in mini(kinds.size(), MAX_LAYERS):
		var kind: String = kinds[i]
		var player := AudioStreamPlayer.new()
		player.name = "Ambience_" + kind
		player.bus = "Amb"
		player.stream = _make_loop(kind, i + 1)
		player.volume_db = FADE_DB
		add_child(player)
		player.play()
		_players.append(player)
		var target_db := _target_volume_db(kind)
		if fade_seconds <= 0.0:
			player.volume_db = target_db
		else:
			var tween := create_tween()
			tween.tween_property(player, "volume_db", target_db, fade_seconds)
			_fade_tweens.append(tween)
	return true


## Stable, deterministic mapping from the sensory sheet's prose to reusable sound layers.
static func classify_tone(description: String) -> Array[String]:
	var source := description.to_lower()
	var result: Array[String] = []
	if _contains_any(source, ["wind", "draught", "draft", "branches", "breeze"]):
		result.append("wind")
	if _contains_any(source, ["cicada", "insect", "moth", "cricket"]):
		result.append("insects")
	if _contains_any(source, ["bird", "grackle", "racoon", "raccoon", "chitter"]):
		result.append("birds")
	if _contains_any(source, ["water", "lake", "reeds", "drip", "bubbl", "rain"]):
		result.append("water")
	if _contains_any(source, ["hum", "whine", "heater", "furnace", "compressor", "engine", "tyre", "tire", "radio", "pump", "motor", "tv", "crt", "highway", "road"]):
		result.append("mechanical")
	if _contains_any(source, ["tick", "creak", "rustle", "crunch", "rattle", "knock", "footstep", "squeak"]):
		result.append("house")
	return result


func active_space() -> String:
	return _active_space


func active_layer_count() -> int:
	return _players.size()


func _load_spaces() -> void:
	var file := FileAccess.open(SPACE_DATA_PATH, FileAccess.READ)
	if file == null:
		push_warning("Ambience could not open " + SPACE_DATA_PATH)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_warning("Ambience sensory sheet is not a JSON object")
		return
	var raw_spaces: Variant = parsed.get("spaces", {})
	if raw_spaces is Dictionary:
		_spaces = raw_spaces


func _retire_current(fade_seconds: float) -> void:
	for player in _players:
		if not is_instance_valid(player):
			continue
		if fade_seconds <= 0.0:
			player.stop()
			player.queue_free()
		else:
			var tween := create_tween()
			tween.tween_property(player, "volume_db", FADE_DB, fade_seconds)
			tween.tween_callback(player.queue_free)
			_fade_tweens.append(tween)
	_players.clear()


func _make_loop(kind: String, seed_value: int) -> AudioStreamWAV:
	var buffer := PackedFloat32Array()
	match kind:
		"wind":
			buffer = SynthScript.noise(LOOP_SECONDS, 0.11, 0.0, 0.0, 0.94, seed_value)
			buffer = SynthScript.mix(buffer, SynthScript.noise(LOOP_SECONDS, 0.025, 0.0, 0.0, 0.72, seed_value + 31))
		"insects":
			buffer = SynthScript.noise(LOOP_SECONDS, 0.045, 0.0, 0.0, 0.22, seed_value + 101)
			buffer = SynthScript.mix(buffer, SynthScript.tone(2800.0, LOOP_SECONDS, "sine", 0.018, 0.0, 0.0))
		"birds":
			buffer = SynthScript.tone(1150.0, LOOP_SECONDS, "triangle", 0.035, 0.0, 0.0)
			buffer = SynthScript.mix(buffer, SynthScript.tone(1730.0, LOOP_SECONDS, "sine", 0.016, 0.0, 0.0))
			buffer = SynthScript.pulsed(buffer, 2.2, 0.94)
		"water":
			buffer = SynthScript.noise(LOOP_SECONDS, 0.055, 0.0, 0.0, 0.55, seed_value + 211)
		"mechanical":
			buffer = SynthScript.tone(58.0, LOOP_SECONDS, "sine", 0.045, 0.0, 0.0)
			buffer = SynthScript.mix(buffer, SynthScript.tone(117.0, LOOP_SECONDS, "triangle", 0.018, 0.0, 0.0))
		"house":
			buffer = SynthScript.noise(LOOP_SECONDS, 0.018, 0.0, 0.0, 0.82, seed_value + 307)
		_:
			buffer = SynthScript.noise(LOOP_SECONDS, 0.022, 0.0, 0.0, 0.96, seed_value + 401)
	return SynthScript.to_stream(buffer, true)


func _target_volume_db(kind: String) -> float:
	match kind:
		"wind":
			return -17.0
		"insects":
			return -24.0
		"birds":
			return -27.0
		"water":
			return -22.0
		"mechanical":
			return -20.0
		"house":
			return -26.0
		_:
			return -28.0


static func _contains_any(source: String, words: Array[String]) -> bool:
	for word in words:
		if source.contains(word):
			return true
	return false
