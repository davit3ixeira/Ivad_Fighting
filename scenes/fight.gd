extends Node2D

const P1_COLOR := Color(0.25, 0.6, 1.0)
const P2_COLOR := Color(1.0, 0.25, 0.3)
const HEAVY_HIT_DAMAGE := 80
const KO_SHAKE := 12.0

@onready var _sim: FightSim = $Sim
@onready var _views_root: Node2D = $Views
@onready var _effects_root: Node2D = $Effects
@onready var _camera: FightCamera = $Camera
@onready var _hud: FightHud = $HudLayer/Hud
@onready var _debug: DebugOverlay = $DebugOverlay

var _views: Array[FighterView] = []
var _pause_held: Array[bool] = [false, false]


func _ready() -> void:
	_sim.setup(GenericData.build(0), GenericData.build(1))
	_sim.hit_landed.connect(_on_hit_landed)
	_sim.hit_blocked.connect(_on_hit_blocked)
	_sim.fight_finished.connect(_on_fight_finished)
	var colors := [P1_COLOR, P2_COLOR]
	for fighter in _sim.fighters:
		var view := FighterView.new()
		_views_root.add_child(view)
		view.setup(fighter, colors[fighter.slot])
		_views.append(view)
	_hud.bind(_sim)
	_debug.bind(_sim)
	_camera.snap_to(_sim.fighters)


func _physics_process(_delta: float) -> void:
	_assign_free_slots()
	_check_restart_request()
	_sim.step()
	for view in _views:
		view.sync()
	_camera.follow(_sim.fighters)
	_hud.refresh()
	_debug.refresh()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match event.physical_keycode:
		ButtonMap.KEY_DEBUG_OVERLAY:
			_debug.toggle()
		ButtonMap.KEY_TRAINING_DUMMY:
			_toggle_dummy()
		ButtonMap.KEY_DUMMY_MODE:
			_cycle_dummy_mode()
		ButtonMap.KEY_RESET_ROUND:
			_restart_round()
		ButtonMap.KEY_FULLSCREEN:
			_toggle_fullscreen()


func _assign_free_slots() -> void:
	var joined := InputRouter.poll_join_press()
	if joined == InputRouter.DEVICE_NONE or InputRouter.slot_of_device(joined) != -1:
		return
	for slot in InputRouter.SLOT_COUNT:
		if InputRouter.slot_devices[slot] != InputRouter.DEVICE_NONE:
			continue
		if slot == InputRouter.SLOT_P2 and _sim.dummy_mode != FightSim.DummyMode.OFF:
			continue
		InputRouter.assign_slot(slot, joined)
		return


func _check_restart_request() -> void:
	for slot in InputRouter.SLOT_COUNT:
		var held := InputRouter.read_slot(slot).is_pressed(ButtonMap.Action.PAUSE)
		var pressed_now := held and not _pause_held[slot]
		_pause_held[slot] = held
		if pressed_now and _sim.finished:
			_restart_round()
			return


func _restart_round() -> void:
	_sim.reset_round()
	for view in _views:
		view.bind(_sim.fighters[_views.find(view)])
	_hud.reset()
	_camera.snap_to(_sim.fighters)


func _toggle_dummy() -> void:
	if _sim.dummy_mode == FightSim.DummyMode.OFF:
		_sim.dummy_mode = FightSim.DummyMode.STAND
	else:
		_sim.dummy_mode = FightSim.DummyMode.OFF


func _cycle_dummy_mode() -> void:
	if _sim.dummy_mode == FightSim.DummyMode.OFF:
		return
	_sim.cycle_dummy_mode()
	if _sim.dummy_mode == FightSim.DummyMode.OFF:
		_sim.dummy_mode = FightSim.DummyMode.STAND


func _toggle_fullscreen() -> void:
	var window := get_window()
	if window.mode == Window.MODE_FULLSCREEN:
		window.mode = Window.MODE_WINDOWED
	else:
		window.mode = Window.MODE_FULLSCREEN


func _spawn_spark(point: Vector2, color: Color, strength: float, blocked: bool) -> void:
	var spark := HitSpark.new()
	_effects_root.add_child(spark)
	spark.setup(point, color, strength, blocked)


func _on_hit_landed(attacker: Fighter, _defender: Fighter, move: MoveData, point: Vector2, damage: int) -> void:
	var heavy := move.damage >= HEAVY_HIT_DAMAGE
	_spawn_spark(point, attacker.data.accent_color, 1.5 if heavy else 1.0, false)
	_camera.add_shake(damage * GlobalTuning.SHAKE_PER_DAMAGE)
	AudioManager.play_sfx("hit_heavy" if heavy else "hit_light")


func _on_hit_blocked(_attacker: Fighter, _defender: Fighter, _move: MoveData, point: Vector2) -> void:
	_spawn_spark(point, Color(0.7, 0.85, 1.0), 0.8, true)
	AudioManager.play_sfx("block")


func _on_fight_finished(winner_slot: int) -> void:
	_camera.add_shake(KO_SHAKE)
	_hud.center_title = "K.O."
	_hud.center_subtitle = "P%d %s VENCE   -   Pausa reinicia" % [winner_slot + 1, _sim.fighters[winner_slot].data.display_name]
	AudioManager.play_sfx("ko")
