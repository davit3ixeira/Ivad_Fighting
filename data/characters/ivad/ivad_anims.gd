class_name IvadAnims
extends RefCounted

const AIR_HIP := 88.0
const HAIR_FILL := Color(0.5, 0.38, 0.1)
const HAIR_HIGHLIGHT := Color(1.0, 0.86, 0.4)

const STAND := {
	"spine": 177.0, "neck": 178.0,
	"arm_n": 15.0, "fore_n": 35.0, "arm_f": -8.0, "fore_f": 20.0,
	"thigh_n": 14.0, "shin_n": -4.0, "thigh_f": -14.0, "shin_f": 6.0,
	"lean_x": 0.0, "hip_y": -1.0,
}

const CROUCH := {
	"spine": 152.0, "neck": 162.0,
	"arm_n": 50.0, "fore_n": 120.0, "arm_f": 30.0, "fore_f": 110.0,
	"thigh_n": 75.0, "shin_n": -35.0, "thigh_f": 55.0, "shin_f": -55.0,
	"lean_x": -12.0, "hip_y": -1.0,
}

const TUCK := {
	"spine": 175.0, "neck": 177.0,
	"arm_n": 40.0, "fore_n": 100.0, "arm_f": -15.0, "fore_f": 60.0,
	"thigh_n": 70.0, "shin_n": -30.0, "thigh_f": 30.0, "shin_f": -50.0,
	"lean_x": 0.0, "hip_y": AIR_HIP,
}

const DOWN := {
	"spine": 262.0, "neck": 265.0,
	"arm_n": -80.0, "fore_n": -95.0, "arm_f": -100.0, "fore_f": -90.0,
	"thigh_n": 92.0, "shin_n": 88.0, "thigh_f": 84.0, "shin_f": 96.0,
	"lean_x": 0.0, "hip_y": 14.0,
}


static func rig() -> Dictionary:
	return {
		"torso": 54.0, "neck": 10.0, "head_radius": 13.5,
		"upper_arm": 32.0, "forearm": 30.0, "thigh": 46.0, "shin": 44.0,
		"arm_width": 13.0, "forearm_width": 11.0, "thigh_width": 17.0, "shin_width": 14.0,
		"shoulder_half": 15.0, "hip_half": 11.0, "neck_width": 10.0,
		"hand_radius": 7.5, "foot_length": 15.0, "foot_width": 10.0, "ankle_height": 5.0,
		"extras": [
			{
				"type": "hair_chain", "anchor": "head", "offset": Vector2(-9, -5), "cap": true,
				"segments": 8, "segment_length": 13.0, "root_width": 17.0, "tip_width": 5.0,
				"gravity": 1.1, "damping": 0.82,
				"fill_color": HAIR_FILL, "highlight_color": HAIR_HIGHLIGHT,
			},
			{
				"type": "hair_chain", "anchor": "head", "offset": Vector2(-11, 3),
				"segments": 6, "segment_length": 12.0, "root_width": 12.0, "tip_width": 4.0,
				"gravity": 1.0, "damping": 0.84,
				"fill_color": HAIR_FILL, "highlight_color": HAIR_HIGHLIGHT,
			},
		],
	}


static func stand(overrides: Dictionary = {}) -> Dictionary:
	return DataKit.merged(STAND, overrides)


static func crouch(overrides: Dictionary = {}) -> Dictionary:
	return DataKit.merged(CROUCH, overrides)


static func tuck(overrides: Dictionary = {}) -> Dictionary:
	return DataKit.merged(TUCK, overrides)


static func down(overrides: Dictionary = {}) -> Dictionary:
	return DataKit.merged(DOWN, overrides)


static func build() -> Dictionary:
	var a := {}
	_build_movement(a)
	_build_reactions(a)
	_build_normals(a)
	_build_specials(a)
	return a


