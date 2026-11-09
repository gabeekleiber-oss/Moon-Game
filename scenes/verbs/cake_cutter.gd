class_name CakeCutter
extends Node3D
## S-15 component: birthday cake and candle cutting for Act 5 (Thirteen Candles).
## Pink and white cake with thirteen lit candles (docs/ACTS.md).
## Cutting slices awards pieces for Frank, Elsa Ray, the birds, and Christopher.
## Works with knife swings (PhysicalVerbs) or direct cut_next_slice calls.

signal slice_cut(recipient: String, slice_index: int, slice: Node3D)
signal candles_blown_out
signal cake_finished

const RECIPIENTS: Array[String] = [
	"frank",
	"elsa_ray",
	"birds_1",
	"birds_2",
	"christopher"
]
const CANDLE_COUNT := 13

@export var cake_radius: float = 0.42
@export var cake_height: float = 0.22

var _candles: Array[Node3D] = []
var _slices_cut: int = 0
var _cake_body: MeshInstance3D
var _hittable: Hittable
var _candles_lit: bool = true


func _ready() -> void:
	_build_cake()
	_build_thirteen_candles()
	_setup_cut_hittable()


## Cuts the next canonical slice and spawns a slice prop.
func cut_next_slice() -> Node3D:
	if _slices_cut >= RECIPIENTS.size():
		return null
	var recipient: String = RECIPIENTS[_slices_cut]
	var index: int = _slices_cut
	_slices_cut += 1

	if Audio:
		Audio.play_sfx("pickup", -2.0, 1.2)

	var slice := _spawn_slice(recipient, index)
	slice_cut.emit(recipient, index, slice)

	# Extinguish some candles as slices are served
	if _slices_cut >= RECIPIENTS.size():
		blow_out_candles()
		cake_finished.emit()

	return slice


## Blows out all 13 candle flames.
func blow_out_candles() -> void:
	if not _candles_lit:
		return
	_candles_lit = false
	for candle in _candles:
		var flame: Node = candle.get_node_or_null("Flame")
		if flame and flame is CanvasItem or flame is Node3D:
			flame.visible = false
		var light: Node = candle.get_node_or_null("Light")
		if light and light is Light3D:
			light.visible = false
	candles_blown_out.emit()


func is_finished() -> bool:
	return _slices_cut >= RECIPIENTS.size()


func slices_remaining() -> int:
	return RECIPIENTS.size() - _slices_cut


func candle_count() -> int:
	return _candles.size()


func are_candles_lit() -> bool:
	return _candles_lit


func _setup_cut_hittable() -> void:
	_hittable = Hittable.new()
	_hittable.name = "CakeCutHittable"
	_hittable.accepts = PackedStringArray(["swing", "cut"])
	_hittable.swing_sound = "pickup"
	_hittable.hits_required = RECIPIENTS.size()
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(cake_radius * 2.2, cake_height * 1.5, cake_radius * 2.2)
	col.shape = box
	col.position = Vector3(0.0, cake_height * 0.5, 0.0)
	_hittable.add_child(col)
	_hittable.hit.connect(func(_kind: String, _strength: float, _count: int) -> void:
		cut_next_slice()
	)
	add_child(_hittable)


func _build_cake() -> void:
	# Main pink frosted round cake
	_cake_body = MeshInstance3D.new()
	_cake_body.name = "CakeBody"
	var cyl := CylinderMesh.new()
	cyl.top_radius = cake_radius
	cyl.bottom_radius = cake_radius
	cyl.height = cake_height
	var pink_mat := StandardMaterial3D.new()
	pink_mat.albedo_color = Color(0.96, 0.68, 0.76) # pink frosting
	pink_mat.roughness = 0.5
	_cake_body.mesh = cyl
	_cake_body.material_override = pink_mat
	_cake_body.position = Vector3(0.0, cake_height * 0.5, 0.0)
	add_child(_cake_body)

	# White icing trim ring
	var trim := MeshInstance3D.new()
	trim.name = "WhiteTrim"
	var t_mesh := TorusMesh.new()
	t_mesh.inner_radius = cake_radius * 0.94
	t_mesh.outer_radius = cake_radius * 1.02
	var white_mat := StandardMaterial3D.new()
	white_mat.albedo_color = Color(0.98, 0.96, 0.94)
	white_mat.roughness = 0.4
	trim.mesh = t_mesh
	trim.material_override = white_mat
	trim.position = Vector3(0.0, cake_height, 0.0)
	add_child(trim)


