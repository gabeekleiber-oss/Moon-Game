class_name EnvPresets
extends RefCounted
## The Environment preset library (S-01): five looks (night_dark, dawn, dream, day, fire), each a flat Dictionary whose keys are
## `Environment` property names, so a preset can be applied with `env.set(key, value)`, eased with `lerp_params`, degraded by the
## quality ladder (`for_quality`) and bent by the hidden Unreality value (`with_unreality`). Everything here is a PURE function, so it
## is unit-testable headless (the headless renderer cannot draw SSAO/volumetric fog; see docs/ART_BIBLE.md 10).
##
## Rules this file encodes (docs/ART_BIBLE.md 4 and docs/LIGHTING.md):
##  * Real darkness: night looks keep ambient energy tiny. Do not "fill" the dark; add a motivated light instead.
##  * Colour temperature carries mood; the PostFX base grade (UnrealGrade) only ties the frame together on top of it.
##  * SSAO and glow are on in every look; volumetric fog (light shafts) is on where there is a shaft to show.
##  * Unreality thickens the air and drifts it sick; it never brightens a dark scene.
##
## Typical use (the MoodEnvironment node does this for you):
##     var env := EnvPresets.build("night_dark")                       # a ready Environment
##     var p := EnvPresets.with_unreality(EnvPresets.for_quality(EnvPresets.get_preset("fire"), "medium"), Unreality.level)
##     EnvPresets.apply(env, p)

## Quality names, best to cheapest (docs/LIGHTING.md "quality ladder"; Game.settings quality is "auto"/"low" today).
const QUALITIES: Array[String] = ["high", "medium", "low"]

## Keys that are not plain Environment properties and are handled by `apply`.
const SPECIAL_KEYS: Array[String] = ["use_sky", "sky_top", "sky_horizon", "ground_horizon", "ground_bottom", "sky_energy", "glow_levels"]

## Properties shared by every look; each preset overrides what it needs. (Keys are Environment property names.)
const BASE := {
	"background_mode": Environment.BG_COLOR,
	"background_color": Color(0.005, 0.005, 0.01),
	"background_energy_multiplier": 1.0,
	"ambient_light_source": Environment.AMBIENT_SOURCE_COLOR,
	"ambient_light_color": Color(0.05, 0.05, 0.08),
	"ambient_light_energy": 0.04,
	"reflected_light_source": Environment.REFLECTION_SOURCE_BG,
	"tonemap_mode": Environment.TONE_MAPPER_FILMIC,
	"tonemap_exposure": 1.0,
	"tonemap_white": 6.0,
	"ssao_enabled": true,
	"ssao_radius": 1.2,
	"ssao_intensity": 2.2,
	"ssao_power": 1.6,
	"ssao_detail": 0.5,
	"ssao_horizon": 0.06,
	"ssao_sharpness": 0.98,
	"ssao_light_affect": 0.15,
	"ssao_ao_channel_affect": 0.0,
	"ssil_enabled": false,
	"glow_enabled": true,
	"glow_intensity": 0.6,
	"glow_strength": 1.0,
	"glow_bloom": 0.03,
	"glow_blend_mode": Environment.GLOW_BLEND_MODE_SOFTLIGHT,
	"glow_hdr_threshold": 1.0,
	"glow_levels": [0.0, 0.0, 1.0, 0.0, 1.0, 0.0, 0.0],
	"fog_enabled": true,
	"fog_light_color": Color(0.04, 0.05, 0.08),
	"fog_light_energy": 1.0,
	"fog_density": 0.01,
	"fog_sky_affect": 0.5,
	"fog_aerial_perspective": 0.0,
	"volumetric_fog_enabled": false,
	"volumetric_fog_density": 0.01,
	"volumetric_fog_albedo": Color(0.85, 0.88, 1.0),
	"volumetric_fog_emission": Color(0, 0, 0),
	"volumetric_fog_emission_energy": 0.0,
	"volumetric_fog_anisotropy": 0.6,
	"volumetric_fog_length": 40.0,
	"volumetric_fog_detail_spread": 2.0,
	"volumetric_fog_gi_inject": 0.0,
	"volumetric_fog_ambient_inject": 0.0,
	"volumetric_fog_sky_affect": 0.5,
	"adjustment_enabled": true,
	"adjustment_brightness": 1.0,
	"adjustment_contrast": 1.0,
	"adjustment_saturation": 1.0,
	"use_sky": false,
	"sky_top": Color(0.3, 0.4, 0.7),
	"sky_horizon": Color(0.7, 0.75, 0.85),
	"ground_horizon": Color(0.3, 0.28, 0.25),
	"ground_bottom": Color(0.05, 0.05, 0.05),
	"sky_energy": 1.0,
}

