class_name HUDController
extends CanvasLayer

@onready var _balance_lbl: Label      = $Root/TopBar/BalanceLabel
@onready var _time_lbl: Label         = $Root/TopBar/TimeLabel
@onready var _eye_rect: TextureRect   = $Root/StatusBar/EyeIcon
@onready var _susp_gauge: HBoxContainer = $Root/StatusBar/SuspicionGauge
@onready var _bar1: ColorRect         = $Root/StatusBar/SuspicionGauge/Bar1
@onready var _bar2: ColorRect         = $Root/StatusBar/SuspicionGauge/Bar2

var _tex_eye_open: Texture2D
var _tex_eye_closed: Texture2D
var _pulse_tween: Tween = null


func _ready() -> void:
	_tex_eye_open   = load("res://assets/sprites/eye_open.png")
	_tex_eye_closed = load("res://assets/sprites/eye_closed.png")
	_susp_gauge.visible = false
	set_eye_open(false)


func enable_suspicion_gauge() -> void:
	_susp_gauge.visible = true


func set_eye_open(open: bool) -> void:
	if open:
		_eye_rect.texture  = _tex_eye_open
		_eye_rect.modulate = Color(1, 0.3, 0.3)
		_start_pulse()
	else:
		_eye_rect.texture  = _tex_eye_closed
		_eye_rect.modulate = Color.WHITE
		_stop_pulse()


func _start_pulse() -> void:
	if _pulse_tween:
		_pulse_tween.kill()
	_pulse_tween = create_tween().set_loops()
	_pulse_tween.tween_property(_eye_rect, "modulate:a", 0.3, 0.22)
	_pulse_tween.tween_property(_eye_rect, "modulate:a", 1.0, 0.22)


func _stop_pulse() -> void:
	if _pulse_tween:
		_pulse_tween.kill()
		_pulse_tween = null
	_eye_rect.modulate.a = 1.0


func update_balance(balance: float) -> void:
	_balance_lbl.text = "Bal $%.0f" % balance


func update_time(seconds: float) -> void:
	var m := int(seconds) / 60
	var s := int(seconds) % 60
	_time_lbl.text = "%02d:%02d" % [m, s]


func update_suspicion(gauge: int) -> void:
	_bar1.modulate.a = 1.0 if gauge >= 1 else 0.2
	_bar2.modulate.a = 1.0 if gauge >= 2 else 0.2


