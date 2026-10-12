extends RefCounted
## Shared, data-light lighting baseline for the game's restrained realistic spaces.
## Use make_environment() on a WorldEnvironment and the practical_* helpers for visible
## light sources. Keep no more than two shadow-casting dynamic lights in a view; bake
## the rest or disable their shadows. Visual results remain renderer/device dependent.

const PRESETS: Array[String] = ["night_dark", "dawn", "dream", "day", "fire"]

## Builds a WorldEnvironment resource for one of the named location moods.
## All presets enable SSAO and restrained glow; volumetric fog is available for shafts.
static func make_environment(preset: String) -> Environment:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.012, 0.014, 0.022)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.11, 0.12, 0.15)
	env.ambient_light_energy = 0.18
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.ssao_enabled = true
	env.ssao_radius = 1.2
	env.ssao_intensity = 1.1
	env.glow_enabled = true
	env.glow_intensity = 0.25
	env.glow_bloom = 0.04
	env.fog_enabled = false
	env.volumetric_fog_enabled = false
	match preset:
		"night_dark":
			env.background_color = Color(0.006, 0.008, 0.014)
			env.ambient_light_color = Color(0.10, 0.12, 0.18)
			env.ambient_light_energy = 0.10
			env.glow_intensity = 0.18
			env.volumetric_fog_enabled = true
			env.volumetric_fog_density = 0.012
			env.volumetric_fog_albedo = Color(0.20, 0.23, 0.30)
		"dawn":
			env.background_color = Color(0.30, 0.19, 0.18)
			env.ambient_light_color = Color(0.62, 0.39, 0.32)
			env.ambient_light_energy = 0.32
			env.glow_intensity = 0.28
			env.volumetric_fog_enabled = true
			env.volumetric_fog_density = 0.006
			env.volumetric_fog_albedo = Color(0.72, 0.48, 0.38)
		"dream":
			env.background_color = Color(0.16, 0.18, 0.28)
			env.ambient_light_color = Color(0.55, 0.58, 0.72)
			env.ambient_light_energy = 0.42
			env.glow_intensity = 0.34
			env.volumetric_fog_enabled = true
			env.volumetric_fog_density = 0.009
			env.volumetric_fog_albedo = Color(0.54, 0.60, 0.78)
		"day":
			env.background_color = Color(0.52, 0.60, 0.68)
			env.ambient_light_color = Color(0.72, 0.74, 0.76)
			env.ambient_light_energy = 0.55
			env.glow_intensity = 0.16
		"fire":
			env.background_color = Color(0.035, 0.009, 0.003)
			env.ambient_light_color = Color(0.28, 0.075, 0.018)
			env.ambient_light_energy = 0.16
			env.glow_intensity = 0.52
			env.volumetric_fog_enabled = true
			env.volumetric_fog_density = 0.018
			env.volumetric_fog_albedo = Color(0.28, 0.10, 0.035)
		_:
			push_warning("Unknown lighting preset '%s'; using night_dark." % preset)
			return make_environment("night_dark")
	return env


## Creates a warm, visible-source point light for a practical lamp or candle.
## Shadows default off so the caller can enforce the two-shadow-light view budget.
static func practical_warm_light(shadows: bool = false) -> OmniLight3D:
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.67, 0.38)
	light.light_energy = 1.15
	light.omni_range = 5.0
	light.shadow_enabled = shadows
	light.omni_shadow_mode = OmniLight3D.SHADOW_CUBE
	return light


## Creates a cool, soft moon/window light. Prefer one shadow caster per view at most
## when a second shadow-casting practical is already visible.
static func window_cool_light(shadows: bool = false) -> SpotLight3D:
	var light := SpotLight3D.new()
	light.light_color = Color(0.58, 0.70, 1.0)
	light.light_energy = 1.6
	light.spot_range = 12.0
	light.spot_angle = 65.0
	light.shadow_enabled = shadows
	return light


## Creates a soft, low-energy TV glow. It is deliberately static; animation belongs
## to a later authored effect and must respect Unreality.motion_scale() / Reduced Motion.
static func tv_glow() -> OmniLight3D:
	var light := OmniLight3D.new()
	light.light_color = Color(0.36, 0.58, 1.0)
	light.light_energy = 0.55
	light.omni_range = 3.2
	light.shadow_enabled = false
	return light
