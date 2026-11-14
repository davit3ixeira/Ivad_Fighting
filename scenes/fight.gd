extends Node2D

const P1_COLOR := Color(0.25, 0.6, 1.0)
const P2_COLOR := Color(1.0, 0.25, 0.3)
const PLAYER_COLORS: Array[Color] = [P1_COLOR, P2_COLOR]
const BLOCK_SPARK_COLOR := Color(0.7, 0.85, 1.0)
const KO_SHAKE := 12.0
const SUPER_DIM := 0.62
const SUPER_DIM_EXTRA_FRAMES := 90
const SUPER_ZOOM := 1.22
const SUPER_FOCUS_HEIGHT := -110.0
const SUPER_BANNER_FRAMES := 80
const EFFECT_SHAKES := {"supernova": 14.0, "cosmic_ring": 6.0}
const EFFECT_FLASHES := {"supernova": 0.75}

@onready var _stage: Node2D = $Stage
@onready var _sim: FightSim = $Sim
@onready var _views_root: Node2D = $Views
@onready var _effects_root: Node2D = $Effects
@onready var _camera: FightCamera = $Camera
@onready var _hud: FightHud = $HudLayer/Hud
@onready var _debug: DebugOverlay = $DebugOverlay

var _views: Array[FighterView] = []
var _entity_views: Dictionary = {}
var _entities_root: Node2D
var _dimmer: StageDimmer
var _pause_held: Array[bool] = [false, false]
var _character_indices: Array[int] = [0, 0]


func _ready() -> void:
	_dimmer = StageDimmer.new()
	add_child(_dimmer)
	move_child(_dimmer, _stage.get_index() + 1)
	_entities_root = Node2D.new()
	add_child(_entities_root)
	move_child(_entities_root, _dimmer.get_index() + 1)
	_sim.hit_landed.connect(_on_hit_landed)
	_sim.hit_blocked.connect(_on_hit_blocked)
	_sim.fight_finished.connect(_on_fight_finished)
	_sim.entity_spawned.connect(_on_entity_spawned)
	_sim.entity_removed.connect(_on_entity_removed)
	_sim.effect_requested.connect(_on_effect_requested)
	_sim.sfx_requested.connect(_on_sfx_requested)
	_sim.super_started.connect(_on_super_started)
	_start_fight()
	_debug.bind(_sim)


func set_characters(p1_index: int, p2_index: int) -> void:
	_character_indices[0] = p1_index
	_character_indices[1] = p2_index
	_start_fight()


func _start_fight() -> void:
	_sim.setup(Roster.build(_character_indices[0]), Roster.build(_character_indices[1]))
	for fighter in _sim.fighters:
		if _views.size() <= fighter.slot:
			var view := FighterView.new()
			_views_root.add_child(view)
			view.setup(fighter, PLAYER_COLORS[fighter.slot])
			_views.append(view)
		else:
			_views[fighter.slot].bind(fighter)
	for effect in _effects_root.get_children():
		effect.queue_free()
	_dimmer.clear()
	_hud.bind(_sim)
	_camera.snap_to(_sim.fighters)


func _physics_process(_delta: float) -> void:
	_assign_free_slots()
	_check_restart_request()
	_sim.step()
	for view in _views:
		view.sync()
	for entity_view in _entities_root.get_children():
		entity_view.sync()
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
			_start_fight()
		ButtonMap.KEY_CYCLE_P1_CHARACTER:
			_cycle_character(0)
		ButtonMap.KEY_CYCLE_P2_CHARACTER:
			_cycle_character(1)
		ButtonMap.KEY_FILL_METER:
			for fighter in _sim.fighters:
				fighter.meter = GlobalTuning.METER_MAX
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
			_start_fight()
			return


func _cycle_character(slot: int) -> void:
	_character_indices[slot] = (_character_indices[slot] + 1) % Roster.count()
	_start_fight()


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


func _bring_to_front(fighter: Fighter) -> void:
	_views_root.move_child(_views[fighter.slot], -1)


func _spawn_spark(point: Vector2, color: Color, strength: float, blocked: bool) -> void:
	var spark := HitSpark.new()
	_effects_root.add_child(spark)
	spark.setup(point, color, strength, blocked)


func _on_hit_landed(attacker: Fighter, _defender: Fighter, hit: HitInfo, point: Vector2, damage: int) -> void:
	var heavy := hit.is_heavy()
	_bring_to_front(attacker)
	_spawn_spark(point, attacker.data.accent_color, 1.5 if heavy else 1.0, false)
	_camera.add_shake(damage * GlobalTuning.SHAKE_PER_DAMAGE)
	AudioManager.play_sfx("hit_heavy" if heavy else "hit_light")


func _on_hit_blocked(attacker: Fighter, _defender: Fighter, _hit: HitInfo, point: Vector2) -> void:
	_bring_to_front(attacker)
	_spawn_spark(point, BLOCK_SPARK_COLOR, 0.8, true)
	AudioManager.play_sfx("block")


func _on_fight_finished(winner_slot: int) -> void:
	_camera.add_shake(KO_SHAKE)
	_hud.center_title = "K.O."
	_hud.center_subtitle = "P%d %s VENCE   -   Pausa reinicia" % [winner_slot + 1, _sim.fighters[winner_slot].data.display_name]
	AudioManager.play_sfx("ko")


func _on_entity_spawned(entity: Entity) -> void:
	var view := EntityVisuals.create(entity.data.visual)
	_entities_root.add_child(view)
	view.setup(entity, PLAYER_COLORS[entity.owner.slot])
	_entity_views[entity] = view


func _on_entity_removed(entity: Entity, reason: String) -> void:
	var view: EntityView = _entity_views.get(entity)
	_entity_views.erase(entity)
	if view != null and is_instance_valid(view):
		view.finish(reason)


func _on_effect_requested(effect_name: String, effect_position: Vector2, params: Dictionary) -> void:
	var effect := EffectLibrary.create(effect_name, params)
	if effect != null:
		effect.position = effect_position
		_effects_root.add_child(effect)
	if EFFECT_SHAKES.has(effect_name):
		_camera.add_shake(EFFECT_SHAKES[effect_name])
	if EFFECT_FLASHES.has(effect_name):
		_hud.flash(Color.WHITE, EFFECT_FLASHES[effect_name])
		_dimmer.dim(0.0, 1)
	AudioManager.play_sfx(effect_name)


func _on_sfx_requested(sfx_name: String) -> void:
	AudioManager.play_sfx(sfx_name)


func _on_super_started(fighter: Fighter, move: MoveData) -> void:
	_hud.flash(Color.WHITE, 0.6)
	_hud.show_banner(move.display_name.to_upper(), fighter.data.power_color, SUPER_BANNER_FRAMES)
	_dimmer.dim(SUPER_DIM, move.super_freeze + SUPER_DIM_EXTRA_FRAMES)
	_camera.focus(fighter.position + Vector2(0, SUPER_FOCUS_HEIGHT), SUPER_ZOOM, move.super_freeze)
	AudioManager.play_sfx("super_start")
