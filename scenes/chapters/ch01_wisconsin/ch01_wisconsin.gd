extends ChapterBase
## Chapter 1 - The Fourteenth of September (C-01). A Wisconsin living room, built entirely in code.
##
## Beats (`stage`): title -> tutorial (~30 s free look) -> entrance (Sweaty Man bursts in, finger to lips) -> letter (take it)
## -> letter_ui (full-screen verbatim rhyme) -> kick (timed boot-kick) -> broom (kitchen cut, closet, take the broom)
## -> tv (thrust the handle into the TV twice) -> ending -> done (Flea +25 in total, then complete()).
## Cutscene bodies set every end-state themselves, so holding Space to skip never leaves the chapter half-built.
## Narration is verbatim from docs/source/STORY.md (data/dialogue/ch01_*.json, data/text/ch01_letter.txt).
##
## Test / debug hooks: `show_title_card`, `tutorial_seconds`, signal `stage_changed`, `stage`.
## Layout (metres): room x -3..3, z -3.5..3.5; player spawns at (0, 0, 2.6) facing -Z toward the TV on the north wall.
## Sofa + family in the middle, front door on the west wall, window and closet on the east wall.

## Emitted when the chapter enters a new beat.
signal stage_changed(stage: String)

const ROOM_W := 6.0
const ROOM_D := 7.0
const ROOM_H := 2.8
const DOOR_Z := 1.4
const FLEA_KICK := 5.0
const FLEA_HIT := 10.0           # per TV hit; kick + 2 hits = the +25 the chapter promises

## Show the CHAPTER card at the start (tests turn this off).
var show_title_card: bool = true
## Length of the free-look tutorial before the Sweaty Man arrives.
var tutorial_seconds: float = 30.0
## Current beat name (see header).
var stage: String = "title"

var _player: CharacterBody3D
var _sweaty: SweatyMan
var _elsa: ElsaRay
var _mary: MarySue
var _frank: Frank
var _door_hinge: Node3D
var _closet_hinge: Node3D
var _tv: Interactable
var _tv_body: Node3D
var _tv_screen: MeshInstance3D
var _tv_light: OmniLight3D
var _letter: Interactable
var _closet: Interactable
var _broom: Interactable
var _held_broom: Node3D
var _has_broom: bool = false
var _tv_hits: int = 0
var _letter_ui: LetterUI
var _kick_meter: KickMeter
var _boot: Node3D
var _closet_open: bool = false
var _flicker: Tween


func _chapter_ready() -> void:
	_player = get_node("Player") as CharacterBody3D
	_player.position = Vector3(0, 0.05, 2.6)
	for mi in _player.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).visible = false                   # first person: the capsule must not block cutscene cameras
	_build_environment()
	_build_room()
	_build_furniture()
	_build_tv()
	_build_family()
	_build_door_and_closet()
	_build_sweaty_man()
	_build_lights()
	Audio.set_reverb("room")
	_flow()


# ------------------------------------------------------------------ flow

func _flow() -> void:
	_set_stage("title")
	if show_title_card:
		await Cutscene.chapter_card(chapter_id)
	_set_stage("tutorial")
	Events.objective_set.emit("Look around the living room. (WASD move, mouse look, E use)")
	await get_tree().create_timer(tutorial_seconds).timeout

	_set_stage("entrance")
	await Cutscene.play(_entrance_body, "ch01_entrance")

	_set_stage("letter")
	Events.objective_set.emit("Take the letter. [E]")
	await _letter.used
	_letter.enabled = false
	await Dialogue.play("ch01_rip")
	_set_stage("letter_ui")
	await _read_letter()

	_set_stage("kick")
	Events.objective_set.emit("Kick him out!")
	await _boot_kick()

	_set_stage("broom")
	Events.objective_set.emit("Find the broom. Try the closet.")
	await Cutscene.play(_kitchen_body, "ch01_kitchen")
	while not _closet_open:                                     # state, not signals: a use during the fade-in must not be missed
		await get_tree().process_frame
	while not _has_broom:
		await get_tree().process_frame

	_set_stage("tv")
	Events.objective_set.emit("Thrust the handle into the TV. Twice.")
	await _tv_two_hits()

	_set_stage("ending")
	await Cutscene.play(_ending_body, "ch01_ending")
	_set_stage("done")
	complete()


