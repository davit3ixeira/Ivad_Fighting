class_name FightSim
extends Node

signal hit_landed(attacker: Fighter, defender: Fighter, hit: HitInfo, point: Vector2, damage: int)
signal hit_blocked(attacker: Fighter, defender: Fighter, hit: HitInfo, point: Vector2)
signal hit_armored(attacker: Fighter, defender: Fighter, hit: HitInfo, point: Vector2, damage: int)
signal fight_finished(winner_slot: int)
signal entity_spawned(entity: Entity)
signal entity_removed(entity: Entity, reason: String)
signal effect_requested(effect_name: String, position: Vector2, params: Dictionary)
signal sfx_requested(sfx_name: String)
signal super_started(fighter: Fighter, move: MoveData)

enum DummyMode { OFF, STAND, BLOCK_STAND, BLOCK_CROUCH, CROUCH }

const DUMMY_MODE_NAMES := {
	DummyMode.OFF: "desligado",
	DummyMode.STAND: "parado",
	DummyMode.BLOCK_STAND: "defende em pé",
	DummyMode.BLOCK_CROUCH: "defende agachado",
	DummyMode.CROUCH: "agachado",
}
const OFFSTAGE_MARGIN := 120.0

var fighters: Array[Fighter] = []
var entities: Array[Entity] = []
var frame: int = 0
var freeze_frames: int = 0
var finished: bool = false
var winner_slot: int = -1
var dummy_mode: DummyMode = DummyMode.OFF
var last_snapshots: Array[InputSnapshot] = [InputSnapshot.new(), InputSnapshot.new()]
var snapshot_overrides: Array = [null, null]
var inputs_enabled: bool = true


func setup(p1_data: CharacterData, p2_data: CharacterData) -> void:
	_clear_entities()
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
	freeze_frames = 0
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
	if freeze_frames > 0:
		freeze_frames -= 1
		return
	for fighter in fighters:
		fighter.step()
	for fighter in fighters:
		if fighter.hitstop > 0:
			continue
		for module in fighter.modules:
			module.on_frame(fighter, self)
	_process_fighter_events()
	_update_holds()
	_step_entities()
	_separate_pushboxes()
	_update_facing()
	_resolve_fighter_hits()
	_resolve_entity_hits()
	_resolve_entity_clashes()
	_remove_dead_entities()
	_collect_freeze_requests()
	_check_ko()


func _snapshot_for(fighter: Fighter) -> InputSnapshot:
	if not inputs_enabled:
		return InputSnapshot.new()
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


func spawn_entity(owner: Fighter, entity_data: EntityData, spawn_position: Vector2, spawn_facing: int) -> Entity:
	var entity := Entity.new()
	entity.setup(entity_data, owner, spawn_position, spawn_facing)
	entities.append(entity)
	entity.behavior.on_spawn(entity, self)
	entity_spawned.emit(entity)
	return entity


func spawn_entity_by_id(owner: Fighter, entity_id: String, offset: Vector2) -> Entity:
	var entity_data: EntityData = owner.data.entities.get(entity_id)
	if entity_data == null:
		return null
	var spawn_position := owner.position + Vector2(offset.x * owner.facing, offset.y)
	return spawn_entity(owner, entity_data, spawn_position, owner.facing)


func remove_entity(entity: Entity, reason: String) -> void:
	if not entity.alive:
		return
	entity.alive = false
	entity.behavior.on_removed(entity, self, reason)
	entity_removed.emit(entity, reason)


func request_effect(effect_name: String, effect_position: Vector2, params: Dictionary = {}) -> void:
	effect_requested.emit(effect_name, effect_position, params)


func request_sfx(sfx_name: String) -> void:
	sfx_requested.emit(sfx_name)


func apply_pull(fighter: Fighter, target_x: float, strength: float) -> void:
	if fighter.hidden or fighter.state == Fighter.State.KO:
		return
	var delta := target_x - fighter.position.x
	if absf(delta) < 1.0:
		return
	fighter.position.x += signf(delta) * minf(strength, absf(delta))
	fighter.clamp_to_stage()


func entities_of(owner: Fighter) -> Array[Entity]:
	var owned: Array[Entity] = []
	for entity in entities:
		if entity.alive and entity.owner == owner:
			owned.append(entity)
	return owned


