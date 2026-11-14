class_name CommandParser
extends RefCounted

enum Motion { NONE, QCF, QCB, DP, HCF, HCB, DOUBLE_QCF, DOUBLE_QCB, CHARGE_BACK_FORWARD, CHARGE_DOWN_UP }

const SEQUENCES := {
	Motion.QCF: [[2, 3, 6]],
	Motion.QCB: [[2, 1, 4]],
	Motion.DP: [[6, 2, 3], [6, 3, 2, 3]],
	Motion.HCF: [[4, 2, 6]],
	Motion.HCB: [[6, 2, 4]],
	Motion.DOUBLE_QCF: [[2, 6, 2, 6], [2, 3, 2, 3, 6]],
	Motion.DOUBLE_QCB: [[2, 4, 2, 4], [2, 1, 2, 1, 4]],
}

const MOTION_PRIORITY := {
	Motion.NONE: 0,
	Motion.QCF: 2, Motion.QCB: 2,
	Motion.CHARGE_BACK_FORWARD: 2, Motion.CHARGE_DOWN_UP: 2,
	Motion.DP: 3,
	Motion.HCF: 4, Motion.HCB: 4,
	Motion.DOUBLE_QCF: 6, Motion.DOUBLE_QCB: 6,
}

const CHARGE_FRAMES := 40


static func matches(buffer: InputBuffer, motion: Motion) -> bool:
	match motion:
		Motion.NONE:
			return true
		Motion.CHARGE_BACK_FORWARD:
			return buffer.forward and buffer.has_back_charge(CHARGE_FRAMES)
		Motion.CHARGE_DOWN_UP:
			return buffer.up and buffer.has_down_charge(CHARGE_FRAMES)
	for sequence in SEQUENCES.get(motion, []):
		if _matches_sequence(buffer, sequence):
			return true
	return false


static func priority(motion: Motion) -> int:
	return MOTION_PRIORITY.get(motion, 0)


static func _matches_sequence(buffer: InputBuffer, sequence: Array) -> bool:
	var history := buffer.direction_history
	var tolerance := GlobalTuning.COMMAND_TOLERANCE_FRAMES
	var now := buffer.frame
	var last_index := sequence.size() - 1
	var need := last_index
	var reference := now
	for index in range(history.size() - 1, -1, -1):
		var entry: Vector2i = history[index]
		var started := entry.y
		var ended: int = history[index + 1].y if index + 1 < history.size() else now
		if entry.x == sequence[need]:
			var gap := now - started if need == last_index else reference - ended
			if gap <= tolerance:
				reference = started
				need -= 1
				if need < 0:
					return true
				continue
		if reference - ended > tolerance:
			return false
	return false