static func _build_movement(a: Dictionary) -> void:
	var key := DataKit.key
	var anim := DataKit.anim
	var prejump := stand({"spine": 166.0, "thigh_n": 50.0, "shin_n": -18.0, "thigh_f": 28.0, "shin_f": -38.0})
	var rise := tuck({"thigh_n": 12.0, "shin_n": 6.0, "thigh_f": -12.0, "shin_f": 16.0, "arm_n": 30.0, "fore_n": 50.0, "arm_f": -30.0, "fore_f": -5.0})
	var fall := tuck({"thigh_n": 24.0, "shin_n": 0.0, "thigh_f": -16.0, "shin_f": 10.0, "arm_n": 70.0, "fore_n": 110.0, "arm_f": -60.0, "fore_f": -30.0})
	a["idle"] = anim.call([
		key.call(0, stand()),
		key.call(34, stand({"spine": 179.0, "neck": 181.0, "arm_n": 18.0, "fore_n": 30.0, "thigh_n": 17.0, "shin_n": -8.0, "thigh_f": -16.0, "shin_f": 10.0})),
		key.call(68, stand()),
	], true)
	var walk_a := stand({"thigh_n": 32.0, "shin_n": 2.0, "thigh_f": -24.0, "shin_f": -4.0, "arm_n": -10.0, "fore_n": 15.0, "arm_f": 20.0, "fore_f": 40.0})
	var walk_b := stand({"thigh_n": 8.0, "shin_n": -8.0, "thigh_f": 6.0, "shin_f": -42.0})
	var walk_c := stand({"thigh_n": -24.0, "shin_n": -4.0, "thigh_f": 32.0, "shin_f": 2.0, "arm_n": 25.0, "fore_n": 45.0, "arm_f": -15.0, "fore_f": 10.0})
	var walk_d := stand({"thigh_n": 6.0, "shin_n": -42.0, "thigh_f": 8.0, "shin_f": -8.0})
	a["walk_forward"] = anim.call([key.call(0, walk_a), key.call(7, walk_b), key.call(14, walk_c), key.call(21, walk_d), key.call(28, walk_a)], true)
	a["walk_back"] = anim.call([key.call(0, walk_a), key.call(8, walk_d), key.call(16, walk_c), key.call(24, walk_b), key.call(32, walk_a)], true)
	a["crouch"] = anim.call([key.call(0, stand()), key.call(3, crouch())])
	a["prejump"] = anim.call([key.call(0, stand()), key.call(3, prejump)])
	a["jump"] = anim.call([key.call(0, rise), key.call(12, tuck()), key.call(28, tuck()), key.call(38, fall)])
	a["landing"] = anim.call([key.call(0, prejump), key.call(6, stand())])
	a["dash"] = anim.call([
		key.call(0, stand()),
		key.call(3, stand({"spine": 150.0, "lean_x": 10.0, "thigh_n": 55.0, "shin_n": 10.0, "thigh_f": -45.0, "shin_f": -30.0, "arm_n": -40.0, "fore_n": -20.0, "arm_f": -60.0, "fore_f": -40.0})),
		key.call(10, stand({"spine": 162.0, "thigh_n": 38.0, "shin_n": 0.0, "thigh_f": -30.0, "shin_f": -10.0})),
	])
	a["backdash"] = anim.call([
		key.call(0, stand()),
		key.call(3, stand({"spine": 194.0, "lean_x": -8.0, "thigh_n": 32.0, "shin_n": 20.0, "thigh_f": -28.0, "shin_f": -15.0, "arm_n": 50.0, "fore_n": 70.0, "arm_f": 30.0, "fore_f": 50.0})),
		key.call(14, stand()),
	])
	a["intro"] = anim.call([
		key.call(0, stand()),
		key.call(14, stand({"arm_n": 150.0, "fore_n": 205.0, "spine": 181.0, "neck": 186.0})),
		key.call(40, stand({"arm_n": 158.0, "fore_n": 215.0, "spine": 182.0, "neck": 190.0})),
		key.call(58, stand()),
	])
	a["win"] = anim.call([
		key.call(0, stand()),
		key.call(16, stand({"arm_n": 62.0, "fore_n": 150.0, "arm_f": 50.0, "fore_f": 140.0, "spine": 185.0, "neck": 190.0, "lean_x": -4.0})),
	])


static func _build_reactions(a: Dictionary) -> void:
	var key := DataKit.key
	var anim := DataKit.anim
	var palm_guard := {"arm_n": 86.0, "fore_n": 152.0}
	var hit_air := tuck({"hip_y": 72.0, "spine": 230.0, "neck": 250.0, "thigh_n": 70.0, "shin_n": 40.0, "thigh_f": 50.0, "shin_f": 30.0, "arm_n": 110.0, "fore_n": 100.0, "arm_f": 130.0, "fore_f": 120.0})
	a["block_stand"] = anim.call([key.call(0, stand(DataKit.merged(palm_guard, {"spine": 181.0, "lean_x": -4.0})))])
	a["block_crouch"] = anim.call([key.call(0, crouch(palm_guard))])
	a["hit_stand"] = anim.call([
		key.call(0, stand({"spine": 203.0, "neck": 222.0, "arm_n": 40.0, "fore_n": 80.0, "arm_f": 10.0, "fore_f": 50.0, "lean_x": -10.0})),
		key.call(8, stand({"spine": 195.0, "neck": 205.0, "arm_n": 30.0, "fore_n": 60.0, "lean_x": -6.0})),
		key.call(26, stand()),
	])
	a["hit_crouch"] = anim.call([
		key.call(0, crouch({"spine": 190.0, "neck": 208.0, "arm_n": 20.0, "fore_n": 60.0, "lean_x": -18.0})),
		key.call(24, crouch()),
	])
	a["hit_air"] = anim.call([key.call(0, hit_air)])
	a["knockdown"] = anim.call([key.call(0, hit_air), key.call(5, down())])
	a["ko"] = anim.call([key.call(0, hit_air), key.call(6, down({"arm_n": 100.0, "fore_n": 95.0, "thigh_n": 100.0, "shin_n": 80.0}))])
	a["getup"] = anim.call([key.call(0, down()), key.call(8, crouch()), key.call(14, stand())])


