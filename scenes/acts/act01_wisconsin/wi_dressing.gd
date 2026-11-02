class_name WiDressing
extends RefCounted
## L-01: set-dressing for the Wisconsin house (WORLD_BIBLE "set dresser" pass): living room, kitchen, entry, hall closet,
## Mary Sue's room and the snowy yard. Code-built primitives, every node tagged meta `placeholder` (PLACEHOLDER: swap for real
## CC0 models as they land in assets/). Furniture that the player could bump is solid; small clutter is not.
##
## Keeps clear every beat lane (Sweaty Man's walk, doorways, the player spawn, carry items, the car): tests/test_wi_dressing.gd
## verifies that mechanically. Call once from Act01._act_ready: `WiDressing.dress_all(self)`.
## World coords = WORLD_BIBLE metre grid (rooms are placed by data/world footprints; Mary Sue's room is at y=5).

## Per-space bounds (x, z, w, d) for the keep-inside test.
const BOUNDS := {
	"living_room": Rect2(0.0, 0.0, 6.0, 5.0),
	"kitchen": Rect2(0.0, 5.0, 6.0, 4.0),
	"entry": Rect2(6.0, 0.0, 3.0, 5.0),
	"hall_closet": Rect2(6.0, 5.0, 3.0, 4.0),
	"marysue_room": Rect2(0.0, 0.0, 5.0, 4.0),
	"yard": Rect2(9.0, -8.0, 24.0, 22.0),
}
const MARY_Y := 5.0

static var _mats: Dictionary = {}


static func dress_all(root: Node3D) -> Node3D:
	var dressing := Node3D.new()
	dressing.name = "Dressing"
	root.add_child(dressing)
	for room_name in BOUNDS:
		var n := Node3D.new()
		n.name = room_name
		dressing.add_child(n)
	_living_room(dressing.get_node("living_room"))
	_kitchen(dressing.get_node("kitchen"))
	_entry(dressing.get_node("entry"))
	_hall_closet(dressing.get_node("hall_closet"))
	_marysue_room(dressing.get_node("marysue_room"))
	_yard(dressing.get_node("yard"))
	_fish_tank_details(root)
	return dressing


