class_name BirdNest
extends Node3D
## A bird nest (F-10): ~70 curved twigs merged into two meshes (dark + light), a soft inner bowl and 0-6 eggs.
## Sits on y=0, opening upward. Exports: `radius` (default 0.22 m), `eggs`, `seed_value` (same seed = same nest), `glowing_eggs` (warm emissive,
## used by NestLantern in Ch6). `egg_count()` reports how many eggs exist. Twigs are built once in _ready; cost is 4-5 draw calls.

@export var radius: float = 0.22
@export_range(0, 6) var eggs: int = 3
@export var seed_value: int = 7
@export var glowing_eggs: bool = false

var _egg_nodes: Array[MeshInstance3D] = []


func _ready() -> void:
	_build()


## Number of eggs in the nest.
func egg_count() -> int:
	return _egg_nodes.size()


func _build() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var dark := SurfaceTool.new()
	dark.begin(Mesh.PRIMITIVE_TRIANGLES)
	var light := SurfaceTool.new()
	light.begin(Mesh.PRIMITIVE_TRIANGLES)
	var twig_n := 70
	for i in twig_n:
		var layer := float(i) / twig_n                   # 0 bottom .. 1 rim
		var a0 := rng.randf() * TAU
		var span := rng.randf_range(0.7, 1.5)
		var ring_r := radius * lerpf(0.55, 1.0, sin(layer * PI * 0.5))
		var y := radius * 0.55 * layer * layer + rng.randf_range(0.0, 0.025)
		var pts: Array[Vector3] = []
		for k in 8:
			var a := a0 + span * float(k) / 7.0
			var wob := 1.0 + rng.randf_range(-0.07, 0.07)
			pts.append(Vector3(cos(a) * ring_r * wob, y + sin(float(k) * 0.9) * 0.012, sin(a) * ring_r * wob))
		var mesh := PropUtil.tube(pts, rng.randf_range(0.004, 0.008), 4)
		(dark if i % 3 != 0 else light).append_from(mesh, 0, Transform3D.IDENTITY)
	for pair: Array in [[dark, Color(0.28, 0.18, 0.1)], [light, Color(0.52, 0.38, 0.22)]]:
		var st: SurfaceTool = pair[0]
		st.generate_normals()
		PropUtil.add_mesh(self, st.commit(), PropUtil.mat(pair[1], 0.0, 0.95), Vector3.ZERO, "Twigs")
	# soft bowl
	var bowl := SphereMesh.new()
	bowl.radius = radius * 0.82
	bowl.height = radius * 1.64
	var bm := PropUtil.mat(Color(0.62, 0.55, 0.42), 0.0, 1.0)
	var bi := PropUtil.add_mesh(self, bowl, bm, Vector3(0, radius * 0.3, 0), "Bowl")
	bi.scale = Vector3(1.0, 0.35, 1.0)
	# eggs
	var em := PropUtil.mat(Color(0.7, 0.88, 0.86), 0.0, 0.35)
	if glowing_eggs:
		em = PropUtil.mat(Color(1.0, 0.9, 0.6), 0.0, 0.4, Color(1.0, 0.75, 0.35), 2.2)
	for i in eggs:
		var egg := SphereMesh.new()
		egg.radius = radius * 0.2
		egg.height = radius * 0.4
		var a := TAU * float(i) / maxi(eggs, 1) + 0.5
		var off := radius * 0.28 if eggs > 1 else 0.0
		var mi := PropUtil.add_mesh(self, egg, em, Vector3(cos(a) * off, radius * 0.72, sin(a) * off), "Egg%d" % i)
		mi.scale = Vector3(0.8, 1.0, 0.8)
		mi.rotation = Vector3(rng.randf_range(-0.4, 0.4), 0, rng.randf_range(-0.4, 0.4))
		_egg_nodes.append(mi)
