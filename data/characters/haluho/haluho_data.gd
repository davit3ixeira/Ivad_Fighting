class_name HaluhoData
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
const HCB := CommandParser.Motion.HCB
const DOUBLE_QCF := CommandParser.Motion.DOUBLE_QCF

const MODULE_PARAMS := {
	"pact_cost": 90,
	"pact_frames": 330,
	"pact_damage_bonus": 0.3,
	"pact_chip_bonus": 6,
	"pact_extra_armor": 1,
	"rage_max_bonus": 0.2,
	"true_form_scale": 1.24,
	"true_form_moves": ["super", "super_seq"],
	"aura_color": Color(1.0, 0.34, 0.08),
}

const HELLFIRE_HIT := {"damage": 34, "hitstun": 20, "hitstop": 8, "meter_gain": 20, "effect": "hellfire"}


static func build() -> CharacterData:
	var c := CharacterData.new()
	c.id = "haluho"
	c.display_name = "Haluho"
	c.health = 1050
	c.walk_speed = 4.4
	c.back_speed = 3.8
	c.jump_velocity = -16.5
	c.jump_forward_speed = 6.0
	c.jump_back_speed = 5.0
	c.gravity = 0.9
	c.dash_speed = 13.0
	c.dash_frames = 12
	c.backdash_speed = 10.0
	c.backdash_frames = 16
	c.backdash_invuln_frames = 6
	c.stand_hurtbox = Rect2(-38, -216, 76, 216)
	c.crouch_hurtbox = Rect2(-42, -150, 84, 150)
	c.air_hurtbox = Rect2(-34, -190, 68, 164)
	c.stand_pushbox = Rect2(-42, -170, 84, 170)
	c.crouch_pushbox = Rect2(-42, -120, 84, 120)
	c.air_pushbox = Rect2(-28, -170, 56, 110)
	c.accent_color = Color(1.0, 0.5, 0.15)
	c.power_color = Color(1.0, 0.36, 0.1)
	c.intro_line = "Mais um verme querendo provar o meu fogo."
	c.win_line = "Eu paguei com sangue. Você pagou com tudo."
	c.intro_lines_vs = {
		"ivad": "O loirinho cósmico. Vou arrancar essas estrelas de você.",
		"haluho": "Só existe espaço para um demônio aqui.",
	}
	c.win_lines_vs = {
		"ivad": "Gravidade nenhuma segura o inferno.",
	}
	c.params = MODULE_PARAMS
	c.rig = HaluhoAnims.rig()
	c.animations = HaluhoAnims.build()
	c.module_scripts.append(HaluhoModule)
	for move in _normals():
		c.moves.append(move)
	for move in _specials():
		c.moves.append(move)
	return c