# ------------------------------------------------------------------ living room
static func _living_room(r: Node3D) -> void:
	var wood := Color(0.36, 0.25, 0.16)
	var tape_colors := [Color(0.15, 0.15, 0.17), Color(0.5, 0.15, 0.15), Color(0.2, 0.3, 0.5), Color(0.8, 0.75, 0.6), Color(0.15, 0.35, 0.2)]
	# TV extras: dust on top, rabbit-ear antenna.
	_b(r, "TVDust", Vector3(0.45, 1.075, 2.5), Vector3(0.6, 0.006, 0.7), Color(0.74, 0.73, 0.69))
	_b(r, "AntennaBase", Vector3(0.45, 1.09, 2.35), Vector3(0.12, 0.03, 0.12), Color(0.1, 0.1, 0.1))
	_b(r, "AntennaL", Vector3(0.45, 1.3, 2.28), Vector3(0.01, 0.45, 0.01), Color(0.7, 0.7, 0.72), false, Vector3(30, 0, 0))
	_b(r, "AntennaR", Vector3(0.45, 1.3, 2.42), Vector3(0.01, 0.45, 0.01), Color(0.7, 0.7, 0.72), false, Vector3(-30, 0, 0))
	# VHS cabinet with a row of tapes and two stacks.
	_b(r, "VHSCabinet", Vector3(0.3, 0.5, 0.9), Vector3(0.5, 1.0, 0.9), wood, true)
	for i in 9:
		_b(r, "VHSTape%d" % i, Vector3(0.3, 1.1, 0.55 + i * 0.09), Vector3(0.19, 0.1, 0.03), tape_colors[i % tape_colors.size()])
	_b(r, "TapeStackA", Vector3(0.3, 1.03, 1.25), Vector3(0.19, 0.06, 0.11), tape_colors[1], false, Vector3(0, 12, 0))
	_b(r, "TapeStackB", Vector3(0.3, 1.0, 0.45), Vector3(0.19, 0.04, 0.11), tape_colors[3], false, Vector3(0, -8, 0))
	# Family photos above the cabinet.
	for i in 3:
		_b(r, "PhotoFrame%d" % i, Vector3(0.07, 1.6, 0.6 + i * 0.35), Vector3(0.03, 0.35, 0.25), Color(0.18, 0.12, 0.08))
		_b(r, "Photo%d" % i, Vector3(0.09, 1.6, 0.6 + i * 0.35), Vector3(0.01, 0.27, 0.18), [Color(0.7, 0.6, 0.5), Color(0.5, 0.6, 0.7), Color(0.75, 0.7, 0.55)][i])
	# Coffee table with TV Guide, remote with tape, hard-candy bowl.
	_b(r, "CoffeeTable", Vector3(2.0, 0.22, 2.5), Vector3(0.55, 0.44, 1.1), Color(0.33, 0.22, 0.14), true)
	_b(r, "TVGuide", Vector3(2.0, 0.446, 2.15), Vector3(0.2, 0.012, 0.27), Color(0.25, 0.4, 0.7), false, Vector3(0, 14, 0))
	_b(r, "Remote", Vector3(1.9, 0.455, 2.85), Vector3(0.05, 0.02, 0.2), Color(0.1, 0.1, 0.1), false, Vector3(0, -10, 0))
	_b(r, "RemoteTape", Vector3(1.9, 0.467, 2.85), Vector3(0.052, 0.005, 0.05), Color(0.85, 0.8, 0.5))
	_c(r, "CandyBowl", Vector3(2.05, 0.48, 2.5), 0.12, 0.08, Color(0.6, 0.75, 0.7))
	for i in 5:
		_s(r, "Candy%d" % i, Vector3(2.0 + (i % 3) * 0.04, 0.54, 2.46 + (i % 2) * 0.05), 0.02, [Color(0.9, 0.2, 0.2), Color(0.95, 0.8, 0.2), Color(0.3, 0.7, 0.3)][i % 3])
	# Couch details: armrests, back, afghan, pillows.
	_b(r, "CouchArmN", Vector3(3.4, 0.45, 1.12), Vector3(0.9, 0.3, 0.16), Color(0.4, 0.27, 0.2))
	_b(r, "CouchArmS", Vector3(3.4, 0.45, 3.88), Vector3(0.9, 0.3, 0.16), Color(0.4, 0.27, 0.2))
	_b(r, "CouchBack", Vector3(3.74, 0.85, 2.5), Vector3(0.2, 0.5, 2.5), Color(0.47, 0.32, 0.24))
	var afghan := [Color(0.8, 0.45, 0.15), Color(0.45, 0.28, 0.12), Color(0.9, 0.85, 0.65), Color(0.3, 0.5, 0.25), Color(0.8, 0.45, 0.15)]
	for i in 5:
		_b(r, "AfghanStripe%d" % i, Vector3(3.74, 1.12, 1.6 + i * 0.22), Vector3(0.24, 0.04, 0.2), afghan[i])
	_b(r, "AfghanDrape", Vector3(3.86, 0.85, 2.7), Vector3(0.03, 0.5, 0.42), Color(0.8, 0.45, 0.15))
	_b(r, "PillowA", Vector3(3.5, 0.68, 3.6), Vector3(0.12, 0.34, 0.34), Color(0.6, 0.25, 0.25), false, Vector3(0, 0, 10))
	_b(r, "PillowB", Vector3(3.5, 0.68, 1.4), Vector3(0.12, 0.34, 0.34), Color(0.3, 0.4, 0.45), false, Vector3(0, 0, -8))
	# Recliner (far corner, out of the door lane), side table, mug, plant.
	_b(r, "Recliner", Vector3(5.0, 0.4, 4.2), Vector3(0.9, 0.8, 0.9), Color(0.55, 0.38, 0.2), true)
	_b(r, "ReclinerFootrest", Vector3(4.42, 0.28, 4.2), Vector3(0.4, 0.14, 0.6), Color(0.5, 0.34, 0.18))
	_b(r, "SideTable", Vector3(5.7, 0.3, 3.9), Vector3(0.45, 0.6, 0.45), Color(0.33, 0.22, 0.14), true)
	_c(r, "Mug", Vector3(5.7, 0.65, 3.9), 0.04, 0.09, Color(0.85, 0.8, 0.7))
	_c(r, "PlantPot", Vector3(5.7, 0.18, 4.75), 0.16, 0.36, Color(0.65, 0.35, 0.22))
	for i in 5:
		_s(r, "Leaf%d" % i, Vector3(5.7 + (i - 2) * 0.07, 0.5 + (i % 3) * 0.12, 4.75 + ((i * 7) % 3 - 1) * 0.05), 0.11, Color(0.25, 0.5, 0.25))
	# Floor lamp (matches the practical light at 5.4,1.9,0.5).
	_c(r, "FloorLampPole", Vector3(5.4, 0.85, 0.5), 0.02, 1.7, Color(0.2, 0.2, 0.2))
	_c(r, "FloorLampShade", Vector3(5.4, 1.85, 0.5), 0.2, 0.3, Color(0.9, 0.8, 0.6), false, 0.35)
	# Window on the north wall with snow light and curtains.
	_b(r, "WindowFrame", Vector3(3.0, 1.45, 0.075), Vector3(1.2, 1.0, 0.04), Color(0.82, 0.8, 0.75))
	_b(r, "WindowSnowLight", Vector3(3.0, 1.45, 0.1), Vector3(1.0, 0.8, 0.01), Color(0.7, 0.8, 0.95), false, Vector3.ZERO, 0.55)
	_b(r, "CurtainL", Vector3(2.25, 1.4, 0.12), Vector3(0.3, 1.2, 0.05), Color(0.75, 0.45, 0.2))
	_b(r, "CurtainR", Vector3(3.75, 1.4, 0.12), Vector3(0.3, 1.2, 0.05), Color(0.75, 0.45, 0.2))
	_b(r, "CurtainRod", Vector3(3.0, 2.1, 0.12), Vector3(1.9, 0.025, 0.025), Color(0.3, 0.25, 0.2))
	_c(r, "WallClock", Vector3(4.6, 1.9, 0.07), 0.15, 0.04, Color(0.9, 0.88, 0.8), false, 0.0, Vector3(90, 0, 0))
	# Knick-knack shelf with ceramic geese.
	_b(r, "KnickShelf", Vector3(0.2, 0.7, 4.3), Vector3(0.3, 1.4, 0.9), wood, true)
	for i in 4:
		_s(r, "Goose%d" % i, Vector3(0.2, 0.42 + (i % 2) * 0.36, 4.05 + (i % 3) * 0.2), 0.05, [Color(0.85, 0.85, 0.8), Color(0.7, 0.8, 0.9), Color(0.9, 0.8, 0.8), Color(0.8, 0.85, 0.7)][i])
	# Floor vent, vacuum lines in the carpet, ceiling fittings.
	_b(r, "FloorVent", Vector3(4.4, 0.006, 1.0), Vector3(0.3, 0.01, 0.14), Color(0.15, 0.15, 0.15))
	for i in 3:
		_b(r, "VentSlat%d" % i, Vector3(4.4, 0.012, 0.96 + i * 0.04), Vector3(0.26, 0.004, 0.012), Color(0.45, 0.45, 0.45))
	for i in 6:
		_b(r, "VacuumLine%d" % i, Vector3(3.0, 0.004, 0.6 + i * 0.7), Vector3(4.6, 0.003, 0.07), Color(0.6, 0.58, 0.56))
	_c(r, "SmokeDetector", Vector3(1.4, 2.385, 3.6), 0.08, 0.03, Color(0.92, 0.92, 0.9))
	_c(r, "CeilingFixture", Vector3(3.0, 2.36, 2.5), 0.25, 0.07, Color(0.9, 0.85, 0.7), false, 0.2)


