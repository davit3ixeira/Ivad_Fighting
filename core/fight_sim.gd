class_name FightSim
extends Node

signal hit_landed(attacker: Fighter, defender: Fighter, move: MoveData, point: Vector2, damage: int)
signal hit_blocked(attacker: Fighter, defender: Fighter, move: MoveData, point: Vector2)
signal fight_finished(winner_slot: int)

enum DummyMode { OFF, STAND, BLOCK_STAND, BLOCK_CROUCH, CROUCH }

const DUMMY_MODE_NAMES := {
	DummyMode.OFF: "desligado",
	DummyMode.STAND: "parado",
	DummyMode.BLOCK_STAND: "defende em pé",
	DummyMode.BLOCK_CROUCH: "defende agachado",
	DummyMode.CROUCH: "agachado",
}

var fighters: Array[Fighter] = []
var frame: int = 0
var finished: bool = false
var winner_slot: int = -1
var dummy_mode: DummyMode = DummyMode.OFF
var last_snapshots: Array[InputSnapshot] = [InputSnapshot.new(), InputSnapshot.new()]
var snapshot_overrides: Array = [null, null]


func setup(p1_data: CharacterData, p2_data: CharacterData) -> void:
	_release_fighters()
	var p1 := Fighter.new()
	var p2 := Fighter.new()
	p1.setup(p1_data, 0, -GlobalTuning.START_DISTANCE * 0.5, 1)
	p2.setup(p2_data, 1, GlobalTuning.START_DISTANCE * 0.5, -1)
	p1.opponent = p2
	p2.opponent = p1
	fighters.append(p1)
	fighters.append(p2)
	frame = 0
	finished = false
	winner_slot = -1


func reset_round() -> void:
	setup(fighters[0].data, fighters[1].data)


func step() -> void:
	frame += 1
	for fighter in fighters:
		var snapshot := _snapshot_for(fighter)
		last_snapshots[fighter.slot] = snapshot
		fighter.begin_frame(snapshot)
	for fighter in fighters:
		fighter.step()
	_separate_pushboxes()
	_update_facing()
	_resolve_hits()
	_check_ko()


func _snapshot_for(fighter: Fighter) -> InputSnapshot:
	if snapshot_overrides[fighter.slot] != null:
		return snapshot_overrides[fighter.slot]
	if fighter.slot == 1 and dummy_mode != DummyMode.OFF:
		return _dummy_snapshot(fighter)
	return InputRouter.read_slot(fighter.slot)


func _dummy_snapshot(fighter: Fighter) -> InputSnapshot:
	var snapshot := InputSnapshot.new()
	match dummy_mode:
		DummyMode.BLOCK_STAND:
			snapshot.dir_x = -fighter.facing
		DummyMode.BLOCK_CROUCH:
			snapshot.dir_x = -fighter.facing
			snapshot.dir_y = 1
		DummyMode.CROUCH:
			snapshot.dir_y = 1
	return snapshot


func cycle_dummy_mode() -> void:
	dummy_mode = ((dummy_mode + 1) % DummyMode.size()) as DummyMode


func dummy_mode_name() -> String:
	return DUMMY_MODE_NAMES.get(dummy_mode, "?")


func _separate_pushboxes() -> void:
	var a := fighters[0]
	var b := fighters[1]
	var box_a := a.pushbox_world()
	var box_b := b.pushbox_world()
	if not box_a.intersects(box_b):
		return
	var left := a if a.position.x <= b.position.x else b
	var right := b if left == a else a
	var left_box := left.pushbox_world()
	var right_box := right.pushbox_world()
	var overlap := left_box.end.x - right_box.position.x
	if overlap <= 0.0:
		return
	var left_blocked := left.at_left_wall
	var right_blocked := right.at_right_wall
	if not left_blocked and not right_blocked:
		left.position.x -= overlap * 0.5
		right.position.x += overlap * 0.5
	elif not left_blocked:
		left.position.x -= overlap
	elif not right_blocked:
		right.position.x += overlap
	left.clamp_to_stage()
	right.clamp_to_stage()


func _update_facing() -> void:
	for fighter in fighters:
		if not fighter.can_turn():
			continue
		var delta := fighter.opponent.position.x - fighter.position.x
		if absf(delta) < 1.0:
			continue
		var new_facing := 1 if delta > 0 else -1
		fighter.facing = new_facing


func _resolve_hits() -> void:
	var contacts: Array[Dictionary] = []
	for attacker in fighters:
		var defender := attacker.opponent
		var hitboxes := attacker.hitboxes_world()
		if hitboxes.is_empty():
			continue
		var hurtboxes := defender.hurtboxes_world()
		var found := false
		for hitbox in hitboxes:
			if found:
				break
			for hurtbox in hurtboxes:
				if hitbox.intersects(hurtbox):
					var overlap := hitbox.intersection(hurtbox)
					contacts.append({"attacker": attacker, "defender": defender, "point": overlap.get_center()})
					found = true
					break
	for contact in contacts:
		_apply_contact(contact["attacker"], contact["defender"], contact["point"])


func _apply_contact(attacker: Fighter, defender: Fighter, point: Vector2) -> void:
	var move := attacker.current_move
	if move == null:
		return
	attacker.move_hit_done = true
	attacker.move_hit_landed = true
	var direction := attacker.facing
	if defender.can_block(move.hit_height):
		defender.enter_block(move, direction)
		attacker.apply_hitstop(maxi(move.hitstop - 2, 2))
		defender.apply_hitstop(maxi(move.hitstop - 2, 2))
		if defender.is_at_wall_in_direction(direction):
			attacker.push_velocity.x = -direction * move.block_pushback * GlobalTuning.WALL_PUSHBACK_FACTOR
		hit_blocked.emit(attacker, defender, move, point)
		return
	var damage := _scaled_damage(move.damage, defender.combo_hits)
	var hitstun := _scaled_hitstun(move.hitstun, defender.combo_hits)
	defender.take_hit(move, direction, damage, hitstun)
	attacker.gain_meter(move.meter_gain)
	attacker.apply_hitstop(move.hitstop)
	defender.apply_hitstop(move.hitstop)
	if defender.is_at_wall_in_direction(direction):
		attacker.push_velocity.x = -direction * move.knockback.x * GlobalTuning.WALL_PUSHBACK_FACTOR
	hit_landed.emit(attacker, defender, move, point, damage)


func _scaled_damage(base: int, combo_index: int) -> int:
	var table: Array = GlobalTuning.COMBO_DAMAGE_SCALE
	var scale: float
	if combo_index < table.size():
		scale = table[combo_index]
	else:
		scale = maxf(table[table.size() - 1] - 0.1 * (combo_index - table.size() + 1), GlobalTuning.COMBO_MIN_DAMAGE_SCALE)
	return maxi(int(round(base * scale)), 1)


func _scaled_hitstun(base: int, combo_index: int) -> int:
	if combo_index < GlobalTuning.COMBO_HITSTUN_DECAY_START:
		return base
	var decay := (combo_index - GlobalTuning.COMBO_HITSTUN_DECAY_START + 1) * GlobalTuning.COMBO_HITSTUN_DECAY_PER_HIT
	return maxi(base - decay, GlobalTuning.COMBO_HITSTUN_MIN)


func _check_ko() -> void:
	if finished:
		return
	for fighter in fighters:
		if fighter.state == Fighter.State.KO:
			finished = true
			winner_slot = fighter.opponent.slot
			fight_finished.emit(winner_slot)
			return


func _release_fighters() -> void:
	for fighter in fighters:
		fighter.opponent = null
	fighters.clear()


func _exit_tree() -> void:
	_release_fighters()
