extends Node2D

enum Phase { INTRO, FIGHT, KO, VICTORY }

const BLOCK_SPARK_COLOR := Color(0.7, 0.85, 1.0)
const KO_SHAKE := 12.0
const SUPER_DIM := 0.62
const SUPER_DIM_EXTRA_FRAMES := 90
const SUPER_ZOOM := 1.22
const SUPER_FOCUS_HEIGHT := -110.0
const SUPER_BANNER_FRAMES := 80
const EFFECT_SHAKES := {"supernova": 14.0, "cosmic_ring": 6.0}
const EFFECT_FLASHES := {"supernova": 0.75}
const INTRO_FIGHT_FRAME := 130
const INTRO_SKIP_FRAME := 20
const KO_WIN_POSE_FRAME := 70
const KO_VICTORY_FRAME := 140
const PAUSE_ITEMS: Array[String] = ["Continuar", "Voltar ao menu"]
const VICTORY_ITEMS: Array[String] = ["Revanche", "Voltar à seleção de personagem"]
const VICTORY_TOP_OFFSET := -95.0
const VICTORY_DIM := 0.38

@onready var _stage: StagePlaceholder = $Stage
@onready var _sim: FightSim = $Sim
@onready var _views_root: Node2D = $Views
@onready var _effects_root: Node2D = $Effects
@onready var _camera: FightCamera = $Camera
@onready var _hud_layer: CanvasLayer = $HudLayer
@onready var _hud: FightHud = $HudLayer/Hud
@onready var _debug: DebugOverlay = $DebugOverlay

var play_intro: bool = true

var _views: Array[FighterView] = []
var _entity_views: Dictionary = {}
var _entities_root: Node2D
var _dimmer: StageDimmer
var _intro: IntroOverlay
var _pause_menu: MenuOverlay
var _victory_menu: MenuOverlay
var _menu := MenuInput.new()
var _character_indices: Array[int] = [0, 0]
var _phase: Phase = Phase.FIGHT
var _phase_frame: int = 0
var _paused: bool = false


func _ready() -> void:
	_dimmer = StageDimmer.new()
	add_child(_dimmer)
	move_child(_dimmer, _stage.get_index() + 1)
	_entities_root = Node2D.new()
	add_child(_entities_root)
	move_child(_entities_root, _dimmer.get_index() + 1)
	_intro = IntroOverlay.new()
	_hud_layer.add_child(_intro)
	_victory_menu = MenuOverlay.new()
	_victory_menu.top_offset = VICTORY_TOP_OFFSET
	_victory_menu.dim_alpha = VICTORY_DIM
	_hud_layer.add_child(_victory_menu)
	_pause_menu = MenuOverlay.new()
	_hud_layer.add_child(_pause_menu)
	_sim.hit_landed.connect(_on_hit_landed)
	_sim.hit_blocked.connect(_on_hit_blocked)
	_sim.fight_finished.connect(_on_fight_finished)
	_sim.entity_spawned.connect(_on_entity_spawned)
	_sim.entity_removed.connect(_on_entity_removed)
	_sim.effect_requested.connect(_on_effect_requested)
	_sim.sfx_requested.connect(_on_sfx_requested)
	_sim.super_started.connect(_on_super_started)
	_character_indices.assign(GameFlow.characters)
	_stage.apply(GameFlow.stage)
	_debug.bind(_sim)
	_start_fight(play_intro)


func set_characters(p1_index: int, p2_index: int) -> void:
	_character_indices = [p1_index, p2_index]
	_start_fight(false)


func _start_fight(with_intro: bool) -> void:
	_sim.setup(Roster.build(_character_indices[0], 0), Roster.build(_character_indices[1], 1))
	for fighter in _sim.fighters:
		if _views.size() <= fighter.slot:
			var view := FighterView.new()
			_views_root.add_child(view)
			view.setup(fighter, UiKit.player_color(fighter.slot))
			_views.append(view)
		else:
			_views[fighter.slot].bind(fighter)
	for effect in _effects_root.get_children():
		effect.queue_free()
	_dimmer.clear()
	_hud.bind(_sim)
	_camera.snap_to(_sim.fighters)
	_paused = false
	_pause_menu.close()
	_victory_menu.close()
	if with_intro:
		_begin_intro()
	else:
		_intro.finish()
		_begin_combat(false)


func _begin_intro() -> void:
	_sim.inputs_enabled = false
	var p1 := _sim.fighters[0]
	var p2 := _sim.fighters[1]
	for fighter in _sim.fighters:
		fighter.play_cinematic("intro")
	_intro.begin(p1.data.display_name, p2.data.display_name, p1.data.intro_line_against(p2.data.id), p2.data.intro_line_against(p1.data.id))
	_set_phase(Phase.INTRO)
	AudioManager.play_sfx("intro")


