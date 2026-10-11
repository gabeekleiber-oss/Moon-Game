class_name BirdMesh
extends RefCounted
## Low-poly bird mesh builder (F-11). One mesh = one species colour set, flat-shaded, about 0.16 m long, facing -Z, feet near y=0.
##
## `BirdMesh.build(BirdSpecies.get_species(2))` returns an ArrayMesh (~300 triangles) with per-vertex colour (RGB = part colour,
## A = wing weight for the flap in bird.gdshader). `BirdMesh.material()` returns the shared ShaderMaterial.
## `BirdMesh.vertex_data(species)` returns {positions: PackedVector3Array, colors: PackedColorArray} without touching the renderer (tests).
## Body parts: body, belly, head, beak, two wings, tail, eyes. `size` of the species scales everything.
const SHADER := preload("res://scenes/birds/bird.gdshader")
const LENGTH := 0.16
static var _material: ShaderMaterial = null

## The shared shader material (vertex colours; wings flap when the shader's flap_strength > 0).
static func material() -> ShaderMaterial:
	if _material == null:
		_material = ShaderMaterial.new()
		_material.shader = SHADER
	return _material


## Builds the renderable mesh for a species dictionary from BirdSpecies.
static func build(species: Dictionary) -> ArrayMesh:
	var d := vertex_data(species)
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = d["positions"]
	arrays[Mesh.ARRAY_COLOR] = d["colors"]
	arrays[Mesh.ARRAY_NORMAL] = d["normals"]
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.surface_set_material(0, material())
	return mesh


## Pure geometry: {positions, colors, normals} (flat shaded, non-indexed triangles). No renderer needed.
static func vertex_data(species: Dictionary) -> Dictionary:
	var pos := PackedVector3Array()
	var col := PackedColorArray()
	var sz: float = species.get("size", 1.0)
	var body: Color = species["body"]
	var belly: Color = species["belly"]
	var wing: Color = species["wing"]
	var head: Color = species["head"]
	var beak: Color = species["beak"]
	var eye: Color = species.get("eye", Color.BLACK)
	var L := LENGTH * sz
	# body (egg shape: ellipsoid), belly lighter ellipsoid slightly lower/forward
	_ellipsoid(pos, col, Vector3(0, L * 0.42, 0), Vector3(L * 0.22, L * 0.22, L * 0.34), body, 8, 5)
	_ellipsoid(pos, col, Vector3(0, L * 0.36, -L * 0.04), Vector3(L * 0.18, L * 0.17, L * 0.28), belly, 8, 4)
	# head
	_ellipsoid(pos, col, Vector3(0, L * 0.68, -L * 0.30), Vector3(L * 0.15, L * 0.15, L * 0.15), head, 8, 5)
	# beak: little pyramid pointing -Z
	var bc := Vector3(0, L * 0.66, -L * 0.44)
	var tip := bc + Vector3(0, -L * 0.01, -L * 0.14)
	var b0 := bc + Vector3(-L * 0.045, L * 0.035, 0)
	var b1 := bc + Vector3(L * 0.045, L * 0.035, 0)
	var b2 := bc + Vector3(0, -L * 0.04, 0)
	_tri(pos, col, b0, tip, b1, beak, 0.0)
	_tri(pos, col, b1, tip, b2, beak, 0.0)
	_tri(pos, col, b2, tip, b0, beak, 0.0)
	# eyes
	for sx in [-1.0, 1.0]:
		_ellipsoid(pos, col, Vector3(sx * L * 0.115, L * 0.71, -L * 0.36), Vector3(L * 0.028, L * 0.028, L * 0.028), eye, 5, 3)
	# wings: two swept wedges (root on the body, tip out and slightly back); weight grows toward the tip
	for sx in [-1.0, 1.0]:
		var r0 := Vector3(sx * L * 0.16, L * 0.52, -L * 0.14)
		var r1 := Vector3(sx * L * 0.16, L * 0.50, L * 0.20)
		var t := Vector3(sx * L * 0.62, L * 0.50, L * 0.12)
		var m := Vector3(sx * L * 0.40, L * 0.55, -L * 0.06)
		_tri(pos, col, r0, m, r1, wing, 0.2)
		_tri(pos, col, r1, m, t, wing, 0.6, 0.2, 0.6, 1.0)
	# tail: fan of two triangles at the back
	var tr := Vector3(0, L * 0.45, L * 0.28)
	_tri(pos, col, tr + Vector3(-L * 0.06, 0, 0), tr + Vector3(L * 0.06, 0, 0), tr + Vector3(L * 0.10, L * 0.02, L * 0.30), wing, 0.0)
	_tri(pos, col, tr + Vector3(-L * 0.06, 0, 0), tr + Vector3(L * 0.10, L * 0.02, L * 0.30), tr + Vector3(-L * 0.10, L * 0.02, L * 0.30), wing, 0.0)
	# feet: two tiny sticks as thin triangles
	for sx in [-1.0, 1.0]:
		var f := Vector3(sx * L * 0.07, L * 0.22, 0.0)
		_tri(pos, col, f, f + Vector3(-L * 0.015, -L * 0.22, 0), f + Vector3(L * 0.015, -L * 0.22, 0), beak, 0.0)
	var nrm := PackedVector3Array()
	nrm.resize(pos.size())
	for i in range(0, pos.size(), 3):
		var n := (pos[i + 1] - pos[i]).cross(pos[i + 2] - pos[i]).normalized()
		nrm[i] = n
		nrm[i + 1] = n
		nrm[i + 2] = n
	return {"positions": pos, "colors": col, "normals": nrm}


## Vertex count of a species mesh (diagnostics, tests).
static func vertex_count(species: Dictionary) -> int:
	return (vertex_data(species)["positions"] as PackedVector3Array).size()


static func _tri(pos: PackedVector3Array, col: PackedColorArray, a: Vector3, b: Vector3, c: Vector3, color: Color, w: float, wa: float = -1.0, wb: float = -1.0, wc: float = -1.0) -> void:
	var ws: Array[float] = [wa if wa >= 0.0 else w, wb if wb >= 0.0 else w, wc if wc >= 0.0 else w]
	var pts: Array[Vector3] = [a, b, c]
	for i in 3:
		pos.append(pts[i])
		col.append(Color(color.r, color.g, color.b, ws[i]))


static func _ellipsoid(pos: PackedVector3Array, col: PackedColorArray, center: Vector3, radii: Vector3, color: Color, segs: int, rings: int) -> void:
	var c := Color(color.r, color.g, color.b, 0.0)
	for r in rings:
		var a0 := PI * float(r) / rings
		var a1 := PI * float(r + 1) / rings
		for s in segs:
			var b0 := TAU * float(s) / segs
			var b1 := TAU * float(s + 1) / segs
			var p00 := center + Vector3(sin(a0) * cos(b0), cos(a0), sin(a0) * sin(b0)) * radii
			var p01 := center + Vector3(sin(a0) * cos(b1), cos(a0), sin(a0) * sin(b1)) * radii
			var p10 := center + Vector3(sin(a1) * cos(b0), cos(a1), sin(a1) * sin(b0)) * radii
			var p11 := center + Vector3(sin(a1) * cos(b1), cos(a1), sin(a1) * sin(b1)) * radii
			if r > 0:
				for p in [p00, p10, p01]:
					pos.append(p)
					col.append(c)
			if r < rings - 1:
				for p in [p01, p10, p11]:
					pos.append(p)
					col.append(c)
