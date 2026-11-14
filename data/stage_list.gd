class_name StageList
extends RefCounted

const ENTRIES: Array[Dictionary] = [
	{
		"id": "neon_city", "name": "Cidade Neon",
		"description": "Arranha-céus em silhueta, letreiros piscando e chuva fina.",
		"sky_top": Color(0.02, 0.02, 0.08), "sky_bottom": Color(0.14, 0.04, 0.22), "line": Color(1.0, 0.3, 0.8),
	},
	{
		"id": "pantheon_ruins", "name": "Ruínas do Panteão",
		"description": "Colunas quebradas sob um crepúsculo cheio de brasas.",
		"sky_top": Color(0.08, 0.03, 0.08), "sky_bottom": Color(0.5, 0.18, 0.08), "line": Color(1.0, 0.62, 0.25),
	},
	{
		"id": "stellar_void", "name": "Vazio Estelar",
		"description": "Uma plataforma à deriva entre nebulosas e um anel orbital.",
		"sky_top": Color(0.0, 0.0, 0.03), "sky_bottom": Color(0.06, 0.08, 0.22), "line": Color(0.5, 0.8, 1.0),
	},
]


static func count() -> int:
	return ENTRIES.size()


static func entry(index: int) -> Dictionary:
	return ENTRIES[clampi(index, 0, ENTRIES.size() - 1)]
