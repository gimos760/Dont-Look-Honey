class_name LayerConfirm
extends Control

# Options: 0 = Confirm Order, 1 = Add 1 Share, 2 = Back
var selected_option: int = 0

var _stock: Dictionary = {}
var _direction: String = "long"
var _market: StockMarket
var _engine: TradingEngine

@onready var _name_lbl: Label    = $InfoBox/NameLabel
@onready var _dir_lbl: Label     = $InfoBox/DirLabel
@onready var _price_lbl: Label   = $InfoBox/PriceLabel
@onready var _cost_lbl: Label    = $InfoBox/CostLabel
@onready var _opt0: Label        = $Options/Opt0
@onready var _opt1: Label        = $Options/Opt1
@onready var _opt2: Label        = $Options/Opt2


func show_confirm(stock: Dictionary, direction: String, market: StockMarket, engine: TradingEngine) -> void:
	_stock     = stock
	_direction = direction
	_market    = market
	_engine    = engine
	# Start on the enabled option
	selected_option = 1 if _engine.has_position(_stock["id"]) else 0
	_refresh()


func move_selection(dir: int) -> void:
	var has_pos := _engine.has_position(_stock["id"])
	# Allowed options based on position state
	var allowed: Array[int] = []
	if has_pos:
		allowed = [1, 2]
	else:
		allowed = [0, 2]
	var idx := allowed.find(selected_option)
	if idx == -1:
		idx = 0
	idx = clamp(idx + dir, 0, allowed.size() - 1)
	selected_option = allowed[idx]
	_refresh_selection()


func _refresh() -> void:
	if _stock.is_empty():
		return
	var price := _market.get_price(_stock["id"])
	var pos   := _engine.get_position(_stock["id"])

	_name_lbl.text  = _stock["name"]
	var dir_str := Loc.t("dir_long") if _direction == "long" else Loc.t("dir_short")
	_dir_lbl.text   = Loc.t("lc_direction") % dir_str
	_dir_lbl.add_theme_color_override("font_color",
		Color.GREEN if _direction == "long" else Color.RED)
	_price_lbl.text = Loc.t("lc_price") % price
	_cost_lbl.text  = Loc.t("lc_cost") % price

	_refresh_selection()


func _refresh_selection() -> void:
	var has_pos := _engine.has_position(_stock["id"]) if _engine else false
	var at_max: bool = has_pos and _engine.get_position(_stock["id"]).get("shares", 0) >= TradingEngine.MAX_ADDS
	var opts := [_opt0, _opt1, _opt2]
	for i in range(opts.size()):
		# opt0 disabled when has position; opt1 disabled when no position or at max shares
		var disabled: bool = (i == 0 and has_pos) or (i == 1 and (not has_pos or at_max))
		if disabled:
			opts[i].add_theme_color_override("font_color", Color(0.45, 0.45, 0.45, 0.5))
			opts[i].text = "  " + _base_text(i) + "  "
		elif selected_option == i:
			opts[i].add_theme_color_override("font_color", Color(0.95, 0.85, 0.15))
			opts[i].text = "> " + _base_text(i) + " <"
		else:
			opts[i].add_theme_color_override("font_color", Color(0.65, 0.65, 0.65))
			opts[i].text = "  " + _base_text(i) + "  "


func _base_text(i: int) -> String:
	match i:
		0: return Loc.t("lc_confirm")
		1:
			var pos: Dictionary = _engine.get_position(_stock["id"]) if _engine else {}
			var shares: int = pos.get("shares", 0) if not pos.is_empty() else 0
			return Loc.t("lc_add_share") % [shares, TradingEngine.MAX_ADDS]
		2: return Loc.t("lc_back")
	return ""
