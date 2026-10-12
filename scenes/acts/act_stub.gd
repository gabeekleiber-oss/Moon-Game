class_name ActStub
extends ActBase
## Placeholder act scene so the whole game boots and every act is reachable. Replace it act by act (docs/ACTS.md).
## A grey floor, a dim light, the player, a title label, and five leaning "pillars" that demonstrate how world objects react to
## the hidden Unreality value (they lean one by one as it rises: `Unreality.wrongs(id)`). Delete all of this when the real act lands.

var _pillars: Array[MeshInstance3D] = []


func _act_ready() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.02, 0.02, 0.03)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.35, 0.36, 0.42)
	env.ambient_light_energy = 0.7
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 30, 0)
	sun.light_energy = 0.6
	add_child(sun)
	var floor_body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(60, 0.4, 60)
	shape.shape = box
	shape.position.y = -0.2
	floor_body.add_child(shape)
	var fm := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(60, 0.4, 60)
	fm.mesh = bm
	fm.position.y = -0.2
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.32, 0.32, 0.34)
	fm.material_override = mat
	floor_body.add_child(fm)
	add_child(floor_body)
	for i in 5:
		var p := MeshInstance3D.new()
		var pm := BoxMesh.new()
		pm.size = Vector3(0.5, 3.0, 0.5)
		p.mesh = pm
		p.position = Vector3(-6.0 + i * 3.0, 1.5, -8.0)
		p.name = "Pillar%d" % i
		p.set_meta("wrong_id", "stub_pillar_%d_%d" % [act_id, i])
		var pmat := StandardMaterial3D.new()
		pmat.albedo_color = Color(0.7, 0.7, 0.72)
		p.material_override = pmat
		add_child(p)
		_pillars.append(p)
	var label := Label3D.new()
	label.text = "ACT %d: %s\n(stub - press N to complete)" % [act_id, act_title]
	label.font_size = 72
	label.pixel_size = 0.01
	label.position = Vector3(0, 4.2, -8.0)
	add_child(label)
	var player: Node = (load("res://scenes/player/player.tscn") as PackedScene).instantiate()
	player.position = Vector3(0, 1.0, 4.0)
	add_child(player)


func _process(_delta: float) -> void:
	for p in _pillars:
		var wrong: bool = Unreality.wrongs(str(p.get_meta("wrong_id")))
		var target := (0.12 + 0.2 * Unreality.level) if wrong else 0.0
		p.rotation.z = lerpf(p.rotation.z, target, 0.03) * Unreality.motion_scale()
