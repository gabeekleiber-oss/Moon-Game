extends ChapterBase
## Chapter 2 - Burning Bridges, Drowning Phones (C-02). The snowy front yard of the Wisconsin house, built in code.
##
## Beats (`stage`): title -> tutorial (baseline look-around) -> call (quit the job) -> throw_phone (power meter, phone into
## Mary Sue's fish tank) -> tank (pick it up) -> throw_tank (throw it, it shatters) -> load (family into the Taurus, the letter
## buckled in the passenger seat) -> done. Flea: quit +5, phone +8, tank +12.
## Throws are RigidBody3D with a hold-to-charge meter (ThrowMeter) whose green zone shows the ideal power for the current aim;
## after two misses the third phone throw is gently assisted so the canon beat can never be failed.
## Narration is verbatim from docs/source/STORY.md (data/dialogue/ch02_*.json).
##
## Layout (metres): player spawns at (0, 0, -1) facing -Z; the house is at z=-8 with a porch table holding the tank at
## (0, 0.8, -6.4); the Taurus is parked at (4.5, 0, -2).
## Test hooks: `show_title_card`, `tutorial_seconds`, `stage`, `stage_changed`, `press_call()`.

## Emitted when the chapter enters a new beat.
signal stage_changed(stage: String)

const TANK_SIZE := Vector3(1.0, 0.55, 0.6)
const TABLE_POS := Vector3(0.0, 0.25, -6.4)
const FLEA_QUIT := 5.0
const FLEA_PHONE := 8.0
const FLEA_TANK := 12.0
const ASSIST_AFTER_MISSES := 2

## Show the CHAPTER card at the start (tests turn this off).
var show_title_card: bool = true
## Length of the baseline look-around before the call.
var tutorial_seconds: float = 20.0
## Current beat name (see header).
var stage: String = "title"

var _player: CharacterBody3D
var _cam: Camera3D
var _meter: ThrowMeter
var _taurus: Taurus
var _elsa: ElsaRay
var _mary: MarySue
var _frank: Frank
var _tank_it: Interactable
var _tank_group: Node3D
var _mouth: Area3D
var _held_phone: Node3D
var _held_tank: Node3D
var _door_hinge: Node3D
var _call_pressed: bool = false
var _phone_in_tank: bool = false
var _tank_held: bool = false
var _tank_shattered: bool = false
var _misses: int = 0
var _zone_timer: float = 0.0
var _thrown: RigidBody3D


func _chapter_ready() -> void:
	_player = get_node("Player") as CharacterBody3D
	_player.position = Vector3(0, 0.05, -1.0)
	_cam = _player.get_node("Head/Camera3D") as Camera3D
	for mi in _player.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).visible = false                   # first person: the capsule must not block cutscene cameras
	_build_environment()
	_build_ground_and_house()
	_build_yard_props()
	_build_tank()
	_build_taurus_and_family()
	_build_held_items()
	_meter = ThrowMeter.new()
	add_child(_meter)
	Audio.set_reverb("none")
	_flow()


# ------------------------------------------------------------------ flow

func _flow() -> void:
	_set_stage("title")
	if show_title_card:
		await Cutscene.chapter_card(chapter_id)
	_set_stage("tutorial")
	Events.objective_set.emit("Look around the yard. (WASD move, mouse look, E use)")
	await get_tree().create_timer(tutorial_seconds).timeout

	_set_stage("call")
	_held_phone.visible = true
	Events.objective_set.emit("Call your boss. [E]")
	while not _call_pressed:
		await get_tree().process_frame
	await Cutscene.play(_call_body, "ch02_call")

	_set_stage("throw_phone")
	Events.objective_set.emit("Hold [E] to charge, release to throw the phone into the fish tank.")
	while not _phone_in_tank:
		await _phone_round()
	await Dialogue.play("ch02_phone")

	_set_stage("tank")
	_tank_it.message = ""
	_tank_it.prompt = "Pick up the tank"
	Events.objective_set.emit("Pick up Mary Sue's fish tank. [E]")
	while not _tank_held:
		await get_tree().process_frame
	await Dialogue.play("ch02_tank_a")

	_set_stage("throw_tank")
	Events.objective_set.emit("Hold [E] to charge, release to throw the tank.")
	await _tank_round()
	await Dialogue.play("ch02_tank_b")

	_set_stage("load")
	Events.objective_set.emit("")
	await Cutscene.play(_load_body, "ch02_load")
	_set_stage("done")
	complete()


