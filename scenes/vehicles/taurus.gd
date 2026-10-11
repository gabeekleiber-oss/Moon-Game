class_name Taurus
extends Node3D
## The family's 1994 Ford Taurus (C-02; reused by Ch3's driving game). ~4.9 m long, 1.8 m wide; the FRONT faces -Z.
##
## Built in code from primitives. The cabin glass is translucent so the family is visible inside.
## Seats are Marker nodes: "driver" (left, -X), "passenger" (+X, the letter's seat), "rear_left", "rear_mid", "rear_right".
## API: `seat_position(name)` (global, seat surface), `seat_character(c, name)` (puts a Character in a seat, legs sunk into the body),
## `buckle_letter(on)` (letter + seatbelt on the passenger seat), `set_headlights(on)`, `wheels()`.
## The paint colour is assumed (the story only says 1994 Ford Taurus).

const SEATS := {
	"driver": Vector3(-0.45, 0.62, -0.3),
	"passenger": Vector3(0.45, 0.62, -0.3),
	"rear_left": Vector3(-0.55, 0.62, 0.95),
	"rear_mid": Vector3(0.0, 0.62, 0.95),
	"rear_right": Vector3(0.55, 0.62, 0.95),
}

@export var paint: Color = Color(0.2, 0.4, 0.37)

var _wheels: Array[MeshInstance3D] = []
var _letter: MeshInstance3D
var _belt: MeshInstance3D
var _lights: Array[Light3D] = []
var _head_mat: StandardMaterial3D


func _ready() -> void:
	_build()


## Global position of a seat's surface, or the car origin for an unknown name.
func seat_position(seat: String) -> Vector3:
	return to_global(SEATS.get(seat, Vector3.ZERO))


## True while the letter sits buckled in the passenger seat.
func letter_buckled() -> bool:
	return _letter != null and _letter.visible


## Shows or hides the letter and its seatbelt on the passenger seat.
func buckle_letter(on: bool) -> void:
	_letter.visible = on
	_belt.visible = on


## Seats a Character: head just under the roof, legs hidden inside the body. Returns the local position used.
func seat_character(c: Node3D, seat: String) -> Vector3:
	var h := 1.7
	if c.has_method("height_m"):
		h = float(c.call("height_m"))
	var p: Vector3 = SEATS.get(seat, Vector3.ZERO)
	p.y = 1.3 - h
	if c.get_parent() != self:
		if c.get_parent() != null:
			c.get_parent().remove_child(c)
		add_child(c)
	c.position = p
	c.rotation = Vector3.ZERO
	c.rotation.y = PI                                      # characters face +Z; the car's front is -Z, so +PI turns them forward
	return p


func set_headlights(on: bool) -> void:
	for l in _lights:
		l.visible = on
	_head_mat.emission_energy_multiplier = 2.5 if on else 0.2


func wheels() -> Array[MeshInstance3D]:
	return _wheels


func _build() -> void:
	var body_mat := PropUtil.mat(paint, 0.35, 0.45)
	var dark := PropUtil.mat(Color(0.06, 0.06, 0.07), 0.0, 0.8)
	var chrome := PropUtil.mat(Color(0.7, 0.7, 0.72), 0.9, 0.25)
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.55, 0.7, 0.85, 0.22)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.roughness = 0.05
	_add_box(Vector3(1.8, 0.55, 4.9), Vector3(0, 0.575, 0), body_mat, "Body")
	_add_box(Vector3(1.7, 0.1, 1.4), Vector3(0, 0.88, -1.7), body_mat, "Hood")          # slight hood step
	_add_box(Vector3(1.66, 0.52, 2.5), Vector3(0, 1.12, 0.25), glass, "CabinGlass")
	_add_box(Vector3(1.72, 0.06, 2.6), Vector3(0, 1.4, 0.25), body_mat, "Roof")
	for x in [-0.82, 0.82]:
		for z in [-0.95, 1.45]:
			_add_box(Vector3(0.06, 0.52, 0.06), Vector3(x, 1.12, z), body_mat, "Pillar")
	_add_box(Vector3(1.85, 0.16, 0.12), Vector3(0, 0.42, -2.48), dark, "BumperFront")
	_add_box(Vector3(1.85, 0.16, 0.12), Vector3(0, 0.42, 2.48), dark, "BumperRear")
	_add_box(Vector3(0.8, 0.12, 0.03), Vector3(0, 0.62, -2.46), chrome, "Grille")
	_head_mat = PropUtil.mat(Color(1, 0.96, 0.8), 0.0, 0.3, Color(1, 0.95, 0.75), 2.5)
	for x in [-0.65, 0.65]:
		_add_box(Vector3(0.3, 0.12, 0.05), Vector3(x, 0.72, -2.46), _head_mat, "Headlight")
		_add_box(Vector3(0.3, 0.1, 0.05), Vector3(x, 0.72, 2.46), PropUtil.mat(Color(0.7, 0.05, 0.05), 0.0, 0.4, Color(1, 0.1, 0.1), 0.8), "Taillight")
		var spot := SpotLight3D.new()
		spot.position = Vector3(x, 0.72, -2.5)
		spot.rotation_degrees = Vector3(-4, 0, 0)
		spot.light_color = Color(1, 0.95, 0.8)
		spot.light_energy = 2.0
		spot.spot_range = 14.0
		spot.spot_angle = 32.0
		add_child(spot)
		_lights.append(spot)
	for wx in [-0.9, 0.9]:
		for wz in [-1.55, 1.55]:
			var w := CylinderMesh.new()
			w.top_radius = 0.33
			w.bottom_radius = 0.33
			w.height = 0.24
			var mi := PropUtil.add_mesh(self, w, dark, Vector3(wx, 0.33, wz), "Wheel")
			mi.rotation_degrees = Vector3(0, 0, 90)
			_wheels.append(mi)
	# Seats: cushions and backs
	var seat_mat := PropUtil.mat(Color(0.45, 0.4, 0.34), 0.0, 0.95)
	for name: String in SEATS:
		var p: Vector3 = SEATS[name]
		_add_box(Vector3(0.45, 0.12, 0.5), Vector3(p.x, p.y - 0.1, p.z), seat_mat, "Seat_" + name)
		_add_box(Vector3(0.45, 0.5, 0.1), Vector3(p.x, p.y + 0.2, p.z + 0.26), seat_mat, "SeatBack_" + name)
	# The letter, upright and buckled in the passenger seat
	_letter = PropUtil.add_mesh(self, _box(Vector3(0.26, 0.34, 0.02)), PropUtil.mat(Color(0.93, 0.86, 0.66), 0.0, 0.8, Color(1.0, 0.8, 0.4), 0.3), SEATS["passenger"] + Vector3(0, 0.38, 0.1), "Letter")
	_belt = PropUtil.add_mesh(self, _box(Vector3(0.05, 0.62, 0.015)), PropUtil.mat(Color(0.08, 0.08, 0.1), 0.0, 0.9), SEATS["passenger"] + Vector3(0.0, 0.4, 0.0), "Seatbelt")
	_belt.rotation_degrees = Vector3(0, 0, 38)
	_letter.visible = false
	_belt.visible = false
	set_headlights(false)


func _box(size: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = size
	return b


func _add_box(size: Vector3, pos: Vector3, material: Material, node_name: String) -> MeshInstance3D:
	return PropUtil.add_mesh(self, _box(size), material, pos, node_name)
