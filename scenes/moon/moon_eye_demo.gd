extends Node3D
## F6 demo for MoonEye: eye opens, blinks at random, follows the mouse. Keys: O open, C close, B blink, P pupil narrow/wide.
## Reduced Motion (if the setting exists) turns off the random blinking.

var _moon: MoonEye
var _cam: Camera3D
var _timer: float = 3.0
var _wide: bool = true


func _ready() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.03, 0.04, 0.09)
	env.ambient_light_color = Color(0.4, 0.45, 0.6)
	env.ambient_light_energy = 0.6
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-20, 25, 0)
	add_child(sun)
	_moon = MoonEye.new()
	add_child(_moon)
	_cam = Camera3D.new()
	_cam.position = Vector3(0, 0, 28)
	add_child(_cam)
	_cam.make_current()
	await get_tree().create_timer(0.8).timeout
	_moon.open(1.6)


func _process(delta: float) -> void:
	var mp := get_viewport().get_mouse_position()
	var origin := _cam.project_ray_origin(mp)
	var dir := _cam.project_ray_normal(mp)
	_moon.look_at_point(origin + dir * 40.0, 0.12)
	_timer -= delta
	if _timer <= 0.0:
		_timer = randf_range(3.0, 6.0)
		if _moon.is_open() and not _reduced():
			_moon.blink()


func _unhandled_key_input(e: InputEvent) -> void:
	var k := e as InputEventKey
	if k == null or not k.pressed or k.echo:
		return
	match k.keycode:
		KEY_O: _moon.open(1.0)
		KEY_C: _moon.close(0.6)
		KEY_B: _moon.blink()
		KEY_P:
			_wide = not _wide
			_moon.set_pupil(1.0 if _wide else 0.0, 0.4)


func _reduced() -> bool:
	return bool(Game.settings.get("reduced_motion", false))
