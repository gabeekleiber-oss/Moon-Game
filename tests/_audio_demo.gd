extends Control
## Audition tool (open tests/_audio_demo.tscn in Godot and press F6): click to hear every SFX recipe, every character voice,
## and the reverb presets. Dev only; not part of the game.

const SAMPLE := "Well, hello there, Christopher"

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scroll)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(box)

	box.add_child(_header("Reverb (applies to everything below)"))
	var rrow := HFlowContainer.new()
	for preset in Audio.REVERB_PRESETS:
		rrow.add_child(_button(preset, func() -> void: Audio.set_reverb(preset)))
	box.add_child(rrow)

	box.add_child(_header("Sound effects"))
	var srow := HFlowContainer.new()
	for n in SfxRecipes.NAMES:
		srow.add_child(_button(n, func() -> void: Audio.play_sfx(n)))
	box.add_child(srow)

	box.add_child(_header("Character voices (types a sample line)"))
	var vrow := HFlowContainer.new()
	for k in VoiceProfiles.PROFILES:
		vrow.add_child(_button(k, func() -> void: _speak(k)))
	vrow.add_child(_button("(unknown speaker)", func() -> void: _speak("demo_speaker")))
	box.add_child(vrow)

func _speak(who: String) -> void:
	for ch in SAMPLE:
		Events.speaker_blip.emit(who, ch)
		await get_tree().create_timer(1.0 / 38.0).timeout

func _header(t: String) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", 24)
	return l

func _button(t: String, f: Callable) -> Button:
	var b := Button.new()
	b.text = t
	b.custom_minimum_size = Vector2(150, 44)
	b.pressed.connect(f)
	return b
