class_name GenericAnims
extends RefCounted

const AIR_HIP := 82.0

const STAND := {
	"spine": 172.0, "neck": 176.0,
	"arm_n": 55.0, "fore_n": 150.0, "arm_f": 40.0, "fore_f": 145.0,
	"thigh_n": 25.0, "shin_n": -5.0, "thigh_f": -20.0, "shin_f": 10.0,
	"lean_x": 0.0, "hip_y": -1.0,
}

const CROUCH := {
	"spine": 150.0, "neck": 160.0,
	"arm_n": 60.0, "fore_n": 150.0, "arm_f": 45.0, "fore_f": 145.0,
	"thigh_n": 75.0, "shin_n": -35.0, "thigh_f": 55.0, "shin_f": -55.0,
	"lean_x": -12.0, "hip_y": -1.0,
}

const TUCK := {
	"spine": 174.0, "neck": 176.0,
	"arm_n": 40.0, "fore_n": 110.0, "arm_f": -10.0, "fore_f": 70.0,
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
		"torso": 52.0, "neck": 10.0, "head_radius": 14.0,
		"upper_arm": 32.0, "forearm": 30.0, "thigh": 44.0, "shin": 42.0,
		"arm_width": 14.0, "forearm_width": 12.0, "thigh_width": 19.0, "shin_width": 15.0,
		"shoulder_half": 16.0, "hip_half": 12.0, "neck_width": 11.0,
		"hand_radius": 8.0, "foot_length": 15.0, "foot_width": 10.0, "ankle_height": 5.0,
	}


static func stand(overrides: Dictionary = {}) -> Dictionary:
	return _merged(STAND, overrides)


static func crouch(overrides: Dictionary = {}) -> Dictionary:
	return _merged(CROUCH, overrides)


static func tuck(overrides: Dictionary = {}) -> Dictionary:
	return _merged(TUCK, overrides)


static func down(overrides: Dictionary = {}) -> Dictionary:
	return _merged(DOWN, overrides)


static func _merged(base: Dictionary, overrides: Dictionary) -> Dictionary:
	var pose := base.duplicate()
	pose.merge(overrides, true)
	return pose


static func key(t: int, pose: Dictionary) -> Dictionary:
	return {"t": t, "pose": pose}


static func anim(keys: Array, loop: bool = false) -> Dictionary:
	return {"loop": loop, "keys": keys}


