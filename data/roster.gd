class_name Roster
extends RefCounted

const PROVISIONAL_INDEX := -1

const ENTRIES: Array[Dictionary] = [
	{"id": "ivad", "name": "Ivad", "title": "Herói cósmico", "ready": true, "power": Color(0.72, 0.5, 1.0)},
	{"id": "haluho", "name": "Haluho", "title": "Demônio do pacto", "ready": true, "power": Color(1.0, 0.35, 0.12)},
	{"id": "god_slayer", "name": "God Slayer", "title": "Caçador de deuses", "ready": false, "power": Color(1.0, 0.62, 0.18)},
	{"id": "oaoj", "name": "Oãoj", "title": "Deus da destruição", "ready": false, "power": Color(0.3, 1.0, 0.65)},
	{"id": "keitchoueitchou", "name": "Keitchoueitchou", "title": "Alienígena de luz", "ready": false, "power": Color(0.75, 1.0, 0.35)},
	{"id": "xing_zhang", "name": "Xing Zhang", "title": "Mestre das projeções", "ready": false, "power": Color(0.7, 0.88, 1.0)},
]


static func count() -> int:
	return ENTRIES.size()


static func display_name(index: int) -> String:
	if index == PROVISIONAL_INDEX:
		return "Provisório"
	return ENTRIES[index]["name"]


static func title(index: int) -> String:
	return ENTRIES[index]["title"]


static func power_color(index: int) -> Color:
	return ENTRIES[index]["power"]


static func is_ready(index: int) -> bool:
	return ENTRIES[index]["ready"]


static func build(index: int, slot: int) -> CharacterData:
	if index == PROVISIONAL_INDEX:
		return GenericData.build(slot)
	match ENTRIES[clampi(index, 0, ENTRIES.size() - 1)]["id"]:
		"ivad":
			return IvadData.build()
		"haluho":
			return HaluhoData.build()
	return GenericData.build(slot)


static func preview(index: int) -> CharacterData:
	if is_ready(index):
		return build(index, 0)
	var stand_in := GenericData.build(0)
	stand_in.display_name = display_name(index)
	return stand_in