static func _normals() -> Array[MoveData]:
	var list: Array[MoveData] = []
	list.append(DataKit.move({
		"id": "lp", "display_name": "Tapa Demoníaco", "button": LP, "stance": STAND,
		"startup": 5, "active": 3, "recovery": 8, "damage": 45, "hitstun": 14, "blockstun": 10, "hitstop": 7,
		"hit_height": MID, "knockback": Vector2(6, 0), "block_pushback": 5.0, "meter_gain": 24,
		"hitboxes": [Rect2(24, -186, 84, 36)], "hurtbox_extra": [Rect2(28, -186, 60, 36)],
		"cancel_into": ["lp", "hp", "clp"], "special_cancel": true,
	}))
	list.append(DataKit.move({
		"id": "hp", "display_name": "Punho do Abismo", "button": HP, "stance": STAND,
		"startup": 10, "active": 4, "recovery": 18, "damage": 120, "hitstun": 23, "blockstun": 15, "hitstop": 12,
		"hit_height": MID, "knockback": Vector2(13, 0), "block_pushback": 9.0, "meter_gain": 55,
		"hitboxes": [Rect2(30, -196, 104, 46)], "hurtbox_extra": [Rect2(30, -196, 76, 46)],
		"advance": 3.5, "advance_frames": 10, "special_cancel": true,
	}))
	list.append(DataKit.move({
		"id": "lk", "display_name": "Pisão", "button": LK, "stance": STAND,
		"startup": 6, "active": 3, "recovery": 10, "damage": 55, "hitstun": 15, "blockstun": 10, "hitstop": 7,
		"hit_height": MID, "knockback": Vector2(8, 0), "block_pushback": 6.0, "meter_gain": 28,
		"hitboxes": [Rect2(30, -118, 96, 40)], "hurtbox_extra": [Rect2(30, -118, 70, 40)],
		"cancel_into": ["hk"], "special_cancel": true,
	}))
	list.append(DataKit.move({
		"id": "hk", "display_name": "Coice Infernal", "button": HK, "stance": STAND,
		"startup": 12, "active": 5, "recovery": 20, "damage": 130, "hitstun": 25, "blockstun": 17, "hitstop": 12,
		"hit_height": MID, "knockback": Vector2(15, 0), "block_pushback": 10.0, "meter_gain": 60,
		"hitboxes": [Rect2(26, -206, 118, 60)], "hurtbox_extra": [Rect2(26, -206, 84, 60)],
	}))
	list.append(DataKit.move({
		"id": "clp", "display_name": "Cotovelada Baixa", "button": LP, "stance": CROUCH,
		"startup": 5, "active": 3, "recovery": 8, "damage": 40, "hitstun": 14, "blockstun": 10, "hitstop": 7,
		"hit_height": MID, "knockback": Vector2(5, 0), "block_pushback": 4.5, "meter_gain": 24,
		"hitboxes": [Rect2(22, -128, 76, 34)], "hurtbox_extra": [Rect2(26, -128, 54, 34)],
		"cancel_into": ["clp", "chp", "clk", "chk"], "special_cancel": true,
	}))
	list.append(DataKit.move({
		"id": "chp", "display_name": "Chifrada", "button": HP, "stance": CROUCH,
		"startup": 8, "active": 5, "recovery": 21, "damage": 100, "hitstun": 22, "blockstun": 13, "hitstop": 11,
		"hit_height": MID, "knockback": Vector2(4, -15.5), "block_pushback": 6.0, "meter_gain": 46,
		"launch": true, "special_cancel": true,
		"hitboxes": [Rect2(0, -262, 72, 112)], "hurtbox_extra": [Rect2(0, -262, 48, 90)],
	}))
	list.append(DataKit.move({
		"id": "clk", "display_name": "Rasteira de Garra", "button": LK, "stance": CROUCH,
		"startup": 6, "active": 3, "recovery": 10, "damage": 45, "hitstun": 14, "blockstun": 10, "hitstop": 7,
		"hit_height": LOW, "knockback": Vector2(6, 0), "block_pushback": 5.0, "meter_gain": 28,
		"hitboxes": [Rect2(32, -50, 100, 36)], "hurtbox_extra": [Rect2(32, -50, 70, 36)],
		"cancel_into": ["chk", "clp"], "special_cancel": true,
	}))
	list.append(DataKit.move({
		"id": "chk", "display_name": "Varredura Brutal", "button": HK, "stance": CROUCH,
		"startup": 10, "active": 4, "recovery": 22, "damage": 110, "hitstun": 20, "blockstun": 15, "hitstop": 11,
		"hit_height": LOW, "knockback": Vector2(10, 0), "block_pushback": 9.0, "meter_gain": 52,
		"knockdown": true,
		"hitboxes": [Rect2(20, -46, 126, 40)], "hurtbox_extra": [Rect2(20, -46, 90, 40)],
	}))
	list.append(DataKit.move({
		"id": "jlp", "display_name": "Garra Aérea", "button": LP, "stance": AIR,
		"startup": 5, "active": 8, "recovery": 0, "damage": 50, "hitstun": 15, "blockstun": 10, "hitstop": 7,
		"hit_height": HIGH, "knockback": Vector2(5, 0), "block_pushback": 4.0, "meter_gain": 24,
		"hitboxes": [Rect2(14, -172, 76, 38)], "hurtbox_extra": [Rect2(14, -172, 52, 38)],
	}))
	list.append(DataKit.move({
		"id": "jhp", "display_name": "Martelo do Abismo", "button": HP, "stance": AIR,
		"startup": 8, "active": 7, "recovery": 0, "damage": 110, "hitstun": 23, "blockstun": 15, "hitstop": 11,
		"hit_height": HIGH, "knockback": Vector2(8, 0), "block_pushback": 6.0, "meter_gain": 50,
		"hitboxes": [Rect2(8, -150, 90, 70)], "hurtbox_extra": [Rect2(8, -150, 62, 70)],
	}))
	list.append(DataKit.move({
		"id": "jlk", "display_name": "Joelhada Pesada", "button": LK, "stance": AIR,
		"startup": 6, "active": 8, "recovery": 0, "damage": 55, "hitstun": 16, "blockstun": 10, "hitstop": 7,
		"hit_height": HIGH, "knockback": Vector2(6, 0), "block_pushback": 4.5, "meter_gain": 28,
		"hitboxes": [Rect2(10, -134, 76, 52)], "hurtbox_extra": [Rect2(10, -134, 52, 52)],
	}))
	list.append(DataKit.move({
		"id": "jhk", "display_name": "Queda Infernal", "button": HK, "stance": AIR,
		"startup": 9, "active": 8, "recovery": 0, "damage": 115, "hitstun": 24, "blockstun": 15, "hitstop": 11,
		"hit_height": HIGH, "knockback": Vector2(9, 0), "block_pushback": 7.0, "meter_gain": 52,
		"hitboxes": [Rect2(4, -104, 108, 66)], "hurtbox_extra": [Rect2(4, -104, 76, 66)],
	}))
	return list


