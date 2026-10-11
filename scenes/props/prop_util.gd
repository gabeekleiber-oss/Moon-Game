class_name PropUtil
extends RefCounted
## Shared mesh/material helpers for the prop kit (F-10). All static; props are built in code.

## Swept tube along a polyline of points (local space) with radius `r`. Returns an ArrayMesh.
static func tube(points: Array[Vector3], r: float, sides: int = 8, r_end: float = -1.0) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := points.size()
	var rings: Array = []
	for i in n:
		var t := points[mini(i + 1, n - 1)] - points[maxi(i - 1, 0)]
		t = t.normalized()
		var ref := Vector3.UP if absf(t.dot(Vector3.UP)) < 0.95 else Vector3.RIGHT
		var u := t.cross(ref).normalized()
		var v := t.cross(u).normalized()
		var rad := lerpf(r, r_end if r_end >= 0.0 else r, float(i) / maxf(n - 1, 1))
		var ring: Array[Vector3] = []
		for k in sides:
			var a := TAU * float(k) / sides
			ring.append(points[i] + (u * cos(a) + v * sin(a)) * rad)
		rings.append(ring)
	for i in n - 1:
		for k in sides:
			var k2 := (k + 1) % sides
			var a: Vector3 = rings[i][k]
			var b: Vector3 = rings[i][k2]
			var c: Vector3 = rings[i + 1][k]
			var d: Vector3 = rings[i + 1][k2]
			for tri: Array in [[a, c, d], [a, d, b]]:
				for p: Vector3 in tri:
					st.add_vertex(p)
	st.generate_normals()
	return st.commit()


## Quadratic bezier sampled into `n` points.
static func bezier(p0: Vector3, p1: Vector3, p2: Vector3, n: int = 10) -> Array[Vector3]:
	var out: Array[Vector3] = []
	for i in n:
		var t := float(i) / (n - 1)
		out.append(p0.lerp(p1, t).lerp(p1.lerp(p2, t), t))
	return out


## Bipyramid (a faceted drop) of height h (hanging, tip down) and radius r.
static func drop_mesh(h: float, r: float, sides: int = 6) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var top := Vector3(0, h * 0.5, 0)
	var bot := Vector3(0, -h * 0.5, 0)
	var mid_y := h * 0.15
	for k in sides:
		var a0 := TAU * float(k) / sides
		var a1 := TAU * float(k + 1) / sides
		var p0 := Vector3(cos(a0) * r, mid_y, sin(a0) * r)
		var p1 := Vector3(cos(a1) * r, mid_y, sin(a1) * r)
		for tri: Array in [[top, p1, p0], [bot, p0, p1]]:
			for p: Vector3 in tri:
				st.add_vertex(p)
	st.generate_normals()
	return st.commit()


## Simple PBR material.
static func mat(color: Color, metallic: float = 0.0, rough: float = 0.6, emit: Color = Color.BLACK, emit_energy: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = metallic
	m.roughness = rough
	if emit_energy > 0.0:
		m.emission_enabled = true
		m.emission = emit
		m.emission_energy_multiplier = emit_energy
	return m


## Adds a MeshInstance3D child with the given mesh/material/position and returns it.
static func add_mesh(parent: Node3D, mesh: Mesh, material: Material, pos: Vector3 = Vector3.ZERO, node_name: String = "") -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = material
	mi.position = pos
	if node_name != "":
		mi.name = node_name
	parent.add_child(mi)
	return mi
