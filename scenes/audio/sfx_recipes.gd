class_name SfxRecipes
extends RefCounted

const SynthScript = preload("res://scenes/audio/synth.gd")
## Named, procedurally generated sound effects for the whole game. (F-08)
##
## `SfxRecipes.get_stream("pickup")` builds the sound once and caches it. `SfxRecipes.NAMES` lists every recipe.
## To add one: add the name to NAMES and a branch in `_build`. Keep sounds short and soft (sincere comedy, no jump scares).

const NAMES: Array[String] = [
	"click", "thud", "pickup", "chime", "door_creak", "flea_tick", "flea_bite", "paper", "whoosh",
	"glass_clink", "heart_loss", "heart_gain", "error", "footstep", "footstep_wood", "footstep_tile", "footstep_grass", "footstep_carpet", "knock", "boing", "whisper",
]

static var _cache: Dictionary = {}


## True if `sfx_name` is a known recipe.
static func has(sfx_name: String) -> bool:
	return NAMES.has(sfx_name)


## The cached AudioStreamWAV for a recipe, or null (with a warning) for an unknown name.
static func get_stream(sfx_name: String) -> AudioStreamWAV:
	if not has(sfx_name):
		push_warning("SfxRecipes: unknown sfx '%s'" % sfx_name)
		return null
	if not _cache.has(sfx_name):
		_cache[sfx_name] = SynthScript.to_stream(_build(sfx_name))
	return _cache[sfx_name]


static func _build(sfx_name: String) -> PackedFloat32Array:
	match sfx_name:
		"click":
			return SynthScript.mix(SynthScript.tone(1800, 0.03, "square", 0.25, 0.0, 3.0), SynthScript.noise(0.02, 0.2, 0.0, 3.0))
		"thud":
			return SynthScript.mix(SynthScript.tone(110, 0.25, "sine", 0.7, 0.002, 3.0, 45), SynthScript.noise(0.12, 0.3, 0.0, 3.0, 0.9))
		"pickup":
			return SynthScript.mix(SynthScript.tone(660, 0.09, "triangle", 0.4, 0.003, 1.5), SynthScript.tone(990, 0.16, "triangle", 0.4, 0.003, 2.0), 0.07)
		"chime":
			var c := SynthScript.tone(1320, 0.7, "sine", 0.35, 0.002, 3.0)
			c = SynthScript.mix(c, SynthScript.tone(1980, 0.5, "sine", 0.2, 0.002, 3.0), 0.0)
			return SynthScript.mix(c, SynthScript.tone(2640, 0.35, "sine", 0.1, 0.002, 3.0), 0.0)
		"door_creak":
			return SynthScript.mix(SynthScript.tone(180, 0.9, "saw", 0.18, 0.1, 1.2, 320, 12.0), SynthScript.noise(0.9, 0.06, 0.2, 1.0, 0.85))
		"flea_tick":
			return SynthScript.tone(2400, 0.02, "square", 0.18, 0.0, 3.0)
		"flea_bite":
			return SynthScript.mix(SynthScript.tone(900, 0.06, "square", 0.25, 0.0, 2.0, 300), SynthScript.noise(0.04, 0.2, 0.0, 3.0))
		"paper":
			return SynthScript.noise(0.22, 0.25, 0.02, 1.5, 0.35, 11)
		"whoosh":
			return SynthScript.noise(0.5, 0.35, 0.18, 1.5, 0.8, 5)
		"glass_clink":
			return SynthScript.mix(SynthScript.tone(3100, 0.35, "sine", 0.3, 0.001, 4.0), SynthScript.tone(4700, 0.25, "sine", 0.15, 0.001, 4.0))
		"heart_loss":
			return SynthScript.mix(SynthScript.tone(392, 0.18, "triangle", 0.4, 0.004, 1.5), SynthScript.tone(294, 0.4, "triangle", 0.4, 0.004, 2.0), 0.14)
		"heart_gain":
			return SynthScript.mix(SynthScript.tone(392, 0.15, "triangle", 0.4, 0.004, 1.5), SynthScript.tone(523, 0.35, "triangle", 0.4, 0.004, 2.0), 0.12)
		"error":
			return SynthScript.mix(SynthScript.tone(150, 0.12, "square", 0.25, 0.002, 1.5), SynthScript.tone(130, 0.18, "square", 0.25, 0.002, 1.5), 0.13)
		"footstep":
			return SynthScript.mix(SynthScript.tone(85, 0.1, "sine", 0.5, 0.001, 3.0, 55), SynthScript.noise(0.06, 0.2, 0.0, 3.0, 0.88, 3))
		"footstep_wood":
			return SynthScript.mix(SynthScript.tone(95, 0.09, "sine", 0.4, 0.002, 3.0, 35), SynthScript.noise(0.05, 0.18, 0.0, 3.0, 0.85, 23))
		"footstep_tile":
			return SynthScript.mix(SynthScript.tone(220, 0.06, "sine", 0.28, 0.001, 3.0, 90), SynthScript.noise(0.025, 0.16, 0.0, 3.0, 0.7, 31))
		"footstep_grass":
			return SynthScript.noise(0.12, 0.12, 0.01, 2.0, 0.3, 37)
		"footstep_carpet":
			return SynthScript.noise(0.06, 0.24, 0.0, 3.0, 0.95, 41)
		"knock":
			var k := SynthScript.tone(200, 0.08, "sine", 0.6, 0.001, 3.0, 120)
			k = SynthScript.mix(k, SynthScript.tone(200, 0.08, "sine", 0.6, 0.001, 3.0, 120), 0.16)
			return SynthScript.mix(k, SynthScript.tone(200, 0.1, "sine", 0.6, 0.001, 3.0, 120), 0.32)
		"whisper":
			var breath := SynthScript.noise(1.3, 0.5, 0.25, 0.8, 0.55, 17)
			return SynthScript.pulsed(SynthScript.mix(breath, SynthScript.noise(1.3, 0.2, 0.3, 0.8, 0.9, 19)), 3.1, 0.85)
		"boing":
			return SynthScript.tone(180, 0.45, "sine", 0.5, 0.004, 1.5, 420, 25.0)
		_:
			return SynthScript.tone(440, 0.1)
