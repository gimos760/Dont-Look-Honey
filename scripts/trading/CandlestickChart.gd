class_name CandlestickChart
extends Control

const MAX_CANDLES: int   = 15
const PRICE_RATIO: float = 0.74
const VOL_RATIO: float   = 0.18
const VOL_GAP: float     = 0.02
const LABEL_W: float     = 44.0
const PRICE_PAD: float   = 0.06

# TradingView-style palette
const COLOR_BULL:            Color = Color(0.149, 0.651, 0.604, 1.0)  # #26A69A
const COLOR_BEAR:            Color = Color(0.937, 0.325, 0.314, 1.0)  # #EF5350
const COLOR_BG:              Color = Color(0.071, 0.086, 0.122, 1.0)  # #121620
const COLOR_GRID:            Color = Color(0.18,  0.21,  0.27,  0.35)
const COLOR_ENTRY:           Color = Color(1.0,   0.85,  0.15,  0.85)
const COLOR_CURRENT:         Color = Color(0.80,  0.80,  0.80,  0.85)
const COLOR_LABEL:           Color = Color(0.55,  0.58,  0.64,  1.0)
const COLOR_MA:              Color = Color(0.24,  0.55,  0.90,  0.85)  # blue MA line
const COLOR_HIGH_VOL_BAR:    Color = Color(1.0,   0.60,  0.05,  0.70)
const COLOR_AVG_VOL_LINE:    Color = Color(1.0,   0.60,  0.05,  0.50)
const COLOR_REVERSAL_MARKER: Color = Color(1.0,   0.85,  0.15,  1.0)
const COLOR_LONG_TINT:       Color = Color(0.0,   0.55,  0.30,  0.05)
const COLOR_SHORT_TINT:      Color = Color(0.75,  0.10,  0.10,  0.05)

var candles: Array[Dictionary] = []
var high_vol_active: bool      = false
var entry_price: float         = 0.0
var current_trend: int         = 1       # 1 = up, -1 = down
var position_direction: String = ""      # "long" | "short" | ""


func set_candles(data: Array[Dictionary]) -> void:
	candles = data.slice(max(0, data.size() - MAX_CANDLES))
	queue_redraw()


func show_high_volume(_direction: String, _probability: float) -> void:
	high_vol_active = true
	queue_redraw()


func hide_high_volume() -> void:
	high_vol_active = false
	queue_redraw()


func _draw() -> void:
	var sz: Vector2    = get_size()
	var chart_w: float = sz.x - LABEL_W
	var price_h: float = sz.y * PRICE_RATIO
	var vol_h: float   = sz.y * VOL_RATIO
	var vol_y: float   = sz.y * (PRICE_RATIO + VOL_GAP)

	draw_rect(Rect2(Vector2.ZERO, sz), COLOR_BG)

	if candles.is_empty():
		return

	# Price range with padding
	var hi: float = -INF
	var lo: float =  INF
	for c in candles:
		if float(c["high"]) > hi: hi = float(c["high"])
		if float(c["low"])  < lo: lo = float(c["low"])
	if hi == lo: hi += 1.0
	var pad := (hi - lo) * PRICE_PAD
	hi += pad; lo -= pad

	_draw_position_tint(chart_w, price_h)
	_draw_grid(chart_w, price_h)
	_draw_volume_area(chart_w, vol_y, vol_h)
	_draw_price_area(chart_w, price_h, hi, lo)
	_draw_ma_line(chart_w, price_h, hi, lo)
	_draw_overlays(chart_w, price_h, hi, lo)
	_draw_y_axis(sz.x, price_h, hi, lo)
	_draw_trend_badge(sz.x, price_h)

	if high_vol_active:
		var bar_y := vol_y - 2.0
		draw_rect(Rect2(0.0, bar_y, chart_w, 2.0), Color(1.0, 0.55, 0.0, 0.80))


# ── Position background tint ────────────────────────────────────────────────

func _draw_position_tint(chart_w: float, price_h: float) -> void:
	match position_direction:
		"long":  draw_rect(Rect2(0.0, 0.0, chart_w, price_h), COLOR_LONG_TINT)
		"short": draw_rect(Rect2(0.0, 0.0, chart_w, price_h), COLOR_SHORT_TINT)


# ── Grid ─────────────────────────────────────────────────────────────────────

func _draw_grid(chart_w: float, price_h: float) -> void:
	for i in range(1, 4):
		var y := price_h * float(i) / 4.0
		draw_line(Vector2(0.0, y), Vector2(chart_w, y), COLOR_GRID, 1.0)
	# Separator between chart and label column
	draw_line(Vector2(chart_w, 0.0), Vector2(chart_w, price_h), COLOR_GRID, 1.0)


# ── Candlestick bodies & wicks ───────────────────────────────────────────────

func _draw_price_area(chart_w: float, price_h: float, hi: float, lo: float) -> void:
	var count   := candles.size()
	var slot_w  := chart_w / float(count)
	var body_w  := maxf(2.0, slot_w * 0.58)

	for i in range(count):
		var c     := candles[i]
		var cx    := float(i) * slot_w + slot_w * 0.5
		var bull  := float(c["close"]) >= float(c["open"])
		var col   := COLOR_BULL if bull else COLOR_BEAR

		var hy := _py(float(c["high"]),  lo, hi, price_h)
		var ly := _py(float(c["low"]),   lo, hi, price_h)
		var oy := _py(float(c["open"]),  lo, hi, price_h)
		var cy := _py(float(c["close"]), lo, hi, price_h)

		# Wick (1 px)
		draw_line(Vector2(cx, hy), Vector2(cx, ly), col, 1.0)

		# Body
		var top  := minf(oy, cy)
		var bot  := maxf(oy, cy)
		var h    := maxf(2.0, bot - top)
		draw_rect(Rect2(cx - body_w * 0.5, top, body_w, h), col)

		# Reversal dot above the high wick
		if c.get("did_reverse", false):
			draw_circle(Vector2(cx, hy - 5.0), 2.5, COLOR_REVERSAL_MARKER)


