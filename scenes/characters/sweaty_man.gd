class_name SweatyMan
extends Character
## The Sweaty Man (F-12): bathrobe, barefoot, long scraggly beard, one VERY long finger held to his lips, damp skin and
## a shimmer of steam. ~1.8 m, faces +Z. Parts: Robe, Belt, Beard + BeardStrand0..n, UpperArmR, ForearmR, HandR, FingerR,
## SteamShell (faint haze) and Steam (rising puffs). Steam freezes under Reduced Motion (`refresh_steam()`; also automatic on
## Events.settings_changed). `set_steam(false)` removes it entirely. The damp letter is a separate prop (not part of him).
## Robe/beard colours are assumed (the story gives none).

const STRANDS := 9
const FINGER_LENGTH := 0.34       # a normal finger is ~0.08 m: this one is "very long"

var _steam: CPUParticles3D
var _shell: MeshInstance3D
var _steam_on: bool = true


func _style() -> Dictionary:
	return {"height": 1.8, "build": 1.05, "skin": Color(0.9, 0.7, 0.6), "skin_rough": 0.18, "shirt": Color(0.72, 0.68, 0.58),
		"pants": Color(0.9, 0.7, 0.6), "shoes": Color(0.9, 0.7, 0.6), "hair": Color(0.5, 0.48, 0.45), "hair_style": "cap",
		"eye_color": Color(0.3, 0.3, 0.35)}


## Turns the steam on or off.
func set_steam(on: bool) -> void:
	_steam_on = on
	if _steam != null:
		_steam.visible = on
		_shell.visible = on
		refresh_steam()


## Re-reads Game.settings: under Reduced Motion the steam stops rising (it stays as a still haze).
func refresh_steam() -> void:
	if _steam == null:
		return
	_steam.speed_scale = 0.0 if bool(Game.settings.get("reduced_motion", false)) else 1.0


func _ready() -> void:
	super._ready()
	Events.settings_changed.connect(func(_k: String) -> void: refresh_steam())


func _decorate(s: Dictionary) -> void:
	var h := height_m()
	var robe_mat := PropUtil.mat(Color(0.72, 0.68, 0.58), 0.0, 0.95)
	var skin_mat := (part("Head") as MeshInstance3D).material_override
	var top_y := 0.46 * h + 0.30 * h + 0.02 * h
	var bottom_y := 0.3 * h
	var robe := CylinderMesh.new()
	robe.top_radius = 0.105 * h
	robe.bottom_radius = 0.16 * h
	robe.height = top_y - bottom_y
	PropUtil.add_mesh(self, robe, robe_mat, Vector3(0, (top_y + bottom_y) * 0.5, 0), "Robe")
	_parts["Robe"] = get_node("Robe")
	_order.append("Robe")
	var belt := CylinderMesh.new()
	belt.top_radius = 0.108 * h
	belt.bottom_radius = 0.108 * h
	belt.height = 0.03 * h
	_part("Belt", belt, PropUtil.mat(Color(0.7, 0.66, 0.58), 0.0, 0.9), Vector3(0, 0.6 * h, 0))

	_beard(h)
	_finger_to_lips(h, robe_mat, skin_mat)
	_steam_fx(h)
	refresh_steam()


func _beard(h: float) -> void:
	var head := part("Head") as Node3D
	var mat := PropUtil.mat(Color(0.52, 0.5, 0.46), 0.0, 1.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var chin := head.position + Vector3(0, -_head_r * 0.55, _head_r * 0.62)
	var strands: Array[MeshInstance3D] = []
	for i in STRANDS:
		var spread := (float(i) / (STRANDS - 1) - 0.5) * 2.0          # -1 .. 1 across the jaw
		var start := chin + Vector3(spread * _head_r * 0.62, -_head_r * 0.1 * absf(spread), -absf(spread) * _head_r * 0.25)
		var length := rng.randf_range(0.22, 0.38) * h / 1.8
		var pts: Array[Vector3] = []
		for k in 5:
			var t := float(k) / 4.0
			pts.append(start + Vector3(spread * 0.03 * t + rng.randf_range(-0.012, 0.012) * t, -length * t, 0.05 * t + rng.randf_range(0.0, 0.025) * t))
		var mi := _part("BeardStrand%d" % i, PropUtil.tube(pts, 0.016, 6, 0.004), mat, Vector3.ZERO)
		strands.append(mi)
	var beard := Node3D.new()
	beard.name = "Beard"
	add_child(beard)
	_parts["Beard"] = beard
	_order.append("Beard")


func _finger_to_lips(h: float, sleeve: Material, skin: Material) -> void:
	var head := part("Head") as Node3D
	var lips := head.position + Vector3(0, -_head_r * 0.42, _head_r * 1.0)
	# the base right arm/hand hang by his side; replace them with a bent arm raised to the face
	part("ArmR").visible = false
	var shoulder := part("ArmR").position + Vector3(0, 0.14 * h, 0)
	var hand_pos := lips + Vector3(0.2, -0.26, 0.22).normalized() * FINGER_LENGTH   # exactly one finger away, so the tip touches the lips
	var elbow := Vector3(shoulder.x + 0.1 * h / 1.8, shoulder.y - 0.2 * h / 1.8, shoulder.z + 0.12 * h / 1.8)
	_limb(shoulder, elbow, 0.03 * h, sleeve, "UpperArmR")
	_limb(elbow, hand_pos, 0.027 * h, sleeve, "ForearmR")
	var hand := part("HandR") as Node3D
	hand.position = hand_pos
	var dir := (lips - hand_pos).normalized()
	var finger_start := hand_pos
	var finger_end := hand_pos + dir * FINGER_LENGTH
	var f := _limb(finger_start, finger_end, 0.0085, skin, "FingerR")
	f.set_meta("tip", finger_end)
	_parts["FingerR"] = f


func _steam_fx(h: float) -> void:
	var shell_mesh := CapsuleMesh.new()
	shell_mesh.radius = 0.2 * h
	shell_mesh.height = h * 1.02
	var shell_mat := StandardMaterial3D.new()
	shell_mat.albedo_color = Color(1.0, 1.0, 1.0, 0.025)
	shell_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shell_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_shell = _part("SteamShell", shell_mesh, shell_mat, Vector3(0, h * 0.52, 0))
	_shell.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	_steam = CPUParticles3D.new()
	_steam.name = "Steam"
	var puff := SphereMesh.new()
	puff.radius = 0.06
	puff.height = 0.12
	var puff_mat := StandardMaterial3D.new()
	puff_mat.albedo_color = Color(1, 1, 1, 0.32)
	puff_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	puff_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	puff.material = puff_mat
	_steam.mesh = puff
	_steam.amount = 20
	_steam.lifetime = 2.6
	_steam.preprocess = 2.6
	_steam.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	_steam.emission_sphere_radius = 0.28 * h / 1.8
	_steam.direction = Vector3.UP
	_steam.spread = 12.0
	_steam.gravity = Vector3.ZERO
	_steam.initial_velocity_min = 0.12
	_steam.initial_velocity_max = 0.25
	_steam.scale_amount_min = 0.5
	_steam.scale_amount_max = 1.3
	_steam.position = Vector3(0, h * 0.55, 0)
	_steam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_steam)
	_parts["Steam"] = _steam
	_order.append("Steam")
