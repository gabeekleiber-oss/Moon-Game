class_name LightShaft
extends Node3D
## Local fog density that thickens a light shaft (S-01). The shaft itself is made by a shadowed SpotLight3D/DirectionalLight3D with
## `light_volumetric_fog_energy > 0` inside an Environment with volumetric fog on (every EnvPresets look has it on, at "high"/"medium"
## quality); this adds an ellipsoid FogVolume along the node's -Z axis so the beam is denser where the light falls, like dust in a window's
## beam. Place it at the window and aim it into the room (same orientation as WindowLight). Dust MOTES are S-14's job.
## Static (nothing moves), so Reduced Motion needs no alternative. Cheap: one FogVolume.

@export var length: float = 6.0
@export var width: float = 1.8
@export var density: float = 0.25 : set = set_density
@export var color: Color = Color(1.0, 0.90, 0.72)

var volume: FogVolume
var _mat: FogMaterial


func _ready() -> void:
	volume = FogVolume.new()
	volume.name = "Volume"
	volume.shape = RenderingServer.FOG_VOLUME_SHAPE_ELLIPSOID
	volume.size = Vector3(width, width, length)
	volume.position = Vector3(0.0, 0.0, -length * 0.5)
	_mat = FogMaterial.new()
	_mat.density = density
	_mat.albedo = color
	_mat.edge_fade = 0.6
	volume.material = _mat
	add_child(volume)


func set_density(d: float) -> void:
	density = maxf(d, 0.0)
	if _mat != null:
		_mat.density = density