# ------------------------------------------------------------------ kitchen
static func _kitchen(r: Node3D) -> void:
	var cabinet := Color(0.62, 0.5, 0.25)
	# Counter run (the counter body itself is built by Act01 at z=8.6): backsplash, uppers, sink, appliances.
	_b(r, "Backsplash", Vector3(1.8, 1.15, 8.97), Vector3(2.6, 0.4, 0.03), Color(0.7, 0.78, 0.72))
	_b(r, "UpperCabinets", Vector3(1.8, 1.8, 8.8), Vector3(2.6, 0.7, 0.35), cabinet)
	for i in 5:
		_b(r, "CabinetDoorLine%d" % i, Vector3(0.5 + i * 0.65, 1.8, 8.62), Vector3(0.02, 0.62, 0.01), Color(0.3, 0.22, 0.1))
		_b(r, "CabinetPull%d" % i, Vector3(0.55 + i * 0.65, 1.62, 8.61), Vector3(0.03, 0.08, 0.02), Color(0.7, 0.65, 0.3))
	_b(r, "SinkBasin", Vector3(2.75, 0.905, 8.6), Vector3(0.5, 0.02, 0.4), Color(0.6, 0.62, 0.64))
	_c(r, "Faucet", Vector3(2.75, 1.0, 8.85), 0.02, 0.2, Color(0.75, 0.75, 0.78))
	_b(r, "DishRack", Vector3(0.8, 0.96, 8.6), Vector3(0.45, 0.12, 0.3), Color(0.75, 0.75, 0.72))
	_b(r, "Toaster", Vector3(1.6, 1.0, 8.82), Vector3(0.28, 0.18, 0.18), Color(0.8, 0.8, 0.78))
	_b(r, "CoffeeMaker", Vector3(0.65, 1.07, 8.82), Vector3(0.22, 0.3, 0.2), Color(0.12, 0.12, 0.12))
	_c(r, "CoffeePot", Vector3(0.65, 0.99, 8.7), 0.07, 0.14, Color(0.2, 0.15, 0.1))
	_c(r, "CookieJar", Vector3(3.0, 1.03, 8.82), 0.1, 0.22, Color(0.85, 0.7, 0.4))
	# Fridge with magnets and papers; stove with a pot and hood.
	_b(r, "Fridge", Vector3(5.3, 0.9, 8.55), Vector3(0.8, 1.8, 0.7), Color(0.82, 0.78, 0.68), true)
	_b(r, "FridgeHandle", Vector3(5.0, 1.1, 8.18), Vector3(0.03, 0.6, 0.03), Color(0.6, 0.6, 0.6))
	for i in 5:
		_b(r, "FridgePaper%d" % i, Vector3(5.1 + (i % 3) * 0.15, 1.2 + (i % 2) * 0.25, 8.195), Vector3(0.1, 0.13, 0.005), [Color(0.95, 0.9, 0.6), Color(0.9, 0.5, 0.5), Color(0.6, 0.8, 0.9), Color(0.95, 0.95, 0.9), Color(0.5, 0.8, 0.5)][i])
	_b(r, "Stove", Vector3(4.2, 0.45, 8.6), Vector3(0.75, 0.9, 0.7), Color(0.92, 0.92, 0.9), true)
	for i in 4:
		_c(r, "Burner%d" % i, Vector3(4.0 + (i % 2) * 0.35, 0.915, 8.45 + (i / 2) * 0.28), 0.1, 0.02, Color(0.12, 0.12, 0.12))
	_c(r, "StovePot", Vector3(4.0, 1.0, 8.45), 0.11, 0.16, Color(0.55, 0.55, 0.58))
	_b(r, "RangeHood", Vector3(4.2, 1.75, 8.75), Vector3(0.8, 0.3, 0.45), Color(0.85, 0.85, 0.82))
	_b(r, "DishTowel", Vector3(4.2, 0.7, 8.24), Vector3(0.25, 0.35, 0.02), Color(0.7, 0.3, 0.3))
	# Table, three chairs, table clutter.
	_b(r, "KitchenTable", Vector3(3.8, 0.375, 6.7), Vector3(1.0, 0.75, 1.0), Color(0.75, 0.7, 0.6), true)
	for i in 3:
		var p: Vector3 = [Vector3(4.55, 0.23, 6.7), Vector3(3.05, 0.23, 6.7), Vector3(3.8, 0.23, 7.45)][i]
		_b(r, "ChairSeat%d" % i, p, Vector3(0.4, 0.46, 0.4), Color(0.55, 0.3, 0.22), true)
	_b(r, "ChairBackE", Vector3(4.78, 0.7, 6.7), Vector3(0.04, 0.5, 0.4), Color(0.55, 0.3, 0.22))
	_b(r, "ChairBackW", Vector3(2.82, 0.7, 6.7), Vector3(0.04, 0.5, 0.4), Color(0.55, 0.3, 0.22))
	_b(r, "ChairBackS", Vector3(3.8, 0.7, 7.68), Vector3(0.4, 0.5, 0.04), Color(0.55, 0.3, 0.22))
	_c(r, "FruitBowl", Vector3(3.8, 0.79, 6.7), 0.15, 0.08, Color(0.8, 0.6, 0.3))
	for i in 3:
		_s(r, "Fruit%d" % i, Vector3(3.74 + i * 0.06, 0.88, 6.68 + (i % 2) * 0.05), 0.045, [Color(0.8, 0.2, 0.2), Color(0.9, 0.8, 0.2), Color(0.6, 0.75, 0.25)][i])
	for i in 3:
		_b(r, "Placemat%d" % i, Vector3(4.2 - i * 0.4, 0.752, 6.3 + (i % 2) * 0.05), Vector3(0.3, 0.004, 0.22), Color(0.8, 0.35, 0.3))
	_c(r, "SaltShaker", Vector3(3.5, 0.82, 6.95), 0.02, 0.1, Color(0.9, 0.9, 0.9))
	_c(r, "PepperShaker", Vector3(3.56, 0.82, 6.95), 0.02, 0.1, Color(0.2, 0.2, 0.2))
	_b(r, "MailPile", Vector3(4.05, 0.77, 7.0), Vector3(0.22, 0.04, 0.3), Color(0.9, 0.88, 0.8), false, Vector3(0, 20, 0))
	_b(r, "NapkinHolder", Vector3(3.9, 0.82, 6.95), Vector3(0.1, 0.1, 0.05), Color(0.6, 0.6, 0.6))
	# Walls: window with snow light, clock, calendar, corkboard.
	_b(r, "KWindowFrame", Vector3(0.075, 1.5, 6.9), Vector3(0.04, 0.9, 1.0), Color(0.85, 0.83, 0.78))
	_b(r, "KWindowSnowLight", Vector3(0.1, 1.5, 6.9), Vector3(0.01, 0.7, 0.8), Color(0.7, 0.8, 0.95), false, Vector3.ZERO, 0.55)
	_b(r, "KValance", Vector3(0.12, 1.95, 6.9), Vector3(0.05, 0.18, 1.1), Color(0.8, 0.6, 0.2))
	_c(r, "KClock", Vector3(0.07, 1.9, 5.9), 0.14, 0.04, Color(0.9, 0.88, 0.8), false, 0.0, Vector3(0, 0, 90))
	_b(r, "Calendar", Vector3(0.07, 1.4, 5.8), Vector3(0.03, 0.4, 0.3), Color(0.9, 0.9, 0.85))
	_b(r, "Corkboard", Vector3(0.07, 1.3, 8.0), Vector3(0.03, 0.4, 0.6), Color(0.6, 0.45, 0.28))
	for i in 3:
		_b(r, "CorkNote%d" % i, Vector3(0.1, 1.3 + (i % 2) * 0.1, 7.8 + i * 0.18), Vector3(0.01, 0.1, 0.1), Color(0.95, 0.9, 0.55))
	# Floor: braided rug, trash can; ceiling fluorescent.
	var rug := _c(r, "BraidedRug", Vector3(1.8, 0.006, 7.5), 0.6, 0.01, Color(0.6, 0.28, 0.22))
	rug.scale = Vector3(1.4, 1.0, 1.0)
	_c(r, "TrashCan", Vector3(0.45, 0.3, 5.4), 0.2, 0.6, Color(0.7, 0.7, 0.72), true)
	_b(r, "FluorescentFixture", Vector3(3.0, 2.36, 7.0), Vector3(1.2, 0.05, 0.25), Color(0.95, 0.95, 0.85), false, Vector3.ZERO, 0.25)


