class_name MoonLight
extends Node3D
## The moon as a light (S-01; ART_BIBLE 4: "milky, cool, slightly too bright"): a shadow-casting DirectionalLight3D. Aim it with
## `elevation_deg` (angle above the horizon) and `azimuth_deg` (compass heading of the light's travel). Under Unreality, once `wrong_id`
## goes wrong the moon turns WARM (ART_BIBLE band 3: "warm moon"); that is a colour change, so Reduced Motion needs nothing special.
## One of the (at most two) shadow casters per view: use `shadows = false` if a window light already casts.

@export var color: Color = Color(0.72, 0.80, 1.0)
@export var energy: float = 0.35
@export_range(5.0, 85.0) var elevation_deg: float = 42.0 : set = set_elevation
@export var azimuth_deg: float = 200.0 : set = set_azimuth
@export var shadows: bool = true
@export var wrong_id: String = "moon_light"

const WARM := Color(1.0, 0.82, 0.58)

var light: DirectionalLight3D


func _ready() -> void:
	light = DirectionalLight3D.new()
	light.name = "Light"
	light.light_color = color
	light.light_energy = energy
	light.shadow_enabled = shadows
	light.directional_shadow_max_distance = 60.0
	light.light_volumetric_fog_energy = 1.0
	add_child(light)
	_aim()


func set_elevation(v: float) -> void:
	elevation_deg = v
	_aim()


func set_azimuth(v: float) -> void:
	azimuth_deg = v
	_aim()


## How warm the moon has gone (0..1): only after `wrong_id` goes wrong.
func warmth() -> float:
	if wrong_id == "" or not Unreality.wrongs(wrong_id):
		return 0.0
	return Unreality.ramp(0.55, 0.8)


func _process(_delta: float) -> void:
	if light != null:
		light.light_color = color.lerp(WARM, warmth())


func _aim() -> void:
	if light != null:
		light.rotation_degrees = Vector3(-elevation_deg, azimuth_deg, 0.0)