func _set_stage(s: String) -> void:
	stage = s
	stage_changed.emit(s)


func _input(event: InputEvent) -> void:
	if stage == "call" and not _call_pressed and event is InputEventKey and event.pressed and not event.echo and event.is_action("interact"):
		get_viewport().set_input_as_handled()
		press_call()


## Dials the boss (what E does during the call beat; tests call it directly).
func press_call() -> void:
	if stage == "call":
		_call_pressed = true


func _process(delta: float) -> void:
	if _meter == null or not _meter.is_armed() or stage != "throw_phone":
		return
	_zone_timer -= delta
	if _zone_timer <= 0.0:
		_zone_timer = 0.2
		_update_zone()


func _update_zone() -> void:
	var w := ThrowMath.ideal_window(_launch_point(), _aim(), _mouth_center(), 0.38, 0.2)
	if w.is_empty():
		_meter.set_zone(-1.0, 0.0)
	else:
		_meter.set_zone(float(w["center"]), float(w["half"]) + 0.03)


func _call_body() -> void:
	Audio.play_sfx("click")
	await Cutscene.wait(0.5)
	Audio.play_sfx("click", -3.0, 1.2)
	await Cutscene.wait(0.4)
	await Dialogue.play("ch02_call")
	Game.add_flea(FLEA_QUIT, "quit the job")
	Game.set_flag("ch02_quit")


## One aim-charge-throw round for the phone. Returns when the phone is in the tank or has missed.
func _phone_round() -> void:
	_held_phone.visible = true
	_meter.arm("Hold [E] to charge - release in the green")
	_zone_timer = 0.0
	var power: float = await _meter.released
	_held_phone.visible = false
	var assisted := _misses >= ASSIST_AFTER_MISSES
	var from := _launch_point()
	var v := ThrowMath.assisted(from, _mouth_center()) if assisted else ThrowMath.velocity(_aim(), power)
	if assisted:
		Events.show_message.emit("The phone seems to know exactly where it is going.")
	var phone := _spawn_phone(from, v)
	var t := 0.0
	while not _phone_in_tank and t < 2.4 and is_instance_valid(phone):
		await get_tree().process_frame
		t += get_process_delta_time()
	if _phone_in_tank:
		return
	if is_instance_valid(phone):
		phone.queue_free()
	_misses += 1
	Events.show_message.emit("Into the snow. You pick it up again.")
	await get_tree().create_timer(0.5).timeout


func _tank_round() -> void:
	_held_tank.visible = true
	_meter.arm("Hold [E] to charge - release to throw")
	_meter.set_zone(-1.0, 0.0)
	var power: float = await _meter.released
	_held_tank.visible = false
	var from := _launch_point()
	var v := ThrowMath.velocity(_aim(), maxf(power, 0.25))
	_spawn_tank(from, v)
	var t := 0.0
	while not _tank_shattered and t < 4.0:
		await get_tree().process_frame
		t += get_process_delta_time()
	if not _tank_shattered and is_instance_valid(_thrown):
		_shatter(_thrown.global_position)
	Game.add_flea(FLEA_TANK, "threw the fish tank")
	Game.set_flag("ch02_tank_shattered")


