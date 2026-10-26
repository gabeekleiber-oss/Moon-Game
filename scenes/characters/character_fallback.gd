class_name CharacterFallback
extends Node3D
## S-08a: the "unfinished face" character set Act 1 ships with. Simple readable bodies, smooth faces with features only
## suggested (ART_BIBLE 6), idle breathing, held expressions, sit/stand poses, voice-blip pulse and a silhouette mode.
## Everything is code-built and marked placeholder; S-08 upgrades these in place with the same API.
##
## Usage: `var c := CharacterFallback.make("elsa_ray"); room.add_child(c); c.set_pose("sit"); c.hold_expression("glare", 0.5)`.
## Ids: elsa_ray, mary_sue, frank, sweaty_man, clement, edith, primo_statue. Never a real person's likeness.

signal expression_changed(expression: String)

const IDS: Array[String] = ["elsa_ray", "mary_sue", "frank", "sweaty_man", "clement", "edith", "primo_statue"]
const EXPRESSIONS: Array[String] = ["neutral", "glare", "smile", "blank"]
const POSES: Array[String] = ["stand", "sit"]

## Per character: height (m), shoulder width (m), skin, top, bottom, hair, voice (VoiceProfiles keyword), optional extras.
const SPECS := {
	"elsa_ray": {"height": 1.68, "width": 0.40, "skin": Color(0.80, 0.64, 0.56), "top": Color(0.30, 0.36, 0.46), "bottom": Color(0.20, 0.20, 0.24), "hair": Color(0.45, 0.33, 0.20), "voice": "elsa", "eyes": Color(0.25, 0.45, 0.85)},
	"mary_sue": {"height": 1.50, "width": 0.32, "skin": Color(0.84, 0.69, 0.60), "top": Color(0.70, 0.42, 0.50), "bottom": Color(0.28, 0.30, 0.42), "hair": Color(0.40, 0.28, 0.18), "voice": "mary", "eyes": Color(0.30, 0.22, 0.16)},
	"frank": {"height": 1.30, "width": 0.28, "skin": Color(0.82, 0.66, 0.58), "top": Color(0.30, 0.50, 0.36), "bottom": Color(0.25, 0.28, 0.35), "hair": Color(0.22, 0.16, 0.12), "voice": "frank", "eyes": Color(0.22, 0.18, 0.14)},
	"sweaty_man": {"height": 1.78, "width": 0.44, "skin": Color(0.78, 0.58, 0.50), "top": Color(0.62, 0.58, 0.50), "bottom": Color(0.62, 0.58, 0.50), "hair": Color(0.30, 0.26, 0.22), "voice": "sweaty", "eyes": Color(0.20, 0.16, 0.12), "beard": true, "barefoot": true, "long_finger": true, "damp": true},
	"clement": {"height": 1.80, "width": 0.46, "skin": Color(0.78, 0.62, 0.54), "top": Color(0.34, 0.34, 0.30), "bottom": Color(0.22, 0.22, 0.20), "hair": Color(0.38, 0.34, 0.30), "voice": "clement", "eyes": Color(0.22, 0.18, 0.14)},
	"edith": {"height": 1.60, "width": 0.38, "skin": Color(0.82, 0.68, 0.60), "top": Color(0.50, 0.40, 0.46), "bottom": Color(0.30, 0.26, 0.30), "hair": Color(0.60, 0.58, 0.56), "voice": "edith", "eyes": Color(0.28, 0.24, 0.20)},
	"primo_statue": {"height": 0.0, "width": 0.50, "skin": Color(0.62, 0.60, 0.55), "top": Color(0.62, 0.60, 0.55), "bottom": Color(0.62, 0.60, 0.55), "hair": Color(0.62, 0.60, 0.55), "voice": "primo", "eyes": Color(0.62, 0.60, 0.55), "statue_base": true},
}

var character_id: String = ""
var expression: String = "neutral"
var pose: String = "stand"
var silhouette: bool = false
## Optional point the head slowly turns toward (world space). Null = look straight ahead.
var look_target: Variant = null

var _spec: Dictionary = {}
var _body: Node3D
var _torso: MeshInstance3D
var _head: Node3D
var _jaw: MeshInstance3D
var _eye_marks: Array[MeshInstance3D] = []
var _mouth_mark: MeshInstance3D
var _legs: Array[MeshInstance3D] = []
var _parts: Array[MeshInstance3D] = []
var _base_materials: Dictionary = {}
var _hold_left: float = 0.0
var _talk_pulse: float = 0.0
var _time: float = 0.0
var _seed: float = 0.0


