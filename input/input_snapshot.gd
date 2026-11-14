class_name InputSnapshot
extends RefCounted

var dir_x: int = 0
var dir_y: int = 0
var buttons: int = 0


func is_pressed(button: ButtonMap.Action) -> bool:
	return (buttons & (1 << button)) != 0


func set_pressed(button: ButtonMap.Action, pressed: bool) -> void:
	if pressed:
		buttons |= 1 << button
	else:
		buttons &= ~(1 << button)


func is_neutral() -> bool:
	return dir_x == 0 and dir_y == 0 and buttons == 0


func equals(other: InputSnapshot) -> bool:
	return dir_x == other.dir_x and dir_y == other.dir_y and buttons == other.buttons


func duplicate_snapshot() -> InputSnapshot:
	var copy := InputSnapshot.new()
	copy.dir_x = dir_x
	copy.dir_y = dir_y
	copy.buttons = buttons
	return copy


func describe() -> String:
	var parts: Array[String] = []
	if dir_x < 0:
		parts.append("Esq")
	if dir_x > 0:
		parts.append("Dir")
	if dir_y < 0:
		parts.append("Cima")
	if dir_y > 0:
		parts.append("Baixo")
	for button in ButtonMap.Action.values():
		if is_pressed(button):
			parts.append(ButtonMap.action_name(button))
	if parts.is_empty():
		return "-"
	return ", ".join(parts)
