class_name CandleLight
extends Node3D
## A candle (S-01): a small warm unshadowed OmniLight3D with an organic +/-7% flicker and a tiny emissive flame. Cheap enough to place
## thirteen of them (Act 5). Reduced Motion: steady glow. `lit = false` snuffs it (energy 0, flame hidden).

@export var color: Color = Color(1.0, 0.62, 0.28)
@export var energy: float = 0.9
@export var light_range: float = 3.5
@export var lit: bool = true : set = set_lit
@export var noise_seed: int = 0

var light: OmniLight3D
var flame: MeshInstance3D
var _t: float = 0.0


func _ready() -> void:
	_t = float(noise_seed) * 0.37
	light = OmniLight3D.new()
	light.name = "Light"
	light.light_color = color
	light.light_energy = energy
	light.omni_range = light_range
	light.omni_attenuation = 1.6
	light.shadow_enabled = false
	light.light_volumetric_fog_energy = 0.8
	add_child(light)
	# PLACEHOLDER: a code-built flame until real candle props exist.
	flame = MeshInstance3D.new()
	flame.name = "Flame"
	var m := SphereMesh.new()
	m.radius = 0.012
	m.height = 0.04
	flame.mesh = m
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 4.0
	flame.material_override = mat
	flame.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(flame)
	set_lit(lit)


func set_lit(on: bool) -> void:
	lit = on
	if light == null:
		return
	light.visible = on
	flame.visible = on


## Multiplier on `energy` at time `t` (pure given Reduced Motion).
func factor_at(t: float) -> float:
	return LightFlicker.candle(t, noise_seed, Unreality.motion_scale())


func _process(delta: float) -> void:
	if not lit:
		return
	_t += delta
	light.light_energy = energy * factor_at(_t)