## Cutscene: the family comes out, climbs into the back of the Taurus, the letter is buckled in, we drive off into the night.
func _load_body() -> void:
	Cutscene.letterbox(true, 0.4)
	await Cutscene.cam_to(Transform3D(Basis.IDENTITY, Vector3(1.0, 1.8, 0.8)).looking_at(Vector3(1.6, 1.0, -5.0), Vector3.UP), 62.0, 0.8)
	var open_tw := create_tween()
	open_tw.tween_property(_door_hinge, "rotation:y", -PI * 0.5, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Audio.play_sfx_at("door_creak", _door_hinge.global_position)
	var starts := [Vector3(-0.6, 0, -7.3), Vector3(0.0, 0, -7.3), Vector3(0.6, 0, -7.3)]
	var stops := [Vector3(3.5, 0, -3.2), Vector3(3.5, 0, -2.2), Vector3(3.5, 0, -1.2)]
	var fam: Array[Character] = [_elsa, _frank, _mary]
	var walks: Array[Tween] = []
	for i in 3:
		fam[i].position = starts[i]
		fam[i].visible = true
		fam[i].face_toward(stops[i])
		var w := create_tween()
		w.tween_interval(0.4 * i)
		w.tween_property(fam[i], "position", stops[i], 2.6).set_trans(Tween.TRANS_SINE)
		walks.append(w)
	await Cutscene.wait(3.8)
	for w in walks:
		w.kill()
	_door_hinge.rotation.y = -PI * 0.5
	# end-state: everyone seated in the back, the letter buckled in front
	_taurus.seat_character(_elsa, "rear_left")
	_taurus.seat_character(_frank, "rear_mid")
	_taurus.seat_character(_mary, "rear_right")
	for c: Character in fam:
		c.visible = true
	Audio.play_sfx_at("thud", _taurus.global_position, -4.0, 0.8)
	_taurus.buckle_letter(true)
	Game.set_flag("ch02_family_loaded")
	await Cutscene.cam_to(Transform3D(Basis.IDENTITY, Vector3(1.3, 1.9, -0.2)).looking_at(_taurus.global_position + Vector3(0, 1.0, 0), Vector3.UP), 50.0, 0.9)
	await Dialogue.play("ch02_load")
	# Christopher takes the wheel
	var eye := _taurus.seat_position("driver") + Vector3(0, 0.78, 0.0)
	await Cutscene.cam_to(Transform3D(Basis.IDENTITY, eye).looking_at(eye + Vector3(0, -0.05, 4.0), Vector3.UP), 70.0, 1.0)
	_taurus.set_headlights(true)
	await Dialogue.play("ch02_drive")
	await Cutscene.fade_out(1.2)
	Game.set_flag("ch02_done")


# ------------------------------------------------------------------ throwing

func _aim() -> Vector3:
	return -_cam.global_transform.basis.z


func _launch_point() -> Vector3:
	return _cam.global_position + _aim() * 0.4 + Vector3(0, -0.1, 0)


func _mouth_center() -> Vector3:
	return TABLE_POS + Vector3(0, 0.55 + TANK_SIZE.y, 0)


func _spawn_phone(from: Vector3, v: Vector3) -> RigidBody3D:
	var rb := RigidBody3D.new()
	rb.name = "ThrownPhone"
	rb.mass = 0.2
	rb.continuous_cd = true
	rb.add_to_group("ch02_phone")
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.08, 0.15, 0.04)
	cs.shape = shape
	rb.add_child(cs)
	rb.add_child(_make_phone_mesh())
	add_child(rb)
	rb.global_position = from
	rb.linear_velocity = v
	rb.angular_velocity = Vector3(6, 3, 8)
	Audio.play_sfx_at("whoosh", from, -4.0, 1.4)
	_thrown = rb
	return rb


func _spawn_tank(from: Vector3, v: Vector3) -> RigidBody3D:
	var rb := RigidBody3D.new()
	rb.name = "ThrownTank"
	rb.mass = 4.0
	rb.continuous_cd = true
	rb.contact_monitor = true
	rb.max_contacts_reported = 4
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = TANK_SIZE
	cs.shape = shape
	rb.add_child(cs)
	rb.add_child(_make_tank_mesh())
	add_child(rb)
	rb.global_position = from
	rb.linear_velocity = v
	rb.angular_velocity = Vector3(1.5, 0.8, 2.0)
	rb.body_entered.connect(func(_b: Node) -> void: _shatter(rb.global_position))
	Audio.play_sfx_at("whoosh", from, -2.0, 0.8)
	_thrown = rb
	return rb


