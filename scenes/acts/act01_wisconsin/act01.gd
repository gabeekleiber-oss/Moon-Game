class_name Act01
extends ActStub
## Act 1, The Fourteenth of September (docs/ACTS.md). Playable slice built from code-made PLACEHOLDER props and figures.
## Beats run in story order: intruder, finger, letter, shoo, kitchen_items, broom, tv_hit_1, tv_hit_2, quit_call, phone_throw,
## tank_throw, family_loaded. Narration captions are copied verbatim from docs/source/STORY.md (typos kept).
## TODO(resume): real characters (S-08), dressed rooms (L-01), kick/throw verbs with physics (S-15), the Taurus (S-13),
## the TV's song continuing faintly after the TV is dead, the pump humming after the tank is gone, Elsa's glare.

const TVLightScript = preload("res://scenes/lighting/lights/tv_light.gd")
const PracticalLampScript = preload("res://scenes/lighting/lights/practical_lamp.gd")
const LetterUIScript = preload("res://scenes/ui/letter_ui.gd")

const TV_POS := Vector3(0.45, 0.0, 2.5)
const FRONT_DOOR_POS := Vector3(8.85, 1.1, 2.5)
const YARD_SPAWN := Vector3(11.0, 0.1, 2.5)
const STAIR_UP_POS := Vector3(8.2, 1.0, 4.6)
const MARY_ROOM_SPAWN := Vector3(2.5, 5.1, 2.0)
const MARY_ROOM_STAIR_POS := Vector3(4.7, 6.1, 2.0)
const CAR_POS := Vector3(16.0, 0.0, 2.5)

## Tests set this false so family_loaded does not leave the scene.
var auto_advance: bool = true

var player: CharacterBody3D
var sweaty_man: Node3D
var tv: Node3D
var tv_hits: int = 0
var tv_light: Node3D
var tv_screen: MeshInstance3D
var letter_item: Interactable
var kick_target: Interactable
var yam: Carryable
var solution: Carryable
var broom: Carryable
var phone: Carryable
var tank: Carryable
var tank_broken: bool = false
var family: Array[Node3D] = []
var _items_touched: Dictionary = {}
var _intruded: bool = false
var _car_use: Interactable


func _act_ready() -> void:
	super._act_ready()
	_find_player()
	_build_living_room()
	_build_kitchen_and_closet()
	_build_entry()
	_build_upstairs()
	_build_yard()
	_ensure_throw_action()
	if player != null:
		player.global_position = Vector3(4.9, 0.1, 2.5)
		player.rotation.y = PI * 0.5
	get_tree().create_timer(2.5).timeout.connect(start_intruder)


func _process(delta: float) -> void:
	super._process(delta)
	_gate_by_beats()
	_check_kitchen_items()
	if kick_target != null and is_instance_valid(sweaty_man) and sweaty_man.visible:
		kick_target.global_position = sweaty_man.global_position + Vector3(0, 0.9, 0)


func _unhandled_input(event: InputEvent) -> void:
	super._unhandled_input(event)
	if event.is_action_pressed("throw"):
		throw_held()


# ---------------------------------------------------------------- story beats

## Beat 1: the Sweaty Man bursts in and walks up to the player. Beat 2: the finger.
func start_intruder() -> void:
	if _intruded or not is_inside_tree():
		return
	_intruded = true
	sweaty_man.visible = true
	sweaty_man.global_position = Vector3(8.6, 0.0, 2.5)
	Audio.play_sfx("door_creak")
	Events.show_message.emit("On the fourteenth of September, a man dressed in a bathrobe and dripping in sweat burst into my living room unannounced while we were watching the annual rerun of the sound of music.")
	beat("intruder")
	var tw := create_tween()
	tw.tween_property(sweaty_man, "global_position", Vector3(5.7, 0.0, 2.5), 3.0)
	await tw.finished
	await touch_with_finger()


func touch_with_finger() -> void:
	var finger := sweaty_man.get_node_or_null("Finger") as Node3D
	if finger != null:
		finger.visible = true
	if player != null:
		var look := player.global_position.direction_to(sweaty_man.global_position)
		player.rotation.y = atan2(-look.x, -look.z)
	beat("finger")
	await Dialogue.play("act01_finger")
	if finger != null:
		finger.visible = false
	letter_item.enabled = true
	Events.show_message.emit("Into the sleeve of his robe he rummaged, until he produced a slightly damp letter, baking like the sun.")


func read_letter() -> void:
	var ui: CanvasLayer = LetterUIScript.new()
	add_child(ui)
	ui.call("open")
	await ui.closed
	ui.queue_free()
	finish_letter()