func _process_fighter_events() -> void:
	for fighter in fighters:
		if fighter.pending_events.is_empty():
			continue
		var events := fighter.pending_events.duplicate()
		fighter.pending_events.clear()
		for event in events:
			_process_event(fighter, event)


func _process_event(fighter: Fighter, event: Dictionary) -> void:
	var offset: Vector2 = event.get("offset", Vector2.ZERO)
	var world_offset := Vector2(offset.x * fighter.facing, offset.y)
	match event.get("type", ""):
		"spawn":
			spawn_entity_by_id(fighter, event["entity"], offset)
		"effect":
			request_effect(event["effect"], fighter.position + world_offset, {"facing": fighter.facing, "color": fighter.data.power_color})
		"sfx":
			request_sfx(event["sfx"])
		"hold_offset":
			fighter.hold_offset = event["offset"]
		"held_hit":
			_apply_held_hit(fighter, event)
		"module":
			for module in fighter.modules:
				module.on_move_event(fighter, self, event)


func _step_entities() -> void:
	for entity: Entity in entities.duplicate():
		if not entity.alive:
			continue
		if entity.hitstop > 0:
			entity.hitstop -= 1
			continue
		entity.frame += 1
		if entity.rehit_timer > 0:
			entity.rehit_timer -= 1
		entity.behavior.on_step(entity, self)
		if not entity.alive:
			continue
		entity.position += entity.velocity
		if entity.frame >= entity.data.lifetime:
			remove_entity(entity, "expired")
		elif entity.data.stage_bound and absf(entity.position.x) > GlobalTuning.STAGE_HALF_WIDTH + OFFSTAGE_MARGIN:
			remove_entity(entity, "offstage")


func _remove_dead_entities() -> void:
	for index in range(entities.size() - 1, -1, -1):
		if not entities[index].alive:
			entities.remove_at(index)


func _clear_entities() -> void:
	for entity in entities:
		if entity.alive:
			entity.alive = false
			entity_removed.emit(entity, "reset")
	entities.clear()


func _separate_pushboxes() -> void:
	var a := fighters[0]
	var b := fighters[1]
	if not a.has_pushbox() or not b.has_pushbox():
		return
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
		if fighter.can_turn():
			fighter.face_opponent()


func _first_overlap(hitboxes: Array[Rect2], hurtboxes: Array[Rect2]) -> Variant:
	for hitbox in hitboxes:
		for hurtbox in hurtboxes:
			if hitbox.intersects(hurtbox):
				return hitbox.intersection(hurtbox).get_center()
	return null


func _resolve_fighter_hits() -> void:
	var contacts: Array[Dictionary] = []
	for attacker in fighters:
		var defender := attacker.opponent
		for index in attacker.active_windows():
			var rects := attacker.window_hitboxes_world(index)
			if _window_hits_entities(attacker, index, rects):
				continue
			var move := attacker.current_move
			if move.grab and not defender.can_be_grabbed():
				continue
			var point: Variant = _first_overlap(rects, defender.hurtboxes_world())
			if point == null:
				continue
			contacts.append({
				"attacker": attacker, "defender": defender, "point": point, "move": move,
				"hit": attacker.build_hit(index), "direction": attacker.facing,
			})
			attacker.windows_hit[index] = true
			attacker.move_hit_landed = true
	for contact in contacts:
		var attacker: Fighter = contact["attacker"]
		var defender: Fighter = contact["defender"]
		var move: MoveData = contact["move"]
		if attacker.held_by != null or attacker.current_move != move:
			continue
		if move.grab:
			_apply_grab(attacker, defender, move, contact["point"])
			continue
		var blocked := _apply_hit(attacker, defender, contact["hit"], contact["point"], contact["direction"], attacker)
		if not blocked and move.link_on_hit != "" and defender.is_stunned():
			_link(attacker, defender, move)


func _window_hits_entities(attacker: Fighter, window_index: int, rects: Array[Rect2]) -> bool:
	var move := attacker.current_move
	var consumed := false
	for entity in entities:
		if not entity.alive or entity.owner == attacker:
			continue
		if move.cuts_projectiles and entity.data.cuttable and _first_overlap(rects, entity.hitboxes_world()) != null:
			request_effect("clash", entity.position, {"color": attacker.data.power_color})
			remove_entity(entity, "cut")
			continue
		if entity.data.destructible:
			var hurt: Array[Rect2] = [entity.hurtbox_world()]
			if _first_overlap(rects, hurt) != null:
				entity.health -= move.damage
				attacker.windows_hit[window_index] = true
				attacker.apply_hitstop(move.hitstop)
				request_effect("clash", entity.position, {"color": attacker.data.power_color})
				if entity.health <= 0:
					remove_entity(entity, "destroyed")
				consumed = true
	return consumed


