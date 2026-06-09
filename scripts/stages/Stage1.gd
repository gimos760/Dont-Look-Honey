extends StageBase

func _setup_stage() -> void:
	STAGE_DURATION = 300.0
	_bgm_path = "res://assets/music/bgm_stage1.wav"
	_alert.configure_low()
	_set_stage_hint("hint_stage1")