func finish_letter() -> void:
	letter_item.enabled = false
	letter_item.visible = false
	if beat("letter"):
		kick_target.enabled = true


## Beat 4: kick the old hoot out. He runs off "in the sun" (a warm light in the dark doorway: the first wrong thing).
func kick_out() -> void:
	if not beats.is_available("shoo"):
		return
	kick_target.enabled = false
	Audio.play_sfx("whoosh")
	Audio.play_sfx("thud", -3.0)
	Events.show_message.emit("So i shooed the old hoot with a kick of my boot")
	beat("shoo")
	var sun := OmniLight3D.new()
	sun.light_color = Color(1.0, 0.86, 0.55)
	sun.light_energy = 2.0
	sun.omni_range = 7.0
	sun.position = Vector3(8.3, 1.8, 2.5)
	add_child(sun)
	var tw := create_tween()
	tw.tween_property(sweaty_man, "global_position", Vector3(8.7, 0.0, 2.5), 0.9)
	tw.tween_callback(func() -> void:
		sweaty_man.visible = false
		Events.show_message.emit("And he ran off in the sun with his smelly bath suit"))
	tw.tween_interval(4.0)
	tw.tween_property(sun, "light_energy", 0.0, 3.0)
	tw.tween_callback(sun.queue_free)


## Beats 7-8: thrust the broom handle into the TV's mouth, twice.
func hit_tv() -> void:
	var held := _held_item()
	if held == null or held != broom:
		Events.show_message.emit("Not with bare hands. The Carringtons are hypnotized, not stupid.")
		return
	if tv_hits == 0 and beats.is_available("tv_hit_1"):
		tv_hits = 1
		Audio.play_sfx("thud")
		tv_light.set("on", false)
		_set_screen_dark()
		Events.show_message.emit("I then thrust the handle into the mouth of that old sap")
		Events.show_message.emit("And his song stopped flat and the television went black")
		beat("tv_hit_1")
	elif tv_hits == 1 and beats.is_available("tv_hit_2"):
		tv_hits = 2
		Audio.play_sfx("glass_clink")
		Audio.play_sfx("thud", 2.0, 0.7)
		var tw := create_tween()
		tw.tween_property(tv, "rotation_degrees:x", 80.0, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.parallel().tween_property(tv, "position:y", 0.3, 0.5)
		Events.show_message.emit("I did it once again, and it fell onto the floor, and the Carrington family 27” RCA CRT was no more")
		beat("tv_hit_2")


## Beat 9: pick up the phone to call the boss and quit.
func _on_phone_picked() -> void:
	if beat("quit_call"):
		Events.show_message.emit("And that was the end of my life as I knew it")
		Events.show_message.emit("I called up my boss on the phone, then I quit, then I threw it")


## Beats 10-11: throw the phone into the fish tank, then the tank itself (key F, forgiving aim).
func throw_held() -> void:
	var item := _held_item()
	if item == null or player == null:
		return
	var cam := player.get_node("Head/Camera3D") as Camera3D
	var forward := -cam.global_transform.basis.z
	var start := cam.global_position + forward * 0.6
	var target := start + forward * 4.5
	target.y = _floor_y_at(player.global_position.y) + 0.15
	var carry := player.get_node("Head/Camera3D/CarryController")
	carry.call("drop_item")
	var hits_tank := false
	if item == phone and is_instance_valid(tank) and not tank_broken and beats.is_available("phone_throw"):
		var to_tank := (tank.global_position - start)
		if to_tank.length() < 7.0 and forward.dot(to_tank.normalized()) > 0.8:
			target = tank.global_position + Vector3(0, 0.2, 0)
			hits_tank = true
	_fly(item, start, target, hits_tank)


func _fly(item: Node3D, start: Vector3, target: Vector3, hits_tank: bool) -> void:
	item.global_position = start
	var tw := create_tween()
	tw.tween_method(func(t: float) -> void:
		item.global_position = start.lerp(target, t) + Vector3(0, sin(t * PI) * 0.9, 0), 0.0, 1.0, 0.55)
	tw.tween_callback(func() -> void: _landed(item, hits_tank))


func _landed(item: Node3D, hits_tank: bool) -> void:
	if item == phone and hits_tank:
		Audio.play_sfx("glass_clink")
		phone.visible = false
		phone.enabled = false
		Events.show_message.emit("Into the fish tank of little Mary Sue, my daughter")
		beat("phone_throw")
	elif item == tank and beats.is_available("tank_throw"):
		_break_tank()
	else:
		Audio.play_sfx("thud", -4.0)


func _break_tank() -> void:
	tank_broken = true
	Audio.play_sfx("glass_clink", 2.0, 0.8)
	Audio.play_sfx("thud")
	tank.visible = false
	tank.enabled = false
	var puddle := MeshInstance3D.new()
	var plane := BoxMesh.new()
	plane.size = Vector3(1.4, 0.02, 1.0)
	puddle.mesh = plane
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.5, 0.55, 0.6)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	puddle.material_override = mat
	puddle.name = "PlaceholderPuddle"
	add_child(puddle)
	puddle.global_position = Vector3(tank.global_position.x, _floor_y_at(tank.global_position.y) + 0.02, tank.global_position.z)
	Events.show_message.emit("Then I threw the fish tank as well")
	beat("tank_throw")


