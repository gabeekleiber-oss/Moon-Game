class_name UnrealGrade
extends RefCounted
## Colour/lens look = LOCATION MOOD (a named base grade) + UNREALITY (continuous offsets keyed on the hidden level 0..1).
## Pure functions (testable). PostFX calls `compose(base, level, motion)` every frame and pushes the result as shader uniforms.
## Tuning rules live in docs/ART_BIBLE.md ("The unreality curve"): ordinary -> off -> wrong -> fraying -> unmoored -> ruin.
## Base grades are deliberately gentle: the real mood comes from lights and fog; this just ties the frame together.
## Keys are uniform names in scenes/fx/post_fx.gdshader. Anything a grade omits falls back to NEUTRAL.

const NEUTRAL := {
	"tint": Color(1, 1, 1), "tint_amount": 0.0,
	"shadow_tint": Color(0.5, 0.5, 0.5), "highlight_tint": Color(0.5, 0.5, 0.5), "split_amount": 0.0,
	"saturation": 1.0, "contrast": 1.0, "exposure": 0.0,
	"vignette_strength": 0.3, "vignette_radius": 0.78, "vignette_color": Color(0.02, 0.01, 0.04),
	"bloom_amount": 0.12, "bloom_threshold": 0.72,
	"grain_amount": 0.035,
}

## Named location moods (one per act, plus neutral). Acts set theirs via ActBase.base_grade.
const BASE := {
	"neutral": {},
	# Act 1: a tired 1990s Wisconsin living room: flat light, cold shadows, the TV's blue.
	"flat_tired": {"tint": Color(0.86, 0.93, 1.0), "tint_amount": 0.22, "shadow_tint": Color(0.40, 0.46, 0.60),
		"highlight_tint": Color(0.62, 0.56, 0.46), "split_amount": 0.30, "saturation": 0.82, "contrast": 1.05,
		"exposure": -0.12, "vignette_strength": 0.34},
	# Act 2: night road, headlights only.
	"road_black": {"tint": Color(0.85, 0.90, 1.0), "tint_amount": 0.20, "saturation": 0.60, "contrast": 1.20,
		"exposure": -0.35, "vignette_strength": 0.58, "vignette_radius": 0.62, "bloom_amount": 0.30,
		"bloom_threshold": 0.60, "grain_amount": 0.05},
	# Act 3: hot dawn, the dome, silver-milk moon.
	"dawn_dome": {"tint": Color(0.90, 0.95, 1.0), "tint_amount": 0.22, "shadow_tint": Color(0.35, 0.40, 0.60),
		"highlight_tint": Color(0.62, 0.60, 0.60), "split_amount": 0.35, "saturation": 0.68, "contrast": 1.05,
		"exposure": 0.05, "bloom_amount": 0.20},
	# Act 4: the house at night, almost nothing to see.
	"pitch_dark": {"tint": Color(0.92, 1.0, 0.85), "tint_amount": 0.18, "shadow_tint": Color(0.34, 0.40, 0.34),
		"highlight_tint": Color(0.65, 0.58, 0.40), "split_amount": 0.30, "saturation": 0.55, "contrast": 1.15,
		"exposure": -0.45, "vignette_strength": 0.60, "grain_amount": 0.05},
	# Act 5: ruby-maroon dream hall and the Wisconsin kitchen that should not be here.
	"maroon_dream": {"tint": Color(1.0, 0.78, 0.78), "tint_amount": 0.30, "shadow_tint": Color(0.52, 0.30, 0.38),
		"highlight_tint": Color(0.72, 0.52, 0.45), "split_amount": 0.38, "contrast": 1.10, "exposure": -0.10,
		"vignette_strength": 0.45},
	# Act 6: violet dusk, glassy teal, a sky and a lake that never meet.
	"lake_dusk": {"tint": Color(0.88, 0.86, 1.0), "tint_amount": 0.25, "shadow_tint": Color(0.44, 0.36, 0.62),
		"highlight_tint": Color(0.42, 0.62, 0.64), "split_amount": 0.42, "saturation": 0.90, "exposure": -0.12,
		"bloom_amount": 0.18},
	# Act 7: cheerful honey sunlight; too bright, too clean, quietly false.
	"false_morning": {"tint": Color(1.0, 0.94, 0.80), "tint_amount": 0.28, "highlight_tint": Color(0.70, 0.60, 0.42),
		"shadow_tint": Color(0.48, 0.46, 0.50), "split_amount": 0.22, "saturation": 1.0, "exposure": 0.18,
		"bloom_amount": 0.24, "bloom_threshold": 0.62, "vignette_strength": 0.20},
	# Act 8: gold, black and red; the stillness of owning too much.
	"gold_stillness": {"tint": Color(1.0, 0.86, 0.58), "tint_amount": 0.25, "shadow_tint": Color(0.46, 0.30, 0.30),
		"highlight_tint": Color(0.72, 0.56, 0.30), "split_amount": 0.35, "saturation": 1.08, "contrast": 1.18,
		"vignette_strength": 0.42, "bloom_amount": 0.24},
	# Act 9: the fire: orange, whiskey amber, black trees.
	"fire_night": {"tint": Color(1.0, 0.72, 0.42), "tint_amount": 0.35, "shadow_tint": Color(0.38, 0.32, 0.36),
		"highlight_tint": Color(0.72, 0.52, 0.30), "split_amount": 0.30, "saturation": 1.05, "contrast": 1.15,
		"exposure": -0.10, "vignette_strength": 0.50, "bloom_amount": 0.22},
}