# ------------------------------------------------------------------ entry
static func _entry(r: Node3D) -> void:
	# Phone table clutter (the phone itself is Act01's carryable).
	_b(r, "AnsweringMachine", Vector3(6.75, 0.84, 0.6), Vector3(0.25, 0.08, 0.2), Color(0.75, 0.74, 0.7))
	_b(r, "AnsweringLED", Vector3(6.8, 0.885, 0.6), Vector3(0.02, 0.01, 0.02), Color(1.0, 0.2, 0.2), false, Vector3.ZERO, 1.5)
	_b(r, "Notepad", Vector3(7.25, 0.805, 0.6), Vector3(0.15, 0.01, 0.2), Color(0.95, 0.92, 0.6))
	_b(r, "Pen", Vector3(7.28, 0.815, 0.62), Vector3(0.01, 0.01, 0.14), Color(0.15, 0.2, 0.5), false, Vector3(0, 30, 0))
	_b(r, "PhoneBook", Vector3(7.25, 0.835, 0.4), Vector3(0.22, 0.06, 0.28), Color(0.85, 0.75, 0.2))
	# Coat rail with four coats.
	_b(r, "CoatBoard", Vector3(7.75, 1.7, 0.08), Vector3(1.8, 0.08, 0.04), Color(0.35, 0.25, 0.15))
	var coats := [Color(0.5, 0.2, 0.2), Color(0.2, 0.3, 0.45), Color(0.3, 0.4, 0.25), Color(0.55, 0.45, 0.25)]
	for i in 4:
		_b(r, "Coat%d" % i, Vector3(7.0 + i * 0.5, 1.2, 0.17), Vector3(0.3, 0.9, 0.12), coats[i])
		_c(r, "CoatHook%d" % i, Vector3(7.0 + i * 0.5, 1.7, 0.12), 0.012, 0.08, Color(0.6, 0.55, 0.3), false, 0.0, Vector3(90, 0, 0))
	# Boot tray, boots, wet prints, salt stains, doormat.
	_b(r, "BootTray", Vector3(8.4, 0.02, 0.8), Vector3(0.9, 0.04, 0.45), Color(0.1, 0.1, 0.1))
	for i in 4:
		_b(r, "Boot%d" % i, Vector3(8.1 + i * 0.2, 0.15, 0.8 + (i % 2) * 0.08), Vector3(0.12, 0.26, 0.3), Color(0.3, 0.22, 0.15), false, Vector3(0, (i % 2) * 15.0, 0))
	for i in 7:
		_b(r, "WetPrint%d" % i, Vector3(8.4 - i * 0.28, 0.004, 2.3 + (i % 2) * 0.4), Vector3(0.1, 0.003, 0.28), Color(0.33, 0.31, 0.28), false, Vector3(0, 8.0 * ((i % 2) * 2 - 1), 0))
	for i in 4:
		_b(r, "SaltStain%d" % i, Vector3(8.3 - i * 0.55, 0.004, 1.9 + (i % 3) * 0.4), Vector3(0.35, 0.003, 0.2), Color(0.82, 0.82, 0.8), false, Vector3(0, i * 25.0, 0))
	_b(r, "Doormat", Vector3(8.55, 0.012, 2.5), Vector3(0.8, 0.024, 1.2), Color(0.35, 0.25, 0.15))
	# Wall fittings: thermostat, mirror, light switches; umbrella stand; shoe pile.
	_b(r, "Thermostat", Vector3(6.06, 1.5, 4.3), Vector3(0.03, 0.12, 0.12), Color(0.88, 0.85, 0.75))
	_b(r, "MirrorFrame", Vector3(8.93, 1.5, 1.0), Vector3(0.03, 0.75, 0.55), Color(0.4, 0.3, 0.2))
	_b(r, "Mirror", Vector3(8.91, 1.5, 1.0), Vector3(0.01, 0.65, 0.45), Color(0.65, 0.72, 0.78), false, Vector3.ZERO, 0.0, 0.1)
	for i in 2:
		_b(r, "SwitchPlate%d" % i, Vector3(8.94, 1.3, 3.5 + i * 0.12), Vector3(0.02, 0.1, 0.07), Color(0.9, 0.88, 0.8))
	_c(r, "UmbrellaStand", Vector3(6.3, 0.25, 4.5), 0.12, 0.5, Color(0.2, 0.25, 0.3))
	_b(r, "Umbrella1", Vector3(6.3, 0.62, 4.5), Vector3(0.03, 0.5, 0.03), Color(0.1, 0.1, 0.1), false, Vector3(0, 0, 8))
	_b(r, "Umbrella2", Vector3(6.34, 0.6, 4.46), Vector3(0.03, 0.46, 0.03), Color(0.5, 0.15, 0.15), false, Vector3(0, 0, -6))
	for i in 3:
		_b(r, "Shoe%d" % i, Vector3(6.6 + i * 0.16, 0.05, 4.6), Vector3(0.1, 0.1, 0.26), Color(0.45, 0.4, 0.35), false, Vector3(0, i * 40.0, 0))
	_c(r, "EntryFixture", Vector3(7.5, 2.36, 2.5), 0.2, 0.07, Color(0.9, 0.85, 0.7), false, 0.2)


