class_name StageDimmer
extends Node2D

const EXTENT := 3000.0
const FADE_SPEED := 0.08

var _amount: float = 0.0
var _target: float = 0.0
var _hold_frames: int = 0


func dim(strength: float, frames: int) -> void:
	_target = strength
	_hold_frames = frames


func clear() -> void:
	_target = 0.0
	_hold_frames = 0
	_amount = 0.0
	queue_redraw()


func _physics_process(_delta: float) -> void:
	if _hold_frames > 0:
		_hold_frames -= 1
		if _hold_frames == 0:
			_target = 0.0
	if is_equal_approx(_amount, _target):
		return
	_amount = move_toward(_amount, _target, FADE_SPEED)
	queue_redraw()


func _draw() -> void:
	if _amount <= 0.001:
		return
	draw_rect(Rect2(-EXTENT, -EXTENT, EXTENT * 2.0, EXTENT * 2.0), Color(0, 0, 0.02, _amount))
