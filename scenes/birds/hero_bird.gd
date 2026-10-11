class_name HeroBird
extends Node3D
## The hero bird (F-11): ONE detailed, close-up-friendly bird (same mesh as the flock, bigger) for story beats and the Bird Room.
##
## `var b := HeroBird.new(); b.species = 4; add_child(b)`. Faces -Z, feet on y=0. `hero_scale` makes it larger than a flock bird.
## API: `set_species(i)`, `perch()` (wings folded, gentle idle bob), `fly(on)` (wings flap), `look_at_point(world, seconds)` (turns the body
## toward a point, yaw only), `hop(height, seconds)`, `is_flying()`, `species_id()`. Reduced Motion (Game.settings) stops the idle bob.
signal hopped
@export_range(0, 11) var species: int = 0
@export var hero_scale: float = 2.5
@export var start_flying: bool = false
var _mesh_inst: MeshInstance3D
var _mat: ShaderMaterial
var _flying := false
var _bob: Tween

func _ready() -> void:
	_mesh_inst = MeshInstance3D.new()
	_mesh_inst.name = "Mesh"
	add_child(_mesh_inst)
	set_species(species)
	if start_flying:
		fly(true)
	else:
		perch()


## Changes the species (palette + body size). Index wraps.
func set_species(i: int) -> void:
	species = posmod(i, BirdSpecies.COUNT)
	if _mesh_inst == null:
		return
	_mesh_inst.mesh = BirdMesh.build(BirdSpecies.get_species(species))
	_mat = BirdMesh.material().duplicate() as ShaderMaterial
	_mat.set_shader_parameter("flap_strength", 1.0 if _flying else 0.0)
	_mesh_inst.material_override = _mat
	_mesh_inst.scale = Vector3.ONE * hero_scale


## Folds the wings and starts a small idle bob (no bob under Reduced Motion).
func perch() -> void:
	_flying = false
	if _mat:
		_mat.set_shader_parameter("flap_strength", 0.0)
	_kill_bob()
	if _reduced_motion() or _mesh_inst == null or not is_inside_tree():
		return
	_bob = create_tween().set_loops()
	_bob.tween_property(_mesh_inst, "position:y", 0.004 * hero_scale, 0.9).set_trans(Tween.TRANS_SINE)
	_bob.tween_property(_mesh_inst, "position:y", 0.0, 0.9).set_trans(Tween.TRANS_SINE)


## Starts or stops flapping.
func fly(on: bool = true) -> void:
	_flying = on
	_kill_bob()
	if on:
		if _mat:
			_mat.set_shader_parameter("flap_strength", 1.0)
	else:
		perch()


## True while the wings are flapping.
func is_flying() -> bool:
	return _flying


## Turns the whole bird (yaw only) to face a world point over `seconds` (0 = instant).
func look_at_point(world_pos: Vector3, seconds: float = 0.3) -> void:
	var to := world_pos - global_position
	to.y = 0.0
	if to.length() < 0.001:
		return
	var yaw := atan2(-to.x, -to.z)
	if seconds <= 0.0 or not is_inside_tree():
		rotation.y = yaw
		return
	var cur := rotation.y
	var target := cur + wrapf(yaw - cur, -PI, PI)
	create_tween().tween_property(self, "rotation:y", target, seconds).set_trans(Tween.TRANS_SINE)


## A little hop in place (perched birds are twitchy). Emits `hopped` when it lands.
func hop(height: float = 0.05, seconds: float = 0.25) -> void:
	if not is_inside_tree():
		hopped.emit()
		return
	_kill_bob()
	var t := create_tween()
	t.tween_property(self, "position:y", position.y + height, seconds * 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(self, "position:y", position.y, seconds * 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.finished.connect(func() -> void:
		hopped.emit()
		if not _flying:
			perch())


## The current species id (e.g. "ink_wren").
func species_id() -> String:
	return BirdSpecies.get_species(species)["id"]


func _kill_bob() -> void:
	if _bob and _bob.is_valid():
		_bob.kill()
	_bob = null
	if _mesh_inst:
		_mesh_inst.position.y = 0.0


func _reduced_motion() -> bool:
	return bool(Game.settings.get("reduced_motion", false))
