class_name DebugOverlay
extends Node2D

const PUSHBOX_COLOR := Color(0.3, 0.5, 1.0)
const HURTBOX_COLOR := Color(0.2, 1.0, 0.4)
const HITBOX_COLOR := Color(1.0, 0.15, 0.15)
const FILL_ALPHA := 0.22

var sim: FightSim
var last_contact_text: String = "-"

var _label: Label


func _ready() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	_label = Label.new()
	_label.position = Vector2(16, 110)
	_label.add_theme_font_size_override("font_size", 14)
	_label.add_theme_color_override("font_color", Color(0.9, 1.0, 0.9))
	_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_label.add_theme_constant_override("outline_size", 4)
	layer.add_child(_label)
	set_enabled(false)


func bind(target: FightSim) -> void:
	sim = target
	sim.hit_landed.connect(_on_hit_landed)
	sim.hit_blocked.connect(_on_hit_blocked)


func set_enabled(enabled: bool) -> void:
	visible = enabled
	_label.visible = enabled


func toggle() -> void:
	set_enabled(not visible)


func refresh() -> void:
	if not visible or sim == null:
		return
	_label.text = _build_text()
	queue_redraw()


func _draw() -> void:
	if sim == null:
		return
	for fighter in sim.fighters:
		_draw_box(fighter.pushbox_world(), PUSHBOX_COLOR, false)
		for rect in fighter.hurtboxes_world():
			_draw_box(rect, HURTBOX_COLOR, true)
		for rect in fighter.hitboxes_world():
			_draw_box(rect, HITBOX_COLOR, true)
		draw_line(fighter.position + Vector2(-8, 0), fighter.position + Vector2(8, 0), Color.WHITE, 2.0)
		draw_line(fighter.position + Vector2(0, -8), fighter.position + Vector2(0, 8), Color.WHITE, 2.0)


func _draw_box(rect: Rect2, color: Color, filled: bool) -> void:
	if filled:
		draw_rect(rect, Color(color, FILL_ALPHA))
	draw_rect(rect, color, false, 2.0)


func _build_text() -> String:
	var lines: Array[String] = []
	lines.append("frame %d   FPS %d   boneco: %s" % [sim.frame, Engine.get_frames_per_second(), sim.dummy_mode_name()])
	lines.append("F1 debug   F2 boneco   F3 modo do boneco   F4 reiniciar   F11 tela cheia")
	lines.append("ultimo contato: %s" % last_contact_text)
	for fighter in sim.fighters:
		lines.append("")
		lines.append("P%d %s   %s f%d   vida %d   poder %d   combo %d   hitstop %d" % [
			fighter.slot + 1, fighter.data.display_name, fighter.state_name(), fighter.state_frame,
			fighter.health, fighter.meter, fighter.combo_hits, fighter.hitstop,
		])
		lines.append("   pos (%.0f, %.0f)   vel (%.1f, %.1f)   push %.1f   lado %d   entrada: %s" % [
			fighter.position.x, fighter.position.y, fighter.velocity.x, fighter.velocity.y,
			fighter.push_velocity.x, fighter.facing, sim.last_snapshots[fighter.slot].describe(),
		])
		var move := fighter.current_move
		if fighter.state == Fighter.State.ATTACK and move != null:
			lines.append("   golpe %s (%s)   %s   S%d A%d R%d   dano %d   hitstun %d   blockstun %d" % [
				move.id, move.display_name, move.phase_name(fighter.state_frame),
				move.startup, move.active, move.recovery, move.damage, move.hitstun, move.blockstun,
			])
		else:
			lines.append("   golpe -")
	return "\n".join(lines)


func _on_hit_landed(attacker: Fighter, defender: Fighter, move: MoveData, _point: Vector2, damage: int) -> void:
	last_contact_text = "P%d acertou %s   dano %d   vantagem %s" % [attacker.slot + 1, move.id, damage, _advantage_text(attacker, defender, move)]


func _on_hit_blocked(attacker: Fighter, defender: Fighter, move: MoveData, _point: Vector2) -> void:
	last_contact_text = "P%d teve %s defendido   vantagem %s" % [attacker.slot + 1, move.id, _advantage_text(attacker, defender, move)]


func _advantage_text(attacker: Fighter, defender: Fighter, move: MoveData) -> String:
	if attacker.airborne:
		return "aereo"
	if defender.state != Fighter.State.HITSTUN and defender.state != Fighter.State.BLOCK_STAND and defender.state != Fighter.State.BLOCK_CROUCH:
		return "derruba"
	var attacker_remaining := move.total_frames() - attacker.state_frame
	var advantage := defender.stun_frames - attacker_remaining
	return "%+d" % advantage