# ------------------------------------------------------------------ hall closet
static func _hall_closet(r: Node3D) -> void:
	# Coat rod with coats along the east wall.
	_b(r, "ClosetRod", Vector3(8.75, 1.75, 6.9), Vector3(0.03, 0.03, 2.2), Color(0.5, 0.5, 0.5))
	for i in 5:
		_b(r, "ClosetCoat%d" % i, Vector3(8.7, 1.25, 5.9 + i * 0.38), Vector3(0.18, 0.9, 0.3), [Color(0.35, 0.3, 0.25), Color(0.2, 0.25, 0.35), Color(0.45, 0.2, 0.2), Color(0.3, 0.35, 0.3), Color(0.5, 0.45, 0.35)][i])
	# Shelf unit with the clutter closets collect.
	_b(r, "ClosetShelf", Vector3(7.4, 1.0, 8.75), Vector3(1.6, 2.0, 0.4), Color(0.4, 0.3, 0.2), true)
	_b(r, "ChristmasBox", Vector3(7.0, 2.12, 8.55), Vector3(0.45, 0.22, 0.3), Color(0.7, 0.2, 0.2))
	_b(r, "Tupperware", Vector3(7.5, 1.58, 8.55), Vector3(0.3, 0.14, 0.22), Color(0.85, 0.85, 0.9))
	_c(r, "PaintCan", Vector3(7.9, 1.07, 8.55), 0.08, 0.16, Color(0.6, 0.6, 0.62))
	_c(r, "Flashlight", Vector3(7.1, 1.03, 8.55), 0.03, 0.2, Color(0.1, 0.1, 0.1), false, 0.0, Vector3(0, 0, 90))
	_b(r, "CleaningBottle", Vector3(7.6, 0.56, 8.55), Vector3(0.07, 0.22, 0.07), Color(0.3, 0.7, 0.6))
	# Upright vacuum, mop bucket, boots, dust bunnies, bare bulb.
	_b(r, "VacuumBody", Vector3(6.6, 0.6, 8.4), Vector3(0.28, 1.0, 0.22), Color(0.45, 0.1, 0.1), true)
	_b(r, "VacuumBase", Vector3(6.6, 0.07, 8.28), Vector3(0.36, 0.14, 0.3), Color(0.15, 0.15, 0.15))
	_b(r, "VacuumHandle", Vector3(6.6, 1.35, 8.46), Vector3(0.04, 0.5, 0.04), Color(0.2, 0.2, 0.2), false, Vector3(-15, 0, 0))
	_c(r, "MopBucket", Vector3(8.0, 0.15, 8.6), 0.15, 0.3, Color(0.85, 0.75, 0.2))
	for i in 3:
		_b(r, "ClosetBoot%d" % i, Vector3(8.4 + i * 0.15, 0.13, 5.45 + (i % 2) * 0.05), Vector3(0.12, 0.26, 0.28), Color(0.25, 0.2, 0.18))
	for i in 5:
		_s(r, "DustBunny%d" % i, Vector3(6.5 + i * 0.5, 0.03, 5.7 + (i * 5 % 4) * 0.3), 0.04, Color(0.65, 0.63, 0.6))
	_s(r, "BareBulb", Vector3(7.5, 2.25, 7.0), 0.05, Color(1.0, 0.9, 0.6), false, 1.2)
	_b(r, "PullChain", Vector3(7.5, 2.1, 7.0), Vector3(0.004, 0.25, 0.004), Color(0.7, 0.7, 0.7))


