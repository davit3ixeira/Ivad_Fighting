class_name Roster
extends RefCounted

const ENTRIES: Array[Dictionary] = [
	{"id": "ivad", "name": "Ivad"},
	{"id": "sombra", "name": "Sombra"},
	{"id": "eco", "name": "Eco"},
]


static func count() -> int:
	return ENTRIES.size()


static func display_name(index: int) -> String:
	return ENTRIES[index]["name"]


static func build(index: int) -> CharacterData:
	match ENTRIES[index]["id"]:
		"ivad":
			return IvadData.build()
		"sombra":
			return GenericData.build(0)
		_:
			return GenericData.build(1)
