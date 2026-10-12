class_name PracticalLamp
extends Node3D
## A motivated warm lamp (S-01): a small OmniLight3D plus a visible bulb. Unshadowed by default (ART_BIBLE 4: at most 2 shadow-casting
## lights per view; flip `shadows` only for a hero lamp). Under Unreality: at the "off" band it hums (a faint slow breathing), at "wrong"
## it drops out rarely, and, if `wrong_id` is set, once that id "goes wrong" its colour drifts cold (ART_BIBLE: "a cold lamp").
## Reduced Motion: steady (colour drift still applies; it does not move).
##     var lamp := PracticalLamp.new(); lamp.wrong_id = "lamp_livingroom"; add_child(lamp)

@export var color: Color = Color(1.0, 0.72, 0.45)
@export var energy: float = 1.2
@export var light_range: float = 6.0
@export var shadows: bool = false
@export var bulb_visible: bool = true
## Stable id for Unreality.wrongs(); "" = this lamp never goes cold.
@export var wrong_id: String = ""
@export var noise_seed: int = 0

const COLD := Color(0.62, 0.78, 1.0)

var light: OmniLight3D
var bulb: MeshInstance3D
var _t: float = 0.0


func _ready() -> void:
	light = OmniLight3D.new()
	light.name = "Light"
	light.light_color = color
	light.light_energy = energy
	light.omni_range = light_range
	light.omni_attenuation = 1.4
	light.shadow_enabled = shadows
	light.light_volumetric_fog_energy = 1.0
	add_child(light)
	if bulb_visible:
		# PLACEHOLDER: a code-built bulb until the lamp props (world tasks) bring real fixtures.
		bulb = MeshInstance3D.new()
		bulb.name = "Bulb"
		var m := SphereMesh.new()
		m.radius = 0.05
		m.height = 0.1
		bulb.mesh = m
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 3.0
		bulb.material_override = mat
		bulb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(bulb)


## The multiplier on `energy` at time `t` for the current Unreality (pure given Unreality; the tests call it directly).
func factor_at(t: float) -> float:
	var hum := Unreality.ramp(0.15, 0.4)
	var wrong := Unreality.ramp(0.35, 0.6)
	return LightFlicker.lamp(t, hum, wrong, noise_seed, Unreality.motion_scale())


## How cold the lamp has drifted (0..1): only after `wrong_id` goes wrong.
func coldness() -> float:
	if wrong_id == "" or not Unreality.wrongs(wrong_id):
		return 0.0
	return Unreality.ramp(0.55, 0.75)


func _process(delta: float) -> void:
	_t += delta
	var f := factor_at(_t)
	var c := color.lerp(COLD, coldness() * 0.8)
	light.light_energy = energy * f
	light.light_color = c
	if bulb != null:
		var mat := bulb.material_override as StandardMaterial3D
		mat.emission = c
		mat.emission_energy_multiplier = 3.0 * f