static func _build_normals(a: Dictionary) -> void:
	var key := DataKit.key
	var anim := DataKit.anim
	var flick := stand({"arm_n": 90.0, "fore_n": 96.0, "spine": 175.0, "lean_x": 3.0})
	a["lp"] = anim.call([key.call(0, stand()), key.call(2, stand({"arm_n": 50.0, "fore_n": 130.0})), key.call(4, flick), key.call(6, flick), key.call(12, stand())])
	var palm := stand({"arm_n": 93.0, "fore_n": 88.0, "arm_f": -40.0, "fore_f": -10.0, "spine": 158.0, "lean_x": 8.0, "thigh_n": 36.0, "shin_n": 0.0, "thigh_f": -30.0, "shin_f": -8.0})
	a["hp"] = anim.call([
		key.call(0, stand()),
		key.call(6, stand({"arm_n": -30.0, "fore_n": 40.0, "spine": 186.0, "lean_x": -5.0})),
		key.call(10, palm),
		key.call(14, palm),
		key.call(28, stand()),
	])
	var lazy_kick := stand({"thigh_n": 99.0, "shin_n": 96.0, "spine": 187.0, "lean_x": -4.0})
	a["lk"] = anim.call([key.call(0, stand()), key.call(3, stand({"thigh_n": 72.0, "shin_n": -12.0})), key.call(6, lazy_kick), key.call(9, lazy_kick), key.call(17, stand())])
	var orbit := stand({"thigh_n": 128.0, "shin_n": 122.0, "spine": 200.0, "neck": 192.0, "lean_x": 12.0, "arm_n": 10.0, "fore_n": 30.0, "arm_f": -50.0, "fore_f": -20.0})
	a["hk"] = anim.call([
		key.call(0, stand()),
		key.call(6, stand({"thigh_n": 96.0, "shin_n": 0.0, "spine": 188.0})),
		key.call(12, orbit),
		key.call(17, orbit),
		key.call(33, stand()),
	])
	var poke := crouch({"arm_n": 92.0, "fore_n": 90.0})
	a["clp"] = anim.call([key.call(0, crouch()), key.call(5, poke), key.call(8, poke), key.call(14, crouch())])
	var ascend := stand({"spine": 172.0, "arm_n": 174.0, "fore_n": 180.0, "lean_x": 6.0, "thigh_n": 26.0, "shin_n": 0.0})
	a["chp"] = anim.call([
		key.call(0, crouch()),
		key.call(4, crouch({"arm_n": 20.0, "fore_n": 50.0, "spine": 148.0})),
		key.call(8, ascend),
		key.call(13, ascend),
		key.call(31, crouch()),
	])
	var low_kick := crouch({"thigh_n": 78.0, "shin_n": 80.0})
	a["clk"] = anim.call([key.call(0, crouch()), key.call(6, low_kick), key.call(9, low_kick), key.call(17, crouch())])
	var sweep := crouch({"hip_y": 36.0, "thigh_n": 72.0, "shin_n": 82.0, "thigh_f": 60.0, "shin_f": -80.0, "spine": 140.0, "lean_x": 14.0, "arm_n": 20.0, "fore_n": 40.0})
	a["chk"] = anim.call([
		key.call(0, crouch()),
		key.call(5, crouch({"thigh_n": 100.0, "shin_n": -40.0, "spine": 160.0})),
		key.call(10, sweep),
		key.call(14, sweep),
		key.call(33, crouch()),
	])
	var air_slap := tuck({"arm_n": 96.0, "fore_n": 92.0})
	a["jlp"] = anim.call([key.call(0, tuck()), key.call(5, air_slap), key.call(13, air_slap), key.call(20, tuck())])
	var meteor := tuck({"arm_n": 68.0, "fore_n": 58.0, "arm_f": 58.0, "fore_f": 52.0, "spine": 160.0})
	a["jhp"] = anim.call([
		key.call(0, tuck()),
		key.call(4, tuck({"arm_n": 170.0, "fore_n": 172.0, "arm_f": 160.0, "fore_f": 166.0})),
		key.call(8, meteor),
		key.call(15, meteor),
		key.call(22, tuck()),
	])
	var knee := tuck({"thigh_n": 98.0, "shin_n": 10.0, "spine": 170.0})
	a["jlk"] = anim.call([key.call(0, tuck()), key.call(6, knee), key.call(14, knee), key.call(20, tuck())])
	var comet := tuck({"thigh_n": 68.0, "shin_n": 66.0, "thigh_f": 20.0, "shin_f": -70.0, "spine": 190.0, "arm_n": -20.0, "fore_n": 10.0, "arm_f": -60.0, "fore_f": -30.0})
	a["jhk"] = anim.call([key.call(0, tuck()), key.call(9, comet), key.call(16, comet), key.call(24, tuck())])


