class_name LayerChart
extends Control

var selected_direction: String = "long"
var _selection: int = 0     # 0 = Long, 1 = Short
var _stock: Dictionary = {}
var _market: StockMarket
var _engine: TradingEngine
var _high_vol_timer: SceneTreeTimer = null

@onready var _chart_node: CandlestickChart = $ChartNode
@onready var _stock_label: Label  = $Header/StockLabel
@onready var _price_label: Label  = $Header/PriceLabel
@onready var _long_lbl: Label     = $ButtonRow/LongBtn/Label
@onready var _short_lbl: Label    = $ButtonRow/ShortBtn/Label
@onready var _hv_panel: Panel     = $HighVolPanel
@onready var _hv_label: Label     = $HighVolPanel/Label
@onready var _hint_lbl: Label     = $HintLabel


func show_stock(stock: Dictionary, market: StockMarket, engine: TradingEngine) -> void:
	_stock  = stock
	_market = market
	_engine = engine

	# Restore direction lock if position exists
	if engine.has_position(stock["id"]):
		var pos: Dictionary = engine.get_position(stock["id"])
		selected_direction = pos["direction"]
		_selection = 0 if selected_direction == "long" else 1

	_refresh()


func _refresh() -> void:
	if _stock.is_empty():
		return

	_stock_label.text = _stock["name"]
	_price_label.text = "$%.2f" % _market.get_price(_stock["id"])

	var candles := _market.get_last_candles(_stock["id"], 15)
	_chart_node.current_trend      = _market.get_trend(_stock["id"])
	var pos: Dictionary = _engine.get_position(_stock["id"])
	_chart_node.position_direction = pos.get("direction", "") if not pos.is_empty() else ""
	_chart_node.entry_price        = pos.get("entry_price", 0.0) if not pos.is_empty() else 0.0
	_chart_node.set_candles(candles)

	_update_direction_highlight()
	if not pos.is_empty():
		var pnl := _engine.get_floating_pnl(_stock["id"])
		var pct := _engine.get_floating_pnl_pct(_stock["id"])
		_hint_lbl.text = "Pos: %s x%d  P&L: $%.2f (%.1f%%)  [Z]Order [X]Back" % [
			pos["direction"].to_upper(), pos["shares"], pnl, pct
		]
	else:
		_hint_lbl.text = "[Z]Select Direction → Confirm  [X]Back"


func move_selection(dir: int) -> void:
	var pos: Dictionary = _engine.get_position(_stock["id"])
	if not pos.is_empty():
		# Locked to existing direction; cannot switch
		return
	_selection = clamp(_selection + dir, 0, 1)
	selected_direction = "long" if _selection == 0 else "short"
	_update_direction_highlight()


func show_high_volume(direction: String, reversal_prob: float) -> void:
	_hv_panel.visible = true
	_hv_label.text    = "High Vol  Trend: %s  Rev: %.0f%%" % [direction, reversal_prob * 100.0]
	_chart_node.show_high_volume(direction, reversal_prob)
	# Auto-hide on next candle (4 s)
	_high_vol_timer = get_tree().create_timer(4.0)
	_high_vol_timer.timeout.connect(_hide_hv)


func _hide_hv() -> void:
	_hv_panel.visible = false
	_chart_node.hide_high_volume()


func _update_direction_highlight() -> void:
	var pos: Dictionary = _engine.get_position(_stock["id"]) if _engine else {}
	var locked := not pos.is_empty()

	_long_lbl.text  = "> Long <" if _selection == 0 else "  Long  "
	_short_lbl.text = "> Short <" if _selection == 1 else "  Short  "

	var active_col := Color(0.90, 0.85, 0.15)
	var idle_col   := Color(0.45, 0.45, 0.45)
	var lock_col   := Color(0.25, 0.25, 0.25)

	if locked:
		_long_lbl.add_theme_color_override("font_color",
			active_col if pos["direction"] == "long" else lock_col)
		_short_lbl.add_theme_color_override("font_color",
			active_col if pos["direction"] == "short" else lock_col)
	else:
		_long_lbl.add_theme_color_override("font_color",
			active_col if _selection == 0 else idle_col)
		_short_lbl.add_theme_color_override("font_color",
			active_col if _selection == 1 else idle_col)
