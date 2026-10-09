extends CharacterBody3D
## Basic first-person controller. Owner: Gameplay role.

@export var speed := 6.0
@export var jump_velocity := 5.0
@export var mouse_sensitivity := 0.0025

@onready var head: Node3D = $Head

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	# F-02: interaction raycast on the camera (reticle, [E] prompt, outline)
	var interaction_ray := preload("res://scenes/interaction/interaction_ray.gd").new() as RayCast3D
	head.get_node("Camera3D").add_child(interaction_ray)
	interaction_ray.call("setup", self)
	Events.player_spawned.emit(self)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		head.rotate_x(-event.relative.y * mouse_sensitivity)
		head.rotation.x = clamp(head.rotation.x, -1.4, 1.4)
	if event.is_action_pressed("pause"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= _gravity * delta
	elif Input.is_action_just_pressed("jump") and not Dialogue.is_active():
		velocity.y = jump_velocity

	var input_dir := Vector2.ZERO if Dialogue.is_active() else Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var dir := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	move_and_slide()
