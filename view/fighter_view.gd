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
var _halo: RigLayer
var _body: RigLayer


func setup(target: Fighter, player_color: Color) -> void:
	outline_color = player_color
	_halo = RigLayer.new()
	_halo.view = self
	_halo.is_halo = true
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_halo.material = additive
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
	sync()


func sync() -> void:
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
	scale.x = fighter.facing
	var stunned := fighter.state == Fighter.State.HITSTUN or fighter.state == Fighter.State.AIR_HITSTUN or fighter.state == Fighter.State.KO
	if fighter.hitstop > 0 and stunned:
		position.x += (float(fighter.hitstop % 2) * 2.0 - 1.0) * HITSTOP_JITTER
		_flash = HIT_FLASH_STRENGTH
	else:
		_flash = maxf(_flash - HIT_FLASH_DECAY, 0.0)
	_halo.queue_redraw()
	_body.queue_redraw()


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
	for part in Part.values():
		_draw_part(canvas, part, wide, HALO_WIDE_EXTRA)
		_draw_part(canvas, part, tight, HALO_TIGHT_EXTRA)


func draw_body(canvas: CanvasItem) -> void:
	if joints.is_empty():
		return
	var body := BODY_COLOR.lerp(outline_color, _flash)
	var body_far := BODY_FAR_COLOR.lerp(outline_color, _flash)
	_draw_part(canvas, Part.FAR_LIMBS, outline_color, OUTLINE_EXTRA_WIDTH)
	_draw_part(canvas, Part.FAR_LIMBS, body_far, 0.0)
	_draw_part(canvas, Part.TORSO, outline_color, OUTLINE_EXTRA_WIDTH)
	_draw_part(canvas, Part.TORSO, body, 0.0)
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
	canvas.draw_circle(joints["hand_" + side], _rig["hand_radius"] + extra * 0.5, color)


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
	var quad := PackedVector2Array([
		hips - normal * hip_half, chest - normal * shoulder_half,
		chest + normal * shoulder_half, hips + normal * hip_half,
	])
	canvas.draw_colored_polygon(quad, color)
	canvas.draw_circle(hips, hip_half, color)
	canvas.draw_circle(chest, shoulder_half, color)
	_draw_capsule(canvas, chest, head, _rig["neck_width"] + extra, color)
	canvas.draw_circle(head, _rig["head_radius"] + extra * 0.5, color)


func _draw_capsule(canvas: CanvasItem, from: Vector2, to: Vector2, width: float, color: Color) -> void:
	canvas.draw_line(from, to, color, width)
	canvas.draw_circle(from, width * 0.5, color)
	canvas.draw_circle(to, width * 0.5, color)


func _draw_accent(canvas: CanvasItem) -> void:
	var accent := fighter.data.accent_color
	var head: Vector2 = joints["head"]
	canvas.draw_line(head + Vector2(3, -2), head + Vector2(11, -2), accent, 2.5)
	var chest: Vector2 = joints["chest"]
	var hips: Vector2 = joints["hips"]
	var center := chest.lerp(hips, 0.3)
	var diamond := PackedVector2Array([center + Vector2(0, -7), center + Vector2(5, 0), center + Vector2(0, 7), center + Vector2(-5, 0)])
	canvas.draw_colored_polygon(diamond, accent)
