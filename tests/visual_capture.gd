extends Node

const LP := ButtonMap.Action.LIGHT_PUNCH
const HP := ButtonMap.Action.HEAVY_PUNCH
const LK := ButtonMap.Action.LIGHT_KICK
const HK := ButtonMap.Action.HEAVY_KICK
const R1 := ButtonMap.Action.SPECIAL
const QCF := [[0, 1], [1, 1], [1, 0]]
const QCB := [[0, 1], [-1, 1], [-1, 0]]
const DOUBLE_QCF := [[0, 1], [1, 1], [1, 0], [0, 1], [1, 1], [1, 0]]
const HCB := [[1, 0], [1, 1], [0, 1], [-1, 1], [-1, 0]]
const HALUHO_LAST_FRAME := 720
const FIGHT_SCENE := "res://scenes/fight.tscn"
const POSES_LAST_FRAME := 560
const IVAD_LAST_FRAME := 900
const PERF_LAST_FRAME := 1200
const PERF_WARMUP_FRAMES := 120
const KO_FRAME_LIMIT := 3000
const KO_LINGER_FRAMES := 50
const VICTORY_CAPTURE_FRAME := 175
const ROSTER_IVAD := 0
const ROSTER_PROVISIONAL := Roster.PROVISIONAL_INDEX
const ROSTER_HALUHO := 1

var _fight: Node
var _sim: FightSim
var _frame: int = 0
var _mode: String = "poses"
var _output_dir: String = "user://captures"
var _ko_frame: int = -1
var _queues: Array = [[], []]
var _scheduled_shots: Dictionary = {}
var _pose_shots := {
	10: "01_idle", 40: "02_walk", 75: "03_lp", 112: "04_hp_blocked", 157: "05_lk", 201: "06_hk",
	258: "07_crouch", 267: "08_clp", 292: "09_clk", 315: "10_chk", 330: "11_knockdown",
	395: "12_jump", 489: "13_chp_debug", 500: "14_launch_debug", 530: "15_dash", 546: "16_air_kick",
}
var _ivad_shots := {
	12: "30_ivad_idle", 34: "31_ivad_cast", 80: "32_well_pull", 232: "33_charge_full",
	352: "35_mark", 392: "36_walk_hair",
}
var _frame_times: Array[float] = []
var _perf_variant: String = "full"
var _physics_time_total: float = 0.0
var _process_time_total: float = 0.0
var _draw_calls_total: float = 0.0
var _primitives_total: float = 0.0
var _monitor_samples: int = 0


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_output_dir = args[0]
	if args.size() > 2:
		_perf_variant = args[2]
	if args.size() > 1:
		_mode = args[1]
	DirAccess.make_dir_recursive_absolute(_output_dir)
	_fight = load(FIGHT_SCENE).instantiate()
	_fight.play_intro = false
	add_child(_fight)
	_sim = _fight.get_node("Sim")
	match _mode:
		"poses", "ko":
			_fight.set_characters(ROSTER_PROVISIONAL, ROSTER_PROVISIONAL)
		"haluho":
			_fight.set_characters(ROSTER_HALUHO, ROSTER_PROVISIONAL)
		"ivad":
			_fight.set_characters(ROSTER_IVAD, ROSTER_PROVISIONAL)
		_:
			_fight.set_characters(ROSTER_IVAD, ROSTER_IVAD)
	_sim.effect_requested.connect(_on_effect_requested)
	_sim.super_started.connect(_on_super_started)
	_sim.hit_armored.connect(_on_hit_armored)
	process_physics_priority = -10


func _process(delta: float) -> void:
	if _frame > PERF_WARMUP_FRAMES:
		_physics_time_total += Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)
		_process_time_total += Performance.get_monitor(Performance.TIME_PROCESS)
		_draw_calls_total += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		_primitives_total += Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
		_monitor_samples += 1
		_frame_times.append(delta)


func _physics_process(_delta: float) -> void:
	_frame += 1
	match _mode:
		"poses":
			_step_poses()
		"ko":
			_step_ko()
		"haluho":
			_fight.set_characters(ROSTER_HALUHO, ROSTER_PROVISIONAL)
		"haluho":
			_step_haluho()
		"ivad":
			_step_ivad()
		_:
			_step_perf()
	if _scheduled_shots.has(_frame):
		_capture(_scheduled_shots[_frame])


