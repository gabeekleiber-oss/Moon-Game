class_name UnrealityModel
extends RefCounted
## Pure maths of the hidden insanity value (no nodes, so tests can step it by hand). The `Unreality` autoload wraps one of these.
##
## Three layers add up to the felt value:
##  - `base`   permanent ratchet. Only goes up (story beats raise it, a slow drift creeps it up while you play).
##  - `spike`  temporary jolt added on top, decays exponentially (a shock, a wrong face, the moon turning to look at you).
##  - `floor_` the minimum the current act allows (a story-set lower bound; base is lifted to it).
## `level` is the smoothed result: it eases toward (base + spike) so effects never pop.

const BAND_EDGES: Array[float] = [0.0, 0.15, 0.35, 0.55, 0.75, 0.90]
const BAND_NAMES: Array[String] = ["ordinary", "off", "wrong", "fraying", "unmoored", "ruin"]

var base: float = 0.0
var spike: float = 0.0
var floor_: float = 0.0
var ceiling: float = 1.0
var level: float = 0.0
## Permanent creep per MINUTE of play (the slow, never-quite-noticed rise).
var drift_per_minute: float = 0.01
## Seconds for `level` to catch up with its target (bigger = gentler).
var smoothing: float = 1.2
## Seconds for a spike to decay to ~37% (one time constant).
var spike_decay: float = 6.0


## Advance by `delta` seconds. Returns the new level.
func step(delta: float) -> float:
	base = clampf(maxf(base, floor_) + drift_per_minute / 60.0 * delta, 0.0, ceiling)
	spike *= exp(-delta / maxf(spike_decay, 0.01))
	var target := clampf(base + spike, floor_, ceiling)
	level = lerpf(level, target, 1.0 - exp(-delta / maxf(smoothing, 0.01)))
	return level


## The value `level` is heading for.
func target() -> float:
	return clampf(base + spike, floor_, ceiling)


## Permanently raises `base` (never lowers it). Use for story beats.
func raise(amount: float) -> void:
	base = clampf(base + maxf(amount, 0.0), 0.0, ceiling)


## Raises base to at least `value`.
func raise_to(value: float) -> void:
	base = clampf(maxf(base, value), 0.0, ceiling)


## Adds a temporary jolt that then decays.
func jolt(amount: float) -> void:
	spike = clampf(spike + amount, 0.0, 1.0)


## Debug/cutscene hard set (can lower). Level jumps if `instant`.
func force(value: float, instant: bool = false) -> void:
	base = clampf(value, 0.0, ceiling)
	spike = 0.0
	if instant:
		level = base


## Band index 0..5 for a level.
static func band_of(value: float) -> int:
	var b := 0
	for i in BAND_EDGES.size():
		if value >= BAND_EDGES[i]:
			b = i
	return b


## Smoothstep remap of a level between two edges: 0 below `a`, 1 above `b`. The standard way for any effect to read the value.
static func ramp_of(value: float, a: float, b: float) -> float:
	return smoothstep(a, b, value)


## Stable pseudo-random 0..1 for a string id (same id, same number, every run). Used to decide WHICH things go wrong first.
static func hash01(id: String) -> float:
	return float(id.hash() % 100000) / 100000.0
