extends Node

const LP := ButtonMap.Action.LIGHT_PUNCH
const HP := ButtonMap.Action.HEAVY_PUNCH
const LK := ButtonMap.Action.LIGHT_KICK
const HK := ButtonMap.Action.HEAVY_KICK
const R1 := ButtonMap.Action.SPECIAL
const QCF := [[0, 1], [1, 1], [1, 0]]
const QCB := [[0, 1], [-1, 1], [-1, 0]]
const DOUBLE_QCF := [[0, 1], [1, 1], [1, 0], [0, 1], [1, 1], [1, 0]]

var _sim: FightSim
var _failures: int = 0
var _states_seen: Dictionary = {}
var _hits: int = 0
var _blocks: int = 0


func _ready() -> void:
	_sim = FightSim.new()
	add_child(_sim)
	_sim.hit_landed.connect(func(_a, _d, _m, _p, _dmg): _hits += 1)
	_sim.hit_blocked.connect(func(_a, _d, _m, _p): _blocks += 1)
	_run_all()
	print("SMOKE TEST: %s" % ("OK" if _failures == 0 else "%d FALHAS" % _failures))
	get_tree().quit(1 if _failures > 0 else 0)


func _snap(dir_x: int = 0, dir_y: int = 0, actions: Array = []) -> InputSnapshot:
	var snapshot := InputSnapshot.new()
	snapshot.dir_x = dir_x
	snapshot.dir_y = dir_y
	for action in actions:
		snapshot.set_pressed(action, true)
	return snapshot


func _advance(frames: int, p1: InputSnapshot = null, p2: InputSnapshot = null) -> void:
	_sim.snapshot_overrides[0] = p1 if p1 != null else _snap()
	_sim.snapshot_overrides[1] = p2 if p2 != null else _snap()
	for i in frames:
		_sim.step()
		for fighter in _sim.fighters:
			_states_seen["%d:%s" % [fighter.slot, fighter.state_name()]] = true


func _fresh() -> void:
	_sim.setup(GenericData.build(0), GenericData.build(1))
	_states_seen.clear()
	_hits = 0
	_blocks = 0
	_advance(5)


func _close_in() -> void:
	for i in 200:
		if absf(_sim.fighters[0].position.x - _sim.fighters[1].position.x) <= 70.0:
			break
		_advance(1, _snap(_sim.fighters[0].facing))
	_advance(3)


func _expect(condition: bool, label: String) -> void:
	if condition:
		print("  ok    %s" % label)
	else:
		_failures += 1
		print("  FALHA %s" % label)


func _saw(slot: int, state_name: String) -> bool:
	return _states_seen.has("%d:%s" % [slot, state_name])


func _run_all() -> void:
	_test_movement()
	_test_light_punch()
	_test_blocking()
	_test_launch_and_knockdown()
	_test_sweep()
	_test_jump_and_cross()
	_test_dash()
	_test_chain_and_scaling()
	_test_air_attack()
	_test_wall()
	_test_ko()
	_test_ivad_commands()
	_test_ivad_charge()
	_test_ivad_well()
	_test_ivad_teleport()
	_test_ivad_super()
	_test_ivad_cancel_and_clash()


func _test_movement() -> void:
	print("movimento")
	_fresh()
	var p1 := _sim.fighters[0]
	var p2 := _sim.fighters[1]
	_expect(p1.state == Fighter.State.IDLE and p2.state == Fighter.State.IDLE, "comeca em IDLE")
	var start_x := p1.position.x
	_advance(10, _snap(1))
	_expect(is_equal_approx(p1.position.x, start_x + 10 * p1.data.walk_speed), "anda para frente na velocidade certa")
	_advance(10, _snap(-1))
	_expect(_saw(0, "WALK"), "estado WALK")
	_advance(5, _snap(0, 1))
	_expect(p1.state == Fighter.State.CROUCH, "agacha")
	_close_in()
	var gap := p2.position.x - p1.position.x
	_expect(gap >= 67.5, "pushbox impede atravessar (distancia %.1f)" % gap)


