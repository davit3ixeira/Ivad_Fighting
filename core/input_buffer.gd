class_name InputBuffer
extends RefCounted

var frame: int = 0
var raw_x: int = 0
var raw_y: int = 0
var forward: bool = false
var back: bool = false
var up: bool = false
var down: bool = false
var held: int = 0
var dash_request: int = 0

var _press_frames: Dictionary = {}
var _consumed: Dictionary = {}
var _last_tap_dir: int = 0
var _last_tap_frame: int = -1000
var _previous_rel_x: int = 0
var _dash_request_frame: int = -1000


func update(snapshot: InputSnapshot, facing: int) -> void:
	frame += 1
	raw_x = snapshot.dir_x
	raw_y = snapshot.dir_y
	var rel_x := snapshot.dir_x * facing
	forward = rel_x > 0
	back = rel_x < 0
	up = snapshot.dir_y < 0
	down = snapshot.dir_y > 0
	var new_presses := snapshot.buttons & ~held
	held = snapshot.buttons
	for action in ButtonMap.Action.values():
		if new_presses & (1 << action):
			_press_frames[action] = frame
			_consumed.erase(action)
	_update_double_tap(rel_x)
	if dash_request != 0 and frame - _dash_request_frame > GlobalTuning.INPUT_BUFFER_FRAMES:
		dash_request = 0


func _update_double_tap(rel_x: int) -> void:
	if rel_x != 0 and rel_x != _previous_rel_x:
		if _last_tap_dir == rel_x and frame - _last_tap_frame <= GlobalTuning.DOUBLE_TAP_WINDOW_FRAMES:
			dash_request = rel_x
			_dash_request_frame = frame
			_last_tap_dir = 0
		else:
			_last_tap_dir = rel_x
			_last_tap_frame = frame
	_previous_rel_x = rel_x


func is_held(action: ButtonMap.Action) -> bool:
	return (held & (1 << action)) != 0


func pressed_buffered(action: ButtonMap.Action, window: int = GlobalTuning.INPUT_BUFFER_FRAMES) -> bool:
	if not _press_frames.has(action) or _consumed.has(action):
		return false
	return frame - _press_frames[action] <= window


func just_pressed(action: ButtonMap.Action) -> bool:
	return _press_frames.get(action, -1000) == frame


func consume(action: ButtonMap.Action) -> void:
	_consumed[action] = true


func consume_dash() -> void:
	dash_request = 0


func clear() -> void:
	_press_frames.clear()
	_consumed.clear()
	dash_request = 0
	held = 0
