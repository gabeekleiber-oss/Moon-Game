class_name Synth
extends RefCounted
## Tiny procedural sound synthesizer: builds mono sample buffers and turns them into AudioStreamWAV. (F-08)
##
## All functions are static and deterministic (noise uses a fixed seed), so recipes sound the same every run and can be
## tested headless. Buffers are PackedFloat32Array of samples in -1..1 at `RATE` Hz.
## Typical use: `Synth.to_stream(Synth.mix(Synth.tone(440, 0.2), Synth.noise(0.1), 0.05))`.

## Sample rate of every generated sound.
const RATE := 22050


## A pitched tone. `wave`: "sine", "triangle", "square" or "saw". `sweep_to` > 0 glides the pitch to that frequency over the
## duration. `curve` shapes the fade-out (1 = linear, 3 = sharp pluck). `vibrato` is a depth in Hz at 6 Hz.
static func tone(freq: float, dur: float, wave: String = "sine", vol: float = 0.5, attack: float = 0.004,
		curve: float = 2.0, sweep_to: float = 0.0, vibrato: float = 0.0) -> PackedFloat32Array:
	var n := maxi(1, int(dur * RATE))
	var out := PackedFloat32Array()
	out.resize(n)
	var phase := 0.0
	for i in n:
		var t := float(i) / RATE
		var u := float(i) / float(n)
		var f := freq if sweep_to <= 0.0 else lerpf(freq, sweep_to, u)
		if vibrato > 0.0:
			f += sin(t * TAU * 6.0) * vibrato
		phase = fposmod(phase + f / RATE, 1.0)
		out[i] = _wave(wave, phase) * vol * _env(t, u, attack, curve)
	return out


## A sustained tone: fades in over `attack`, holds, fades out over `release` (both seconds, inside `dur`). For organs, pads, flutes.
## `vibrato` is a depth in Hz at `vibrato_rate` Hz.
static func held(freq: float, dur: float, wave: String = "sine", vol: float = 0.4, attack: float = 0.05, release: float = 0.1,
		vibrato: float = 0.0, vibrato_rate: float = 5.0) -> PackedFloat32Array:
	var n := maxi(1, int(dur * RATE))
	var out := PackedFloat32Array()
	out.resize(n)
	var phase := 0.0
	for i in n:
		var t := float(i) / RATE
		var f := freq
		if vibrato > 0.0:
			f += sin(t * TAU * vibrato_rate) * vibrato
		phase = fposmod(phase + f / RATE, 1.0)
		var env := 1.0
		if attack > 0.0:
			env = minf(env, t / attack)
		if release > 0.0:
			env = minf(env, (dur - t) / release)
		out[i] = _wave(wave, phase) * vol * clampf(env, 0.0, 1.0)
	return out


## White noise burst. `lowpass` 0..1 darkens it (0 = white, 0.95 = very dull rumble).
static func noise(dur: float, vol: float = 0.4, attack: float = 0.003, curve: float = 2.0, lowpass: float = 0.0,
		seed_value: int = 7) -> PackedFloat32Array:
	var n := maxi(1, int(dur * RATE))
	var out := PackedFloat32Array()
	out.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var last := 0.0
	for i in n:
		var t := float(i) / RATE
		var u := float(i) / float(n)
		var raw := rng.randf_range(-1.0, 1.0)
		last = lowpass * last + (1.0 - lowpass) * raw
		out[i] = last * vol * _env(t, u, attack, curve)
	return out


## Adds `b` on top of `a`, starting `offset` seconds into `a`. Returns a new buffer long enough for both.
static func mix(a: PackedFloat32Array, b: PackedFloat32Array, offset: float = 0.0) -> PackedFloat32Array:
	var start := maxi(0, int(offset * RATE))
	var out := PackedFloat32Array()
	out.resize(maxi(a.size(), start + b.size()))
	for i in a.size():
		out[i] = a[i]
	for i in b.size():
		out[start + i] += b[i]
	return out


## Multiplies every sample by `gain`.
static func scaled(a: PackedFloat32Array, gain: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(a.size())
	for i in a.size():
		out[i] = a[i] * gain
	return out


## Length of a buffer in seconds.
static func duration(a: PackedFloat32Array) -> float:
	return float(a.size()) / RATE


## Largest absolute sample (0 for an empty buffer).
static func peak(a: PackedFloat32Array) -> float:
	var p := 0.0
	for s in a:
		p = maxf(p, absf(s))
	return p


## Converts a buffer to a 16-bit mono AudioStreamWAV (samples are clamped; a hard-clipped buffer is safe, just harsh).
static func to_stream(a: PackedFloat32Array, loop: bool = false) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(a.size() * 2)
	for i in a.size():
		bytes.encode_s16(i * 2, int(clampf(a[i], -1.0, 1.0) * 32767.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = bytes
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = a.size()
	return w


static func _wave(kind: String, phase: float) -> float:
	match kind:
		"square":
			return 1.0 if phase < 0.5 else -1.0
		"saw":
			return phase * 2.0 - 1.0
		"triangle":
			return 4.0 * absf(phase - 0.5) - 1.0
		_:
			return sin(phase * TAU)


static func _env(t: float, u: float, attack: float, curve: float) -> float:
	var a := 1.0 if attack <= 0.0 else minf(t / attack, 1.0)
	return a * pow(maxf(1.0 - u, 0.0), curve)
