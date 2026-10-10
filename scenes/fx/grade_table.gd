class_name GradeTable
extends RefCounted
## Per-chapter colour grades for the PostFX pass. (F-04)
##
## Palettes come from docs/DESIGN.md. Grades are deliberately gentle ("grade via light + fog tint, never a
## flat filter"): tints are partial, split-toning pushes shadows/highlights only a little. Chapter lights and
## fog still do the heavy lifting; this just ties the frame together.
## Keys are shader uniform names (scenes/fx/post_fx.gdshader). Anything a grade omits falls back to NEUTRAL.
## Usage: `GradeTable.for_chapter(5)` or `GradeTable.get_grade("ch07_kitchen")` -> full Dictionary.

const NEUTRAL := {
	"tint": Color(1, 1, 1), "tint_amount": 0.0,
	"shadow_tint": Color(0.5, 0.5, 0.5), "highlight_tint": Color(0.5, 0.5, 0.5), "split_amount": 0.0,
	"saturation": 1.0, "contrast": 1.0, "exposure": 0.0,
	"vignette_strength": 0.3, "vignette_radius": 0.78, "vignette_color": Color(0.02, 0.01, 0.04),
	"bloom_amount": 0.12, "bloom_threshold": 0.72,
	"grain_amount": 0.035,
}

## Chapter id -> default grade name. Chapters with sub-areas (e.g. 7) expose extra named grades below.
const CHAPTER_GRADE := {
	1: "ch01", 2: "ch02", 3: "ch03", 4: "ch04", 5: "ch05", 6: "ch06",
	7: "ch07_hall", 8: "ch08", 9: "ch09", 10: "ch10", 11: "ch11",
}

const GRADES := {
	"neutral": {},
	# Ch1 cold blue night + warm lamp amber
	"ch01": {"tint": Color(0.80, 0.90, 1.0), "tint_amount": 0.30, "shadow_tint": Color(0.40, 0.48, 0.64),
		"highlight_tint": Color(0.64, 0.55, 0.42), "split_amount": 0.35, "saturation": 0.95, "contrast": 1.08,
		"exposure": -0.15, "vignette_strength": 0.40},
	# Ch2 (not in DESIGN.md palettes; ASSUMED ember-orange night for "Burning Bridges")
	"ch02": {"tint": Color(1.0, 0.82, 0.66), "tint_amount": 0.30, "shadow_tint": Color(0.40, 0.38, 0.52),
		"highlight_tint": Color(0.66, 0.50, 0.34), "split_amount": 0.30, "saturation": 1.05, "contrast": 1.10,
		"exposure": -0.10, "vignette_strength": 0.42, "bloom_amount": 0.20},
	# Ch3 inky black, white headlights, racoon eyeshine
	"ch03": {"tint": Color(0.85, 0.90, 1.0), "tint_amount": 0.20, "saturation": 0.70, "contrast": 1.20,
		"exposure": -0.30, "vignette_strength": 0.55, "vignette_radius": 0.65, "bloom_amount": 0.30,
		"bloom_threshold": 0.60, "grain_amount": 0.05},
	# Ch4 dawn peach / rose / dusty gold
	"ch04": {"tint": Color(1.0, 0.88, 0.82), "tint_amount": 0.30, "shadow_tint": Color(0.50, 0.42, 0.52),
		"highlight_tint": Color(0.68, 0.55, 0.45), "split_amount": 0.30, "saturation": 1.05, "exposure": 0.05,
		"bloom_amount": 0.16},
	# Ch5 silver-milk + ink blue (the dome)
	"ch05": {"tint": Color(0.90, 0.95, 1.0), "tint_amount": 0.25, "shadow_tint": Color(0.35, 0.40, 0.60),
		"highlight_tint": Color(0.60, 0.60, 0.62), "split_amount": 0.35, "saturation": 0.70, "contrast": 1.05,
		"exposure": 0.10, "bloom_amount": 0.20},
	# Ch6 dark -> green-gold, dirt-brown, warm nests
	"ch06": {"tint": Color(0.95, 1.0, 0.80), "tint_amount": 0.30, "shadow_tint": Color(0.40, 0.44, 0.34),
		"highlight_tint": Color(0.65, 0.58, 0.40), "split_amount": 0.30, "saturation": 0.90, "exposure": -0.25,
		"vignette_strength": 0.50},
	# Ch7 hall ruby-maroon
	"ch07_hall": {"tint": Color(1.0, 0.78, 0.78), "tint_amount": 0.30, "shadow_tint": Color(0.52, 0.34, 0.40),
		"highlight_tint": Color(0.70, 0.52, 0.45), "split_amount": 0.35, "contrast": 1.10, "exposure": -0.10,
		"vignette_strength": 0.45},
	# Ch7 kitchen: 90s yellow-beige + tacky marble
	"ch07_kitchen": {"tint": Color(1.0, 0.96, 0.78), "tint_amount": 0.30, "shadow_tint": Color(0.50, 0.48, 0.40),
		"highlight_tint": Color(0.66, 0.60, 0.44), "split_amount": 0.25, "saturation": 0.95, "exposure": 0.05,
		"vignette_strength": 0.25},
	# Ch8 violet dusk + glassy teal
	"ch08": {"tint": Color(0.90, 0.88, 1.0), "tint_amount": 0.25, "shadow_tint": Color(0.46, 0.38, 0.62),
		"highlight_tint": Color(0.44, 0.60, 0.62), "split_amount": 0.40, "exposure": -0.10, "bloom_amount": 0.18},
	# Ch9 honey sunlight, cream
	"ch09": {"tint": Color(1.0, 0.93, 0.78), "tint_amount": 0.30, "highlight_tint": Color(0.68, 0.58, 0.40),
		"shadow_tint": Color(0.48, 0.46, 0.50), "split_amount": 0.25, "saturation": 1.05, "exposure": 0.15,
		"bloom_amount": 0.22, "bloom_threshold": 0.65, "vignette_strength": 0.22},
	# Ch10 gold, black, red
	"ch10": {"tint": Color(1.0, 0.85, 0.55), "tint_amount": 0.25, "shadow_tint": Color(0.46, 0.30, 0.30),
		"highlight_tint": Color(0.70, 0.55, 0.30), "split_amount": 0.35, "saturation": 1.15, "contrast": 1.20,
		"vignette_strength": 0.45, "bloom_amount": 0.25},
	# Ch11 orange, whiskey amber, black trees
	"ch11": {"tint": Color(1.0, 0.72, 0.42), "tint_amount": 0.35, "shadow_tint": Color(0.38, 0.32, 0.36),
		"highlight_tint": Color(0.70, 0.52, 0.30), "split_amount": 0.30, "saturation": 1.05, "contrast": 1.15,
		"exposure": -0.10, "vignette_strength": 0.50, "bloom_amount": 0.20},
}


## Full grade (NEUTRAL + overrides) for a grade name. Unknown names return NEUTRAL with a warning.
static func get_grade(grade_name: String) -> Dictionary:
	var out := NEUTRAL.duplicate()
	if not GRADES.has(grade_name):
		push_warning("GradeTable: unknown grade '%s'" % grade_name)
		return out
	out.merge(GRADES[grade_name], true)
	return out


## Default grade for chapter `id` (1-11). Unknown ids return NEUTRAL.
static func for_chapter(id: int) -> Dictionary:
	return get_grade(CHAPTER_GRADE.get(id, "neutral"))


## All grade names (for debug menus).
static func names() -> Array:
	return GRADES.keys()
