extends Node
## Headless test for F-02. Run: godot --headless --path . res://tests/test_interaction.tscn
## Builds floor + player + two Interactables, looks at one, presses E, checks focus/outline/events.

var _fails := 0
var _events := {"focus": 0, "interacted": 0, "message": ""}


func _check(cond: bool, what: String) -> void:
	print(("PASS " if cond else "FAIL ") + what)
	if not cond:
		_fails += 1


func _ready() -> void:
	var events := get_node("/root/Events")
	events.interact_focus_changed.connect(func(_t: Node3D) -> void: _events["focus"] += 1)
	events.interacted.connect(func(_t: Node3D) -> void: _events["interacted"] += 1)
	events.show_message.connect(func(t: String) -> void: _events["message"] = t)

	var level := Node3D.new()
	add_child(level)
	var player := (load("res://scenes/player/player.tscn") as PackedScene).instantiate()
	level.add_child(player)
	(player.get_node("Head/Camera3D").get_child(0) as InteractionRay).require_captured_mouse = false

	var floor_body := StaticBody3D.new()
	var fs := CollisionShape3D.new()
	var fbox := BoxShape3D.new()
	fbox.size = Vector3(40, 1, 40)
	fs.shape = fbox
	floor_body.add_child(fs)
	floor_body.position = Vector3(0, -0.5, 0)
	level.add_child(floor_body)

	# Interactable 2 m in front of the camera (player looks down -Z), camera height 1.6
	var near := _make_box(Vector3(0, 1.6, -2.0), "Open")
	near.message = "It opens. It regrets it."
	near.once = true
	level.add_child(near)
	var far := _make_box(Vector3(0, 1.6, -3.9), "Poke")  # beyond its 2.4 range
	far.position = Vector3(3, 1.6, -3.9)
	level.add_child(far)
	level.set_meta("near", near)
	set_meta("level", level)
	set_meta("player", player)


func _make_box(pos: Vector3, prompt_text: String) -> Interactable:
	var it := Interactable.new()
	it.prompt = prompt_text
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.6, 0.6, 0.6)
	cs.shape = box
	it.add_child(cs)
	var mi := MeshInstance3D.new()
	mi.mesh = BoxMesh.new()
	mi.scale = Vector3(0.6, 0.6, 0.6)
	it.add_child(mi)
	it.position = pos
	return it


var _frame := 0


func _physics_process(_delta: float) -> void:
	_frame += 1
	var level: Node3D = get_meta("level")
	var near: Interactable = level.get_meta("near")
	var mi := near.get_child(1) as MeshInstance3D
	if _frame == 10:
		_check(_events["focus"] >= 1, "focus event fired when looking at near interactable")
		_check(mi.material_overlay != null, "outline overlay applied to focused mesh")
		var ray: InteractionRay = get_meta("player").get_node("Head/Camera3D").get_child(0)
		_check(ray.focus == near, "ray.focus is the near interactable")
		var ev := InputEventAction.new()
		ev.action = "interact"
		ev.pressed = true
		Input.parse_input_event(ev)
	if _frame == 14:
		_check(_events["interacted"] == 1, "interacted event fired once on [E]")
		_check(_events["message"] == "It opens. It regrets it.", "funny message emitted")
		_check(not near.can_use(), "once=true: can_use() false after use")
		_check(mi.material_overlay == null, "outline cleared after once-use")
		print("RESULT: %s" % ("ALL PASS" if _fails == 0 else "%d FAILED" % _fails))
		get_tree().quit(0 if _fails == 0 else 1)
