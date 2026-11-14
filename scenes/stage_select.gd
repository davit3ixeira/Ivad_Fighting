extends Control

const CARD_SIZE := Vector2(340, 200)
const CARD_GAP := 36.0
const CARD_TOP := 200.0
const SELECTED_GROW := 8.0

var _menu := MenuInput.new()
var _clock: int = 0
var _index: int = 0


func _ready() -> void:
	UiKit.fill_screen(self)
	_index = clampi(GameFlow.stage, 0, StageList.count() - 1)


func _physics_process(_delta: float) -> void:
	_clock += 1
	_menu.update()
	queue_redraw()
	if GameFlow.is_transitioning():
		return
	_menu.join_new_player()
	var step := _menu.any_nav().x
	if step != 0:
		_index = wrapi(_index + step, 0, StageList.count())
		AudioManager.play_sfx("menu_move")
	if _menu.any_confirm():
		AudioManager.play_sfx("menu_confirm")
		GameFlow.stage = _index
		GameFlow.go_to(GameFlow.FIGHT)
	elif _menu.any_back():
		AudioManager.play_sfx("menu_back")
		GameFlow.go_to(GameFlow.CHARACTER_SELECT)


func _card_rect(index: int) -> Rect2:
	var total := StageList.count() * CARD_SIZE.x + (StageList.count() - 1) * CARD_GAP
	var left := (UiKit.SCREEN_SIZE.x - total) * 0.5
	return Rect2(Vector2(left + index * (CARD_SIZE.x + CARD_GAP), CARD_TOP), CARD_SIZE)


func _draw() -> void:
	MenuBackdrop.draw(self, _clock)
	UiKit.centered(self, 116, "ESCOLHA O MAPA", 46, UiKit.TEXT_COLOR)
	UiKit.centered(self, 154, "Qualquer jogador pode escolher", 18, UiKit.DIM_TEXT_COLOR, false)
	for index in StageList.count():
		_draw_card(index)
	var stage := StageList.entry(_index)
	UiKit.centered(self, 520, stage["description"], 20, UiKit.DIM_TEXT_COLOR, false)
	_draw_matchup()
	UiKit.hint(self)


func _draw_card(index: int) -> void:
	var selected := index == _index
	var rect := _card_rect(index)
	if selected:
		rect = rect.grow(SELECTED_GROW)
	var stage := StageList.entry(index)
	var line: Color = stage["line"]
	StagePreview.draw(self, rect, index, _clock)
	if selected:
		draw_rect(rect.grow(3.0), Color(line, 0.3), false, 8.0)
		draw_rect(rect, Color.WHITE, false, 3.0)
	else:
		draw_rect(rect, Color(0, 0, 0.02, 0.45))
		draw_rect(rect, Color(line, 0.5), false, 2.0)
	var name_color := UiKit.TEXT_COLOR if selected else UiKit.DIM_TEXT_COLOR
	UiKit.text(self, Vector2(rect.position.x, rect.end.y + 38.0), stage["name"], 26 if selected else 22, name_color, rect.size.x, HORIZONTAL_ALIGNMENT_CENTER, selected)


func _draw_matchup() -> void:
	var center := UiKit.SCREEN_SIZE.x * 0.5
	var p1_name := Roster.display_name(GameFlow.characters[0])
	var p2_name := Roster.display_name(GameFlow.characters[1])
	UiKit.text(self, Vector2(0, 600), p1_name, 28, UiKit.P1_COLOR, center - 40.0, HORIZONTAL_ALIGNMENT_RIGHT)
	UiKit.text(self, Vector2(center - 40.0, 600), "vs", 24, UiKit.TEXT_COLOR, 80.0, HORIZONTAL_ALIGNMENT_CENTER, false)
	UiKit.text(self, Vector2(center + 40.0, 600), p2_name, 28, UiKit.P2_COLOR, center - 40.0, HORIZONTAL_ALIGNMENT_LEFT)
