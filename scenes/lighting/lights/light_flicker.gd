class_name LightFlicker
extends RefCounted
## Pure flicker maths for the light helpers (S-01), so the rules are testable and live in one place:
##  * NO STROBING (docs/ART_BIBLE.md 7, 9): nothing here may change by >= 10% of its range more than 3 times a second. The TV is the
##    fastest light in the game; it changes level at most 2.5 times a second and eases between levels. `max_changes_per_second` measures it.
##  * REDUCED MOTION: every function takes `motion` (Unreality.motion_scale(): 1 normally, 0 with Reduced Motion). 0 returns a steady 1.0.
##  * UNREALITY (ART_BIBLE 1 "Light"): `lamp` hums at the "off" band and drops out now and then at "wrong"; callers pass ramps.
## All results are multipliers around 1.0 (energy = base * result) unless stated.

const TAU_F := TAU


## A candle: gentle, organic, always alive. Amplitude +/- ~7%.
static func candle(t: float, noise_seed: int = 0, motion: float = 1.0) -> float:
	var s := float(noise_seed) * 1.713
	var n := 0.5 * sin(TAU_F * 1.3 * t + s) + 0.3 * sin(TAU_F * 2.1 * t + 1.7 + s * 0.7) + 0.2 * sin(TAU_F * 3.1 * t + 4.1 + s * 1.3)
	return 1.0 + 0.07 * n * motion


## A CRT in a dark room: returns {"energy": multiplier, "mix": 0..1 (0 = cold blue, 1 = white-ish)}. Levels change at most every
## SEG seconds (2.5/s) with a smooth ease, like slow scene cuts, never a strobe. Energy swings about 0.55..1.15.
const TV_SEG := 0.4
const TV_EASE := 0.18
static func tv(t: float, noise_seed: int = 0, motion: float = 1.0) -> Dictionary:
	if motion <= 0.0:
		return {"energy": 1.0, "mix": 0.5}
	var i := int(floorf(t / TV_SEG))
	var local := t - float(i) * TV_SEG
	var e_prev := _level(i - 1, noise_seed)
	var e_cur := _level(i, noise_seed)
	var k := smoothstep(0.0, TV_EASE, local)
	var e := lerpf(e_prev, e_cur, k)
	var m_prev := _level(i - 1, noise_seed + 977)
	var m_cur := _level(i, noise_seed + 977)
	var mixv := lerpf(m_prev, m_cur, k)
	var energy_mul := lerpf(1.0, 0.55 + 0.6 * e, motion)
	return {"energy": energy_mul, "mix": lerpf(0.5, mixv, motion)}


## A practical lamp under Unreality. `hum` 0..1 (the "off" band: a faint slow breathing), `wrong` 0..1 (the "wrong" band: rare dropouts
## about every 7 s, each about a quarter-second and up to 60% deep). `hum = wrong = 0` is exactly 1.0.
static func lamp(t: float, hum: float, wrong: float, noise_seed: int = 0, motion: float = 1.0) -> float:
	var s := float(noise_seed) * 2.31
	var f := 1.0 - hum * 0.05 * (0.5 + 0.5 * sin(TAU_F * 0.7 * t + s)) * motion
	if wrong > 0.0 and motion > 0.0:
		var period := 7.0 + float(noise_seed % 5)
		var ph := fposmod(t + float(noise_seed), period)
		var dip := smoothstep(0.0, 0.06, ph) * (1.0 - smoothstep(0.18, 0.30, ph))
		f -= 0.6 * wrong * dip * motion
	return f


## Largest number of "significant" changes (swings of >= `threshold`, direction reversals) in any 1-second window of `samples` taken
## every `dt` seconds. WCAG-style: more than 3 per second is a flash hazard. Used by the tests.
static func max_changes_per_second(samples: PackedFloat32Array, dt: float, threshold: float = 0.1) -> int:
	if samples.size() < 2:
		return 0
	var events: PackedFloat32Array = PackedFloat32Array()
	var ref := samples[0]
	var dir := 0
	for i in range(1, samples.size()):
		var v := samples[i]
		if dir == 0:
			if v - ref >= threshold:
				dir = 1
				ref = v
				events.append(i * dt)
			elif ref - v >= threshold:
				dir = -1
				ref = v
				events.append(i * dt)
		elif dir == 1:
			if v > ref:
				ref = v
			elif ref - v >= threshold:
				dir = -1
				ref = v
				events.append(i * dt)
		else:
			if v < ref:
				ref = v
			elif v - ref >= threshold:
				dir = 1
				ref = v
				events.append(i * dt)
	var best := 0
	var lo := 0
	for hi in events.size():
		while events[hi] - events[lo] >= 1.0:
			lo += 1
		best = maxi(best, hi - lo + 1)
	return best


static func _level(i: int, noise_seed: int) -> float:
	return float(hash(Vector2i(i, noise_seed)) & 0xFFFF) / 65535.0