func _on_mouth_entered(body: Node3D) -> void:
	if _phone_in_tank or not body.is_in_group("ch02_phone"):
		return
	_phone_in_tank = true
	var rb := body as RigidBody3D
	rb.freeze = true
	_burst(rb.global_position, Color(0.6, 0.8, 1.0, 0.8), 40, 2.8)
	Audio.play_sfx_at("glass_clink", rb.global_position, 0.0, 0.7)
	Audio.play_sfx_at("boing", rb.global_position, -8.0, 0.6)
	var tw := create_tween()
	tw.tween_property(rb, "global_position:y", TABLE_POS.y + 0.55 + 0.12, 0.8).set_trans(Tween.TRANS_SINE)
	Game.add_flea(FLEA_PHONE, "phone in the fish tank")
	Game.set_flag("ch02_phone_drowned")


func _shatter(pos: Vector3) -> void:
	if _tank_shattered:
		return
	_tank_shattered = true
	if is_instance_valid(_thrown):
		_thrown.visible = false
		_thrown.freeze = true
	_burst(pos, Color(0.75, 0.9, 1.0, 0.9), 70, 5.0)
	_burst(pos, Color(0.35, 0.6, 0.95, 0.8), 50, 3.0)
	Audio.play_sfx_at("glass_clink", pos, 2.0, 0.6)
	Audio.play_sfx_at("glass_clink", pos, 0.0, 0.9)
	Audio.play_sfx_at("thud", pos, 3.0, 0.5)
	var puddle := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 1.0
	disc.bottom_radius = 1.0
	disc.height = 0.01
	puddle.mesh = disc
	var pm := StandardMaterial3D.new()
	pm.albedo_color = Color(0.4, 0.65, 0.95, 0.55)
	pm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	puddle.material_override = pm
	add_child(puddle)
	puddle.global_position = Vector3(pos.x, 0.015, pos.z)
	puddle.scale = Vector3(0.1, 1, 0.1)
	create_tween().tween_property(puddle, "scale", Vector3(1.4, 1, 1.4), 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


## A one-shot burst of small bits (glass, water drops) at `pos`.
func _burst(pos: Vector3, color: Color, amount: int, speed: float) -> void:
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = amount
	p.lifetime = 1.1
	p.direction = Vector3.UP
	p.spread = 70.0
	p.initial_velocity_min = speed * 0.4
	p.initial_velocity_max = speed
	p.gravity = Vector3(0, -9.8, 0)
	var bit := BoxMesh.new()
	bit.size = Vector3(0.04, 0.04, 0.04)
	p.mesh = bit
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	p.material_override = m
	add_child(p)
	p.global_position = pos
	p.emitting = true
	get_tree().create_timer(2.0).timeout.connect(p.queue_free)


func _on_tank_used(_p: Node3D) -> void:
	if stage != "tank" or _tank_held:
		return
	_tank_held = true
	_tank_group.visible = false
	_tank_it.enabled = false
	_tank_it.collision_layer = 0
	Audio.play_sfx("pickup", 0.0, 0.7)
	Game.set_flag("ch02_tank_taken")


# ------------------------------------------------------------------ building

func _box(size: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = size
	return b


func _solid(size: Vector3, pos: Vector3, material: Material, node_name: String, parent: Node = null) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = pos
	var mi := MeshInstance3D.new()
	mi.mesh = _box(size)
	mi.material_override = material
	body.add_child(mi)
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	cs.shape = shape
	body.add_child(cs)
	(parent if parent != null else self).add_child(body)
	return body


func _interactable(node_name: String, pos: Vector3, size: Vector3, prompt_text: String, msg: String) -> Interactable:
	var it := Interactable.new()
	it.name = node_name
	it.prompt = prompt_text
	it.message = msg
	it.position = pos
	it.range = 5.0
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	cs.shape = shape
	it.add_child(cs)
	add_child(it)
	return it


func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.04, 0.06, 0.14)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.35, 0.42, 0.68)
	env.ambient_light_energy = 0.6
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_light_color = Color(0.1, 0.15, 0.28)
	env.fog_density = 0.018
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var moon := DirectionalLight3D.new()
	moon.rotation_degrees = Vector3(-48, 28, 0)
	moon.light_color = Color(0.6, 0.72, 1.0)
	moon.light_energy = 0.8
	add_child(moon)
	var lantern := OmniLight3D.new()
	lantern.position = Vector3(-2.0, 2.3, -6.2)
	lantern.light_color = Color(1.0, 0.72, 0.38)
	lantern.light_energy = 2.2
	lantern.omni_range = 7.5
	add_child(lantern)
	var glow := OmniLight3D.new()
	glow.position = Vector3(1.8, 1.8, -5.6)
	glow.light_color = Color(1.0, 0.8, 0.5)
	glow.light_energy = 1.3
	glow.omni_range = 6.0
	add_child(glow)
	var snow := CPUParticles3D.new()
	snow.position = Vector3(0, 6, -3)
	snow.amount = 360
	snow.lifetime = 7.0
	snow.preprocess = 7.0
	snow.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	snow.emission_box_extents = Vector3(11, 0.1, 9)
	snow.direction = Vector3(0.2, -1, 0)
	snow.spread = 12.0
	snow.initial_velocity_min = 0.8
	snow.initial_velocity_max = 1.4
	snow.gravity = Vector3.ZERO
	var flake := QuadMesh.new()
	flake.size = Vector2(0.05, 0.05)
	snow.mesh = flake
	var fm := StandardMaterial3D.new()
	fm.albedo_color = Color(0.95, 0.97, 1.0, 0.85)
	fm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	fm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	snow.material_override = fm
	add_child(snow)


