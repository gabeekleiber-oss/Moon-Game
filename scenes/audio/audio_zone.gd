extends Area3D
## Applies the sensory-sheet reverb while the player occupies this room.
##
## Set space_id to a key from data/sensory/spaces.json. The room's reverb preset is
## resolved from that data instead of being duplicated in each scene.

const SPACE_DATA_PATH := "res://data/sensory/spaces.json"

@export var space_id: String = ""

var _space_reverb := "none"
var _previous_reverb := "none"
var _inside: Array[Node3D] = []


func _ready() -> void:
	monitoring = true
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_space_reverb = _reverb_for_space(space_id)
	if _space_reverb == "":
		push_warning("AudioZone has unknown space_id: " + space_id)
		_space_reverb = "none"


func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player") or _inside.has(body):
		return
	if _inside.is_empty():
		_previous_reverb = Audio.reverb_preset()
	_inside.append(body)
	Audio.set_reverb(_space_reverb)


func _on_body_exited(body: Node3D) -> void:
	if not _inside.has(body):
		return
	_inside.erase(body)
	if _inside.is_empty() and Audio.reverb_preset() == _space_reverb:
		Audio.set_reverb(_previous_reverb)


func active_player_count() -> int:
	return _inside.size()


static func _reverb_for_space(id: String) -> String:
	if id.is_empty():
		return ""
	var file := FileAccess.open(SPACE_DATA_PATH, FileAccess.READ)
	if file == null:
		return ""
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return ""
	var spaces: Variant = parsed.get("spaces", {})
	if not spaces is Dictionary or not spaces.has(id):
		return ""
	return String(spaces[id].get("reverb", "none"))