## The five looks: only the differences from BASE.
const LOOKS := {
	# Interiors at night (Acts 1, 2, 4): genuinely dark, cold air that only light shafts reveal.
	"night_dark": {
		"background_color": Color(0.004, 0.005, 0.010),
		"ambient_light_color": Color(0.030, 0.040, 0.075), "ambient_light_energy": 0.03,
		"tonemap_exposure": 1.05, "ssao_intensity": 2.6,
		"glow_intensity": 0.8, "glow_bloom": 0.04, "glow_hdr_threshold": 0.9,
		"fog_light_color": Color(0.030, 0.040, 0.070), "fog_density": 0.012,
		"volumetric_fog_enabled": true, "volumetric_fog_density": 0.012, "volumetric_fog_albedo": Color(0.72, 0.78, 0.95),
		"adjustment_saturation": 0.92,
	},
	# Hot dawn over the clearing (Acts 3, 9 exterior): peach horizon, long gold shafts, black forest.
	"dawn": {
		"background_mode": Environment.BG_SKY, "use_sky": true,
		"sky_top": Color(0.30, 0.38, 0.58), "sky_horizon": Color(1.0, 0.64, 0.46), "ground_horizon": Color(0.55, 0.38, 0.28),
		"ground_bottom": Color(0.06, 0.05, 0.05), "sky_energy": 0.9,
		"ambient_light_source": Environment.AMBIENT_SOURCE_SKY, "ambient_light_energy": 0.55,
		"reflected_light_source": Environment.REFLECTION_SOURCE_SKY,
		"tonemap_mode": Environment.TONE_MAPPER_ACES, "tonemap_exposure": 1.0, "ssao_intensity": 1.8,
		"glow_intensity": 0.7, "glow_bloom": 0.06, "glow_hdr_threshold": 0.85,
		"fog_light_color": Color(0.95, 0.68, 0.52), "fog_density": 0.006, "fog_sky_affect": 0.3, "fog_aerial_perspective": 0.5,
		"volumetric_fog_enabled": true, "volumetric_fog_density": 0.018, "volumetric_fog_albedo": Color(1.0, 0.82, 0.68),
		"volumetric_fog_anisotropy": 0.75, "volumetric_fog_length": 80.0, "volumetric_fog_ambient_inject": 0.15,
		"adjustment_saturation": 0.95,
	},
	# Act 5 and 6 dream spaces: ruby-maroon, milky and close; the one place realism softens.
	"dream": {
		"background_color": Color(0.09, 0.02, 0.05),
		"ambient_light_color": Color(0.30, 0.10, 0.17), "ambient_light_energy": 0.22,
		"tonemap_exposure": 0.95, "ssao_intensity": 1.6, "ssao_radius": 1.8,
		"glow_intensity": 1.0, "glow_bloom": 0.14, "glow_hdr_threshold": 0.75,
		"fog_light_color": Color(0.30, 0.08, 0.17), "fog_density": 0.028,
		"volumetric_fog_enabled": true, "volumetric_fog_density": 0.03, "volumetric_fog_albedo": Color(0.95, 0.70, 0.78),
		"volumetric_fog_anisotropy": 0.35, "volumetric_fog_ambient_inject": 0.25, "volumetric_fog_length": 30.0,
		"adjustment_saturation": 1.05,
	},
	# Acts 7 and 8: honey sunlight through big south windows; cheerful, clean, quietly false.
	"day": {
		"background_mode": Environment.BG_SKY, "use_sky": true,
		"sky_top": Color(0.36, 0.52, 0.82), "sky_horizon": Color(0.86, 0.88, 0.90), "ground_horizon": Color(0.62, 0.58, 0.50),
		"ground_bottom": Color(0.20, 0.18, 0.15), "sky_energy": 1.1,
		"ambient_light_source": Environment.AMBIENT_SOURCE_SKY, "ambient_light_energy": 0.8,
		"reflected_light_source": Environment.REFLECTION_SOURCE_SKY,
		"tonemap_mode": Environment.TONE_MAPPER_ACES, "tonemap_exposure": 1.05, "ssao_intensity": 1.5, "ssao_radius": 1.0,
		"glow_intensity": 0.45, "glow_bloom": 0.02, "glow_hdr_threshold": 1.1,
		"fog_light_color": Color(0.92, 0.86, 0.72), "fog_density": 0.002, "fog_sky_affect": 0.2,
		"volumetric_fog_enabled": true, "volumetric_fog_density": 0.006, "volumetric_fog_albedo": Color(1.0, 0.94, 0.80),
		"volumetric_fog_anisotropy": 0.8, "volumetric_fog_length": 40.0, "volumetric_fog_ambient_inject": 0.1,
		"adjustment_saturation": 1.0,
	},
	# Act 9 night: the fire is the only light; everything is the fire, the sky is gone.
	"fire": {
		"background_color": Color(0.010, 0.005, 0.003),
		"ambient_light_color": Color(0.15, 0.07, 0.03), "ambient_light_energy": 0.06,
		"tonemap_exposure": 1.0, "ssao_intensity": 2.4,
		"glow_intensity": 1.1, "glow_bloom": 0.12, "glow_hdr_threshold": 0.8,
		"fog_light_color": Color(0.30, 0.12, 0.05), "fog_density": 0.02,
		"volumetric_fog_enabled": true, "volumetric_fog_density": 0.02, "volumetric_fog_albedo": Color(0.9, 0.6, 0.4),
		"volumetric_fog_emission": Color(0.45, 0.16, 0.04), "volumetric_fog_emission_energy": 0.25,
		"volumetric_fog_anisotropy": 0.55, "volumetric_fog_length": 35.0,
		"adjustment_saturation": 1.05,
	},
}

