class_name BeatTracker
extends RefCounted
## Pure ordered-story-beat bookkeeping (no nodes; testable). An act defines its beats in story order; each beat may
## require other beats. By default a beat requires the one before it (strict story order); pass `requires` to allow
## free exploration (e.g. several rooms in any order, then a final beat that requires all of them).
##   var t := BeatTracker.new()
##   t.add("enter"); t.add("letter"); t.add("shoo"); t.add("broom"); t.add("quit")      # a chain
##   t.add("find_a", [], false); t.add("find_b", [], false); t.add("done", ["find_a", "find_b"])  # any order, then join
## `complete(id)` returns false (and does nothing) if the beat is unknown, already done, or its requirements are not met.

var _order: Array[String] = []
var _requires: Dictionary = {}      # id -> Array[String]
var _done: Dictionary = {}          # id -> true


## Adds a beat. `requires` = explicit prerequisites; `chain` = also require the previous beat (default true).
func add(id: String, requires: Array = [], chain: bool = true) -> void:
	var req: Array = requires.duplicate()
	if chain and not _order.is_empty() and not req.has(_order[-1]):
		req.append(_order[-1])
	_order.append(id)
	_requires[id] = req


## True if `id` can be completed right now.
func is_available(id: String) -> bool:
	if not _requires.has(id) or _done.has(id):
		return false
	for r in _requires[id]:
		if not _done.has(r):
			return false
	return true


## Completes a beat. Returns true if it newly completed.
func complete(id: String) -> bool:
	if not is_available(id):
		return false
	_done[id] = true
	return true


## Marks the given beats done without any side effects (save/load). Unknown ids are ignored.
func restore(ids: Array) -> void:
	for id in ids:
		if _order.has(str(id)):
			_done[str(id)] = true


func is_done(id: String) -> bool:
	return _done.has(id)


## Beats that can be completed right now, in story order.
func available() -> Array[String]:
	var out: Array[String] = []
	for id in _order:
		if is_available(id):
			out.append(id)
	return out


## The first available beat (the "current" story moment), or "" when everything is done.
func current() -> String:
	var a := available()
	return a[0] if not a.is_empty() else ""


func all_done() -> bool:
	return not _order.is_empty() and _done.size() == _order.size()


## 0..1 fraction of beats done.
func progress() -> float:
	return 0.0 if _order.is_empty() else float(_done.size()) / _order.size()


func ids() -> Array[String]:
	return _order.duplicate()


func count() -> int:
	return _order.size()
