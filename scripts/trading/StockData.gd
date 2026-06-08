class_name StockData
extends RefCounted

const DEFINITIONS: Array[Dictionary] = [
	{
		"id": "FIN",
		"name": "Finance",
		"price_min": 60.0,
		"price_max": 160.0,
		"volatility": 0.003,
		"trend_bias": 0.0,
		"has_spikes": false,
		"spike_chance": 0.0,
		"high_vol_chance": 0.05,
	},
	{
		"id": "BIO",
		"name": "Biotech",
		"price_min": 100.0,
		"price_max": 400.0,
		"volatility": 0.015,
		"trend_bias": 0.0005,
		"has_spikes": true,
		"spike_chance": 0.08,
		"high_vol_chance": 0.10,
	},
	{
		"id": "NRG",
		"name": "Energy",
		"price_min": 80.0,
		"price_max": 240.0,
		"volatility": 0.008,
		"trend_bias": 0.0,
		"has_spikes": false,
		"spike_chance": 0.0,
		"high_vol_chance": 0.07,
	},
	{
		"id": "GOLD",
		"name": "Gold ETF",
		"price_min": 300.0,
		"price_max": 600.0,
		"volatility": 0.003,
		"trend_bias": 0.001,
		"has_spikes": false,
		"spike_chance": 0.0,
		"high_vol_chance": 0.05,
	},
	{
		"id": "BTC",
		"name": "BTC ETF",
		"price_min": 800.0,
		"price_max": 1800.0,
		"volatility": 0.03,
		"trend_bias": 0.0005,
		"has_spikes": true,
		"spike_chance": 0.12,
		"high_vol_chance": 0.15,
	},
	{
		"id": "TECH",
		"name": "Tech",
		"price_min": 200.0,
		"price_max": 800.0,
		"volatility": 0.012,
		"trend_bias": 0.0003,
		"has_spikes": false,
		"spike_chance": 0.0,
		"high_vol_chance": 0.10,
	},
	{
		"id": "AI",
		"name": "AI",
		"price_min": 400.0,
		"price_max": 1200.0,
		"volatility": 0.018,
		"trend_bias": 0.0005,
		"has_spikes": true,
		"spike_chance": 0.10,
		"high_vol_chance": 0.12,
	},
]


static func pick_random_five() -> Array[Dictionary]:
	var pool: Array[Dictionary] = []
	for d in DEFINITIONS:
		pool.append(d.duplicate())
	pool.shuffle()
	return pool.slice(0, 5)


static func mid_range_price(stock: Dictionary) -> float:
	var lo: float = stock["price_min"]
	var hi: float = stock["price_max"]
	return lo + (hi - lo) * randf_range(0.4, 0.6)
