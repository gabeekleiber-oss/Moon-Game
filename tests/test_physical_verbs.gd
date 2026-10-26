extends Node
const CarryPropsScript = preload("res://scenes/player/props/carry_props.gd")
var _fails := 0

func _check(condition: bool, message: String) -> void:
	print(("PASS " if condition else "FAIL ") + message)
	if not condition:
		_fails += 1

func _physics_frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame

func _make_hittable(pos: Vector3, required: int, accepts: PackedStringArray) -> Hittable:
	var h := Hittable.new()
	h.position = pos
	h.hits_required = required
	h.accepts = accepts
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.8, 0.8, 0.5)
	shape.shape = box
	h.add_child(shape)
	add_child(h)
	return h

func _ready() -> void:
	# Camera at the origin looking down -Z, with a carry controller and the verbs node, like the player rig.
	var cam := Camera3D.new()
	add_child(cam)
	var carry := CarryController.new()
	carry.name = "CarryController"
	cam.add_child(carry)
	var verbs := PhysicalVerbs.new()
	cam.add_child(verbs)
	await get_tree().process_frame
	_check(InputMap.has_action("swing") and InputMap.has_action("kick") and InputMap.has_action("throw_item"), "verb input actions exist")

	# --- swing: the TV takes two broom blows; forgiving cone also catches an off-axis target.
	var tv := _make_hittable(Vector3(0.5, 0.0, -1.6), 2, PackedStringArray(["swing"]))
	var hits: Array = []
	tv.hit.connect(func(_k: String, _s: float, c: int) -> void: hits.append(c))
	var broke := [false]
	tv.broken.connect(func() -> void: broke[0] = true)
	await _physics_frames(3)
	_check(not verbs.swing(), "swinging empty-handed does nothing")
	var broom := CarryPropsScript.make("broom")
	add_child(broom)
	_check(carry.try_pickup(broom), "broom can be picked up")
	_check(PhysicalVerbs.is_swingable(broom), "broom counts as swingable")
	_check(verbs.swing(), "first swing connects with an off-axis target")
	_check(hits == [1] and not broke[0], "first blow counted, TV not yet broken")
	_check(not verbs.swing(), "swing is on a short cooldown")
	verbs._cooldown = 0.0
	_check(verbs.swing() and hits == [1, 2] and broke[0], "second blow breaks the TV exactly once")
	verbs._cooldown = 0.0
	verbs.swing()
	_check(hits.size() == 2, "a third swing does not re-break it")
	await get_tree().create_timer(0.6).timeout
	_check(carry.action_rotation.length() < 0.5, "swing animation returns to the hold pose")

	# --- kick: shoo accepts a kick, ignores a swing.
	carry.drop_item()
	var shoo := _make_hittable(Vector3(0.0, 0.0, -1.5), 1, PackedStringArray(["kick"]))
	var ignored := [0]
	shoo.ignored.connect(func(_k: String) -> void: ignored[0] += 1)
	await _physics_frames(3)
	_check(shoo.take_hit("swing") == false and ignored[0] == 1, "unaccepted blow is ignored, not an error")
	verbs._cooldown = 0.0
	_check(verbs.kick() and shoo.hit_count == 1, "kick shoos the target")

	tv.free()
	shoo.free()   # clear the flight path; the earlier targets would block the throw
	# --- throw: ballistic assist lands a thrown prop in a ThrowTarget.
	var floor_body := StaticBody3D.new()
	var floor_shape := CollisionShape3D.new()
	var floor_box := BoxShape3D.new()
	floor_box.size = Vector3(30, 1, 30)
	floor_shape.shape = floor_box
	floor_body.add_child(floor_shape)
	floor_body.position = Vector3(0, -3.5, 0)
	add_child(floor_body)
	var tank := ThrowTarget.new()
	tank.position = Vector3(0.0, 0.0, -5.0)
	var area_shape := CollisionShape3D.new()
	var area_box := BoxShape3D.new()
	area_box.size = Vector3(1.6, 1.6, 1.6)
	area_shape.shape = area_box
	tank.add_child(area_shape)
	add_child(tank)
	var caught: Array = []
	tank.received.connect(func(p: ThrownProp) -> void: caught.append(p.kind))
	var phone := CarryPropsScript.make("broom")
	phone.set_meta("throw_kind", "phone")
	add_child(phone)
	await _physics_frames(3)
	carry.try_pickup(phone)
	var prop := verbs.throw_held()
	_check(prop != null and prop.kind == "phone", "throw_held creates a physics prop of the item's kind")
	_check(not phone.visible and carry.held_item == null, "thrown original is hidden and no longer held")
	var waited := 0.0
	while caught.is_empty() and waited < 3.0:
		await get_tree().physics_frame
		waited += 1.0 / 60.0
	_check(caught == ["phone"], "aim-assisted throw lands in the target")
	var vel := PhysicalVerbs.ballistic_velocity(Vector3.ZERO, Vector3(0, 0, -5), 0.7)
	_check(vel.z < 0.0 and vel.y > 0.0, "ballistic velocity points toward the target and upward")
	print("RESULT: %s" % ("ALL PASS" if _fails == 0 else "%d FAILED" % _fails))
	get_tree().quit(0 if _fails == 0 else 1)
