extends Node

# Audio bus names
const BUS_MASTER := "Master"
const BUS_BGM := "BGM"
const BUS_SFX := "SFX"

var _bgm_player: AudioStreamPlayer
var _sfx_player: AudioStreamPlayer

# Track which bgm is playing to avoid restart
var _current_bgm: String = ""


func _ready() -> void:
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.bus = BUS_BGM if AudioServer.get_bus_index(BUS_BGM) >= 0 else BUS_MASTER
	add_child(_bgm_player)

	_sfx_player = AudioStreamPlayer.new()
	_sfx_player.bus = BUS_SFX if AudioServer.get_bus_index(BUS_SFX) >= 0 else BUS_MASTER
	add_child(_sfx_player)


func play_bgm(path: String) -> void:
	if path == _current_bgm:
		return
	_current_bgm = path
	if ResourceLoader.exists(path):
		_bgm_player.stream = load(path)
		_bgm_player.play()


func stop_bgm() -> void:
	_bgm_player.stop()
	_current_bgm = ""


func play_sfx(path: String) -> void:
	if ResourceLoader.exists(path):
		_sfx_player.stream = load(path)
		_sfx_player.play()


func play_alert() -> void:
	play_sfx("res://assets/music/sfx_alert.wav")


func play_qte_success() -> void:
	play_sfx("res://assets/music/sfx_qte_success.wav")


func play_qte_fail() -> void:
	play_sfx("res://assets/music/sfx_qte_fail.wav")


func play_game_over() -> void:
	play_sfx("res://assets/music/sfx_gameover.wav")


func play_win() -> void:
	play_sfx("res://assets/music/sfx_win.wav")
