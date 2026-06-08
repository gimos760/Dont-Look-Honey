class_name PhoneController
extends CanvasLayer

signal phone_hidden()
signal phone_shown()

enum Mode  { FULL, MINI }
enum Layer { STOCK_OVERVIEW = 0, CHART = 1, CONFIRM = 2 }

var mode: Mode = Mode.FULL
var current_layer: Layer = Layer.STOCK_OVERVIEW
var selected_stock_idx: int = 0
var input_blocked: bool = false

var _market: StockMarket
var _engine: TradingEngine

@onready var _full_root: Control    = $FullPhone
@onready var _layer_stock: LayerStockOverview = $FullPhone/PhoneFrame/Screen/LayerStock
@onready var _layer_chart: LayerChart         = $FullPhone/PhoneFrame/Screen/LayerChart
@onready var _layer_confirm: LayerConfirm     = $FullPhone/PhoneFrame/Screen/LayerConfirm


func initialize(market: StockMarket, engine: TradingEngine) -> void:
	_market = market
	_engine = engine
	_show_layer(Layer.STOCK_OVERVIEW)
	_set_mode(Mode.FULL)


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("phone_hide"):
		_set_mode(Mode.MINI)
		phone_hidden.emit()
	elif Input.is_action_just_released("phone_hide"):
		_set_mode(Mode.FULL)
		phone_shown.emit()


func _input(event: InputEvent) -> void:
	if input_blocked or mode != Mode.FULL:
		return
	if not (event is InputEventKey and event.pressed and not event.echo):
		return

	if event.is_action("game_confirm"):
		_handle_confirm()
		get_viewport().set_input_as_handled()
	elif event.is_action("game_cancel"):
		_handle_cancel()
		get_viewport().set_input_as_handled()
	elif event.is_action("game_up"):
		_handle_up()
		get_viewport().set_input_as_handled()
	elif event.is_action("game_down"):
		_handle_down()
		get_viewport().set_input_as_handled()
	elif event.is_action("game_left"):
		_handle_left()
		get_viewport().set_input_as_handled()
	elif event.is_action("game_right"):
		_handle_right()
		get_viewport().set_input_as_handled()
	elif event.is_action("trade_close"):
		_handle_close_shortcut()
		get_viewport().set_input_as_handled()


# --- Mode switching ---

func _set_mode(m: Mode) -> void:
	mode = m
	_full_root.visible = (m == Mode.FULL)


# --- Layer management ---

func _show_layer(layer: Layer) -> void:
	current_layer = layer
	_layer_stock.visible   = (layer == Layer.STOCK_OVERVIEW)
	_layer_chart.visible   = (layer == Layer.CHART)
	_layer_confirm.visible = (layer == Layer.CONFIRM)
	_refresh_current_layer()


func _refresh_current_layer() -> void:
	match current_layer:
		Layer.STOCK_OVERVIEW:
			_layer_stock.refresh(_market.stocks, _engine, _market)
		Layer.CHART:
			var s := _market.stocks[selected_stock_idx]
			_layer_chart.show_stock(s, _market, _engine)
		Layer.CONFIRM:
			var s := _market.stocks[selected_stock_idx]
			_layer_confirm.show_confirm(s, _layer_chart.selected_direction, _market, _engine)


# --- Input handlers ---

func _handle_confirm() -> void:
	match current_layer:
		Layer.STOCK_OVERVIEW:
			_show_layer(Layer.CHART)
		Layer.CHART:
			var s := _market.stocks[selected_stock_idx]
			if _engine.has_position(s["id"]):
				# Enter on existing position opens confirm to add
				_show_layer(Layer.CONFIRM)
			else:
				_show_layer(Layer.CONFIRM)
		Layer.CONFIRM:
			_execute_order()


func _handle_cancel() -> void:
	match current_layer:
		Layer.CHART:
			_show_layer(Layer.STOCK_OVERVIEW)
		Layer.CONFIRM:
			_show_layer(Layer.CHART)


func _handle_up() -> void:
	match current_layer:
		Layer.STOCK_OVERVIEW:
			selected_stock_idx = max(0, selected_stock_idx - 1)
			_layer_stock.set_cursor(selected_stock_idx)
		Layer.CONFIRM:
			_layer_confirm.move_selection(-1)


func _handle_down() -> void:
	match current_layer:
		Layer.STOCK_OVERVIEW:
			selected_stock_idx = min(_market.stocks.size() - 1, selected_stock_idx + 1)
			_layer_stock.set_cursor(selected_stock_idx)
		Layer.CONFIRM:
			_layer_confirm.move_selection(1)


func _handle_left() -> void:
	if current_layer == Layer.CHART:
		_layer_chart.move_selection(-1)


func _handle_right() -> void:
	if current_layer == Layer.CHART:
		_layer_chart.move_selection(1)


func _handle_close_shortcut() -> void:
	if current_layer == Layer.STOCK_OVERVIEW:
		var s := _market.stocks[selected_stock_idx]
		_engine.close_position(s["id"])
		_refresh_current_layer()


func _execute_order() -> void:
	var s   := _market.stocks[selected_stock_idx]
	var opt := _layer_confirm.selected_option
	match opt:
		0:  # Confirm Order — only reachable when no position exists
			_engine.open_position(s["id"], _layer_chart.selected_direction)
			_show_layer(Layer.STOCK_OVERVIEW)
		1:  # Add 1 Share — only reachable when position exists
			_engine.add_to_position(s["id"])
			_layer_confirm.show_confirm(s, _layer_chart.selected_direction, _market, _engine)
		2:  # Back
			_show_layer(Layer.CHART)


# --- Called by stage to refresh after market tick ---
func refresh_chart_if_visible() -> void:
	if mode == Mode.FULL and current_layer == Layer.CHART:
		var s := _market.stocks[selected_stock_idx]
		_layer_chart.show_stock(s, _market, _engine)
