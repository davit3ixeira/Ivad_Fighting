extends Control

const ITEMS: Array[String] = ["Jogar", "Sair"]
const ITEM_TOP := 350.0
const ITEM_SIZE := Vector2(360, 58)
const ITEM_GAP := 76.0

var _menu := MenuInput.new()
var _clock: int = 0
var _index: int = 0


func _ready() -> void:
	UiKit.fill_screen(self)


func _physics_process(_delta: float) -> void:
	_clock += 1
	_menu.update()
	queue_redraw()
	if GameFlow.is_transitioning():
		return
	if _menu.join_new_player() != -1:
		AudioManager.play_sfx("menu_join")
	var step := _menu.any_nav().y
	if step != 0:
		_index = wrapi(_index + step, 0, ITEMS.size())
		AudioManager.play_sfx("menu_move")
	if _menu.any_confirm():
		_activate()
	elif _menu.any_back():
		AudioManager.play_sfx("menu_back")
		GameFlow.go_to(GameFlow.PRESS_START)


func _activate() -> void:
	AudioManager.play_sfx("menu_confirm")
	match _index:
		0:
			GameFlow.go_to(GameFlow.CHARACTER_SELECT)
		_:
			GameFlow.quit_game()


func _draw() -> void:
	MenuBackdrop.draw(self, _clock)
	UiKit.centered(self, 210, "IVAD FIGHTING", 80, UiKit.TEXT_COLOR)
	for index in ITEMS.size():
		var rect := Rect2(Vector2((UiKit.SCREEN_SIZE.x - ITEM_SIZE.x) * 0.5, ITEM_TOP + index * ITEM_GAP), ITEM_SIZE)
		var selected := index == _index
		if selected:
			UiKit.panel(self, rect.grow(4.0), Color.WHITE, Color(UiKit.ACCENT_COLOR, 0.28), 3.0)
		else:
			UiKit.panel(self, rect, Color(UiKit.ACCENT_COLOR, 0.4))
		UiKit.text(self, Vector2(rect.position.x, rect.position.y + 39), ITEMS[index], 30, UiKit.TEXT_COLOR if selected else UiKit.DIM_TEXT_COLOR, rect.size.x, HORIZONTAL_ALIGNMENT_CENTER, selected)
	for slot in 2:
		var label := InputRouter.device_label(InputRouter.slot_devices[slot]) if _menu.is_joined(slot) else "aperte um botão para entrar"
		var align := HORIZONTAL_ALIGNMENT_LEFT if slot == 0 else HORIZONTAL_ALIGNMENT_RIGHT
		UiKit.text(self, Vector2(40, 650), "P%d: %s" % [slot + 1, label], 16, UiKit.player_color(slot), 1200, align, false)
	UiKit.hint(self)
