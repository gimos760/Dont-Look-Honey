extends Control

const REASON_TEXT := {
	GameManager.GameOverReason.CAUGHT:    "Your wife saw the screen!",
	GameManager.GameOverReason.TIMEOUT:   "Time's up — target not reached.",
	GameManager.GameOverReason.SUSPICION: "Suspicion gauge depleted!",
}

@onready var _reason_lbl: Label = $Panel/ReasonLabel
@onready var _amount_lbl: Label = $Panel/AmountLabel


func _ready() -> void:
	AudioManager.stop_bgm()
	_reason_lbl.text = REASON_TEXT.get(
		GameManager.game_over_reason, "Game Over")
	var target := GameManager.get_stage_target(GameManager.current_stage)
	_amount_lbl.text = "Final: $%.0f / $%.0f" % [GameManager.get_total_realized(), target]


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.is_action("game_confirm"):
		GameManager.start_game()
	elif event.is_action("game_cancel"):
		GameManager.go_to_lobby()
