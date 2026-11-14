extends Control

const AUTO_CONTINUE_FRAMES := 45
const TITLE := "IVAD FIGHTING"
const SLOT_RECTS: Array[Rect2] = [Rect2(300, 440, 320, 92), Rect2(660, 440, 320, 92)]

var _menu := MenuInput.new()
var _clock: int = 0
var _ready_frames: int = 0


func _ready() -> void:
	UiKit.fill_screen(self)
	InputRouter.clear_all_slots()
	InputRouter.reset_join_tracking()


func _physics_process(_delta: float) -> void:
	_clock += 1
	_menu.update()
	queue_redraw()
	if GameFlow.is_transitioning():
		return
	if _menu.join_new_player() != -1:
		AudioManager.play_sfx("menu_join")
	if _menu.is_joined(0) and _menu.is_joined(1):
		_ready_frames += 1
		if _ready_frames >= AUTO_CONTINUE_FRAMES:
			_continue()
	elif _menu.is_joined(0) and _menu.confirm(0):
		_continue()


func _continue() -> void:
	AudioManager.play_sfx("menu_confirm")
	GameFlow.go_to(GameFlow.MAIN_MENU)


func _draw() -> void:
	MenuBackdrop.draw(self, _clock)
	UiKit.centered(self, 250, TITLE, 92, UiKit.TEXT_COLOR)
	UiKit.centered(self, 300, "Luta local para dois jogadores", 22, UiKit.DIM_TEXT_COLOR, false)
	var both := _menu.is_joined(0) and _menu.is_joined(1)
	if both:
		UiKit.centered(self, 395, "TUDO PRONTO!", 36, UiKit.GOLD_COLOR)
	elif UiKit.blink(_clock):
		UiKit.centered(self, 395, "APERTE UM BOTÃO", 36, UiKit.GOLD_COLOR)
	for slot in 2:
		_draw_slot(slot)
	var message := "O primeiro controle a apertar vira o P1. O segundo vira o P2."
	if _menu.is_joined(0) and not both:
		message = "P1: aperte confirmar para continuar        P2: aperte qualquer botão para entrar"
	UiKit.centered(self, 600, message, 18, UiKit.DIM_TEXT_COLOR, false)
	UiKit.hint(self)


func _draw_slot(slot: int) -> void:
	var rect := SLOT_RECTS[slot]
	var color := UiKit.player_color(slot)
	var joined := _menu.is_joined(slot)
	UiKit.panel(self, rect, color if joined else Color(color, 0.35))
	UiKit.text(self, rect.position + Vector2(18, 40), "P%d" % (slot + 1), 32, color)
	var label := InputRouter.device_label(InputRouter.slot_devices[slot]) if joined else "aguardando..."
	UiKit.text(self, rect.position + Vector2(18, 74), label, 16, UiKit.TEXT_COLOR if joined else UiKit.DIM_TEXT_COLOR, rect.size.x - 30, HORIZONTAL_ALIGNMENT_LEFT, false)
