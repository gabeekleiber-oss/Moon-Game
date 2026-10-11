class_name VoiceProfiles
extends RefCounted
## Per-character voice-blip settings (the little "animal crossing" sound that plays as dialogue types out). (F-08)
##
## `VoiceProfiles.for_speaker("elsa_ray")` returns {base: Hz, wave: String, vary: semitones of random-ish spread,
## every: play one blip per N letters, vol: 0..1, len: seconds}. Speaker ids are matched by keyword, so "elsa", "elsa_ray"
## and "Elsa Ray" all work. Unknown speakers get a deterministic profile derived from their id, so they still sound distinct.

const PROFILES := {
	"christopher": {"base": 196.0, "wave": "triangle", "vary": 3.0, "every": 2, "vol": 0.30, "len": 0.05},
	"elsa": {"base": 330.0, "wave": "sine", "vary": 4.0, "every": 2, "vol": 0.32, "len": 0.05},
	"mary": {"base": 523.0, "wave": "triangle", "vary": 5.0, "every": 2, "vol": 0.28, "len": 0.04},
	"frank": {"base": 294.0, "wave": "square", "vary": 2.0, "every": 3, "vol": 0.15, "len": 0.05},
	"sweaty": {"base": 130.0, "wave": "saw", "vary": 2.0, "every": 3, "vol": 0.14, "len": 0.07},
	"clement": {"base": 110.0, "wave": "sine", "vary": 1.0, "every": 3, "vol": 0.35, "len": 0.09},
	"edith": {"base": 392.0, "wave": "sine", "vary": 2.0, "every": 2, "vol": 0.30, "len": 0.06},
	"gronfiser": {"base": 165.0, "wave": "saw", "vary": 2.0, "every": 3, "vol": 0.13, "len": 0.08},
	"primo": {"base": 165.0, "wave": "saw", "vary": 2.0, "every": 3, "vol": 0.13, "len": 0.08},
	"errante": {"base": 247.0, "wave": "triangle", "vary": 6.0, "every": 2, "vol": 0.26, "len": 0.06},
	"moon": {"base": 98.0, "wave": "sine", "vary": 1.5, "every": 3, "vol": 0.40, "len": 0.12},
	"crumpis": {"base": 87.0, "wave": "square", "vary": 1.0, "every": 3, "vol": 0.14, "len": 0.08},
	"crumpalump": {"base": 92.0, "wave": "square", "vary": 1.0, "every": 3, "vol": 0.14, "len": 0.08},
	"curt": {"base": 440.0, "wave": "triangle", "vary": 3.0, "every": 2, "vol": 0.26, "len": 0.05},
	"narrator": {"base": 262.0, "wave": "sine", "vary": 1.0, "every": 4, "vol": 0.18, "len": 0.05},
}
## Speaker ids that mean the player character.
const PLAYER_ALIASES: Array[String] = ["self", "you", "player"]
const WAVES: Array[String] = ["sine", "triangle", "square", "saw"]


## The voice profile for a speaker id (see the class doc). Always returns a complete dictionary.
static func for_speaker(who: String) -> Dictionary:
	var id := who.to_lower().replace(" ", "_")
	if PLAYER_ALIASES.has(id):
		return PROFILES["christopher"]
	for key in PROFILES:
		if id.contains(key):
			return PROFILES[key]
	var h := absi(id.hash())
	return {
		"base": 150.0 + float(h % 280),
		"wave": WAVES[(h / 7) % WAVES.size()],
		"vary": 3.0,
		"every": 2,
		"vol": 0.25,
		"len": 0.05,
	}


## Pitch multiplier (for AudioStreamPlayer.pitch_scale) for one typed letter: a stable pseudo-random offset of up to
## +/- `vary` semitones, so the same letter always sounds the same for the same character.
static func pitch_for(profile: Dictionary, ch: String) -> float:
	if ch == "":
		return 1.0
	var code := ch.unicode_at(0)
	var step := float(code % 7) / 3.0 - 1.0   # -1 .. +1
	return pow(2.0, step * float(profile["vary"]) / 12.0)


## True for characters that should be silent (punctuation, digits' neighbours, etc.): only letters and digits blip.
static func is_voiced(ch: String) -> bool:
	if ch == "":
		return false
	var c := ch.unicode_at(0)
	return (c >= 48 and c <= 57) or (c >= 65 and c <= 90) or (c >= 97 and c <= 122) or c > 127
