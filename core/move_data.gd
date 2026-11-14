class_name MoveData
extends Resource

enum Stance { STAND, CROUCH, AIR }
enum Height { HIGH, MID, LOW }

var id: String = ""
var display_name: String = ""
var button: ButtonMap.Action = ButtonMap.Action.LIGHT_PUNCH
var stance: Stance = Stance.STAND
var startup: int = 4
var active: int = 3
var recovery: int = 8
var damage: int = 40
var hitstun: int = 14
var blockstun: int = 9
var hitstop: int = 6
var hit_height: Height = Height.MID
var knockback: Vector2 = Vector2(6, 0)
var block_pushback: float = 5.0
var launch: bool = false
var knockdown: bool = false
var meter_gain: int = 30
var hitboxes: Array[Rect2] = []
var hurtbox_extra: Array[Rect2] = []
var cancel_into: Array[String] = []
var advance: float = 0.0
var advance_frames: int = 0
var animation: String = ""


func total_frames() -> int:
	return startup + active + recovery


func is_active_frame(frame: int) -> bool:
	return frame > startup and frame <= startup + active


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