func _test_light_punch() -> void:
	print("soco fraco")
	_fresh()
	_close_in()
	var p1 := _sim.fighters[0]
	var p2 := _sim.fighters[1]
	_advance(1, _snap(0, 0, [LP]))
	_expect(p1.state == Fighter.State.ATTACK, "entra em ATTACK no frame do botao")
	_advance(3)
	_expect(p2.health == 1000, "nao acerta durante o startup")
	_advance(1)
	_expect(p2.health == 960, "acerta no quinto frame (vida %d)" % p2.health)
	_expect(p1.hitstop > 0 and p2.hitstop > 0, "hitstop nos dois")
	_advance(40)
	_expect(p1.state == Fighter.State.IDLE and p2.state == Fighter.State.IDLE, "ambos voltam para IDLE")
	_expect(p1.meter > 0 and p2.meter > 0, "barra de poder enche")


func _test_blocking() -> void:
	print("defesa")
	_fresh()
	_close_in()
	var p2 := _sim.fighters[1]
	_advance(1, _snap(0, 0, [HP]), _snap(1))
	_advance(30, _snap(), _snap(1))
	_expect(p2.health == 1000 and _blocks == 1, "defesa em pe segura golpe medio")
	_expect(_saw(1, "BLOCK_STAND"), "estado BLOCK_STAND")
	_advance(20)
	_close_in()
	_advance(1, _snap(0, 1, [LK]), _snap(1))
	_advance(25, _snap(0, 1), _snap(1))
	_expect(p2.health == 960, "golpe baixo fura defesa em pe (vida %d)" % p2.health)
	_advance(20)
	_close_in()
	var before := p2.health
	_advance(1, _snap(0, 1, [LK]), _snap(1, 1))
	_advance(25, _snap(0, 1), _snap(1, 1))
	_expect(p2.health == before and _saw(1, "BLOCK_CROUCH"), "defesa agachada segura golpe baixo")
	_advance(20)
	_close_in()
	before = p2.health
	_advance(1, _snap(0, -1), _snap(1, 1))
	_advance(22, _snap(), _snap(1, 1))
	_advance(1, _snap(0, 0, [HK]), _snap(1, 1))
	_advance(30, _snap(), _snap(1, 1))
	_expect(p2.health < before, "golpe aereo fura defesa agachada (vida %d)" % p2.health)


func _test_launch_and_knockdown() -> void:
	print("lancamento")
	_fresh()
	_close_in()
	var p2 := _sim.fighters[1]
	_advance(1, _snap(0, 1, [HP]))
	_advance(12, _snap(0, 1))
	_expect(p2.state == Fighter.State.AIR_HITSTUN and p2.airborne, "gancho lanca para o ar")
	_advance(120)
	_expect(_saw(1, "KNOCKDOWN") and _saw(1, "GETUP"), "cai, fica no chao e levanta")
	_expect(p2.state == Fighter.State.IDLE and p2.position.y == 0.0, "volta ao IDLE no chao")


func _test_sweep() -> void:
	print("rasteira")
	_fresh()
	_close_in()
	var p2 := _sim.fighters[1]
	_advance(1, _snap(0, 1, [HK]))
	_advance(12, _snap(0, 1))
	_expect(p2.state == Fighter.State.KNOCKDOWN, "rasteira derruba")
	_advance(1, _snap(0, 1, [LK]))
	_advance(20, _snap(0, 1))
	_expect(p2.health == 900, "nao apanha caido (vida %d)" % p2.health)