static func _build_specials(a: Dictionary) -> void:
	var key := DataKit.key
	var anim := DataKit.anim
	var windup := stand({"arm_n": -40.0, "fore_n": 30.0, "arm_f": 60.0, "fore_f": 80.0, "spine": 192.0, "lean_x": -8.0, "thigh_n": 20.0, "thigh_f": -22.0})
	var coiled := stand({"arm_n": -58.0, "fore_n": 18.0, "arm_f": 86.0, "fore_f": 90.0, "spine": 199.0, "neck": 186.0, "lean_x": -13.0, "thigh_n": 24.0, "shin_n": -6.0, "thigh_f": -26.0, "shin_f": -2.0})
	var strike := stand({"arm_n": 94.0, "fore_n": 90.0, "arm_f": -45.0, "fore_f": 5.0, "spine": 152.0, "neck": 162.0, "lean_x": 12.0, "thigh_n": 46.0, "shin_n": 4.0, "thigh_f": -46.0, "shin_f": -16.0})
	a["soco_ivad_l"] = anim.call([key.call(0, stand()), key.call(4, windup), key.call(9, coiled), key.call(13, strike), key.call(18, strike), key.call(38, stand())])
	a["soco_ivad_h"] = anim.call([key.call(0, stand()), key.call(6, windup), key.call(12, coiled), key.call(18, strike), key.call(23, strike), key.call(46, stand())])
	var gather := stand({"arm_n": 40.0, "fore_n": 104.0, "arm_f": 28.0, "fore_f": 98.0, "spine": 183.0, "lean_x": -3.0})
	var release := stand({"arm_n": 88.0, "fore_n": 93.0, "arm_f": 78.0, "fore_f": 86.0, "spine": 168.0, "lean_x": 6.0, "thigh_n": 26.0, "thigh_f": -22.0})
	a["poco"] = anim.call([key.call(0, stand()), key.call(7, gather), key.call(14, release), key.call(22, release), key.call(40, stand())])
	var step_in := stand({"spine": 152.0, "lean_x": 8.0, "thigh_n": 50.0, "shin_n": -18.0, "thigh_f": -30.0, "shin_f": -20.0, "arm_n": 60.0, "fore_n": 84.0, "arm_f": -30.0, "fore_f": -10.0})
	a["passo"] = anim.call([key.call(0, stand()), key.call(7, step_in), key.call(20, step_in), key.call(40, stand())])
	var plant := stand({"spine": 150.0, "neck": 150.0, "arm_n": 32.0, "fore_n": 12.0, "thigh_n": 62.0, "shin_n": -30.0, "thigh_f": 22.0, "shin_f": -52.0})
	a["marca"] = anim.call([key.call(0, stand()), key.call(9, plant), key.call(13, plant), key.call(22, stand())])
	var raise := stand({"arm_n": 150.0, "fore_n": 172.0, "arm_f": 160.0, "fore_f": 176.0, "spine": 183.0, "neck": 186.0})
	var command := stand({"arm_n": 92.0, "fore_n": 90.0, "arm_f": 150.0, "fore_f": 172.0, "spine": 172.0, "lean_x": 5.0, "thigh_n": 24.0, "thigh_f": -22.0})
	var clench := stand({"arm_n": 104.0, "fore_n": 168.0, "arm_f": -20.0, "fore_f": 10.0, "spine": 178.0})
	a["super"] = anim.call([
		key.call(0, stand()),
		key.call(9, raise),
		key.call(15, command),
		key.call(74, command),
		key.call(80, clench),
		key.call(92, clench),
		key.call(102, stand()),
	])
