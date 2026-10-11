class_name MusicScore
extends RefCounted
## The game's music data: one original 16-bar waltz theme ("the Moon Waltz") and how each chapter bends it. (F-09)
##
## Time is counted in EIGHTH notes: a 3/4 bar is 6 steps (`STEPS_PER_BAR`). The melody is a list of [midi_note, length_in_steps]
## pairs per bar (midi_note -1 = rest); each bar must add up to 6. Chords give an oom-pah-pah accompaniment: a low bass note on
## step 0 and the triad on steps 2 and 4. Everything here is original; no real tune or lyric is used.
## `MusicScore.variation_for_chapter(5)` returns the chapter's treatment (tempo, key, instruments, sparseness, ...).

const STEPS_PER_BAR := 6
const BARS := 16

## Chord name -> {bass: low note, triad: three notes above it} (MIDI numbers, A4 = 69).
const CHORDS := {
	"Am": {"bass": 45, "triad": [57, 60, 64]},
	"Dm": {"bass": 50, "triad": [62, 65, 69]},
	"E": {"bass": 40, "triad": [56, 59, 64]},
	"F": {"bass": 41, "triad": [60, 65, 69]},
	"C": {"bass": 48, "triad": [60, 64, 67]},
	"G": {"bass": 43, "triad": [59, 62, 67]},
}

## One chord per bar.
const PROGRESSION: Array[String] = [
	"Am", "Am", "Dm", "E", "Am", "F", "Dm", "Am",
	"C", "F", "C", "G", "Dm", "E", "E", "Am",
]

## The tune: per bar, [midi, steps] pairs.
const MELODY: Array = [
	[[76, 3], [72, 1], [74, 1], [72, 1]],
	[[71, 3], [69, 3]],
	[[74, 3], [77, 1], [76, 1], [74, 1]],
	[[76, 4], [68, 2]],
	[[76, 3], [72, 1], [74, 1], [76, 1]],
	[[81, 3], [79, 3]],
	[[77, 2], [76, 2], [74, 2]],
	[[69, 6]],
	[[72, 2], [76, 2], [79, 2]],
	[[77, 3], [76, 1], [74, 2]],
	[[72, 2], [74, 2], [76, 2]],
	[[71, 3], [67, 3]],
	[[74, 2], [77, 2], [81, 2]],
	[[80, 3], [76, 3]],
	[[74, 1], [72, 1], [71, 1], [72, 1], [74, 1], [71, 1]],
	[[69, 6]],
]

## Treatment applied to the theme. Keys: bpm (quarter notes per minute), transpose (semitones), melody / accomp (instrument
## names from Instruments), accomp_style ("waltz" = oom-pah-pah, "pad" = held chords, "none"), sparse (0..1 chance-free
## deterministic fraction of melody notes dropped), detune (cents of wobble), octave (melody octave shift), vol_db, bars (how
## many of the 16 bars to loop), silent_first (seconds of silence before the music starts).
const DEFAULT_VARIATION := {
	"bpm": 100.0, "transpose": 0, "melody": "music_box", "accomp": "pump_organ", "accomp_style": "waltz",
	"sparse": 0.0, "detune": 0.0, "octave": 0, "vol_db": 0.0, "bars": 16, "silent_first": 0.0,
}

## Named treatments. Chapters map to these in CHAPTER_VARIATION.
const VARIATIONS := {
	"tv_waltz": {"bpm": 112.0, "transpose": 3, "melody": "pump_organ", "accomp": "pump_organ", "vol_db": -4.0},
	"nervous": {"bpm": 132.0, "melody": "music_box", "accomp": "music_box", "sparse": 0.2, "vol_db": -4.0},
	"night_drive": {"bpm": 76.0, "transpose": -2, "melody": "music_box", "accomp_style": "pad", "accomp": "bell_pad", "sparse": 0.3, "vol_db": -5.0},
	"clearing": {"bpm": 84.0, "melody": "music_box", "accomp": "pump_organ", "accomp_style": "pad", "vol_db": -4.0},
	"moon": {"bpm": 54.0, "transpose": -5, "melody": "bell_pad", "accomp": "bell_pad", "accomp_style": "pad", "sparse": 0.6, "vol_db": -6.0, "bars": 8},
	"dark_rooms": {"bpm": 92.0, "transpose": 1, "melody": "music_box", "accomp": "pump_organ", "sparse": 0.45, "detune": 35.0, "vol_db": -6.0},
	"candles": {"bpm": 96.0, "transpose": 0, "melody": "music_box", "accomp": "music_box", "vol_db": -3.0},
	"lake": {"bpm": 60.0, "transpose": -7, "melody": "music_box", "accomp_style": "none", "sparse": 0.5, "vol_db": -7.0, "bars": 8, "silent_first": 60.0},
	"morning": {"bpm": 108.0, "transpose": 3, "melody": "music_box", "accomp": "pump_organ", "vol_db": -4.0},
	"inventory": {"bpm": 120.0, "transpose": 0, "melody": "flute", "accomp": "pump_organ", "detune": 12.0, "vol_db": -4.0},
	"melting": {"bpm": 138.0, "transpose": -1, "melody": "flute", "accomp": "pump_organ", "detune": 28.0, "octave": 0, "vol_db": -2.0},
	"title": {"bpm": 72.0, "transpose": 0, "melody": "music_box", "accomp": "bell_pad", "accomp_style": "pad", "vol_db": -3.0},
}

## Chapter id (1-11) -> variation name. 0 is the title screen.
const CHAPTER_VARIATION := {
	0: "title", 1: "tv_waltz", 2: "nervous", 3: "night_drive", 4: "clearing", 5: "moon", 6: "dark_rooms",
	7: "candles", 8: "lake", 9: "morning", 10: "inventory", 11: "melting",
}


## The treatment for a named variation, merged over DEFAULT_VARIATION. Unknown names return the default (with a warning).
static func variation(variation_name: String) -> Dictionary:
	var out := DEFAULT_VARIATION.duplicate()
	if VARIATIONS.has(variation_name):
		out.merge(VARIATIONS[variation_name], true)
	else:
		push_warning("MusicScore: unknown variation '%s'" % variation_name)
	return out


## The treatment for a chapter id (0 = title screen). Unknown ids return the default treatment.
static func variation_for_chapter(chapter_id: int) -> Dictionary:
	return variation(CHAPTER_VARIATION.get(chapter_id, ""))


## Total steps in one loop of the theme for a variation (bars * 6).
static func loop_steps(v: Dictionary) -> int:
	return clampi(int(v["bars"]), 1, BARS) * STEPS_PER_BAR


## Seconds per eighth-note step at the variation's tempo.
static func step_seconds(v: Dictionary) -> float:
	return 30.0 / maxf(float(v["bpm"]), 20.0)
