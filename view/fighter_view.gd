class_name FighterView
extends Node2D

const BLEND_FRAMES := 3
const BODY_COLOR := Color(0.04, 0.045, 0.08)
const BODY_FAR_COLOR := Color(0.025, 0.03, 0.055)
const OUTLINE_EXTRA_WIDTH := 5.0
const HALO_WIDE_EXTRA := 18.0
const HALO_WIDE_ALPHA := 0.07
const HALO_TIGHT_EXTRA := 10.0
const HALO_TIGHT_ALPHA := 0.13
const HIT_FLASH_STRENGTH := 0.55
const HIT_FLASH_DECAY := 0.12
const HITSTOP_JITTER := 2.0
const CHARGE_BASE_RADIUS := 7.0
const CHARGE_EXTRA_RADIUS := 15.0
const CHARGE_SPARK_COUNT := 5
const FORM_SCALE_SPEED := 0.12
const AURA_JOINTS: Array[String] = ["hips", "chest", "head", "hand_n", "hand_f", "knee_n", "knee_f"]
const AURA_FLAMES := 7
const WING_FEATHERS := 5
const WING_SHADOW := Color(0.05, 0.0, 0.03)


enum Part { FAR_LIMBS, TORSO, NEAR_LEG, NEAR_ARM }

var fighter: Fighter
var outline_color: Color = Color.WHITE
var joints: Dictionary = {}

var _rig: Dictionary = {}
var _pose: Dictionary = {}
var _last_anim: String = ""
var _blend_from: Dictionary = {}
var _blend_left: int = 0
var _flash: float = 0.0
var _clock: int = 0
var _extras: Array = []
var _halo: RigLayer
var _body: RigLayer
var _flags: Dictionary = {}
var _form_scale: float = 1.0


func setup(target: Fighter, player_color: Color) -> void:
	outline_color = player_color
	_halo = RigLayer.new()
	_halo.view = self
	_halo.is_halo = true
	_halo.material = DrawKit.additive_material()
	add_child(_halo)
	_body = RigLayer.new()
	_body.view = self
	add_child(_body)
	bind(target)


func bind(target: Fighter) -> void:
	fighter = target
	_rig = fighter.data.rig
	_last_anim = ""
	_blend_left = 0
	_pose = {}
	_extras.clear()
	_form_scale = 1.0
	_flags = {}
	for config in _rig.get("extras", []):
		var extra = _create_extra(config.get("type", ""))
		if extra == null:
			continue
		extra.configure(config)
		_extras.append(extra)
	sync()


func sync() -> void:
	_clock += 1
	var target := PoseResolver.resolve(fighter.data.animations, fighter.anim_name, fighter.anim_frame, _rig)
	if fighter.anim_name != _last_anim:
		if not _pose.is_empty() and _last_anim != "":
			_blend_from = _pose
			_blend_left = BLEND_FRAMES
		_last_anim = fighter.anim_name
	if _blend_left > 0 and fighter.hitstop == 0:
		_blend_left -= 1
	if _blend_left > 0:
		_pose = PoseResolver.blend(_blend_from, target, 1.0 - float(_blend_left) / BLEND_FRAMES)
	else:
		_pose = target
	joints = _compute_joints(_pose)
	position = fighter.position
	_flags = fighter.visual_flags()
	_form_scale = move_toward(_form_scale, float(_flags.get("form_scale", 1.0)), FORM_SCALE_SPEED)
	scale = Vector2(fighter.facing * _form_scale, _form_scale)
	visible = not fighter.hidden
	var stunned := fighter.state == Fighter.State.HITSTUN or fighter.state == Fighter.State.AIR_HITSTUN or fighter.state == Fighter.State.KO
	if fighter.hitstop > 0 and stunned:
		position.x += (float(fighter.hitstop % 2) * 2.0 - 1.0) * HITSTOP_JITTER
		_flash = HIT_FLASH_STRENGTH
	else:
		_flash = maxf(_flash - HIT_FLASH_DECAY, 0.0)
	if fighter.charge_frames > 0:
		position.x += (float(_clock % 2) * 2.0 - 1.0) * fighter.charge_ratio() * 1.5
	for extra in _extras:
		extra.update(self)
	_halo.queue_redraw()
	_body.queue_redraw()


func _create_extra(extra_type: String) -> RefCounted:
	match extra_type:
		"hair_chain":
			return HairChain.new()
		"horns":
			return Horns.new()
	return null


func joint_world(joint: String, offset: Vector2 = Vector2.ZERO) -> Vector2:
	var local: Vector2 = joints.get(joint, Vector2.ZERO) + offset
	return position + Vector2(local.x * scale.x, local.y * scale.y)


func rig_value(field: String) -> float:
	return _rig.get(field, 0.0)


func tinted(color: Color) -> Color:
	return color.lerp(outline_color, _flash)


