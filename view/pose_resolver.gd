class_name PoseResolver
extends RefCounted

const FALLBACK_ANIMATION := "idle"


static func resolve(animations: Dictionary, anim_name: String, frame: int, rig: Dictionary) -> Dictionary:
	var animation: Dictionary = animations.get(anim_name, animations.get(FALLBACK_ANIMATION, {}))
	var keys: Array = animation.get("keys", [])
	if keys.is_empty():
		return {}
	var last: Dictionary = keys[keys.size() - 1]
	var length: int = last["t"]
	var time := frame
	if animation.get("loop", false) and length > 0:
		time = frame % length
	if time >= length:
		return with_explicit_hip(last["pose"], rig)
	for index in range(keys.size() - 1):
		var from: Dictionary = keys[index]
		var to: Dictionary = keys[index + 1]
		if time >= from["t"] and time < to["t"]:
			var span := float(to["t"] - from["t"])
			var weight := smoothstep(0.0, 1.0, (time - from["t"]) / span)
			return blend(with_explicit_hip(from["pose"], rig), with_explicit_hip(to["pose"], rig), weight)
	return with_explicit_hip(keys[0]["pose"], rig)


static func blend(from: Dictionary, to: Dictionary, weight: float) -> Dictionary:
	var result := {}
	for joint in to:
		var target: float = to[joint]
		result[joint] = lerpf(from.get(joint, target), target, weight)
	return result


static func with_explicit_hip(pose: Dictionary, rig: Dictionary) -> Dictionary:
	if pose.get("hip_y", -1.0) >= 0.0:
		return pose
	var explicit := pose.duplicate()
	explicit["hip_y"] = maxf(_leg_drop(pose, "thigh_n", "shin_n", rig), _leg_drop(pose, "thigh_f", "shin_f", rig))
	return explicit


static func _leg_drop(pose: Dictionary, thigh_joint: String, shin_joint: String, rig: Dictionary) -> float:
	return cos(deg_to_rad(pose[thigh_joint])) * rig["thigh"] + cos(deg_to_rad(pose[shin_joint])) * rig["shin"] + rig.get("ankle_height", 0.0)


static func direction(angle_degrees: float) -> Vector2:
	var radians := deg_to_rad(angle_degrees)
	return Vector2(sin(radians), cos(radians))
