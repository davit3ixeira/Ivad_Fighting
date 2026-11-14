class_name IvadData
extends RefCounted

const LP := ButtonMap.Action.LIGHT_PUNCH
const HP := ButtonMap.Action.HEAVY_PUNCH
const LK := ButtonMap.Action.LIGHT_KICK
const HK := ButtonMap.Action.HEAVY_KICK
const R1 := ButtonMap.Action.SPECIAL
const STAND := MoveData.Stance.STAND
const CROUCH := MoveData.Stance.CROUCH
const AIR := MoveData.Stance.AIR
const HIGH := MoveData.Height.HIGH
const MID := MoveData.Height.MID
const LOW := MoveData.Height.LOW
const SPECIAL := MoveData.Kind.SPECIAL
const SUPER := MoveData.Kind.SUPER
const UNIQUE := MoveData.Kind.UNIQUE
const QCF := CommandParser.Motion.QCF
const QCB := CommandParser.Motion.QCB
const DOUBLE_QCF := CommandParser.Motion.DOUBLE_QCF

const MODULE_PARAMS := {
	"teleport_behind_distance": 96.0,
	"teleport_retreat_distance": 300.0,
	"singularity_min_distance": 150.0,
	"singularity_max_distance": 460.0,
	"singularity_height": -100.0,
	"well_spawn_offset": Vector2(72, -104),
}

const WELL_PARAMS := {
	"pull_radius": 340.0,
	"pull_strength": 2.4,
	"projectile_bend": 0.3,
}

const SINGULARITY_PARAMS := {
	"pull_radius": 620.0,
	"pull_strength": 5.0,
	"hold_strength": 10.0,
	"nova_frame": 58,
	"nova_hitbox": Rect2(-150, -160, 300, 320),
	"nova_hit": {
		"damage": 220, "chip_damage": 30, "hitstun": 30, "blockstun": 20, "hitstop": 16,
		"knockback": Vector2(16, -14), "block_pushback": 14.0, "launch": true, "scales_combo": false,
	},
}


static func build() -> CharacterData:
	var c := CharacterData.new()
	c.id = "ivad"
	c.display_name = "Ivad"
	c.health = 1000
	c.walk_speed = 5.3
	c.back_speed = 4.4
	c.jump_velocity = -17.5
	c.jump_forward_speed = 6.5
	c.jump_back_speed = 5.5
	c.gravity = 0.86
	c.dash_speed = 14.5
	c.dash_frames = 10
	c.backdash_speed = 11.5
	c.backdash_frames = 14
	c.backdash_invuln_frames = 7
	c.stand_hurtbox = Rect2(-28, -180, 56, 180)
	c.crouch_hurtbox = Rect2(-34, -134, 68, 134)
	c.air_hurtbox = Rect2(-26, -158, 52, 134)
	c.stand_pushbox = Rect2(-34, -156, 68, 156)
	c.crouch_pushbox = Rect2(-34, -108, 68, 108)
	c.air_pushbox = Rect2(-22, -146, 44, 92)
	c.accent_color = Color(1.0, 0.85, 0.35)
	c.power_color = Color(0.72, 0.5, 1.0)
	c.intro_line = "Vamos logo com isso. O universo não se equilibra sozinho."
	c.win_line = "Nada pessoal. É só gravidade."
	c.params = MODULE_PARAMS
	c.rig = IvadAnims.rig()
	c.animations = IvadAnims.build()
	c.module_scripts.append(IvadModule)
	c.entities = _entities()
	for move in _normals():
		c.moves.append(move)
	for move in _specials():
		c.moves.append(move)
	return c


