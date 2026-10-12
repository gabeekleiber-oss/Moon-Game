extends CharacterBody3D
## First-person controller. Walks, looks, jumps; the view itself carries the hidden Unreality: from the 'wrong' band the head
## drifts and tilts and the field of view slowly breathes (all scaled by Unreality.motion_scale(), so Reduced Motion stills it).

@export var speed := 6.0
@export var jump_velocity := 5.0
@export var mouse_sensitivity := 0.0025

const BASE_FOV := 75.0
@onready var head: Node3D = $Head
var _t: float = 0.0

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	# F-02: interaction raycast on the camera (reticle, [E] prompt, outline)
	var interaction_ray := preload("res://scenes/interaction/interaction_ray.gd").new() as RayCast3D
	head.get_node("Camera3D").add_child(interaction_ray)
	interaction_ray.call("setup", self)
	Events.player_spawned.emit(self)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and not Cutscene.is_active():
		rotate_y(-event.relative.x * _sensitivity())
		head.rotate_x(-event.relative.y * _sensitivity())
		head.rotation.x = clamp(head.rotation.x, -1.4, 1.4)
	# Esc is owned by the PauseMenu autoload (F-06): it pauses and frees the mouse.

func _process(delta: float) -> void:
	_t += delta
	var k := Unreality.ramp(0.35, 1.0) * Unreality.motion_scale()
	head.rotation.z = lerpf(head.rotation.z, sin(_t * 0.7) * 0.035 * k + sin(_t * 0.31) * 0.02 * k, 1.0 - exp(-delta * 2.0))
	var cam: Camera3D = head.get_node("Camera3D")
	cam.fov = lerpf(cam.fov, BASE_FOV + sin(_t * 0.5) * 3.0 * k, 1.0 - exp(-delta * 2.0))


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= _gravity * delta
	elif Input.is_action_just_pressed("jump") and not _locked():
		velocity.y = jump_velocity

	var input_dir := Vector2.ZERO if _locked() else Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var dir := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	move_and_slide()

## True while a dialogue or cutscene owns the player (no walking, jumping or (cutscene) looking).
func _locked() -> bool:
	return Dialogue.is_active() or Cutscene.is_active()

## Mouse sensitivity from the settings menu (falls back to the exported value).
func _sensitivity() -> float:
	return float(Game.settings.get("sensitivity", mouse_sensitivity))