func _test_jump_and_cross() -> void:
	print("pulo")
	_fresh()
	var p1 := _sim.fighters[0]
	var p2 := _sim.fighters[1]
	_advance(15, _snap(1))
	_advance(1, _snap(1, -1))
	_advance(10, _snap(1, -1))
	_expect(p1.airborne and p1.position.y < 0.0, "sai do chao")
	_advance(60)
	_expect(not p1.airborne and p1.position.y == 0.0, "pousa")
	_expect(p1.position.x > p2.position.x, "pulo para frente cruza o oponente")
	_expect(p1.facing == -1 and p2.facing == 1, "troca de lado automatica")


func _test_dash() -> void:
	print("dash")
	_fresh()
	var p1 := _sim.fighters[0]
	var start_x := p1.position.x
	_advance(2, _snap(1))
	_advance(2)
	_advance(2, _snap(1))
	_expect(_saw(0, "DASH"), "toque duplo para frente da dash")
	_advance(20)
	_expect(p1.position.x > start_x + 100.0, "dash desloca (%.0f px)" % (p1.position.x - start_x))
	_fresh()
	_advance(2, _snap(-1))
	_advance(2)
	_advance(2, _snap(-1))
	_expect(_saw(0, "BACKDASH"), "toque duplo para tras da recuo")


func _test_chain_and_scaling() -> void:
	print("combo")
	_fresh()
	_close_in()
	var p2 := _sim.fighters[1]
	_advance(1, _snap(0, 0, [LP]))
	_advance(12)
	_advance(1, _snap(0, 0, [HP]))
	_advance(20)
	_expect(_hits == 2 and p2.combo_hits == 2, "jab cancela em direto (hits %d, combo %d)" % [_hits, p2.combo_hits])
	_expect(p2.health == 1000 - 40 - 100, "dano do combo (vida %d)" % p2.health)
	_advance(60)
	_expect(p2.combo_hits == 0, "contador de combo zera")


func _test_air_attack() -> void:
	print("ataque aereo")
	_fresh()
	var p1 := _sim.fighters[0]
	var p2 := _sim.fighters[1]
	_advance(1, _snap(1, -1))
	_advance(20, _snap(1, -1))
	_advance(1, _snap(0, 0, [HK]))
	_advance(40)
	_expect(p2.health < 1000, "voadora acerta (vida %d)" % p2.health)
	_expect(_saw(0, "LANDING") and p1.state == Fighter.State.IDLE, "pousa e recupera")


func _test_wall() -> void:
	print("parede")
	_fresh()
	var p1 := _sim.fighters[0]
	var p2 := _sim.fighters[1]
	_advance(400, _snap(1))
	_expect(p2.at_right_wall, "oponente empurrado ate a parede")
	_expect(p2.position.x <= GlobalTuning.STAGE_HALF_WIDTH and p1.position.x < p2.position.x, "ninguem sai do palco")
	var p1_x := p1.position.x
	_advance(1, _snap(0, 0, [HP]))
	_advance(40)
	_expect(p1.position.x < p1_x + 24.0 - 5.0, "no canto o atacante e empurrado para tras")


func _test_ko() -> void:
	print("ko")
	_fresh()
	var p2 := _sim.fighters[1]
	for i in 4000:
		if _sim.finished:
			break
		var p1 := _sim.fighters[0]
		if absf(p1.position.x - p2.position.x) > 90.0:
			_advance(1, _snap(p1.facing))
		elif i % 30 == 0:
			_advance(1, _snap(0, 0, [HP]))
		else:
			_advance(1)
	_expect(_sim.finished and _sim.winner_slot == 0, "luta termina com vitoria do P1 no frame %d" % _sim.frame)
	_expect(p2.health == 0 and p2.state == Fighter.State.KO, "P2 em KO")
	_advance(120)
	_expect(not p2.airborne and p2.position.y == 0.0, "corpo do KO pousa no chao")


func _fresh_ivad(p2_ivad: bool = false) -> void:
	_sim.setup(IvadData.build(), IvadData.build() if p2_ivad else GenericData.build(1))
	_states_seen.clear()
	_hits = 0
	_blocks = 0
	_advance(5)


