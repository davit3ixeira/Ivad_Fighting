class_name FightCamera
extends Camera2D

const VIEW_WIDTH := 1280.0
const VIEW_HEIGHT := 720.0
const MIN_ZOOM := 0.68
const MAX_ZOOM := 1.0
const HORIZONTAL_MARGIN := 520.0
const FLOOR_SCREEN_FRACTION := 0.86
const POSITION_SMOOTHING := 0.14
const ZOOM_SMOOTHING := 0.08
const SHAKE_DECAY := 0.86

var shake_amount: float = 0.0
var _target_position: Vector2 = Vector2.ZERO
var _target_zoom: float = 1.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 1337
	zoom = Vector2.ONE
	position = Vector2(0, -VIEW_HEIGHT * (FLOOR_SCREEN_FRACTION - 0.5))


func snap_to(fighters: Array[Fighter]) -> void:
	_compute_targets(fighters)
	position = _target_position
	zoom = Vector2(_target_zoom, _target_zoom)


func follow(fighters: Array[Fighter]) -> void:
	_compute_targets(fighters)
	var z := lerpf(zoom.x, _target_zoom, ZOOM_SMOOTHING)
	zoom = Vector2(z, z)
	position = position.lerp(_target_position, POSITION_SMOOTHING)
	position = _clamp_to_stage(position, z)
	_apply_shake()


func add_shake(amount: float) -> void:
	shake_amount = minf(shake_amount + amount, GlobalTuning.SHAKE_MAX)


func _apply_shake() -> void:
	if shake_amount < 0.3:
		shake_amount = 0.0
		offset = Vector2.ZERO
		return
	offset = Vector2(_rng.randf_range(-shake_amount, shake_amount), _rng.randf_range(-shake_amount, shake_amount) * 0.6)
	shake_amount *= SHAKE_DECAY


func _compute_targets(fighters: Array[Fighter]) -> void:
	var a := fighters[0].position
	var b := fighters[1].position
	var distance := absf(a.x - b.x)
	var needed_width := distance + HORIZONTAL_MARGIN
	var z := clampf(VIEW_WIDTH / needed_width, MIN_ZOOM, MAX_ZOOM)
	_target_zoom = z
	var center_x := (a.x + b.x) * 0.5
	var highest := minf(a.y, b.y)
	var floor_offset := VIEW_HEIGHT * (FLOOR_SCREEN_FRACTION - 0.5) / z
	var center_y := GlobalTuning.FLOOR_Y - floor_offset
	if highest < -220.0:
		center_y += (highest + 220.0) * 0.45
	_target_position = _clamp_to_stage(Vector2(center_x, center_y), z)


func _clamp_to_stage(point: Vector2, z: float) -> Vector2:
	var half_width := VIEW_WIDTH * 0.5 / z
	var min_x := -GlobalTuning.STAGE_HALF_WIDTH + half_width
	var max_x := GlobalTuning.STAGE_HALF_WIDTH - half_width
	if min_x > max_x:
		point.x = 0.0
	else:
		point.x = clampf(point.x, min_x, max_x)
	var floor_offset := VIEW_HEIGHT * (FLOOR_SCREEN_FRACTION - 0.5) / z
	point.y = minf(point.y, GlobalTuning.FLOOR_Y - floor_offset)
	return point