func _step_poses() -> void:
	_sim.snapshot_overrides[0] = _poses_p1_input(_frame)
	_sim.snapshot_overrides[1] = _snap(1, 0) if _frame >= 98 and _frame <= 125 else _snap(0, 0)
	if _frame == 430:
		_fight.get_node("DebugOverlay").set_enabled(true)
	if _frame == 510:
		_fight.get_node("DebugOverlay").set_enabled(false)
	if _pose_shots.has(_frame):
		_capture(_pose_shots[_frame])
	if _frame >= POSES_LAST_FRAME:
		_finish()


func _step_ivad() -> void:
	match _frame:
		20:
			_queue_motion(0, QCB, LP)
		150:
			_queue_hold(0, _snap(1, 0), 22)
		190:
			_queue_motion(0, QCF, LP, 46)
		320:
			_queue_hold(0, _snap(0, 0, [R1]), 1)
		360:
			_queue_hold(0, _snap(1, 0), 40)
		420:
			_queue_motion(0, QCB, LK)
		490:
			_queue_motion(0, QCB, HK)
		560:
			_sim.fighters[0].meter = GlobalTuning.METER_MAX
			_queue_motion(0, DOUBLE_QCF, HP)
		436:
			_capture("37_rift_hidden")
		452:
			_capture("38_behind")
		528:
			_capture("39_back_at_mark")
	_sim.snapshot_overrides[0] = _next_input(0)
	_sim.snapshot_overrides[1] = _snap(0, 0)
	if _ivad_shots.has(_frame):
		_capture(_ivad_shots[_frame])
	if _frame >= IVAD_LAST_FRAME:
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
	if _ko_frame >= 0 and _frame == _ko_frame + VICTORY_CAPTURE_FRAME:
		_capture("22_victory")
	if (_ko_frame >= 0 and _frame >= _ko_frame + VICTORY_CAPTURE_FRAME + 5) or _frame >= KO_FRAME_LIMIT:
		_finish()


func _step_perf() -> void:
	if _frame == 1 and _perf_variant == "haluho":
		_fight.set_characters(ROSTER_HALUHO, ROSTER_HALUHO)
	if _frame == 1 and _perf_variant == "generic":
		_fight.set_characters(ROSTER_PROVISIONAL, ROSTER_PROVISIONAL)
	for slot in 2:
		var phase := _frame + slot * 170
		if _perf_variant == "haluho":
			if phase % 340 == 0:
				_queue_motion(slot, QCB, HP)
			elif phase % 340 == 120:
				_queue_motion(slot, QCF, HK)
			elif phase % 340 == 220:
				_queue_hold(slot, _snap(0, 0, [R1]), 1)
			elif phase % 510 == 300:
				_sim.fighters[slot].meter = GlobalTuning.METER_MAX
				_queue_motion(slot, DOUBLE_QCF, HP)
		if _perf_variant == "full":
			if phase % 340 == 0:
				_queue_motion(slot, QCB, HP)
			elif phase % 340 == 120:
				_queue_motion(slot, QCF, LP, 20)
			elif phase % 510 == 300:
				_sim.fighters[slot].meter = GlobalTuning.METER_MAX
				_queue_motion(slot, DOUBLE_QCF, HP)
		if _perf_variant == "idle":
			_sim.snapshot_overrides[slot] = _snap(0, 0)
		elif _queues[slot].is_empty():
			_sim.snapshot_overrides[slot] = _brawler_input(slot, HP if (_frame / 60) % 2 == 0 else LK, 22 + slot * 4)
		else:
			_sim.snapshot_overrides[slot] = _next_input(slot)
	if _sim.finished:
		_fight._start_fight(false)
	if _frame >= PERF_LAST_FRAME:
		_finish()