func _motion(dirs: Array, action: ButtonMap.Action, p2: InputSnapshot = null, hold_after: int = 0) -> void:
	var facing := _sim.fighters[0].facing
	for index in dirs.size() - 1:
		_advance(2, _snap(dirs[index][0] * facing, dirs[index][1]), p2)
	var last: Array = dirs[dirs.size() - 1]
	_advance(1, _snap(last[0] * facing, last[1], [action]), p2)
	if hold_after > 0:
		_advance(hold_after, _snap(0, 0, [action]), p2)


func _move_id(slot: int) -> String:
	var move := _sim.fighters[slot].current_move
	return move.id if move != null else "-"


func _test_ivad_commands() -> void:
	print("ivad comandos")
	_fresh_ivad()
	_close_in()
	var p2 := _sim.fighters[1]
	_motion(QCF, LP)
	_expect(_move_id(0) == "soco_ivad_l", "quarto de circulo + soco fraco (%s)" % _move_id(0))
	_advance(30)
	_expect(p2.health == 1000 - 110, "Soco de Ivad acerta (vida %d)" % p2.health)
	_expect(_saw(1, "AIR_HITSTUN"), "Soco de Ivad lanca")
	_advance(120)
	_fresh_ivad()
	_motion(QCB, LK)
	_expect(_move_id(0) == "passo_l", "quarto de circulo para tras + chute (%s)" % _move_id(0))
	_fresh_ivad()
	_motion(DOUBLE_QCF, HP)
	_expect(_move_id(0) == "soco_ivad_h", "sem barra o duplo vira soco forte (%s)" % _move_id(0))
	_fresh_ivad()
	_advance(1, _snap(0, 0, [LP]))
	_expect(_move_id(0) == "lp", "botao sem comando sai o normal (%s)" % _move_id(0))
	_fresh_ivad()
	_advance(40, _snap(0, 1))
	_advance(2, _snap(1, 1))
	_advance(1, _snap(1, 0, [HP]))
	_expect(_move_id(0) == "soco_ivad_h", "agachado parado e depois comando funciona (%s)" % _move_id(0))
	_fresh_ivad()
	_advance(2, _snap(0, 1))
	_advance(2, _snap(1, 1))
	_advance(30, _snap(1, 0))
	_advance(1, _snap(1, 0, [LP]))
	_expect(_move_id(0) == "lp", "comando velho nao vale (%s)" % _move_id(0))


func _test_ivad_charge() -> void:
	print("ivad carga")
	_fresh_ivad()
	_close_in()
	var p1 := _sim.fighters[0]
	var p2 := _sim.fighters[1]
	_motion(QCF, LP, _snap(1, 1), 20)
	_expect(p1.charge_frames > 0 and p2.health == 1000, "segurar o botao carrega (carga %d)" % p1.charge_frames)
	_advance(30, _snap(0, 0, [LP]), _snap(1, 1))
	_advance(40, _snap(), _snap(1, 1))
	_expect(p2.health == 1000 - 190, "carga cheia fura a defesa com dano maximo (vida %d)" % p2.health)
	_fresh_ivad()
	_close_in()
	p2 = _sim.fighters[1]
	_motion(QCF, LP, _snap(1))
	_advance(40, _snap(), _snap(1))
	_expect(p2.health == 1000 - 12 and _blocks == 1, "sem carga e defendido com dano de raspao (vida %d)" % p2.health)


func _test_ivad_well() -> void:
	print("ivad poco")
	_fresh_ivad()
	var p1 := _sim.fighters[0]
	var p2 := _sim.fighters[1]
	_motion(QCB, LP)
	_advance(16)
	_expect(_sim.entities.size() == 1, "poco gravitacional criado (%d entidades)" % _sim.entities.size())
	var start_x := p2.position.x
	_advance(12)
	_expect(p2.position.x < start_x, "oponente e puxado (%.0f -> %.0f)" % [start_x, p2.position.x])
	_motion(QCB, LP)
	_expect(_move_id(0) != "poco_l" or p1.state_frame > 10, "nao lanca segundo poco com um ativo")
	_advance(200)
	_expect(p2.health < 1000 and _hits == 3, "poco acerta 3 vezes (vida %d, hits %d)" % [p2.health, _hits])
	_expect(_sim.entities.is_empty(), "poco some depois")


