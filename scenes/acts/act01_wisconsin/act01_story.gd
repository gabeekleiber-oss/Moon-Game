extends Node3D
## Playable Act 1 story route. Interactions are physical [E] targets, never an automatic beat timer.
## Text is descriptive guidance, not purported verbatim dialogue from the manuscript.
const InteractableScript = preload("res://scenes/interaction/interactable.gd")
const CarryPropsScript = preload("res://scenes/player/props/carry_props.gd")

var act: Node3D
var props: Dictionary = {}
var prompts: Dictionary = {}
var story_text := {
	"intruder": "The television holds the family still. A barefoot stranger in a damp bathrobe bursts in.",
	"finger": "His finger presses against your lips. The room seems to draw closer.",
	"letter": "The damp letter bears a verse about Joshua Primo, the Gronfiser, and thirteen years.",
	"shoo": "You kick the intruder out. Beyond the door, the sun burns in the middle of the night.",
	"kitchen_items": "You set the yam and grime fighter solution on the kitchen floor.",
	"broom": "Take the broom from the hall closet.",
	"tv_hit_1": "The broom handle strikes the television. The song cuts off. The screen goes black.",
	"tv_hit_2": "The second blow topples the twenty-seven-inch television.",
	"quit_call": "You call your boss, quit, and put the telephone down.",
	"phone_throw": "The telephone splashes into Mary Sue's fish tank.",
	"tank_throw": "You throw the fish tank too.",
	"family_loaded": "Frank, Elsa Ray, and Mary Sue squeeze into the Taurus. The letter sits in the passenger seat."
}

func _ready() -> void:
	act = get_parent() as Node3D
	# Separate targets keep all story actions spatially discoverable.
	_add("intruder", "Look toward the stranger", Vector3(2.5, 1.2, 1.0), Vector3(0.6, 1.8, 0.4), Color(0.43, 0.35, 0.34))
	_add("finger", "Face the stranger", Vector3(2.5, 1.5, 1.0), Vector3(0.22, 0.20, 0.22), Color(0.65, 0.48, 0.41))
	_add("letter", "Read the damp letter", Vector3(2.1, 0.9, 2.4), Vector3(0.32, 0.04, 0.24), Color(0.76, 0.69, 0.52))
	_add("shoo", "Kick the stranger out", Vector3(7.2, 1.1, 1.2), Vector3(0.7, 1.4, 0.5), Color(0.39, 0.29, 0.25))
	_add("kitchen_items", "Set down the yam and cleaner", Vector3(2.7, 0.7, 7.2), Vector3(0.7, 0.25, 0.4), Color(0.58, 0.34, 0.17))
	_add("tv_hit_1", "Strike the television with the broom", Vector3(3.0, 1.2, 0.6), Vector3(1.1, 0.85, 0.5), Color(0.13, 0.17, 0.22))
	_add("tv_hit_2", "Strike the television again", Vector3(3.0, 1.2, 0.6), Vector3(1.1, 0.85, 0.5), Color(0.13, 0.17, 0.22))
	_add("quit_call", "Call your boss and quit", Vector3(4.8, 0.95, 6.5), Vector3(0.38, 0.22, 0.25), Color(0.25, 0.24, 0.22))
	_add("phone_throw", "Throw the telephone into the tank", Vector3(13.8, 1.1, 1.6), Vector3(0.8, 0.65, 0.5), Color(0.25, 0.44, 0.47))
	_add("tank_throw", "Throw the fish tank", Vector3(13.8, 1.1, 1.6), Vector3(0.8, 0.65, 0.5), Color(0.25, 0.44, 0.47))
	_add("family_loaded", "Help the family into the Taurus", Vector3(7.6, 0.9, -4.5), Vector3(2.2, 1.0, 4.0), Color(0.25, 0.27, 0.30))
	_add("stairs", "Go upstairs to Mary Sue's room", Vector3(8.2, 1.1, 2.5), Vector3(0.7, 1.5, 0.3), Color(0.36, 0.28, 0.23))
	_add("downstairs", "Return downstairs", Vector3(13.0, 1.1, 3.1), Vector3(0.7, 1.5, 0.3), Color(0.36, 0.28, 0.23))
	_add("outside", "Go out to the driveway", Vector3(7.5, 1.1, 0.6), Vector3(0.8, 1.5, 0.3), Color(0.36, 0.30, 0.27))
	_add("inside", "Return to the house", Vector3(7.2, 1.0, -1.7), Vector3(0.8, 1.5, 0.3), Color(0.36, 0.30, 0.27))
	_build_driveway()
	_build_wrong_sun()
	_build_tv_light()
	_build_story_label()
	Events.beat_completed.connect(_on_beat)
	call_deferred("_refresh")

func _add(id: String, prompt_text: String, at: Vector3, size: Vector3, color: Color) -> void:
	var item: Interactable = InteractableScript.new()
	item.name = "Story_" + id
	item.position = at
	item.prompt = prompt_text
	item.range = 3.4
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.8
	mesh.material_override = mat
	item.add_child(mesh)
	var shape := CollisionShape3D.new()
	var collider := BoxShape3D.new()
	collider.size = size
	shape.shape = collider
	item.add_child(shape)
	add_child(item)
	props[id] = item
	item.used.connect(func(player: Node3D) -> void: _interact(id, player))

