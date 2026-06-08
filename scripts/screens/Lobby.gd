extends Control

enum Menu { MAIN, OPTIONS }

const LANG_OPTIONS: Array[String] = ["English", "中文"]

const COLOR_SELECTED: Color = Color(0.95, 0.85, 0.15, 1.0)
const COLOR_IDLE:     Color = Color(0.62, 0.62, 0.62, 1.0)

const MAIN_COUNT:    int = 3
const OPTIONS_COUNT: int = 2

var _menu:     Menu = Menu.MAIN
var _cursor:   int  = 0
var _lang_idx: int  = 0

@onready var _main_panel:    VBoxContainer = $Center/MainPanel
@onready var _options_panel: VBoxContainer = $Center/OptionsPanel
@onready var _opt_start:     Label         = $Center/MainPanel/OptStart
@onready var _opt_options:   Label         = $Center/MainPanel/OptOptions
@onready var _opt_quit:      Label         = $Center/MainPanel/OptQuit
@onready var _opt_lang:      Label         = $Center/OptionsPanel/OptLang
@onready var _opt_back:      Label         = $Center/OptionsPanel/OptBack
@onready var _hint_lbl:      Label         = $HintLabel


func _ready() -> void:
	AudioManager.play_bgm("res://assets/music/bgm_lobby.wav")
	_show_menu(Menu.MAIN)


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return

	if event.is_action("game_up"):
		_move_cursor(-1)
		accept_event()
	elif event.is_action("game_down"):
		_move_cursor(1)
		accept_event()
	elif event.is_action("game_confirm"):
		_confirm()
		accept_event()
	elif event.is_action("game_cancel") and _menu == Menu.OPTIONS:
		_show_menu(Menu.MAIN)
		accept_event()


func _move_cursor(dir: int) -> void:
	var count: int = MAIN_COUNT if _menu == Menu.MAIN else OPTIONS_COUNT
	_cursor = (_cursor + dir + count) % count
	_refresh_cursor()


func _confirm() -> void:
	match _menu:
		Menu.MAIN:
			match _cursor:
				0: GameManager.start_game()
				1: _show_menu(Menu.OPTIONS)
				2: get_tree().quit()
		Menu.OPTIONS:
			match _cursor:
				0:
					_lang_idx = (_lang_idx + 1) % LANG_OPTIONS.size()
					_refresh_cursor()
				1:
					_show_menu(Menu.MAIN)


func _show_menu(m: Menu) -> void:
	_menu   = m
	_cursor = 0
	_main_panel.visible    = (m == Menu.MAIN)
	_options_panel.visible = (m == Menu.OPTIONS)
	_refresh_cursor()
	match m:
		Menu.MAIN:
			_hint_lbl.text = "[W/S] Navigate   [Z] Select"
		Menu.OPTIONS:
			_hint_lbl.text = "[W/S] Navigate   [Z] Toggle / Select   [X] Back"


func _refresh_cursor() -> void:
	match _menu:
		Menu.MAIN:
			var items: Array[Label] = [_opt_start, _opt_options, _opt_quit]
			for i in range(items.size()):
				var sel := (i == _cursor)
				items[i].add_theme_color_override("font_color",
					COLOR_SELECTED if sel else COLOR_IDLE)
				items[i].text = ("> %s <" if sel else "  %s  ") % _main_text(i)
		Menu.OPTIONS:
			var items: Array[Label] = [_opt_lang, _opt_back]
			for i in range(items.size()):
				var sel := (i == _cursor)
				items[i].add_theme_color_override("font_color",
					COLOR_SELECTED if sel else COLOR_IDLE)
				items[i].text = ("> %s <" if sel else "  %s  ") % _options_text(i)


func _main_text(i: int) -> String:
	match i:
		0: return "Start Game"
		1: return "Options"
		2: return "Quit"
	return ""


func _options_text(i: int) -> String:
	match i:
		0: return "Language: %s" % LANG_OPTIONS[_lang_idx]
		1: return "Back"
	return ""
