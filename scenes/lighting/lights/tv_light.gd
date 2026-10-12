class_name TVLight
extends Node3D
## The CRT's glow (S-01; Act 1: "the TV is the hearth"): a cold blue-white OmniLight3D that changes level at most 2.5 times a second and
## always eases (LightFlicker.tv), so it can never strobe (max 3 flashes/s, ART_BIBLE 7). Reduced Motion: a steady mid-blue glow.
## A TV prop can read `level()` (0..1.2) to drive its own screen emission so both stay in step. `on = false` switches it off (the TV is
## hit twice with a broom handle: the story turns it off).

@export var cold_color: Color = Color(0.45, 0.62, 1.0)
@export var white_color: Color = Color(0.88, 0.93, 1.0)
@export var energy: float = 1.1
@export var light_range: float = 5.5
@export var on: bool = true : set = set_on
@export var noise_seed: int = 0

var light: OmniLight3D
var _t: float = 0.0
var _level: float = 1.0


func _ready() -> void:
	light = OmniLight3D.new()
	light.name = "Light"
	light.light_color = cold_color
	light.light_energy = energy
	light.omni_range = light_range
	light.omni_attenuation = 1.3
	light.shadow_enabled = false
	light.light_volumetric_fog_energy = 1.2
	add_child(light)
	set_on(on)


func set_on(v: bool) -> void:
	on = v
	if light != null:
		light.visible = v


## Current brightness multiplier (what a screen material should follow).
func level() -> float:
	return _level


func _process(delta: float) -> void:
	if not on:
		return
	_t += delta
	var s := LightFlicker.tv(_t, noise_seed, Unreality.motion_scale())
	_level = float(s["energy"])
	light.light_energy = energy * _level
	light.light_color = cold_color.lerp(white_color, float(s["mix"]))