func _compute_joints(pose: Dictionary) -> Dictionary:
	var result := {}
	if pose.is_empty():
		return result
	var hips := Vector2(pose["lean_x"], -pose["hip_y"])
	var chest: Vector2 = hips + PoseResolver.direction(pose["spine"]) * _rig["torso"]
	result["hips"] = hips
	result["chest"] = chest
	result["head"] = chest + PoseResolver.direction(pose["neck"]) * (_rig["neck"] + _rig["head_radius"])
	for side in ["n", "f"]:
		var elbow: Vector2 = chest + PoseResolver.direction(pose["arm_" + side]) * _rig["upper_arm"]
		var knee: Vector2 = hips + PoseResolver.direction(pose["thigh_" + side]) * _rig["thigh"]
		var shin_direction := PoseResolver.direction(pose["shin_" + side])
		var ankle: Vector2 = knee + shin_direction * _rig["shin"]
		result["elbow_" + side] = elbow
		result["hand_" + side] = elbow + PoseResolver.direction(pose["fore_" + side]) * _rig["forearm"]
		result["knee_" + side] = knee
		result["foot_" + side] = ankle
		result["toe_" + side] = ankle + Vector2(shin_direction.y, -shin_direction.x) * _rig["foot_length"]
	return result


func draw_halo(canvas: CanvasItem) -> void:
	if joints.is_empty():
		return
	var wide := Color(outline_color, HALO_WIDE_ALPHA)
	var tight := Color(outline_color, HALO_TIGHT_ALPHA)
	if _flags.has("aura_color"):
		_draw_aura(canvas, _flags["aura_color"], float(_flags.get("aura_strength", 1.0)))
	if _flags.get("wings", false):
		_draw_wings(canvas, Color(fighter.data.power_color, 0.35), 8.0, true)
	for extra in _extras:
		extra.draw(canvas, self, tight, HALO_TIGHT_EXTRA, false)
	for part in Part.values():
		_draw_part(canvas, part, wide, HALO_WIDE_EXTRA)
		_draw_part(canvas, part, tight, HALO_TIGHT_EXTRA)
	_draw_charge(canvas)


func draw_body(canvas: CanvasItem) -> void:
	if joints.is_empty():
		return
	var body := tinted(BODY_COLOR)
	var body_far := tinted(BODY_FAR_COLOR)
	if _flags.get("wings", false):
		_draw_wings(canvas, outline_color, OUTLINE_EXTRA_WIDTH, false)
		_draw_wings(canvas, tinted(WING_SHADOW), 0.0, false)
	for extra in _extras:
		extra.draw(canvas, self, outline_color, OUTLINE_EXTRA_WIDTH, false)
	for extra in _extras:
		extra.draw(canvas, self, outline_color, 0.0, true)
	_draw_part(canvas, Part.FAR_LIMBS, outline_color, OUTLINE_EXTRA_WIDTH)
	_draw_part(canvas, Part.FAR_LIMBS, body_far, 0.0)
	_draw_part(canvas, Part.TORSO, outline_color, OUTLINE_EXTRA_WIDTH)
	_draw_part(canvas, Part.TORSO, body, 0.0)
	for extra in _extras:
		extra.draw_front(canvas, self, outline_color, OUTLINE_EXTRA_WIDTH, false)
	for extra in _extras:
		extra.draw_front(canvas, self, outline_color, 0.0, true)
	_draw_accent(canvas)
	_draw_part(canvas, Part.NEAR_LEG, outline_color, OUTLINE_EXTRA_WIDTH)
	_draw_part(canvas, Part.NEAR_LEG, body, 0.0)
	_draw_part(canvas, Part.NEAR_ARM, outline_color, OUTLINE_EXTRA_WIDTH)
	_draw_part(canvas, Part.NEAR_ARM, body, 0.0)


func _draw_part(canvas: CanvasItem, part: Part, color: Color, extra: float) -> void:
	match part:
		Part.FAR_LIMBS:
			_draw_arm(canvas, "f", color, extra)
			_draw_leg(canvas, "f", color, extra)
		Part.TORSO:
			_draw_torso(canvas, color, extra)
		Part.NEAR_LEG:
			_draw_leg(canvas, "n", color, extra)
		Part.NEAR_ARM:
			_draw_arm(canvas, "n", color, extra)


func _draw_arm(canvas: CanvasItem, side: String, color: Color, extra: float) -> void:
	_draw_capsule(canvas, joints["chest"], joints["elbow_" + side], _rig["arm_width"] + extra, color)
	_draw_capsule(canvas, joints["elbow_" + side], joints["hand_" + side], _rig["forearm_width"] + extra, color)
	DrawKit.disc(canvas, joints["hand_" + side], _rig["hand_radius"] + extra * 0.5, color)


func _draw_leg(canvas: CanvasItem, side: String, color: Color, extra: float) -> void:
	_draw_capsule(canvas, joints["hips"], joints["knee_" + side], _rig["thigh_width"] + extra, color)
	_draw_capsule(canvas, joints["knee_" + side], joints["foot_" + side], _rig["shin_width"] + extra, color)
	_draw_capsule(canvas, joints["foot_" + side], joints["toe_" + side], _rig["foot_width"] + extra, color)


