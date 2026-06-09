class_name WifeAlertSystem
extends Node

signal wife_turned()
signal wife_looked_away()
signal qte_triggered()
signal game_over_caught()
signal suspicion_depleted()

enum State { IDLE, RESPONSE_WINDOW, GAZE, QTE_ACTIVE }

var state: State = State.IDLE
var suspicion_gauge: int = 2

# Difficulty config
var turn_min: float = 25.0
var turn_max: float = 30.0
var gaze_min: float = 4.0
var gaze_max: float = 8.0
var qte_chance: float = 0.0
var stage3: bool = false

var _is_phone_hidden: bool = false

var _turn_timer: Timer
var _response_timer: Timer   # 0.5 s window after wife turns
var _gaze_timer: Timer
var _qte_delay_timer: Timer


func _ready() -> void:
	_turn_timer = _make_timer(0.0, true, _on_turn_elapsed)
	_response_timer = _make_timer(0.5, true, _on_response_elapsed)
	_gaze_timer = _make_timer(0.0, true, _on_gaze_elapsed)
	_qte_delay_timer = _make_timer(0.0, true, _on_qte_delay_elapsed)


func _make_timer(wait: float, one_shot: bool, callback: Callable) -> Timer:
	var t := Timer.new()
	t.wait_time = max(0.1, wait)
	t.one_shot = one_shot
	t.timeout.connect(callback)
	add_child(t)
	return t


# --- Public API ---

func configure_low() -> void:
	turn_min = 25.0; turn_max = 30.0
	gaze_min = 4.0;  gaze_max = 8.0
	qte_chance = 0.0; stage3 = false

func configure_medium() -> void:
	turn_min = 15.0; turn_max = 20.0
	gaze_min = 6.0;  gaze_max = 8.0
	qte_chance = 0.0; stage3 = false

func configure_high() -> void:
	turn_min = 8.0;  turn_max = 12.0
	gaze_min = 6.0;  gaze_max = 8.0
	qte_chance = 0.8; stage3 = true


func start() -> void:
	_is_phone_hidden = false
	state = State.IDLE
	suspicion_gauge = 2
	_schedule_turn()


func stop() -> void:
	_turn_timer.stop()
	_response_timer.stop()
	_gaze_timer.stop()
	_qte_delay_timer.stop()
	state = State.IDLE


func notify_phone_hidden() -> void:
	_is_phone_hidden = true


func notify_phone_shown() -> void:
	_is_phone_hidden = false
	if state == State.GAZE or state == State.QTE_ACTIVE:
		game_over_caught.emit()


func on_qte_success() -> void:
	if state != State.QTE_ACTIVE:
		return
	state = State.IDLE
	_gaze_timer.stop()
	wife_looked_away.emit()
	_schedule_turn()


func on_qte_fail() -> void:
	if state != State.QTE_ACTIVE:
		return
	suspicion_gauge -= 1
	if suspicion_gauge <= 0:
		suspicion_depleted.emit()
	else:
		# Resume gaze
		state = State.GAZE
		_gaze_timer.paused = false


func get_suspicion() -> int:
	return suspicion_gauge


# --- Internals ---

func _schedule_turn() -> void:
	_turn_timer.wait_time = randf_range(turn_min, turn_max)
	_turn_timer.start()


func _on_turn_elapsed() -> void:
	state = State.RESPONSE_WINDOW
	wife_turned.emit()
	AudioManager.play_alert()
	_response_timer.wait_time = 0.5
	_response_timer.start()


func _on_response_elapsed() -> void:
	if not _is_phone_hidden:
		state = State.IDLE
		game_over_caught.emit()
	else:
		state = State.GAZE
		_start_gaze()


func _start_gaze() -> void:
	_gaze_timer.wait_time = randf_range(gaze_min, gaze_max)
	_gaze_timer.start()
	if stage3 and qte_chance > 0.0:
		_qte_delay_timer.wait_time = randf_range(1.0, 2.0)
		_qte_delay_timer.start()


func _on_gaze_elapsed() -> void:
	_qte_delay_timer.stop()
	state = State.IDLE
	wife_looked_away.emit()
	_schedule_turn()


func _on_qte_delay_elapsed() -> void:
	if state == State.GAZE and randf() < qte_chance:
		state = State.QTE_ACTIVE
		_gaze_timer.paused = true
		qte_triggered.emit()