# ------------------------------------------------------------------ Mary Sue's room (upstairs, y = 5)
static func _marysue_room(r: Node3D) -> void:
	var y := MARY_Y
	# Bed with quilt, pillow, headboard and stuffed animals.
	_b(r, "Bed", Vector3(3.3, y + 0.25, 3.35), Vector3(2.0, 0.5, 0.95), Color(0.55, 0.4, 0.3), true)
	_b(r, "Quilt", Vector3(3.5, y + 0.55, 3.35), Vector3(1.6, 0.1, 0.9), Color(0.7, 0.45, 0.65))
	_b(r, "QuiltStripe", Vector3(3.5, y + 0.605, 3.35), Vector3(0.3, 0.01, 0.9), Color(0.9, 0.8, 0.5))
	_b(r, "Pillow", Vector3(2.55, y + 0.58, 3.35), Vector3(0.5, 0.12, 0.35), Color(0.95, 0.9, 0.9))
	_b(r, "Headboard", Vector3(2.27, y + 0.6, 3.35), Vector3(0.08, 0.9, 1.0), Color(0.45, 0.3, 0.2))
	for i in 3:
		_b(r, "PlushBody%d" % i, Vector3(2.9 + i * 0.35, y + 0.72, 3.2 + (i % 2) * 0.2), Vector3(0.18, 0.18, 0.15), [Color(0.6, 0.4, 0.25), Color(0.9, 0.7, 0.8), Color(0.5, 0.6, 0.85)][i])
		_s(r, "PlushHead%d" % i, Vector3(2.9 + i * 0.35, y + 0.89, 3.2 + (i % 2) * 0.2), 0.08, [Color(0.6, 0.4, 0.25), Color(0.9, 0.7, 0.8), Color(0.5, 0.6, 0.85)][i])
	# Desk clutter (the desk and tank are Act01's).
	_b(r, "DeskLampBase", Vector3(0.45, y + 0.83, 0.55), Vector3(0.14, 0.04, 0.14), Color(0.2, 0.2, 0.2))
	_b(r, "DeskLampArm", Vector3(0.45, y + 1.05, 0.55), Vector3(0.02, 0.4, 0.02), Color(0.3, 0.3, 0.3), false, Vector3(0, 0, 15))
	_c(r, "PencilCup", Vector3(1.6, y + 0.87, 0.6), 0.045, 0.1, Color(0.8, 0.3, 0.3))
	_b(r, "Notebook", Vector3(1.35, y + 0.805, 0.95), Vector3(0.2, 0.02, 0.27), Color(0.3, 0.45, 0.7), false, Vector3(0, 18, 0))
	_c(r, "FishFoodCan", Vector3(1.55, y + 0.86, 0.9), 0.04, 0.1, Color(0.85, 0.3, 0.2))
	for i in 6:
		_b(r, "Flake%d" % i, Vector3(1.4 + (i % 3) * 0.07, y + 0.802, 0.78 + (i % 2) * 0.05), Vector3(0.015, 0.003, 0.015), Color(0.9, 0.6, 0.3))
	_b(r, "PumpUnit", Vector3(0.3, y + 0.89, 0.95), Vector3(0.12, 0.15, 0.12), Color(0.1, 0.1, 0.12))
	_b(r, "PumpTube", Vector3(0.6, y + 0.82, 0.95), Vector3(0.6, 0.01, 0.01), Color(0.7, 0.8, 0.85))
	# Posters (one with a taped corner), calendar, bookshelf.
	var poster_colors := [Color(0.8, 0.3, 0.5), Color(0.3, 0.5, 0.8), Color(0.9, 0.75, 0.3), Color(0.35, 0.7, 0.5), Color(0.6, 0.35, 0.75)]
	for i in 5:
		_b(r, "Poster%d" % i, Vector3(0.07, y + 1.45 + (i % 2) * 0.35, 1.6 + i * 0.45), Vector3(0.02, 0.55, 0.38), poster_colors[i])
	_b(r, "PosterTape", Vector3(0.09, y + 1.75, 1.43), Vector3(0.015, 0.05, 0.05), Color(0.95, 0.92, 0.7), false, Vector3(30, 0, 0))
	_b(r, "MCalendar", Vector3(1.9, y + 1.6, 0.07), Vector3(0.3, 0.4, 0.02), Color(0.92, 0.92, 0.88))
	_b(r, "Bookshelf", Vector3(4.75, y + 0.9, 0.8), Vector3(0.3, 1.8, 0.9), Color(0.4, 0.3, 0.2), true)
	for i in 9:
		_b(r, "Book%d" % i, Vector3(4.7, y + 0.45 + (i / 3) * 0.55, 0.5 + (i % 3) * 0.28), Vector3(0.2, 0.3, 0.08), [Color(0.7, 0.3, 0.3), Color(0.3, 0.5, 0.7), Color(0.85, 0.75, 0.3), Color(0.3, 0.6, 0.4)][i % 4])
	# Window with snow light and curtains; rug; clothes; slippers; nightlight; damp stain.
	_b(r, "MWindowFrame", Vector3(1.5, y + 1.5, 3.925), Vector3(1.1, 0.95, 0.04), Color(0.85, 0.83, 0.78))
	_b(r, "MWindowSnowLight", Vector3(1.5, y + 1.5, 3.9), Vector3(0.95, 0.8, 0.01), Color(0.7, 0.8, 0.95), false, Vector3.ZERO, 0.55)
	_b(r, "MCurtainL", Vector3(0.85, y + 1.45, 3.88), Vector3(0.28, 1.2, 0.05), Color(0.6, 0.4, 0.7))
	_b(r, "MCurtainR", Vector3(2.15, y + 1.45, 3.88), Vector3(0.28, 1.2, 0.05), Color(0.6, 0.4, 0.7))
	var rug := _c(r, "RoundRug", Vector3(2.2, y + 0.006, 2.0), 0.9, 0.01, Color(0.45, 0.6, 0.7))
	rug.scale = Vector3(1.0, 1.0, 1.0)
	_b(r, "ClothesPile", Vector3(1.0, y + 0.08, 2.8), Vector3(0.5, 0.16, 0.4), Color(0.6, 0.5, 0.55), false, Vector3(0, 25, 0))
	_b(r, "Slipper1", Vector3(3.6, y + 0.04, 2.7), Vector3(0.1, 0.08, 0.26), Color(0.9, 0.7, 0.75), false, Vector3(0, 20, 0))
	_b(r, "Slipper2", Vector3(3.75, y + 0.04, 2.75), Vector3(0.1, 0.08, 0.26), Color(0.9, 0.7, 0.75), false, Vector3(0, -10, 0))
	_b(r, "Nightlight", Vector3(3.9, y + 0.3, 3.93), Vector3(0.06, 0.08, 0.02), Color(1.0, 0.85, 0.5), false, Vector3.ZERO, 0.8)
	_b(r, "DampStain", Vector3(0.9, y + 2.395, 1.2), Vector3(0.8, 0.004, 0.6), Color(0.58, 0.52, 0.42))


