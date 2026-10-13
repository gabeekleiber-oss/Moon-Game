extends Node3D
## Code-built first-person forearms and hands. Placeholder geometry can be replaced by licensed meshes later.

func _ready() -> void:
	var skin := StandardMaterial3D.new()
	skin.albedo_color = Color(0.54, 0.39, 0.30)
	skin.roughness = 0.86
	var sleeve := StandardMaterial3D.new()
	sleeve.albedo_color = Color(0.20, 0.21, 0.22)
	sleeve.roughness = 0.94
	_make_arm("LeftForearm", Vector3(-0.31, -0.44, -0.48), Vector3(0.0, 0.0, -22.0), sleeve)
	_make_hand("LeftHand", Vector3(-0.27, -0.28, -0.78), skin)
	_make_arm("RightForearm", Vector3(0.31, -0.44, -0.48), Vector3(0.0, 0.0, 22.0), sleeve)
	_make_hand("RightHand", Vector3(0.27, -0.28, -0.78), skin)


func _make_arm(label: String, pos: Vector3, rotation_deg: Vector3, material: Material) -> void:
	var arm := MeshInstance3D.new()
	arm.name = label
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.075
	mesh.height = 0.46
	arm.mesh = mesh
	arm.position = pos
	arm.rotation_degrees = rotation_deg
	arm.material_override = material
	add_child(arm)


func _make_hand(label: String, pos: Vector3, material: Material) -> void:
	var hand := MeshInstance3D.new()
	hand.name = label
	var mesh := SphereMesh.new()
	mesh.radius = 0.085
	mesh.height = 0.17
	hand.mesh = mesh
	hand.position = pos
	hand.scale = Vector3(1.0, 0.85, 1.1)
	hand.material_override = material
	add_child(hand)
