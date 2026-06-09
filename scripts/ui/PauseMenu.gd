class_name PauseMenu
extends CanvasLayer

signal resumed()
signal quit_to_lobby()

var _cursor: int = 0  # 0 = 繼續, 1 = 退出大廳

@onready var _title:      Label = $Panel/VBox/Title
@onready var _opt_resume: Label = $Panel/VBox/OptResume
@onready var _opt_quit:   Label = $Panel/VBox/OptQuit
@onready var _hint:       Label = $Panel/VBox/Hint


func _ready() -> void:
	layer = 20
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS


func open() -> void:
	visible = true
	get_tree().paused = true
	_cursor = 0
	_title.text = Loc.t("pause_title")
	_hint.text  = Loc.t("pause_hint")
	_refresh()


func close() -> void:
	get_tree().paused = false
	visible = false


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if not (event is InputEventKey and event.pressed and not event.echo):
		return

	if event.is_action("game_up") or event.is_action("game_down"):
		_cursor = 1 - _cursor
		_refresh()
		get_viewport().set_input_as_handled()
	elif event.is_action("game_confirm"):
		get_viewport().set_input_as_handled()
		if _cursor == 0:
			close()
			resumed.emit()
		else:
			get_tree().paused = false
			quit_to_lobby.emit()
	elif event.is_action("game_pause") or event.is_action("game_cancel"):
		get_viewport().set_input_as_handled()
		close()
		resumed.emit()


func _refresh() -> void:
	var resume := Loc.t("pause_resume")
	var quit   := Loc.t("pause_quit")
	_opt_resume.text = ("> %s <" if _cursor == 0 else "  %s  ") % resume
	_opt_quit.text   = ("> %s <" if _cursor == 1 else "  %s  ") % quit
	_opt_resume.add_theme_color_override("font_color",
		Color(0.95, 0.85, 0.15) if _cursor == 0 else Color(0.65, 0.65, 0.65))
	_opt_quit.add_theme_color_override("font_color",
		Color(0.95, 0.85, 0.15) if _cursor == 1 else Color(0.65, 0.65, 0.65))
