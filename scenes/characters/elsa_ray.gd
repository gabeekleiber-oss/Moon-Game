class_name ElsaRay
extends Character
## Elsa Ray (F-12): blue eyes, long hair, and a signature half-second glare (`glare()`, inherited, 0.5 s by default).
## ~1.68 m, faces +Z. Hair colour and clothing are NOT in the story (assumed; change in _style()).
## Expressions: see Character.expressions(); she defaults to "neutral".

func _style() -> Dictionary:
	return {"height": 1.68, "build": 0.95, "skin": Color(0.95, 0.80, 0.69), "shirt": Color(0.62, 0.36, 0.40),
		"pants": Color(0.22, 0.2, 0.3), "hair": Color(0.36, 0.22, 0.12), "hair_style": "long",
		"eye_color": Color(0.22, 0.48, 0.92), "lash": true}
