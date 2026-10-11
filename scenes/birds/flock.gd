class_name Flock
extends Node3D
## A flock of 60-120 birds (F-11): boids steering + one MultiMesh per species (12 draw calls total, all 12 palettes in use).
##
##   var f := Flock.new(); f.count = 90; f.bounds = AABB(Vector3(-6, 1, -6), Vector3(12, 5, 12)); add_child(f)
## Bounds are in the flock's LOCAL space. Bird i has species i % 12. `bird_scale` enlarges them (a bird is ~0.16 m; 3-4 looks right in a hall).
## API: `set_attractor(local_point)`, `clear_attractor()`, `scare(local_from, radius, strength)`, `bird_count()`, `species_count(s)`,
## `bird_position(i)`, `set_active(false)` pauses the sim and hides the birds. Reduced Motion slows the wing flap.
## Wing flap is in bird.gdshader; birds glide (wings still) while descending steeply.
const MIN_COUNT := 60
const MAX_COUNT := 120
@export_range(60, 120) var count: int = 90
@export var bounds: AABB = AABB(Vector3(-6, 1, -6), Vector3(12, 5, 12))
@export var bird_scale: float = 3.0
@export var seed_value: int = 1
var boids: Boids
var _mmis: Array[MultiMeshInstance3D] = []
var _phase := PackedFloat32Array()
var _active := true

func _ready() -> void:
	count = clampi(count, MIN_COUNT, MAX_COUNT)
	boids = Boids.new(count, bounds, seed_value)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value + 99
	_phase.resize(count)
	for i in count:
		_phase[i] = rng.randf() * TAU
	for s in BirdSpecies.COUNT:
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_custom_data = true
		mm.mesh = BirdMesh.build(BirdSpecies.get_species(s))
		mm.instance_count = species_count(s)
		var mmi := MultiMeshInstance3D.new()
		mmi.name = "Species%02d" % s
		mmi.multimesh = mm
		mmi.custom_aabb = bounds.grow(1.0)
		add_child(mmi)
		_mmis.append(mmi)
	if bool(Game.settings.get("reduced_motion", false)):
		BirdMesh.material().set_shader_parameter("flap_speed", 7.0)
	_sync()


func _process(delta: float) -> void:
	if not _active:
		return
	boids.step(delta)
	_sync()


## Number of birds in the flock.
func bird_count() -> int:
	return count


## How many birds wear species palette `s` (0-11).
func species_count(s: int) -> int:
	return (count - s + BirdSpecies.COUNT - 1) / BirdSpecies.COUNT


## Local position of bird `i`.
func bird_position(i: int) -> Vector3:
	return boids.positions[i]


## Steers the flock toward a point in the flock's local space.
func set_attractor(local_point: Vector3) -> void:
	boids.set_attractor(local_point)


## Stops steering toward a point.
func clear_attractor() -> void:
	boids.clear_attractor()


## Startles birds near `local_from` (they scatter and re-gather by themselves).
func scare(local_from: Vector3, radius: float = 3.0, strength: float = 5.0) -> void:
	boids.scare(local_from, radius, strength)


## Pauses/resumes the simulation and shows/hides the birds.
func set_active(on: bool) -> void:
	_active = on
	for m in _mmis:
		m.visible = on


## Pushes boids state into the MultiMeshes.
func _sync() -> void:
	var slot := PackedInt32Array()
	slot.resize(BirdSpecies.COUNT)
	for i in count:
		var s := i % BirdSpecies.COUNT
		var v := boids.velocities[i]
		var fwd := v.normalized()
		var up := Vector3.UP if absf(fwd.y) < 0.95 else Vector3.RIGHT
		var basis := Basis.looking_at(fwd, up).scaled(Vector3.ONE * bird_scale)
		var mm := _mmis[s].multimesh
		mm.set_instance_transform(slot[s], Transform3D(basis, boids.positions[i]))
		var glide := clampf(-fwd.y * 2.0 - 0.3, 0.0, 1.0)
		mm.set_instance_custom_data(slot[s], Color(_phase[i], glide, 0.0, 0.0))
		slot[s] += 1
