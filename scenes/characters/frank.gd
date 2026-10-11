class_name Frank
extends Character
## Frank (F-12): stern, still, with a sly smile. ~1.3 m (the story calls him Elsa Ray's and Christopher's son; the
## stray "John" in the source is Frank). He defaults to "stern" and NEVER idles or moves on his own: stillness is the point.
## `sly_smile()` switches to the smile; `stern()` back. What he is stays unexplained (CANON ambiguity rules): nothing
## here may label him.

func _style() -> Dictionary:
	return {"height": 1.3, "build": 0.9, "head_scale": 1.1, "skin": Color(0.92, 0.76, 0.64), "shirt": Color(0.28, 0.32, 0.4),
		"pants": Color(0.18, 0.18, 0.24), "hair": Color(0.2, 0.14, 0.09), "hair_style": "cap"}


func _ready() -> void:
	expression = "stern"
	super._ready()


## Shows the sly smile.
func sly_smile() -> void:
	set_expression("sly_smile")


## Back to the stern face.
func stern() -> void:
	set_expression("stern")
