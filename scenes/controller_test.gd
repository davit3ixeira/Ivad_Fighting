extends Control

const MAX_EVENT_LINES := 10
const RAW_BUTTON_COUNT := 21

var _event_lines: Array[String] = []

@onready var _devices_label: Label = $Margin/Columns/Devices
@onready var _events_label: Label = $Margin/Columns/Events


func _ready() -> void:
	InputRouter.device_connected.connect(_on_device_changed.bind(true))
	InputRouter.device_disconnected.connect(_on_device_changed.bind(false))


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == ButtonMap.KEY_FULLSCREEN:
			_toggle_fullscreen()
		_push_event("Tecla fisica %s (device %d)" % [OS.get_keycode_string(event.physical_keycode), event.device])
	elif event is InputEventJoypadButton and event.pressed:
		_push_event("Controle id %d: botao %d" % [event.device, event.button_index])
	elif event is InputEventJoypadMotion and absf(event.axis_value) > 0.9:
		_push_event("Controle id %d: eixo %d = %.2f" % [event.device, event.axis, event.axis_value])


func _physics_process(_delta: float) -> void:
	var joined := InputRouter.poll_join_press()
	if joined != InputRouter.DEVICE_NONE and InputRouter.slot_of_device(joined) == -1:
		for slot in InputRouter.SLOT_COUNT:
			if InputRouter.slot_devices[slot] == InputRouter.DEVICE_NONE:
				InputRouter.assign_slot(slot, joined)
				_push_event("P%d assumido por %s" % [slot + 1, InputRouter.device_label(joined)])
				break
	_devices_label.text = _build_devices_text()
	_events_label.text = "Ultimos eventos brutos:\n" + "\n".join(_event_lines)


func _build_devices_text() -> String:
	var lines: Array[String] = []
	lines.append("TESTE DE CONTROLES  (F11 tela cheia, F5 limpa P1/P2)")
	lines.append("Aperte qualquer botao: o primeiro vira P1, o segundo vira P2.")
	lines.append("")
	for slot in InputRouter.SLOT_COUNT:
		var device: int = InputRouter.slot_devices[slot]
		var snapshot := InputRouter.read_slot(slot)
		lines.append("P%d = %s   ->  %s" % [slot + 1, InputRouter.device_label(device), snapshot.describe()])
	lines.append("")
	lines.append("Controles conectados: %d" % Input.get_connected_joypads().size())
	for device in Input.get_connected_joypads():
		var snapshot := InputRouter.read_device(device)
		lines.append("")
		lines.append("[id %d] %s" % [device, Input.get_joy_name(device)])
		lines.append("   GUID: %s" % Input.get_joy_guid(device))
		lines.append("   Leitura: %s" % snapshot.describe())
		lines.append("   Analogico esq: x=%.2f y=%.2f   zona morta=%.2f" % [
			Input.get_joy_axis(device, ButtonMap.JOYPAD_STICK_X),
			Input.get_joy_axis(device, ButtonMap.JOYPAD_STICK_Y),
			InputRouter.deadzone,
		])
		lines.append("   Botoes brutos apertados: %s" % _raw_pressed_buttons(device))
	lines.append("")
	lines.append("Teclado WASD: %s" % InputRouter.read_device(InputRouter.DEVICE_KEYBOARD_P1).describe())
	lines.append("Teclado Setas: %s" % InputRouter.read_device(InputRouter.DEVICE_KEYBOARD_P2).describe())
	lines.append("")
	lines.append("FPS: %d" % Engine.get_frames_per_second())
	return "\n".join(lines)


func _raw_pressed_buttons(device: int) -> String:
	var pressed: Array[String] = []
	for index in RAW_BUTTON_COUNT:
		if Input.is_joy_button_pressed(device, index):
			pressed.append(str(index))
	if pressed.is_empty():
		return "-"
	return ", ".join(pressed)


func _push_event(text: String) -> void:
	_event_lines.push_front(text)
	if _event_lines.size() > MAX_EVENT_LINES:
		_event_lines.resize(MAX_EVENT_LINES)


func _on_device_changed(device: int, connected: bool) -> void:
	_push_event("Controle id %d %s" % [device, "conectado" if connected else "desconectado"])


func _toggle_fullscreen() -> void:
	var window := get_window()
	if window.mode == Window.MODE_FULLSCREEN:
		window.mode = Window.MODE_WINDOWED
	else:
		window.mode = Window.MODE_FULLSCREEN


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F5:
		InputRouter.clear_all_slots()
		InputRouter.reset_join_tracking()
		_push_event("P1 e P2 liberados")
