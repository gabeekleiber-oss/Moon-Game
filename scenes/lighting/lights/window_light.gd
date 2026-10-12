class_name WindowLight
extends Node3D
## Light through a window (S-01): a SpotLight3D aimed down the node's -Z axis (rotate the node to aim it into the room), shadowed so the
## frame casts its pattern, and contributing to volumetric fog so it becomes a visible shaft (EnvPresets looks have it on). It is one
## of the (at most two) shadow-casting lights per view; set `shadows = false` for secondary windows.
## `kind`: "day" honey sun (Acts 7-8), "dawn" low peach sun (Act 3, 9), "night" cold moonlight through glass (Acts 3-4, 9 east wing).

@export_enum("day", "dawn", "night") var kind: String = "day" : set = set_kind
@export var shadows: bool = true
@export var light_range: float = 14.0
@export var cone_degrees: float = 38.0

const KINDS := {
	"day": {"color": Color(1.0, 0.90, 0.70), "energy": 5.0, "fog": 1.6},
	"dawn": {"color": Color(1.0, 0.66, 0.44), "energy": 4.0, "fog": 2.0},
	"night": {"color": Color(0.56, 0.66, 0.96), "energy": 1.4, "fog": 2.5},
}

var light: SpotLight3D


func _ready() -> void:
	light = SpotLight3D.new()
	light.name = "Light"
	light.spot_range = light_range
	light.spot_angle = cone_degrees
	light.spot_angle_attenuation = 0.6
	light.shadow_enabled = shadows
	add_child(light)
	set_kind(kind)


func set_kind(k: String) -> void:
	kind = k if KINDS.has(k) else "day"
	if light == null:
		return
	var d: Dictionary = KINDS[kind]
	light.light_color = d["color"]
	light.light_energy = d["energy"]
	light.light_volumetric_fog_energy = d["fog"]