func _build_driveway() -> void:
	var ground := StaticBody3D.new()
	ground.name = "DrivewayGround"
	ground.position = Vector3(7.0, -0.16, -5.0)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(13, 0.3, 12)
	shape.shape = box
	ground.add_child(shape)
	var visual := MeshInstance3D.new()
	var ground_mesh := BoxMesh.new()
	ground_mesh.size = box.size
	visual.mesh = ground_mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.36, 0.38, 0.41)
	visual.material_override = material
	ground.add_child(visual)
	add_child(ground)

## The sun is inexplicably visible over the snow despite the winter-night setting.
func _build_wrong_sun() -> void:
	var orb := MeshInstance3D.new()
	orb.name = "SunAtNight"
	var sphere := SphereMesh.new()
	sphere.radius = 1.35
	sphere.height = 2.7
	orb.mesh = sphere
	orb.position = Vector3(10.0, 7.0, -22.0)
	var glow := StandardMaterial3D.new()
	glow.albedo_color = Color(0.98, 0.64, 0.27)
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	orb.material_override = glow
	add_child(orb)
	var light := OmniLight3D.new()
	light.name = "ImpossibleSunlight"
	light.position = Vector3(8.0, 4.5, -8.0)
	light.light_color = Color(1.0, 0.64, 0.30)
	light.light_energy = 0.55
	light.omni_range = 16.0
	add_child(light)

func _build_tv_light() -> void:
	var tv := OmniLight3D.new()
	tv.name = "TelevisionGlow"
	tv.position = Vector3(3.0, 1.6, 1.1)
	tv.light_color = Color(0.46, 0.63, 0.89)
	tv.light_energy = 0.85
	tv.omni_range = 5.0
	add_child(tv)
func _build_story_label() -> void:
	var ui := CanvasLayer.new()
	ui.name = "Act01Guidance"
	ui.layer = 6
	add_child(ui)
	var label := Label.new()
	label.name = "Guidance"
	label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	label.offset_top = 24
	label.offset_bottom = 80
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 19)
	label.add_theme_color_override("font_color", Color(0.88, 0.84, 0.72))
	label.add_theme_color_override("font_outline_color", Color(0.08, 0.07, 0.07))
	label.add_theme_constant_override("outline_size", 5)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(label)

func _notice(message: String) -> void:
	var label := get_node_or_null("Act01Guidance/Guidance") as Label
	if label != null:
		label.text = message


func _interact(id: String, player: Node3D) -> void:
	if id == "outside":
		player.global_position = Vector3(7.5, 0.35, -2.6)
		_notice("Snow lies across the driveway. The Taurus is waiting.")
		return
	if id == "inside":
		player.global_position = Vector3(7.5, 0.35, 1.5)
		return
	if id == "family_loaded" and act.beats.all_done():
		Acts.go_to_next()
		return
	if id == "stairs":
		player.global_position = Vector3(13.0, 0.35, 2.8)
		_notice("Mary Sue's room. The fish tank is beside the bed.")
		return
	if id == "downstairs":
		player.global_position = Vector3(8.0, 0.35, 2.4)
		_notice("The television's faint song still hangs in the house.")
		return
	if act.beats.current() != id:
		return
	if id in ["tv_hit_1", "tv_hit_2"]:
		var controller := player.get_node_or_null("Head/Camera3D/CarryController") as CarryController
		if controller == null or not is_instance_valid(controller.held_item) or controller.held_item.name != "Broom":
			_notice("You need the broom handle.")
			return
	if act.beat(id):
		_notice(story_text.get(id, ""))
		if id == "tv_hit_1":
			var tv_light := get_node_or_null("TelevisionGlow") as OmniLight3D
			if tv_light != null:
				tv_light.light_energy = 0.0
			(props["tv_hit_1"] as Node3D).visible = false
		if id == "tv_hit_2":
			(props["tv_hit_2"] as Node3D).rotation_degrees.z = 75.0

func _on_beat(act_id: int, _beat: String) -> void:
	if act_id == 1:
		_refresh()

func _refresh() -> void:
	var next: String = act.beats.current()
	for id in props:
		var item: Interactable = props[id]
		if id in ["stairs", "downstairs", "outside", "inside"]:
			item.enabled = (next in ["phone_throw", "tank_throw"] or (id == "downstairs" and next in ["family_loaded", ""])) if id in ["stairs", "downstairs"] else (next == "family_loaded" or next == "")
		elif id == "finger":
			item.enabled = next == "finger"
		else:
			item.enabled = next == id or (next == "" and id == "family_loaded")
		item.collision_layer = InteractableScript.INTERACT_LAYER if item.enabled else 0
	if next == "broom":
		_notice("The broom is in the hall closet. Press E to take it.")
	elif next == "family_loaded":
		_notice("The Taurus waits in the snowy driveway. Bring the family to the car.")
	elif next == "":
		_notice("The headlights come on by themselves. Press E at the Taurus to begin the road south.")
	else:
		_notice("Next: " + str((props[next] as Interactable).prompt) + "  |  " + _where(next) if props.has(next) else "Continue exploring.")
## Directions use the canonical Wisconsin floor-plan grid, not a minimap or quest marker.
func _where(id: String) -> String:
	if id in ["intruder", "finger", "letter", "tv_hit_1", "tv_hit_2"]:
		return "Living room"
	if id in ["kitchen_items", "quit_call"]:
		return "Kitchen, beyond the living room"
	if id == "shoo":
		return "Front entry, east of the living room"
	if id in ["phone_throw", "tank_throw"]:
		return "Entry stairway, then Mary Sue's room"
	if id == "family_loaded":
		return "Front entry, then driveway"
	return "Explore the house"