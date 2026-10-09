class_name Typewriter
extends RefCounted
## Pure timing for the typewriter effect. (F-01) Spec: 38 chars/s, +180 ms after . ? !, +90 ms after commas.
##
## `reveal_times(text)[i]` is the time (seconds from the start of the line) at which character i becomes visible.
## A run of sentence punctuation ("?!", "...") pauses once, after its last character.

const CPS := 38.0
const PAUSE_SENTENCE := 0.18
const PAUSE_COMMA := 0.09
const SENTENCE_CHARS := ".?!"


## Seconds at which each character of `text` becomes visible.
static func reveal_times(text: String) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(text.length())
	var t := 0.0
	for i in text.length():
		out[i] = t
		t += 1.0 / CPS + _pause_after(text, i)
	return out


## Total seconds until the whole line is visible.
static func duration(text: String) -> float:
	var times := reveal_times(text)
	return 0.0 if times.is_empty() else times[times.size() - 1]


## How many characters are visible `elapsed` seconds into the line.
static func visible_count(times: PackedFloat32Array, elapsed: float) -> int:
	var n := 0
	while n < times.size() and times[n] <= elapsed:
		n += 1
	return n


static func _pause_after(text: String, i: int) -> float:
	var ch := text[i]
	if ch == ",":
		return PAUSE_COMMA
	if SENTENCE_CHARS.contains(ch):
		var nxt := text[i + 1] if i + 1 < text.length() else ""
		if nxt != "" and SENTENCE_CHARS.contains(nxt):
			return 0.0
		return PAUSE_SENTENCE
	return 0.0