## Beat 12: get in the car; the family is crammed in the back and the letter rides in the passenger seat.
func board_car() -> void:
	if not beats.is_available("family_loaded"):
		Events.show_message.emit("Not yet. The whole house is still in the way.")
		return
	_car_use.enabled = false
	Events.show_message.emit("But my daughter and son Frank and my wife Elsa Ray")
	await Cutscene.fade_out(1.0)
	for f in family:
		f.global_position = CAR_POS + Vector3(randf_range(-0.3, 0.3), 0.7, 1.0)
	var seat := _box(self, "PlaceholderLetterOnSeat", CAR_POS + Vector3(-0.5, 0.95, -0.4), Vector3(0.22, 0.02, 0.3), Color(0.9, 0.85, 0.7))
	seat.get_parent().set_meta("letter_in_passenger_seat", true)
	Events.show_message.emit("Crammed into the back of that 1994 Ford Taurus that day")
	beat("family_loaded")
	await Cutscene.wait(1.0)
	if auto_advance:
		Acts.go_to_next()
	else:
		await Cutscene.fade_in(0.1)


# ---------------------------------------------------------------- gating and checks

## Items become usable only when the story reaches them, so no input is ever lost to the beat order.
func _gate_by_beats() -> void:
	if yam == null:
		return
	var kitchen_open := beats.is_done("shoo")
	yam.enabled = kitchen_open and not _picked_and_placed(yam)
	solution.enabled = kitchen_open and not _picked_and_placed(solution)
	broom.enabled = beats.is_done("kitchen_items")
	phone.enabled = beats.is_done("tv_hit_2") and phone.visible
	tank.enabled = beats.is_done("phone_throw") and not tank_broken


func _picked_and_placed(item: Carryable) -> bool:
	return _items_touched.get(item, false) and not item.held and item.global_position.y < 0.6


func _check_kitchen_items() -> void:
	if not beats.is_available("kitchen_items"):
		return
	for item in [yam, solution]:
		var c := item as Carryable
		if c.held:
			_items_touched[c] = true
		elif _items_touched.get(c, false) and c.global_position.y > 0.5 and c.get_parent() == self:
			c.global_position.y = 0.12  # set "stilly" on the floor (no physics yet)
	if _picked_and_placed(yam) and _picked_and_placed(solution):
		Events.show_message.emit("I went into my kitchen, took the yam and grime fighter solution and set them stilly on the floor.")
		beat("kitchen_items")


func _on_broom_picked() -> void:
	if beat("broom"):
		Events.show_message.emit("Then I grabbed the broom out of the closet, lifting it by its handle, the back into the front room where my family were hypnotized by Christoper Plummer")


# ---------------------------------------------------------------- building (all PLACEHOLDER)

