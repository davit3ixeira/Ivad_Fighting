extends Node

const SFX_DIR := "res://audio/sfx"
const PLAYER_POOL_SIZE := 8
const TEST_BEEP_SAMPLE_RATE := 22050
const TEST_BEEP_SECONDS := 0.06

var test_beeps_enabled: bool = false

var _streams: Dictionary = {}
var _beeps: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _next_player: int = 0


func _ready() -> void:
	for i in PLAYER_POOL_SIZE:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_players.append(player)
	_scan_sfx()


func _scan_sfx() -> void:
	var dir := DirAccess.open(SFX_DIR)
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and (file_name.ends_with(".wav") or file_name.ends_with(".ogg")):
			var stream := load("%s/%s" % [SFX_DIR, file_name])
			if stream != null:
				_streams[file_name.get_basename()] = stream
		file_name = dir.get_next()
	dir.list_dir_end()


func play_sfx(sfx_name: String, volume_db: float = 0.0) -> void:
	var stream: AudioStream = _streams.get(sfx_name)
	if stream == null and test_beeps_enabled:
		stream = _beep_for(sfx_name)
	if stream == null:
		return
	var player := _players[_next_player]
	_next_player = (_next_player + 1) % _players.size()
	player.stream = stream
	player.volume_db = volume_db
	player.play()


func _beep_for(sfx_name: String) -> AudioStream:
	if _beeps.has(sfx_name):
		return _beeps[sfx_name]
	var frequency := 220.0 + float(absi(sfx_name.hash()) % 900)
	var sample_count := int(TEST_BEEP_SAMPLE_RATE * TEST_BEEP_SECONDS)
	var bytes := PackedByteArray()
	bytes.resize(sample_count * 2)
	for i in sample_count:
		var t := float(i) / TEST_BEEP_SAMPLE_RATE
		var envelope := 1.0 - float(i) / sample_count
		var value := int(sin(TAU * frequency * t) * envelope * 12000.0)
		bytes.encode_s16(i * 2, value)
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = TEST_BEEP_SAMPLE_RATE
	wav.stereo = false
	wav.data = bytes
	_beeps[sfx_name] = wav
	return wav
