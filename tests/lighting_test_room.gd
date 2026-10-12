extends Node3D
## Standalone lighting study for inspecting the project's five environment moods.
## Run this scene directly, or set the exported preset before launch in the Inspector.
## Geometry is deliberately code-built so the study remains asset-free and reproducible.

@export_enum("night_dark", "dawn", "dream", "day", "fire") var preset: String = "night_dark"

const Lighting = preload("res://scenes/world/lighting/lighting_library.gd")
const TvFlicker = preload("res://scenes/world/lighting/tv_flicker.gd")

func _ready() -> void:
	var world := WorldEnvironment.new()
	world.name = "WorldEnvironment"
	world.environment = Lighting.make_environment(preset)
	add_child(world)

	add_child(_box("Floor", Vector3(0.0, -0.1, 0.0), Vector3(10.0, 0.2, 10.0), Color(0.24, 0.21, 0.18)))
	add_child(_box("BackWall", Vector3(0.0, 2.0, -4.8), Vector3(10.0, 4.0, 0.2), Color(0.30, 0.27, 0.23)))
	add_child(_box("SideWall", Vector3(-4.8, 2.0, 0.0), Vector3(0.2, 4.0, 10.0), Color(0.22, 0.24, 0.28)))

	# A visible lamp shade and bulb make the warm practical source legible.
	add_child(_box("LampStand", Vector3(-2.0, 1.0, -1.0), Vector3(0.12, 2.0, 0.12), Color(0.16, 0.13, 0.10)))
	add_child(_box("LampShade", Vector3(-2.0, 2.2, -1.0), Vector3(0.62, 0.48, 0.62), Color(0.64, 0.48, 0.28)))
	var bulb_material := StandardMaterial3D.new()
	bulb_material.albedo_color = Color(1.0, 0.74, 0.42)
	bulb_material.emission_enabled = true
	bulb_material.emission = Color(1.0, 0.48, 0.16)
	bulb_material.emission_energy_multiplier = 1.3
	add_child(_sphere("LampBulb_VisibleSource", Vector3(-2.0, 2.0, -1.0), 0.13, bulb_material))

	var practical := Lighting.practical_warm_light(true)
	practical.name = "VisibleSource_PracticalLight"
	practical.position = Vector3(-2.0, 2.0, -1.0)
	add_child(practical)

	# The cool window source is aimed into the room and casts no dynamic shadow.
	var window_light := Lighting.window_cool_light(false)
	window_light.name = "WindowFill_NoShadows"
	window_light.position = Vector3(3.9, 2.7, -3.8)
	window_light.rotation_degrees = Vector3(-18.0, 42.0, 0.0)
	add_child(window_light)
	add_child(_box("WindowFrame", Vector3(4.35, 2.5, -4.62), Vector3(0.9, 1.5, 0.08), Color(0.12, 0.15, 0.20)))

	# A simple CRT model sits in front of the back wall, in the camera's view.
	add_child(_box("CRT_Case", Vector3(0.0, 0.85, -3.65), Vector3(1.55, 1.05, 0.55), Color(0.055, 0.06, 0.065)))
	var screen_material := StandardMaterial3D.new()
	screen_material.albedo_color = Color(0.08, 0.19, 0.34)
	screen_material.emission_enabled = true
	screen_material.emission = Color(0.08, 0.25, 0.62)
	screen_material.emission_energy_multiplier = 0.8
	add_child(_box_with_material("CRT_Screen_VisibleSource", Vector3(0.0, 0.9, -3.355), Vector3(1.28, 0.72, 0.025), screen_material))

	var tv := Lighting.tv_glow()
	tv.name = "TV_Glow_NoShadows"
	tv.position = Vector3(0.0, 1.0, -2.95)
	tv.set_script(TvFlicker)
	add_child(tv)

	var moon := Lighting.moon_light(true)
	moon.name = "Moon_Key"
	moon.rotation_degrees = Vector3(-42.0, -28.0, 0.0)
	add_child(moon)

	var camera := Camera3D.new()
	camera.name = "StudyCamera"
	camera.position = Vector3(0.0, 2.0, 7.5)
	camera.rotation_degrees = Vector3(-8.0, 0.0, 0.0)
	camera.current = true
	add_child(camera)


func _box(node_name: String, at: Vector3, size: Vector3, tint: Color) -> MeshInstance3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	material.roughness = 0.82
	return _box_with_material(node_name, at, size, material)


func _box_with_material(node_name: String, at: Vector3, size: Vector3, material: StandardMaterial3D) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	mesh_instance.position = at
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.material_override = material
	return mesh_instance


func _sphere(node_name: String, at: Vector3, radius: float, material: StandardMaterial3D) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	mesh_instance.position = at
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh_instance.mesh = mesh
	mesh_instance.material_override = material
	return mesh_instance
