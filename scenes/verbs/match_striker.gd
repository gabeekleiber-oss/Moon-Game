class_name MatchStriker
extends Node3D
## S-15 component: tactile match striking for Act 9 (fire lighting).
## Striking ignites a small candle-like flame with subtle flicker, burn countdown,
## and allows lighting nearby flammable targets (woodpile, fire pit, candles).

signal struck(success: bool)
signal ignited
signal extinguished
signal target_lit(target: Node3D)

enum State { UNLIT, STRIKING, LIT, BURNT_OUT }

@export var burn_duration: float = 14.0
@export var flame_color: Color = Color(1.0, 0.65, 0.25)
@export var light_energy: float = 1.0
@export var light_range: float = 3.5

var _state: State = State.UNLIT
var _burn_time_left: float = 0.0
var _stick_mesh: MeshInstance3D
var _head_mesh: MeshInstance3D
var _flame_mesh: MeshInstance3D
var _light: OmniLight3D
var _flame_tip: Area3D
var _time_elapsed: float = 0.0


func _ready() -> void:
	_build_match()


func _process(delta: float) -> void:
	if _state != State.LIT:
		return
	_time_elapsed += delta
	_burn_time_left -= delta

	# Organic subtle flicker
	var motion := 1.0
	if Engine.has_singleton("Unreality"):
		motion = Unreality.motion_scale()
	var flicker := LightFlicker.candle(_time_elapsed, 42, motion)
	if _light:
		_light.energy = light_energy * flicker

	if _burn_time_left <= 0.0:
		extinguish()


## Strikes the match. Forgiving: ignites on the first try by default.
func strike(speed: float = 1.0) -> bool:
	if _state != State.UNLIT:
		return false
	if speed <= 0.0:
		struck.emit(false)
		return false

	_state = State.LIT
	_burn_time_left = burn_duration
	if _flame_mesh:
		_flame_mesh.visible = true
	if _light:
		_light.visible = true

	if Audio:
		Audio.play_sfx("pickup", -2.0, 1.4)
	struck.emit(true)
	ignited.emit()
	return true


## Extinguishes the flame.
func extinguish() -> void:
	if _state != State.LIT:
		return
	_state = State.BURNT_OUT
	if _flame_mesh:
		_flame_mesh.visible = false
	if _light:
		_light.visible = false
	if _head_mesh:
		# Burnt char tip
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.1, 0.1, 0.1)
		_head_mesh.material_override = mat
	extinguished.emit()


## Ignites an explicit flammable target.
func ignite_target(target: Node3D) -> bool:
	if _state != State.LIT or target == null:
		return false
	if target.has_method("ignite"):
		target.call("ignite")
		target_lit.emit(target)
		return true
	if target.is_in_group("flammable") or target.is_in_group("burnable"):
		target.set("lit", true)
		target_lit.emit(target)
		return true
	return false


func get_state() -> State:
	return _state


func is_lit() -> bool:
	return _state == State.LIT


func time_left() -> float:
	return _burn_time_left


func _on_tip_entered(body: Node3D) -> void:
	if _state == State.LIT:
		ignite_target(body)


func _on_tip_area_entered(area: Area3D) -> void:
	if _state == State.LIT:
		ignite_target(area)


func _build_match() -> void:
	# Wooden matchstick
	_stick_mesh = MeshInstance3D.new()
	_stick_mesh.name = "Stick"
	var stick_m := BoxMesh.new()
	stick_m.size = Vector3(0.015, 0.12, 0.015)
	var wood_mat := StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.85, 0.76, 0.62)
	wood_mat.roughness = 0.8
	_stick_mesh.mesh = stick_m
	_stick_mesh.material_override = wood_mat
	_stick_mesh.position = Vector3(0.0, 0.06, 0.0)
	add_child(_stick_mesh)

	# Sulfur match head
	_head_mesh = MeshInstance3D.new()
	_head_mesh.name = "Head"
	var head_m := SphereMesh.new()
	head_m.radius = 0.014
	head_m.height = 0.024
	var red_mat := StandardMaterial3D.new()
	red_mat.albedo_color = Color(0.72, 0.18, 0.15)
	_head_mesh.mesh = head_m
	_head_mesh.material_override = red_mat
	_head_mesh.position = Vector3(0.0, 0.125, 0.0)
	add_child(_head_mesh)

	# Flame mesh
	_flame_mesh = MeshInstance3D.new()
	_flame_mesh.name = "Flame"
	var flame_m := SphereMesh.new()
	flame_m.radius = 0.018
	flame_m.height = 0.045
	var f_mat := StandardMaterial3D.new()
	f_mat.albedo_color = flame_color
	f_mat.emission_enabled = true
	f_mat.emission = flame_color
	f_mat.emission_energy_multiplier = 2.0
	_flame_mesh.mesh = flame_m
	_flame_mesh.material_override = f_mat
	_flame_mesh.position = Vector3(0.0, 0.145, 0.0)
	_flame_mesh.visible = false
	add_child(_flame_mesh)

	# Flame light
	_light = OmniLight3D.new()
	_light.name = "FlameLight"
	_light.light_color = flame_color
	_light.light_energy = light_energy
	_light.omni_range = light_range
	_light.shadow_enabled = false
	_light.visible = false
	_light.position = Vector3(0.0, 0.15, 0.0)
	add_child(_light)

	# Proximity tip for lighting targets
	_flame_tip = Area3D.new()
	_flame_tip.name = "FlameTip"
	var shape := SphereShape3D.new()
	shape.radius = 0.15
	var c := CollisionShape3D.new()
	c.shape = shape
	c.position = Vector3(0.0, 0.145, 0.0)
	_flame_tip.add_child(c)
	_flame_tip.body_entered.connect(_on_tip_entered)
	_flame_tip.area_entered.connect(_on_tip_area_entered)
	add_child(_flame_tip)
