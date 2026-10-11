extends Node
## Headless test for C-01 (Chapter 1). Run: godot --headless --path . res://tests/test_ch01.tscn
## Plays the whole chapter: skip the entrance, read the letter, miss then land the kick, closet + broom, two TV hits, ending.

var _fails := 0
var _chapter: Node3D
var _pumping: bool = true


func _check(cond: bool, what: String) -> void:
	print(("PASS " if cond else "FAIL ") + what)
	if not cond:
		_fails += 1


func _ready() -> void:
	Game.flea = 0.0
	Game.flags.clear()
	ChapterManager.current_id = 99                      # complete() must not load a real next chapter here
	_verbatim_checks()

	var packed := load("res://scenes/chapters/ch01_wisconsin/ch01_wisconsin.tscn") as PackedScene
	_chapter = packed.instantiate()
	_chapter.set("show_title_card", false)
	_chapter.set("tutorial_seconds", 0.3)
	var done := [false]
	Events.chapter_completed.connect(func(id: int) -> void: done[0] = (id == 1))
	add_child(_chapter)
	_pump_dialogue()
	await get_tree().process_frame
	_check(_chapter.get("stage") == "tutorial", "starts in the tutorial beat")
	for n in ["Floor", "Ceiling", "WallNorth", "SofaSeat", "TV", "Letter", "Broom", "ClosetInteract", "LampInteract", "WindowInteract"]:
		_check(_chapter.find_child(n, true, false) != null, "room has %s" % n)
	_check(_chapter.find_children("*", "Interactable", true, false).size() >= 10, "10+ interactables to poke at (funny messages)")
	var tv := _chapter.find_child("TV", true, false) as Interactable
	var shown: Array[String] = []
	Events.show_message.connect(func(t: String) -> void: shown.append(t))
	tv.use(null)
	_check(shown.size() > 0 and tv.message != "", "interacting with the TV in the tutorial gives a response")

	# entrance: skipped on purpose; the end-state must still be complete
	_check(await _wait_stage("entrance", 3.0), "tutorial hands over to the entrance cutscene")
	await get_tree().create_timer(0.4).timeout
	Cutscene.request_skip()
	_check(await _wait_stage("letter", 6.0), "skipped entrance still reaches the letter beat")
	var sweaty := _chapter.get("_sweaty") as SweatyMan
	var letter := _chapter.get("_letter") as Interactable
	_check(Game.has_flag("ch01_sweaty_entered") and sweaty.visible, "skip left the Sweaty Man in the room and the flag set")
	_check(letter.visible and letter.enabled, "the damp letter is available after the entrance")
	_check(sweaty.position.distance_to(Vector3(0, 0, 1.45)) < 0.05, "Sweaty Man ended up in front of Christopher")

	# letter
	letter.use(null)
	_check(await _wait_stage("letter_ui", 6.0), "taking the letter shows the letter UI after 'I ripped it open'")
	await get_tree().process_frame
	var ui := _chapter.get("_letter_ui") as LetterUI
	_check(ui != null and ui.is_open(), "letter UI is open")
	_check(ui.letter_text().begins_with("“How do you do?") and ui.letter_text().contains("wiscansin"), "letter text is the verbatim rhyme (typo kept)")
	_check(not ui.is_fully_revealed(), "letter writes itself out")
	ui.advance()
	_check(ui.is_fully_revealed() and ui.is_open(), "first press reveals the whole letter")
	ui.advance()
	_check(await _wait_stage("kick", 3.0), "second press closes it and starts the boot-kick")

	# kick: a deliberate miss, then a hit
	await get_tree().create_timer(0.6).timeout
	var meter := _chapter.get("_kick_meter") as KickMeter
	_check(meter != null and meter.is_active(), "kick meter is sweeping")
	meter.press()                                         # at the very start the marker is far from the zone
	await get_tree().create_timer(0.7).timeout
	meter = _chapter.get("_kick_meter") as KickMeter
	_check(_chapter.get("stage") == "kick" and meter != null and meter.is_active(), "a miss restarts the sweep instead of failing")
	var guard := 0
	while not meter.in_zone() and guard < 400:
		guard += 1
		await get_tree().process_frame
	meter.press()
	_check(await _wait_stage("broom", 8.0), "a landed kick moves on (kick dialogue plays)")
	_check(Game.has_flag("ch01_kicked") and not sweaty.visible, "Sweaty Man has been shooed out")
	_check(is_equal_approx(Game.flea, 5.0), "kick adds +5 Flea (got %.1f)" % Game.flea)

	# broom
	var closet := _chapter.get("_closet") as Interactable
	var broom := _chapter.get("_broom") as Interactable
	guard = 0
	while not closet.enabled and guard < 600:
		guard += 1
		await get_tree().process_frame
	_check(closet.enabled and not broom.enabled, "kitchen cut-away done: closet usable, broom still hidden")
	closet.use(null)
	await get_tree().process_frame
	_check(broom.enabled and broom.visible, "closet reveals the broom")
	broom.use(null)
	_check(await _wait_stage("tv", 3.0) and Game.has_flag("ch01_has_broom"), "taking the broom starts the TV beat")

	# TV
	await get_tree().process_frame
	tv.use(null)
	guard = 0
	while Game.flea < 14.9 and guard < 300:
		guard += 1
		await get_tree().process_frame
	_check(Game.has_flag("ch01_tv_black") and not Game.has_flag("ch01_tv_fallen"), "first thrust: song stops, screen goes black, TV still standing")
	guard = 0
	while Dialogue.is_active() and guard < 600:
		guard += 1
		await get_tree().process_frame
	await get_tree().create_timer(0.3).timeout
	tv.use(null)
	guard = 0
	while not Game.has_flag("ch01_tv_smashed") and guard < 900:
		guard += 1
		await get_tree().process_frame
	_check(Game.has_flag("ch01_tv_fallen") and Game.has_flag("ch01_tv_smashed"), "second thrust: the TV topples")
	_check(is_equal_approx(Game.flea, 25.0), "chapter total is Flea +25 (got %.1f)" % Game.flea)

	# ending
	guard = 0
	while not done[0] and guard < 1200:
		guard += 1
		await get_tree().process_frame
	_check(done[0] and Game.has_flag("ch01_done"), "chapter completes via complete()")

	print("RESULT: %s" % ("ALL PASS" if _fails == 0 else "%d FAILED" % _fails))
	_pumping = false
	get_tree().quit(0 if _fails == 0 else 1)