func _build_ground_and_house() -> void:
	_solid(Vector3(60, 0.2, 60), Vector3(0, -0.1, -3), PropUtil.mat(Color(0.82, 0.86, 0.94), 0.0, 0.95), "Snow")
	_solid(Vector3(3.2, 0.02, 12), Vector3(4.5, 0.01, -3), PropUtil.mat(Color(0.5, 0.52, 0.58), 0.0, 0.9), "Driveway")
	# House facade (white clapboard, dark roof), warm windows
	_solid(Vector3(9, 3.4, 4), Vector3(0, 1.7, -10), PropUtil.mat(Color(0.8, 0.78, 0.72), 0.0, 0.9), "House")
	var roof := PrismMesh.new()
	roof.size = Vector3(9.6, 1.6, 4.4)
	PropUtil.add_mesh(self, roof, PropUtil.mat(Color(0.2, 0.2, 0.26), 0.0, 0.9), Vector3(0, 4.2, -10), "Roof")
	PropUtil.add_mesh(self, _box(Vector3(0.7, 1.6, 0.7)), PropUtil.mat(Color(0.45, 0.25, 0.2), 0.0, 0.9), Vector3(2.8, 4.5, -10.4), "Chimney")
	var warm := PropUtil.mat(Color(1.0, 0.8, 0.5), 0.0, 0.5, Color(1.0, 0.72, 0.35), 1.6)
	for x in [-3.2, -1.8, 1.8, 3.2]:
		PropUtil.add_mesh(self, _box(Vector3(0.9, 1.0, 0.04)), warm, Vector3(x, 1.9, -7.97), "Window")
	# Porch platform and the front door (hinged; opens for the family later)
	_solid(Vector3(4.4, 0.25, 2.0), Vector3(0, 0.125, -6.9), PropUtil.mat(Color(0.4, 0.3, 0.22), 0.0, 0.8), "Porch")
	_solid(Vector3(4.6, 0.12, 2.2), Vector3(0, 3.0, -6.9), PropUtil.mat(Color(0.2, 0.2, 0.26), 0.0, 0.9), "PorchRoof")
	for x in [-2.1, 2.1]:
		_solid(Vector3(0.12, 2.7, 0.12), Vector3(x, 1.5, -5.95), PropUtil.mat(Color(0.8, 0.78, 0.72), 0.0, 0.8), "PorchPost")
	_door_hinge = Node3D.new()
	_door_hinge.position = Vector3(-0.5, 0.25, -7.95)
	add_child(_door_hinge)
	PropUtil.add_mesh(_door_hinge, _box(Vector3(1.0, 2.1, 0.08)), PropUtil.mat(Color(0.35, 0.18, 0.12), 0.0, 0.6), Vector3(0.5, 1.05, 0), "DoorPanel")
	_interactable("HouseDoor", Vector3(0, 1.3, -7.7), Vector3(1.2, 2.2, 0.4), "Look at the door", "The house is quiet now. A television is no more, and nobody has mentioned it.")


