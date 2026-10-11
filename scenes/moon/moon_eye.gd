class_name MoonEye
extends Node3D
## The Moon with the Eye: reusable hero prop (title, Ch5 dome, windows in Ch6/8/9, finale). Built entirely in code.
## The eye looks along local +Z. Drop it in, then:
##   await moon.open(1.2)  /  moon.close(0.6)  /  moon.blink()  /  moon.look_at_point(world_pos)  /  moon.set_pupil(0.2, 0.4)
##   moon.aim_eye_at(world_pos) turns the whole moon so the eye faces that point.
## `eye_enabled = false` gives a plain blank moon (distant sky). Lids start CLOSED unless start_open is set.
## Geometry is in metres; `radius` is the moon radius. Reduced Motion is respected for blinks (they become slow fades are not needed: blinks just stay short and un-repeated).

signal opened
signal closed
signal blinked

const MOON_SHADER := preload("res://scenes/moon/moon_surface.gdshader")
const IRIS_SHADER := preload("res://scenes/moon/iris.gdshader")
const MAX_LID_ANGLE := deg_to_rad(84.0)
const MAX_LOOK_ANGLE := deg_to_rad(32.0)

@export var radius: float = 10.0
@export var eye_enabled: bool = true
@export var start_open: bool = false
@export_range(0.0, 1.0) var glow: float = 0.22

var openness: float = 0.0 : set = _set_openness   ## 0 closed .. 1 fully open
var pupil_size: float = 0.35 : set = _set_pupil

var _eye_radius: float
var _moon: MeshInstance3D
var _eye_root: Node3D        ## sits at the eyeball centre
var _eyeball: Node3D         ## rotates for look_at (sclera + iris + cornea)
var _upper: Node3D
var _lower: Node3D
var _iris_mat: ShaderMaterial
var _lid_tween: Tween
var _pupil_tween: Tween
var _look_dir: Vector3 = Vector3.FORWARD * -1.0


func _ready() -> void:
	_eye_radius = radius * 0.27
	_build_moon()
	if eye_enabled:
		_build_eye()
		_set_openness(1.0 if start_open else 0.0)
		_set_pupil(pupil_size)


## Open the lids over `seconds`. Returns the Tween (await tween.finished) and emits `opened`.
func open(seconds: float = 1.0) -> Tween:
	return _animate_lids(1.0, seconds, opened)


## Close the lids over `seconds`. Emits `closed`.
func close(seconds: float = 0.6) -> Tween:
	return _animate_lids(0.0, seconds, closed)


## One quick blink (close then reopen to the current openness). Emits `blinked`.
func blink(seconds: float = 0.22) -> Tween:
	if not eye_enabled:
		return null
	var start := openness
	_kill(_lid_tween)
	_lid_tween = create_tween()
	_lid_tween.tween_method(_set_openness, start, 0.0, seconds * 0.4).set_trans(Tween.TRANS_SINE)
	_lid_tween.tween_method(_set_openness, 0.0, start, seconds * 0.6).set_trans(Tween.TRANS_SINE)
	_lid_tween.tween_callback(func() -> void: blinked.emit())
	return _lid_tween


