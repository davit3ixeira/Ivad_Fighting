class_name Fighter
extends RefCounted

enum State { IDLE, WALK, CROUCH, JUMP, DASH, BACKDASH, ATTACK, BLOCK_STAND, BLOCK_CROUCH, HITSTUN, AIR_HITSTUN, KNOCKDOWN, GETUP, LANDING, KO }

const STATE_NAMES := {
	State.IDLE: "IDLE",
	State.WALK: "WALK",
	State.CROUCH: "CROUCH",
	State.JUMP: "JUMP",
	State.DASH: "DASH",
	State.BACKDASH: "BACKDASH",
	State.ATTACK: "ATTACK",
	State.BLOCK_STAND: "BLOCK_STAND",
	State.BLOCK_CROUCH: "BLOCK_CROUCH",
	State.HITSTUN: "HITSTUN",
	State.AIR_HITSTUN: "AIR_HITSTUN",
	State.KNOCKDOWN: "KNOCKDOWN",
	State.GETUP: "GETUP",
	State.LANDING: "LANDING",
	State.KO: "KO",
}

const ATTACK_PRIORITY: Array[ButtonMap.Action] = [
	ButtonMap.Action.HEAVY_KICK,
	ButtonMap.Action.HEAVY_PUNCH,
	ButtonMap.Action.LIGHT_KICK,
	ButtonMap.Action.LIGHT_PUNCH,
]

const KINDS_FROM_NEUTRAL: Array[MoveData.Kind] = [MoveData.Kind.SUPER, MoveData.Kind.SPECIAL, MoveData.Kind.UNIQUE]
const KINDS_FROM_NORMAL: Array[MoveData.Kind] = [MoveData.Kind.SUPER, MoveData.Kind.SPECIAL]
const KINDS_FROM_SPECIAL: Array[MoveData.Kind] = [MoveData.Kind.SUPER]

var data: CharacterData
var slot: int = 0
var opponent: Fighter
var modules: Array[FighterModule] = []
var position: Vector2 = Vector2.ZERO
var velocity: Vector2 = Vector2.ZERO
var push_velocity: Vector2 = Vector2.ZERO
var facing: int = 1
var airborne: bool = false
var hidden: bool = false
var state: State = State.IDLE
var state_frame: int = 0
var health: int = 1000
var meter: int = 0
var current_move: MoveData
var windows_hit: Dictionary = {}
var move_hit_landed: bool = false
var charge_frames: int = 0
var stun_frames: int = 0
var combo_hits: int = 0
var combo_scale_hits: int = 0
var juggle_hits: int = 0
var hitstop: int = 0
var air_attack_used: bool = false
var jump_dir: int = 0
var hit_while_crouching: bool = false
var landing_frames: int = GlobalTuning.LANDING_FRAMES
var input: InputBuffer = InputBuffer.new()
var anim_name: String = "idle"
var anim_frame: int = 0
var at_left_wall: bool = false
var at_right_wall: bool = false
var pending_events: Array[Dictionary] = []
var freeze_request: int = 0
var cinematic_anim: String = ""

var _events_fired: Dictionary = {}
var _hold_frame: bool = false


func setup(character: CharacterData, player_slot: int, start_x: float, start_facing: int) -> void:
	data = character
	slot = player_slot
	health = character.health
	meter = 0
	position = Vector2(start_x, GlobalTuning.FLOOR_Y)
	velocity = Vector2.ZERO
	push_velocity = Vector2.ZERO
	facing = start_facing
	airborne = false
	hidden = false
	combo_hits = 0
	combo_scale_hits = 0
	juggle_hits = 0
	hitstop = 0
	current_move = null
	input = InputBuffer.new()
	cinematic_anim = ""
	modules.clear()
	for script in character.module_scripts:
		var module: FighterModule = script.new()
		modules.append(module)
	for module in modules:
		module.on_setup(self)
	_enter_state(State.IDLE)
	_update_anim()


func release() -> void:
	opponent = null
	modules.clear()
	pending_events.clear()


func begin_frame(snapshot: InputSnapshot) -> void:
	input.update(snapshot, facing)