func _build_yard_props() -> void:
	# Mailbox, two trees, the interactable baseline for the first 20 seconds
	var post := PropUtil.mat(Color(0.3, 0.22, 0.15), 0.0, 0.8)
	_solid(Vector3(0.1, 1.0, 0.1), Vector3(-4.0, 0.5, -1.0), post, "MailboxPost")
	PropUtil.add_mesh(self, _box(Vector3(0.28, 0.24, 0.5)), PropUtil.mat(Color(0.2, 0.25, 0.4), 0.0, 0.6), Vector3(-4.0, 1.1, -1.0), "Mailbox")
	_interactable("MailboxInteract", Vector3(-4.0, 1.0, -1.0), Vector3(0.5, 0.6, 0.7), "Look at mailbox", "The mailbox is empty. It has the air of a mailbox that expects something.")
	for p: Vector3 in [Vector3(-6.0, 0, -5.0), Vector3(7.5, 0, -7.0)]:
		var trunk := CylinderMesh.new()
		trunk.top_radius = 0.18
		trunk.bottom_radius = 0.24
		trunk.height = 2.0
		PropUtil.add_mesh(self, trunk, post, p + Vector3(0, 1.0, 0), "Trunk")
		var cone := CylinderMesh.new()
		cone.top_radius = 0.0
		cone.bottom_radius = 1.3
		cone.height = 3.2
		PropUtil.add_mesh(self, cone, PropUtil.mat(Color(0.12, 0.28, 0.2), 0.0, 0.95), p + Vector3(0, 3.0, 0), "Pine")
		_interactable("TreeInteract", p + Vector3(0, 1.5, 0), Vector3(1.2, 3.0, 1.2), "Look at tree", "A tree. Wisconsin has several, and all of them are being very patient.")


func _build_tank() -> void:
	var wood := PropUtil.mat(Color(0.35, 0.24, 0.14), 0.0, 0.7)
	_solid(Vector3(1.4, 0.55, 0.8), TABLE_POS + Vector3(0, 0.275, 0), wood, "Table")
	_tank_group = Node3D.new()
	_tank_group.name = "FishTank"
	_tank_group.position = TABLE_POS + Vector3(0, 0.55, 0)
	add_child(_tank_group)
	# Glass walls as solid bodies (open top), so a phone can bounce off the sides or drop in through the mouth
	var t := 0.05
	var sz := TANK_SIZE
	var walls := StaticBody3D.new()
	walls.name = "TankWalls"
	_tank_group.add_child(walls)
	for w: Array in [[Vector3(sz.x, t, sz.z), Vector3(0, t * 0.5, 0)], [Vector3(t, sz.y, sz.z), Vector3(-sz.x * 0.5, sz.y * 0.5, 0)],
			[Vector3(t, sz.y, sz.z), Vector3(sz.x * 0.5, sz.y * 0.5, 0)], [Vector3(sz.x, sz.y, t), Vector3(0, sz.y * 0.5, -sz.z * 0.5)],
			[Vector3(sz.x, sz.y, t), Vector3(0, sz.y * 0.5, sz.z * 0.5)]]:
		var cs := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = w[0]
		cs.shape = shape
		cs.position = w[1]
		walls.add_child(cs)
	_tank_group.add_child(_make_tank_mesh(true))
	# Mouth sensor just under the open top
	_mouth = Area3D.new()
	_mouth.name = "TankMouth"
	var acs := CollisionShape3D.new()
	var ashape := BoxShape3D.new()
	ashape.size = Vector3(sz.x - 0.12, 0.25, sz.z - 0.12)
	acs.shape = ashape
	_mouth.add_child(acs)
	_mouth.position = TABLE_POS + Vector3(0, 0.55 + sz.y - 0.12, 0)
	_mouth.body_entered.connect(_on_mouth_entered)
	add_child(_mouth)
	_tank_it = _interactable("TankInteract", TABLE_POS + Vector3(0, 0.55 + sz.y * 0.5, 0), sz + Vector3(0.1, 0.1, 0.1), "Look at the fish tank", "Mary Sue's fish tank: blue water, a tiny castle, a gently bubbling air stone. Her whole world, on a folding table.")
	_tank_it.used.connect(_on_tank_used)


