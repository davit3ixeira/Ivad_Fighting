class_name Entity
extends RefCounted

var data: EntityData
var owner: Fighter
var position: Vector2 = Vector2.ZERO
var velocity: Vector2 = Vector2.ZERO
var facing: int = 1
var frame: int = 0
var alive: bool = true
var hits_left: int = 0
var rehit_timer: int = 0
var hitstop: int = 0
var durability: int = 1
var health: int = 0
var hit: HitInfo
var hitboxes: Array[Rect2] = []
var behavior: EntityBehavior
var vars: Dictionary = {}


func setup(entity_data: EntityData, entity_owner: Fighter, spawn_position: Vector2, spawn_facing: int) -> void:
	data = entity_data
	owner = entity_owner
	position = spawn_position
	facing = spawn_facing
	velocity = Vector2(entity_data.velocity.x * spawn_facing, entity_data.velocity.y)
	hits_left = entity_data.hits
	durability = entity_data.durability
	health = entity_data.health
	hitboxes.assign(entity_data.hitboxes)
	if entity_data.has_hit():
		hit = HitInfo.from_fields(entity_data.id, entity_data.hit_fields)
		hit.from_projectile = true
	if entity_data.behavior != null:
		behavior = entity_data.behavior.new()
	else:
		behavior = EntityBehavior.new()


func can_hit() -> bool:
	return alive and hit != null and hits_left > 0 and rehit_timer <= 0 and not hitboxes.is_empty()


func hitboxes_world() -> Array[Rect2]:
	var boxes: Array[Rect2] = []
	for rect in hitboxes:
		boxes.append(to_world(rect))
	return boxes


func hurtbox_world() -> Rect2:
	return to_world(data.hurtbox)


func to_world(rect: Rect2) -> Rect2:
	if facing > 0:
		return Rect2(position + rect.position, rect.size)
	return Rect2(position.x - rect.position.x - rect.size.x, position.y + rect.position.y, rect.size.x, rect.size.y)
