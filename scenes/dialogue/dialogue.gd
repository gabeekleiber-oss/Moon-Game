extends Node
## Autoload `Dialogue`: plays dialogue JSON files with the on-screen box. (F-01)
##
## From any script (chapters, interactables, cutscenes):
##     await Dialogue.play("moon_01")          # loads res://data/dialogue/moon_01.json; resumes when it ends
##     Dialogue.play("res://some/other.json")  # full paths work too; fire-and-forget is fine
## While a dialogue runs: Dialogue.is_active() is true, the mouse is released, the player stands still,
## and Events emits dialogue_started / dialogue_line / caption / dialogue_choice_made / dialogue_cue /
## speaker_blip / dialogue_ended. The last 12 lines (player picks marked who="you") are in Dialogue.log().
## Effects in the JSON (flea, heart, set) are applied through Game as nodes/choices are reached.

## Emitted when a dialogue ends (normally or via stop()).
signal finished(dialogue_id: String)

const DIALOGUE_DIR := "res://data/dialogue/"

var _runner := DialogueRunner.new()
var _box: DialogueBox
var _active: bool = false
var _prev_mouse: Input.MouseMode = Input.MOUSE_MODE_CAPTURED


func _ready() -> void:
	_box = DialogueBox.new()
	add_child(_box)
	_runner.line_shown.connect(_on_line_shown)
	_runner.cue.connect(func(kind: String, value: Variant) -> void: Events.dialogue_cue.emit(kind, value))
	_runner.choice_made.connect(func(i: int, t: String) -> void: Events.dialogue_choice_made.emit(i, t))
	_runner.finished.connect(_on_finished)
	_box.advance_requested.connect(_runner.advance)
	_box.choice_selected.connect(_runner.choose)


## True while a dialogue is on screen.
func is_active() -> bool:
	return _active


## The last 12 lines shown, oldest first: [{"who": String, "text": String}, ...].
func log() -> Array[Dictionary]:
	return _runner.log


## Loads `id_or_path` (id -> res://data/dialogue/<id>.json) without playing it. Check `is_valid()` on the result.
func load_data(id_or_path: String) -> DialogueData:
	var path := id_or_path if id_or_path.begins_with("res://") else "%s%s.json" % [DIALOGUE_DIR, id_or_path]
	return DialogueData.from_file(path)


## Plays a dialogue and returns true when it finished, false if it could not start (invalid file,
## or another dialogue is already running). Use `await` to wait for the end.
func play(id_or_path: String) -> bool:
	if _active:
		push_warning("Dialogue.play('%s') ignored: a dialogue is already running." % id_or_path)
		return false
	var data := load_data(id_or_path)
	for w in data.warnings:
		push_warning("Dialogue '%s': %s" % [id_or_path, w])
	if not data.is_valid():
		for e in data.errors:
			push_error("Dialogue '%s': %s" % [id_or_path, e])
		return false
	_active = true
	_prev_mouse = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Events.dialogue_started.emit(data.id)
	_runner.start(data)
	await finished
	return true


## Ends the running dialogue immediately (e.g. when a cutscene is skipped). Effects already reached stay applied.
func stop() -> void:
	_runner.stop()


func _on_line_shown(_node_id: String, node: Dictionary) -> void:
	var who := str(node.get("who", ""))
	var text := str(node.get("text", ""))
	if text != "":
		Events.dialogue_line.emit(who, text)
		Events.caption.emit(who, text)
	_box.show_line(node)


func _on_finished(dialogue_id: String) -> void:
	_box.hide_box()
	_active = false
	if _prev_mouse == Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	Events.dialogue_ended.emit(dialogue_id)
	finished.emit(dialogue_id)
