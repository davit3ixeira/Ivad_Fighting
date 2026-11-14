class_name DataKit
extends RefCounted

const TYPED_ARRAY_FIELDS: Array[String] = ["hitboxes", "hurtbox_extra", "cancel_into", "events", "windows"]


static func move(fields: Dictionary) -> MoveData:
	var result := MoveData.new()
	for field in fields:
		var value = fields[field]
		if TYPED_ARRAY_FIELDS.has(field):
			result.get(field).assign(value)
		else:
			result.set(field, value)
	return result


static func variant(base: Dictionary, overrides: Dictionary) -> MoveData:
	var fields := base.duplicate(true)
	fields.merge(overrides, true)
	return move(fields)


static func entity(fields: Dictionary) -> EntityData:
	var result := EntityData.new()
	for field in fields:
		var value = fields[field]
		if field == "hitboxes":
			result.hitboxes.assign(value)
		else:
			result.set(field, value)
	return result


static func merged(base: Dictionary, overrides: Dictionary) -> Dictionary:
	var result := base.duplicate()
	result.merge(overrides, true)
	return result


static func key(t: int, pose: Dictionary) -> Dictionary:
	return {"t": t, "pose": pose}


static func anim(keys: Array, loop: bool = false) -> Dictionary:
	return {"loop": loop, "keys": keys}