static func _normals() -> Array[MoveData]:
	var list: Array[MoveData] = []
	list.append(DataKit.move({
		"id": "lp", "display_name": "Peteleco", "button": LP, "stance": STAND,
		"startup": 3, "active": 3, "recovery": 6, "damage": 30, "hitstun": 13, "blockstun": 9, "hitstop": 5,
		"hit_height": MID, "knockback": Vector2(5, 0), "block_pushback": 4.5, "meter_gain": 22,
		"hitboxes": [Rect2(20, -158, 68, 28)], "hurtbox_extra": [Rect2(26, -158, 46, 28)],
		"cancel_into": ["lp", "hp", "lk", "hk", "clp", "chp"], "special_cancel": true,
	}))
	list.append(DataKit.move({
		"id": "hp", "display_name": "Palma Cósmica", "button": HP, "stance": STAND,
		"startup": 9, "active": 4, "recovery": 15, "damage": 95, "hitstun": 22, "blockstun": 14, "hitstop": 10,
		"hit_height": MID, "knockback": Vector2(11, 0), "block_pushback": 8.0, "meter_gain": 48,
		"hitboxes": [Rect2(28, -166, 92, 42)], "hurtbox_extra": [Rect2(28, -166, 68, 42)],
		"advance": 3.0, "advance_frames": 9, "special_cancel": true,
	}))
	list.append(DataKit.move({
		"id": "lk", "display_name": "Chute Desleixado", "button": LK, "stance": STAND,
		"startup": 5, "active": 3, "recovery": 9, "damage": 45, "hitstun": 15, "blockstun": 10, "hitstop": 6,
		"hit_height": MID, "knockback": Vector2(7, 0), "block_pushback": 5.5, "meter_gain": 28,
		"hitboxes": [Rect2(28, -118, 90, 32)], "hurtbox_extra": [Rect2(28, -118, 62, 32)],
		"cancel_into": ["hk", "chk"], "special_cancel": true,
	}))
	list.append(DataKit.move({
		"id": "hk", "display_name": "Órbita", "button": HK, "stance": STAND,
		"startup": 11, "active": 5, "recovery": 17, "damage": 115, "hitstun": 24, "blockstun": 16, "hitstop": 11,
		"hit_height": MID, "knockback": Vector2(14, 0), "block_pushback": 9.5, "meter_gain": 55,
		"hitboxes": [Rect2(24, -176, 104, 52)], "hurtbox_extra": [Rect2(24, -176, 72, 52)],
	}))
	list.append(DataKit.move({
		"id": "clp", "display_name": "Cutucão", "button": LP, "stance": CROUCH,
		"startup": 4, "active": 3, "recovery": 7, "damage": 30, "hitstun": 13, "blockstun": 9, "hitstop": 5,
		"hit_height": MID, "knockback": Vector2(5, 0), "block_pushback": 4.5, "meter_gain": 22,
		"hitboxes": [Rect2(20, -108, 72, 28)], "hurtbox_extra": [Rect2(26, -108, 48, 28)],
		"cancel_into": ["clp", "chp", "clk", "chk", "lp", "hp"], "special_cancel": true,
	}))
	list.append(DataKit.move({
		"id": "chp", "display_name": "Ascensão", "button": HP, "stance": CROUCH,
		"startup": 7, "active": 5, "recovery": 19, "damage": 85, "hitstun": 20, "blockstun": 12, "hitstop": 9,
		"hit_height": MID, "knockback": Vector2(4, -15.5), "block_pushback": 6.0, "meter_gain": 44,
		"launch": true, "special_cancel": true,
		"hitboxes": [Rect2(8, -206, 58, 98)], "hurtbox_extra": [Rect2(8, -206, 40, 86)],
	}))
	list.append(DataKit.move({
		"id": "clk", "display_name": "Rasteirinha", "button": LK, "stance": CROUCH,
		"startup": 5, "active": 3, "recovery": 9, "damage": 40, "hitstun": 14, "blockstun": 10, "hitstop": 6,
		"hit_height": LOW, "knockback": Vector2(6, 0), "block_pushback": 5.0, "meter_gain": 28,
		"hitboxes": [Rect2(30, -48, 90, 32)], "hurtbox_extra": [Rect2(30, -48, 62, 32)],
		"cancel_into": ["chk", "clp", "chp"], "special_cancel": true,
	}))
	list.append(DataKit.move({
		"id": "chk", "display_name": "Varredura Orbital", "button": HK, "stance": CROUCH,
		"startup": 9, "active": 4, "recovery": 20, "damage": 100, "hitstun": 20, "blockstun": 14, "hitstop": 10,
		"hit_height": LOW, "knockback": Vector2(9, 0), "block_pushback": 8.0, "meter_gain": 50,
		"knockdown": true,
		"hitboxes": [Rect2(20, -42, 106, 36)], "hurtbox_extra": [Rect2(20, -42, 74, 36)],
	}))
	list.append(DataKit.move({
		"id": "jlp", "display_name": "Tapa Aéreo", "button": LP, "stance": AIR,
		"startup": 4, "active": 8, "recovery": 0, "damage": 40, "hitstun": 15, "blockstun": 10, "hitstop": 6,
		"hit_height": HIGH, "knockback": Vector2(5, 0), "block_pushback": 4.0, "meter_gain": 22,
		"hitboxes": [Rect2(14, -150, 66, 30)], "hurtbox_extra": [Rect2(14, -150, 44, 30)],
	}))
	list.append(DataKit.move({
		"id": "jhp", "display_name": "Meteoro", "button": HP, "stance": AIR,
		"startup": 7, "active": 7, "recovery": 0, "damage": 95, "hitstun": 22, "blockstun": 14, "hitstop": 9,
		"hit_height": HIGH, "knockback": Vector2(8, 0), "block_pushback": 6.0, "meter_gain": 45,
		"hitboxes": [Rect2(6, -130, 76, 58)], "hurtbox_extra": [Rect2(6, -130, 50, 58)],
	}))
	list.append(DataKit.move({
		"id": "jlk", "display_name": "Joelhada", "button": LK, "stance": AIR,
		"startup": 5, "active": 8, "recovery": 0, "damage": 50, "hitstun": 16, "blockstun": 10, "hitstop": 6,
		"hit_height": HIGH, "knockback": Vector2(6, 0), "block_pushback": 4.5, "meter_gain": 28,
		"hitboxes": [Rect2(10, -112, 64, 44)], "hurtbox_extra": [Rect2(10, -112, 44, 44)],
	}))
	list.append(DataKit.move({
		"id": "jhk", "display_name": "Cometa", "button": HK, "stance": AIR,
		"startup": 8, "active": 7, "recovery": 0, "damage": 100, "hitstun": 24, "blockstun": 15, "hitstop": 10,
		"hit_height": HIGH, "knockback": Vector2(9, 0), "block_pushback": 7.0, "meter_gain": 50,
		"hitboxes": [Rect2(14, -96, 100, 54)], "hurtbox_extra": [Rect2(14, -96, 66, 54)],
	}))
	return list


