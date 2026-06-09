class_name StageBase
extends Node2D

# Override in subclass
var STAGE_DURATION: float = 300.0
var _bgm_path: String = "res://assets/music/bgm_game.wav"

@onready var _market: StockMarket              = $StockMarket
@onready var _engine: TradingEngine            = $TradingEngine
@onready var _alert: WifeAlertSystem           = $WifeContainer/WifeAlertSystem
@onready var _hud: HUDController               = $HUD
@onready var _phone: PhoneController           = $Phone
@onready var _qte: QTEManager                  = $QTE
@onready var _stage_timer: Timer               = $StageTimer
@onready var _wife_sprite: Sprite2D            = $WifeContainer/WifeSprite

var _time_left: float = 0.0
var _running: bool    = false
var _paused: bool     = false

var _tex_wife_back: Texture2D
var _tex_wife_front: Texture2D

var _pause_menu: PauseMenu


func _ready() -> void:
	# Subclass sets STAGE_DURATION and alert config first
	_setup_stage()
	_time_left = STAGE_DURATION

	# Init market & engine
	var stocks := StockData.pick_random_five()
	_market.initialize(stocks)
	_engine.initialize(_market)

	# Init phone & HUD
	_phone.initialize(_market, _engine)
	_hud.update_balance(_engine.get_available_balance())
	_hud.update_time(_time_left)

	# Wire signals
	_alert.wife_turned.connect(_on_wife_turned)
	_alert.wife_looked_away.connect(_on_wife_looked_away)
	_alert.qte_triggered.connect(_on_qte_triggered)
	_alert.game_over_caught.connect(_on_caught)
	_alert.suspicion_depleted.connect(_on_suspicion_depleted)

	_phone.phone_hidden.connect(_alert.notify_phone_hidden)
	_phone.phone_shown.connect(_alert.notify_phone_shown)

	_qte.qte_success.connect(_alert.on_qte_success)
	_qte.qte_fail.connect(_alert.on_qte_fail)
	_qte.qte_success.connect(func(): _phone.input_blocked = false)
	_qte.qte_fail.connect(func(): _phone.input_blocked = false)

	_engine.balance_updated.connect(_hud.update_balance)
	_engine.position_opened.connect(func(_p): _phone.refresh_current_layer())
	_engine.position_closed.connect(func(_p, _n): _phone.refresh_current_layer())

	_market.tick_completed.connect(_on_tick_completed)
	_market.high_volume_alert.connect(_on_high_volume)

	_stage_timer.wait_time = STAGE_DURATION
	_stage_timer.one_shot  = true
	_stage_timer.timeout.connect(_on_stage_timer_end)

	# Pause menu
	_pause_menu = load("res://scenes/ui/PauseMenu.tscn").instantiate()
	add_child(_pause_menu)
	_pause_menu.resumed.connect(_on_resumed)
	_pause_menu.quit_to_lobby.connect(GameManager.go_to_lobby)

	_start()


func _setup_stage() -> void:
	# Override in subclasses
	pass


func _set_stage_hint(key: String) -> void:
	var lbl: Label = get_node_or_null("HintLabel")
	if lbl:
		lbl.text = Loc.t(key)


func _start() -> void:
	_running = true
	_tex_wife_back  = load("res://assets/sprites/wife_back.png")
	_tex_wife_front = load("res://assets/sprites/wife_front.png")
	if is_instance_valid(_wife_sprite) and _tex_wife_back:
		_wife_sprite.texture = _tex_wife_back
	AudioManager.play_bgm(_bgm_path)
	_market.start()
	_alert.start()
	_stage_timer.start()


func _unhandled_input(event: InputEvent) -> void:
	if not _running:
		return
	if event.is_action_pressed("game_pause"):
		_pause_menu.open()
		get_viewport().set_input_as_handled()


func _on_resumed() -> void:
	pass  # game resumes automatically via get_tree().paused = false


func _process(delta: float) -> void:
	if not _running:
		return
	_time_left = _stage_timer.time_left
	_hud.update_time(_time_left)



# --- Signal callbacks ---

func _on_wife_turned() -> void:
	_hud.set_eye_open(true)
	if is_instance_valid(_wife_sprite) and _tex_wife_front:
		_wife_sprite.texture = _tex_wife_front
	_phone.set_right_hand_react(true)
	_move_wife_for_turn()


func _on_wife_looked_away() -> void:
	_hud.set_eye_open(false)
	if is_instance_valid(_wife_sprite) and _tex_wife_back:
		_wife_sprite.texture = _tex_wife_back
	_phone.set_right_hand_react(false)


func _on_qte_triggered() -> void:
	_phone.input_blocked = true
	_qte.start_qte()


func _on_caught() -> void:
	_game_over(GameManager.GameOverReason.CAUGHT)


func _on_suspicion_depleted() -> void:
	_game_over(GameManager.GameOverReason.SUSPICION)


func _on_stage_timer_end() -> void:
	_market.stop()
	_alert.stop()
	var total  := GameManager.get_total_realized()
	var target := GameManager.get_stage_target(GameManager.current_stage)
	if total >= target:
		_running = false
		if GameManager.current_stage < 3:
			GameManager.advance_stage()
		else:
			GameManager.go_to_results()
	else:
		_game_over(GameManager.GameOverReason.TIMEOUT)


func _on_tick_completed() -> void:
	_phone.refresh_current_layer()


func _on_high_volume(stock_id: String, direction: String, probability: float) -> void:
	# Forward to chart layer if that stock is currently viewed
	var layer_chart = _phone.get_node_or_null(
		"FullPhone/PhoneFrame/Screen/LayerChart")
	if layer_chart and layer_chart.visible:
		if layer_chart._stock.get("id", "") == stock_id:
			layer_chart.show_high_volume(direction, probability)


func _game_over(reason: GameManager.GameOverReason) -> void:
	if not _running:
		return
	_running = false
	_market.stop()
	_alert.stop()
	AudioManager.play_game_over()
	GameManager.trigger_game_over(reason)


# Subclasses override to reposition wife sprite
func _move_wife_for_turn() -> void:
	pass