func _resolve_entity_hits() -> void:
	for entity: Entity in entities.duplicate():
		if not entity.can_hit():
			continue
		var defender := entity.owner.opponent
		if defender == null:
			continue
		var point: Variant = _first_overlap(entity.hitboxes_world(), defender.hurtboxes_world())
		if point == null:
			continue
		var hit := entity.hit.copy()
		for module in entity.owner.modules:
			module.modify_hit(entity.owner, hit)
		var delta := defender.position.x - entity.position.x
		var direction := entity.facing if absf(delta) < 8.0 else (1 if delta > 0 else -1)
		var blocked := _apply_hit(entity.owner, defender, hit, point, direction, null)
		entity.hits_left -= 1
		entity.rehit_timer = entity.data.hit_interval
		entity.hitstop = hit.hitstop
		entity.behavior.on_hit(entity, defender, blocked, self)
		if entity.hits_left <= 0 and entity.data.expire_on_last_hit:
			remove_entity(entity, "hit")


func _resolve_entity_clashes() -> void:
	for i in entities.size():
		var a := entities[i]
		if not a.alive or not a.data.clash or a.hitboxes.is_empty():
			continue
		for j in range(i + 1, entities.size()):
			var b := entities[j]
			if not b.alive or not b.data.clash or b.hitboxes.is_empty() or b.owner == a.owner:
				continue
			if _first_overlap(a.hitboxes_world(), b.hitboxes_world()) == null:
				continue
			a.durability -= 1
			b.durability -= 1
			request_effect("clash", (a.position + b.position) * 0.5, {"color": a.owner.data.power_color})
			if b.durability <= 0:
				remove_entity(b, "clash")
			if a.durability <= 0:
				remove_entity(a, "clash")
				break


func _apply_hit(owner: Fighter, defender: Fighter, hit: HitInfo, point: Vector2, direction: int, melee_attacker: Fighter) -> bool:
	if defender.can_block(hit):
		defender.enter_block(hit, direction)
		var block_stop := maxi(hit.hitstop - 2, 2)
		defender.apply_hitstop(block_stop)
		if melee_attacker != null:
			melee_attacker.apply_hitstop(block_stop)
			if defender.is_at_wall_in_direction(direction):
				melee_attacker.push_velocity.x = -direction * hit.block_pushback * GlobalTuning.WALL_PUSHBACK_FACTOR
		for module in owner.modules:
			module.on_hit_dealt(owner, defender, hit, true, self)
		hit_blocked.emit(owner, defender, hit, point)
		return true
	var damage := _scaled_damage(hit.damage, defender.combo_scale_hits)
	if damage < defender.health and defender.absorbs_hit(hit):
		_apply_armored_hit(owner, defender, hit, point, damage, melee_attacker)
		return false
	var hitstun := _scaled_hitstun(hit.hitstun, defender.combo_hits)
	defender.take_hit(hit, direction, damage, hitstun)
	owner.gain_meter(hit.meter_gain)
	defender.apply_hitstop(hit.hitstop)
	if melee_attacker != null:
		melee_attacker.apply_hitstop(hit.hitstop)
		if defender.is_at_wall_in_direction(direction):
			melee_attacker.push_velocity.x = -direction * hit.knockback.x * GlobalTuning.WALL_PUSHBACK_FACTOR
	for module in owner.modules:
		module.on_hit_dealt(owner, defender, hit, false, self)
	if hit.effect != "":
		request_effect(hit.effect, point, {"facing": direction, "color": owner.data.power_color})
	hit_landed.emit(owner, defender, hit, point, damage)
	return false


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


func _collect_freeze_requests() -> void:
	for fighter in fighters:
		if fighter.freeze_request <= 0:
			continue
		freeze_frames = maxi(freeze_frames, fighter.freeze_request)
		fighter.freeze_request = 0
		super_started.emit(fighter, fighter.current_move)


