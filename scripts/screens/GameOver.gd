extends Control

@onready var _title_lbl:  Label = $Panel/TitleLabel
@onready var _reason_lbl: Label = $Panel/ReasonLabel
@onready var _amount_lbl: Label = $Panel/AmountLabel
@onready var _hint_lbl:   Label = $Panel/HintLabel


func _ready() -> void:
	AudioManager.stop_bgm()
	_title_lbl.text  = Loc.t("go_title")
	_reason_lbl.text = _reason_key(GameManager.game_over_reason)
	var target := GameManager.get_stage_target(GameManager.current_stage)
	_amount_lbl.text = Loc.t("go_final") % [GameManager.get_total_realized(), target]
	_hint_lbl.text   = Loc.t("go_hint")


func _reason_key(reason: GameManager.GameOverReason) -> String:
	match reason:
		GameManager.GameOverReason.CAUGHT:    return Loc.t("go_caught")
		GameManager.GameOverReason.TIMEOUT:   return Loc.t("go_timeout")
		GameManager.GameOverReason.SUSPICION: return Loc.t("go_suspicion")
	return Loc.t("go_title")


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.is_action("game_confirm"):
		GameManager.start_game()
	elif event.is_action("game_cancel"):
		GameManager.go_to_lobby()
