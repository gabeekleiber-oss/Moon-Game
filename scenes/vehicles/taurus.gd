class_name Taurus
extends Node3D
## S-13a: static 1994 Ford Taurus sedan for Act 1 (parked in the Wisconsin driveway, no driving).
## Code-built placeholder art at real scale (about 4.8 x 1.8 x 1.4 m). Front of the car faces -Z, the driver side is -X
## (the side the player walks up to). Four doors and the trunk are pivoted and open/close with a tween.
## Usage: `var car := Taurus.new(); add_child(car); car.seat_passenger(node, "rear_left"); car.place_letter(); car.play_family_loaded_cue()`.
## Reduced Motion: the dome light and headlights come on without flicker.

signal door_toggled(door_id: String, is_open: bool)
signal family_loaded_cue_played

const DOOR_IDS: Array[String] = ["front_left", "rear_left", "front_right", "rear_right", "trunk"]
const SEATS := {
	"rear_left": Vector3(-0.48, 0.05, 0.75),
	"rear_middle": Vector3(0.0, 0.05, 0.75),
	"rear_right": Vector3(0.48, 0.05, 0.75),
	"front_left": Vector3(-0.42, 0.05, -0.35),
	"front_right": Vector3(0.42, 0.05, -0.35),
}
const LETTER_POS := Vector3(0.42, 0.52, -0.38)
const OPEN_SECONDS := 0.45

var _paint := Color(0.30, 0.33, 0.40)
var _pivots: Dictionary = {}
var _open: Dictionary = {}
var _door_use: Dictionary = {}
var _passengers: Array[Node3D] = []
var _letter: MeshInstance3D = null
var _headlights: Array[SpotLight3D] = []
var _dome: OmniLight3D = null
var cue_played: bool = false


func _ready() -> void:
	if get_child_count() == 0:
		build()


## Builds the whole car (safe to call once; _ready does it when the node is empty).
func build() -> void:
	set_meta("placeholder", true)
	var shell := StaticBody3D.new()
	shell.name = "Shell"
	add_child(shell)
	_collider(shell, Vector3(0, 0.62, 0), Vector3(1.8, 0.8, 4.8))
	_collider(shell, Vector3(0, 1.2, 0.1), Vector3(1.55, 0.5, 2.5))
	_mesh(shell, "Body", Vector3(0, 0.5, 0), Vector3(1.8, 0.55, 4.8), _paint, 0.5)
	_mesh(shell, "Hood", Vector3(0, 0.82, -1.6), Vector3(1.7, 0.1, 1.5), _paint, 0.45)
	_mesh(shell, "DeckLid", Vector3(0, 0.82, 1.85), Vector3(1.7, 0.1, 1.0), _paint, 0.45)
	_mesh(shell, "Roof", Vector3(0, 1.4, 0.1), Vector3(1.6, 0.06, 1.7), _paint, 0.45)
	_mesh(shell, "Windshield", Vector3(0, 1.12, -1.0), Vector3(1.56, 0.58, 0.05), Color(0.2, 0.28, 0.3, 0.45), 0.1, -0.7)
	_mesh(shell, "RearGlass", Vector3(0, 1.12, 1.25), Vector3(1.56, 0.58, 0.05), Color(0.2, 0.28, 0.3, 0.45), 0.1, 0.8)
	for sx in [-1.0, 1.0]:
		_mesh(shell, "Pillar_%s" % ("L" if sx < 0 else "R"), Vector3(0.78 * sx, 1.12, 0.1), Vector3(0.05, 0.58, 2.2), Color(0.25, 0.27, 0.32), 0.5)
		_mesh(shell, "Window_%s" % ("L" if sx < 0 else "R"), Vector3(0.8 * sx, 1.12, 0.1), Vector3(0.03, 0.46, 2.1), Color(0.18, 0.24, 0.27, 0.35), 0.1)
	_mesh(shell, "Bumper_F", Vector3(0, 0.38, -2.42), Vector3(1.78, 0.2, 0.14), Color(0.2, 0.2, 0.22), 0.7)
	_mesh(shell, "Bumper_R", Vector3(0, 0.38, 2.42), Vector3(1.78, 0.2, 0.14), Color(0.2, 0.2, 0.22), 0.7)
	for wx in [-0.88, 0.88]:
		for wz in [-1.45, 1.45]:
			_wheel(shell, Vector3(wx, 0.32, wz))
	_build_interior()
	_build_doors()
	_build_lights()