static func _specials() -> Array[MoveData]:
	var list: Array[MoveData] = []
	var soco := {
		"display_name": "Soco de Ivad", "kind": SPECIAL, "motion": QCF, "stance": STAND,
		"hit_height": MID, "launch": true, "effect": "cosmic_ring", "super_cancel": true,
		"charge_max_frames": 40, "charge_damage_bonus": 80, "charge_knockback_bonus": Vector2(5, -3),
		"charge_full_unblockable": true, "meter_gain": 70,
	}
	list.append(DataKit.variant(soco, {
		"id": "soco_ivad_l", "button": LP,
		"startup": 12, "active": 4, "recovery": 22, "damage": 110, "chip_damage": 12,
		"hitstun": 26, "blockstun": 18, "hitstop": 13, "knockback": Vector2(15, -8), "block_pushback": 11.0,
		"charge_frame": 9, "advance": 5.0, "advance_start": 9, "advance_frames": 5,
		"hitboxes": [Rect2(28, -168, 100, 48)], "hurtbox_extra": [Rect2(28, -168, 70, 48)],
	}))
	list.append(DataKit.variant(soco, {
		"id": "soco_ivad_h", "button": HP,
		"startup": 17, "active": 4, "recovery": 25, "damage": 135, "chip_damage": 15,
		"hitstun": 28, "blockstun": 19, "hitstop": 14, "knockback": Vector2(18, -9), "block_pushback": 12.0,
		"charge_frame": 12, "advance": 8.0, "advance_start": 12, "advance_frames": 7,
		"hitboxes": [Rect2(28, -170, 108, 52)], "hurtbox_extra": [Rect2(28, -170, 76, 52)],
	}))
	var poco := {
		"display_name": "Poço Gravitacional", "kind": SPECIAL, "motion": QCB, "stance": STAND,
		"startup": 14, "active": 1, "damage": 0, "meter_gain": 0, "animation": "poco",
	}
	list.append(DataKit.variant(poco, {
		"id": "poco_l", "button": LP, "recovery": 25,
		"events": [{"frame": 14, "type": "module", "name": "cast_well", "entity": "gravity_well_slow"}],
	}))
	list.append(DataKit.variant(poco, {
		"id": "poco_h", "button": HP, "recovery": 29,
		"events": [{"frame": 14, "type": "module", "name": "cast_well", "entity": "gravity_well_fast"}],
	}))
	var passo := {
		"display_name": "Passo Estelar", "kind": SPECIAL, "motion": QCB, "stance": STAND,
		"startup": 8, "active": 10, "recovery": 22, "damage": 0, "meter_gain": 0,
		"invuln_start": 6, "invuln_end": 18, "animation": "passo",
	}
	list.append(DataKit.variant(passo, {
		"id": "passo_l", "button": LK,
		"events": [
			{"frame": 8, "type": "module", "name": "teleport_out"},
			{"frame": 18, "type": "module", "name": "teleport_in", "target": "behind"},
		],
	}))
	list.append(DataKit.variant(passo, {
		"id": "passo_h", "button": HK,
		"events": [
			{"frame": 8, "type": "module", "name": "teleport_out"},
			{"frame": 18, "type": "module", "name": "teleport_in", "target": "mark"},
		],
	}))
	list.append(DataKit.move({
		"id": "marca", "display_name": "Marca Cósmica", "kind": UNIQUE, "button": R1, "stance": STAND,
		"startup": 10, "active": 1, "recovery": 11, "damage": 0, "meter_gain": 0,
		"events": [{"frame": 10, "type": "module", "name": "plant_mark"}],
	}))
	list.append(DataKit.move({
		"id": "super", "display_name": "Singularidade", "kind": SUPER, "button": HP, "motion": DOUBLE_QCF,
		"stance": STAND, "meter_cost": GlobalTuning.METER_MAX, "super_freeze": 36, "super_freeze_frame": 9,
		"startup": 14, "active": 60, "recovery": 28, "damage": 0, "meter_gain": 0,
		"events": [{"frame": 14, "type": "module", "name": "open_singularity"}],
	}))
	return list


