class_name HaluhoAnims
extends RefCounted

const AIR_HIP := 104.0
const HAIR_FILL := Color(0.84, 0.84, 0.9)
const HAIR_HIGHLIGHT := Color(1.0, 1.0, 1.0)
const HORN_FILL := Color(0.16, 0.1, 0.08)
const HORN_HIGHLIGHT := Color(1.0, 0.55, 0.25)

const STAND := {
	"spine": 166.0, "neck": 160.0,
	"arm_n": 45.0, "fore_n": 112.0, "arm_f": 28.0, "fore_f": 96.0,
	"thigh_n": 28.0, "shin_n": -6.0, "thigh_f": -24.0, "shin_f": 8.0,
	"lean_x": 0.0, "hip_y": -1.0,
}

const CROUCH := {
	"spine": 140.0, "neck": 148.0,
	"arm_n": 60.0, "fore_n": 108.0, "arm_f": 42.0, "fore_f": 96.0,
	"thigh_n": 78.0, "shin_n": -38.0, "thigh_f": 58.0, "shin_f": -58.0,
	"lean_x": -16.0, "hip_y": -1.0,
}

const TUCK := {
	"spine": 170.0, "neck": 168.0,
	"arm_n": 60.0, "fore_n": 128.0, "arm_f": 8.0, "fore_f": 78.0,
	"thigh_n": 72.0, "shin_n": -32.0, "thigh_f": 34.0, "shin_f": -50.0,
	"lean_x": 0.0, "hip_y": AIR_HIP,
}

const DOWN := {
	"spine": 262.0, "neck": 265.0,
	"arm_n": -80.0, "fore_n": -95.0, "arm_f": -100.0, "fore_f": -90.0,
	"thigh_n": 92.0, "shin_n": 88.0, "thigh_f": 84.0, "shin_f": 96.0,
	"lean_x": 0.0, "hip_y": 20.0,
}


