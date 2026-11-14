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

var data: CharacterData
var slot: int = 0
var opponent: Fighter
var position: Vector2 = Vector2.ZERO
var velocity: Vector2 = Vector2.ZERO
var push_velocity: Vector2 = Vector2.ZERO
var facing: int = 1
var airborne: bool = false
var state: State = State.IDLE
var state_frame: int = 0
var health: int = 1000
var meter: int = 0
var current_move: MoveData
var move_hit_done: bool = false
var move_hit_landed: bool = false
var stun_frames: int = 0
var combo_hits: int = 0
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
	combo_hits = 0
	juggle_hits = 0
	hitstop = 0
	current_move = null
	input = InputBuffer.new()
	_enter_state(State.IDLE)
	_update_anim()


func begin_frame(snapshot: InputSnapshot) -> void:
	input.update(snapshot, facing)


func step() -> void:
	if hitstop > 0:
		hitstop -= 1
		return
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
	state_frame += 1


func _enter_state(new_state: State) -> void:
	state = new_state
	state_frame = 0


func _set_state_keep_frame(new_state: State) -> void:
	if state != new_state:
		_enter_state(new_state)


func _step_neutral() -> void:
	combo_hits = 0
	juggle_hits = 0
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


func _start_move(move: MoveData) -> void:
	current_move = move
	move_hit_done = false
	move_hit_landed = false
	if not airborne:
		velocity.x = 0.0
	else:
		air_attack_used = true
	_enter_state(State.ATTACK)


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
	if not air_attack_used:
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
	if airborne:
		return
	if state_frame >= move.total_frames():
		velocity.x = 0.0
		_enter_state(State.CROUCH if input.down else State.IDLE)
		_step_neutral()
		return
	if move_hit_landed and state_frame > move.startup and not move.cancel_into.is_empty():
		var stance := MoveData.Stance.CROUCH if move.stance == MoveData.Stance.CROUCH else MoveData.Stance.STAND
		if input.down:
			stance = MoveData.Stance.CROUCH
		for action in ATTACK_PRIORITY:
			if input.pressed_buffered(action):
				var candidate := data.find_move(action, stance)
				if candidate != null and move.cancel_into.has(candidate.id):
					input.consume(action)
					_start_move(candidate)
					return
	if state_frame <= move.advance_frames:
		velocity.x = facing * move.advance
	else:
		velocity.x = 0.0


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
	match state:
		State.KNOCKDOWN, State.GETUP, State.KO:
			return true
		State.BACKDASH:
			return state_frame <= data.backdash_invuln_frames
		_:
			return false


func can_block(height: MoveData.Height) -> bool:
	if airborne or not input.back:
		return false
	match state:
		State.IDLE, State.WALK, State.CROUCH, State.BLOCK_STAND, State.BLOCK_CROUCH, State.LANDING:
			pass
		_:
			return false
	if input.down:
		return height != MoveData.Height.HIGH
	return height != MoveData.Height.LOW


func enter_block(move: MoveData, direction_from_attacker: int) -> void:
	stun_frames = move.blockstun
	velocity.x = 0.0
	push_velocity.x = direction_from_attacker * move.block_pushback
	_enter_state(State.BLOCK_CROUCH if input.down else State.BLOCK_STAND)


func take_hit(move: MoveData, direction_from_attacker: int, damage: int, hitstun: int) -> void:
	health = maxi(health - damage, 0)
	combo_hits += 1
	meter = mini(meter + int(damage * GlobalTuning.METER_GAIN_ON_DAMAGE_TAKEN), GlobalTuning.METER_MAX)
	if health <= 0:
		_enter_ko(move, direction_from_attacker)
		return
	if airborne or move.launch:
		juggle_hits += 1
		airborne = true
		velocity.x = direction_from_attacker * move.knockback.x
		if juggle_hits <= GlobalTuning.MAX_JUGGLE_HITS:
			velocity.y = move.knockback.y if move.launch else GlobalTuning.AIR_HIT_POP_VELOCITY
		push_velocity = Vector2.ZERO
		current_move = null
		_enter_state(State.AIR_HITSTUN)
		return
	if move.knockdown:
		velocity.x = 0.0
		push_velocity.x = direction_from_attacker * move.knockback.x
		current_move = null
		_enter_state(State.KNOCKDOWN)
		return
	hit_while_crouching = is_crouching()
	stun_frames = hitstun
	velocity.x = 0.0
	push_velocity.x = direction_from_attacker * move.knockback.x
	current_move = null
	_enter_state(State.HITSTUN)


func _enter_ko(move: MoveData, direction_from_attacker: int) -> void:
	current_move = null
	airborne = true
	velocity = Vector2(direction_from_attacker * maxf(move.knockback.x, 6.0), minf(move.knockback.y, -9.0))
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


func hitboxes_world() -> Array[Rect2]:
	var boxes: Array[Rect2] = []
	if state != State.ATTACK or current_move == null or move_hit_done:
		return boxes
	if not current_move.is_active_frame(state_frame):
		return boxes
	for rect in current_move.hitboxes:
		boxes.append(to_world(rect))
	return boxes


func to_world(rect: Rect2) -> Rect2:
	if facing > 0:
		return Rect2(position + rect.position, rect.size)
	var flipped_x := -(rect.position.x + rect.size.x)
	return Rect2(position.x + flipped_x, position.y + rect.position.y, rect.size.x, rect.size.y)


func state_name() -> String:
	return STATE_NAMES.get(state, "?")


func _update_anim() -> void:
	var name := "idle"
	match state:
		State.IDLE:
			name = "idle"
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
