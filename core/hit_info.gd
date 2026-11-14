class_name HitInfo
extends RefCounted

const FIELDS: Array[String] = [
	"damage", "chip_damage", "hitstun", "blockstun", "hitstop", "hit_height", "knockback",
	"block_pushback", "launch", "knockdown", "unblockable", "scales_combo", "meter_gain", "effect",
]
const HEAVY_DAMAGE := 80

var source_id: String = ""
var damage: int = 0
var chip_damage: int = 0
var hitstun: int = 14
var blockstun: int = 9
var hitstop: int = 6
var hit_height: MoveData.Height = MoveData.Height.MID
var knockback: Vector2 = Vector2(6, 0)
var block_pushback: float = 5.0
var launch: bool = false
var knockdown: bool = false
var unblockable: bool = false
var scales_combo: bool = true
var meter_gain: int = 0
var effect: String = ""
var ignores_armor: bool = false
var from_projectile: bool = false


static func from_move(move: MoveData, overrides: Dictionary = {}) -> HitInfo:
	var hit := HitInfo.new()
	hit.source_id = move.id
	for field in FIELDS:
		hit.set(field, move.get(field))
	hit.apply(overrides)
	return hit


static func from_fields(source: String, fields: Dictionary) -> HitInfo:
	var hit := HitInfo.new()
	hit.source_id = source
	hit.apply(fields)
	return hit


func apply(fields: Dictionary) -> void:
	for field in fields:
		set(field, fields[field])


func copy() -> HitInfo:
	var hit := HitInfo.new()
	hit.source_id = source_id
	for field in FIELDS:
		hit.set(field, get(field))
	hit.ignores_armor = ignores_armor
	hit.from_projectile = from_projectile
	return hit


func is_heavy() -> bool:
	return damage >= HEAVY_DAMAGE
