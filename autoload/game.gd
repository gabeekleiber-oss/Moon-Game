extends Node
## Global game state: Flea Meter, Household Hearts, flags, counters, Treasure Notepad.
## Also registers the default input map. Owner: Lead.

const VERSION := "0.1.0"
const HEART_MAX := 10

var flea: float = 0.0                       # 0..100
var hearts := {"elsa": 6, "mary_sue": 6, "frank": 6, "self": 6}
var flags := {}                             # name -> true
var counters := {}                          # name -> number
var notepad: Array[Dictionary] = []         # {id, name, value, room}
var settings := {"quality": "auto", "volume": 0.8, "sensitivity": 0.0022,
	"reduced_motion": false, "assist": false}

func _ready() -> void:
	_setup_input()

# ---- meters ----
func add_flea(amount: float, reason: String = "") -> void:
	var old := flea
	flea = clampf(flea + amount, 0.0, 100.0)
	Events.flea_changed.emit(flea, flea - old, reason)

func set_flea(value: float, reason: String = "") -> void:
	add_flea(value - flea, reason)

func add_heart(who: String, amount: int) -> void:
	if not hearts.has(who):
		push_warning("Unknown heart: %s" % who)
		return
	var old: int = hearts[who]
	hearts[who] = clampi(old + amount, 0, HEART_MAX)
	Events.heart_changed.emit(who, hearts[who], hearts[who] - old)

# ---- flags / counters ----
func set_flag(flag_name: String) -> void:
	flags[flag_name] = true
	Events.flag_set.emit(flag_name)

func has_flag(flag_name: String) -> bool:
	return flags.get(flag_name, false)

func bump(counter: String, amount: float = 1.0) -> float:
	counters[counter] = counters.get(counter, 0.0) + amount
	return counters[counter]

# ---- Treasure Notepad ----
func add_notepad_item(id: String, item_name: String, value: int, room: String) -> void:
	for item in notepad:
		if item["id"] == id:
			return
	var entry := {"id": id, "name": item_name, "value": value, "room": room}
	notepad.append(entry)
	Events.notepad_item_added.emit(entry)

func notepad_total() -> int:
	var total := 0
	for item in notepad:
		total += int(item["value"])
	return total

# ---- input ----
func _setup_input() -> void:
	_add_key("move_forward", KEY_W)
	_add_key("move_back", KEY_S)
	_add_key("move_left", KEY_A)
	_add_key("move_right", KEY_D)
	_add_key("jump", KEY_SPACE)
	_add_key("sprint", KEY_SHIFT)
	_add_key("crouch", KEY_C)
	_add_key("interact", KEY_E)
	_add_key("notepad", KEY_Q)
	_add_key("see_family", KEY_F)      # Appraisal Gaze (Ch 9+)
	_add_key("pause", KEY_ESCAPE)
	_add_key("debug_menu", KEY_QUOTELEFT)  # backtick

func _add_key(action: String, key: Key) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action)
	var ev := InputEventKey.new()
	ev.physical_keycode = key
	InputMap.action_add_event(action, ev)
