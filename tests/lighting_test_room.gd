extends Node3D
## Standalone lighting study for inspecting the project's five environment moods.
## Run this scene directly, or set the exported preset before launch in the Inspector.

@export_enum("night_dark", "dawn", "dream", "day", "fire") var preset: String = "night_dark"

const Lighting = preload("res://scenes/world/lighting/lighting_library.gd")

func _ready() -> void:
	var world := WorldEnvironment.new()
	world.name = "WorldEnvironment"
	world.environment = Lighting.make_environment(preset)
	add_child(world)

	var floor := _box("Floor", Vector3(0.0, -0.1, 0.0), Vector3(10.0, 0.2, 10.0), Color(0.24, 0.21, 0.18))
	var back_wall := _box("BackWall", Vector3(0.0, 2.0, -4.8), Vector3(10.0, 4.0, 0.2), Color(0.30, 0.27, 0.23))
	var side_wall := _box("SideWall", Vector3(-4.8, 2.0, 0.0), Vector3(0.2, 4.0, 10.0), Color(0.22, 0.24, 0.28))
	add_child(floor)
	add_child(back_wall)
	add_child(side_wall)

	var practical := Lighting.practical_warm_light(true)
	practical.name = "VisibleSource_Practical"
	practical.position = Vector3(-2.0, 2.5, -1.0)
	add_child(practical)
	var window_light := Lighting.window_cool_light(false)
	window_light.name = "WindowFill_NoShadows"
	window_light.position = Vector3(2.8, 2.7, -2.0)
	window_light.rotation_degrees = Vector3(-12.0, -22.0, 0.0)
	add_child(window_light)
	var tv := Lighting.tv_glow()
	tv.name = "TV_Glow_NoShadows"
	tv.position = Vector3(0.0, 1.0, 2.4)
	add_child(tv)

	var moon := DirectionalLight3D.new()
	moon.name = "Moon_Key"
	moon.rotation_degrees = Vector3(-42.0, -28.0, 0.0)
	moon.light_color = Color(0.68, 0.76, 1.0)
	moon.light_energy = 0.35
	moon.shadow_enabled = true
	add_child(moon)

	var camera := Camera3D.new()
	camera.name = "StudyCamera"
	camera.position = Vector3(0.0, 2.0, 7.5)
	camera.rotation_degrees = Vector3(-8.0, 0.0, 0.0)
	camera.current = true
	add_child(camera)


func _box(node_name: String, at: Vector3, size: Vector3, tint: Color) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	mesh_instance.position = at
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	material.roughness = 0.82
	mesh_instance.material_override = material
	return mesh_instance
