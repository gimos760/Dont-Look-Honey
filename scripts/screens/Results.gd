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
		_result_lbl.text = Loc.t("result_win")
		_result_lbl.add_theme_color_override("font_color", Color.YELLOW)
		_gap_lbl.text    = Loc.t("result_win_sub")
		AudioManager.play_win()
	else:
		_result_lbl.text = Loc.t("result_lose")
		_result_lbl.add_theme_color_override("font_color", Color.RED)
		var gap := target - total
		_gap_lbl.text = Loc.t("result_short") % gap

	_amount_lbl.text = Loc.t("result_amount") % [total, target]
	_hint_lbl.text   = Loc.t("result_hint")


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.is_action("game_confirm"):
		GameManager.start_game()
	elif event.is_action("game_cancel"):
		GameManager.go_to_lobby()