## The tank's look: glass, water, gravel, a little castle. `with_table_offset` places it for the table group (local origin = base).
func _make_tank_mesh(base_origin: bool = false) -> Node3D:
	var root := Node3D.new()
	var sz := TANK_SIZE
	var cy := sz.y * 0.5 if base_origin else 0.0
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.7, 0.85, 1.0, 0.18)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.roughness = 0.05
	PropUtil.add_mesh(root, _box(sz), glass, Vector3(0, cy, 0), "Glass")
	var water := StandardMaterial3D.new()
	water.albedo_color = Color(0.3, 0.6, 0.85, 0.35)
	water.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	PropUtil.add_mesh(root, _box(Vector3(sz.x - 0.06, sz.y * 0.78, sz.z - 0.06)), water, Vector3(0, cy - sz.y * 0.1, 0), "Water")
	PropUtil.add_mesh(root, _box(Vector3(sz.x - 0.06, 0.07, sz.z - 0.06)), PropUtil.mat(Color(0.75, 0.68, 0.5), 0.0, 1.0), Vector3(0, cy - sz.y * 0.5 + 0.06, 0), "Gravel")
	var castle := PropUtil.mat(Color(0.8, 0.55, 0.6), 0.0, 0.8)
	PropUtil.add_mesh(root, _box(Vector3(0.2, 0.2, 0.16)), castle, Vector3(-0.2, cy - sz.y * 0.5 + 0.16, 0), "Castle")
	var tower := CylinderMesh.new()
	tower.top_radius = 0.05
	tower.bottom_radius = 0.06
	tower.height = 0.28
	PropUtil.add_mesh(root, tower, castle, Vector3(-0.2, cy - sz.y * 0.5 + 0.35, 0), "Tower")
	var plant := PropUtil.mat(Color(0.2, 0.6, 0.35), 0.0, 0.9)
	var blade := PrismMesh.new()
	blade.size = Vector3(0.08, 0.3, 0.02)
	PropUtil.add_mesh(root, blade, plant, Vector3(0.25, cy - sz.y * 0.5 + 0.22, 0.05), "Weed")
	return root


func _make_phone_mesh() -> Node3D:
	var root := Node3D.new()
	PropUtil.add_mesh(root, _box(Vector3(0.07, 0.14, 0.015)), PropUtil.mat(Color(0.08, 0.08, 0.1), 0.0, 0.4), Vector3.ZERO, "Body")
	PropUtil.add_mesh(root, _box(Vector3(0.058, 0.11, 0.002)), PropUtil.mat(Color(0.3, 0.6, 0.9), 0.0, 0.3, Color(0.3, 0.6, 0.95), 1.2), Vector3(0, 0.005, 0.009), "Screen")
	return root


func _build_held_items() -> void:
	_held_phone = _make_phone_mesh()
	_held_phone.position = Vector3(0.22, -0.2, -0.45)
	_held_phone.rotation_degrees = Vector3(-25, -15, 0)
	_held_phone.scale = Vector3(1.6, 1.6, 1.6)
	_held_phone.visible = false
	_cam.add_child(_held_phone)
	_held_tank = _make_tank_mesh()
	_held_tank.position = Vector3(0.0, -0.35, -0.9)
	_held_tank.scale = Vector3(0.6, 0.6, 0.6)
	_held_tank.visible = false
	_cam.add_child(_held_tank)


func _build_taurus_and_family() -> void:
	_taurus = Taurus.new()
	_taurus.position = Vector3(4.5, 0, -2.0)
	_taurus.rotation.y = PI
	add_child(_taurus)
	_interactable("TaurusInteract", Vector3(4.5, 0.8, -2.0), Vector3(2.0, 1.6, 5.0), "Look at the car", "A 1994 Ford Taurus. It starts on the first try, which is more than can be said for most things.")
	_elsa = ElsaRay.new()
	_mary = MarySue.new()
	_frank = Frank.new()
	for c: Character in [_elsa, _mary, _frank]:
		c.visible = false
		add_child(c)
