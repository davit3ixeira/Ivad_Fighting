class_name HairChain
extends RefCounted

const TELEPORT_DISTANCE := 160.0
const CONSTRAINT_PASSES := 2
const FLOOR_CLEARANCE := 3.0
const CAP_OFFSET := Vector2(-2.5, -2.0)
const FACE_OFFSET := Vector2(4.5, 3.5)
const WHIP_LEAD_FRAMES := 5
const WHIP_REST_RATIO := 0.6
const WHIP_CURL := 26.0

var anchor: String = "head"
var offset: Vector2 = Vector2(-8, -4)
var segments: int = 7
var segment_length: float = 13.0
var root_width: float = 15.0
var tip_width: float = 4.0
var gravity: float = 0.55
var damping: float = 0.87
var drift: float = 0.3
var cap: bool = false
var fill_color: Color = Color(0.4, 0.3, 0.1)
var highlight_color: Color = Color(1.0, 0.85, 0.4)
var whip_moves: Dictionary = {}

var _points: PackedVector2Array = PackedVector2Array()
var _previous: PackedVector2Array = PackedVector2Array()


func configure(config: Dictionary) -> void:
	for field in config:
		if field != "type":
			set(field, config[field])


func update(view: FighterView) -> void:
	var root := view.joint_world(anchor, offset)
	var size := absf(view.scale.y)
	if _points.is_empty() or root.distance_to(_points[0]) > TELEPORT_DISTANCE * size:
		_reset(root, size)
	var progress := _whip_progress(view.fighter)
	if progress > 0.0:
		_apply_whip(view, root, size, progress)
		return
	_points[0] = root
	var side := signf(view.scale.x)
	for index in range(1, _points.size()):
		var velocity := (_points[index] - _previous[index]) * damping
		_previous[index] = _points[index]
		_points[index] += velocity + Vector2(-side * drift, gravity)
	var link := segment_length * size
	for pass_index in CONSTRAINT_PASSES:
		for index in range(1, _points.size()):
			var delta := _points[index] - _points[index - 1]
			if delta.length() < 0.01:
				delta = Vector2.DOWN
			_points[index] = _points[index - 1] + delta.normalized() * link
			_points[index].y = minf(_points[index].y, GlobalTuning.FLOOR_Y - FLOOR_CLEARANCE)


func _whip_progress(fighter: Fighter) -> float:
	if whip_moves.is_empty() or fighter.state != Fighter.State.ATTACK or fighter.current_move == null:
		return 0.0
	var move := fighter.current_move
	if not whip_moves.has(move.id):
		return 0.0
	var frame := fighter.state_frame
	var lead_start := maxi(move.startup - WHIP_LEAD_FRAMES, 0)
	var strike := move.startup + 1
	var active_end := move.startup + move.active
	if frame < lead_start:
		return 0.0
	if frame < strike:
		return float(frame - lead_start) / float(maxi(strike - lead_start, 1))
	if frame <= active_end:
		return 1.0
	return clampf(1.0 - float(frame - active_end) / float(maxi(move.recovery, 1)), 0.0, 1.0)


func _apply_whip(view: FighterView, root: Vector2, size: float, progress: float) -> void:
	var config: Dictionary = whip_moves[view.fighter.current_move.id]
	var rest_length := segments * segment_length * WHIP_REST_RATIO
	var length := lerpf(rest_length, float(config["reach"]), progress) * size
	var direction := PoseResolver.direction(config["angle"])
	direction.x *= signf(view.scale.x)
	var normal := Vector2(-direction.y, direction.x)
	for index in _points.size():
		var t := float(index) / segments
		var curl := sin(t * PI) * (1.0 - progress) * WHIP_CURL * size
		var point := root + direction * length * t + normal * curl
		_points[index] = point
		_previous[index] = point


func _reset(root: Vector2, size: float) -> void:
	_points.resize(segments + 1)
	_previous.resize(segments + 1)
	for index in segments + 1:
		_points[index] = root + Vector2(0, segment_length * size * index)
		_previous[index] = _points[index]


func draw(canvas: CanvasItem, view: FighterView, color: Color, extra: float, is_fill: bool) -> void:
	if _points.is_empty():
		return
	var local := PackedVector2Array()
	for point in _points:
		var relative := point - view.position
		local.append(Vector2(relative.x / view.scale.x, relative.y / view.scale.y))
	var paint := view.tinted(fill_color) if is_fill else color
	var last := local.size() - 1
	for index in last:
		var width := lerpf(root_width, tip_width, float(index) / last) + extra
		canvas.draw_line(local[index], local[index + 1], paint, width)
		DrawKit.disc(canvas, local[index + 1], width * 0.5, paint)
	DrawKit.disc(canvas, local[0], (root_width + extra) * 0.5, paint)
	if is_fill:
		var shine := Color(highlight_color, 0.85)
		for index in last:
			canvas.draw_line(local[index], local[index + 1], shine, 1.8)


func draw_front(canvas: CanvasItem, view: FighterView, color: Color, extra: float, is_fill: bool) -> void:
	if not cap:
		return
	var paint := view.tinted(fill_color) if is_fill else color
	var head: Vector2 = view.joints["head"]
	var head_radius := view.rig_value("head_radius")
	DrawKit.disc(canvas, head + CAP_OFFSET, head_radius + 1.5 + extra * 0.5, paint)
	if is_fill:
		DrawKit.disc(canvas, head + FACE_OFFSET, head_radius - 3.0, view.tinted(FighterView.BODY_COLOR))