## Seats a character (or any Node3D) in the car. Reparents it; use ids from SEATS (unknown ids use rear_middle).
func seat_passenger(node: Node3D, seat: String = "rear_middle") -> Node3D:
	var p: Node = node.get_parent()
	if p != null:
		p.remove_child(node)
	add_child(node)
	node.position = SEATS.get(seat, SEATS["rear_middle"])
	node.rotation = Vector3.ZERO
	if node.has_method("set_pose"):
		node.call("set_pose", "sit")
	if not _passengers.has(node):
		_passengers.append(node)
	return node


## Creates a fallback character (mary_sue, frank, elsa_ray) and seats it.
func load_passenger(character_id: String, seat: String = "rear_middle") -> Node3D:
	var c: Node3D = CharacterFallback.make(character_id)
	return seat_passenger(c, seat)


## Puts the letter on the front passenger seat (idempotent) and returns it.
func place_letter() -> MeshInstance3D:
	if _letter == null:
		_letter = _mesh(self, "Letter", LETTER_POS, Vector3(0.22, 0.015, 0.3), Color(0.9, 0.85, 0.7), 0.9)
	return _letter


func passenger_count() -> int:
	return _passengers.size()


## True when Mary Sue, Frank and Elsa Ray (three passengers) are seated and the letter is on the seat.
func is_loaded() -> bool:
	return _passengers.size() >= 3 and _letter != null


func door_interactable(door_id: String) -> Interactable:
	return _door_use.get(door_id) as Interactable


func is_open(door_id: String) -> bool:
	return bool(_open.get(door_id, false))


## Opens or closes a door/trunk with a short tween. Returns false for an unknown id.
func set_open(door_id: String, value: bool) -> bool:
	if not _pivots.has(door_id):
		return false
	if is_open(door_id) == value:
		return true
	_open[door_id] = value
	var pivot := _pivots[door_id] as Node3D
	var target := _open_rotation(door_id) if value else Vector3.ZERO
	var tw := create_tween()
	tw.tween_property(pivot, "rotation", target, 0.0 if not is_inside_tree() else OPEN_SECONDS).set_trans(Tween.TRANS_SINE)
	var it := _door_use.get(door_id) as Interactable
	if it != null:
		it.prompt = ("Close the " if value else "Open the ") + _door_label(door_id)
	if is_inside_tree():
		Audio.play_sfx_at("door_creak", global_position, -6.0, 0.8 if value else 0.7)
	door_toggled.emit(door_id, value)
	return true


func toggle(door_id: String) -> void:
	set_open(door_id, not is_open(door_id))


## The `family_loaded` cue: headlights on, engine turns over, the dome light shows the letter.
func play_family_loaded_cue() -> void:
	cue_played = true
	for h in _headlights:
		h.visible = true
		h.light_energy = 3.0
	_dome.visible = true
	var steady := _dome.light_energy
	if not bool(Game.settings.get("reduced_motion", false)):
		_dome.light_energy = 0.0
		var tw := create_tween()
		tw.tween_property(_dome, "light_energy", steady, 0.3)
	for i in 3:
		Audio.play_sfx_at("thud", global_position, -8.0, 0.35 + 0.05 * i)
	family_loaded_cue_played.emit()


# ---------------------------------------------------------------- build helpers

func _build_interior() -> void:
	var cloth := Color(0.38, 0.32, 0.30)
	_mesh(self, "Floor", Vector3(0, 0.3, 0), Vector3(1.6, 0.04, 2.7), Color(0.2, 0.19, 0.19), 0.95)
	for x in [-0.42, 0.42]:
		_mesh(self, "FrontSeat", Vector3(x, 0.5, -0.35), Vector3(0.5, 0.18, 0.5), cloth, 0.95)
		_mesh(self, "FrontSeatBack", Vector3(x, 0.85, -0.12), Vector3(0.5, 0.6, 0.12), cloth, 0.95)
	_mesh(self, "RearSeat", Vector3(0, 0.5, 0.75), Vector3(1.4, 0.18, 0.55), cloth, 0.95)
	_mesh(self, "RearSeatBack", Vector3(0, 0.85, 1.05), Vector3(1.4, 0.6, 0.12), cloth, 0.95)
	_mesh(self, "Dash", Vector3(0, 0.8, -0.85), Vector3(1.5, 0.3, 0.3), Color(0.2, 0.2, 0.22), 0.8)
	_mesh(self, "SteeringWheel", Vector3(-0.42, 0.88, -0.68), Vector3(0.36, 0.04, 0.36), Color(0.12, 0.12, 0.13), 0.7, -0.5)