static func build() -> Dictionary:
	var a := {}
	var guard_block := {"arm_n": 75.0, "fore_n": 172.0, "arm_f": 65.0, "fore_f": 168.0}
	var prejump := stand({"spine": 165.0, "thigh_n": 55.0, "shin_n": -15.0, "thigh_f": 30.0, "shin_f": -35.0})
	var rise := tuck({"thigh_n": 15.0, "shin_n": 5.0, "thigh_f": -10.0, "shin_f": 15.0, "arm_n": 140.0, "fore_n": 160.0, "arm_f": 120.0, "fore_f": 150.0})
	var fall := tuck({"thigh_n": 25.0, "shin_n": 0.0, "thigh_f": -15.0, "shin_f": 10.0, "arm_n": 100.0, "fore_n": 130.0})
	var hit_air := tuck({"hip_y": 70.0, "spine": 230.0, "neck": 250.0, "thigh_n": 70.0, "shin_n": 40.0, "thigh_f": 50.0, "shin_f": 30.0, "arm_n": 110.0, "fore_n": 100.0, "arm_f": 130.0, "fore_f": 120.0})

	a["idle"] = anim([
		key(0, stand()),
		key(28, stand({"spine": 174.0, "thigh_n": 29.0, "shin_n": -10.0, "thigh_f": -23.0, "shin_f": 15.0, "arm_n": 58.0, "fore_n": 146.0})),
		key(56, stand()),
	], true)
	var walk_a := stand({"thigh_n": 35.0, "shin_n": 0.0, "thigh_f": -25.0, "shin_f": -5.0})
	var walk_b := stand({"thigh_n": 10.0, "shin_n": -10.0, "thigh_f": 5.0, "shin_f": -40.0})
	var walk_c := stand({"thigh_n": -25.0, "shin_n": -5.0, "thigh_f": 35.0, "shin_f": 0.0})
	var walk_d := stand({"thigh_n": 5.0, "shin_n": -40.0, "thigh_f": 10.0, "shin_f": -10.0})
	a["walk_forward"] = anim([key(0, walk_a), key(6, walk_b), key(12, walk_c), key(18, walk_d), key(24, walk_a)], true)
	a["walk_back"] = anim([key(0, walk_a), key(7, walk_d), key(14, walk_c), key(21, walk_b), key(28, walk_a)], true)
	a["crouch"] = anim([key(0, stand()), key(3, crouch())])
	a["prejump"] = anim([key(0, stand()), key(3, prejump)])
	a["jump"] = anim([key(0, rise), key(12, tuck()), key(28, tuck()), key(38, fall)])
	a["landing"] = anim([key(0, prejump), key(6, stand())])
	a["dash"] = anim([
		key(0, stand()),
		key(3, stand({"spine": 148.0, "lean_x": 10.0, "thigh_n": 55.0, "shin_n": 10.0, "thigh_f": -45.0, "shin_f": -30.0, "arm_n": 20.0, "fore_n": 80.0, "arm_f": -40.0, "fore_f": 10.0})),
		key(10, stand({"spine": 160.0, "thigh_n": 40.0, "shin_n": 0.0, "thigh_f": -30.0, "shin_f": -10.0})),
	])
	a["backdash"] = anim([
		key(0, stand()),
		key(3, stand({"spine": 196.0, "lean_x": -8.0, "thigh_n": 35.0, "shin_n": 20.0, "thigh_f": -30.0, "shin_f": -15.0, "arm_n": 70.0, "fore_n": 120.0})),
		key(14, stand()),
	])
	a["block_stand"] = anim([key(0, stand(_merged(guard_block, {"spine": 180.0, "lean_x": -4.0})))])
	a["block_crouch"] = anim([key(0, crouch(guard_block))])
	a["hit_stand"] = anim([
		key(0, stand({"spine": 202.0, "neck": 220.0, "arm_n": 20.0, "fore_n": 60.0, "arm_f": -10.0, "fore_f": 40.0, "lean_x": -10.0})),
		key(8, stand({"spine": 195.0, "neck": 205.0, "arm_n": 30.0, "fore_n": 80.0, "lean_x": -6.0})),
		key(26, stand()),
	])
	a["hit_crouch"] = anim([
		key(0, crouch({"spine": 190.0, "neck": 208.0, "arm_n": 20.0, "fore_n": 60.0, "lean_x": -8.0})),
		key(24, crouch()),
	])
	a["hit_air"] = anim([key(0, hit_air)])
	a["knockdown"] = anim([key(0, hit_air), key(5, down())])
	a["ko"] = anim([key(0, hit_air), key(6, down({"arm_n": 100.0, "fore_n": 95.0, "thigh_n": 100.0, "shin_n": 80.0}))])
	a["getup"] = anim([key(0, down()), key(8, crouch()), key(14, stand())])

	var punch := {"arm_n": 92.0, "fore_n": 90.0}
	a["lp"] = anim([
		key(0, stand()),
		key(2, stand({"arm_n": 30.0, "fore_n": 120.0})),
		key(5, stand(_merged(punch, {"spine": 166.0, "lean_x": 6.0}))),
		key(8, stand(_merged(punch, {"spine": 166.0, "lean_x": 6.0}))),
		key(14, stand()),
	])
	var hp_strike := stand({"arm_n": 95.0, "fore_n": 92.0, "arm_f": -20.0, "fore_f": 60.0, "spine": 152.0, "lean_x": 8.0, "thigh_n": 40.0, "shin_n": 0.0, "thigh_f": -35.0, "shin_f": -10.0})
	a["hp"] = anim([
		key(0, stand()),
		key(5, stand({"arm_n": -10.0, "fore_n": 100.0, "spine": 186.0, "lean_x": -6.0})),
		key(9, hp_strike),
		key(13, hp_strike),
		key(28, stand()),
	])
	var lk_kick := stand({"thigh_n": 100.0, "shin_n": 98.0, "spine": 184.0, "lean_x": -4.0})
	a["lk"] = anim([
		key(0, stand()),
		key(3, stand({"thigh_n": 80.0, "shin_n": -20.0})),
		key(6, lk_kick),
		key(9, lk_kick),
		key(17, stand()),
	])
	var hk_kick := stand({"thigh_n": 130.0, "shin_n": 120.0, "spine": 198.0, "neck": 190.0, "lean_x": 14.0, "arm_n": 20.0, "fore_n": 60.0, "arm_f": -30.0, "fore_f": 30.0})
	a["hk"] = anim([
		key(0, stand()),
		key(5, stand({"thigh_n": 100.0, "shin_n": 10.0, "spine": 186.0})),
		key(10, hk_kick),
		key(15, hk_kick),
		key(32, stand()),
	])
	a["clp"] = anim([
		key(0, crouch()),
		key(5, crouch(punch)),
		key(8, crouch(punch)),
		key(14, crouch()),
	])
	var uppercut := stand({"spine": 170.0, "arm_n": 172.0, "fore_n": 178.0, "lean_x": 8.0, "thigh_n": 30.0, "shin_n": 0.0})
	a["chp"] = anim([
		key(0, crouch()),
		key(4, crouch({"arm_n": 20.0, "fore_n": 60.0, "spine": 150.0})),
		key(8, uppercut),
		key(13, uppercut),
		key(30, crouch()),
	])
	var low_kick := crouch({"thigh_n": 78.0, "shin_n": 80.0})
	a["clk"] = anim([key(0, crouch()), key(6, low_kick), key(9, low_kick), key(17, crouch())])
	var sweep := crouch({"hip_y": 34.0, "thigh_n": 72.0, "shin_n": 82.0, "thigh_f": 60.0, "shin_f": -80.0, "spine": 140.0, "lean_x": 16.0, "arm_n": 20.0, "fore_n": 40.0})
	a["chk"] = anim([
		key(0, crouch()),
		key(4, crouch({"thigh_n": 100.0, "shin_n": -40.0, "spine": 160.0})),
		key(9, sweep),
		key(13, sweep),
		key(32, crouch()),
	])
	var air_punch := tuck({"arm_n": 95.0, "fore_n": 92.0})
	a["jlp"] = anim([key(0, tuck()), key(5, air_punch), key(13, air_punch), key(20, tuck())])
	var hammer := tuck({"arm_n": 70.0, "fore_n": 60.0, "arm_f": 60.0, "fore_f": 55.0, "spine": 160.0})
	a["jhp"] = anim([
		key(0, tuck()),
		key(4, tuck({"arm_n": 170.0, "fore_n": 170.0, "arm_f": 160.0, "fore_f": 165.0})),
		key(8, hammer),
		key(15, hammer),
		key(22, tuck()),
	])
	var air_kick := tuck({"thigh_n": 95.0, "shin_n": 92.0, "spine": 182.0})
	a["jlk"] = anim([key(0, tuck()), key(6, air_kick), key(14, air_kick), key(20, tuck())])
	var dive_kick := tuck({"thigh_n": 70.0, "shin_n": 68.0, "thigh_f": 20.0, "shin_f": -70.0, "spine": 190.0, "arm_n": 20.0, "fore_n": 70.0})
	a["jhk"] = anim([key(0, tuck()), key(9, dive_kick), key(16, dive_kick), key(24, tuck())])
	return a
