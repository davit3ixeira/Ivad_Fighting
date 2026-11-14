extends Node

const PRESS_START := "res://scenes/press_start.tscn"
const MAIN_MENU := "res://scenes/main_menu.tscn"
const CHARACTER_SELECT := "res://scenes/character_select.tscn"
const STAGE_SELECT := "res://scenes/stage_select.tscn"
const FIGHT := "res://scenes/fight.tscn"
const TAP_FRAMES := 4

var _output_dir: String = "user://flow"
var _steps: Array = []
var _wait: int = 0
var _releases: Dictionary = {}
var _frame: int = 0
var _failures: int = 0
var _done: bool = false


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_output_dir = args[0]
	DirAccess.make_dir_recursive_absolute(_output_dir)
	_build_steps()


func _build_steps() -> void:
	_steps = [
		["wait", 40], ["scene", PRESS_START], ["shot", "50_press_start"],
		["tap", KEY_K], ["wait", 20], ["shot", "51_p1_joined"],
		["tap", KEY_KP_2], ["wait", 85],
		["scene", MAIN_MENU], ["shot", "52_menu"],
		["tap", KEY_S], ["wait", 10], ["tap", KEY_W], ["wait", 10],
		["tap", KEY_K], ["wait", 50],
		["scene", CHARACTER_SELECT], ["shot", "53_select"],
		["tap", KEY_D], ["wait", 10], ["tap", KEY_RIGHT], ["wait", 10], ["tap", KEY_RIGHT], ["wait", 20],
		["shot", "54_select_hover"],
		["tap", KEY_A], ["wait", 10], ["tap", KEY_K], ["wait", 25],
		["shot", "55_p1_locked"],
		["tap", KEY_LEFT], ["wait", 10], ["tap", KEY_LEFT], ["wait", 10], ["tap", KEY_KP_2], ["wait", 15],
		["shot", "56_both_locked"], ["wait", 80],
		["scene", STAGE_SELECT], ["shot", "57_stages"],
		["tap", KEY_D], ["wait", 20], ["shot", "58_stage_hover"],
		["tap", KEY_K], ["wait", 50],
		["scene", FIGHT], ["shot", "59_intro_names"],
		["wait", 50], ["shot", "60_intro_lines"],
		["wait", 55], ["shot", "61_fight_call"],
		["wait", 30], ["tap", KEY_ESCAPE], ["wait", 15], ["shot", "62_pause"],
		["tap", KEY_K], ["wait", 20], ["expect_running"],
		["weaken_p2"],
		["hold", KEY_D, 70], ["wait", 60],
		["tap", KEY_J], ["wait", 14], ["tap", KEY_J], ["wait", 14], ["tap", KEY_J], ["wait", 14],
		["wait", 40], ["shot", "63_ko"],
		["wait", 160], ["shot", "64_victory"],
		["tap", KEY_K], ["wait", 40], ["scene", FIGHT], ["shot", "65_rematch_intro"],
		["wait", 140], ["tap", KEY_ESCAPE], ["wait", 12], ["tap", KEY_S], ["wait", 12],
		["shot", "66_pause_exit"], ["tap", KEY_K], ["wait", 60],
		["scene", MAIN_MENU], ["shot", "67_back_to_menu"],
	]


func _physics_process(_delta: float) -> void:
	if _done:
		return
	_frame += 1
	for keycode in _releases.keys():
		if _releases[keycode] <= _frame:
			_send_key(keycode, false)
			_releases.erase(keycode)
	if _wait > 0:
		_wait -= 1
		return
	if _steps.is_empty():
		_finish()
		return
	_run(_steps.pop_front())


func _run(step: Array) -> void:
	match step[0]:
		"wait":
			_wait = step[1]
		"tap":
			_send_key(step[1], true)
			_releases[step[1]] = _frame + TAP_FRAMES
		"hold":
			_send_key(step[1], true)
			_releases[step[1]] = _frame + step[2]
		"shot":
			_capture(step[1])
		"scene":
			_expect_scene(step[1])
		"weaken_p2":
			var sim: FightSim = get_tree().current_scene.get_node("Sim")
			sim.fighters[1].health = 1
		"expect_running":
			var fight := get_tree().current_scene
			_expect(fight.get("_paused") == false, "pausa fecha com Continuar")


func _send_key(keycode: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = keycode
	event.pressed = pressed
	Input.parse_input_event(event)


func _expect_scene(path: String) -> void:
	var current := get_tree().current_scene
	var actual := current.scene_file_path if current != null else "-"
	_expect(actual == path, "cena %s (atual %s)" % [path.get_file(), actual.get_file()])


func _expect(condition: bool, label: String) -> void:
	if condition:
		print("  ok    %s" % label)
	else:
		_failures += 1
		print("  FALHA %s" % label)


func _capture(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.save_png("%s/%s.png" % [_output_dir, shot_name])


func _finish() -> void:
	_done = true
	print("FLOW: %s" % ("OK" if _failures == 0 else "%d FALHAS" % _failures))
	await get_tree().create_timer(0.3).timeout
	get_tree().quit(1 if _failures > 0 else 0)
