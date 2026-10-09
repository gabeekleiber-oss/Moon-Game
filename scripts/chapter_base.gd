class_name ChapterBase
extends Node3D
## Base class for every chapter scene. Owner: Lead (chapter owners subclass or extend it).
## Contract: set chapter_id in the scene; call complete() when the chapter's canon beat is done.

@export var chapter_id: int = 0
@export var chapter_title: String = ""
@export var objective: String = ""

func _ready() -> void:
	if objective != "":
		Events.objective_set.emit(objective)
	Events.show_message.emit("Chapter %d - %s" % [chapter_id, chapter_title])
	_chapter_ready()

## Override in chapter scripts.
func _chapter_ready() -> void:
	pass

func complete() -> void:
	Events.chapter_completed.emit(chapter_id)
	ChapterManager.next()

## Stubs only: press N to advance. Remove when the real chapter lands.
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_N and OS.is_debug_build():
		complete()