func _set_stage(s: String) -> void:
	stage = s
	stage_changed.emit(s)


## Cutscene: knock, the door bursts open, the Sweaty Man crosses the room and presses his finger to Christopher's lips.
func _entrance_body() -> void:
	Cutscene.letterbox(true, 0.4)
	Audio.play_sfx_at("knock", _door_hinge.global_position)
	await Cutscene.wait(0.7)
	_sweaty.position = Vector3(-2.7, 0, DOOR_Z)
	_sweaty.visible = true
	_sweaty.face_toward(_player.global_position)
	var door_tw := create_tween()
	door_tw.tween_property(_door_hinge, "rotation:y", -PI * 0.55, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Audio.play_sfx_at("thud", _door_hinge.global_position, -2.0)
	Cutscene.shake(0.05, 0.35)
	await Cutscene.cam_to(Transform3D(Basis.IDENTITY, Vector3(1.4, 1.7, 3.1)).looking_at(Vector3(-1.6, 1.1, 1.3), Vector3.UP), 66.0, 0.9)
	var end_pos := Vector3(0.0, 0.0, 1.45)
	var walk := create_tween()
	walk.tween_property(_sweaty, "position", end_pos, 1.7).set_trans(Tween.TRANS_SINE)
	await Cutscene.wait(1.7)
	walk.kill()
	_sweaty.position = end_pos                                  # end-state (also reached when skipped)
	_sweaty.face_toward(_player.global_position)
	_door_hinge.rotation.y = -PI * 0.55
	await Cutscene.cam_to(Transform3D(Basis.IDENTITY, Vector3(0.7, 1.75, 2.35)).looking_at(Vector3(0.0, 1.65, 1.45), Vector3.UP), 48.0, 0.8)
	await Dialogue.play("ch01_intro")
	_letter.global_position = _sweaty.global_position + Vector3(0.0, 1.35, 0.55)
	_letter.visible = true
	_letter.enabled = true
	Game.set_flag("ch01_sweaty_entered")
	Cutscene.letterbox(false, 0.4)


func _read_letter() -> void:
	Cutscene.begin("ch01_letter", false)
	_letter.visible = false
	_letter_ui = LetterUI.new()
	add_child(_letter_ui)
	_letter_ui.open()
	await _letter_ui.closed
	_letter_ui.queue_free()
	_letter_ui = null
	await Cutscene.end()
	Game.set_flag("ch01_letter_read")


## Timed kick: up to three sweeps, then the canon kick lands whatever happened (it can never be failed out of).
func _boot_kick() -> void:
	_kick_meter = KickMeter.new()
	add_child(_kick_meter)
	var misses := 0
	while true:
		await get_tree().create_timer(0.35).timeout
		_kick_meter.start(1.5, 0.62, 0.11)
		var hit: bool = await _kick_meter.resolved
		if hit or misses >= 2:
			break
		misses += 1
		Events.show_message.emit("Your boot finds only air. Again!" if misses == 1 else "Closer. The old hoot is still there. Again!")
	_kick_meter.queue_free()
	_kick_meter = null
	await _swing_boot()
	Audio.play_sfx_at("thud", _sweaty.global_position, 0.0, 0.8)
	Cutscene.begin("ch01_kick", false)
	Game.add_flea(FLEA_KICK, "boot-kick")
	await Cutscene.cam_to(Transform3D(Basis.IDENTITY, Vector3(1.2, 1.7, 3.0)).looking_at(Vector3(-1.2, 1.0, 1.4), Vector3.UP), 62.0, 0.5)
	var fly := create_tween()
	fly.tween_property(_sweaty, "position", Vector3(-2.7, 0.0, DOOR_Z), 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	Audio.play_sfx_at("whoosh", _sweaty.global_position)
	await Dialogue.play("ch01_kick")
	fly.kill()
	_sweaty.visible = false
	_door_hinge.rotation.y = 0.0
	Game.set_flag("ch01_kicked")
	await Cutscene.end()


func _swing_boot() -> void:
	if _boot == null:
		_boot = Node3D.new()
		var leather := PropUtil.mat(Color(0.25, 0.16, 0.1), 0.0, 0.7)
		PropUtil.add_mesh(_boot, _box(Vector3(0.14, 0.12, 0.34)), leather, Vector3(0, 0, 0), "Foot")
		PropUtil.add_mesh(_boot, _box(Vector3(0.12, 0.3, 0.12)), leather, Vector3(0, 0.16, 0.12), "Shaft")
		PropUtil.add_mesh(_boot, _box(Vector3(0.15, 0.03, 0.36)), PropUtil.mat(Color(0.08, 0.06, 0.05)), Vector3(0, -0.07, 0), "Sole")
		(_player.get_node("Head/Camera3D") as Node3D).add_child(_boot)
	_boot.position = Vector3(0.18, -0.75, -0.2)
	_boot.rotation_degrees = Vector3(-20, 0, 0)
	_boot.visible = true
	var tw := create_tween()
	tw.tween_property(_boot, "position", Vector3(0.1, -0.35, -1.1), 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(_boot, "rotation_degrees", Vector3(35, 0, 0), 0.16)
	tw.tween_interval(0.12)
	await tw.finished
	_boot.visible = false


## Cutscene: the kitchen cut-away line, then the closet becomes available.
func _kitchen_body() -> void:
	await Cutscene.fade_out(0.5)
	await Dialogue.play("ch01_broom")
	_closet.enabled = true
	Game.set_flag("ch01_kitchen")
	await Cutscene.fade_in(0.5)


func _on_closet_used(_p: Node3D) -> void:
	if _closet_open:
		return
	_closet_open = true
	var tw := create_tween()
	tw.tween_property(_closet_hinge, "rotation:y", -PI * 0.6, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Audio.play_sfx_at("door_creak", _closet_hinge.global_position)
	_broom.visible = true
	_broom.enabled = true
	_broom.collision_layer = Interactable.INTERACT_LAYER
	_closet.enabled = false


func _on_broom_used(_p: Node3D) -> void:
	_broom.visible = false
	_broom.enabled = false
	_broom.collision_layer = 0
	_has_broom = true
	_hold_broom()
	Audio.play_sfx("pickup")
	Game.set_flag("ch01_has_broom")


func _hold_broom() -> void:
	_held_broom = Node3D.new()
	var wood := PropUtil.mat(Color(0.62, 0.45, 0.25), 0.0, 0.8)
	var handle := CylinderMesh.new()
	handle.top_radius = 0.014
	handle.bottom_radius = 0.014
	handle.height = 1.3
	var h := PropUtil.add_mesh(_held_broom, handle, wood, Vector3.ZERO, "Handle")
	h.rotation_degrees = Vector3(90, 0, 0)               # handle points forward (-Z)
	PropUtil.add_mesh(_held_broom, _box(Vector3(0.24, 0.1, 0.06)), PropUtil.mat(Color(0.75, 0.62, 0.3), 0.0, 0.95), Vector3(0, -0.02, 0.62), "Bristles")
	_held_broom.position = Vector3(0.28, -0.3, -0.55)
	(_player.get_node("Head/Camera3D") as Node3D).add_child(_held_broom)


## Two thrusts into the TV. First: the song stops flat and the screen goes black. Second: it topples.
func _tv_two_hits() -> void:
	_tv.prompt = "Thrust the handle"
	_tv.message = ""
	_tv.enabled = true
	while _tv_hits < 2:
		await _tv.used
		if not _has_broom:
			continue
		_tv_hits += 1
		await _thrust()
		Game.add_flea(FLEA_HIT, "smashed the TV")
		if _tv_hits == 1:
			_tv_go_black()
			await Dialogue.play("ch01_tv1")
		else:
			_tv_topple()
			Cutscene.shake(0.08, 0.5)
			await Dialogue.play("ch01_tv2")
	_tv.enabled = false
	Game.set_flag("ch01_tv_smashed")


func _thrust() -> void:
	var tw := create_tween()
	tw.tween_property(_held_broom, "position", Vector3(0.1, -0.2, -1.5), 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.08)
	tw.tween_property(_held_broom, "position", Vector3(0.28, -0.3, -0.55), 0.25)
	Audio.play_sfx_at("thud", _tv.global_position, 0.0, 0.7)
	await tw.finished


func _tv_go_black() -> void:
	if _flicker != null and _flicker.is_valid():
		_flicker.kill()
	var screen_mat := _tv_screen.material_override as StandardMaterial3D
	screen_mat.emission_energy_multiplier = 0.0
	screen_mat.albedo_texture = null
	screen_mat.emission_texture = null
	screen_mat.albedo_color = Color(0.02, 0.02, 0.025)
	_tv_light.visible = false
	for c: Character in [_elsa, _mary, _frank]:
		c.set_expression("worried")
	Audio.play_sfx_at("glass_clink", _tv.global_position, -6.0)
	Game.set_flag("ch01_tv_black")


func _tv_topple() -> void:
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_tv_body, "rotation:x", 1.45, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(_tv_body, "position:y", -0.45, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(_tv_body, "position:z", 0.55, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(func() -> void: Audio.play_sfx_at("thud", _tv.global_position, 3.0, 0.5))
	Game.set_flag("ch01_tv_fallen")


## Cutscene: the closing line. Everything it changes is set in the body so a skip cannot lose it.
func _ending_body() -> void:
	await Cutscene.wait(0.6)
	await Dialogue.play("ch01_end")
	await Cutscene.fade_out(1.2)
	Game.set_flag("ch01_done")


# ------------------------------------------------------------------ building

func _box(size: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = size
	return b


## A static, solid (world layer) box with a mesh; returns the body.
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


## An Interactable with a box collider at `pos`, with a funny `message`.
func _interactable(node_name: String, pos: Vector3, size: Vector3, prompt_text: String, msg: String, parent: Node = null) -> Interactable:
	var it := Interactable.new()
	it.name = node_name
	it.prompt = prompt_text
	it.message = msg
	it.position = pos
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	cs.shape = shape
	it.add_child(cs)
	(parent if parent != null else self).add_child(it)
	return it


func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.03, 0.04, 0.09)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.32, 0.38, 0.62)         # cold blue night
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)


func _build_room() -> void:
	var wall := PropUtil.mat(Color(0.46, 0.52, 0.56), 0.0, 0.95)
	var floor_mat := PropUtil.mat(Color(0.34, 0.22, 0.14), 0.0, 0.7)
	var ceil_mat := PropUtil.mat(Color(0.7, 0.7, 0.68), 0.0, 1.0)
	_solid(Vector3(ROOM_W + 0.4, 0.2, ROOM_D + 0.4), Vector3(0, -0.1, 0), floor_mat, "Floor")
	_solid(Vector3(ROOM_W + 0.4, 0.2, ROOM_D + 0.4), Vector3(0, ROOM_H + 0.1, 0), ceil_mat, "Ceiling")
	_solid(Vector3(ROOM_W + 0.2, ROOM_H, 0.2), Vector3(0, ROOM_H * 0.5, -ROOM_D * 0.5 - 0.1), wall, "WallNorth")
	_solid(Vector3(ROOM_W + 0.2, ROOM_H, 0.2), Vector3(0, ROOM_H * 0.5, ROOM_D * 0.5 + 0.1), wall, "WallSouth")
	# West wall with a doorway (z 0.95..1.85, 2.0 m high)
	var wx := -ROOM_W * 0.5 - 0.1
	_solid(Vector3(0.2, ROOM_H, (0.95 - -ROOM_D * 0.5)), Vector3(wx, ROOM_H * 0.5, (-ROOM_D * 0.5 + 0.95) * 0.5), wall, "WallWestA")
	_solid(Vector3(0.2, ROOM_H, (ROOM_D * 0.5 - 1.85)), Vector3(wx, ROOM_H * 0.5, (1.85 + ROOM_D * 0.5) * 0.5), wall, "WallWestB")
	_solid(Vector3(0.2, ROOM_H - 2.0, 0.9), Vector3(wx, 2.0 + (ROOM_H - 2.0) * 0.5, DOOR_Z), wall, "WallWestLintel")
	# East wall with a window (z -0.3..1.3, y 1.0..2.1)
	var ex := ROOM_W * 0.5 + 0.1
	_solid(Vector3(0.2, ROOM_H, (-0.3 - -ROOM_D * 0.5)), Vector3(ex, ROOM_H * 0.5, (-ROOM_D * 0.5 - 0.3) * 0.5), wall, "WallEastA")
	_solid(Vector3(0.2, ROOM_H, (ROOM_D * 0.5 - 1.3)), Vector3(ex, ROOM_H * 0.5, (1.3 + ROOM_D * 0.5) * 0.5), wall, "WallEastB")
	_solid(Vector3(0.2, 1.0, 1.6), Vector3(ex, 0.5, 0.5), wall, "WindowSill")
	_solid(Vector3(0.2, ROOM_H - 2.1, 1.6), Vector3(ex, 2.1 + (ROOM_H - 2.1) * 0.5, 0.5), wall, "WindowHead")
	# Night outside the window: a deep-blue backdrop with a pale moon (a plain disc; the eye comes much later)
	var sky := MeshInstance3D.new()
	var plane := QuadMesh.new()
	plane.size = Vector2(8, 5)
	sky.mesh = plane
	sky.material_override = PropUtil.mat(Color(0.05, 0.08, 0.2), 0.0, 1.0, Color(0.1, 0.16, 0.38), 1.0)
	sky.position = Vector3(ex + 1.5, 1.6, 0.5)
	sky.rotation_degrees = Vector3(0, -90, 0)
	add_child(sky)
	var moon := MeshInstance3D.new()
	var disc := SphereMesh.new()
	disc.radius = 0.35
	disc.height = 0.7
	moon.mesh = disc
	moon.material_override = PropUtil.mat(Color(0.9, 0.92, 0.98), 0.0, 0.9, Color(0.85, 0.9, 1.0), 1.4)
	moon.position = Vector3(ex + 1.4, 2.0, 0.2)
	add_child(moon)
	# Window frame
	var frame := PropUtil.mat(Color(0.8, 0.78, 0.72), 0.0, 0.6)
	for p: Array in [[Vector3(0.12, 0.08, 1.7), Vector3(ex - 0.08, 1.0, 0.5)], [Vector3(0.12, 0.08, 1.7), Vector3(ex - 0.08, 2.1, 0.5)],
			[Vector3(0.12, 1.2, 0.08), Vector3(ex - 0.08, 1.55, -0.3)], [Vector3(0.12, 1.2, 0.08), Vector3(ex - 0.08, 1.55, 1.3)],
			[Vector3(0.1, 1.1, 0.04), Vector3(ex - 0.08, 1.55, 0.5)]]:
		PropUtil.add_mesh(self, _box(p[0] as Vector3), frame, p[1] as Vector3, "WindowFrame")


func _build_furniture() -> void:
	var fabric := PropUtil.mat(Color(0.5, 0.28, 0.22), 0.0, 0.95)
	var wood := PropUtil.mat(Color(0.3, 0.19, 0.1), 0.0, 0.6)
	# Rug
	var rug := CylinderMesh.new()
	rug.top_radius = 1.9
	rug.bottom_radius = 1.9
	rug.height = 0.02
	PropUtil.add_mesh(self, rug, PropUtil.mat(Color(0.55, 0.4, 0.28), 0.0, 1.0), Vector3(0, 0.01, -0.8), "Rug")
	# Sofa (seat 0.5 m high, back 0.95 m) facing -Z, so the family watches the TV
	_solid(Vector3(3.0, 0.5, 0.9), Vector3(0, 0.25, -0.6), fabric, "SofaSeat")
	_solid(Vector3(3.0, 0.5, 0.2), Vector3(0, 0.75, -0.2), fabric, "SofaBack")
	_solid(Vector3(0.22, 0.65, 0.9), Vector3(-1.4, 0.6, -0.6), fabric, "SofaArmL")
	_solid(Vector3(0.22, 0.65, 0.9), Vector3(1.4, 0.6, -0.6), fabric, "SofaArmR")
	# Coffee table + a bowl of something
	_solid(Vector3(1.1, 0.4, 0.55), Vector3(0, 0.2, -1.7), wood, "CoffeeTable")
	var bowl := CylinderMesh.new()
	bowl.top_radius = 0.13
	bowl.bottom_radius = 0.08
	bowl.height = 0.07
	PropUtil.add_mesh(self, bowl, PropUtil.mat(Color(0.8, 0.8, 0.75), 0.0, 0.4), Vector3(0, 0.435, -1.7), "Bowl")
	var table_it := _interactable("CoffeeTableInteract", Vector3(0, 0.3, -1.7), Vector3(1.2, 0.6, 0.65), "Look at table", "A bowl, a table, a quiet evening. Nothing here could possibly go wrong.")
	table_it.range = 3.2
	# Pictures either side of the TV
	for x in [-1.9, 1.9]:
		PropUtil.add_mesh(self, _box(Vector3(0.6, 0.45, 0.04)), PropUtil.mat(Color(0.2, 0.12, 0.06)), Vector3(x, 1.6, -ROOM_D * 0.5 + 0.03), "Frame")
		PropUtil.add_mesh(self, _box(Vector3(0.5, 0.35, 0.045)), PropUtil.mat(Color(0.55, 0.62, 0.7), 0.0, 0.8), Vector3(x, 1.6, -ROOM_D * 0.5 + 0.035), "Picture")
	var pics := _interactable("PictureInteract", Vector3(-1.9, 1.6, -ROOM_D * 0.5 + 0.2), Vector3(0.7, 0.55, 0.3), "Look at picture", "Wisconsin, framed. It is very flat and very cold, as promised.")
	pics.range = 5.0
	# Floor lamp (warm amber)
	var pole := CylinderMesh.new()
	pole.top_radius = 0.02
	pole.bottom_radius = 0.02
	pole.height = 1.5
	PropUtil.add_mesh(self, pole, PropUtil.mat(Color(0.25, 0.2, 0.12), 0.6, 0.4), Vector3(-2.45, 0.75, -2.8), "LampPole")
	var shade := CylinderMesh.new()
	shade.top_radius = 0.16
	shade.bottom_radius = 0.28
	shade.height = 0.34
	PropUtil.add_mesh(self, shade, PropUtil.mat(Color(0.95, 0.75, 0.4), 0.0, 0.9, Color(1.0, 0.7, 0.3), 1.6), Vector3(-2.45, 1.62, -2.8), "LampShade")
	var lamp := _interactable("LampInteract", Vector3(-2.45, 1.0, -2.8), Vector3(0.6, 1.8, 0.6), "Look at lamp", "A lamp, glowing amber. It is the warmest thing in Wisconsin tonight.")
	lamp.range = 5.0
	var window_it := _interactable("WindowInteract", Vector3(ROOM_W * 0.5 - 0.15, 1.55, 0.5), Vector3(0.3, 1.2, 1.6), "Look out the window", "Night. A very large moon sits over the snow, being enormous and doing nothing at all.")
	window_it.range = 5.0


func _build_tv() -> void:
	_tv = Interactable.new()
	_tv.name = "TV"
	_tv.position = Vector3(0, 0, -ROOM_D * 0.5 + 0.45)
	_tv.prompt = "Watch TV"
	_tv.message = "The annual rerun is on. The hills are alive. Nobody moves."
	_tv.range = 5.0
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.0, 1.25, 0.7)
	cs.shape = shape
	cs.position = Vector3(0, 0.62, 0)
	_tv.add_child(cs)
	add_child(_tv)
	var wood := PropUtil.mat(Color(0.28, 0.18, 0.1), 0.0, 0.6)
	PropUtil.add_mesh(_tv, _box(Vector3(1.1, 0.55, 0.6)), wood, Vector3(0, 0.275, 0), "Stand")
	# The CRT hangs off a pivot so the topple can tip it forward (+Z) off the stand
	_tv_body = Node3D.new()
	_tv_body.name = "Crt"
	_tv_body.position = Vector3(0, 0.55, 0)
	_tv.add_child(_tv_body)
	var shell := PropUtil.mat(Color(0.12, 0.11, 0.11), 0.0, 0.5)
	PropUtil.add_mesh(_tv_body, _box(Vector3(0.84, 0.64, 0.58)), shell, Vector3(0, 0.32, 0), "Shell")
	PropUtil.add_mesh(_tv_body, _box(Vector3(0.64, 0.5, 0.12)), shell, Vector3(0, 0.32, -0.3), "Tube")
	_tv_screen = MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(0.62, 0.46)
	_tv_screen.mesh = quad
	var screen_mat := StandardMaterial3D.new()
	screen_mat.albedo_color = Color(0.5, 0.65, 0.45)
	screen_mat.emission_enabled = true
	screen_mat.emission = Color(0.55, 0.72, 0.6)
	screen_mat.emission_energy_multiplier = 0.55
	var grad := Gradient.new()                                   # pastiche hills: pale sky over green
	grad.colors = PackedColorArray([Color(0.78, 0.88, 0.95), Color(0.55, 0.7, 0.5), Color(0.3, 0.5, 0.3)])
	grad.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill_from = Vector2(0.5, 0.0)
	gt.fill_to = Vector2(0.5, 1.0)
	screen_mat.albedo_texture = gt
	screen_mat.emission_texture = gt
	_tv_screen.material_override = screen_mat
	_tv_screen.position = Vector3(0, 0.34, 0.295)
	_tv_body.add_child(_tv_screen)
	var label := Label3D.new()
	label.text = "RCA"
	label.font_size = 36
	label.pixel_size = 0.0025
	label.position = Vector3(0, 0.04, 0.295)
	label.modulate = Color(0.8, 0.78, 0.7)
	_tv_body.add_child(label)
	_tv_light = OmniLight3D.new()
	_tv_light.position = Vector3(0, 0.9, 0.9)
	_tv_light.light_color = Color(0.7, 0.85, 1.0)
	_tv_light.light_energy = 1.1
	_tv_light.omni_range = 5.0
	_tv.add_child(_tv_light)
	_flicker = create_tween().set_loops()
	_flicker.tween_property(_tv_light, "light_energy", 0.8, 0.9).set_trans(Tween.TRANS_SINE)
	_flicker.tween_property(_tv_light, "light_energy", 1.3, 0.7).set_trans(Tween.TRANS_SINE)


func _build_family() -> void:
	# Seated by sinking the legs into the sofa seat; all three stare at the screen (rotated to face -Z)
	_elsa = ElsaRay.new()
	_elsa.position = Vector3(0.0, -0.38, -0.55)
	_mary = MarySue.new()
	_mary.position = Vector3(-0.95, -0.12, -0.55)
	_frank = Frank.new()
	_frank.position = Vector3(0.95, 0.0, -0.55)
	for c: Character in [_elsa, _mary, _frank]:
		c.rotation.y = PI
		add_child(c)
		c.set_expression("neutral")
	var notes := {
		_elsa: ["ElsaInteract", "Elsa Ray", "Elsa Ray does not look away from the screen. She has seen this a hundred times and loves it a hundred times."],
		_mary: ["MaryInteract", "Mary Sue", "Mary Sue is nearly thirteen and entirely hypnotized."],
		_frank: ["FrankInteract", "Frank", "Frank watches the screen. Frank does not blink. Frank is, as ever, simply here."],
	}
	for c: Character in notes:
		var n: Array = notes[c]
		var it := _interactable(n[0], c.position + Vector3(0, 1.1, 0.0), Vector3(0.6, 1.0, 0.5), "Look at %s" % n[1], n[2])
		it.range = 5.0


func _build_door_and_closet() -> void:
	# Front door on the west wall; hinge at z=1.85, panel extends to z=0.95
	_door_hinge = Node3D.new()
	_door_hinge.position = Vector3(-ROOM_W * 0.5, 0, 1.85)
	add_child(_door_hinge)
	PropUtil.add_mesh(_door_hinge, _box(Vector3(0.06, 2.0, 0.9)), PropUtil.mat(Color(0.32, 0.2, 0.12), 0.0, 0.6), Vector3(0, 1.0, -0.45), "DoorPanel")
	PropUtil.add_mesh(_door_hinge, _box(Vector3(0.08, 0.08, 0.08)), PropUtil.mat(Color(0.85, 0.7, 0.3), 0.8, 0.3), Vector3(0.04, 1.0, -0.8), "Knob")
	# Closet: a cabinet against the east wall; its door swings out to show the broom
	_solid(Vector3(0.5, 2.2, 1.0), Vector3(ROOM_W * 0.5 - 0.25, 1.1, -2.6), PropUtil.mat(Color(0.4, 0.34, 0.28), 0.0, 0.9), "Cabinet")
	_closet_hinge = Node3D.new()
	_closet_hinge.position = Vector3(ROOM_W * 0.5 - 0.5, 0, -3.06)
	add_child(_closet_hinge)
	PropUtil.add_mesh(_closet_hinge, _box(Vector3(0.04, 2.1, 0.92)), PropUtil.mat(Color(0.5, 0.42, 0.34), 0.0, 0.7), Vector3(-0.02, 1.05, 0.46), "ClosetDoor")
	_closet = _interactable("ClosetInteract", Vector3(ROOM_W * 0.5 - 0.5, 1.1, -2.6), Vector3(0.3, 2.0, 0.9), "Open the closet", "The closet door swings open with the confidence of a door that has been waiting all night.")
	_closet.enabled = false
	_closet.used.connect(_on_closet_used)
	# The broom, standing behind the closet door
	_broom = Interactable.new()
	_broom.name = "Broom"
	_broom.prompt = "Take the broom"
	_broom.message = "A broom. You take it by the handle, like a man with a plan."
	_broom.position = Vector3(ROOM_W * 0.5 - 0.62, 0, -2.6)
	var bcs := CollisionShape3D.new()
	var bshape := BoxShape3D.new()
	bshape.size = Vector3(0.3, 1.5, 0.3)
	bcs.shape = bshape
	bcs.position = Vector3(0, 0.75, 0)
	_broom.add_child(bcs)
	var bh := CylinderMesh.new()
	bh.top_radius = 0.014
	bh.bottom_radius = 0.014
	bh.height = 1.3
	PropUtil.add_mesh(_broom, bh, PropUtil.mat(Color(0.62, 0.45, 0.25), 0.0, 0.8), Vector3(0, 0.85, 0), "Handle")
	PropUtil.add_mesh(_broom, _box(Vector3(0.24, 0.2, 0.06)), PropUtil.mat(Color(0.75, 0.62, 0.3), 0.0, 0.95), Vector3(0, 0.1, 0), "Bristles")
	add_child(_broom)
	_broom.visible = false
	_broom.enabled = false
	_broom.collision_layer = 0
	_broom.used.connect(_on_broom_used)


func _build_sweaty_man() -> void:
	_sweaty = SweatyMan.new()
	_sweaty.visible = false
	add_child(_sweaty)
	# The damp letter he produces from his sleeve (hidden until the entrance cutscene ends)
	_letter = Interactable.new()
	_letter.name = "Letter"
	_letter.prompt = "Take the letter"
	_letter.message = ""
	_letter.range = 4.0
	var lcs := CollisionShape3D.new()
	var lshape := BoxShape3D.new()
	lshape.size = Vector3(0.4, 0.3, 0.3)
	lcs.shape = lshape
	_letter.add_child(lcs)
	PropUtil.add_mesh(_letter, _box(Vector3(0.22, 0.3, 0.01)), PropUtil.mat(Color(0.93, 0.86, 0.66), 0.0, 0.8, Color(1.0, 0.8, 0.4), 0.35), Vector3.ZERO, "Paper")
	add_child(_letter)
	_letter.visible = false
	_letter.enabled = false


func _build_lights() -> void:
	var amber := OmniLight3D.new()
	amber.position = Vector3(-2.2, 1.6, -2.4)
	amber.light_color = Color(1.0, 0.72, 0.38)
	amber.light_energy = 2.0
	amber.omni_range = 6.5
	add_child(amber)
	var moonlight := OmniLight3D.new()
	moonlight.position = Vector3(2.4, 1.7, 0.5)
	moonlight.light_color = Color(0.55, 0.68, 1.0)
	moonlight.light_energy = 1.4
	moonlight.omni_range = 5.5
	add_child(moonlight)
	var fill := OmniLight3D.new()                                # a faint ceiling fill so the back of the room is not pure black
	fill.position = Vector3(0, 2.5, 1.5)
	fill.light_color = Color(0.7, 0.75, 0.9)
	fill.light_energy = 0.35
	fill.omni_range = 7.0
	add_child(fill)
