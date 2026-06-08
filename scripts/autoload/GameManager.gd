extends Node

enum GameOverReason {
	CAUGHT,
	TIMEOUT,
	SUSPICION
}

const STARTING_CAPITAL: float = 10000.0
const STAGE_TARGETS: Array[float] = [20000.0, 30000.0, 50000.0]

func get_stage_target(stage: int) -> float:
	return STAGE_TARGETS[clamp(stage - 1, 0, STAGE_TARGETS.size() - 1)]

var current_stage: int = 1
var cutscene_seen: bool = false
var game_over_reason: GameOverReason = GameOverReason.CAUGHT

var realized_pnl: float = 0.0
var open_positions: Array[Dictionary] = []


func get_available_balance() -> float:
	var locked := 0.0
	for pos in open_positions:
		locked += pos.get("total_cost", 0.0)
	# realized_pnl can be negative (losses reduce available capital)
	return STARTING_CAPITAL + realized_pnl - locked


func get_total_realized() -> float:
	return STARTING_CAPITAL + realized_pnl


func reset_for_new_game() -> void:
	current_stage = 1
	realized_pnl = 0.0
	open_positions.clear()
	cutscene_seen = false


func start_game() -> void:
	reset_for_new_game()
	if not cutscene_seen:
		get_tree().change_scene_to_file("res://scenes/Cutscene.tscn")
	else:
		change_scene_to_stage(1)


func change_scene_to_stage(stage: int) -> void:
	current_stage = stage
	match stage:
		1: get_tree().change_scene_to_file("res://scenes/stages/Stage1.tscn")
		2: get_tree().change_scene_to_file("res://scenes/stages/Stage2.tscn")
		3: get_tree().change_scene_to_file("res://scenes/stages/Stage3.tscn")


func advance_stage() -> void:
	if current_stage < 3:
		# carry over realized PnL; open positions are lost (not settled)
		open_positions.clear()
		change_scene_to_stage(current_stage + 1)
	else:
		get_tree().change_scene_to_file("res://scenes/Results.tscn")


func trigger_game_over(reason: GameOverReason) -> void:
	game_over_reason = reason
	open_positions.clear()
	get_tree().change_scene_to_file("res://scenes/GameOver.tscn")


func go_to_lobby() -> void:
	reset_for_new_game()
	get_tree().change_scene_to_file("res://scenes/Lobby.tscn")


func go_to_results() -> void:
	open_positions.clear()
	get_tree().change_scene_to_file("res://scenes/Results.tscn")
