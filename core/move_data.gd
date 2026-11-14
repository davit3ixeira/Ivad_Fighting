class_name MoveData
extends Resource

enum Stance { STAND, CROUCH, AIR }
enum Height { HIGH, MID, LOW }
enum Kind { NORMAL, SPECIAL, SUPER, UNIQUE }

var id: String = ""
var display_name: String = ""
var kind: Kind = Kind.NORMAL
var button: ButtonMap.Action = ButtonMap.Action.LIGHT_PUNCH
var motion: CommandParser.Motion = CommandParser.Motion.NONE
var stance: Stance = Stance.STAND
var meter_cost: int = 0
var startup: int = 4
var active: int = 3
var recovery: int = 8
var damage: int = 40
var chip_damage: int = 0
var hitstun: int = 14
var blockstun: int = 9
var hitstop: int = 6
var hit_height: Height = Height.MID
var knockback: Vector2 = Vector2(6, 0)
var block_pushback: float = 5.0
var launch: bool = false
var knockdown: bool = false
var unblockable: bool = false
var scales_combo: bool = true
var meter_gain: int = 30
var effect: String = ""
var hitboxes: Array[Rect2] = []
var hurtbox_extra: Array[Rect2] = []
var windows: Array[HitWindow] = []
var cancel_into: Array[String] = []
var special_cancel: bool = false
var super_cancel: bool = false
var cuts_projectiles: bool = false
var grab: bool = false
var link_on_hit: String = ""
var hold_on_link: bool = false
var holds_target: bool = false
var followup: bool = false
var hold_offset: Vector2 = Vector2(60, 0)
var armor_start: int = 0
var armor_end: int = 0
var armor_hits: int = 0
var stop_on_contact: bool = false
var advance: float = 0.0
var advance_start: int = 0
var advance_frames: int = 0
var invuln_start: int = 0
var invuln_end: int = 0
var charge_frame: int = 0
var charge_max_frames: int = 0
var charge_damage_bonus: int = 0
var charge_knockback_bonus: Vector2 = Vector2.ZERO
var charge_full_unblockable: bool = false
var charge_joint: String = "hand_n"
var super_freeze: int = 0
var super_freeze_frame: int = 1
var events: Array[Dictionary] = []
var animation: String = ""

var _default_windows: Array[HitWindow] = []


func total_frames() -> int:
	return startup + active + recovery


func hit_windows() -> Array[HitWindow]:
	if not windows.is_empty():
		return windows
	if _default_windows.is_empty() and not hitboxes.is_empty():
		var window := HitWindow.new()
		window.start = startup + 1
		window.end = startup + active
		window.hitboxes = hitboxes
		_default_windows.append(window)
	return _default_windows


func first_active_frame() -> int:
	var first := startup + 1
	for window in hit_windows():
		first = mini(first, window.start)
	return first


func is_active_frame(frame: int) -> bool:
	for window in hit_windows():
		if frame >= window.start and frame <= window.end:
			return true
	return false


func is_extended_frame(frame: int) -> bool:
	return frame > 1 and frame <= startup + active + 2


func phase_name(frame: int) -> String:
	if frame <= startup:
		return "startup %d/%d" % [frame, startup]
	if frame <= startup + active:
		return "active %d/%d" % [frame - startup, active]
	return "recovery %d/%d" % [frame - startup - active, recovery]


func animation_name() -> String:
	return animation if animation != "" else id