func _check_ko() -> void:
	if finished:
		return
	var knocked_out: Array[Fighter] = []
	for fighter in fighters:
		if fighter.state == Fighter.State.KO:
			knocked_out.append(fighter)
	if knocked_out.is_empty():
		return
	finished = true
	winner_slot = -1 if knocked_out.size() == fighters.size() else knocked_out[0].opponent.slot
	fight_finished.emit(winner_slot)


func _release_fighters() -> void:
	for fighter in fighters:
		fighter.release()
	fighters.clear()


func _exit_tree() -> void:
	_clear_entities()
	_release_fighters()


func _apply_grab(attacker: Fighter, defender: Fighter, move: MoveData, point: Vector2) -> void:
	attacker.apply_hitstop(GlobalTuning.GRAB_HITSTOP)
	defender.apply_hitstop(GlobalTuning.GRAB_HITSTOP)
	request_effect("grab", point, {"facing": attacker.facing, "color": attacker.data.power_color})
	request_sfx("grab")
	_link(attacker, defender, move)


func _link(attacker: Fighter, defender: Fighter, move: MoveData) -> void:
	var followup := attacker.data.move_by_id(move.link_on_hit)
	if followup == null:
		return
	attacker.start_followup(followup)
	if not move.hold_on_link:
		return
	attacker.holding = defender
	attacker.hold_offset = followup.hold_offset
	defender.become_held(attacker)
	_update_holds()


func _update_holds() -> void:
	for holder in fighters:
		var target := holder.holding
		if target == null:
			continue
		var holding_move := holder.state == Fighter.State.ATTACK and holder.current_move != null and holder.current_move.holds_target
		if not holding_move or holder.state == Fighter.State.KO:
			_release_hold(holder)
			continue
		target.position = holder.position + Vector2(holder.hold_offset.x * holder.facing, holder.hold_offset.y)
		target.facing = -holder.facing
		target.clamp_to_stage()


func _release_hold(holder: Fighter) -> void:
	var target := holder.holding
	holder.holding = null
	if target == null:
		return
	target.release_from_hold()
	if target.state == Fighter.State.HELD:
		target.drop_after_hold()


func _apply_held_hit(holder: Fighter, event: Dictionary) -> void:
	var target := holder.holding
	if target == null or holder.current_move == null:
		return
	var hit := HitInfo.from_fields(holder.current_move.id, event.get("hit", {}))
	hit.unblockable = true
	hit.ignores_armor = true
	for module in holder.modules:
		module.modify_hit(holder, hit)
	var point := target.position + Vector2(0, GlobalTuning.HELD_HIT_HEIGHT)
	var damage := _scaled_damage(hit.damage, target.combo_scale_hits)
	if event.get("release", false) or damage >= target.health:
		holder.holding = null
		target.release_from_hold()
		_apply_hit(holder, target, hit, point, holder.facing, holder)
		if target.state == Fighter.State.HELD:
			target.drop_after_hold()
		return
	target.health -= damage
	target.combo_hits += 1
	if hit.scales_combo:
		target.combo_scale_hits += 1
	target.gain_meter(int(damage * GlobalTuning.METER_GAIN_ON_DAMAGE_TAKEN))
	holder.gain_meter(hit.meter_gain)
	holder.apply_hitstop(hit.hitstop)
	target.apply_hitstop(hit.hitstop)
	for module in target.modules:
		module.on_damage_taken(target, hit, damage)
	for module in holder.modules:
		module.on_hit_dealt(holder, target, hit, false, self)
	if hit.effect != "":
		request_effect(hit.effect, point, {"facing": holder.facing, "color": holder.data.power_color})
	hit_landed.emit(holder, target, hit, point, damage)


func _apply_armored_hit(owner: Fighter, defender: Fighter, hit: HitInfo, point: Vector2, damage: int, melee_attacker: Fighter) -> void:
	defender.health -= damage
	defender.gain_meter(int(damage * GlobalTuning.METER_GAIN_ON_DAMAGE_TAKEN))
	owner.gain_meter(hit.meter_gain)
	var stop := maxi(hit.hitstop - GlobalTuning.ARMOR_HITSTOP_REDUCTION, 2)
	defender.apply_hitstop(stop)
	if melee_attacker != null:
		melee_attacker.apply_hitstop(stop)
	for module in defender.modules:
		module.on_damage_taken(defender, hit, damage)
	hit_armored.emit(owner, defender, hit, point, damage)
