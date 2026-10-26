extends Node
## Autoload `SaveGame` (S-11a): one save slot holding act progress, story flags/counters, completed beats per act and the hidden
## Unreality value. No UI (S-11 adds Begin/Continue). Player position is NOT saved: Continue re-enters the act at its normal spawn.
##
## API (the title screen and act scripts only need these):
##   SaveGame.has_save() -> bool                    SaveGame.new_game() / SaveGame.continue_game() (await; both start autosave)
##   SaveGame.save_now(reason) -> Error             SaveGame.delete_save()
##   SaveGame.snapshot() / SaveGame.read_save()     (pure data in, pure data out; for tests and tools)
## Autosave happens after every beat, act completion and act unlock, but ONLY once a session began via new_game/continue_game/
## begin_session, so running a scene or test directly never overwrites a player's save.
## Writes are atomic (temp file then rename) and the previous save is kept as `.bak`; a corrupt save falls back to the backup.

signal saved(reason: String)
signal loaded

const SAVE_VERSION := 1
const DEFAULT_PATH := "user://savegame.json"

var path: String = DEFAULT_PATH
## True once a play session began; gates autosave.
var session_active: bool = false
var beats_done: Dictionary = {}              ## act id (int) -> Array[String]
var _pending_beats: Dictionary = {}          ## act id (int) -> Array, applied once by restore_into()
var _dirty: bool = false


func _ready() -> void:
	Events.beat_completed.connect(_on_beat_completed)
	Events.act_completed.connect(func(_id: int) -> void: _queue_autosave("act completed"))
	Events.act_unlocked.connect(func(_id: int) -> void: _queue_autosave("act unlocked"))


# ---- queries ----
func has_save() -> bool:
	return not read_save().is_empty()


## Turns on autosave without loading anything (used when a scene is launched directly by the title/debug flow).
func begin_session() -> void:
	session_active = true


# ---- start / continue ----
## Fresh run: clears flags, counters, Unreality and beat memory, then enters act 1. Does not delete the old save until the first autosave.
func new_game() -> void:
	reset_state()
	session_active = true
	await Acts.go_to(1, true)
	save_now("new game")


## Loads the save and re-enters its act with beats restored. Returns false (and changes nothing) if there is no valid save.
func continue_game() -> bool:
	var data := read_save()
	if data.is_empty():
		return false
	apply_state(data)
	session_active = true
	var act_id := int(data["act"])
	await Acts.go_to(act_id, true)
	# The act's _ready lifted Unreality to its floor; put the saved value back now that it ran.
	_restore_unreality(data)
	loaded.emit()
	return true


func reset_state() -> void:
	Game.flags = {}
	Game.counters = {}
	Game.furthest_act = 1
	beats_done = {}
	_pending_beats = {}
	Unreality.model.floor_ = 0.0
	Unreality.force(0.0, true)


# ---- snapshot / apply ----
func snapshot() -> Dictionary:
	var beats := {}
	for act_id in beats_done:
		beats[str(act_id)] = (beats_done[act_id] as Array).duplicate()
	return {
		"version": SAVE_VERSION,
		"saved_at": Time.get_unix_time_from_system(),
		"act": maxi(Acts.current_id, 1),
		"furthest_act": Game.furthest_act,
		"flags": Game.flags.duplicate(),
		"counters": Game.counters.duplicate(),
		"beats": beats,
		"unreality": {"base": Unreality.model.base, "level": Unreality.model.level},
	}


## Restores Game state and queues the beats for the next act load. Call with data from read_save().
func apply_state(data: Dictionary) -> void:
	Game.flags = (data["flags"] as Dictionary).duplicate()
	Game.counters = (data["counters"] as Dictionary).duplicate()
	Game.furthest_act = clampi(int(data["furthest_act"]), 1, Acts.ACTS.size())
	beats_done = {}
	for key in (data["beats"] as Dictionary):
		beats_done[int(key)] = (data["beats"][key] as Array).duplicate()
	_pending_beats = beats_done.duplicate(true)
	_restore_unreality(data)


## Called by ActBase right after the act defined its beats and before `_act_ready`, so the act builds in its restored state.
func restore_into(act_id: int, tracker: BeatTracker) -> void:
	if _pending_beats.has(act_id):
		tracker.restore(_pending_beats[act_id])
		_pending_beats.erase(act_id)


func _restore_unreality(data: Dictionary) -> void:
	var u: Dictionary = data["unreality"]
	Unreality.model.base = clampf(float(u["base"]), 0.0, 1.0)
	Unreality.force(maxf(float(u["base"]), float(Unreality.model.floor_)), true)


# ---- disk ----
func save_now(reason: String = "") -> Error:
	var json := JSON.stringify(snapshot(), "\t")
	var tmp := path + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		push_warning("SaveGame: cannot write %s (%s)" % [tmp, error_string(FileAccess.get_open_error())])
		return FileAccess.get_open_error()
	f.store_string(json)
	f.close()
	if FileAccess.file_exists(path):
		DirAccess.copy_absolute(ProjectSettings.globalize_path(path), ProjectSettings.globalize_path(path + ".bak"))
	var err := DirAccess.rename_absolute(ProjectSettings.globalize_path(tmp), ProjectSettings.globalize_path(path))
	if err == OK:
		saved.emit(reason)
	return err


## The validated save, or {} when there is none or it is unusable. Tries the backup if the main file is corrupt.
func read_save() -> Dictionary:
	for candidate in [path, path + ".bak"]:
		var data := _read_file(candidate)
		if not data.is_empty():
			return data
	return {}


func delete_save() -> void:
	for p in [path, path + ".bak", path + ".tmp"]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))


func _read_file(file_path: String) -> Dictionary:
	if not FileAccess.file_exists(file_path):
		return {}
	var json := JSON.new()   # json.parse() reports errors by return code instead of printing engine errors
	if json.parse(FileAccess.get_file_as_string(file_path)) != OK:
		return {}
	return _validate(json.data)


## Returns the data when it has the right shape and a known version, else {}. Future versions would migrate here.
func _validate(parsed: Variant) -> Dictionary:
	if not (parsed is Dictionary):
		return {}
	var d: Dictionary = parsed
	if int(d.get("version", 0)) != SAVE_VERSION:
		return {}
	for key in ["act", "furthest_act", "flags", "counters", "beats", "unreality"]:
		if not d.has(key):
			return {}
	if not (d["flags"] is Dictionary and d["counters"] is Dictionary and d["beats"] is Dictionary and d["unreality"] is Dictionary):
		return {}
	if not (d["unreality"].has("base") and d["unreality"].has("level")):
		return {}
	var act_id := int(d["act"])
	if act_id < 1 or act_id > Acts.ACTS.size():
		return {}
	for key in (d["beats"] as Dictionary):
		if not (d["beats"][key] is Array):
			return {}
	return d


# ---- autosave ----
func _on_beat_completed(act: int, beat: String) -> void:
	var list: Array = beats_done.get(act, [])
	if not list.has(beat):
		list.append(beat)
	beats_done[act] = list
	_queue_autosave("beat " + beat)


func _queue_autosave(reason: String) -> void:
	if not session_active or _dirty:
		return
	_dirty = true
	# One write per frame no matter how many events fire together (finish() emits several).
	await get_tree().process_frame
	_dirty = false
	save_now(reason)
