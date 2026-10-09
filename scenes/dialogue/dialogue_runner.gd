class_name DialogueRunner
extends RefCounted
## Walks a DialogueData graph: shows lines, offers choices, applies effects, keeps the log. (F-01)
##
## No UI and no timing in here (see DialogueBox / Dialogue autoload). Typical flow:
##   var r := DialogueRunner.new(); r.line_shown.connect(...); r.finished.connect(...); r.start(data)
##   on a plain line: r.advance();  on a fork (r.has_choices()): r.choose(index)
## Effects are read from a node OR a choice: `flea` (float), `heart` ({"elsa": -1}), `set` (flag name or array).
## Node extras `cam`, `sfx`, `emote` are re-emitted through `cue` for cutscene/audio listeners; `wait` (seconds
## to pause BEFORE the line appears) is carried in the node dictionary for the presenter to honour.

## A node was entered. `node` is the raw dictionary (who, text, choices, wait, ...).
signal line_shown(node_id: String, node: Dictionary)
## A node carried a cue key (`cam`, `sfx` or `emote`).
signal cue(kind: String, value: Variant)
## The player picked choice `index` (0-based) with this `text`.
signal choice_made(index: int, text: String)
## The dialogue ended (a node with no `next` and no `choices` was advanced, or stop() was called).
signal finished(dialogue_id: String)

## How many lines the log keeps.
const LOG_SIZE := 12
const CUE_KEYS := ["cam", "sfx", "emote"]

var data: DialogueData
var current_id: String = ""
var current: Dictionary = {}
var running: bool = false
## Last LOG_SIZE lines, oldest first: {"who": String, "text": String}. Player picks are logged with who "you".
var log: Array[Dictionary] = []


## Starts `d` at its start node. Does nothing (and returns false) if the data has errors.
func start(d: DialogueData) -> bool:
	if d == null or not d.is_valid():
		push_warning("DialogueRunner: refusing to start invalid dialogue.")
		return false
	data = d
	running = true
	_enter(d.start)
	return true


## True if the current node is a fork waiting for choose().
func has_choices() -> bool:
	return running and not (current.get("choices", []) as Array).is_empty()


## Choices of the current node (Array of dictionaries with at least `text`).
func choices() -> Array:
	return current.get("choices", []) as Array


## Moves past a plain line (follows `next`, or finishes). Ignored while a fork is waiting.
func advance() -> void:
	if not running or has_choices():
		return
	var nxt := str(current.get("next", ""))
	if nxt == "":
		stop()
	else:
		_enter(nxt)


## Picks choice `index` (0-based) at a fork, applies its effects and follows its `goto`.
func choose(index: int) -> void:
	if not has_choices():
		return
	var list := choices()
	if index < 0 or index >= list.size():
		return
	var c := list[index] as Dictionary
	var text := str(c.get("text", ""))
	_push_log("you", text)
	choice_made.emit(index, text)
	_apply_effects(c)
	_enter(str(c.get("goto", "")))


## Ends the dialogue immediately.
func stop() -> void:
	if not running:
		return
	running = false
	finished.emit(data.id)


func _enter(node_id: String) -> void:
	current_id = node_id
	current = data.get_node_data(node_id)
	_apply_effects(current)
	for k in CUE_KEYS:
		if current.has(k):
			cue.emit(k, current[k])
	var text := str(current.get("text", ""))
	if text != "":
		_push_log(str(current.get("who", "")), text)
	line_shown.emit(node_id, current)


func _apply_effects(src: Dictionary) -> void:
	if src.has("flea"):
		Game.add_flea(float(src["flea"]), "dialogue")
	if src.has("heart"):
		var h := src["heart"] as Dictionary
		for who in h:
			Game.add_heart(str(who), int(h[who]))
	if src.has("set"):
		var s: Variant = src["set"]
		if s is Array:
			for f in s:
				Game.set_flag(str(f))
		else:
			Game.set_flag(str(s))


func _push_log(who: String, text: String) -> void:
	log.append({"who": who, "text": text})
	while log.size() > LOG_SIZE:
		log.pop_front()
