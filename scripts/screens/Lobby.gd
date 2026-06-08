extends Control


func _ready() -> void:
	AudioManager.play_bgm("res://assets/music/bgm_lobby.wav")


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.is_action("game_confirm"):
		GameManager.start_game()
	elif event.is_action("game_cancel"):
		get_tree().quit()
