class_name LayerStockOverview
extends Control

const COLOR_SELECTED := Color(0.25, 0.55, 0.90, 0.35)
const COLOR_BG_ROW   := Color(0.08, 0.10, 0.15, 0.70)

var _cursor: int = 0
var _rows: Array[Control] = []

@onready var _list: VBoxContainer = $Scroll/List


func refresh(stocks: Array[Dictionary], engine: TradingEngine, market: StockMarket) -> void:
	for r in _rows:
		if is_instance_valid(r):
			r.queue_free()
	_rows.clear()

	for i in range(stocks.size()):
		var s     := stocks[i]
		var price := market.get_price(s["id"])
		var row   := _make_row(i, s, engine, market, price)
		_list.add_child(row)
		_rows.append(row)

	_apply_cursor()


func set_cursor(idx: int) -> void:
	_cursor = idx
	_apply_cursor()


func _apply_cursor() -> void:
	for i in range(_rows.size()):
		var row := _rows[i]
		if not is_instance_valid(row):
			continue
		var bg: ColorRect = row.get_node_or_null("BG")
		if bg:
			bg.color = COLOR_SELECTED if i == _cursor else COLOR_BG_ROW


func _make_row(idx: int, s: Dictionary, engine: TradingEngine, market: StockMarket, price: float) -> Control:
	var row := Control.new()
	row.name = "Row%d" % idx
	row.custom_minimum_size = Vector2(0, 24)

	var bg := ColorRect.new()
	bg.name = "BG"
	bg.color = COLOR_BG_ROW
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.add_child(bg)

	var hbox := HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.add_theme_constant_override("separation", 4)
	row.add_child(hbox)

	var name_lbl := _lbl(s["name"], 100)
	hbox.add_child(name_lbl)

	var price_lbl := _lbl("$%.2f" % price, 80)
	hbox.add_child(price_lbl)

	var pos: Dictionary = engine.get_position(s["id"])
	var shares_lbl: Label
	var pnl_lbl: Label
	if not pos.is_empty():
		var dir_icon := "↑" if pos["direction"] == "long" else "↓"
		shares_lbl = _lbl("%s x%d" % [dir_icon, pos["shares"]], 60)
		var pct := engine.get_floating_pnl_pct(s["id"])
		var sign := "+" if pct >= 0 else ""
		pnl_lbl = _lbl("%s%.1f%%" % [sign, pct], 70)
		pnl_lbl.add_theme_color_override("font_color", Color.GREEN if pct >= 0 else Color.RED)
	else:
		shares_lbl = _lbl("---", 60)
		pnl_lbl    = _lbl("", 70)

	hbox.add_child(shares_lbl)
	hbox.add_child(pnl_lbl)

	var hint_lbl := _lbl("[Z]Ent [C]Cls", 90)
	hint_lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55))
	hbox.add_child(hint_lbl)

	return row


func _lbl(text: String, min_w: int) -> Label:
	var l := Label.new()
	l.text = text
	l.custom_minimum_size = Vector2(min_w, 0)
	l.add_theme_font_size_override("font_size", 10)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return l