func _begin_combat(announce: bool) -> void:
	_sim.inputs_enabled = true
	for fighter in _sim.fighters:
		fighter.clear_cinematic()
	if announce:
		_intro.call_fight()
		AudioManager.play_sfx("fight_start")
	_set_phase(Phase.FIGHT)


func _set_phase(phase: Phase) -> void:
	_phase = phase
	_phase_frame = 0


func _physics_process(_delta: float) -> void:
	_menu.update()
	_assign_free_slots()
	if _paused:
		_update_pause()
		_pause_menu.refresh()
		return
	_phase_frame += 1
	match _phase:
		Phase.INTRO:
			_update_intro()
		Phase.FIGHT:
			if _menu.any_pause() and not GameFlow.is_transitioning():
				_open_pause()
				return
		Phase.KO:
			_update_ko()
		Phase.VICTORY:
			_update_victory()
	_sim.step()
	for view in _views:
		view.sync()
	for entity_view in _entities_root.get_children():
		entity_view.sync()
	_camera.follow(_sim.fighters)
	_hud.refresh()
	_intro.refresh()
	_victory_menu.refresh()
	_debug.refresh()


func _update_intro() -> void:
	var skip := _phase_frame >= INTRO_SKIP_FRAME and _menu.any_confirm()
	if _phase_frame >= INTRO_FIGHT_FRAME or skip:
		_begin_combat(true)


func _update_ko() -> void:
	if _phase_frame == KO_WIN_POSE_FRAME and _sim.winner_slot >= 0:
		_sim.fighters[_sim.winner_slot].play_cinematic("win")
	if _phase_frame >= KO_VICTORY_FRAME:
		_open_victory()


func _open_victory() -> void:
	_hud.center_title = ""
	_hud.center_subtitle = ""
	var winner_slot := _sim.winner_slot
	if winner_slot < 0:
		_victory_menu.open("EMPATE", UiKit.TEXT_COLOR, "Ninguém ficou de pé.", "", VICTORY_ITEMS)
	else:
		var winner := _sim.fighters[winner_slot]
		var loser := winner.opponent
		_victory_menu.open("P%d VENCE" % (winner_slot + 1), UiKit.player_color(winner_slot), winner.data.display_name, winner.data.win_line_against(loser.data.id), VICTORY_ITEMS)
	_set_phase(Phase.VICTORY)
	AudioManager.play_sfx("victory")


func _update_victory() -> void:
	if GameFlow.is_transitioning():
		return
	var step := _menu.any_nav().y
	if step != 0:
		_victory_menu.move(step)
	if not _menu.any_confirm():
		return
	AudioManager.play_sfx("menu_confirm")
	if _victory_menu.index == 0:
		_start_fight(true)
	else:
		GameFlow.go_to(GameFlow.CHARACTER_SELECT)


func _open_pause() -> void:
	_paused = true
	_intro.finish()
	_pause_menu.open("PAUSA", UiKit.TEXT_COLOR, "", "", PAUSE_ITEMS)
	AudioManager.play_sfx("pause")


func _close_pause() -> void:
	_paused = false
	_pause_menu.close()
	AudioManager.play_sfx("menu_back")


func _update_pause() -> void:
	if GameFlow.is_transitioning():
		return
	if _menu.any_pause() or _menu.any_back():
		_close_pause()
		return
	var step := _menu.any_nav().y
	if step != 0:
		_pause_menu.move(step)
	if not _menu.any_confirm():
		return
	if _pause_menu.index == 0:
		_close_pause()
	else:
		AudioManager.play_sfx("menu_confirm")
		GameFlow.go_to(GameFlow.MAIN_MENU)


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
			_start_fight(false)
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


func _cycle_character(slot: int) -> void:
	_character_indices[slot] = (_character_indices[slot] + 1) % Roster.count()
	_start_fight(false)


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
	_sim.inputs_enabled = false
	_camera.add_shake(KO_SHAKE)
	_hud.center_title = "K.O." if winner_slot >= 0 else "K.O. DUPLO"
	_hud.center_subtitle = ""
	_set_phase(Phase.KO)
	AudioManager.play_sfx("ko")


func _on_entity_spawned(entity: Entity) -> void:
	var view := EntityVisuals.create(entity.data.visual)
	_entities_root.add_child(view)
	view.setup(entity, UiKit.player_color(entity.owner.slot))
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
