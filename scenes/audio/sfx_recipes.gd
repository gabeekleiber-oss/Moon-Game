class_name SfxRecipes
extends RefCounted
## Named, procedurally generated sound effects for the whole game. (F-08)
##
## `SfxRecipes.get_stream("pickup")` builds the sound once and caches it. `SfxRecipes.NAMES` lists every recipe.
## To add one: add the name to NAMES and a branch in `_build`. Keep sounds short and soft (sincere comedy, no jump scares).

const NAMES: Array[String] = [
	"click", "thud", "pickup", "chime", "door_creak", "flea_tick", "flea_bite", "paper", "whoosh",
	"glass_clink", "heart_loss", "heart_gain", "error", "footstep", "knock", "boing",
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
		_cache[sfx_name] = Synth.to_stream(_build(sfx_name))
	return _cache[sfx_name]


static func _build(sfx_name: String) -> PackedFloat32Array:
	match sfx_name:
		"click":
			return Synth.mix(Synth.tone(1800, 0.03, "square", 0.25, 0.0, 3.0), Synth.noise(0.02, 0.2, 0.0, 3.0))
		"thud":
			return Synth.mix(Synth.tone(110, 0.25, "sine", 0.7, 0.002, 3.0, 45), Synth.noise(0.12, 0.3, 0.0, 3.0, 0.9))
		"pickup":
			return Synth.mix(Synth.tone(660, 0.09, "triangle", 0.4, 0.003, 1.5), Synth.tone(990, 0.16, "triangle", 0.4, 0.003, 2.0), 0.07)
		"chime":
			var c := Synth.tone(1320, 0.7, "sine", 0.35, 0.002, 3.0)
			c = Synth.mix(c, Synth.tone(1980, 0.5, "sine", 0.2, 0.002, 3.0), 0.0)
			return Synth.mix(c, Synth.tone(2640, 0.35, "sine", 0.1, 0.002, 3.0), 0.0)
		"door_creak":
			return Synth.mix(Synth.tone(180, 0.9, "saw", 0.18, 0.1, 1.2, 320, 12.0), Synth.noise(0.9, 0.06, 0.2, 1.0, 0.85))
		"flea_tick":
			return Synth.tone(2400, 0.02, "square", 0.18, 0.0, 3.0)
		"flea_bite":
			return Synth.mix(Synth.tone(900, 0.06, "square", 0.25, 0.0, 2.0, 300), Synth.noise(0.04, 0.2, 0.0, 3.0))
		"paper":
			return Synth.noise(0.22, 0.25, 0.02, 1.5, 0.35, 11)
		"whoosh":
			return Synth.noise(0.5, 0.35, 0.18, 1.5, 0.8, 5)
		"glass_clink":
			return Synth.mix(Synth.tone(3100, 0.35, "sine", 0.3, 0.001, 4.0), Synth.tone(4700, 0.25, "sine", 0.15, 0.001, 4.0))
		"heart_loss":
			return Synth.mix(Synth.tone(392, 0.18, "triangle", 0.4, 0.004, 1.5), Synth.tone(294, 0.4, "triangle", 0.4, 0.004, 2.0), 0.14)
		"heart_gain":
			return Synth.mix(Synth.tone(392, 0.15, "triangle", 0.4, 0.004, 1.5), Synth.tone(523, 0.35, "triangle", 0.4, 0.004, 2.0), 0.12)
		"error":
			return Synth.mix(Synth.tone(150, 0.12, "square", 0.25, 0.002, 1.5), Synth.tone(130, 0.18, "square", 0.25, 0.002, 1.5), 0.13)
		"footstep":
			return Synth.mix(Synth.tone(85, 0.1, "sine", 0.5, 0.001, 3.0, 55), Synth.noise(0.06, 0.2, 0.0, 3.0, 0.88, 3))
		"knock":
			var k := Synth.tone(200, 0.08, "sine", 0.6, 0.001, 3.0, 120)
			k = Synth.mix(k, Synth.tone(200, 0.08, "sine", 0.6, 0.001, 3.0, 120), 0.16)
			return Synth.mix(k, Synth.tone(200, 0.1, "sine", 0.6, 0.001, 3.0, 120), 0.32)
		"boing":
			return Synth.tone(180, 0.45, "sine", 0.5, 0.004, 1.5, 420, 25.0)
		_:
			return Synth.tone(440, 0.1)
