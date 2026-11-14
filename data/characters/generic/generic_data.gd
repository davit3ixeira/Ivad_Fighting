class_name GenericData
extends RefCounted

const LP := ButtonMap.Action.LIGHT_PUNCH
const HP := ButtonMap.Action.HEAVY_PUNCH
const LK := ButtonMap.Action.LIGHT_KICK
const HK := ButtonMap.Action.HEAVY_KICK
const STAND := MoveData.Stance.STAND
const CROUCH := MoveData.Stance.CROUCH
const AIR := MoveData.Stance.AIR
const HIGH := MoveData.Height.HIGH
const MID := MoveData.Height.MID
const LOW := MoveData.Height.LOW


static func build(variant: int = 0) -> CharacterData:
	var c := CharacterData.new()
	c.id = "generic"
	c.display_name = "Sombra" if variant == 0 else "Eco"
	c.health = 1000
	c.walk_speed = 5.5
	c.back_speed = 4.5
	c.jump_velocity = -17.0
	c.jump_forward_speed = 6.5
	c.jump_back_speed = 5.5
	c.gravity = 0.85
	c.dash_speed = 14.0
	c.dash_frames = 10
	c.backdash_speed = 11.0
	c.backdash_frames = 14
	c.backdash_invuln_frames = 7
	c.stand_hurtbox = Rect2(-28, -170, 56, 170)
	c.crouch_hurtbox = Rect2(-34, -130, 68, 130)
	c.air_hurtbox = Rect2(-26, -150, 52, 130)
	c.stand_pushbox = Rect2(-34, -150, 68, 150)
	c.crouch_pushbox = Rect2(-34, -105, 68, 105)
	c.air_pushbox = Rect2(-22, -140, 44, 90)
	c.accent_color = Color(0.7, 0.9, 1.0) if variant == 0 else Color(1.0, 0.8, 0.5)
	c.rig = GenericAnims.rig()
	c.animations = GenericAnims.build()
	for move in _moves():
		c.moves.append(move)
	return c


