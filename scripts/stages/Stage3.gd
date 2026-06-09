extends StageBase

const WIFE_POSITIONS: Array = [
	Vector2(80,  258),
	Vector2(200, 268),
	Vector2(320, 272),
	Vector2(450, 268),
	Vector2(560, 258),
]

func _setup_stage() -> void:
	STAGE_DURATION = 600.0
	_bgm_path = "res://assets/music/bgm_stage1.wav"
	_alert.configure_high()
	_hud.enable_suspicion_gauge()
	_hud.update_suspicion(_alert.get_suspicion())
	_alert.qte_triggered.connect(_update_suspicion_display)
	_qte.qte_fail.connect(_update_suspicion_display)
	_set_stage_hint("hint_stage3")


func _move_wife_for_turn() -> void:
	if is_instance_valid(_wife_sprite):
		_wife_sprite.position = WIFE_POSITIONS[randi() % WIFE_POSITIONS.size()]


func _update_suspicion_display() -> void:
	_hud.update_suspicion(_alert.get_suspicion())