# ------------------------------------------------------------------ yard
static func _yard(r: Node3D) -> void:
	var snow := Color(0.9, 0.93, 0.98)
	# Driveway, plow ridges, slush, footprints from the front door to the car.
	_b(r, "Driveway", Vector3(17.25, 0.006, 2.5), Vector3(15.5, 0.01, 4.6), Color(0.2, 0.2, 0.22), false, Vector3.ZERO, 0.0, 0.5)
	_b(r, "PlowRidgeN", Vector3(17.25, 0.22, -0.2), Vector3(15.5, 0.45, 0.8), snow)
	_b(r, "PlowRidgeS", Vector3(17.25, 0.22, 5.2), Vector3(15.5, 0.45, 0.8), snow)
	for i in 5:
		_b(r, "Slush%d" % i, Vector3(11.0 + i * 3.0, 0.012, 1.0 + (i % 3) * 1.4), Vector3(1.2, 0.004, 0.7), Color(0.55, 0.53, 0.5), false, Vector3(0, i * 30.0, 0))
	for i in 18:
		_b(r, "Footprint%d" % i, Vector3(9.8 + i * 0.3, 0.014, 2.35 + (i % 2) * 0.3), Vector3(0.12, 0.004, 0.3), Color(0.58, 0.6, 0.65), false, Vector3(0, 4.0 * ((i % 2) * 2 - 1), 0))
	# Front stoop, porch light, trash cans, shovel, sled.
	_b(r, "Stoop", Vector3(9.55, 0.075, 2.5), Vector3(1.0, 0.15, 1.6), Color(0.55, 0.52, 0.48))
	_c(r, "PorchLight", Vector3(9.1, 2.0, 1.4), 0.07, 0.14, Color(1.0, 0.9, 0.6), false, 1.2)
	for i in 2:
		_c(r, "TrashCanY%d" % i, Vector3(9.7, 0.45, 0.5 + i * 0.5), 0.22, 0.9, Color(0.25, 0.3, 0.28), true)
		_c(r, "SnowCap%d" % i, Vector3(9.7, 0.92, 0.5 + i * 0.5), 0.23, 0.06, snow)
	_b(r, "ShovelHandle", Vector3(11.0, 0.7, -0.9), Vector3(0.04, 1.0, 0.04), Color(0.5, 0.35, 0.2), false, Vector3(0, 0, 14))
	_b(r, "ShovelBlade", Vector3(11.1, 0.18, -0.9), Vector3(0.3, 0.04, 0.25), Color(0.5, 0.5, 0.55), false, Vector3(0, 0, 14))
	_b(r, "Sled", Vector3(10.6, 0.08, 6.6), Vector3(0.5, 0.06, 1.0), Color(0.75, 0.15, 0.15), false, Vector3(0, 25, 0))
	# Mailbox on a post, streetlight, hedges, bare trees, fence.
	_b(r, "MailboxPost", Vector3(24.0, 0.55, 6.0), Vector3(0.1, 1.1, 0.1), Color(0.4, 0.3, 0.2), true)
	_b(r, "Mailbox", Vector3(24.0, 1.2, 6.0), Vector3(0.22, 0.2, 0.46), Color(0.15, 0.15, 0.17))
	_b(r, "MailboxFlag", Vector3(24.13, 1.3, 5.85), Vector3(0.02, 0.18, 0.04), Color(0.85, 0.2, 0.15))
	_c(r, "StreetlightPole", Vector3(13.0, 2.0, -3.0), 0.06, 4.0, Color(0.2, 0.2, 0.22), true)
	_b(r, "StreetlightArm", Vector3(13.0, 4.0, -2.8), Vector3(0.06, 0.06, 0.5), Color(0.2, 0.2, 0.22))
	_b(r, "StreetlightHead", Vector3(13.0, 3.95, -2.55), Vector3(0.22, 0.1, 0.35), Color(1.0, 0.85, 0.5), false, Vector3.ZERO, 1.0)
	for i in 3:
		_b(r, "Hedge%d" % i, Vector3(9.7, 0.4, 6.5 + i * 1.1), Vector3(0.8, 0.8, 1.0), Color(0.25, 0.4, 0.28), true)
		_b(r, "HedgeSnow%d" % i, Vector3(9.7, 0.82, 6.5 + i * 1.1), Vector3(0.85, 0.1, 1.05), snow)
	var tree_spots := [Vector3(20.0, 0, -5.0), Vector3(24.0, 0, -4.0), Vector3(27.0, 0, 8.0), Vector3(18.0, 0, 9.0)]
	for i in tree_spots.size():
		var t: Vector3 = tree_spots[i]
		_c(r, "TreeTrunk%d" % i, t + Vector3(0, 1.6, 0), 0.15, 3.2, Color(0.3, 0.24, 0.2), true)
		for j in 4:
			_b(r, "Branch%d_%d" % [i, j], t + Vector3(0, 2.6 + j * 0.22, 0), Vector3(1.1, 0.06, 0.06), Color(0.3, 0.24, 0.2), false, Vector3(0, j * 45.0 + i * 20.0, 20.0 * (j % 2 * 2 - 1)))
		_b(r, "TreeSnow%d" % i, t + Vector3(0, 3.25, 0), Vector3(0.4, 0.08, 0.4), snow)
	for i in 8:
		_b(r, "FencePost%d" % i, Vector3(12.0 + i * 2.8, 0.55, 11.0), Vector3(0.1, 1.1, 0.1), Color(0.4, 0.33, 0.25))
	_b(r, "FenceRail", Vector3(21.6, 0.85, 11.0), Vector3(19.6, 0.08, 0.04), Color(0.4, 0.33, 0.25))
	_b(r, "FenceSnow", Vector3(21.6, 0.9, 11.0), Vector3(19.6, 0.04, 0.1), snow)


