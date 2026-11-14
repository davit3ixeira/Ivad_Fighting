class_name ButtonMap
extends RefCounted

enum Action { LIGHT_PUNCH, HEAVY_PUNCH, LIGHT_KICK, HEAVY_KICK, SPECIAL, PAUSE }

const ACTION_NAMES_PT := {
	Action.LIGHT_PUNCH: "Soco fraco",
	Action.HEAVY_PUNCH: "Soco forte",
	Action.LIGHT_KICK: "Chute fraco",
	Action.HEAVY_KICK: "Chute forte",
	Action.SPECIAL: "Habilidade",
	Action.PAUSE: "Pausa",
}

const JOYPAD := {
	Action.LIGHT_PUNCH: JOY_BUTTON_X,
	Action.HEAVY_PUNCH: JOY_BUTTON_Y,
	Action.LIGHT_KICK: JOY_BUTTON_A,
	Action.HEAVY_KICK: JOY_BUTTON_B,
	Action.SPECIAL: JOY_BUTTON_RIGHT_SHOULDER,
	Action.PAUSE: JOY_BUTTON_START,
}

const JOYPAD_DPAD := {
	"up": JOY_BUTTON_DPAD_UP,
	"down": JOY_BUTTON_DPAD_DOWN,
	"left": JOY_BUTTON_DPAD_LEFT,
	"right": JOY_BUTTON_DPAD_RIGHT,
}

const JOYPAD_STICK_X := JOY_AXIS_LEFT_X
const JOYPAD_STICK_Y := JOY_AXIS_LEFT_Y

const KEYBOARD_P1 := {
	"up": KEY_W,
	"down": KEY_S,
	"left": KEY_A,
	"right": KEY_D,
	Action.LIGHT_PUNCH: KEY_J,
	Action.HEAVY_PUNCH: KEY_U,
	Action.LIGHT_KICK: KEY_K,
	Action.HEAVY_KICK: KEY_I,
	Action.SPECIAL: KEY_L,
	Action.PAUSE: KEY_ESCAPE,
}

const KEYBOARD_P2 := {
	"up": KEY_UP,
	"down": KEY_DOWN,
	"left": KEY_LEFT,
	"right": KEY_RIGHT,
	Action.LIGHT_PUNCH: KEY_KP_1,
	Action.HEAVY_PUNCH: KEY_KP_4,
	Action.LIGHT_KICK: KEY_KP_2,
	Action.HEAVY_KICK: KEY_KP_5,
	Action.SPECIAL: KEY_KP_3,
	Action.PAUSE: KEY_ESCAPE,
}

const KEY_FULLSCREEN := KEY_F11
const KEY_DEBUG_OVERLAY := KEY_F1
const KEY_TRAINING_DUMMY := KEY_F2
const KEY_DUMMY_MODE := KEY_F3
const KEY_RESET_ROUND := KEY_F4
const KEY_CYCLE_P1_CHARACTER := KEY_F5
const KEY_CYCLE_P2_CHARACTER := KEY_F6
const KEY_FILL_METER := KEY_F7

const DEFAULT_DEADZONE := 0.45
const PREFER_DIGITAL_DPAD := true


static func action_name(action: Action) -> String:
	return ACTION_NAMES_PT.get(action, "?")