func _test_ivad_teleport() -> void:
	print("ivad passo estelar")
	_fresh_ivad()
	var p1 := _sim.fighters[0]
	var p2 := _sim.fighters[1]
	_motion(QCB, LK)
	_advance(10)
	_expect(p1.hidden and p1.hurtboxes_world().is_empty(), "fica invisivel e intangivel")
	_advance(12)
	_expect(not p1.hidden and p1.position.x > p2.position.x, "reaparece atras do oponente")
	_expect(p1.facing == -1, "vira para o oponente")
	_advance(40)
	_fresh_ivad()
	p1 = _sim.fighters[0]
	_advance(1, _snap(0, 0, [R1]))
	_advance(30)
	var mark_x := p1.position.x
	_expect(_sim.entities.size() == 1, "R1 planta a marca")
	_advance(40, _snap(1))
	_advance(3)
	_motion(QCB, HK)
	_advance(25)
	_expect(absf(p1.position.x - mark_x) < 1.0, "Passo Estelar forte volta para a marca (%.0f vs %.0f)" % [p1.position.x, mark_x])
	_expect(_sim.entities.is_empty(), "marca e consumida")


func _test_ivad_super() -> void:
	print("ivad supremo")
	_fresh_ivad()
	var p1 := _sim.fighters[0]
	var p2 := _sim.fighters[1]
	p1.meter = GlobalTuning.METER_MAX
	_motion(DOUBLE_QCF, HP)
	_expect(_move_id(0) == "super" and p1.meter == 0, "supremo sai e gasta a barra (%s)" % _move_id(0))
	_advance(10)
	_expect(_sim.freeze_frames > 0, "congela a tela")
	_advance(220)
	_expect(p2.health == 1000 - 5 * 24 - 220, "singularidade esmaga e explode (vida %d)" % p2.health)
	_expect(_sim.entities.is_empty() and p1.state == Fighter.State.IDLE, "tudo volta ao normal")
	_fresh_ivad()
	p1 = _sim.fighters[0]
	p2 = _sim.fighters[1]
	p1.meter = GlobalTuning.METER_MAX
	_motion(DOUBLE_QCF, HP, _snap(1))
	_advance(220, _snap(), _snap(1))
	_expect(p2.health == 1000 - 5 * 4 - 30, "defendido causa so raspao (vida %d)" % p2.health)


func _test_ivad_cancel_and_clash() -> void:
	print("ivad cancelamento e choque")
	_fresh_ivad()
	_close_in()
	var p2 := _sim.fighters[1]
	_advance(1, _snap(0, 0, [LP]))
	_motion(QCF, LP)
	_advance(4)
	_expect(_move_id(0) == "soco_ivad_l", "normal cancela em especial (%s)" % _move_id(0))
	_advance(40)
	_expect(_hits == 2 and p2.health == 1000 - 30 - 110, "combo de 2 golpes (vida %d, hits %d)" % [p2.health, _hits])
	_fresh_ivad(true)
	var qcb_p1 := [[0, 1], [-1, 1], [-1, 0]]
	for index in 2:
		_advance(2, _snap(qcb_p1[index][0], qcb_p1[index][1]), _snap(-qcb_p1[index][0], qcb_p1[index][1]))
	_advance(1, _snap(-1, 0, [HP]), _snap(1, 0, [HP]))
	_advance(16)
	_expect(_sim.entities.size() == 2, "os dois lancam pocos (%d)" % _sim.entities.size())
	_advance(120)
	_expect(_sim.entities.is_empty(), "pocos se anulam no choque")
