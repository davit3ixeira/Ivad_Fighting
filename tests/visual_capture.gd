extends Node

const LP := ButtonMap.Action.LIGHT_PUNCH
const HP := ButtonMap.Action.HEAVY_PUNCH
const LK := ButtonMap.Action.LIGHT_KICK
const HK := ButtonMap.Action.HEAVY_KICK
const FIGHT_SCENE := "res://scenes/fight.tscn"
const POSES_LAST_FRAME := 560
const PERF_LAST_FRAME := 900
const PERF_WARMUP_FRAMES := 120
const KO_FRAME_LIMIT := 3000
const KO_LINGER_FRAMES := 50

var _fight: Node
var _sim: FightSim
var _frame: int = 0
var _mode: String = "poses"
var _output_dir: String = "user://captures"
var _ko_frame: int = -1
var _shots := {
	10: "01_idle", 40: "02_walk", 75: "03_lp", 112: "04_hp_blocked", 157: "05_lk", 201: "06_hk",
	258: "07_crouch", 267: "08_clp", 292: "09_clk", 315: "10_chk", 330: "11_knockdown",
	395: "12_jump", 489: "13_chp_debug", 500: "14_launch_debug", 530: "15_dash", 546: "16_air_kick",
}
var _frame_times: Array[float] = []


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_output_dir = args[0]
	if args.size() > 1:
		_mode = args[1]
	DirAccess.make_dir_recursive_absolute(_output_dir)
	_fight = load(FIGHT_SCENE).instantiate()
	add_child(_fight)
	_sim = _fight.get_node("Sim")
	process_physics_priority = -10


func _process(delta: float) -> void:
	if _frame > PERF_WARMUP_FRAMES:
		_frame_times.append(delta)


func _physics_process(_delta: float) -> void:
	_frame += 1
	match _mode:
		"poses":
			_step_poses()
		"ko":
			_step_ko()
		_:
			_step_perf()


func _step_poses() -> void:
	_sim.snapshot_overrides[0] = _poses_p1_input(_frame)
	_sim.snapshot_overrides[1] = _snap(1, 0) if _frame >= 98 and _frame <= 125 else _snap(0, 0)
	if _frame == 430:
		_fight.get_node("DebugOverlay").set_enabled(true)
	if _frame == 510:
		_fight.get_node("DebugOverlay").set_enabled(false)
	if _shots.has(_frame):
		_capture(_shots[_frame])
	if _frame >= POSES_LAST_FRAME:
		_finish()


func _step_ko() -> void:
	_sim.snapshot_overrides[0] = _brawler_input(0, HP, 30)
	_sim.snapshot_overrides[1] = _snap(0, 0)
	if _sim.finished and _ko_frame < 0:
		_ko_frame = _frame
	if _ko_frame >= 0 and _frame == _ko_frame + 4:
		_capture("20_ko_hit")
	if _ko_frame >= 0 and _frame == _ko_frame + KO_LINGER_FRAMES:
		_capture("21_ko_screen")
	if (_ko_frame >= 0 and _frame >= _ko_frame + KO_LINGER_FRAMES + 5) or _frame >= KO_FRAME_LIMIT:
		_finish()


func _step_perf() -> void:
	_sim.snapshot_overrides[0] = _brawler_input(0, HP if (_frame / 60) % 2 == 0 else LK, 22)
	_sim.snapshot_overrides[1] = _brawler_input(1, LP if (_frame / 45) % 2 == 0 else HK, 26)
	if _sim.finished:
		_sim.reset_round()
		for view in _fight.get_node("Views").get_children():
			view.bind(_sim.fighters[view.get_index()])
	if _frame >= PERF_LAST_FRAME:
		_finish()


func _brawler_input(slot: int, action: ButtonMap.Action, period: int) -> InputSnapshot:
	var me := _sim.fighters[slot]
	var other := _sim.fighters[1 - slot]
	if absf(me.position.x - other.position.x) > 110.0:
		return _snap(me.facing, 0)
	if (_frame + slot * 7) % period == 0:
		return _snap(0, 0, [action])
	if (_frame + slot * 11) % 97 < 6:
		return _snap(0, -1)
	return _snap(0, 0)


func _snap(dir_x: int, dir_y: int, actions: Array = []) -> InputSnapshot:
	var snapshot := InputSnapshot.new()
	snapshot.dir_x = dir_x
	snapshot.dir_y = dir_y
	for action in actions:
		snapshot.set_pressed(action, true)
	return snapshot


func _poses_p1_input(frame: int) -> InputSnapshot:
	if frame >= 20 and frame <= 60:
		return _snap(1, 0)
	match frame:
		70:
			return _snap(0, 0, [LP])
		100:
			return _snap(0, 0, [HP])
		150:
			return _snap(0, 0, [LK])
		190:
			return _snap(0, 0, [HK])
		262:
			return _snap(0, 1, [LP])
		285:
			return _snap(0, 1, [LK])
		305:
			return _snap(0, 1, [HK])
		480:
			return _snap(0, 1, [HP])
		520, 521, 524, 525:
			return _snap(-1, 0)
		540:
			return _snap(0, 0, [LK])
	if frame >= 130 and frame <= 145:
		return _snap(1, 0)
	if frame >= 170 and frame <= 185:
		return _snap(1, 0)
	if frame >= 225 and frame <= 245:
		return _snap(1, 0)
	if frame >= 250 and frame <= 335:
		return _snap(0, 1)
	if frame >= 380 and frame <= 384:
		return _snap(0, -1)
	if frame >= 440 and frame <= 472:
		return _snap(1, 0)
	if frame >= 473 and frame <= 500:
		return _snap(0, 1)
	if frame >= 532 and frame <= 536:
		return _snap(1, -1)
	return _snap(0, 0)


func _capture(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.save_png("%s/%s.png" % [_output_dir, shot_name])


func _finish() -> void:
	set_physics_process(false)
	if _mode == "perf" and not _frame_times.is_empty():
		var sorted := _frame_times.duplicate()
		sorted.sort()
		var total := 0.0
		for time in sorted:
			total += time
		var average: float = total / sorted.size()
		var p99: float = sorted[int(sorted.size() * 0.99) - 1]
		var slow := 0
		for time in sorted:
			if time > 0.0185:
				slow += 1
		print("PERF: %d frames, media %.2f ms (%.1f fps), p99 %.2f ms, pior %.2f ms, acima de 18.5 ms: %d" % [
			sorted.size(), average * 1000.0, 1.0 / average, p99 * 1000.0, sorted[sorted.size() - 1] * 1000.0, slow,
		])
	await get_tree().create_timer(0.3).timeout
	get_tree().quit()
