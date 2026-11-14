class_name EntityData
extends Resource

var id: String = ""
var visual: String = ""
var lifetime: int = 120
var velocity: Vector2 = Vector2.ZERO
var hitboxes: Array[Rect2] = []
var hit_fields: Dictionary = {}
var hits: int = 1
var hit_interval: int = 10
var expire_on_last_hit: bool = true
var clash: bool = true
var durability: int = 1
var cuttable: bool = true
var destructible: bool = false
var hurtbox: Rect2 = Rect2()
var health: int = 0
var stage_bound: bool = true
var behavior: Script = null
var params: Dictionary = {}


func has_hit() -> bool:
	return not hit_fields.is_empty() and not hitboxes.is_empty()
