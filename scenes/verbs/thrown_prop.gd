class_name ThrownProp
extends RigidBody3D
## S-15: a held or placed object turned into a real physics body for a throw. Tactile: weight sets how far it goes, impacts
## play sounds scaled by speed, and the player never needs to aim precisely (see ThrowTarget).
##
## `ThrownProp.launch(source, velocity, kind, parent)` moves the source's visuals and collision into a new RigidBody3D and hides the
## original, so any Carryable or placeholder prop can be thrown without a separate "throwable" scene.

signal impact(body: Node, speed: float)

const PROP_LAYER := 16     # physics layer 5: thrown props
## Physics mask a thrown prop collides with: world (1) and other props (16).
const COLLIDE_MASK := 1 | 16

var kind: String = ""
var caught_by: Node = null
var impact_sound: String = "thud"
var _last_impact_msec: int = -1000


## Creates the body with copies of `source`'s mesh and collision shapes and gives it `velocity`. Returns the new prop.
static func launch(source: Node3D, velocity: Vector3, prop_kind: String, parent: Node, mass_kg: float = 1.0) -> ThrownProp:
	var prop := ThrownProp.new()
	prop.name = "Thrown_" + prop_kind
	prop.kind = prop_kind
	prop.mass = maxf(mass_kg, 0.1)
	prop.collision_layer = PROP_LAYER
	prop.collision_mask = COLLIDE_MASK
	prop.contact_monitor = true
	prop.max_contacts_reported = 4
	prop.continuous_cd = true
	var origin := source.global_transform
	for child in source.get_children():
		if child is MeshInstance3D or child is CollisionShape3D:
			var copy := child.duplicate()
			prop.add_child(copy)
	if prop.find_children("*", "CollisionShape3D", false, false).is_empty():
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(0.3, 0.3, 0.3)
		shape.shape = box
		prop.add_child(shape)
	parent.add_child(prop)
	prop.global_transform = origin
	prop.linear_velocity = velocity
	prop.angular_velocity = Vector3(randf_range(-3.0, 3.0), randf_range(-3.0, 3.0), randf_range(-3.0, 3.0)) * clampf(1.5 / prop.mass, 0.3, 2.0)
	source.visible = false
	source.process_mode = Node.PROCESS_MODE_DISABLED
	if source is CollisionObject3D:
		(source as CollisionObject3D).collision_layer = 0
		(source as CollisionObject3D).collision_mask = 0
	if source.get("enabled") != null:
		source.set("enabled", false)
	return prop


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	var speed := linear_velocity.length()
	if speed < 1.2 or Time.get_ticks_msec() - _last_impact_msec < 120:
		return
	_last_impact_msec = Time.get_ticks_msec()
	if impact_sound != "":
		Audio.play_sfx_at(impact_sound, global_position, clampf(linear_to_db(clampf(speed / 8.0, 0.1, 1.0)), -18.0, 0.0), clampf(1.3 - mass * 0.05, 0.8, 1.3))
	impact.emit(body, speed)
