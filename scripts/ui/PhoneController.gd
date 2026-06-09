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
var _tween: Tween = null

@onready var _full_root:    Control    = $FullPhone
@onready var _mini_root:    Control    = $MiniPhone
@onready var _mini_content: Label      = $MiniPhone/Content
@onready var _mini_pnl:     Label      = $MiniPhone/PnlLabel
@onready var _hands_layer:  Control    = $HandsLayer
@onready var _right_hand:   TextureRect = $HandsLayer/RightHand
@onready var _layer_stock:   LayerStockOverview = $FullPhone/PhoneFrame/Screen/LayerStock
@onready var _layer_chart:   LayerChart         = $FullPhone/PhoneFrame/Screen/LayerChart
@onready var _layer_confirm: LayerConfirm       = $FullPhone/PhoneFrame/Screen/LayerConfirm

var _tex_right_normal: Texture2D
var _tex_right_yeah: Texture2D


func _ready() -> void:
	_tex_right_normal = load("res://assets/sprites/right_hand.png")
	_tex_right_yeah   = load("res://assets/sprites/right_hand_yeah.png")


func initialize(market: StockMarket, engine: TradingEngine) -> void:
	_market = market
	_engine = engine
	_show_layer(Layer.STOCK_OVERVIEW)
	_set_mode(Mode.FULL, false)


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

func _set_mode(m: Mode, animate: bool = true) -> void:
	mode = m
	if _tween:
		_tween.kill()
		_tween = null

	if m == Mode.FULL:
		_mini_root.visible   = false
		_hands_layer.visible = false
		_full_root.visible   = true
		if animate:
			_full_root.pivot_offset = Vector2(320.0, 180.0)
			_full_root.scale        = Vector2(0.55, 0.55)
			_full_root.modulate.a   = 0.0
			_tween = create_tween().set_parallel()
			_tween.tween_property(_full_root, "scale", Vector2.ONE, 0.25) \
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			_tween.tween_property(_full_root, "modulate:a", 1.0, 0.18)
		else:
			_full_root.scale      = Vector2.ONE
			_full_root.modulate.a = 1.0
	else:
		_refresh_mini()
		_mini_root.visible   = true
		_hands_layer.visible = true
		if animate:
			_full_root.visible    = true
			_full_root.modulate.a = 1.0
			_tween = create_tween()
			_tween.tween_property(_full_root, "modulate:a", 0.0, 0.12)
			_tween.tween_callback(func(): _full_root.visible = false)
		else:
			_full_root.visible = false


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


func _refresh_mini() -> void:
	if _engine == null or _market == null:
		return
	var lines: PackedStringArray = []
	var has_pos := false
	for s in _market.stocks:
		if _engine.has_position(s["id"]):
			has_pos = true
			var pos  := _engine.get_position(s["id"])
			var pct  := _engine.get_floating_pnl_pct(s["id"])
			var sign := "+" if pct >= 0 else ""
			var dir  := "▲" if pos["direction"] == "long" else "▼"
			lines.append("%s%s x%d  %s%.1f%%" % [s["name"], dir, pos["shares"], sign, pct])
	if not has_pos:
		lines.append(Loc.t("phone_no_pos"))
	_mini_content.text = "\n".join(lines)
	_auto_scale_label(_mini_content, 107.0)

	var pnl  := GameManager.realized_pnl
	var sign := "+" if pnl >= 0 else ""
	_mini_pnl.text = Loc.t("phone_pnl") % [sign, pnl]
	_mini_pnl.add_theme_color_override("font_color",
		Color(0.0, 0.45, 0.0) if pnl >= 0 else Color(0.7, 0.0, 0.0))


func _auto_scale_label(lbl: Label, max_height: float) -> void:
	const BASE_SIZE := 6
	const LINE_RATIO := 1.3
	var line_count := lbl.text.count("\n") + 1
	var needed := line_count * BASE_SIZE * LINE_RATIO
	if needed > max_height:
		var new_size := int(max_height / (line_count * LINE_RATIO))
		lbl.add_theme_font_size_override("font_size", maxi(new_size, 4))
	else:
		lbl.add_theme_font_size_override("font_size", BASE_SIZE)


# --- Called by StageBase after each market tick ---
func refresh_current_layer() -> void:
	if mode == Mode.FULL:
		_refresh_current_layer()
	else:
		_refresh_mini()


# --- Input handlers ---

func _handle_confirm() -> void:
	AudioManager.play_ui_confirm()
	match current_layer:
		Layer.STOCK_OVERVIEW:
			_show_layer(Layer.CHART)
		Layer.CHART:
			_show_layer(Layer.CONFIRM)
		Layer.CONFIRM:
			_execute_order()


func _handle_cancel() -> void:
	match current_layer:
		Layer.CHART:
			AudioManager.play_ui_cancel()
			_show_layer(Layer.STOCK_OVERVIEW)
		Layer.CONFIRM:
			AudioManager.play_ui_cancel()
			_show_layer(Layer.CHART)


func _handle_up() -> void:
	match current_layer:
		Layer.STOCK_OVERVIEW:
			selected_stock_idx = max(0, selected_stock_idx - 1)
			_layer_stock.set_cursor(selected_stock_idx)
			AudioManager.play_ui_move()
		Layer.CONFIRM:
			_layer_confirm.move_selection(-1)
			AudioManager.play_ui_move()


func _handle_down() -> void:
	match current_layer:
		Layer.STOCK_OVERVIEW:
			selected_stock_idx = min(_market.stocks.size() - 1, selected_stock_idx + 1)
			_layer_stock.set_cursor(selected_stock_idx)
			AudioManager.play_ui_move()
		Layer.CONFIRM:
			_layer_confirm.move_selection(1)
			AudioManager.play_ui_move()


func _handle_left() -> void:
	if current_layer == Layer.CHART:
		_layer_chart.move_selection(-1)
		AudioManager.play_ui_move()


func _handle_right() -> void:
	if current_layer == Layer.CHART:
		_layer_chart.move_selection(1)
		AudioManager.play_ui_move()


func _handle_close_shortcut() -> void:
	if current_layer == Layer.STOCK_OVERVIEW:
		var s := _market.stocks[selected_stock_idx]
		_engine.close_position(s["id"])
		AudioManager.play_ui_confirm()
		_refresh_current_layer()


func _execute_order() -> void:
	var s   := _market.stocks[selected_stock_idx]
	var opt := _layer_confirm.selected_option
	match opt:
		0:
			_engine.open_position(s["id"], _layer_chart.selected_direction)
			_show_layer(Layer.STOCK_OVERVIEW)
		1:
			_engine.add_to_position(s["id"])
			_layer_confirm.show_confirm(s, _layer_chart.selected_direction, _market, _engine)
		2:
			_show_layer(Layer.CHART)


func set_right_hand_react(reacting: bool) -> void:
	_right_hand.texture = _tex_right_yeah if reacting else _tex_right_normal