## Which look each location mood (UnrealGrade base grade name) uses. Acts set the grade; MoodEnvironment follows it.
const GRADE_TO_LOOK := {
	"neutral": "night_dark",
	"flat_tired": "night_dark",
	"road_black": "night_dark",
	"dawn_dome": "dawn",
	"pitch_dark": "night_dark",
	"maroon_dream": "dream",
	"lake_dusk": "dream",
	"false_morning": "day",
	"gold_stillness": "day",
	"fire_night": "fire",
}


## Names of the five looks, in a stable order.
static func names() -> Array[String]:
	return ["night_dark", "dawn", "dream", "day", "fire"]


## A complete parameter Dictionary (BASE + the look's overrides). Unknown names fall back to night_dark.
static func get_preset(look: String) -> Dictionary:
	var p: Dictionary = BASE.duplicate(true)
	var over: Dictionary = LOOKS.get(look, LOOKS["night_dark"])
	for k in over:
		p[k] = over[k]
	return p


## The look to use for a UnrealGrade base-grade name (what an act's `base_grade` export holds).
static func for_grade(grade_name: String) -> String:
	return String(GRADE_TO_LOOK.get(grade_name, "night_dark"))


## Quality ladder: drops the expensive passes first (volumetric fog, then SSAO, then glow). `quality` is "high", "medium", "low";
## "auto" (the Game.settings default) is treated as "high".
static func for_quality(params: Dictionary, quality: String) -> Dictionary:
	var p: Dictionary = params.duplicate(true)
	match quality:
		"medium":
			p["volumetric_fog_length"] = minf(float(p["volumetric_fog_length"]), 30.0)
			p["ssao_detail"] = 0.0
			p["ssao_radius"] = float(p["ssao_radius"]) * 0.8
		"low":
			p["volumetric_fog_enabled"] = false
			p["ssao_enabled"] = false
			p["glow_intensity"] = float(p["glow_intensity"]) * 0.6
	return p