# ------------------------------------------------------------------ fish tank (children of Act01's carryable so they travel and throw with it)
static func _fish_tank_details(root: Node3D) -> void:
	var tank := root.find_child("FishTank", true, false) as Node3D
	if tank == null:
		return
	# See-through glass so the fish read; details are direct MeshInstance3D children (ThrownProp copies those).
	var glass := tank.find_child("Mesh", true, false) as MeshInstance3D
	if glass != null:
		var m := (glass.material_override as StandardMaterial3D).duplicate() as StandardMaterial3D
		m.albedo_color = Color(0.55, 0.75, 0.85, 0.3)
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		glass.material_override = m
	_child_box(tank, "Gravel", Vector3(0.0, -0.17, 0.0), Vector3(0.66, 0.05, 0.36), Color(0.55, 0.5, 0.42))
	for i in 3:
		_child_box(tank, "Plant%d" % i, Vector3(-0.22 + i * 0.22, -0.06, -0.1), Vector3(0.05, 0.22, 0.05), Color(0.2, 0.55, 0.3))
	for i in 3:
		_child_box(tank, "Fish%d" % i, Vector3(-0.2 + i * 0.2, 0.0 + (i % 2) * 0.07, 0.05), Vector3(0.1, 0.05, 0.03), Color(0.95, 0.55, 0.2))
	_child_box(tank, "Hood", Vector3(0.0, 0.21, 0.0), Vector3(0.7, 0.03, 0.4), Color(0.12, 0.12, 0.14))


static func _child_box(parent: Node3D, n: String, pos: Vector3, size: Vector3, col: Color) -> void:
	var mi := MeshInstance3D.new()
	mi.name = n
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = _mat(col, 0.7, 0.0)
	mi.position = pos
	mi.set_meta("placeholder", true)
	parent.add_child(mi)


# ------------------------------------------------------------------ primitives
static func _mat(col: Color, rough: float, emit: float) -> StandardMaterial3D:
	var key := "%s|%s|%s" % [col.to_html(true), rough, emit]
	if _mats.has(key) and is_instance_valid(_mats[key]):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = rough
	if col.a < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if emit > 0.0:
		m.emission_enabled = true
		m.emission = col
		m.emission_energy_multiplier = emit
	_mats[key] = m
	return m


static func _wrap(parent: Node3D, n: String, mesh: Mesh, shape: Shape3D, pos: Vector3, rot: Vector3, mat: Material, solid: bool) -> Node3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	var node: Node3D = mi
	if solid:
		var body := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		cs.shape = shape
		body.add_child(cs)
		mi.name = "Mesh"
		body.add_child(mi)
		node = body
	node.name = n
	node.position = pos
	node.rotation_degrees = rot
	node.set_meta("placeholder", true)
	parent.add_child(node)
	return node


static func _b(parent: Node3D, n: String, pos: Vector3, size: Vector3, col: Color, solid: bool = false, rot: Vector3 = Vector3.ZERO, emit: float = 0.0, rough: float = 0.9) -> Node3D:
	var bm := BoxMesh.new()
	bm.size = size
	var bs := BoxShape3D.new()
	bs.size = size
	return _wrap(parent, n, bm, bs, pos, rot, _mat(col, rough, emit), solid)


static func _c(parent: Node3D, n: String, pos: Vector3, radius: float, height: float, col: Color, solid: bool = false, emit: float = 0.0, rot: Vector3 = Vector3.ZERO) -> Node3D:
	var cm := CylinderMesh.new()
	cm.top_radius = radius
	cm.bottom_radius = radius
	cm.height = height
	cm.radial_segments = 16
	var cs := CylinderShape3D.new()
	cs.radius = radius
	cs.height = height
	return _wrap(parent, n, cm, cs, pos, rot, _mat(col, 0.85, emit), solid)


static func _s(parent: Node3D, n: String, pos: Vector3, radius: float, col: Color, solid: bool = false, emit: float = 0.0) -> Node3D:
	var sm := SphereMesh.new()
	sm.radius = radius
	sm.height = radius * 2.0
	sm.radial_segments = 12
	sm.rings = 6
	var ss := SphereShape3D.new()
	ss.radius = radius
	return _wrap(parent, n, sm, ss, pos, Vector3.ZERO, _mat(col, 0.85, emit), solid)