func _build_thirteen_candles() -> void:
	# 1 center candle + 12 perimeter candles = 13 candles
	_candles.clear()
	var positions: Array[Vector3] = []
	positions.append(Vector3(0.0, cake_height, 0.0)) # center

	var ring_r := cake_radius * 0.7
	for i in range(12):
		var angle := (TAU / 12.0) * float(i)
		positions.append(Vector3(cos(angle) * ring_r, cake_height, sin(angle) * ring_r))

	for i in range(positions.size()):
		var candle := _create_candle("Candle_%d" % (i + 1), positions[i])
		_candles.append(candle)
		add_child(candle)


func _create_candle(node_name: String, pos: Vector3) -> Node3D:
	var root := Node3D.new()
	root.name = node_name
	root.position = pos

	# Candle stick
	var stick := MeshInstance3D.new()
	var stick_m := CylinderMesh.new()
	stick_m.top_radius = 0.012
	stick_m.bottom_radius = 0.012
	stick_m.height = 0.09
	var s_mat := StandardMaterial3D.new()
	s_mat.albedo_color = Color(0.95, 0.92, 0.82)
	stick.mesh = stick_m
	stick.material_override = s_mat
	stick.position = Vector3(0.0, 0.045, 0.0)
	root.add_child(stick)

	# Candle flame
	var flame := MeshInstance3D.new()
	flame.name = "Flame"
	var flame_m := SphereMesh.new()
	flame_m.radius = 0.012
	flame_m.height = 0.03
	var f_mat := StandardMaterial3D.new()
	f_mat.albedo_color = Color(1.0, 0.68, 0.22)
	f_mat.emission_enabled = true
	f_mat.emission = Color(1.0, 0.68, 0.22)
	f_mat.emission_energy_multiplier = 2.0
	flame.mesh = flame_m
	flame.material_override = f_mat
	flame.position = Vector3(0.0, 0.105, 0.0)
	root.add_child(flame)

	# Candle light (unshadowed, warm)
	var light := OmniLight3D.new()
	light.name = "Light"
	light.light_color = Color(1.0, 0.72, 0.35)
	light.light_energy = 0.35
	light.omni_range = 1.4
	light.shadow_enabled = false
	light.position = Vector3(0.0, 0.11, 0.0)
	root.add_child(light)

	return root


func _spawn_slice(recipient: String, index: int) -> Node3D:
	var slice := Node3D.new()
	slice.name = "Slice_%s_%d" % [recipient, index]
	slice.position = position + Vector3(0.5 + float(index) * 0.25, 0.0, 0.4)

	# Little plate + cake wedge
	var plate := MeshInstance3D.new()
	var p_mesh := CylinderMesh.new()
	p_mesh.top_radius = 0.16
	p_mesh.bottom_radius = 0.14
	p_mesh.height = 0.02
	var p_mat := StandardMaterial3D.new()
	p_mat.albedo_color = Color(0.94, 0.94, 0.96)
	plate.mesh = p_mesh
	plate.material_override = p_mat
	slice.add_child(plate)

	var wedge := MeshInstance3D.new()
	var w_mesh := BoxMesh.new()
	w_mesh.size = Vector3(0.18, cake_height * 0.9, 0.14)
	var w_mat := StandardMaterial3D.new()
	w_mat.albedo_color = Color(0.96, 0.68, 0.76)
	wedge.mesh = w_mesh
	wedge.material_override = w_mat
	wedge.position = Vector3(0.0, cake_height * 0.45, 0.0)
	slice.add_child(wedge)

	get_parent().add_child(slice)
	return slice