func step() -> void:
	if hitstop > 0:
		hitstop -= 1
		return
	_hold_frame = false
	match state:
		State.IDLE, State.WALK, State.CROUCH:
			_step_neutral()
		State.JUMP:
			_step_jump()
		State.DASH:
			_step_dash()
		State.BACKDASH:
			_step_backdash()
		State.ATTACK:
			_step_attack()
		State.BLOCK_STAND, State.BLOCK_CROUCH:
			_step_block()
		State.HITSTUN:
			_step_hitstun()
		State.AIR_HITSTUN:
			pass
		State.KNOCKDOWN:
			if state_frame >= GlobalTuning.KNOCKDOWN_FRAMES:
				_enter_state(State.GETUP)
		State.GETUP:
			if state_frame >= GlobalTuning.GETUP_FRAMES:
				_enter_state(State.IDLE)
				_step_neutral()
		State.LANDING:
			if state_frame >= landing_frames:
				_enter_state(State.IDLE)
				_step_neutral()
		State.KO:
			velocity.x = 0.0
	_apply_physics()
	_update_anim()
	if not _hold_frame:
		state_frame += 1


func _enter_state(new_state: State) -> void:
	state = new_state
	state_frame = 0


func _set_state_keep_frame(new_state: State) -> void:
	if state != new_state:
		_enter_state(new_state)


func _step_neutral() -> void:
	combo_hits = 0
	combo_scale_hits = 0
	juggle_hits = 0
	var command_move := _buffered_command_move(KINDS_FROM_NEUTRAL)
	if command_move != null:
		_start_move(command_move)
		return
	if input.dash_request != 0:
		var dash_dir := input.dash_request
		input.consume_dash()
		_enter_state(State.DASH if dash_dir > 0 else State.BACKDASH)
		return
	var stance := MoveData.Stance.CROUCH if input.down else MoveData.Stance.STAND
	var move := _buffered_move(stance)
	if move != null:
		_start_move(move)
		return
	if input.up:
		_start_jump()
		return
	if input.down:
		_set_state_keep_frame(State.CROUCH)
		velocity.x = 0.0
		return
	if input.forward:
		_set_state_keep_frame(State.WALK)
		velocity.x = facing * data.walk_speed
	elif input.back:
		_set_state_keep_frame(State.WALK)
		velocity.x = -facing * data.back_speed
	else:
		_set_state_keep_frame(State.IDLE)
		velocity.x = 0.0


func _buffered_move(stance: MoveData.Stance) -> MoveData:
	for action in ATTACK_PRIORITY:
		if input.pressed_buffered(action):
			var move := data.find_move(action, stance)
			if move != null:
				input.consume(action)
				return move
	return null


func _buffered_command_move(allowed_kinds: Array[MoveData.Kind]) -> MoveData:
	for move in data.command_moves():
		if not allowed_kinds.has(move.kind):
			continue
		if (move.stance == MoveData.Stance.AIR) != airborne:
			continue
		if not input.pressed_buffered(move.button):
			continue
		if meter < move.meter_cost:
			continue
		if not CommandParser.matches(input, move.motion):
			continue
		if not _modules_allow(move):
			continue
		input.consume(move.button)
		return move
	return null


func _modules_allow(move: MoveData) -> bool:
	for module in modules:
		if not module.can_start_move(self, move):
			return false
	return true


func _start_move(move: MoveData) -> void:
	for module in modules:
		move = module.resolve_move(self, move)
	current_move = move
	windows_hit.clear()
	move_hit_landed = false
	charge_frames = 0
	_events_fired.clear()
	meter = maxi(meter - move.meter_cost, 0)
	if not airborne:
		velocity.x = 0.0
	else:
		air_attack_used = true
	_enter_state(State.ATTACK)
	for module in modules:
		module.on_move_started(self, move)


func _start_jump() -> void:
	jump_dir = 1 if input.forward else (-1 if input.back else 0)
	velocity.x = 0.0
	_enter_state(State.JUMP)


func _step_jump() -> void:
	if not airborne:
		if state_frame >= GlobalTuning.PREJUMP_FRAMES:
			airborne = true
			air_attack_used = false
			velocity.y = data.jump_velocity
			if jump_dir > 0:
				velocity.x = facing * data.jump_forward_speed
			elif jump_dir < 0:
				velocity.x = -facing * data.jump_back_speed
			else:
				velocity.x = 0.0
		return
	if air_attack_used:
		return
	var command_move := _buffered_command_move(KINDS_FROM_NEUTRAL)
	if command_move != null:
		_start_move(command_move)
		return
	var move := _buffered_move(MoveData.Stance.AIR)
	if move != null:
		_start_move(move)


