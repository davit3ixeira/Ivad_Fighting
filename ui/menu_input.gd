class_name MenuInput
extends RefCounted

const REPEAT_DELAY := 18
const REPEAT_INTERVAL := 6
const UNKNOWN_DEVICE := -99

var _previous: Array = [null, null]
var _devices: Array[int] = [UNKNOWN_DEVICE, UNKNOWN_DEVICE]
var _hold: Array[int] = [0, 0]
var _nav: Array[Vector2i] = [Vector2i.ZERO, Vector2i.ZERO]
var _pressed: Array[int] = [0, 0]
var _confirm_mask: int = 0
var _back_mask: int = 0
var _pause_mask: int = 0


func _init() -> void:
	for action in ButtonMap.MENU_CONFIRM:
		_confirm_mask |= 1 << action
	for action in ButtonMap.MENU_BACK:
		_back_mask |= 1 << action
	_pause_mask = 1 << ButtonMap.Action.PAUSE


func update() -> void:
	for slot in InputRouter.SLOT_COUNT:
		var device: int = InputRouter.slot_devices[slot]
		var current: InputSnapshot = InputRouter.read_slot(slot)
		var previous: InputSnapshot = _previous[slot]
		_nav[slot] = Vector2i.ZERO
		_pressed[slot] = 0
		if previous == null or _devices[slot] != device:
			_previous[slot] = current
			_devices[slot] = device
			_hold[slot] = 0
			continue
		_pressed[slot] = current.buttons & ~previous.buttons
		var direction := Vector2i(current.dir_x, current.dir_y)
		var old := Vector2i(previous.dir_x, previous.dir_y)
		if direction == Vector2i.ZERO:
			_hold[slot] = 0
		elif direction != old:
			_hold[slot] = 0
			_nav[slot] = Vector2i(direction.x if direction.x != old.x else 0, direction.y if direction.y != old.y else 0)
		else:
			_hold[slot] += 1
			if _hold[slot] >= REPEAT_DELAY and (_hold[slot] - REPEAT_DELAY) % REPEAT_INTERVAL == 0:
				_nav[slot] = direction
		_previous[slot] = current


func join_new_player() -> int:
	var device := InputRouter.poll_join_press()
	if device == InputRouter.DEVICE_NONE or InputRouter.slot_of_device(device) != -1:
		return -1
	for slot in InputRouter.SLOT_COUNT:
		if InputRouter.slot_devices[slot] == InputRouter.DEVICE_NONE:
			InputRouter.assign_slot(slot, device)
			return slot
	return -1


func is_joined(slot: int) -> bool:
	return InputRouter.slot_devices[slot] != InputRouter.DEVICE_NONE


func nav(slot: int) -> Vector2i:
	return _nav[slot]


func confirm(slot: int) -> bool:
	return (_pressed[slot] & _confirm_mask) != 0


func back(slot: int) -> bool:
	return (_pressed[slot] & _back_mask) != 0


func pause(slot: int) -> bool:
	return (_pressed[slot] & _pause_mask) != 0


func any_nav() -> Vector2i:
	for slot in InputRouter.SLOT_COUNT:
		if _nav[slot] != Vector2i.ZERO:
			return _nav[slot]
	return Vector2i.ZERO


func any_confirm() -> bool:
	return confirm(0) or confirm(1)


func any_back() -> bool:
	return back(0) or back(1)


func any_pause() -> bool:
	return pause(0) or pause(1)