## Make the eyeball look at a world-space point (clamped to a believable cone). `seconds` 0 = instant.
func look_at_point(world_pos: Vector3, seconds: float = 0.35) -> void:
	if not eye_enabled or _eyeball == null:
		return
	var local := to_local(world_pos) - _eye_root.position
	if local.length() < 0.001:
		return
	var dir := local.normalized()
	var angle := dir.angle_to(Vector3.BACK)
	if angle > MAX_LOOK_ANGLE:
		dir = Vector3.BACK.slerp(dir, MAX_LOOK_ANGLE / angle)
	_look_dir = dir
	var target := Basis.looking_at(-dir, Vector3.UP)   # eyeball's front is +Z, looking_at points -Z
	if seconds <= 0.0:
		_eyeball.basis = target
	else:
		create_tween().tween_property(_eyeball, "basis", target, seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


## Eyes forward again.
func look_forward(seconds: float = 0.35) -> void:
	look_at_point(to_global(_eye_root.position + Vector3.BACK * 10.0), seconds)


## Set the pupil size, 0 (pinpoint) .. 1 (wide), over `seconds`.
func set_pupil(size: float, seconds: float = 0.3) -> void:
	_kill(_pupil_tween)
	if seconds <= 0.0:
		_set_pupil(size)
		return
	_pupil_tween = create_tween()
	_pupil_tween.tween_method(_set_pupil, pupil_size, clampf(size, 0.0, 1.0), seconds)


## Rotate the whole moon so its eye faces `world_pos` (the eye looks along local +Z).
func aim_eye_at(world_pos: Vector3) -> void:
	if world_pos.distance_to(global_position) < 0.001:
		return
	look_at(world_pos, Vector3.UP)
	rotate_object_local(Vector3.UP, PI)


## True when the lids are (almost) fully open.
func is_open() -> bool:
	return openness > 0.98


## World-space position of the eyeball centre (useful for aiming cameras/lights).
func eye_world_position() -> Vector3:
	return to_global(_eye_root.position) if _eye_root != null else global_position


# ---------------------------------------------------------------- internals

func _animate_lids(target: float, seconds: float, done: Signal) -> Tween:
	if not eye_enabled:
		return null
	_kill(_lid_tween)
	_lid_tween = create_tween()
	_lid_tween.tween_method(_set_openness, openness, target, maxf(seconds, 0.001)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_lid_tween.tween_callback(func() -> void: done.emit())
	return _lid_tween


func _kill(t: Tween) -> void:
	if t != null and t.is_valid():
		t.kill()


func _set_openness(v: float) -> void:
	openness = clampf(v, 0.0, 1.0)
	if _upper == null:
		return
	var a := openness * MAX_LID_ANGLE
	_upper.rotation = Vector3(-a, 0.0, 0.0)   # pole +Y swings toward -Z (behind the eye)
	_lower.rotation = Vector3(a * 0.8, 0.0, 0.0)


func _set_pupil(v: float) -> void:
	pupil_size = clampf(v, 0.0, 1.0)
	if _iris_mat != null:
		_iris_mat.set_shader_parameter("pupil", lerpf(0.12, 0.62, pupil_size))


func _build_moon() -> void:
	_moon = MeshInstance3D.new()
	_moon.name = "MoonSphere"
	var m := SphereMesh.new()
	m.radius = radius
	m.height = radius * 2.0
	m.radial_segments = 96
	m.rings = 48
	_moon.mesh = m
	var mat := ShaderMaterial.new()
	mat.shader = MOON_SHADER
	mat.set_shader_parameter("glow", glow)
	mat.set_shader_parameter("socket_radius", 0.42 if eye_enabled else 0.0)
	_moon.material_override = mat
	add_child(_moon)


func _build_eye() -> void:
	var e := _eye_radius
	_eye_root = Node3D.new()
	_eye_root.name = "EyeRoot"
	_eye_root.position = Vector3(0.0, 0.0, radius - e * 0.35)   # eyeball sunk into the socket
	add_child(_eye_root)

	_eyeball = Node3D.new()
	_eyeball.name = "Eyeball"
	_eye_root.add_child(_eyeball)

	var sclera := MeshInstance3D.new()
	sclera.name = "Sclera"
	var sm := SphereMesh.new()
	sm.radius = e
	sm.height = e * 2.0
	sm.radial_segments = 48
	sm.rings = 24
	sclera.mesh = sm
	var sclera_mat := StandardMaterial3D.new()
	sclera_mat.albedo_color = Color(0.96, 0.94, 0.9)
	sclera_mat.roughness = 0.45
	sclera_mat.emission_enabled = true
	sclera_mat.emission = Color(0.9, 0.88, 0.85)
	sclera_mat.emission_energy_multiplier = 0.25
	sclera.material_override = sclera_mat
	_eyeball.add_child(sclera)

	# Iris: a slightly larger sphere that the shader clips to a disc, so it hugs the eyeball curve.
	var iris := MeshInstance3D.new()
	iris.name = "Iris"
	var im := SphereMesh.new()
	im.radius = e * 1.006
	im.height = e * 2.012
	im.radial_segments = 48
	im.rings = 24
	iris.mesh = im
	_iris_mat = ShaderMaterial.new()
	_iris_mat.shader = IRIS_SHADER
	_iris_mat.set_shader_parameter("iris_radius", e * 0.5)
	iris.material_override = _iris_mat
	_eyeball.add_child(iris)

	var cornea := MeshInstance3D.new()
	cornea.name = "Cornea"
	var cm := SphereMesh.new()
	cm.radius = e * 0.8
	cm.height = e * 1.6
	cm.radial_segments = 48
	cm.rings = 24
	cornea.mesh = cm
	cornea.position = Vector3(0.0, 0.0, e * 0.3)
	var cmat := StandardMaterial3D.new()
	cmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cmat.albedo_color = Color(0.9, 0.97, 1.0, 0.13)
	cmat.roughness = 0.02
	cmat.metallic_specular = 1.0
	cmat.cull_mode = BaseMaterial3D.CULL_BACK
	cornea.material_override = cmat
	_eyeball.add_child(cornea)

	_upper = _make_lid("UpperLid", true)
	_lower = _make_lid("LowerLid", false)
	_eye_root.add_child(_upper)
	_eye_root.add_child(_lower)


func _make_lid(lid_name: String, upper: bool) -> Node3D:
	var pivot := Node3D.new()
	pivot.name = lid_name
	var mi := MeshInstance3D.new()
	mi.mesh = _hemisphere_mesh(_eye_radius * 1.07, upper)
	var mat := ShaderMaterial.new()
	mat.shader = MOON_SHADER
	mat.set_shader_parameter("milk", Vector3(0.86, 0.84, 0.8))
	mat.set_shader_parameter("shade", Vector3(0.6, 0.58, 0.62))
	mat.set_shader_parameter("crater_scale", 9.0)
	mat.set_shader_parameter("crater_depth", 0.25)
	mat.set_shader_parameter("socket_radius", 0.0)
	mat.set_shader_parameter("glow", glow)
	mi.material_override = mat
	pivot.add_child(mi)
	return pivot


## Half sphere around +Y (upper) or -Y (lower), open side toward the equator plane.
func _hemisphere_mesh(r: float, upper: bool) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var lat_n := 14
	var lon_n := 40
	var sgn := 1.0 if upper else -1.0
	for i in lat_n:
		var a0 := (PI * 0.5) * float(i) / lat_n
		var a1 := (PI * 0.5) * float(i + 1) / lat_n
		for j in lon_n:
			var b0 := TAU * float(j) / lon_n
			var b1 := TAU * float(j + 1) / lon_n
			var p00 := _sph(r, a0, b0, sgn)
			var p01 := _sph(r, a0, b1, sgn)
			var p10 := _sph(r, a1, b0, sgn)
			var p11 := _sph(r, a1, b1, sgn)
			for tri: Array in ([[p00, p10, p11], [p00, p11, p01]] if upper else [[p00, p11, p10], [p00, p01, p11]]):
				for p: Vector3 in tri:
					st.set_normal(p.normalized())
					st.add_vertex(p)
	return st.commit()


func _sph(r: float, lat: float, lon: float, sgn: float) -> Vector3:
	# lat 0 = pole, PI/2 = equator
	return Vector3(sin(lat) * cos(lon), sgn * cos(lat), sin(lat) * sin(lon)) * r
