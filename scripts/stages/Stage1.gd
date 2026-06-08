extends StageBase

func _setup_stage() -> void:
	STAGE_DURATION = 300.0
	_alert.configure_low()
	if is_instance_valid(_wife_sprite):
		_wife_sprite.position = Vector2(480, 255)
