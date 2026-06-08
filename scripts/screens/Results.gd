extends Control

@onready var _result_lbl: Label   = $Panel/ResultLabel
@onready var _amount_lbl: Label   = $Panel/AmountLabel
@onready var _gap_lbl: Label      = $Panel/GapLabel
@onready var _hint_lbl: Label     = $Panel/HintLabel


func _ready() -> void:
	var total  := GameManager.get_total_realized()
	var target := GameManager.get_stage_target(3)
	var won    := total >= target

	if won:
		_result_lbl.text = "VICTORY!"
		_result_lbl.add_theme_color_override("font_color", Color.YELLOW)
		_gap_lbl.text    = "You cleared the target. Honey never knew!"
		AudioManager.play_win()
	else:
		_result_lbl.text = "FAILED"
		_result_lbl.add_theme_color_override("font_color", Color.RED)
		var gap := target - total
		_gap_lbl.text = "Short by $%.0f" % gap

	_amount_lbl.text = "Realized: $%.2f / $%.0f" % [total, target]
	_hint_lbl.text   = "[Z] Play Again   [X] Lobby"


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.is_action("game_confirm"):
		GameManager.start_game()
	elif event.is_action("game_cancel"):
		GameManager.go_to_lobby()