## Layers the hidden Unreality value onto a parameter set (docs/ART_BIBLE.md 1, "Light" and "Screen" rows): the air thickens, the fog
## drifts sick, the glow swells and the day gets dimmer, never brighter. `level` is 0..1; `motion` is Unreality.motion_scale()
## (the sick cast is colour so it ignores it; nothing here moves, so `motion` is only reserved for future effects).
static func with_unreality(params: Dictionary, level: float, _motion: float = 1.0) -> Dictionary:
	var p: Dictionary = params.duplicate(true)
	var k_off := _smooth(0.15, 0.55, level)
	var k_ruin := _smooth(0.55, 1.0, level)
	var sick := Color(0.46, 0.60, 0.30)
	p["fog_density"] = float(p["fog_density"]) * (1.0 + 1.4 * k_off + 2.0 * k_ruin)
	p["volumetric_fog_density"] = float(p["volumetric_fog_density"]) * (1.0 + 1.0 * k_off + 2.5 * k_ruin)
	p["fog_light_color"] = (p["fog_light_color"] as Color).lerp(sick * 0.4, 0.22 * k_off)
	p["volumetric_fog_albedo"] = (p["volumetric_fog_albedo"] as Color).lerp(sick, 0.20 * k_off)
	p["glow_intensity"] = float(p["glow_intensity"]) * (1.0 + 0.35 * k_off + 0.5 * k_ruin)
	p["tonemap_exposure"] = float(p["tonemap_exposure"]) * (1.0 - 0.08 * k_off)
	p["adjustment_saturation"] = float(p["adjustment_saturation"]) * lerpf(1.0, 0.88, k_off) * lerpf(1.0, 1.25, k_ruin)
	return p


## Linear blend of two parameter sets (t 0..1). Floats and Colors blend; enums/bools/arrays switch at t >= 0.5.
## (Switching an enum such as background_mode pops; do it under a fade, as acts do via Acts.transition_to.)
static func lerp_params(a: Dictionary, b: Dictionary, t: float) -> Dictionary:
	var out: Dictionary = {}
	for k in a:
		var va: Variant = a[k]
		var vb: Variant = b.get(k, va)
		if va is float and vb is float:
			out[k] = lerpf(va, vb, t)
		elif va is Color and vb is Color:
			out[k] = (va as Color).lerp(vb, t)
		elif va is Array and vb is Array and va.size() == vb.size():
			var arr: Array = []
			for i in va.size():
				arr.append(lerpf(float(va[i]), float(vb[i]), t))
			out[k] = arr
		else:
			out[k] = vb if t >= 0.5 else va
	return out


## Writes `params` onto `env` (keys are Environment properties; SPECIAL_KEYS are handled here).
static func apply(env: Environment, params: Dictionary) -> void:
	for k in params:
		var key := String(k)
		if key in SPECIAL_KEYS:
			continue
		env.set(key, params[k])
	var levels: Array = params.get("glow_levels", [])
	for i in mini(levels.size(), 7):
		env.set_glow_level(i, float(levels[i]))
	if bool(params.get("use_sky", false)):
		var sky: Sky = env.sky
		if sky == null:
			sky = Sky.new()
			env.sky = sky
		var mat: ProceduralSkyMaterial = sky.sky_material as ProceduralSkyMaterial
		if mat == null:
			mat = ProceduralSkyMaterial.new()
			sky.sky_material = mat
		mat.sky_top_color = params["sky_top"]
		mat.sky_horizon_color = params["sky_horizon"]
		mat.ground_horizon_color = params["ground_horizon"]
		mat.ground_bottom_color = params["ground_bottom"]
		mat.sky_energy_multiplier = float(params["sky_energy"])


## A ready Environment for a look (optionally at a quality level).
static func build(look: String, quality: String = "high") -> Environment:
	var env := Environment.new()
	apply(env, for_quality(get_preset(look), quality))
	return env


static func _smooth(a: float, b: float, x: float) -> float:
	var t := clampf((x - a) / (b - a), 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)