# ── Volume bars ──────────────────────────────────────────────────────────────

func _draw_volume_area(chart_w: float, vol_y: float, vol_h: float) -> void:
	var count  := candles.size()
	var slot_w := chart_w / float(count)
	var body_w := maxf(2.0, slot_w * 0.58)

	var vols: Array[float] = []
	for c in candles:
		vols.append(float(c.get("volume", 0.0)))

	var v_max := 0.0
	for v in vols:
		if v > v_max: v_max = v
	if v_max == 0.0: return

	var avg_vol := 0.0
	for v in vols: avg_vol += v
	avg_vol /= float(vols.size())

	for i in range(count):
		var c      := candles[i]
		var v      := vols[i]
		var bar_h  := (v / v_max) * vol_h * 0.95
		var cx     := float(i) * slot_w + slot_w * 0.5
		var bull   := float(c["close"]) >= float(c["open"])
		var is_hv  := avg_vol > 0.0 and v > avg_vol * 2.0
		var col    := COLOR_HIGH_VOL_BAR if is_hv else (COLOR_BULL if bull else COLOR_BEAR)
		col.a = 0.55
		draw_rect(Rect2(cx - body_w * 0.5, vol_y + vol_h - bar_h, body_w, bar_h), col)

	if avg_vol > 0.0:
		var avg_y := vol_y + vol_h - (avg_vol / v_max) * vol_h * 0.95
		draw_dashed_line(Vector2(0.0, avg_y), Vector2(chart_w, avg_y),
			COLOR_AVG_VOL_LINE, 1.0, 4.0)


# ── MA5 line ─────────────────────────────────────────────────────────────────

func _draw_ma_line(chart_w: float, price_h: float, hi: float, lo: float) -> void:
	var count  := candles.size()
	var slot_w := chart_w / float(count)
	var prev   := Vector2(-1.0, -1.0)

	for i in range(count):
		var s_i: int = maxi(0, i - 4)
		var sum := 0.0; var n := 0
		for j in range(s_i, i + 1):
			sum += float(candles[j]["close"]); n += 1
		var cx := float(i) * slot_w + slot_w * 0.5
		var cy := _py(sum / float(n), lo, hi, price_h)
		var pt := Vector2(cx, cy)
		if prev.x >= 0.0:
			draw_line(prev, pt, COLOR_MA, 1.0)
		prev = pt


# ── Price overlays (current + entry dashed lines) ───────────────────────────

func _draw_overlays(chart_w: float, price_h: float, hi: float, lo: float) -> void:
	var font := ThemeDB.fallback_font

	if not candles.is_empty():
		var cur := float(candles[-1]["close"])
		var cy  := _py(cur, lo, hi, price_h)
		if cy >= 0.0 and cy <= price_h:
			draw_dashed_line(Vector2(0.0, cy), Vector2(chart_w, cy), COLOR_CURRENT, 0.8, 4.0)

	if entry_price > 0.0:
		var ey := _py(entry_price, lo, hi, price_h)
		if ey >= 0.0 and ey <= price_h:
			draw_dashed_line(Vector2(0.0, ey), Vector2(chart_w, ey), COLOR_ENTRY, 1.0, 5.0)
			draw_string(font, Vector2(chart_w + 3.0, ey + 5.0), "Avg",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 8, COLOR_ENTRY)


# ── Y-axis labels ────────────────────────────────────────────────────────────

func _draw_y_axis(total_w: float, price_h: float, hi: float, lo: float) -> void:
	var font := ThemeDB.fallback_font
	var lx   := total_w - LABEL_W + 3.0

	# Current price tag (highlighted box)
	if not candles.is_empty():
		var cur := float(candles[-1]["close"])
		var cy  := _py(cur, lo, hi, price_h)
		if cy >= 0.0 and cy <= price_h:
			var tag := "$%.2f" % cur
			draw_rect(Rect2(lx - 1.0, cy - 8.0, LABEL_W - 2.0, 10.0),
				Color(0.80, 0.80, 0.80, 0.20))
			draw_string(font, Vector2(lx + 1.0, cy + 1.0), tag,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 8, COLOR_CURRENT)

	# Fixed grid price labels
	for i in range(5):
		var t     := float(i) / 4.0
		var price := hi - t * (hi - lo)
		var y     := t * price_h
		draw_string(font, Vector2(lx, y + 8.0), "$%.0f" % price,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 7, COLOR_LABEL)


# ── Trend badge in label column (top-right, no overlap) ─────────────────────

func _draw_trend_badge(total_w: float, price_h: float) -> void:
	var font  := ThemeDB.fallback_font
	var arrow := "▲" if current_trend == 1 else "▼"
	var col   := COLOR_BULL if current_trend == 1 else COLOR_BEAR
	var lx    := total_w - LABEL_W + 3.0
	# Small tinted background
	draw_rect(Rect2(lx - 2.0, price_h - 16.0, LABEL_W - 2.0, 14.0), Color(col, 0.18))
	draw_string(font, Vector2(lx + 6.0, price_h - 5.0), arrow,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 11, col)


# ── Utility ───────────────────────────────────────────────────────────────────

func _py(price: float, lo: float, hi: float, height: float) -> float:
	return height * (1.0 - (price - lo) / (hi - lo))
