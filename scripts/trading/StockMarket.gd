class_name StockMarket
extends Node

signal candle_closed(stock_id: String, candle: Dictionary)
signal high_volume_alert(stock_id: String, direction: String, reversal_prob: float)
signal tick_completed

const CANDLE_DURATION := 4.0
const MAX_HISTORY    := 70
const SHOWN_CANDLES  := 20

var stocks: Array[Dictionary] = []
var candle_history: Dictionary = {}
var current_prices: Dictionary = {}

var _tick_timer: Timer


func _ready() -> void:
	_tick_timer = Timer.new()
	_tick_timer.wait_time = CANDLE_DURATION
	_tick_timer.autostart = false
	_tick_timer.timeout.connect(_on_tick)
	add_child(_tick_timer)


func initialize(stock_list: Array[Dictionary]) -> void:
	stocks = stock_list
	for s in stocks:
		var id: String = s["id"]
		current_prices[id] = StockData.mid_range_price(s)
		s["trend"] = 1 if randf() > 0.5 else -1  # random initial trend
		candle_history[id] = []
		for _i in range(SHOWN_CANDLES):
			_build_candle(id, false)


func start() -> void:
	_tick_timer.start()


func stop() -> void:
	_tick_timer.stop()


func get_price(stock_id: String) -> float:
	return current_prices.get(stock_id, 0.0)


func get_trend(stock_id: String) -> int:
	var s := _find_stock(stock_id)
	return s.get("trend", 1)


func get_last_candles(stock_id: String, n: int = SHOWN_CANDLES) -> Array[Dictionary]:
	var hist: Array[Dictionary] = []
	hist.assign(candle_history.get(stock_id, [] as Array))
	var start: int = max(0, hist.size() - n)
	return hist.slice(start)


# ---------- internals ----------

func _on_tick() -> void:
	for s in stocks:
		_build_candle(s["id"], true)
	tick_completed.emit()


func _build_candle(stock_id: String, emit: bool) -> void:
	var s := _find_stock(stock_id)
	if s.is_empty():
		return

	var prev_close: float = current_prices[stock_id]
	var p_min: float      = s["price_min"]
	var p_max: float      = s["price_max"]
	var vol: float        = s["volatility"]
	var trend: int        = s.get("trend", 1)

	# Normalised position: 0 = at min, 1 = at max
	var norm: float = (prev_close - p_min) / (p_max - p_min)

	# Hard boundary guard — force trend reversal at extreme edges
	if norm > 0.95:
		trend = -1
		s["trend"] = trend
	elif norm < 0.05:
		trend = 1
		s["trend"] = trend

	# --- Event determination ---
	var is_spike: bool    = s["has_spikes"] and randf() < s["spike_chance"]
	# High-volume can happen independently, or always occurs alongside a spike
	var is_high_vol: bool = is_spike or randf() < s["high_vol_chance"]

	# --- Trend reversal check (triggered by high volume) ---
	var did_reverse: bool    = false
	var reversal_prob: float = 0.0
	if is_high_vol:
		if trend == 1:      # uptrend — more likely to reverse when near the top
			reversal_prob = norm
		else:               # downtrend — more likely to reverse when near the bottom
			reversal_prob = 1.0 - norm
		if randf() < reversal_prob:
			s["trend"] = -trend
			trend = s["trend"]
			did_reverse = true

	# --- Price movement ---
	# trend_bias magnitude stays constant; direction follows current trend
	var bias: float = abs(s["trend_bias"]) * float(trend)
	var pct: float  = randfn(bias, vol)

	# Spike: large random shock regardless of trend direction
	if is_spike:
		var spike_mult: float = randf_range(5.0, 10.0)
		var spike_dir: float  = 1.0 if randf() > 0.5 else -1.0
		pct += spike_dir * vol * spike_mult

	var new_close: float = clamp(prev_close * (1.0 + pct), p_min, p_max)

	# --- OHLC ---
	var open_p: float  = prev_close
	var close_p: float = new_close
	var wick_scale: float = (
		abs(open_p - close_p) * randf_range(0.1, 0.5)
		+ prev_close * vol * randf()
	)
	var candle := {
		"open":        open_p,
		"close":       close_p,
		"high":        clamp(max(open_p, close_p) + wick_scale, p_min, p_max),
		"low":         clamp(min(open_p, close_p) - wick_scale, p_min, p_max),
		"volume":      _gen_volume(abs(pct), vol, is_high_vol),
		"is_high_vol": is_high_vol,
		"did_reverse": did_reverse,
	}

	current_prices[stock_id] = close_p

	var hist: Array = candle_history[stock_id]
	hist.append(candle)
	if hist.size() > MAX_HISTORY:
		hist.pop_front()

	if emit:
		candle_closed.emit(stock_id, candle)
		if is_high_vol:
			var dir: String = "Up" if trend == 1 else "Down"
			high_volume_alert.emit(stock_id, dir, reversal_prob)


func _gen_volume(price_change_pct: float, base_vol: float, high_vol: bool) -> float:
	var base: float = (1000.0 + randf() * 2000.0) * (1.0 + price_change_pct / base_vol * 0.5)
	if high_vol:
		base *= randf_range(2.5, 5.0)
	return base


func _find_stock(stock_id: String) -> Dictionary:
	for s in stocks:
		if s["id"] == stock_id:
			return s
	return {}