static func _moves() -> Array[MoveData]:
	var list: Array[MoveData] = []
	list.append(_move({
		"id": "lp", "display_name": "Jab", "button": LP, "stance": STAND,
		"startup": 4, "active": 3, "recovery": 7, "damage": 40, "hitstun": 14, "blockstun": 9, "hitstop": 6,
		"hit_height": MID, "knockback": Vector2(6, 0), "block_pushback": 5.0, "meter_gain": 25,
		"hitboxes": [Rect2(20, -152, 72, 30)], "hurtbox_extra": [Rect2(28, -152, 50, 30)],
		"cancel_into": ["lp", "hp", "lk", "hk", "clp", "chp"],
	}))
	list.append(_move({
		"id": "hp", "display_name": "Direto", "button": HP, "stance": STAND,
		"startup": 8, "active": 4, "recovery": 16, "damage": 100, "hitstun": 22, "blockstun": 14, "hitstop": 10,
		"hit_height": MID, "knockback": Vector2(11, 0), "block_pushback": 8.0, "meter_gain": 50,
		"hitboxes": [Rect2(30, -162, 92, 38)], "hurtbox_extra": [Rect2(28, -162, 70, 38)],
		"advance": 3.0, "advance_frames": 8,
	}))
	list.append(_move({
		"id": "lk", "display_name": "Chute Curto", "button": LK, "stance": STAND,
		"startup": 5, "active": 3, "recovery": 9, "damage": 50, "hitstun": 15, "blockstun": 10, "hitstop": 6,
		"hit_height": MID, "knockback": Vector2(7, 0), "block_pushback": 5.5, "meter_gain": 30,
		"hitboxes": [Rect2(30, -112, 84, 32)], "hurtbox_extra": [Rect2(30, -112, 60, 32)],
		"cancel_into": ["hk", "chk"],
	}))
	list.append(_move({
		"id": "hk", "display_name": "Chute Giratório", "button": HK, "stance": STAND,
		"startup": 9, "active": 5, "recovery": 18, "damage": 110, "hitstun": 24, "blockstun": 15, "hitstop": 10,
		"hit_height": MID, "knockback": Vector2(13, 0), "block_pushback": 9.0, "meter_gain": 55,
		"hitboxes": [Rect2(26, -164, 90, 48)], "hurtbox_extra": [Rect2(26, -164, 64, 48)],
	}))
	list.append(_move({
		"id": "clp", "display_name": "Jab Baixo", "button": LP, "stance": CROUCH,
		"startup": 4, "active": 3, "recovery": 7, "damage": 35, "hitstun": 13, "blockstun": 9, "hitstop": 6,
		"hit_height": MID, "knockback": Vector2(5, 0), "block_pushback": 4.5, "meter_gain": 25,
		"hitboxes": [Rect2(20, -104, 70, 28)], "hurtbox_extra": [Rect2(26, -104, 48, 28)],
		"cancel_into": ["clp", "chp", "clk", "chk", "lp", "hp"],
	}))
	list.append(_move({
		"id": "chp", "display_name": "Gancho", "button": HP, "stance": CROUCH,
		"startup": 7, "active": 5, "recovery": 18, "damage": 90, "hitstun": 20, "blockstun": 12, "hitstop": 9,
		"hit_height": MID, "knockback": Vector2(5, -15), "block_pushback": 6.0, "meter_gain": 45,
		"launch": true,
		"hitboxes": [Rect2(8, -196, 56, 90)], "hurtbox_extra": [Rect2(8, -196, 40, 80)],
	}))
	list.append(_move({
		"id": "clk", "display_name": "Chute Rasteiro", "button": LK, "stance": CROUCH,
		"startup": 5, "active": 3, "recovery": 9, "damage": 40, "hitstun": 14, "blockstun": 10, "hitstop": 6,
		"hit_height": LOW, "knockback": Vector2(6, 0), "block_pushback": 5.0, "meter_gain": 30,
		"hitboxes": [Rect2(30, -46, 86, 30)], "hurtbox_extra": [Rect2(30, -46, 60, 30)],
		"cancel_into": ["chk", "clp", "chp"],
	}))
	list.append(_move({
		"id": "chk", "display_name": "Rasteira", "button": HK, "stance": CROUCH,
		"startup": 8, "active": 4, "recovery": 20, "damage": 100, "hitstun": 20, "blockstun": 14, "hitstop": 10,
		"hit_height": LOW, "knockback": Vector2(9, 0), "block_pushback": 8.0, "meter_gain": 50,
		"knockdown": true,
		"hitboxes": [Rect2(20, -40, 100, 34)], "hurtbox_extra": [Rect2(20, -40, 70, 34)],
	}))
	list.append(_move({
		"id": "jlp", "display_name": "Jab Aéreo", "button": LP, "stance": AIR,
		"startup": 4, "active": 8, "recovery": 0, "damage": 45, "hitstun": 15, "blockstun": 10, "hitstop": 6,
		"hit_height": HIGH, "knockback": Vector2(5, 0), "block_pushback": 4.0, "meter_gain": 25,
		"hitboxes": [Rect2(14, -142, 64, 30)], "hurtbox_extra": [Rect2(14, -142, 44, 30)],
	}))
	list.append(_move({
		"id": "jhp", "display_name": "Martelo Aéreo", "button": HP, "stance": AIR,
		"startup": 7, "active": 7, "recovery": 0, "damage": 95, "hitstun": 22, "blockstun": 14, "hitstop": 9,
		"hit_height": HIGH, "knockback": Vector2(8, 0), "block_pushback": 6.0, "meter_gain": 45,
		"hitboxes": [Rect2(6, -124, 74, 54)], "hurtbox_extra": [Rect2(6, -124, 50, 54)],
	}))
	list.append(_move({
		"id": "jlk", "display_name": "Chute Aéreo", "button": LK, "stance": AIR,
		"startup": 5, "active": 8, "recovery": 0, "damage": 50, "hitstun": 16, "blockstun": 10, "hitstop": 6,
		"hit_height": HIGH, "knockback": Vector2(6, 0), "block_pushback": 4.5, "meter_gain": 30,
		"hitboxes": [Rect2(20, -104, 78, 32)], "hurtbox_extra": [Rect2(20, -104, 54, 32)],
	}))
	list.append(_move({
		"id": "jhk", "display_name": "Voadora", "button": HK, "stance": AIR,
		"startup": 8, "active": 7, "recovery": 0, "damage": 100, "hitstun": 24, "blockstun": 15, "hitstop": 10,
		"hit_height": HIGH, "knockback": Vector2(9, 0), "block_pushback": 7.0, "meter_gain": 50,
		"hitboxes": [Rect2(14, -92, 96, 52)], "hurtbox_extra": [Rect2(14, -92, 64, 52)],
	}))
	return list


static func _move(fields: Dictionary) -> MoveData:
	var move := MoveData.new()
	for key in fields:
		var value = fields[key]
		match key:
			"hitboxes":
				move.hitboxes.assign(value)
			"hurtbox_extra":
				move.hurtbox_extra.assign(value)
			"cancel_into":
				move.cancel_into.assign(value)
			_:
				move.set(key, value)
	return move