## Creates a ready character. Unknown ids fall back to a plain adult so a typo never crashes a scene.
static func make(id: String) -> CharacterFallback:
	var c := CharacterFallback.new()
	c.character_id = id if SPECS.has(id) else "elsa_ray"
	c.name = "Character_" + c.character_id
	c.build()
	return c


func build() -> void:
	_spec = SPECS[character_id]
	_seed = float(absi(character_id.hash() % 1000)) / 1000.0 * TAU
	set_meta("placeholder", true)
	set_meta("character_id", character_id)
	set_meta("voice", _spec["voice"])
	_body = Node3D.new()
	_body.name = "Body"
	add_child(_body)
	if bool(_spec.get("statue_base", false)):
		_build_statue_base()
	else:
		_build_figure()
	if not Events.speaker_blip.is_connected(_on_speaker_blip):
		Events.speaker_blip.connect(_on_speaker_blip)
	set_expression("neutral")


func _build_figure() -> void:
	var h: float = _spec["height"]
	var w: float = _spec["width"]
	var skin: Color = _spec["skin"]
	var top: Color = _spec["top"]
	var bottom: Color = _spec["bottom"]
	var leg_len := h * 0.47
	var torso_len := h * 0.31
	var head_r := h * 0.085
	for side in [-1.0, 1.0]:
		var leg := _part(CapsuleMesh.new(), "Leg_%s" % ("L" if side < 0 else "R"), bottom)
		(leg.mesh as CapsuleMesh).radius = w * 0.17
		(leg.mesh as CapsuleMesh).height = leg_len
		leg.position = Vector3(side * w * 0.22, leg_len * 0.5, 0.0)
		_legs.append(leg)
		if bool(_spec.get("barefoot", false)):
			var foot := _part(BoxMesh.new(), "Foot_%s" % ("L" if side < 0 else "R"), skin)
			(foot.mesh as BoxMesh).size = Vector3(w * 0.3, 0.06, 0.26)
			foot.position = Vector3(side * w * 0.22, 0.03, 0.06)
	_torso = _part(CapsuleMesh.new(), "Torso", top)
	(_torso.mesh as CapsuleMesh).radius = w * 0.40
	(_torso.mesh as CapsuleMesh).height = maxf(torso_len, w * 0.9)
	_torso.position = Vector3(0.0, leg_len + torso_len * 0.5, 0.0)
	_torso.scale = Vector3(1.0, 1.0, 0.62)
	for side in [-1.0, 1.0]:
		var arm := _part(CapsuleMesh.new(), "Arm_%s" % ("L" if side < 0 else "R"), top)
		var arm_len := h * 0.36
		(arm.mesh as CapsuleMesh).radius = w * 0.12
		(arm.mesh as CapsuleMesh).height = arm_len
		arm.position = Vector3(side * (w * 0.52), leg_len + torso_len * 0.92 - arm_len * 0.5, 0.0)
		var hand := _part(SphereMesh.new(), "Hand_%s" % ("L" if side < 0 else "R"), skin)
		var hand_scale := 1.0
		(hand.mesh as SphereMesh).radius = w * 0.12 * hand_scale
		(hand.mesh as SphereMesh).height = w * 0.24 * hand_scale
		hand.position = arm.position + Vector3(0.0, -arm_len * 0.5 - 0.03, 0.0)
	if bool(_spec.get("long_finger", false)):
		# The Sweaty Man's finger is longer than it should be (ACTS Act 1 wrongness). Held out in front, ready to press.
		var finger := _part(CapsuleMesh.new(), "LongFinger", skin)
		(finger.mesh as CapsuleMesh).radius = 0.016
		(finger.mesh as CapsuleMesh).height = 0.62
		finger.rotation_degrees = Vector3(90.0, 0.0, 0.0)
		finger.position = Vector3(w * 0.52, leg_len + torso_len * 0.62, 0.34)
	_head = Node3D.new()
	_head.name = "Head"
	_head.position = Vector3(0.0, leg_len + torso_len + head_r * 1.35, 0.0)
	_body.add_child(_head)
	var skull := _part(SphereMesh.new(), "Skull", skin, _head)
	(skull.mesh as SphereMesh).radius = head_r
	(skull.mesh as SphereMesh).height = head_r * 2.25
	var neck := _part(CylinderMesh.new(), "Neck", skin)
	(neck.mesh as CylinderMesh).top_radius = head_r * 0.38
	(neck.mesh as CylinderMesh).bottom_radius = head_r * 0.42
	(neck.mesh as CylinderMesh).height = head_r * 0.9
	neck.position = Vector3(0.0, leg_len + torso_len + head_r * 0.3, 0.0)
	var hair := _part(SphereMesh.new(), "Hair", _spec["hair"], _head)
	(hair.mesh as SphereMesh).radius = head_r * 1.06
	(hair.mesh as SphereMesh).height = head_r * 1.5
	hair.position = Vector3(0.0, head_r * 0.42, -head_r * 0.12)
	if bool(_spec.get("beard", false)):
		var beard := _part(SphereMesh.new(), "Beard", _spec["hair"], _head)
		(beard.mesh as SphereMesh).radius = head_r * 0.82
		(beard.mesh as SphereMesh).height = head_r * 2.1
		beard.position = Vector3(0.0, -head_r * 0.62, head_r * 0.28)
		beard.scale = Vector3(1.0, 1.0, 0.75)
	# Unfinished face: no nose, no lips. Only a faint pair of eye smudges and a faint mouth line, soft and half transparent.
	for side in [-1.0, 1.0]:
		var mark := _mark(SphereMesh.new(), "EyeMark_%s" % ("L" if side < 0 else "R"), _spec["eyes"].darkened(0.1), 0.32)
		(mark.mesh as SphereMesh).radius = head_r * 0.17
		(mark.mesh as SphereMesh).height = head_r * 0.2
		mark.position = Vector3(side * head_r * 0.36, head_r * 0.1, head_r * 0.93)
		_head.add_child(mark)
		_eye_marks.append(mark)
	_mouth_mark = _mark(BoxMesh.new(), "MouthMark", skin.darkened(0.45), 0.28)
	(_mouth_mark.mesh as BoxMesh).size = Vector3(head_r * 0.5, head_r * 0.045, head_r * 0.05)
	_mouth_mark.position = Vector3(0.0, -head_r * 0.42, head_r * 0.93)
	_head.add_child(_mouth_mark)
	_jaw = _mouth_mark
	if bool(_spec.get("damp", false)):
		# Damp robe: slightly glossy, reads as sweat under the light.
		for p in _parts:
			if p.name in ["Torso", "Arm_L", "Arm_R", "Leg_L", "Leg_R"]:
				var m := p.material_override as StandardMaterial3D
				m.roughness = 0.35
				m.metallic_specular = 0.8
	for p in _parts:
		_base_materials[p] = p.material_override


