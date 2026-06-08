class_name HUDController
extends CanvasLayer

@onready var _balance_lbl: Label    = $Root/TopBar/BalanceLabel
@onready var _time_lbl: Label       = $Root/TopBar/TimeLabel
@onready var _realized_lbl: Label   = $Root/RightPanel/RealizedLabel
@onready var _pos_list: VBoxContainer = $Root/RightPanel/PosList
@onready var _eye_rect: TextureRect  = $Root/StatusBar/EyeIcon
@onready var _susp_gauge: HBoxContainer = $Root/StatusBar/SuspicionGauge
@onready var _bar1: ColorRect       = $Root/StatusBar/SuspicionGauge/Bar1
@onready var _bar2: ColorRect       = $Root/StatusBar/SuspicionGauge/Bar2


var _tex_eye_open: Texture2D
var _tex_eye_closed: Texture2D


func _ready() -> void:
	_tex_eye_open   = load("res://assets/sprites/eye_open.png")
	_tex_eye_closed = load("res://assets/sprites/eye_closed.png")
	_susp_gauge.visible = false
	set_eye_open(false)


func enable_suspicion_gauge() -> void:
	_susp_gauge.visible = true


func set_eye_open(open: bool) -> void:
	if open:
		_eye_rect.texture = _tex_eye_open
		_eye_rect.modulate = Color(1, 0.3, 0.3)
	else:
		_eye_rect.texture = _tex_eye_closed
		_eye_rect.modulate = Color.WHITE


func update_balance(balance: float) -> void:
	_balance_lbl.text = "Bal $%.0f" % balance


func update_time(seconds: float) -> void:
	var m := int(seconds) / 60
	var s := int(seconds) % 60
	_time_lbl.text = "%02d:%02d" % [m, s]


func update_realized(pnl: float) -> void:
	var sign := "+" if pnl >= 0 else ""
	_realized_lbl.text = "P&L %s$%.0f" % [sign, pnl]
	_realized_lbl.add_theme_color_override("font_color",
		Color.GREEN if pnl >= 0 else Color.RED)


func update_suspicion(gauge: int) -> void:
	_bar1.modulate.a = 1.0 if gauge >= 1 else 0.2
	_bar2.modulate.a = 1.0 if gauge >= 2 else 0.2


func update_positions(stocks: Array[Dictionary], engine: TradingEngine, market: StockMarket) -> void:
	for c in _pos_list.get_children():
		c.queue_free()

	for s in stocks:
		if not engine.has_position(s["id"]):
			continue
		var pos    := engine.get_position(s["id"])
		var price  := market.get_price(s["id"])
		var pct    := engine.get_floating_pnl_pct(s["id"])
		var sign   := "+" if pct >= 0 else ""

		var lbl := Label.new()
		lbl.add_theme_font_size_override("font_size", 9)
		var dir_icon := "▲" if pos["direction"] == "long" else "▼"
		lbl.text = "%s%s x%d $%.0f %s%.1f%%" % [
			s["name"], dir_icon, pos["shares"], price, sign, pct
		]
		lbl.add_theme_color_override("font_color", Color.GREEN if pct >= 0 else Color.RED)
		_pos_list.add_child(lbl)