func _build_living_room() -> void:
	var lamp: Node3D = PracticalLampScript.new()
	lamp.position = Vector3(5.4, 1.9, 0.5)
	lamp.set("energy", 0.5)
	add_child(lamp)
	tv = Node3D.new()
	tv.name = "PlaceholderTV"
	tv.position = TV_POS + Vector3(0, 0.0, 0)
	add_child(tv)
	_box(tv, "Stand", Vector3(0, 0.25, 0), Vector3(0.7, 0.5, 0.9), Color(0.25, 0.2, 0.16))
	var body := _box(tv, "Body", Vector3(0, 0.78, 0), Vector3(0.7, 0.58, 0.8), Color(0.12, 0.12, 0.13))
	tv_screen = _mesh_box(body, "Screen", Vector3(0.36, 0, 0), Vector3(0.02, 0.44, 0.62), Color(0.55, 0.72, 1.0))
	(tv_screen.material_override as StandardMaterial3D).emission_enabled = true
	(tv_screen.material_override as StandardMaterial3D).emission = Color(0.4, 0.6, 1.0)
	tv_light = TVLightScript.new()
	tv_light.position = Vector3(1.0, 0.8, 0.0)
	tv.add_child(tv_light)
	var tv_use := _interactable(tv, "TVUse", "Thrust the broom handle in", Vector3(0, 0.78, 0), Vector3(0.9, 0.8, 1.0))
	tv_use.used.connect(func(_p: Node3D) -> void: hit_tv())
	_box(self, "PlaceholderCouch", Vector3(3.4, 0.3, 2.5), Vector3(0.9, 0.6, 2.6), Color(0.45, 0.3, 0.22))
	var names := ["Frank", "Elsa Ray", "Mary Sue"]
	var colors := [Color(0.3, 0.4, 0.6), Color(0.6, 0.35, 0.4), Color(0.75, 0.6, 0.3)]
	for i in 3:
		var f := _figure(names[i], colors[i], 1.0 if i == 1 else 0.85)
		f.position = Vector3(3.5, 0.3, 1.6 + i * 0.9)
		f.scale = Vector3(1.0, 0.6, 1.0)  # seated on the couch
		f.rotation.y = PI * 0.5
		family.append(f)
		add_child(f)
	sweaty_man = _figure("Sweaty Man", Color(0.62, 0.55, 0.45), 1.0)
	sweaty_man.visible = false
	add_child(sweaty_man)
	var finger := _mesh_box(sweaty_man, "Finger", Vector3(0, 1.45, -0.5), Vector3(0.04, 0.04, 0.55), Color(0.85, 0.7, 0.6))
	finger.visible = false
	letter_item = _interactable(sweaty_man, "Letter", "Read the letter", Vector3(0.2, 1.2, -0.35), Vector3(0.4, 0.4, 0.4))
	letter_item.enabled = false
	letter_item.used.connect(func(_p: Node3D) -> void: read_letter())
	_mesh_box(letter_item, "Paper", Vector3.ZERO, Vector3(0.22, 0.02, 0.3), Color(0.9, 0.85, 0.7))
	kick_target = _interactable(self, "KickSweatyMan", "Kick him out (boot)", Vector3(5.7, 0.9, 2.5), Vector3(0.9, 1.8, 0.9))
	kick_target.enabled = false
	kick_target.used.connect(func(_p: Node3D) -> void: kick_out())


func _build_kitchen_and_closet() -> void:
	_box(self, "PlaceholderCounter", Vector3(1.8, 0.45, 8.6), Vector3(2.6, 0.9, 0.7), Color(0.55, 0.5, 0.42))
	yam = _carryable("Yam", Vector3(1.2, 1.0, 8.6), Vector3(0.28, 0.14, 0.14), Color(0.7, 0.35, 0.2))
	solution = _carryable("GrimeFighterSolution", Vector3(2.0, 1.1, 8.6), Vector3(0.14, 0.3, 0.14), Color(0.3, 0.75, 0.35))
	broom = _carryable("Broom", Vector3(8.6, 0.9, 8.7), Vector3(0.05, 1.5, 0.05), Color(0.7, 0.55, 0.3))
	broom.hold_rotation_degrees = Vector3(-20.0, 0.0, 0.0)
	broom.hold_offset = Vector3(0.3, -0.7, -0.6)
	broom.used.connect(func(_p: Node3D) -> void: _on_broom_picked())


func _build_entry() -> void:
	_box(self, "PlaceholderTable", Vector3(7.0, 0.4, 0.6), Vector3(0.9, 0.8, 0.5), Color(0.4, 0.3, 0.2))
	phone = _carryable("Phone", Vector3(7.0, 0.88, 0.6), Vector3(0.1, 0.05, 0.22), Color(0.1, 0.1, 0.1))
	phone.used.connect(func(_p: Node3D) -> void: _on_phone_picked())
	var door := _interactable(self, "FrontDoor", "Go outside", FRONT_DOOR_POS, Vector3(0.3, 2.0, 1.1))
	door.used.connect(func(_p: Node3D) -> void: _teleport(YARD_SPAWN, -PI * 0.5))
	var stairs := _interactable(self, "StairUp", "Go upstairs", STAIR_UP_POS, Vector3(0.9, 2.0, 0.9))
	stairs.used.connect(func(_p: Node3D) -> void: _teleport(MARY_ROOM_SPAWN, 0.0))


func _build_upstairs() -> void:
	_box(self, "PlaceholderDesk", Vector3(1.0, 5.4, 0.7), Vector3(1.4, 0.8, 0.6), Color(0.5, 0.4, 0.3))
	tank = _carryable("FishTank", Vector3(1.0, 5.95, 0.7), Vector3(0.7, 0.4, 0.4), Color(0.45, 0.7, 0.8))
	tank.carry_weight = 3.0
	tank.hold_offset = Vector3(0.0, -0.45, -0.9)
	var down := _interactable(self, "StairDown", "Go downstairs", MARY_ROOM_STAIR_POS, Vector3(0.6, 2.0, 1.0))
	down.used.connect(func(_p: Node3D) -> void: _teleport(Vector3(7.5, 0.1, 3.0), 0.0))


