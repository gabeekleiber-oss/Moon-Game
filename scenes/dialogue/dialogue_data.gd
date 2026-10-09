class_name DialogueData
extends RefCounted
## Loads and validates one dialogue JSON (shape: docs/ARCHITECTURE.md "Dialogue JSON shape"). (F-01)
##
## Usage: `var d := DialogueData.from_file("res://data/dialogue/moon_01.json")`; check `d.is_valid()`;
## read `d.errors` (structural problems: the dialogue cannot run) and `d.warnings`
## (design-rule problems: no/multiple canon choice, a non-canon choice that does not funnel back to
## the canon path within FUNNEL_MAX_HOPS nodes, unreachable nodes).
## `d.todo_verbatim_count` counts nodes still holding TODO_VERBATIM placeholders.

## Non-canon choices must rejoin the canon path within this many nodes.
const FUNNEL_MAX_HOPS := 2
const MAX_CHOICES := 4

var id: String = ""
var start: String = ""
var nodes: Dictionary = {}
var errors: Array[String] = []
var warnings: Array[String] = []
var todo_verbatim_count: int = 0


## Reads and validates a dialogue file. Always returns an object; check `is_valid()`.
static func from_file(path: String) -> DialogueData:
	var d := DialogueData.new()
	if not FileAccess.file_exists(path):
		d.errors.append("File not found: %s" % path)
		return d
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (parsed is Dictionary):
		d.errors.append("Not a JSON object: %s" % path)
		return d
	d._load(parsed as Dictionary)
	return d


## Builds and validates from an already-parsed Dictionary (used by tests and tools).
static func from_dict(dict: Dictionary) -> DialogueData:
	var d := DialogueData.new()
	d._load(dict)
	return d


## True when there are no structural errors.
func is_valid() -> bool:
	return errors.is_empty()


## Returns the node dictionary for `node_id`, or {} if missing.
func get_node_data(node_id: String) -> Dictionary:
	return nodes.get(node_id, {}) as Dictionary


## Ids of every node reachable in one step from `node` (its `next` and all choice `goto`s).
func successors(node: Dictionary) -> Array[String]:
	var out: Array[String] = []
	var nxt: String = str(node.get("next", ""))
	if nxt != "":
		out.append(nxt)
	for c in node.get("choices", []):
		var g: String = str((c as Dictionary).get("goto", ""))
		if g != "":
			out.append(g)
	return out


func _load(dict: Dictionary) -> void:
	id = str(dict.get("id", ""))
	start = str(dict.get("start", ""))
	nodes = dict.get("nodes", {}) as Dictionary
	if id == "":
		errors.append("Missing `id`.")
	if nodes.is_empty():
		errors.append("No `nodes`.")
		return
	if not nodes.has(start):
		errors.append("`start` node '%s' does not exist." % start)
	for nid in nodes:
		_check_node(str(nid), nodes[nid] as Dictionary)
	if errors.is_empty():
		_check_reachability()


func _check_node(nid: String, node: Dictionary) -> void:
	var text := str(node.get("text", ""))
	if text.contains("TODO_VERBATIM"):
		todo_verbatim_count += 1
	var nxt := str(node.get("next", ""))
	if nxt != "" and not nodes.has(nxt):
		errors.append("Node '%s': `next` '%s' does not exist." % [nid, nxt])
	var choices: Array = node.get("choices", [])
	if choices.is_empty():
		return
	if nxt != "":
		warnings.append("Node '%s' has both `next` and `choices`; choices win." % nid)
	if choices.size() > MAX_CHOICES:
		errors.append("Node '%s' has %d choices (max %d)." % [nid, choices.size(), MAX_CHOICES])
	var canon_goto := ""
	var canon_count := 0
	for c in choices:
		var cd := c as Dictionary
		if str(cd.get("text", "")) == "":
			errors.append("Node '%s': a choice has no `text`." % nid)
		var g := str(cd.get("goto", ""))
		if g == "" or not nodes.has(g):
			errors.append("Node '%s': choice goto '%s' does not exist." % [nid, g])
		if cd.get("canon", false):
			canon_count += 1
			canon_goto = g
	if choices.size() > 1:
		if canon_count != 1:
			warnings.append("Node '%s': needs exactly one canon choice (has %d)." % [nid, canon_count])
		elif errors.is_empty():
			for c in choices:
				var cd2 := c as Dictionary
				if not cd2.get("canon", false) and not _reaches(str(cd2.get("goto", "")), canon_goto, FUNNEL_MAX_HOPS):
					warnings.append("Node '%s': choice '%s' does not funnel to canon '%s' within %d nodes." % [nid, str(cd2.get("text", "")).left(24), canon_goto, FUNNEL_MAX_HOPS])


## True if `target` is `from` or reachable from it within `hops` further steps.
func _reaches(from: String, target: String, hops: int) -> bool:
	if from == target:
		return true
	if hops <= 0 or not nodes.has(from):
		return false
	for s in successors(nodes[from] as Dictionary):
		if _reaches(s, target, hops - 1):
			return true
	return false


func _check_reachability() -> void:
	var seen := {}
	var stack: Array[String] = [start]
	while not stack.is_empty():
		var cur: String = stack.pop_back()
		if seen.has(cur):
			continue
		seen[cur] = true
		for s in successors(nodes[cur] as Dictionary):
			stack.append(s)
	for nid in nodes:
		if not seen.has(nid):
			warnings.append("Node '%s' is unreachable from start." % nid)
