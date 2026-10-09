class_name Interactable
extends StaticBody3D
## Base class for anything the player can look at and press [E] on. (F-02)
##
## Usage: add an Interactable node, give it a CollisionShape3D and some meshes as children,
## set `prompt` and `message` in the inspector (every interactable gets a funny response),
## then either connect the `used` signal or extend this script and override `_on_use()`.
## The player's InteractionRay finds it via physics layer 4 + the `interactable` group.
##
## Contract (docs/ARCHITECTURE.md): group `interactable`; `prompt`, `range`, `can_use()`, `use(player)`; runs once if `once`.
## Any other node can also be interactable if it is a collider in layer 4 / group `interactable` and exposes the same members.

## Emitted when the player uses this object.
signal used(player: Node3D)

## Physics layer 4 (interactables), as a layer bitmask value.
const INTERACT_LAYER := 8

## Text after "[E]" in the on-screen prompt.
@export var prompt: String = "Use"
## Max distance (metres) from the camera at which the prompt appears and use works.
@warning_ignore("shadowed_global_identifier")
@export var range: float = 2.4
## If true, can only be used once.
@export var once: bool = false
## If false, the object is not highlighted and cannot be used (toggle from chapter scripts).
@export var enabled: bool = true
## Funny response shown via Events.show_message when used. Leave empty for none.
@export_multiline var message: String = ""
## Optional flag set via Game.set_flag() when used.
@export var set_flag_on_use: String = ""

var _used: bool = false


func _init() -> void:
	collision_layer = INTERACT_LAYER
	collision_mask = 0


func _ready() -> void:
	add_to_group("interactable")


## True if the player may use this right now.
func can_use() -> bool:
	return enabled and not (once and _used)


## Called by the InteractionRay when [E] is pressed. Safe to call from scripts too.
func use(player: Node3D) -> void:
	if not can_use():
		return
	_used = true
	if message != "":
		Events.show_message.emit(message)
	if set_flag_on_use != "":
		Game.set_flag(set_flag_on_use)
	_on_use(player)
	used.emit(player)


## Override in subclasses to add behaviour (runs before the `used` signal).
func _on_use(_player: Node3D) -> void:
	pass


## Allows `once` objects to be used again (e.g. a chapter reset).
func reset_use() -> void:
	_used = false