static func _specials() -> Array[MoveData]:
	var list: Array[MoveData] = []
	var grab := {
		"display_name": "Agarrão Infernal", "kind": SPECIAL, "motion": HCB, "stance": STAND,
		"grab": true, "hold_on_link": true, "active": 3, "damage": 0, "meter_gain": 0, "animation": "agarrao",
	}
	list.append(DataKit.variant(grab, {
		"id": "agarrao_l", "button": LP, "startup": 5, "recovery": 30,
		"hitboxes": [Rect2(18, -180, 66, 160)], "link_on_hit": "agarrao_seq_l",
	}))
	list.append(DataKit.variant(grab, {
		"id": "agarrao_h", "button": HP, "startup": 7, "recovery": 34,
		"hitboxes": [Rect2(18, -180, 82, 160)], "link_on_hit": "agarrao_seq_h",
	}))
	var grab_seq := {
		"display_name": "Agarrão Infernal", "kind": SPECIAL, "stance": STAND, "holds_target": true, "followup": true,
		"startup": 50, "active": 1, "recovery": 2, "damage": 0, "meter_gain": 0, "animation": "agarrao_seq",
		"hold_offset": Vector2(62, -20),
	}
	list.append(DataKit.variant(grab_seq, {
		"id": "agarrao_seq_l",
		"events": [
			{"frame": 4, "type": "hold_offset", "offset": Vector2(60, -34)},
			{"frame": 10, "type": "held_hit", "hit": HELLFIRE_HIT},
			{"frame": 22, "type": "held_hit", "hit": HELLFIRE_HIT},
			{"frame": 26, "type": "hold_offset", "offset": Vector2(46, -96)},
			{"frame": 33, "type": "hold_offset", "offset": Vector2(64, 0)},
			{"frame": 34, "type": "held_hit", "release": true, "hit": {
				"damage": 80, "hitstun": 30, "hitstop": 14, "knockdown": true, "knockback": Vector2(9, 0),
				"meter_gain": 40, "effect": "hellfire_burst",
			}},
		],
	}))
	list.append(DataKit.variant(grab_seq, {
		"id": "agarrao_seq_h",
		"events": [
			{"frame": 4, "type": "hold_offset", "offset": Vector2(60, -34)},
			{"frame": 10, "type": "held_hit", "hit": HELLFIRE_HIT},
			{"frame": 16, "type": "held_hit", "hit": HELLFIRE_HIT},
			{"frame": 22, "type": "held_hit", "hit": HELLFIRE_HIT},
			{"frame": 26, "type": "hold_offset", "offset": Vector2(46, -96)},
			{"frame": 33, "type": "hold_offset", "offset": Vector2(64, 0)},
			{"frame": 34, "type": "held_hit", "release": true, "hit": {
				"damage": 100, "hitstun": 30, "hitstop": 16, "knockdown": true, "knockback": Vector2(11, 0),
				"meter_gain": 50, "effect": "hellfire_burst",
			}},
		],
	}))
	var charge := {
		"display_name": "Investida de Chifres", "kind": SPECIAL, "motion": QCF, "stance": STAND,
		"hit_height": MID, "stop_on_contact": true, "animation": "investida", "advance_start": 5, "super_cancel": true,
		"hitboxes": [Rect2(14, -196, 96, 176)], "hurtbox_extra": [Rect2(14, -196, 60, 120)],
	}
	list.append(DataKit.variant(charge, {
		"id": "investida_l", "button": LK, "startup": 9, "active": 16, "recovery": 18,
		"damage": 110, "hitstun": 22, "blockstun": 14, "hitstop": 12, "knockback": Vector2(14, 0), "block_pushback": 12.0,
		"meter_gain": 55, "advance": 11.0, "advance_frames": 20,
		"armor_start": 3, "armor_end": 18, "armor_hits": 1,
	}))
	list.append(DataKit.variant(charge, {
		"id": "investida_h", "button": HK, "startup": 13, "active": 20, "recovery": 22,
		"damage": 140, "hitstun": 24, "blockstun": 16, "hitstop": 14, "knockback": Vector2(12, 0), "block_pushback": 14.0,
		"knockdown": true, "meter_gain": 65, "advance": 13.0, "advance_frames": 26,
		"armor_start": 3, "armor_end": 26, "armor_hits": 2,
	}))
	var whip := {
		"display_name": "Chicote de Cabelo", "kind": SPECIAL, "motion": QCB, "stance": STAND,
		"hit_height": MID, "super_cancel": true,
	}
	list.append(DataKit.variant(whip, {
		"id": "chicote_l", "button": LP, "startup": 12, "active": 4, "recovery": 20,
		"damage": 80, "hitstun": 21, "blockstun": 13, "hitstop": 10, "knockback": Vector2(9, 0), "block_pushback": 8.0,
		"meter_gain": 42,
		"hitboxes": [Rect2(40, -196, 84, 42), Rect2(122, -172, 84, 42), Rect2(204, -146, 92, 42)],
		"hurtbox_extra": [Rect2(30, -196, 120, 42)],
	}))
	list.append(DataKit.variant(whip, {
		"id": "chicote_h", "button": HP, "startup": 15, "active": 5, "recovery": 24,
		"damage": 95, "hitstun": 22, "blockstun": 14, "hitstop": 11, "knockback": Vector2(6, -9), "block_pushback": 8.0,
		"meter_gain": 48,
		"hitboxes": [Rect2(14, -262, 70, 56), Rect2(66, -318, 82, 52), Rect2(124, -372, 90, 52), Rect2(176, -424, 90, 50)],
		"hurtbox_extra": [Rect2(14, -262, 90, 56)],
	}))
	list.append(DataKit.move({
		"id": "pacto", "display_name": "Pacto", "kind": UNIQUE, "button": R1, "stance": STAND,
		"startup": 18, "active": 1, "recovery": 14, "damage": 0, "meter_gain": 0,
		"events": [{"frame": 18, "type": "module", "name": "pact"}],
	}))
	list.append(DataKit.move({
		"id": "super", "display_name": "Forma Verdadeira", "kind": SUPER, "button": HP, "motion": DOUBLE_QCF,
		"stance": STAND, "meter_cost": GlobalTuning.METER_MAX, "super_freeze": 40, "super_freeze_frame": 2,
		"startup": 14, "active": 18, "recovery": 30, "invuln_start": 1, "invuln_end": 24,
		"advance": 14.0, "advance_start": 12, "advance_frames": 20, "stop_on_contact": true,
		"damage": 40, "chip_damage": 25, "hitstun": 30, "blockstun": 20, "hitstop": 10, "knockback": Vector2(4, 0),
		"block_pushback": 10.0, "scales_combo": false, "meter_gain": 0, "effect": "hellfire",
		"hitboxes": [Rect2(14, -210, 100, 200)],
		"link_on_hit": "super_seq", "hold_on_link": true,
		"events": [{"frame": 2, "type": "effect", "effect": "true_form", "offset": Vector2(0, -120)}],
	}))
	var claw := {"damage": 40, "hitstun": 20, "hitstop": 7, "scales_combo": false, "effect": "hellfire"}
	list.append(DataKit.move({
		"id": "super_seq", "display_name": "Forma Verdadeira", "kind": SUPER, "stance": STAND, "holds_target": true, "followup": true,
		"startup": 56, "active": 1, "recovery": 8, "damage": 0, "meter_gain": 0, "hold_offset": Vector2(74, -40),
		"events": [
			{"frame": 6, "type": "held_hit", "hit": claw},
			{"frame": 12, "type": "held_hit", "hit": claw},
			{"frame": 18, "type": "held_hit", "hit": claw},
			{"frame": 24, "type": "held_hit", "hit": claw},
			{"frame": 28, "type": "hold_offset", "offset": Vector2(52, -170)},
			{"frame": 40, "type": "hold_offset", "offset": Vector2(80, 0)},
			{"frame": 41, "type": "held_hit", "release": true, "hit": {
				"damage": 160, "hitstun": 34, "hitstop": 18, "knockdown": true, "knockback": Vector2(14, 0),
				"scales_combo": false, "effect": "hellfire_burst",
			}},
		],
	}))
	return list
