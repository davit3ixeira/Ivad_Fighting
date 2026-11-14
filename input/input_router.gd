extends Node

signal device_connected(device: int)
signal device_disconnected(device: int)

const SLOT_P1 := 0
const SLOT_P2 := 1
const SLOT_COUNT := 2

const DEVICE_NONE := -1
const DEVICE_KEYBOARD_P1 := -2
const DEVICE_KEYBOARD_P2 := -3

const JOIN_DUPLICATE_WINDOW_FRAMES := 10
const MIRROR_CONFIRMATIONS := 3

var deadzone: float = ButtonMap.DEFAULT_DEADZONE
var prefer_digital_dpad: bool = ButtonMap.PREFER_DIGITAL_DPAD

var slot_devices: Array[int] = [DEVICE_NONE, DEVICE_NONE]

var _previous_by_device: Dictionary = {}
var _frame: int = 0
var _recent_presses: Dictionary = {}
var _coincidences: Dictionary = {}
var _mirror_devices: Dictionary = {}
var _pending_join: int = DEVICE_NONE
var _pending_frame: int = 0


func _ready() -> void:
	process_physics_priority = -100
	Input.joy_connection_changed.connect(_on_joy_connection_changed)


func _physics_process(_delta: float) -> void:
	_frame += 1


func _on_joy_connection_changed(device: int, connected: bool) -> void:
	if connected:
		device_connected.emit(device)
		return
	_previous_by_device.erase(device)
	_recent_presses.erase(device)
	_coincidences.erase(device)
	_mirror_devices.erase(device)
	if _pending_join == device:
		_pending_join = DEVICE_NONE
	for slot in SLOT_COUNT:
		if slot_devices[slot] == device:
			slot_devices[slot] = DEVICE_NONE
	device_disconnected.emit(device)


func all_devices() -> Array[int]:
	var devices: Array[int] = []
	for device in Input.get_connected_joypads():
		devices.append(device)
	devices.append(DEVICE_KEYBOARD_P1)
	devices.append(DEVICE_KEYBOARD_P2)
	return devices


func device_label(device: int) -> String:
	match device:
		DEVICE_NONE:
			return "Nenhum"
		DEVICE_KEYBOARD_P1:
			return "Teclado (WASD)"
		DEVICE_KEYBOARD_P2:
			return "Teclado (Setas)"
		_:
			return "%s [id %d]" % [Input.get_joy_name(device), device]


func is_keyboard(device: int) -> bool:
	return device == DEVICE_KEYBOARD_P1 or device == DEVICE_KEYBOARD_P2


func assign_slot(slot: int, device: int) -> void:
	slot_devices[slot] = device


func clear_slot(slot: int) -> void:
	slot_devices[slot] = DEVICE_NONE


func clear_all_slots() -> void:
	for slot in SLOT_COUNT:
		slot_devices[slot] = DEVICE_NONE


func slot_of_device(device: int) -> int:
	for slot in SLOT_COUNT:
		if slot_devices[slot] == device:
			return slot
	return -1


func read_slot(slot: int) -> InputSnapshot:
	return read_device(slot_devices[slot])


func read_device(device: int) -> InputSnapshot:
	var snapshot := InputSnapshot.new()
	match device:
		DEVICE_NONE:
			pass
		DEVICE_KEYBOARD_P1:
			_read_keyboard(ButtonMap.KEYBOARD_P1, snapshot)
		DEVICE_KEYBOARD_P2:
			_read_keyboard(ButtonMap.KEYBOARD_P2, snapshot)
		_:
			_read_joypad(device, snapshot)
	return snapshot


func _read_keyboard(map: Dictionary, snapshot: InputSnapshot) -> void:
	snapshot.dir_x = _axis_from_pair(Input.is_physical_key_pressed(map["left"]), Input.is_physical_key_pressed(map["right"]))
	snapshot.dir_y = _axis_from_pair(Input.is_physical_key_pressed(map["up"]), Input.is_physical_key_pressed(map["down"]))
	for button in ButtonMap.Action.values():
		snapshot.set_pressed(button, Input.is_physical_key_pressed(map[button]))