func _step_dash() -> void:
	velocity.x = facing * data.dash_speed
	if state_frame >= data.dash_frames:
		velocity.x = 0.0
		_enter_state(State.IDLE)
		_step_neutral()


func _step_backdash() -> void:
	velocity.x = -facing * data.backdash_speed
	if state_frame >= data.backdash_frames:
		velocity.x = 0.0
		_enter_state(State.IDLE)
		_step_neutral()


func _step_attack() -> void:
	var move := current_move
	_fire_move_events(move)
	if move.super_freeze > 0 and state_frame == maxi(move.super_freeze_frame, 1):
		freeze_request = move.super_freeze
	if airborne:
		return
	if state_frame >= move.total_frames():
		velocity.x = 0.0
		_enter_state(State.CROUCH if input.down else State.IDLE)
		_step_neutral()
		return
	if _try_cancel(move):
		return
	if move.charge_frame > 0 and state_frame == move.charge_frame and charge_frames < move.charge_max_frames and input.is_held(move.button):
		charge_frames += 1
		_hold_frame = true
		velocity.x = 0.0
		return
	if state_frame > move.advance_start and state_frame <= move.advance_start + move.advance_frames:
		velocity.x = facing * move.advance
	else:
		velocity.x = 0.0


func _try_cancel(move: MoveData) -> bool:
	if not move_hit_landed or state_frame < move.first_active_frame():
		return false
	var allowed: Array[MoveData.Kind] = []
	if move.kind == MoveData.Kind.NORMAL and move.special_cancel:
		allowed = KINDS_FROM_NORMAL
	elif move.kind == MoveData.Kind.SPECIAL and move.super_cancel:
		allowed = KINDS_FROM_SPECIAL
	if not allowed.is_empty():
		var command_move := _buffered_command_move(allowed)
		if command_move != null:
			_start_move(command_move)
			return true
	if move.cancel_into.is_empty():
		return false
	var stance := MoveData.Stance.CROUCH if input.down else MoveData.Stance.STAND
	for action in ATTACK_PRIORITY:
		if input.pressed_buffered(action):
			var candidate := data.find_move(action, stance)
			if candidate != null and move.cancel_into.has(candidate.id):
				input.consume(action)
				_start_move(candidate)
				return true
	return false


func _fire_move_events(move: MoveData) -> void:
	for index in move.events.size():
		if _events_fired.has(index):
			continue
		var event: Dictionary = move.events[index]
		if state_frame >= event.get("frame", 0):
			_events_fired[index] = true
			pending_events.append(event)


func charge_ratio() -> float:
	if current_move == null or current_move.charge_max_frames <= 0:
		return 0.0
	return clampf(float(charge_frames) / current_move.charge_max_frames, 0.0, 1.0)


func _step_block() -> void:
	velocity.x = 0.0
	if state_frame >= stun_frames:
		_enter_state(State.CROUCH if input.down else State.IDLE)
		_step_neutral()


func _step_hitstun() -> void:
	velocity.x = 0.0
	if state_frame >= stun_frames:
		_enter_state(State.CROUCH if input.down else State.IDLE)
		_step_neutral()


func _apply_physics() -> void:
	if airborne:
		velocity.y += data.gravity
	position += velocity + push_velocity
	var friction := GlobalTuning.AIR_KNOCKBACK_FRICTION if airborne else GlobalTuning.GROUND_KNOCKBACK_FRICTION
	push_velocity.x *= friction
	if absf(push_velocity.x) < 0.1:
		push_velocity.x = 0.0
	if airborne and position.y >= GlobalTuning.FLOOR_Y:
		position.y = GlobalTuning.FLOOR_Y
		_land()
	clamp_to_stage()


func _land() -> void:
	airborne = false
	velocity = Vector2.ZERO
	air_attack_used = false
	match state:
		State.ATTACK:
			landing_frames = GlobalTuning.ATTACK_LANDING_FRAMES
			current_move = null
			_enter_state(State.LANDING)
		State.AIR_HITSTUN:
			push_velocity.x *= 0.5
			_enter_state(State.KNOCKDOWN)
		State.KO:
			push_velocity.x = 0.0
		_:
			landing_frames = GlobalTuning.LANDING_FRAMES
			_enter_state(State.LANDING)