func _build_doors() -> void:
	# Hinge at the door's front edge. Left doors swing outward to -X, right doors to +X.
	var specs := {
		"front_left": [Vector3(-0.9, 0.55, -0.95), 0.9, -1.0],
		"rear_left": [Vector3(-0.9, 0.55, 0.0), 0.85, -1.0],
		"front_right": [Vector3(0.9, 0.55, -0.95), 0.9, 1.0],
		"rear_right": [Vector3(0.9, 0.55, 0.0), 0.85, 1.0],
	}
	for id in specs:
		var hinge: Vector3 = specs[id][0]
		var length: float = specs[id][1]
		var side: float = specs[id][2]
		var pivot := Node3D.new()
		pivot.name = "Door_%s" % id
		pivot.position = hinge
		add_child(pivot)
		_mesh(pivot, "Panel", Vector3(0, 0.0, length * 0.5), Vector3(0.07, 0.5, length), _paint, 0.5)
		_mesh(pivot, "Glass", Vector3(0, 0.5, length * 0.5), Vector3(0.04, 0.42, length - 0.1), Color(0.18, 0.24, 0.27, 0.35), 0.1)
		_mesh(pivot, "Handle", Vector3(0.05 * -side, 0.12, length * 0.8), Vector3(0.04, 0.03, 0.14), Color(0.7, 0.7, 0.72), 0.3)
		_pivots[id] = pivot
		_register_use(id, Vector3(hinge.x + side * 0.2, 0.9, hinge.z + length * 0.55), Vector3(0.6, 1.0, length * 0.7))
	var trunk := Node3D.new()
	trunk.name = "Door_trunk"
	trunk.position = Vector3(0, 0.88, 1.35)
	add_child(trunk)
	_mesh(trunk, "Lid", Vector3(0, 0.0, 0.5), Vector3(1.7, 0.08, 1.0), _paint, 0.45)
	_pivots["trunk"] = trunk
	_register_use("trunk", Vector3(0, 0.85, 2.7), Vector3(1.2, 0.7, 0.5))


func _register_use(id: String, pos: Vector3, size: Vector3) -> void:
	var it := Interactable.new()
	it.name = "Use_%s" % id
	it.prompt = "Open the %s" % _door_label(id)
	it.position = pos
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	cs.shape = bs
	it.add_child(cs)
	add_child(it)
	it.used.connect(func(_p: Node3D) -> void: toggle(id))
	_door_use[id] = it


func _build_lights() -> void:
	for x in [-0.6, 0.6]:
		var lamp := _mesh(self, "Headlamp", Vector3(x, 0.62, -2.41), Vector3(0.38, 0.14, 0.04), Color(0.9, 0.9, 0.8), 0.2)
		var spot := SpotLight3D.new()
		spot.name = "Headlight_L" if x < 0.0 else "Headlight_R"
		spot.position = lamp.position + Vector3(0, 0, -0.1)
		spot.light_energy = 3.0
		spot.spot_range = 22.0
		spot.spot_angle = 32.0
		spot.light_color = Color(1.0, 0.95, 0.8)
		spot.visible = false
		add_child(spot)
		_headlights.append(spot)
	_dome = OmniLight3D.new()
	_dome.name = "DomeLight"
	_dome.position = Vector3(0.1, 1.3, -0.2)
	_dome.light_energy = 0.9
	_dome.omni_range = 2.2
	_dome.light_color = Color(1.0, 0.9, 0.7)
	_dome.shadow_enabled = false
	_dome.visible = false
	add_child(_dome)


func _wheel(parent: Node3D, pos: Vector3) -> void:
	var m := MeshInstance3D.new()
	m.name = "Wheel"
	var c := CylinderMesh.new()
	c.top_radius = 0.32
	c.bottom_radius = 0.32
	c.height = 0.22
	m.mesh = c
	m.rotation_degrees = Vector3(0, 0, 90)
	m.position = pos
	m.material_override = _mat(Color(0.06, 0.06, 0.07), 0.9)
	parent.add_child(m)


func _open_rotation(door_id: String) -> Vector3:
	match door_id:
		"front_left", "rear_left":
			return Vector3(0, -1.0, 0)
		"front_right", "rear_right":
			return Vector3(0, 1.0, 0)
		_:
			return Vector3(-1.1, 0, 0)


func _door_label(door_id: String) -> String:
	return "trunk" if door_id == "trunk" else "car door"


func _collider(parent: Node3D, pos: Vector3, size: Vector3) -> void:
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	cs.shape = bs
	cs.position = pos
	parent.add_child(cs)


func _mat(color: Color, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	if color.a < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m


func _mesh(parent: Node3D, node_name: String, pos: Vector3, size: Vector3, color: Color, rough: float, pitch: float = 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.position = pos
	mi.rotation.x = pitch
	mi.material_override = _mat(color, rough)
	parent.add_child(mi)
	return mi