func _queue_motion(slot: int, dirs: Array, action: ButtonMap.Action, hold_after: int = 0) -> void:
	var facing := _sim.fighters[slot].facing
	for index in dirs.size() - 1:
		_queue_hold(slot, _snap(dirs[index][0] * facing, dirs[index][1]), 2)
	var last: Array = dirs[dirs.size() - 1]
	_queue_hold(slot, _snap(last[0] * facing, last[1], [action]), 1)
	if hold_after > 0:
		_queue_hold(slot, _snap(0, 0, [action]), hold_after)


func _queue_hold(slot: int, snapshot: InputSnapshot, frames: int) -> void:
	for index in frames:
		_queues[slot].append(snapshot)


func _next_input(slot: int) -> InputSnapshot:
	if _queues[slot].is_empty():
		return _snap(0, 0)
	return _queues[slot].pop_front()


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


func _on_effect_requested(effect_name: String, _position: Vector2, _params: Dictionary) -> void:
	if _mode != "ivad":
		return
	match effect_name:
		"cosmic_ring":
			_scheduled_shots[_frame + 7] = "34_cosmic_ring"
		"supernova":
			_scheduled_shots[_frame + 6] = "42_supernova"
			_scheduled_shots[_frame + 22] = "43_supernova_late"


func _on_super_started(_fighter: Fighter, _move: MoveData) -> void:
	if _mode == "haluho":
		_scheduled_shots[_frame + 22] = "77_true_form"
		_scheduled_shots[_frame + 56] = "78_super_hold"
		_scheduled_shots[_frame + 84] = "79_super_lift"
	if _mode != "ivad":
		return
	_scheduled_shots[_frame + 14] = "40_super_freeze"
	_scheduled_shots[_frame + 80] = "41_singularity"


func _capture(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.save_png("%s/%s.png" % [_output_dir, shot_name])


func _finish() -> void:
	set_physics_process(false)
	if not _frame_times.is_empty() and _mode == "perf":
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
		var samples := maxf(_monitor_samples, 1.0)
		print("MONITOR %s: fisica %.2f ms, processo %.2f ms, draw calls %.0f, primitivas %.0f" % [_perf_variant, _physics_time_total / samples * 1000.0, _process_time_total / samples * 1000.0, _draw_calls_total / samples, _primitives_total / samples])
		print("PERF: %d frames, media %.2f ms (%.1f fps), p99 %.2f ms, pior %.2f ms, acima de 18.5 ms: %d" % [
			sorted.size(), average * 1000.0, 1.0 / average, p99 * 1000.0, sorted[sorted.size() - 1] * 1000.0, slow,
		])
	await get_tree().create_timer(0.3).timeout
	get_tree().quit()


func _step_haluho() -> void:
	match _frame:
		12:
			_capture("70_haluho_idle")
		20:
			_queue_motion(0, QCB, LP)
		90:
			_queue_motion(0, QCB, HP)
		160:
			_queue_hold(0, _snap(1, 0), 24)
		200:
			_queue_motion(0, HCB, LP)
		330:
			_queue_hold(0, _snap(0, 0, [R1]), 1)
		400:
			_queue_hold(0, _snap(-1, 0), 30)
		440:
			_queue_motion(0, QCF, LK)
		540:
			_sim.fighters[0].meter = GlobalTuning.METER_MAX
			_queue_motion(0, DOUBLE_QCF, HP)
		37:
			_capture("71_whip_l")
		111:
			_capture("72_whip_h")
		226:
			_capture("73_grab_hold")
		246:
			_capture("74_grab_lift")
		362:
			_capture("75_pact_aura")
	if _frame == 25:
		_fight.get_node("DebugOverlay").set_enabled(true)
	if _frame == 120:
		_fight.get_node("DebugOverlay").set_enabled(false)
	_sim.snapshot_overrides[0] = _next_input(0)
	_sim.snapshot_overrides[1] = _snap(0, 0, [LP]) if _frame == 452 else _snap(0, 0)
	if _frame >= HALUHO_LAST_FRAME:
		_finish()


func _on_hit_armored(_attacker: Fighter, _defender: Fighter, _hit: HitInfo, _point: Vector2, _damage: int) -> void:
	if _mode == "haluho":
		_scheduled_shots[_frame + 2] = "76_armor"
