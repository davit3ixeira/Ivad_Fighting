extends Control

const COLUMNS := 3
const CELL_SIZE := Vector2(176, 112)
const CELL_GAP := 18.0
const GRID_TOP := 190.0
const PREVIEW_FLOOR_Y := 540.0
const PREVIEW_X: Array[float] = [175.0, 1105.0]
const PREVIEW_SCALE := 1.4
const PREVIEW_FACING: Array[int] = [1, -1]
const PREVIEW_TEXT_WIDTH := 320.0
const CONTINUE_DELAY := 40
const UNREADY_OUTLINE := Color(0.4, 0.42, 0.52)
const LONG_NAME_LENGTH := 11

var _menu := MenuInput.new()
var _cursor: Array[int] = [0, 0]
var _locked: Array[bool] = [false, false]
var _clock: int = 0
var _continue_frames: int = 0
var _data_cache: Dictionary = {}
var _preview_roots: Array[Node2D] = []
var _preview_fighters: Array[Fighter] = [null, null]
var _preview_views: Array[FighterView] = [null, null]
var _shown: Array[int] = [-1, -1]
var _anim_frames: Array[int] = [0, 0]


func _ready() -> void:
	UiKit.fill_screen(self)
	for slot in 2:
		_cursor[slot] = clampi(GameFlow.characters[slot], 0, Roster.count() - 1)
		var root := Node2D.new()
		root.position = Vector2(PREVIEW_X[slot], PREVIEW_FLOOR_Y)
		root.scale = Vector2.ONE * PREVIEW_SCALE
		add_child(root)
		_preview_roots.append(root)
	_update_previews()


func _exit_tree() -> void:
	for fighter in _preview_fighters:
		if fighter != null:
			fighter.release()


func _physics_process(_delta: float) -> void:
	_clock += 1
	_menu.update()
	if not GameFlow.is_transitioning():
		if _menu.join_new_player() != -1:
			AudioManager.play_sfx("menu_join")
		for slot in 2:
			_handle_slot(slot)
		_check_continue()
	_update_previews()
	queue_redraw()


func _handle_slot(slot: int) -> void:
	if not _menu.is_joined(slot) or GameFlow.is_transitioning():
		return
	if _locked[slot]:
		if _menu.back(slot):
			_locked[slot] = false
			_anim_frames[slot] = 0
			AudioManager.play_sfx("menu_back")
		return
	var nav := _menu.nav(slot)
	if nav != Vector2i.ZERO:
		_cursor[slot] = _moved(_cursor[slot], nav)
		AudioManager.play_sfx("menu_move")
	if _menu.confirm(slot):
		_locked[slot] = true
		_anim_frames[slot] = 0
		AudioManager.play_sfx("menu_confirm")
	elif _menu.back(slot):
		AudioManager.play_sfx("menu_back")
		GameFlow.go_to(GameFlow.MAIN_MENU)


func _moved(index: int, nav: Vector2i) -> int:
	var rows := ceili(float(Roster.count()) / COLUMNS)
	var column := wrapi(index % COLUMNS + nav.x, 0, COLUMNS)
	var row := wrapi(index / COLUMNS + nav.y, 0, rows)
	return mini(row * COLUMNS + column, Roster.count() - 1)


func _check_continue() -> void:
	if not (_locked[0] and _locked[1]):
		_continue_frames = 0
		return
	_continue_frames += 1
	if _continue_frames >= CONTINUE_DELAY:
		GameFlow.characters.assign(_cursor)
		GameFlow.go_to(GameFlow.STAGE_SELECT)


func _update_previews() -> void:
	for slot in 2:
		_preview_roots[slot].visible = _menu.is_joined(slot)
		if _shown[slot] != _cursor[slot]:
			_show_preview(slot, _cursor[slot])
		var fighter := _preview_fighters[slot]
		_anim_frames[slot] += 1
		var celebrate := _locked[slot] and fighter.data.animations.has("win")
		fighter.anim_name = "win" if celebrate else "idle"
		fighter.anim_frame = _anim_frames[slot]
		_preview_views[slot].sync()


func _show_preview(slot: int, index: int) -> void:
	if _preview_fighters[slot] != null:
		_preview_fighters[slot].release()
	var fighter := Fighter.new()
	fighter.setup(_preview_data(index), slot, 0.0, PREVIEW_FACING[slot])
	_preview_fighters[slot] = fighter
	var outline := UiKit.player_color(slot) if Roster.is_ready(index) else UNREADY_OUTLINE
	if _preview_views[slot] == null:
		var view := FighterView.new()
		_preview_roots[slot].add_child(view)
		view.setup(fighter, outline)
		_preview_views[slot] = view
	else:
		_preview_views[slot].outline_color = outline
		_preview_views[slot].bind(fighter)
	_shown[slot] = index
	_anim_frames[slot] = 0


func _preview_data(index: int) -> CharacterData:
	if not _data_cache.has(index):
		_data_cache[index] = Roster.preview(index)
	return _data_cache[index]


func _cell_rect(index: int) -> Rect2:
	var grid_width := COLUMNS * CELL_SIZE.x + (COLUMNS - 1) * CELL_GAP
	var left := (UiKit.SCREEN_SIZE.x - grid_width) * 0.5
	var column := index % COLUMNS
	var row := index / COLUMNS
	return Rect2(Vector2(left + column * (CELL_SIZE.x + CELL_GAP), GRID_TOP + row * (CELL_SIZE.y + CELL_GAP)), CELL_SIZE)


