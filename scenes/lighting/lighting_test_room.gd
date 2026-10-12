class_name LightingTestRoom
extends Node3D
## The S-01 lighting test room: a 6 x 5 x 3 m room with one window, a table with a lamp and a candle, a TV and a few boxes that catch
## shadows. Everything is code-built (PLACEHOLDER greybox with plain materials) so it runs with no assets. It exercises every look and
## every light helper together and reports the light budget. Walk it with WASD/mouse (the Player scene).
## Keys (dev tool only; the game itself has no HUD): 1-5 looks (night_dark, dawn, dream, day, fire) | L lamp | C candle | T TV |
## W window | M moon | U cycle Unreality 0 / .3 / .6 / .9 | B print the light budget | Q cycle quality (high/medium/low).
## F6 to run standalone; a screenshot uses `tests/_lighting_shot.tscn`.

@export var look: String = "night_dark"
## False in screenshot/test use: the caller supplies its own camera.
@export var use_player: bool = true

const SIZE := Vector3(6.0, 3.0, 5.0)
const LOOK_KEYS := {KEY_1: "night_dark", KEY_2: "dawn", KEY_3: "dream", KEY_4: "day", KEY_5: "fire"}
## Which lights each look switches on by default (toggle any with the keys).
const LOOK_LIGHTS := {
	"night_dark": ["moon", "tv", "lamp"],
	"dawn": ["window", "candle"],
	"dream": ["lamp", "candle"],
	"day": ["window"],
	"fire": ["candle"],
}
const UNREALITY_STEPS: Array[float] = [0.0, 0.3, 0.6, 0.9]

var mood: MoodEnvironment
var lamp: PracticalLamp
var candle: CandleLight
var tv: TVLight
var window: WindowLight
var shaft: LightShaft
var moon: MoonLight
var player: Node3D
var _u_step: int = 0
var _q_step: int = 0
var _wall_mat: StandardMaterial3D
var _floor_mat: StandardMaterial3D
var _wood_mat: StandardMaterial3D


func _ready() -> void:
	_wall_mat = _mat(Color(0.74, 0.70, 0.62), 0.92)     # PLACEHOLDER materials: plain PBR colours until S-02's library lands
	_floor_mat = _mat(Color(0.34, 0.24, 0.16), 0.55)
	_wood_mat = _mat(Color(0.28, 0.19, 0.12), 0.7)
	_build_room()
	_build_props()
	mood = MoodEnvironment.new()
	mood.name = "Mood"
	mood.look = look
	add_child(mood)
	window = WindowLight.new()
	window.name = "WindowLight"
	window.position = Vector3(0.0, 1.6, -SIZE.z * 0.5 - 0.7)
	window.rotation_degrees = Vector3(-12.0, 180.0, 0.0)    # -Z of the node points into the room (+Z), tilted down so the cone does not fill the ceiling
	add_child(window)
	shaft = LightShaft.new()
	shaft.name = "Shaft"
	shaft.position = Vector3(0.0, 1.6, -SIZE.z * 0.5)
	shaft.rotation_degrees = Vector3(0.0, 180.0, 0.0)
	add_child(shaft)
	moon = MoonLight.new()
	moon.name = "MoonLight"
	moon.azimuth_deg = 180.0
	moon.elevation_deg = 35.0
	add_child(moon)
	lamp = PracticalLamp.new()
	lamp.name = "Lamp"
	lamp.wrong_id = "lamp_test_room"
	lamp.position = Vector3(-1.9, 1.15, -1.2)
	add_child(lamp)
	candle = CandleLight.new()
	candle.name = "Candle"
	candle.position = Vector3(-1.45, 0.9, -1.0)
	add_child(candle)
	tv = TVLight.new()
	tv.name = "TVLight"
	tv.position = Vector3(2.35, 1.0, 0.6)
	add_child(tv)
	if use_player:
		var scene := load("res://scenes/player/player.tscn") as PackedScene
		if scene != null:
			player = scene.instantiate() as Node3D
			player.position = Vector3(0.0, 0.1, 1.9)
			add_child(player)
	set_look(look)


## Switches the environment look and the default set of lights for it.
func set_look(look_name: String, seconds: float = 0.0) -> void:
	if not EnvPresets.names().has(look_name):
		return
	look = look_name
	mood.set_look(look_name, seconds)
	var on: Array = LOOK_LIGHTS[look_name]
	moon.visible = "moon" in on
	window.visible = "window" in on
	shaft.visible = "window" in on
	lamp.visible = "lamp" in on
	candle.visible = "candle" in on
	tv.visible = "tv" in on
	window.set_kind("dawn" if look_name == "dawn" else ("night" if look_name == "night_dark" else "day"))
	shaft.color = window.light.light_color if window.light != null else shaft.color


