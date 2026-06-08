class_name TradingEngine
extends Node

signal position_opened(position: Dictionary)
signal position_closed(position: Dictionary, pnl: float)
signal balance_updated(balance: float)
signal realized_updated(total: float)
signal order_failed(reason: String)

const MAX_ADDS := 10

var _market: StockMarket


func initialize(market: StockMarket) -> void:
	_market = market


# Returns copy of open positions from GameManager
func get_open_positions() -> Array:
	return GameManager.open_positions


func get_position(stock_id: String) -> Dictionary:
	for p in GameManager.open_positions:
		if p["stock_id"] == stock_id:
			return p
	return {}


func has_position(stock_id: String) -> bool:
	return not get_position(stock_id).is_empty()


func get_available_balance() -> float:
	var locked := 0.0
	for p in GameManager.open_positions:
		locked += p.get("total_cost", 0.0)
	return GameManager.STARTING_CAPITAL + GameManager.realized_pnl - locked


func open_position(stock_id: String, direction: String) -> bool:
	var price := _market.get_price(stock_id)
	if get_available_balance() < price:
		order_failed.emit("Insufficient balance")
		return false

	# Cannot hold opposite direction on same stock
	if has_position(stock_id):
		var existing := get_position(stock_id)
		if existing["direction"] != direction:
			order_failed.emit("Cannot hold Long and Short simultaneously")
			return false
		# Already have same direction — treat as add
		return add_to_position(stock_id)

	var pos: Dictionary = {
		"stock_id":   stock_id,
		"direction":  direction,
		"entry_price": price,
		"shares":     1,
		"add_count":  0,
		"total_cost": price,
	}
	GameManager.open_positions.append(pos)
	position_opened.emit(pos)
	balance_updated.emit(get_available_balance())
	return true


func add_to_position(stock_id: String) -> bool:
	var pos: Dictionary = get_position(stock_id)
	if pos.is_empty():
		return false
	if pos["shares"] >= MAX_ADDS:
		order_failed.emit("Max adds reached (10)")
		return false
	var price := _market.get_price(stock_id)
	if get_available_balance() < price:
		order_failed.emit("Insufficient balance")
		return false

	pos["shares"]     += 1
	pos["add_count"]  += 1
	pos["total_cost"] += price
	pos["entry_price"] = pos["total_cost"] / float(pos["shares"])
	balance_updated.emit(get_available_balance())
	return true


func close_position(stock_id: String) -> float:
	var idx := -1
	for i in range(GameManager.open_positions.size()):
		if GameManager.open_positions[i]["stock_id"] == stock_id:
			idx = i
			break
	if idx == -1:
		return 0.0

	var pos: Dictionary = GameManager.open_positions[idx]
	var price := _market.get_price(stock_id)
	var pnl   := calc_pnl(pos, price)

	GameManager.realized_pnl += pnl
	GameManager.open_positions.remove_at(idx)

	position_closed.emit(pos, pnl)
	balance_updated.emit(get_available_balance())
	realized_updated.emit(GameManager.realized_pnl)
	return pnl


func get_floating_pnl(stock_id: String) -> float:
	var pos: Dictionary = get_position(stock_id)
	if pos.is_empty():
		return 0.0
	return calc_pnl(pos, _market.get_price(stock_id))


func get_floating_pnl_pct(stock_id: String) -> float:
	var pos: Dictionary = get_position(stock_id)
	if pos.is_empty() or pos["total_cost"] == 0.0:
		return 0.0
	return get_floating_pnl(stock_id) / pos["total_cost"] * 100.0


func calc_pnl(pos: Dictionary, current_price: float) -> float:
	var entry: float  = pos["entry_price"]
	var shares: float = float(pos["shares"])
	if pos["direction"] == "long":
		return (current_price - entry) * shares
	else:
		return (entry - current_price) * shares


func can_afford(stock_id: String) -> bool:
	return get_available_balance() >= _market.get_price(stock_id)
