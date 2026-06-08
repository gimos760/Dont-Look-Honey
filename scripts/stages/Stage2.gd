extends StageBase

const WIFE_POSITIONS: Array = [
	Vector2(80,  258),
	Vector2(200, 268),
	Vector2(320, 272),
	Vector2(450, 268),
	Vector2(560, 258),
]

func _setup_stage() -> void:
	STAGE_DURATION = 420.0
	_alert.configure_medium()


func _move_wife_for_turn() -> void:
	if is_instance_valid(_wife_sprite):
		_wife_sprite.position = WIFE_POSITIONS[randi() % WIFE_POSITIONS.size()]