func _build_yard() -> void:
	_box(self, "PlaceholderYardSnow", Vector3(20.0, -0.1, 3.0), Vector3(22.0, 0.2, 18.0), Color(0.82, 0.86, 0.92))
	var lamp: Node3D = PracticalLampScript.new()
	lamp.position = Vector3(13.0, 4.0, -3.0)
	lamp.set("energy", 1.4)
	lamp.set("light_range", 12.0)
	add_child(lamp)
	var car := Node3D.new()
	car.name = "PlaceholderTaurus"
	car.position = CAR_POS
	add_child(car)
	_box(car, "Body", Vector3(0, 0.55, 0), Vector3(1.8, 0.7, 4.5), Color(0.35, 0.37, 0.42))
	_box(car, "Cabin", Vector3(0, 1.1, 0.2), Vector3(1.6, 0.5, 2.4), Color(0.3, 0.33, 0.38))
	_car_use = _interactable(car, "CarDoor", "Get in the car", Vector3(-1.0, 0.9, 0.0), Vector3(0.5, 1.2, 1.6))
	_car_use.used.connect(func(_p: Node3D) -> void: board_car())
	var back := _interactable(self, "FrontDoorInside", "Go inside", Vector3(9.4, 1.1, 2.5), Vector3(0.3, 2.0, 1.1))
	back.used.connect(func(_p: Node3D) -> void: _teleport(Vector3(7.8, 0.1, 2.5), PI * 0.5))


# ---------------------------------------------------------------- helpers

func _find_player() -> void:
	for child in get_children():
		if child is CharacterBody3D:
			player = child as CharacterBody3D


func _teleport(pos: Vector3, yaw: float) -> void:
	if player != null:
		player.global_position = pos
		player.velocity = Vector3.ZERO
		player.rotation.y = yaw


func _held_item() -> Node3D:
	if player == null:
		return null
	var carry := player.get_node_or_null("Head/Camera3D/CarryController")
	return carry.get("held_item") if carry != null else null


func _floor_y_at(y: float) -> float:
	return 5.0 if y > 3.0 else 0.0


func _ensure_throw_action() -> void:
	if InputMap.has_action("throw"):
		return
	InputMap.add_action("throw")
	var ev := InputEventKey.new()
	ev.physical_keycode = KEY_F
	InputMap.action_add_event("throw", ev)


func _set_screen_dark() -> void:
	var m := tv_screen.material_override as StandardMaterial3D
	m.emission_enabled = false
	m.albedo_color = Color(0.02, 0.02, 0.02)


func _figure(fig_name: String, color: Color, height_scale: float) -> Node3D:
	var root := Node3D.new()
	root.name = "Placeholder_" + fig_name.replace(" ", "")
	var body := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.24
	cap.height = 1.4 * height_scale
	body.mesh = cap
	body.position.y = 0.7 * height_scale
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	body.material_override = mat
	root.add_child(body)
	var head := MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = 0.16
	sph.height = 0.32
	head.mesh = sph
	head.name = "Head"
	head.position.y = 1.55 * height_scale
	var hmat := StandardMaterial3D.new()
	hmat.albedo_color = Color(0.8, 0.65, 0.55)
	head.material_override = hmat
	root.add_child(head)
	return root


func _mesh_box(parent: Node3D, node_name: String, pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi


func _box(parent: Node3D, node_name: String, pos: Vector3, size: Vector3, color: Color) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = pos
	var shape := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	shape.shape = bs
	body.add_child(shape)
	_mesh_box(body, "Mesh", Vector3.ZERO, size, color)
	parent.add_child(body)
	return body


func _interactable(parent: Node3D, node_name: String, prompt: String, pos: Vector3, size: Vector3) -> Interactable:
	var it := Interactable.new()
	it.name = node_name
	it.prompt = prompt
	it.position = pos
	var shape := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	shape.shape = bs
	it.add_child(shape)
	parent.add_child(it)
	return it


func _carryable(node_name: String, pos: Vector3, size: Vector3, color: Color) -> Carryable:
	var c := Carryable.new()
	c.name = node_name
	c.prompt = "Take " + node_name
	c.position = pos
	var shape := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	shape.shape = bs
	c.add_child(shape)
	_mesh_box(c, "Mesh", Vector3.ZERO, size, color)
	add_child(c)
	return c
