class_name Instruments
extends RefCounted
## Procedural instrument voices for the music: music box, pump organ, bell pad, flute. (F-09)
##
## `Instruments.stream("music_box", 72)` returns a cached AudioStreamWAV for one note (MIDI number, A4 = 69).
## Sustained instruments (pump_organ, bell_pad, flute) honour the requested duration (rounded up to 0.25 s so only a few
## variants are ever built); the music box rings for a fixed time like a real tine. `detune_cents` bends the pitch for wobbly,
## unsettling treatments. Notes are rendered once on first use and cached.

const SynthScript = preload("res://scenes/audio/synth.gd")
const NAMES: Array[String] = ["music_box", "pump_organ", "bell_pad", "flute"]
const MAX_HELD := 3.0
const BOX_RING := 1.6

static var _cache: Dictionary = {}
static var _mutex: Mutex = Mutex.new()


## True for instruments whose length follows the requested duration (everything except the music box).
static func is_sustained(inst: String) -> bool:
	return inst != "music_box"


## Frequency in Hz of a MIDI note number (+ optional detune in cents).
static func midi_to_hz(midi: float, detune_cents: float = 0.0) -> float:
	return 440.0 * pow(2.0, (midi - 69.0) / 12.0 + detune_cents / 1200.0)


## The (cached) stream for one note. Unknown instrument names fall back to the music box.
## Safe to call from worker threads (the music pre-renders notes in the background).
static func stream(inst: String, midi: int, dur: float = 0.5, detune_cents: float = 0.0) -> AudioStreamWAV:
	if not NAMES.has(inst):
		inst = "music_box"
	var d := _quantised_dur(inst, dur)
	var key := _key(inst, midi, d, detune_cents)
	_mutex.lock()
	var hit: AudioStreamWAV = _cache.get(key)
	_mutex.unlock()
	if hit != null:
		return hit
	var made := SynthScript.to_stream(_render(inst, midi, d, detune_cents))   # rendered outside the lock; a duplicate render is harmless
	_mutex.lock()
	_cache[key] = made
	_mutex.unlock()
	return made


## True if this exact note (after duration/detune rounding) is already rendered, so `stream()` returns instantly.
static func is_cached(inst: String, midi: int, dur: float = 0.5, detune_cents: float = 0.0) -> bool:
	if not NAMES.has(inst):
		inst = "music_box"
	_mutex.lock()
	var has: bool = _cache.has(_key(inst, midi, _quantised_dur(inst, dur), detune_cents))
	_mutex.unlock()
	return has


## How many notes are cached (for tests/diagnostics).
static func cache_size() -> int:
	_mutex.lock()
	var n := _cache.size()
	_mutex.unlock()
	return n


static func _quantised_dur(inst: String, dur: float) -> float:
	return BOX_RING if inst == "music_box" else clampf(ceilf(dur / 0.25) * 0.25, 0.25, MAX_HELD)


static func _key(inst: String, midi: int, d: float, cents: float) -> String:
	return "%s|%d|%.2f|%d" % [inst, midi, d, int(round(cents))]


static func _render(inst: String, midi: int, dur: float, cents: float) -> PackedFloat32Array:
	var f := midi_to_hz(midi, cents)
	match inst:
		"pump_organ":
			var b := SynthScript.held(f, dur, "saw", 0.10, 0.07, 0.12)
			b = SynthScript.mix(b, SynthScript.held(f * 1.003, dur, "square", 0.06, 0.07, 0.12))
			return SynthScript.mix(b, SynthScript.held(f * 2.0, dur, "triangle", 0.05, 0.09, 0.12))
		"bell_pad":
			var b := SynthScript.held(f, dur, "sine", 0.22, 0.25, maxf(0.3, dur * 0.4))
			b = SynthScript.mix(b, SynthScript.held(f * 2.0, dur, "sine", 0.07, 0.3, maxf(0.3, dur * 0.4)))
			return SynthScript.mix(b, SynthScript.held(f * 3.01, dur, "sine", 0.03, 0.35, maxf(0.3, dur * 0.4)))
		"flute":
			var b := SynthScript.held(f, dur, "triangle", 0.26, 0.06, 0.1, 4.0, 5.0)
			return SynthScript.mix(b, SynthScript.noise(dur, 0.025, 0.05, 0.3, 0.7, midi))
		_:
			var b := SynthScript.tone(f, BOX_RING, "sine", 0.34, 0.001, 3.0)
			b = SynthScript.mix(b, SynthScript.tone(f * 2.76, BOX_RING * 0.6, "sine", 0.11, 0.001, 4.0))
			return SynthScript.mix(b, SynthScript.tone(f * 5.4, BOX_RING * 0.3, "sine", 0.04, 0.001, 5.0))