static func _entities() -> Dictionary:
	var well := {
		"visual": "gravity_well", "hitboxes": [Rect2(-24, -24, 48, 48)],
		"hits": 3, "hit_interval": 9, "durability": 2, "behavior": GravityWellBehavior, "params": WELL_PARAMS,
		"hit_fields": {
			"damage": 28, "chip_damage": 3, "hitstun": 18, "blockstun": 12, "hitstop": 5,
			"knockback": Vector2(2, 0), "block_pushback": 2.0, "meter_gain": 15,
		},
	}
	return {
		"gravity_well_slow": DataKit.entity(DataKit.merged(well, {"id": "gravity_well_slow", "velocity": Vector2(2.6, 0), "lifetime": 170})),
		"gravity_well_fast": DataKit.entity(DataKit.merged(well, {"id": "gravity_well_fast", "velocity": Vector2(4.8, 0), "lifetime": 130})),
		"cosmic_mark": DataKit.entity({
			"id": "cosmic_mark", "visual": "cosmic_mark", "lifetime": 900, "clash": false, "cuttable": false,
		}),
		"singularity": DataKit.entity({
			"id": "singularity", "visual": "singularity", "lifetime": 66, "clash": false, "cuttable": false,
			"stage_bound": false, "hitboxes": [Rect2(-46, -60, 92, 120)],
			"hits": 5, "hit_interval": 7, "expire_on_last_hit": false,
			"behavior": SingularityBehavior, "params": SINGULARITY_PARAMS,
			"hit_fields": {
				"damage": 24, "chip_damage": 4, "hitstun": 18, "blockstun": 14, "hitstop": 4,
				"knockback": Vector2(0, 0), "block_pushback": 0.0, "scales_combo": false,
			},
		}),
	}
