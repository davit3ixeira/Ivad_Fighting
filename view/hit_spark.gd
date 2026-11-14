class_name HitSpark
extends Node2D

const LIFETIME_FRAMES := 10
const RAY_COUNT_HIT := 8
const RAY_COUNT_BLOCK := 4

var _color: Color = Color.WHITE
var _strength: float = 1.0
var _blocked: bool = false
var _frame: int = 0
var _angles: PackedFloat32Array = PackedFloat32Array()


func setup(point: Vector2, color: Color, strength: float, blocked: bool) -> void:
	position = point
	_color = color
	_strength = strength
	_blocked = blocked
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = additive
	var rng := RandomNumberGenerator.new()
	rng.seed = int(absf(point.x) * 13.0 + absf(point.y) * 7.0) + 1
	var count := RAY_COUNT_BLOCK if blocked else RAY_COUNT_HIT
	for index in count:
		_angles.append(TAU * float(index) / count + rng.randf_range(-0.3, 0.3))


func _physics_process(_delta: float) -> void:
	_frame += 1
	if _frame >= LIFETIME_FRAMES:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var t := float(_frame) / LIFETIME_FRAMES
	var fade := 1.0 - t
	var color := Color(_color, fade)
	var inner := 8.0 + t * 46.0 * _strength
	var length := fade * 34.0 * _strength
	for angle in _angles:
		var dir := Vector2(cos(angle), sin(angle))
		draw_line(dir * inner, dir * (inner + length), color, 3.5 * fade + 1.0)
	if _blocked:
		draw_arc(Vector2.ZERO, 14.0 + t * 26.0, 0.0, TAU, 20, color, 2.5)
	elif t < 0.4:
		draw_circle(Vector2.ZERO, (18.0 - t * 30.0) * _strength, Color(1, 1, 1, fade * 0.8))