func _draw() -> void:
	MenuBackdrop.draw(self, _clock)
	UiKit.centered(self, 110, "ESCOLHA SEU LUTADOR", 46, UiKit.TEXT_COLOR)
	for index in Roster.count():
		_draw_cell(index)
	for slot in 2:
		if _menu.is_joined(slot):
			_draw_cursor_frame(slot)
	for slot in 2:
		if _menu.is_joined(slot):
			_draw_cursor(slot)
		_draw_preview_info(slot)
	if _locked[0] and _locked[1]:
		UiKit.centered(self, 520, "PREPARAR!", 40, UiKit.GOLD_COLOR)
	UiKit.hint(self)


func _draw_cell(index: int) -> void:
	var rect := _cell_rect(index)
	var power := Roster.power_color(index)
	var ready := Roster.is_ready(index)
	UiKit.panel(self, rect, Color(power, 0.55 if ready else 0.25))
	draw_rect(Rect2(rect.position, Vector2(rect.size.x, 4)), Color(power, 0.9 if ready else 0.35))
	var name := Roster.display_name(index)
	var font_size := 22 if name.length() <= LONG_NAME_LENGTH else 17
	var name_color := UiKit.TEXT_COLOR if ready else UiKit.DIM_TEXT_COLOR
	UiKit.text(self, rect.position + Vector2(0, 54), name, font_size, name_color, rect.size.x, HORIZONTAL_ALIGNMENT_CENTER, ready)
	UiKit.text(self, rect.position + Vector2(0, 78), Roster.title(index), 13, UiKit.DIM_TEXT_COLOR, rect.size.x, HORIZONTAL_ALIGNMENT_CENTER, false)
	if not ready:
		UiKit.text(self, rect.position + Vector2(0, 100), "EM BREVE", 12, UiKit.WARNING_COLOR, rect.size.x, HORIZONTAL_ALIGNMENT_CENTER, false)


func _cursor_rect(slot: int) -> Rect2:
	return _cell_rect(_cursor[slot]).grow(5.0 if slot == 0 else 11.0)


func _draw_cursor_frame(slot: int) -> void:
	var rect := _cursor_rect(slot)
	var color := UiKit.player_color(slot)
	var width := 4.0 if _locked[slot] else 3.0 + sin(_clock * 0.2)
	draw_rect(rect.grow(2.0), Color(color, 0.25), false, 8.0)
	draw_rect(rect, color, false, width)


func _draw_cursor(slot: int) -> void:
	var rect := _cursor_rect(slot)
	var color := UiKit.player_color(slot)
	var tag_y := rect.end.y + 2.0 if slot == 0 else rect.position.y - 20.0
	var tag := Rect2(rect.position.x if slot == 0 else rect.end.x - 34.0, tag_y, 34, 18)
	draw_rect(tag, color)
	UiKit.text(self, tag.position + Vector2(0, 14), "P%d" % (slot + 1), 14, Color.WHITE, tag.size.x, HORIZONTAL_ALIGNMENT_CENTER, false)


func _draw_preview_info(slot: int) -> void:
	var x := PREVIEW_X[slot]
	var left := x - PREVIEW_TEXT_WIDTH * 0.5
	var color := UiKit.player_color(slot)
	if not _menu.is_joined(slot):
		if UiKit.blink(_clock):
			UiKit.text(self, Vector2(left, 400), "P%d: APERTE UM BOTÃO" % (slot + 1), 22, color, PREVIEW_TEXT_WIDTH, HORIZONTAL_ALIGNMENT_CENTER)
		return
	draw_line(Vector2(x - 110, PREVIEW_FLOOR_Y + 4), Vector2(x + 110, PREVIEW_FLOOR_Y + 4), Color(color, 0.15), 12.0)
	draw_line(Vector2(x - 110, PREVIEW_FLOOR_Y + 4), Vector2(x + 110, PREVIEW_FLOOR_Y + 4), Color(color, 0.7), 2.0)
	var index := _cursor[slot]
	var name := Roster.display_name(index)
	var font_size := 34 if name.length() <= LONG_NAME_LENGTH else 26
	UiKit.text(self, Vector2(left, 598), name, font_size, color, PREVIEW_TEXT_WIDTH, HORIZONTAL_ALIGNMENT_CENTER)
	UiKit.text(self, Vector2(left, 626), Roster.title(index), 16, UiKit.DIM_TEXT_COLOR, PREVIEW_TEXT_WIDTH, HORIZONTAL_ALIGNMENT_CENTER, false)
	var status := "X ou □ para confirmar"
	var status_color := UiKit.HINT_COLOR
	if _locked[slot]:
		status = "PRONTO!"
		status_color = UiKit.GOLD_COLOR
	elif not Roster.is_ready(index):
		status = "EM BREVE · usa lutador provisório"
		status_color = UiKit.WARNING_COLOR
	UiKit.text(self, Vector2(left, 654), status, 16, status_color, PREVIEW_TEXT_WIDTH, HORIZONTAL_ALIGNMENT_CENTER, _locked[slot])