func _build_statue_base() -> void:
	# The Joshua Primo statue base: a plinth only; S-08 or the Gold Statue Room dressing adds the figure.
	var stone: Color = _spec["skin"]
	var plinth := _part(BoxMesh.new(), "Plinth", stone)
	(plinth.mesh as BoxMesh).size = Vector3(1.0, 0.9, 1.0)
	plinth.position = Vector3(0.0, 0.45, 0.0)
	var cap := _part(BoxMesh.new(), "PlinthCap", stone.lightened(0.08))
	(cap.mesh as BoxMesh).size = Vector3(1.15, 0.12, 1.15)
	cap.position = Vector3(0.0, 0.96, 0.0)
	var col := StaticBody3D.new()
	col.name = "Collision"
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.15, 1.0, 1.15)
	shape.shape = box
	shape.position = Vector3(0.0, 0.5, 0.0)
	col.add_child(shape)
	add_child(col)
	for p in _parts:
		_base_materials[p] = p.material_override


func _part(mesh: Mesh, part_name: String, color: Color, parent: Node = null) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = part_name
	mi.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.85
	mi.material_override = mat
	(parent if parent != null else _body).add_child(mi)
	_parts.append(mi)
	return mi


func _mark(mesh: Mesh, part_name: String, color: Color, alpha: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = part_name
	mi.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(color.r, color.g, color.b, alpha)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 1.0
	mi.material_override = mat
	return mi


## Sets the face expression. Allowed: neutral, glare, smile, blank. The face only ever *suggests* the feature.
func set_expression(new_expression: String) -> void:
	if not EXPRESSIONS.has(new_expression):
		new_expression = "neutral"
	expression = new_expression
	if _mouth_mark == null:
		return
	var head_r := float(_spec["height"]) * 0.085
	var eye_scale := Vector3.ONE
	var eye_roll := 0.0
	var mouth_roll := 0.0
	var mouth_width := 1.0
	match expression:
		"glare":
			eye_scale = Vector3(1.35, 0.7, 1.0)
			eye_roll = 14.0
			mouth_width = 0.7
		"smile":
			mouth_width = 1.5
			mouth_roll = 0.0
			eye_scale = Vector3(1.0, 0.8, 1.0)
		"blank":
			eye_scale = Vector3(0.6, 0.6, 1.0)
			mouth_width = 0.6
	for i in _eye_marks.size():
		var side := -1.0 if i == 0 else 1.0
		_eye_marks[i].scale = eye_scale
		_eye_marks[i].rotation_degrees = Vector3(0.0, 0.0, -side * eye_roll)
	_mouth_mark.scale = Vector3(mouth_width, 1.0 if expression != "smile" else 2.2, 1.0)
	_mouth_mark.rotation_degrees = Vector3(0.0, 0.0, mouth_roll)
	_mouth_mark.position.y = -head_r * (0.42 if expression != "smile" else 0.38)
	expression_changed.emit(expression)


## Holds an expression for `seconds`, then returns to neutral. Used for beats like Elsa's half-second glare. seconds <= 0 holds forever.
func hold_expression(new_expression: String, seconds: float) -> void:
	set_expression(new_expression)
	_hold_left = seconds


func set_pose(new_pose: String) -> void:
	if not POSES.has(new_pose) or _body == null or bool(_spec.get("statue_base", false)):
		return
	pose = new_pose
	var h: float = _spec["height"]
	if pose == "sit":
		# Hips drop to a couch-cushion height and thighs point forward.
		_body.position = Vector3(0.0, -h * 0.20, 0.0)
		for leg in _legs:
			leg.rotation_degrees = Vector3(90.0, 0.0, 0.0)
			leg.position.y = h * 0.47 * 0.62
			leg.position.z = h * 0.47 * 0.5
	else:
		_body.position = Vector3.ZERO
		for leg in _legs:
			leg.rotation_degrees = Vector3.ZERO
			leg.position.y = h * 0.47 * 0.5
			leg.position.z = 0.0


## Flat black figure for dark-room or doorway beats ("a family member in a doorway who was not there").
func set_silhouette(on: bool) -> void:
	silhouette = on
	for p in _parts:
		if on:
			var m := StandardMaterial3D.new()
			m.albedo_color = Color(0.02, 0.02, 0.025)
			m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			p.material_override = m
		else:
			p.material_override = _base_materials.get(p, p.material_override)
	for mark in _eye_marks:
		mark.visible = not on
	if _mouth_mark != null:
		_mouth_mark.visible = not on


## Face the head toward a world-space point (null to stop). Slow, never snaps.
func look_at_point(point: Variant) -> void:
	look_target = point


func _on_speaker_blip(who: String, _ch: String) -> void:
	if who.to_lower().replace(" ", "_").contains(String(_spec.get("voice", "~"))):
		_talk_pulse = 1.0


func _process(delta: float) -> void:
	if _body == null or bool(_spec.get("statue_base", false)):
		return
	var motion := Unreality.motion_scale()
	_time += delta
	# Breathing: a slow chest swell and a tiny sway. Zero under Reduced Motion.
	var breath := sin(_time * 1.6 + _seed) * 0.012 * motion
	_torso.scale = Vector3(1.0 + breath, 1.0 + breath * 0.6, 0.62)
	_head.rotation.z = sin(_time * 0.5 + _seed) * 0.02 * motion
	# Head turn toward look_target (yaw only, limited so it never twists unnaturally).
	if look_target is Vector3:
		var to_target: Vector3 = to_local(look_target as Vector3) - _head.position
		var yaw := clampf(atan2(to_target.x, to_target.z), -1.1, 1.1)
		_head.rotation.y = lerp_angle(_head.rotation.y, yaw, clampf(delta * 2.0, 0.0, 1.0) * maxf(motion, 0.15))
	else:
		_head.rotation.y = lerp_angle(_head.rotation.y, 0.0, clampf(delta * 2.0, 0.0, 1.0))
	# Talking pulse from the voice blip: the mouth mark flickers in height.
	_talk_pulse = maxf(0.0, _talk_pulse - delta * 8.0)
	if _jaw != null and expression != "smile":
		_jaw.scale.y = 1.0 + _talk_pulse * 2.5
	if _hold_left > 0.0:
		_hold_left -= delta
		if _hold_left <= 0.0:
			set_expression("neutral")
