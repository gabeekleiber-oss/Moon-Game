class_name BirdSpecies
extends RefCounted
## Twelve bird species palettes for the Bird Room / Ch6 (F-11). Data only; no lore is implied (Canon: add no lore).
##
## `BirdSpecies.get_species(3)` returns {id, name, body, belly, wing, head, beak, eye, size} (all colours are Color).
## `size` is a body-scale multiplier (1.0 = sparrow-sized, about 0.16 m long). Index wraps, so any int is safe.
## `BirdSpecies.COUNT` is 12. Names are made up for the game and deliberately silly (Seuss tone).
const COUNT := 12

const SPECIES: Array[Dictionary] = [
	{"id": "marigold_finch", "name": "Marigold Finch", "body": Color("e8a523"), "belly": Color("f6d56a"), "wing": Color("5a3b1d"), "head": Color("e8a523"), "beak": Color("c9703a"), "size": 0.9},
	{"id": "ink_wren", "name": "Ink Wren", "body": Color("27294a"), "belly": Color("4b4f86"), "wing": Color("171830"), "head": Color("27294a"), "beak": Color("d9c9a0"), "size": 0.8},
	{"id": "rose_dove", "name": "Rose Dove", "body": Color("d9a0a8"), "belly": Color("f2d6d6"), "wing": Color("a8707c"), "head": Color("e8c2c4"), "beak": Color("7a5058"), "size": 1.3},
	{"id": "teal_jay", "name": "Teal Jay", "body": Color("1f8a8a"), "belly": Color("e9f0e4"), "wing": Color("124f5c"), "head": Color("27a6a0"), "beak": Color("222222"), "size": 1.2},
	{"id": "ruby_robin", "name": "Ruby Robin", "body": Color("7a4a35"), "belly": Color("c93a2b"), "wing": Color("4d2f22"), "head": Color("5b3626"), "beak": Color("e0b24a"), "size": 1.0},
	{"id": "milk_owlet", "name": "Milk Owlet", "body": Color("e9e2cf"), "belly": Color("fbf6e6"), "wing": Color("b9ac90"), "head": Color("f3ecd8"), "beak": Color("d4a24a"), "size": 1.5},
	{"id": "moss_warbler", "name": "Moss Warbler", "body": Color("7f9a3d"), "belly": Color("d3dc8a"), "wing": Color("4d6224"), "head": Color("93ad47"), "beak": Color("5b4a2a"), "size": 0.85},
	{"id": "violet_swift", "name": "Violet Swift", "body": Color("6a3d9a"), "belly": Color("a98ad0"), "wing": Color("3b2160"), "head": Color("7e52b0"), "beak": Color("1a1a1a"), "size": 1.05},
	{"id": "copper_crow", "name": "Copper Crow", "body": Color("2b2420"), "belly": Color("5a3d2c"), "wing": Color("b36a2e"), "head": Color("2b2420"), "beak": Color("4a3a2e"), "size": 1.7},
	{"id": "peach_puffin", "name": "Peach Puffin", "body": Color("2f3a4a"), "belly": Color("fbe7d4"), "wing": Color("1f2833"), "head": Color("f6d2b0"), "beak": Color("ef7b3f"), "size": 1.25},
	{"id": "sky_bunting", "name": "Sky Bunting", "body": Color("5fb4e6"), "belly": Color("d9eefb"), "wing": Color("2a77b0"), "head": Color("8dcdf0"), "beak": Color("f1c24a"), "size": 0.9},
	{"id": "gold_canary", "name": "Gold Canary", "body": Color("f6c915"), "belly": Color("fff0a0"), "wing": Color("c99a0a"), "head": Color("f9d93a"), "beak": Color("e8873a"), "size": 0.85},
]

## The species dictionary for `index` (wraps around, negatives too) with an `eye` colour added.
static func get_species(index: int) -> Dictionary:
	var d: Dictionary = SPECIES[posmod(index, COUNT)].duplicate()
	d["eye"] = Color(0.05, 0.04, 0.05)
	return d


## All twelve species ids, in order.
static func ids() -> PackedStringArray:
	var out := PackedStringArray()
	for s in SPECIES:
		out.append(s["id"])
	return out


## Index of a species id, or -1.
static func index_of(species_id: String) -> int:
	for i in COUNT:
		if SPECIES[i]["id"] == species_id:
			return i
	return -1