static func rig() -> Dictionary:
	return {
		"torso": 64.0, "neck": 10.0, "head_radius": 15.0,
		"upper_arm": 38.0, "forearm": 34.0, "thigh": 50.0, "shin": 48.0,
		"arm_width": 19.0, "forearm_width": 17.0, "thigh_width": 23.0, "shin_width": 19.0,
		"shoulder_half": 25.0, "hip_half": 16.0, "neck_width": 16.0,
		"hand_radius": 11.0, "foot_length": 18.0, "foot_width": 13.0, "ankle_height": 6.0,
		"extras": [
			{
				"type": "hair_chain", "anchor": "head", "offset": Vector2(-10, -4), "cap": true,
				"segments": 12, "segment_length": 14.0, "root_width": 22.0, "tip_width": 6.0,
				"gravity": 1.0, "damping": 0.84,
				"fill_color": HAIR_FILL, "highlight_color": HAIR_HIGHLIGHT,
				"whip_moves": {
					"chicote_l": {"angle": 72.0, "reach": 300.0},
					"chicote_h": {"angle": 132.0, "reach": 320.0},
				},
			},
			{
				"type": "hair_chain", "anchor": "head", "offset": Vector2(-13, 6),
				"segments": 10, "segment_length": 13.0, "root_width": 15.0, "tip_width": 5.0,
				"gravity": 0.95, "damping": 0.86,
				"fill_color": HAIR_FILL, "highlight_color": HAIR_HIGHLIGHT,
			},
			{
				"type": "horns", "anchor": "head",
				"near_base": Vector2(5, -11), "far_base": Vector2(-3, -13),
				"control": Vector2(12, -34), "tip": Vector2(-14, -54),
				"base_width": 10.0, "tip_width": 2.0,
				"fill_color": HORN_FILL, "highlight_color": HORN_HIGHLIGHT,
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
	var prejump := stand({"spine": 150.0, "thigh_n": 60.0, "shin_n": -24.0, "thigh_f": 36.0, "shin_f": -44.0})
	var rise := tuck({"thigh_n": 14.0, "shin_n": 6.0, "thigh_f": -12.0, "shin_f": 14.0, "arm_n": 140.0, "fore_n": 160.0, "arm_f": 120.0, "fore_f": 150.0})
	var fall := tuck({"thigh_n": 26.0, "shin_n": 0.0, "thigh_f": -16.0, "shin_f": 10.0, "arm_n": 100.0, "fore_n": 130.0})
	a["idle"] = anim.call([
		key.call(0, stand()),
		key.call(36, stand({"spine": 162.0, "neck": 156.0, "arm_n": 50.0, "fore_n": 108.0, "arm_f": 32.0, "fore_f": 92.0, "thigh_n": 31.0, "shin_n": -11.0, "thigh_f": -26.0, "shin_f": 12.0})),
		key.call(72, stand()),
	], true)
	var walk_a := stand({"thigh_n": 38.0, "shin_n": 0.0, "thigh_f": -26.0, "shin_f": -6.0, "spine": 162.0})
	var walk_b := stand({"thigh_n": 10.0, "shin_n": -12.0, "thigh_f": 8.0, "shin_f": -46.0, "spine": 168.0})
	var walk_c := stand({"thigh_n": -26.0, "shin_n": -6.0, "thigh_f": 38.0, "shin_f": 0.0, "spine": 162.0})
	var walk_d := stand({"thigh_n": 8.0, "shin_n": -46.0, "thigh_f": 10.0, "shin_f": -12.0, "spine": 168.0})
	a["walk_forward"] = anim.call([key.call(0, walk_a), key.call(8, walk_b), key.call(16, walk_c), key.call(24, walk_d), key.call(32, walk_a)], true)
	a["walk_back"] = anim.call([key.call(0, walk_a), key.call(9, walk_d), key.call(18, walk_c), key.call(27, walk_b), key.call(36, walk_a)], true)
	a["crouch"] = anim.call([key.call(0, stand()), key.call(4, crouch())])
	a["prejump"] = anim.call([key.call(0, stand()), key.call(3, prejump)])
	a["jump"] = anim.call([key.call(0, rise), key.call(12, tuck()), key.call(28, tuck()), key.call(38, fall)])
	a["landing"] = anim.call([key.call(0, prejump), key.call(7, stand())])
	a["dash"] = anim.call([
		key.call(0, stand()),
		key.call(4, stand({"spine": 138.0, "neck": 128.0, "lean_x": 12.0, "thigh_n": 58.0, "shin_n": 8.0, "thigh_f": -46.0, "shin_f": -34.0, "arm_n": -30.0, "fore_n": -10.0, "arm_f": -50.0, "fore_f": -30.0})),
		key.call(12, stand({"spine": 156.0, "thigh_n": 40.0, "shin_n": 0.0, "thigh_f": -30.0, "shin_f": -10.0})),
	])
	a["backdash"] = anim.call([
		key.call(0, stand()),
		key.call(4, stand({"spine": 188.0, "lean_x": -10.0, "thigh_n": 34.0, "shin_n": 20.0, "thigh_f": -30.0, "shin_f": -16.0, "arm_n": 70.0, "fore_n": 120.0})),
		key.call(16, stand()),
	])
	var roar := stand({"arm_n": 122.0, "fore_n": 96.0, "arm_f": -62.0, "fore_f": -88.0, "spine": 194.0, "neck": 212.0, "lean_x": -4.0})
	a["intro"] = anim.call([key.call(0, stand()), key.call(14, roar), key.call(40, DataKit.merged(roar, {"neck": 205.0})), key.call(58, stand())])
	a["win"] = anim.call([
		key.call(0, stand()),
		key.call(16, stand({"arm_n": 40.0, "fore_n": -75.0, "arm_f": 46.0, "fore_f": -70.0, "spine": 186.0, "neck": 196.0, "lean_x": -4.0, "thigh_n": 18.0, "thigh_f": -18.0})),
	])
	a["held"] = anim.call([key.call(0, stand({"spine": 200.0, "neck": 228.0, "arm_n": 140.0, "fore_n": 160.0, "arm_f": 120.0, "fore_f": 140.0, "thigh_n": 20.0, "shin_n": -10.0, "thigh_f": -10.0, "shin_f": -20.0}))])


static func _build_reactions(a: Dictionary) -> void:
	var key := DataKit.key
	var anim := DataKit.anim
	var guard := {"arm_n": 80.0, "fore_n": 168.0, "arm_f": 70.0, "fore_f": 162.0}
	var hit_air := tuck({"hip_y": 84.0, "spine": 230.0, "neck": 250.0, "thigh_n": 70.0, "shin_n": 40.0, "thigh_f": 50.0, "shin_f": 30.0, "arm_n": 110.0, "fore_n": 100.0, "arm_f": 130.0, "fore_f": 120.0})
	a["block_stand"] = anim.call([key.call(0, stand(DataKit.merged(guard, {"spine": 176.0, "neck": 168.0, "lean_x": -4.0})))])
	a["block_crouch"] = anim.call([key.call(0, crouch(guard))])
	a["hit_stand"] = anim.call([
		key.call(0, stand({"spine": 198.0, "neck": 222.0, "arm_n": 30.0, "fore_n": 70.0, "arm_f": 0.0, "fore_f": 40.0, "lean_x": -10.0})),
		key.call(8, stand({"spine": 190.0, "neck": 200.0, "arm_n": 36.0, "fore_n": 80.0, "lean_x": -6.0})),
		key.call(26, stand()),
	])
	a["hit_crouch"] = anim.call([
		key.call(0, crouch({"spine": 184.0, "neck": 204.0, "arm_n": 20.0, "fore_n": 60.0, "lean_x": -20.0})),
		key.call(24, crouch()),
	])
	a["hit_air"] = anim.call([key.call(0, hit_air)])
	a["knockdown"] = anim.call([key.call(0, hit_air), key.call(5, down())])
	a["ko"] = anim.call([key.call(0, hit_air), key.call(6, down({"arm_n": 100.0, "fore_n": 95.0, "thigh_n": 100.0, "shin_n": 80.0}))])
	a["getup"] = anim.call([key.call(0, down()), key.call(8, crouch()), key.call(14, stand())])


static func _build_normals(a: Dictionary) -> void:
	var key := DataKit.key
	var anim := DataKit.anim
	var swipe := stand({"arm_n": 98.0, "fore_n": 82.0, "spine": 156.0, "lean_x": 6.0})
	a["lp"] = anim.call([key.call(0, stand()), key.call(3, stand({"arm_n": 25.0, "fore_n": 150.0})), key.call(6, swipe), key.call(9, swipe), key.call(17, stand())])
	var abyss := stand({"arm_n": 93.0, "fore_n": 92.0, "arm_f": -35.0, "fore_f": 0.0, "spine": 150.0, "neck": 145.0, "lean_x": 14.0, "thigh_n": 46.0, "shin_n": 0.0, "thigh_f": -38.0, "shin_f": -12.0})
	a["hp"] = anim.call([key.call(0, stand()), key.call(6, stand({"arm_n": -25.0, "fore_n": 40.0, "spine": 186.0, "lean_x": -6.0})), key.call(11, abyss), key.call(15, abyss), key.call(34, stand())])
	var stomp := stand({"thigh_n": 96.0, "shin_n": 90.0, "spine": 182.0, "lean_x": -4.0})
	a["lk"] = anim.call([key.call(0, stand()), key.call(4, stand({"thigh_n": 82.0, "shin_n": -10.0})), key.call(7, stomp), key.call(10, stomp), key.call(20, stand())])
	var buck := stand({"thigh_n": 128.0, "shin_n": 120.0, "spine": 202.0, "neck": 186.0, "lean_x": 12.0, "arm_n": 10.0, "fore_n": 40.0, "arm_f": -50.0, "fore_f": -20.0})
	a["hk"] = anim.call([key.call(0, stand()), key.call(7, stand({"thigh_n": 96.0, "shin_n": 0.0, "spine": 190.0})), key.call(13, buck), key.call(18, buck), key.call(38, stand())])
	var elbow := crouch({"arm_n": 92.0, "fore_n": 80.0})
	a["clp"] = anim.call([key.call(0, crouch()), key.call(6, elbow), key.call(9, elbow), key.call(16, crouch())])
	var gore := stand({"spine": 176.0, "neck": 192.0, "arm_n": 150.0, "fore_n": 170.0, "arm_f": 140.0, "fore_f": 160.0, "thigh_n": 28.0, "lean_x": 6.0})
	a["chp"] = anim.call([key.call(0, crouch()), key.call(5, crouch({"spine": 120.0, "neck": 112.0})), key.call(9, gore), key.call(14, gore), key.call(35, crouch())])
	var low_kick := crouch({"thigh_n": 78.0, "shin_n": 80.0})
	a["clk"] = anim.call([key.call(0, crouch()), key.call(7, low_kick), key.call(10, low_kick), key.call(19, crouch())])
	var sweep := crouch({"hip_y": 40.0, "thigh_n": 72.0, "shin_n": 82.0, "thigh_f": 60.0, "shin_f": -80.0, "spine": 138.0, "lean_x": 14.0, "arm_n": 20.0, "fore_n": 40.0})
	a["chk"] = anim.call([key.call(0, crouch()), key.call(5, crouch({"thigh_n": 100.0, "shin_n": -40.0, "spine": 158.0})), key.call(11, sweep), key.call(15, sweep), key.call(37, crouch())])
	var air_claw := tuck({"arm_n": 98.0, "fore_n": 92.0})
	a["jlp"] = anim.call([key.call(0, tuck()), key.call(6, air_claw), key.call(14, air_claw), key.call(20, tuck())])
	var hammer := tuck({"arm_n": 66.0, "fore_n": 56.0, "arm_f": 56.0, "fore_f": 50.0, "spine": 158.0})
	a["jhp"] = anim.call([key.call(0, tuck()), key.call(4, tuck({"arm_n": 170.0, "fore_n": 172.0, "arm_f": 160.0, "fore_f": 166.0})), key.call(9, hammer), key.call(16, hammer), key.call(24, tuck())])
	var knee := tuck({"thigh_n": 100.0, "shin_n": 12.0, "spine": 168.0})
	a["jlk"] = anim.call([key.call(0, tuck()), key.call(7, knee), key.call(15, knee), key.call(22, tuck())])
	var drop := tuck({"thigh_n": 52.0, "shin_n": 44.0, "thigh_f": 40.0, "shin_f": 36.0, "spine": 186.0, "arm_n": 120.0, "fore_n": 150.0, "arm_f": 100.0, "fore_f": 130.0})
	a["jhk"] = anim.call([key.call(0, tuck()), key.call(10, drop), key.call(18, drop), key.call(26, tuck())])


static func _build_specials(a: Dictionary) -> void:
	var key := DataKit.key
	var anim := DataKit.anim
	var reach := stand({"arm_n": 92.0, "fore_n": 96.0, "arm_f": 80.0, "fore_f": 90.0, "spine": 148.0, "neck": 140.0, "lean_x": 14.0, "thigh_n": 46.0, "shin_n": 0.0, "thigh_f": -38.0, "shin_f": -14.0})
	var whiff := stand({"arm_n": 40.0, "fore_n": 70.0, "arm_f": 20.0, "fore_f": 50.0, "spine": 142.0, "neck": 136.0, "lean_x": 8.0, "thigh_n": 44.0, "thigh_f": -34.0})
	a["agarrao"] = anim.call([key.call(0, stand()), key.call(5, reach), key.call(9, reach), key.call(28, whiff), key.call(42, stand())])
	var hold := stand({"arm_n": 112.0, "fore_n": 150.0, "arm_f": 30.0, "fore_f": 70.0, "spine": 176.0, "neck": 170.0})
	var cocked := DataKit.merged(hold, {"arm_f": -50.0, "fore_f": 20.0})
	var punch := DataKit.merged(hold, {"arm_f": 96.0, "fore_f": 92.0, "spine": 166.0, "lean_x": 6.0})
	var knee := DataKit.merged(hold, {"thigh_n": 100.0, "shin_n": -15.0, "arm_f": 70.0, "fore_f": 100.0})
	var lift := stand({"arm_n": 165.0, "fore_n": 172.0, "arm_f": 160.0, "fore_f": 170.0, "spine": 186.0, "neck": 192.0})
	var slam := stand({"arm_n": 80.0, "fore_n": 50.0, "arm_f": 70.0, "fore_f": 40.0, "spine": 132.0, "neck": 125.0, "thigh_n": 70.0, "shin_n": -30.0, "thigh_f": 50.0, "shin_f": -50.0, "lean_x": 14.0})
	a["agarrao_seq"] = anim.call([
		key.call(0, hold), key.call(7, cocked), key.call(10, punch), key.call(14, cocked), key.call(16, punch),
		key.call(20, knee), key.call(22, knee), key.call(26, lift), key.call(31, lift), key.call(34, slam),
		key.call(42, slam), key.call(52, stand()),
	])
	var charge_a := stand({"spine": 118.0, "neck": 100.0, "arm_n": -40.0, "fore_n": -20.0, "arm_f": -60.0, "fore_f": -40.0, "thigh_n": 62.0, "shin_n": 2.0, "thigh_f": -48.0, "shin_f": -38.0, "lean_x": 18.0})
	var charge_b := DataKit.merged(charge_a, {"thigh_n": -30.0, "shin_n": -48.0, "thigh_f": 60.0, "shin_f": 4.0})
	a["investida_l"] = _run_cycle(charge_a, charge_b, 25, 43)
	a["investida_h"] = _run_cycle(charge_a, charge_b, 33, 55)
	var gather := stand({"spine": 192.0, "neck": 222.0, "arm_n": 60.0, "fore_n": 140.0, "arm_f": 40.0, "fore_f": 120.0, "lean_x": -6.0})
	var lash := stand({"spine": 150.0, "neck": 118.0, "arm_n": 20.0, "fore_n": 40.0, "arm_f": -20.0, "fore_f": 10.0, "lean_x": 12.0, "thigh_n": 42.0, "thigh_f": -34.0})
	a["chicote_l"] = anim.call([key.call(0, stand()), key.call(8, gather), key.call(13, lash), key.call(17, lash), key.call(36, stand())])
	var dip := stand({"spine": 150.0, "neck": 120.0, "thigh_n": 60.0, "shin_n": -30.0, "thigh_f": 40.0, "shin_f": -50.0})
	var lash_up := stand({"spine": 188.0, "neck": 205.0, "arm_n": 150.0, "fore_n": 170.0, "arm_f": 120.0, "fore_f": 150.0, "thigh_n": 24.0, "thigh_f": -18.0})
	a["chicote_h"] = anim.call([key.call(0, stand()), key.call(10, dip), key.call(16, lash_up), key.call(21, lash_up), key.call(44, stand())])
	var raise := stand({"arm_n": 158.0, "fore_n": 165.0, "arm_f": 150.0, "fore_f": 160.0, "spine": 182.0, "neck": 192.0})
	var rip := stand({"arm_n": 60.0, "fore_n": 205.0, "arm_f": 50.0, "fore_f": 215.0, "spine": 158.0, "neck": 145.0, "thigh_n": 50.0, "shin_n": -20.0, "thigh_f": 30.0, "shin_f": -40.0})
	var roar := stand({"arm_n": 120.0, "fore_n": 100.0, "arm_f": -60.0, "fore_f": -90.0, "spine": 194.0, "neck": 210.0, "lean_x": -6.0})
	a["pacto"] = anim.call([key.call(0, stand()), key.call(8, raise), key.call(17, rip), key.call(22, roar), key.call(30, roar), key.call(40, stand())])
	var ready := crouch({"spine": 132.0, "arm_n": -30.0, "fore_n": 0.0, "arm_f": -50.0, "fore_f": -20.0})
	var rush := stand({"spine": 128.0, "neck": 120.0, "arm_n": 96.0, "fore_n": 92.0, "arm_f": 80.0, "fore_f": 86.0, "thigh_n": 62.0, "shin_n": 2.0, "thigh_f": -48.0, "shin_f": -38.0, "lean_x": 20.0})
	a["super"] = anim.call([key.call(0, stand()), key.call(2, roar), key.call(11, ready), key.call(13, rush), key.call(31, rush), key.call(42, whiff), key.call(62, stand())])
	var claw := DataKit.merged(hold, {"arm_f": 100.0, "fore_f": 70.0, "spine": 160.0, "lean_x": 6.0})
	var seq_keys := [key.call(0, hold)]
	for strike in 4:
		seq_keys.append(key.call(3 + strike * 6, cocked))
		seq_keys.append(key.call(6 + strike * 6, claw))
	seq_keys.append_array([key.call(28, lift), key.call(36, lift), key.call(40, slam), key.call(50, slam), key.call(64, stand())])
	a["super_seq"] = anim.call(seq_keys)


static func _run_cycle(pose_a: Dictionary, pose_b: Dictionary, active_end: int, total: int) -> Dictionary:
	var keys := [DataKit.key(0, stand()), DataKit.key(4, pose_a)]
	var time := 9
	var use_b := true
	while time < active_end:
		keys.append(DataKit.key(time, pose_b if use_b else pose_a))
		use_b = not use_b
		time += 5
	keys.append(DataKit.key(active_end, pose_a))
	keys.append(DataKit.key(total, stand()))
	return DataKit.anim(keys)