func clamp_to_stage() -> void:
	var half := _current_pushbox_local().size.x * 0.5
	var min_x := -GlobalTuning.STAGE_HALF_WIDTH + half
	var max_x := GlobalTuning.STAGE_HALF_WIDTH - half
	at_left_wall = position.x <= min_x + 0.5
	at_right_wall = position.x >= max_x - 0.5
	position.x = clampf(position.x, min_x, max_x)


func is_at_wall_in_direction(direction: int) -> bool:
	return at_right_wall if direction > 0 else at_left_wall


func can_turn() -> bool:
	if airborne:
		return false
	return state == State.IDLE or state == State.WALK or state == State.CROUCH or state == State.LANDING


func face_opponent() -> void:
	if opponent == null:
		return
	var delta := opponent.position.x - position.x
	if absf(delta) >= 1.0:
		facing = 1 if delta > 0 else -1


func is_crouching() -> bool:
	match state:
		State.CROUCH, State.BLOCK_CROUCH:
			return true
		State.ATTACK:
			return current_move != null and current_move.stance == MoveData.Stance.CROUCH
		State.HITSTUN:
			return hit_while_crouching
		_:
			return false


func is_invulnerable() -> bool:
	if hidden:
		return true
	match state:
		State.KNOCKDOWN, State.GETUP, State.KO:
			return true
		State.BACKDASH:
			return state_frame <= data.backdash_invuln_frames
		State.ATTACK:
			if current_move == null or current_move.invuln_start <= 0:
				return false
			return state_frame >= current_move.invuln_start and state_frame <= current_move.invuln_end
		_:
			return false


func is_stunned() -> bool:
	return state == State.HITSTUN or state == State.AIR_HITSTUN or state == State.KNOCKDOWN


func can_block(hit: HitInfo) -> bool:
	if hit.unblockable or airborne or not input.back:
		return false
	match state:
		State.IDLE, State.WALK, State.CROUCH, State.BLOCK_STAND, State.BLOCK_CROUCH, State.LANDING:
			pass
		_:
			return false
	if input.down:
		return hit.hit_height != MoveData.Height.HIGH
	return hit.hit_height != MoveData.Height.LOW


func enter_block(hit: HitInfo, direction_from_attacker: int) -> void:
	stun_frames = hit.blockstun
	velocity.x = 0.0
	push_velocity.x = direction_from_attacker * hit.block_pushback
	_enter_state(State.BLOCK_CROUCH if input.down else State.BLOCK_STAND)
	if hit.chip_damage > 0:
		health = maxi(health - hit.chip_damage, 0)
		if health <= 0:
			_enter_ko(hit, direction_from_attacker)


func take_hit(hit: HitInfo, direction_from_attacker: int, damage: int, hitstun: int) -> void:
	_interrupt()
	health = maxi(health - damage, 0)
	combo_hits += 1
	if hit.scales_combo:
		combo_scale_hits += 1
	meter = mini(meter + int(damage * GlobalTuning.METER_GAIN_ON_DAMAGE_TAKEN), GlobalTuning.METER_MAX)
	for module in modules:
		module.on_damage_taken(self, hit, damage)
	if health <= 0:
		_enter_ko(hit, direction_from_attacker)
		return
	if airborne or hit.launch:
		juggle_hits += 1
		airborne = true
		velocity.x = direction_from_attacker * hit.knockback.x
		if juggle_hits <= GlobalTuning.MAX_JUGGLE_HITS:
			velocity.y = hit.knockback.y if hit.launch else GlobalTuning.AIR_HIT_POP_VELOCITY
		push_velocity = Vector2.ZERO
		_enter_state(State.AIR_HITSTUN)
		return
	if hit.knockdown:
		velocity.x = 0.0
		push_velocity.x = direction_from_attacker * hit.knockback.x
		_enter_state(State.KNOCKDOWN)
		return
	stun_frames = hitstun
	velocity.x = 0.0
	push_velocity.x = direction_from_attacker * hit.knockback.x
	_enter_state(State.HITSTUN)


func _interrupt() -> void:
	var was_crouching := is_crouching()
	if current_move != null or hidden:
		for module in modules:
			module.on_interrupted(self)
	hit_while_crouching = was_crouching
	current_move = null
	charge_frames = 0
	hidden = false


func _enter_ko(hit: HitInfo, direction_from_attacker: int) -> void:
	current_move = null
	hidden = false
	airborne = true
	velocity = Vector2(direction_from_attacker * maxf(hit.knockback.x, 6.0), minf(hit.knockback.y, -9.0))
	push_velocity = Vector2.ZERO
	_enter_state(State.KO)


