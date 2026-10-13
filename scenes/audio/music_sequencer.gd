class_name MusicSequencer
extends RefCounted
## Pure music scheduler: turns a MusicScore variation into "start this note now" events as time passes. (F-09)
##
## No audio here, so it is deterministic and testable. Usage:
##   var seq := MusicSequencer.new(MusicScore.variation_for_chapter(3))
##   each frame: for ev in seq.advance(delta): play(ev)      # ev = {layer, inst, midi, dur, vol_db, detune, step, late}
## Layers: "melody", "bass", "chord", "double" (melody an octave up, only at intensity >= 0.5).
## `set_intensity(0..1)` speeds the tempo up to +30% (smoothly); from 0.5 up it also adds the octave double and +20 cents of detune
## (a single step, so only two note sets ever need pre-rendering). Used for the Flea manic ramp.
## `silence(seconds)` holds the music back (chapter 8 starts with 60 s of it). The first advance() fires step 0 immediately.

const MAX_DELTA := 0.25   # a long frame hitch never releases a flood of notes
const DOUBLE_AT := 0.5
const TEMPO_BOOST := 0.3
const DETUNE_BOOST := 20.0

var variation: Dictionary
var intensity: float = 0.0

var _table: Array = []          # step index -> Array of {layer, inst, midi, steps, vol_db, min_intensity}
var _loop: int = 96
var _next: int = 0              # absolute index of the next step to fire
var _pos: float = 0.0           # absolute position in steps
var _silence: float = 0.0


func _init(v: Dictionary = MusicScore.DEFAULT_VARIATION) -> void:
	variation = v
	_silence = float(v.get("silent_first", 0.0))
	_build()


## Holds the music back for `seconds` more (adds to any silence already pending).
func silence(seconds: float) -> void:
	_silence += maxf(seconds, 0.0)


## Seconds of silence still pending.
func silence_left() -> float:
	return _silence


## Sets the intensity (clamped 0..1).
func set_intensity(v: float) -> void:
	intensity = clampf(v, 0.0, 1.0)


## Rewinds to the start of the theme (silence is not re-applied).
func restart() -> void:
	_next = 0
	_pos = 0.0


## Seconds per eighth-note step right now (tempo includes the intensity boost).
func step_seconds() -> float:
	return MusicScore.step_seconds({"bpm": float(variation["bpm"]) * (1.0 + TEMPO_BOOST * intensity)})


## Steps in one loop of the theme.
func loop_steps() -> int:
	return _loop


## Which bar (0-based) of the loop the playhead is in.
func bar() -> int:
	return (int(_pos) % _loop) / MusicScore.STEPS_PER_BAR


## How many complete loops have played.
func loops_done() -> int:
	return int(_pos) / _loop


## Moves the playhead forward by `delta` seconds and returns the notes to start (in order). Empty while silent.
func advance(delta: float) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	delta = minf(maxf(delta, 0.0), MAX_DELTA)
	if _silence > 0.0:
		_silence -= delta
		if _silence > 0.0:
			return out
		delta = -_silence
		_silence = 0.0
	var sec := step_seconds()
	_pos += delta / sec
	while float(_next) <= _pos:
		for e in _table[_next % _loop]:
			if intensity < float(e["min_intensity"]):
				continue
			out.append({
				"layer": e["layer"], "inst": e["inst"], "midi": e["midi"], "dur": float(e["steps"]) * sec,
				"vol_db": e["vol_db"], "detune": _detune(intensity),
				"step": _next, "late": (_pos - float(_next)) * sec,
			})
		_next += 1
	return out


## Every note of one full loop at the given intensity (inst, midi, dur, detune...), in step order, without moving the playhead.
## The music pre-renders exactly these notes in the background before playing.
func loop_events(at_intensity: float) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var sec := MusicScore.step_seconds({"bpm": float(variation["bpm"])})
	for k in _loop:
		for e in _table[k]:
			if at_intensity < float(e["min_intensity"]):
				continue
			out.append({"layer": e["layer"], "inst": e["inst"], "midi": e["midi"], "dur": float(e["steps"]) * sec,
				"vol_db": e["vol_db"], "detune": _detune(at_intensity), "step": k})
	return out


func _detune(at_intensity: float) -> float:
	return float(variation["detune"]) + (DETUNE_BOOST if at_intensity >= DOUBLE_AT else 0.0)


func _build() -> void:
	_loop = MusicScore.loop_steps(variation)
	_table.clear()
	for i in _loop:
		_table.append([])
	var tr := int(variation["transpose"])
	var sparse := float(variation["sparse"])
	var style := String(variation["accomp_style"])
	for bar_i in _loop / MusicScore.STEPS_PER_BAR:
		var base := bar_i * MusicScore.STEPS_PER_BAR
		var step := 0
		var idx := 0
		for n in MusicScore.MELODY[bar_i]:
			var midi := int(n[0])
			var len := int(n[1])
			var dropped := idx > 0 and sparse > 0.0 and float(absi(("%d:%d" % [bar_i, idx]).hash()) % 100) / 100.0 < sparse
			if midi >= 0 and not dropped:
				var m := midi + tr + 12 * int(variation["octave"])
				_add(base + step, "melody", String(variation["melody"]), m, len, 0.0, 0.0)
				_add(base + step, "double", String(variation["melody"]), m + 12, len, -9.0, DOUBLE_AT)
			step += len
			idx += 1
		var chord: Dictionary = MusicScore.CHORDS[MusicScore.PROGRESSION[bar_i]]
		var triad: Array = chord["triad"]
		var inst := String(variation["accomp"])
		if style == "waltz":
			_add(base, "bass", inst, int(chord["bass"]) + tr, 2, -3.0, 0.0)
			for s in [2, 4]:
				for t in triad:
					_add(base + s, "chord", inst, int(t) + tr, 2, -9.0, 0.0)
		elif style == "pad":
			_add(base, "bass", inst, int(chord["bass"]) + tr, MusicScore.STEPS_PER_BAR, -6.0, 0.0)
			for t in triad:
				_add(base, "chord", inst, int(t) + tr, MusicScore.STEPS_PER_BAR, -10.0, 0.0)


func _add(step: int, layer: String, inst: String, midi: int, steps: int, vol_db: float, min_intensity: float) -> void:
	_table[step].append({"layer": layer, "inst": inst, "midi": midi, "steps": steps, "vol_db": vol_db, "min_intensity": min_intensity})