func _read_joypad(device: int, snapshot: InputSnapshot) -> void:
	var dpad_x := _axis_from_pair(Input.is_joy_button_pressed(device, ButtonMap.JOYPAD_DPAD["left"]), Input.is_joy_button_pressed(device, ButtonMap.JOYPAD_DPAD["right"]))
	var dpad_y := _axis_from_pair(Input.is_joy_button_pressed(device, ButtonMap.JOYPAD_DPAD["up"]), Input.is_joy_button_pressed(device, ButtonMap.JOYPAD_DPAD["down"]))
	var stick_x := _digitize(Input.get_joy_axis(device, ButtonMap.JOYPAD_STICK_X))
	var stick_y := _digitize(Input.get_joy_axis(device, ButtonMap.JOYPAD_STICK_Y))
	if prefer_digital_dpad and (dpad_x != 0 or dpad_y != 0):
		snapshot.dir_x = dpad_x
		snapshot.dir_y = dpad_y
	elif stick_x != 0 or stick_y != 0:
		snapshot.dir_x = stick_x
		snapshot.dir_y = stick_y
	else:
		snapshot.dir_x = dpad_x
		snapshot.dir_y = dpad_y
	for button in ButtonMap.Action.values():
		snapshot.set_pressed(button, Input.is_joy_button_pressed(device, ButtonMap.JOYPAD[button]))


func _axis_from_pair(negative: bool, positive: bool) -> int:
	if negative == positive:
		return 0
	return 1 if positive else -1


func _digitize(value: float) -> int:
	if value > deadzone:
		return 1
	if value < -deadzone:
		return -1
	return 0


func poll_join_press() -> int:
	for device in all_devices():
		var current := read_device(device)
		var previous: InputSnapshot = _previous_by_device.get(device, InputSnapshot.new())
		_previous_by_device[device] = current
		if (current.buttons & ~previous.buttons) == 0:
			continue
		var suspected := _register_press(device, current)
		if suspected or slot_of_device(device) != -1 or _mirror_devices.has(device):
			continue
		if _pending_join == DEVICE_NONE:
			_pending_join = device
			_pending_frame = _frame
	return _resolve_pending_join()


func _register_press(device: int, current: InputSnapshot) -> bool:
	var suspect := DEVICE_NONE
	if not is_keyboard(device):
		for other in _recent_presses:
			if other == device or is_keyboard(other):
				continue
			var press: Dictionary = _recent_presses[other]
			if _frame - int(press["frame"]) > JOIN_DUPLICATE_WINDOW_FRAMES or not current.equals(press["snapshot"]):
				continue
			suspect = device
			if slot_of_device(device) != -1 and slot_of_device(other) == -1:
				suspect = other
			break
	_recent_presses[device] = {"frame": _frame, "snapshot": current.duplicate_snapshot()}
	if suspect == DEVICE_NONE:
		_coincidences[device] = 0
		return false
	_coincidences[suspect] = int(_coincidences.get(suspect, 0)) + 1
	if _coincidences[suspect] >= MIRROR_CONFIRMATIONS:
		_mirror_devices[suspect] = true
	return suspect == device


func _resolve_pending_join() -> int:
	if _pending_join == DEVICE_NONE:
		return DEVICE_NONE
	var device := _pending_join
	if _mirror_devices.has(device) or int(_coincidences.get(device, 0)) > 0 or slot_of_device(device) != -1:
		_pending_join = DEVICE_NONE
		return DEVICE_NONE
	var delay := 0 if is_keyboard(device) else JOIN_DUPLICATE_WINDOW_FRAMES
	if _frame - _pending_frame < delay:
		return DEVICE_NONE
	_pending_join = DEVICE_NONE
	return device


func is_mirror(device: int) -> bool:
	return _mirror_devices.has(device)


func reset_join_tracking() -> void:
	_previous_by_device.clear()
	_recent_presses.clear()
	_coincidences.clear()
	_mirror_devices.clear()
	_pending_join = DEVICE_NONE