## Current light budget for `camera` (defaults to the viewport's camera): see LightBudget.
func budget(camera: Camera3D = null) -> Dictionary:
	var cam := camera if camera != null else get_viewport().get_camera_3d()
	if cam == null:
		return LightBudget.count(self)
	return LightBudget.in_view(cam, self)


func _unhandled_key_input(event: InputEvent) -> void:
	var k := event as InputEventKey
	if k == null or not k.pressed or k.echo:
		return
	if LOOK_KEYS.has(k.keycode):
		set_look(LOOK_KEYS[k.keycode], 1.0)
	match k.keycode:
		KEY_L: lamp.visible = not lamp.visible
		KEY_C: candle.visible = not candle.visible
		KEY_T: tv.visible = not tv.visible
		KEY_W:
			window.visible = not window.visible
			shaft.visible = window.visible
		KEY_M: moon.visible = not moon.visible
		KEY_U:
			_u_step = (_u_step + 1) % UNREALITY_STEPS.size()
			Unreality.force(UNREALITY_STEPS[_u_step])
		KEY_Q:
			_q_step = (_q_step + 1) % EnvPresets.QUALITIES.size()
			Game.settings["quality"] = EnvPresets.QUALITIES[_q_step]
		KEY_B: print("[lighting] ", LightBudget.describe(budget()))


func _build_room() -> void:
	var hx := SIZE.x * 0.5
	var hz := SIZE.z * 0.5
	_solid("Floor", Vector3(0, -0.05, 0), Vector3(SIZE.x + 0.6, 0.1, SIZE.z + 0.6), _floor_mat)
	_solid("Ceiling", Vector3(0, SIZE.y + 0.05, 0), Vector3(SIZE.x + 0.6, 0.1, SIZE.z + 0.6), _wall_mat)
	_solid("WallS", Vector3(0, SIZE.y * 0.5, hz + 0.15), Vector3(SIZE.x + 0.6, SIZE.y, 0.3), _wall_mat)
	_solid("WallW", Vector3(-hx - 0.15, SIZE.y * 0.5, 0), Vector3(0.3, SIZE.y, SIZE.z), _wall_mat)
	_solid("WallE", Vector3(hx + 0.15, SIZE.y * 0.5, 0), Vector3(0.3, SIZE.y, SIZE.z), _wall_mat)
	# North wall with a 1.4 x 1.4 m window opening (sill 0.9 m, WORLD_BIBLE scale) centred on x = 0.
	var wz := -hz - 0.15
	var gap := 1.4
	var side := (SIZE.x + 0.6 - gap) * 0.5
	_solid("WallN_L", Vector3(-(gap * 0.5 + side * 0.5), SIZE.y * 0.5, wz), Vector3(side, SIZE.y, 0.3), _wall_mat)
	_solid("WallN_R", Vector3(gap * 0.5 + side * 0.5, SIZE.y * 0.5, wz), Vector3(side, SIZE.y, 0.3), _wall_mat)
	_solid("WallN_Below", Vector3(0, 0.45, wz), Vector3(gap, 0.9, 0.3), _wall_mat)
	_solid("WallN_Above", Vector3(0, 2.3 + (SIZE.y - 2.3) * 0.5, wz), Vector3(gap, SIZE.y - 2.3, 0.3), _wall_mat)


func _build_props() -> void:
	_solid("Table", Vector3(-1.7, 0.375, -1.2), Vector3(1.2, 0.75, 0.7), _wood_mat)
	_solid("CentreBlock", Vector3(0.0, 0.4, -0.2), Vector3(1.4, 0.8, 0.7), _wood_mat)    # catches the window's shaft and shadow
	_solid("Sofa", Vector3(0.3, 0.35, 2.0), Vector3(2.0, 0.7, 0.9), _mat(Color(0.30, 0.34, 0.30), 0.95))
	_solid("TVStand", Vector3(2.55, 0.3, 0.6), Vector3(0.6, 0.6, 1.0), _wood_mat)
	_solid("TV", Vector3(2.55, 0.9, 0.6), Vector3(0.55, 0.6, 0.7), _mat(Color(0.05, 0.05, 0.06), 0.4))


func _solid(nm: String, pos: Vector3, size: Vector3, mat: StandardMaterial3D) -> StaticBody3D:
	var b := StaticBody3D.new()
	b.name = nm
	b.position = pos
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	b.add_child(mi)
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	cs.shape = bs
	b.add_child(cs)
	add_child(b)
	return b


func _mat(c: Color, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	return m