func gain_meter(amount: int) -> void:
	meter = mini(meter + amount, GlobalTuning.METER_MAX)


func apply_hitstop(frames: int) -> void:
	hitstop = maxi(hitstop, frames)


func _current_pushbox_local() -> Rect2:
	if airborne:
		return data.air_pushbox
	if is_crouching():
		return data.crouch_pushbox
	return data.stand_pushbox


func pushbox_world() -> Rect2:
	return to_world(_current_pushbox_local())


func has_pushbox() -> bool:
	return not hidden


func hurtboxes_world() -> Array[Rect2]:
	var boxes: Array[Rect2] = []
	if is_invulnerable():
		return boxes
	if airborne:
		boxes.append(to_world(data.air_hurtbox))
	elif is_crouching():
		boxes.append(to_world(data.crouch_hurtbox))
	else:
		boxes.append(to_world(data.stand_hurtbox))
	if state == State.ATTACK and current_move != null and current_move.is_extended_frame(state_frame):
		for rect in current_move.hurtbox_extra:
			boxes.append(to_world(rect))
	return boxes


func active_windows() -> Array[int]:
	var indices: Array[int] = []
	if state != State.ATTACK or current_move == null:
		return indices
	var windows := current_move.hit_windows()
	for index in windows.size():
		if windows_hit.has(index):
			continue
		if state_frame >= windows[index].start and state_frame <= windows[index].end:
			indices.append(index)
	return indices


func window_hitboxes_world(index: int) -> Array[Rect2]:
	var boxes: Array[Rect2] = []
	for rect in current_move.hit_windows()[index].hitboxes:
		boxes.append(to_world(rect))
	return boxes


func hitboxes_world() -> Array[Rect2]:
	var boxes: Array[Rect2] = []
	for index in active_windows():
		boxes.append_array(window_hitboxes_world(index))
	return boxes


func build_hit(window_index: int) -> HitInfo:
	var move := current_move
	var hit := HitInfo.from_move(move, move.hit_windows()[window_index].overrides)
	var ratio := charge_ratio()
	if ratio > 0.0:
		hit.damage += int(move.charge_damage_bonus * ratio)
		hit.knockback += move.charge_knockback_bonus * ratio
		if ratio >= 1.0 and move.charge_full_unblockable:
			hit.unblockable = true
	if move.cuts_projectiles:
		hit.ignores_armor = true
	for module in modules:
		module.modify_hit(self, hit)
	return hit


func to_world(rect: Rect2) -> Rect2:
	if facing > 0:
		return Rect2(position + rect.position, rect.size)
	var flipped_x := -(rect.position.x + rect.size.x)
	return Rect2(position.x + flipped_x, position.y + rect.position.y, rect.size.x, rect.size.y)


func play_cinematic(anim: String) -> void:
	cinematic_anim = anim
	if state == State.IDLE:
		state_frame = 0


func clear_cinematic() -> void:
	cinematic_anim = ""


func state_name() -> String:
	return STATE_NAMES.get(state, "?")


func hud_gauges() -> Array[Dictionary]:
	var gauges: Array[Dictionary] = []
	for module in modules:
		gauges.append_array(module.hud_gauges(self))
	return gauges


func _update_anim() -> void:
	var name := "idle"
	match state:
		State.IDLE:
			name = cinematic_anim if cinematic_anim != "" and data.animations.has(cinematic_anim) else "idle"
		State.WALK:
			name = "walk_forward" if velocity.x * facing > 0 else "walk_back"
		State.CROUCH:
			name = "crouch"
		State.JUMP:
			name = "jump" if airborne else "prejump"
		State.DASH:
			name = "dash"
		State.BACKDASH:
			name = "backdash"
		State.ATTACK:
			name = current_move.animation_name() if current_move != null else "idle"
		State.BLOCK_STAND:
			name = "block_stand"
		State.BLOCK_CROUCH:
			name = "block_crouch"
		State.HITSTUN:
			name = "hit_crouch" if hit_while_crouching else "hit_stand"
		State.AIR_HITSTUN:
			name = "hit_air"
		State.KNOCKDOWN:
			name = "knockdown"
		State.GETUP:
			name = "getup"
		State.LANDING:
			name = "landing"
		State.KO:
			name = "ko" if not airborne else "hit_air"
	anim_name = name
	anim_frame = state_frame
