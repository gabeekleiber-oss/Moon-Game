extends Node3D
## F6 this scene to inspect the four surface effects. Keys 0-5 change Unreality bands.
const UnrealSurfaceScript = preload("res://scenes/assets/unreal_surface.gd")
const EFFECTS: Array[String] = ["damp", "rot", "swim", "crawl"]
const COLORS: Array[Color] = [Color(0.55, 0.48, 0.38), Color(0.48, 0.42, 0.34), Color(0.36, 0.48, 0.58), Color(0.58, 0.54, 0.46)]
var _time := 0.0
var _level := 0.65
var _status: Label3D


func _ready() -> void:
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.035, 0.04, 0.05)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.34, 0.36, 0.40)
	env.ambient_light_energy = 0.8
	environment.environment = env
	add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-42.0, -25.0, 0.0)
	light.light_energy = 2.2
	add_child(light)
	var camera := Camera3D.new()
	camera.position = Vector3(0.0, 1.0, 8.5)
	camera.look_at(Vector3(0.0, -0.1, 0.0), Vector3.UP)
	add_child(camera)
	camera.current = true
	var floor := MeshInstance3D.new()
	var floor_mesh := BoxMesh.new()
	floor_mesh.size = Vector3(10.0, 0.15, 3.0)
	floor.mesh = floor_mesh
	floor.position = Vector3(0.0, -1.05, 0.0)
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.12, 0.12, 0.13)
	floor_mat.roughness = 0.92
	floor.material_override = floor_mat
	add_child(floor)
	for i in EFFECTS.size():
		var base := StandardMaterial3D.new()
		base.albedo_color = COLORS[i]
		base.roughness = 0.78
		var ball := MeshInstance3D.new()
		var mesh := SphereMesh.new()
		mesh.radius = 0.68
		mesh.height = 1.36
		ball.mesh = mesh
		ball.position = Vector3((float(i) - 1.5) * 1.8, -0.1, 0.0)
		ball.material_override = UnrealSurfaceScript.make(EFFECTS[i], base)
		add_child(ball)
		var label := Label3D.new()
		label.text = EFFECTS[i].to_upper()
		label.position = ball.position + Vector3(0.0, 1.0, 0.0)
		label.font_size = 48
		label.pixel_size = 0.004
		add_child(label)
	_status = Label3D.new()
	_status.text = "UNREALITY: 0.65  |  KEYS 0-5 CHANGE BAND"
	_status.position = Vector3(0.0, 1.8, 0.0)
	_status.font_size = 38
	_status.pixel_size = 0.004
	add_child(_status)
	_set_level(_level)


func _process(delta: float) -> void:
	_time += delta
	RenderingServer.global_shader_parameter_set("unreal_time", _time)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var key := (event as InputEventKey).keycode
		if key >= KEY_0 and key <= KEY_5:
			var index := key - KEY_0
			_set_level(float(index) / 5.0)


func _set_level(value: float) -> void:
	_level = clampf(value, 0.0, 1.0)
	RenderingServer.global_shader_parameter_set("unreality", _level)
	if is_instance_valid(_status):
		_status.text = "UNREALITY: %.2f  |  KEYS 0-5 CHANGE BAND" % _level