## Level keyframes shared by every curve below (the band edges plus the ends).
const KEYS: Array[float] = [0.0, 0.15, 0.35, 0.55, 0.75, 1.0]

## Unreality curves: one value per KEYS entry, linearly interpolated.
const CURVES := {
	"sat_mul":       [1.00, 0.97, 0.88, 0.75, 0.88, 1.30],   # colour drains, then over-saturates in ruin
	"contrast_add":  [0.00, 0.02, 0.06, 0.10, 0.14, 0.22],
	"exposure_add":  [0.00, -0.02, -0.05, -0.08, -0.04, 0.06],
	"vignette_add":  [0.00, 0.04, 0.10, 0.18, 0.28, 0.38],   # the world closes in
	"hue_shift":     [0.00, 0.00, 0.05, 0.12, 0.22, 0.40],   # radians; colours slide off true
	"chroma_mult":   [1.00, 1.20, 1.80, 2.80, 4.00, 6.00],
	"grain_mult":    [1.00, 1.10, 1.40, 1.80, 2.30, 3.00],
	"warp":          [0.00, 0.00, 0.010, 0.025, 0.045, 0.080], # barrel lens
	"wobble":        [0.00, 0.00, 0.000, 0.004, 0.010, 0.020], # slow liquid sway (MOTION: scaled by motion_scale)
	"ghost":         [0.00, 0.00, 0.000, 0.150, 0.350, 0.600], # double vision
	"specks":        [0.00, 0.00, 0.000, 0.100, 0.350, 0.800], # the fleas: dark specks crawling at the edges (MOTION)
	"sick":          [0.00, 0.00, 0.030, 0.070, 0.130, 0.220], # a faint bilious cast
}


## Piecewise-linear lookup of a CURVES entry at `level` (0..1).
static func curve(curve_name: String, level: float) -> float:
	var arr: Array = CURVES[curve_name]
	var l := clampf(level, 0.0, 1.0)
	for i in KEYS.size() - 1:
		if l <= KEYS[i + 1]:
			var t := (l - KEYS[i]) / (KEYS[i + 1] - KEYS[i])
			return lerpf(float(arr[i]), float(arr[i + 1]), t)
	return float(arr[arr.size() - 1])


## Full base grade (NEUTRAL + named overrides). Unknown names warn and return NEUTRAL.
static func get_base(grade_name: String) -> Dictionary:
	var out := NEUTRAL.duplicate()
	if not BASE.has(grade_name):
		push_warning("UnrealGrade: unknown base grade '%s'" % grade_name)
		return out
	out.merge(BASE[grade_name], true)
	return out


static func names() -> Array:
	return BASE.keys()


## Base grade + unreality at `level` -> the full uniform dictionary for the shader. `motion` (0 or 1) scales the moving effects.
static func compose(base: Dictionary, level: float, motion: float = 1.0) -> Dictionary:
	var out := NEUTRAL.duplicate()
	out.merge(base, true)
	out["saturation"] = float(out["saturation"]) * curve("sat_mul", level)
	out["contrast"] = clampf(float(out["contrast"]) + curve("contrast_add", level), 0.5, 1.5)
	out["exposure"] = clampf(float(out["exposure"]) + curve("exposure_add", level), -1.0, 1.0)
	out["vignette_strength"] = clampf(float(out["vignette_strength"]) + curve("vignette_add", level), 0.0, 1.0)
	out["grain_amount"] = clampf(float(out["grain_amount"]) * curve("grain_mult", level), 0.0, 0.2)
	out["hue_shift"] = curve("hue_shift", level)
	out["chroma_mult"] = curve("chroma_mult", level)
	out["warp"] = curve("warp", level)
	out["wobble"] = curve("wobble", level) * motion
	out["ghost"] = curve("ghost", level)
	out["specks"] = curve("specks", level) * motion
	out["sick"] = curve("sick", level)
	out["unreal"] = clampf(level, 0.0, 1.0)
	return out
