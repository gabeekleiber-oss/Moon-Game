extends OmniLight3D
## Optional, restrained TV-source variation. Attach to an OmniLight3D scene only when
## authored for a specific room. Reduced Motion disables all animated variation.
## The low-frequency blend is deliberately smooth and never flashes rapidly.

@export_range(0.0, 0.5, 0.01) var variation: float = 0.06
@export_range(0.1, 5.0, 0.1) var cycles_per_second: float = 0.65

var _elapsed: float = 0.0
var _base_energy: float = 0.0


func _ready() -> void:
	_base_energy = light_energy


func _process(delta: float) -> void:
	_elapsed += delta
	var motion_scale: float = Unreality.motion_scale()
	if motion_scale <= 0.0:
		light_energy = _base_energy
		return
	var wave: float = sin(_elapsed * TAU * cycles_per_second) * 0.65
	var slow_wave: float = sin(_elapsed * TAU * cycles_per_second * 0.37) * 0.35
	light_energy = _base_energy * (1.0 + (wave + slow_wave) * variation * motion_scale)