func _draw_torso(canvas: CanvasItem, color: Color, extra: float) -> void:
	var hips: Vector2 = joints["hips"]
	var chest: Vector2 = joints["chest"]
	var head: Vector2 = joints["head"]
	var hip_half: float = _rig["hip_half"] + extra * 0.5
	var shoulder_half: float = _rig["shoulder_half"] + extra * 0.5
	var axis := (chest - hips).normalized()
	var normal := Vector2(-axis.y, axis.x)
	DrawKit.quad(canvas, hips - normal * hip_half, chest - normal * shoulder_half, chest + normal * shoulder_half, hips + normal * hip_half, color)
	DrawKit.disc(canvas, hips, hip_half, color)
	DrawKit.disc(canvas, chest, shoulder_half, color)
	_draw_capsule(canvas, chest, head, _rig["neck_width"] + extra, color)
	DrawKit.disc(canvas, head, _rig["head_radius"] + extra * 0.5, color)


func _draw_capsule(canvas: CanvasItem, from: Vector2, to: Vector2, width: float, color: Color) -> void:
	DrawKit.capsule(canvas, from, to, width, color)


func _draw_accent(canvas: CanvasItem) -> void:
	var accent := fighter.data.accent_color
	var head: Vector2 = joints["head"]
	canvas.draw_line(head + Vector2(3, -2), head + Vector2(11, -2), accent, 2.5)
	var chest: Vector2 = joints["chest"]
	var hips: Vector2 = joints["hips"]
	var center := chest.lerp(hips, 0.3)
	DrawKit.diamond(canvas, center, 5.0, 7.0, accent)


func _draw_charge(canvas: CanvasItem) -> void:
	var move := fighter.current_move
	if move == null or fighter.charge_frames <= 0 or not joints.has(move.charge_joint):
		return
	var ratio := fighter.charge_ratio()
	var center: Vector2 = joints[move.charge_joint]
	var power := fighter.data.power_color
	var pulse := 1.0 + 0.2 * sin(_clock * 0.9)
	DrawKit.glow_circle(canvas, center, (CHARGE_BASE_RADIUS + CHARGE_EXTRA_RADIUS * ratio) * pulse, Color(power, 0.75))
	for index in CHARGE_SPARK_COUNT:
		var angle := _clock * 0.21 + TAU * index / CHARGE_SPARK_COUNT
		var distance := (46.0 - float((_clock * 3 + index * 9) % 36)) * (0.6 + ratio)
		DrawKit.star(canvas, center + Vector2(cos(angle), sin(angle)) * distance, 3.0 + 4.0 * ratio, Color(1, 1, 1, 0.8), angle)
	if ratio >= 1.0:
		DrawKit.ring(canvas, center, 34.0 * pulse, Color(1, 1, 1, 0.7), 2.5)


func _draw_aura(canvas: CanvasItem, color: Color, strength: float) -> void:
	var flicker := 0.75 + 0.25 * sin(_clock * 0.9)
	for joint in AURA_JOINTS:
		DrawKit.soft_disc(canvas, joints[joint], 34.0 * flicker, Color(color, 0.32 * strength))
	var chest: Vector2 = joints["chest"]
	for index in AURA_FLAMES:
		var phase := fmod(_clock * 0.035 + float(index) / AURA_FLAMES, 1.0)
		var sway := sin(_clock * 0.25 + index * 1.9) * 26.0
		var center := chest + Vector2(sway + (index - AURA_FLAMES * 0.5) * 9.0, 70.0 - phase * 190.0)
		var size := (1.0 - phase) * 16.0
		DrawKit.diamond(canvas, center, size * 0.55, size * 1.4, Color(color, 0.6 * strength * (1.0 - phase)))
		DrawKit.diamond(canvas, center, size * 0.25, size * 0.8, Color(1.0, 0.9, 0.6, 0.5 * strength * (1.0 - phase)))


func _draw_wings(canvas: CanvasItem, color: Color, extra: float, is_glow: bool) -> void:
	var root: Vector2 = joints["chest"] + Vector2(-8, 4)
	var flap := sin(_clock * 0.16) * 0.14
	for wing in 2:
		var spread := 1.0 if wing == 0 else 0.82
		var paint := color if wing == 0 or is_glow else color.darkened(0.25)
		for feather in WING_FEATHERS:
			var t := float(feather) / (WING_FEATHERS - 1)
			var angle := lerpf(-1.75, -3.25, t) + flap * (1.0 + t) + wing * 0.18
			var length := lerpf(150.0, 92.0, t) * spread
			var direction := Vector2(cos(angle), sin(angle))
			var normal := Vector2(-direction.y, direction.x)
			var half := 13.0 + extra * 0.5
			var tip := root + direction * (length + extra)
			DrawKit.quad(canvas, root + normal * half, root + direction * length * 0.55 + normal * (half + 4.0), tip, root - normal * half, paint)