## Every narrated line and the letter must appear word-for-word in the source story.
func _verbatim_checks() -> void:
	var story := FileAccess.get_file_as_string("res://docs/source/STORY.md").replace("\r", "")
	var ids := ["ch01_intro", "ch01_rip", "ch01_kick", "ch01_broom", "ch01_tv1", "ch01_tv2", "ch01_end"]
	var bad := 0
	for id in ids:
		var d := DialogueData.from_file("res://data/dialogue/%s.json" % id)
		_check(d.is_valid() and d.todo_verbatim_count == 0, "%s is valid with no TODO_VERBATIM" % id)
		for node_id in d.nodes:
			var text := str((d.nodes[node_id] as Dictionary).get("text", ""))
			if not story.contains(text):
				bad += 1
				print("  not in story: ", text.left(60))
	_check(bad == 0, "all dialogue lines are verbatim from STORY.md")
	var letter := FileAccess.get_file_as_string("res://data/text/ch01_letter.txt").replace("\r", "").strip_edges()
	_check(story.contains(letter), "letter text is verbatim from STORY.md")


func _wait_stage(stage_name: String, timeout: float) -> bool:
	var t := 0.0
	while _chapter.get("stage") != stage_name and t < timeout:
		await get_tree().process_frame
		t += get_process_delta_time()
	return _chapter.get("stage") == stage_name


## Advances any running dialogue (skip typing, then advance) so the test never waits on a human.
func _pump_dialogue() -> void:
	var box: DialogueBox = Dialogue.get_child(0)
	while _pumping and is_inside_tree():
		await get_tree().create_timer(0.25).timeout
		if Dialogue.is_active():
			if box.is_typing():
				box.skip_typing()
			else:
				box.advance_requested.emit()
