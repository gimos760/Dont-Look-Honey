extends Control

enum Menu { MAIN, OPTIONS, STAGE_SELECT }

const LANG_CODES:    Array[String] = ["en", "zh"]
const STAGE_COUNT:   int           = 3
const OPTIONS_COUNT: int           = 4

const COLOR_SELECTED: Color = Color(0.95, 0.85, 0.15, 1.0)
const COLOR_IDLE:     Color = Color(0.62, 0.62, 0.62, 1.0)

var _menu:           Menu   = Menu.MAIN
var _cursor:         int    = 0
var _lang_idx:       int    = 0
var _bgm_vol:        int    = 100
var _sfx_vol:        int    = 100
var _cheat_unlocked: bool   = false
var _cheat_buffer:   String = ""

@onready var _main_panel:         VBoxContainer = $Center/MainPanel
@onready var _options_panel:      VBoxContainer = $Center/OptionsPanel
@onready var _stage_select_panel: VBoxContainer = $Center/StageSelectPanel
@onready var _sub_lbl:            Label         = $Center/MainPanel/SubLabel
@onready var _opt_start:          Label         = $Center/MainPanel/OptStart
@onready var _opt_options:        Label         = $Center/MainPanel/OptOptions
@onready var _opt_stage_select:   Label         = $Center/MainPanel/OptStageSelect
@onready var _opt_quit:           Label         = $Center/MainPanel/OptQuit
@onready var _opt_title:          Label         = $Center/OptionsPanel/OptTitle
@onready var _opt_bgm_vol:        Label         = $Center/OptionsPanel/OptBgmVol
@onready var _opt_sfx_vol:        Label         = $Center/OptionsPanel/OptSfxVol
@onready var _opt_lang:           Label         = $Center/OptionsPanel/OptLang
@onready var _opt_back:           Label         = $Center/OptionsPanel/OptBack
@onready var _ss_title:           Label         = $Center/StageSelectPanel/SSTitle
@onready var _ss_stage1:          Label         = $Center/StageSelectPanel/SSStage1
@onready var _ss_stage2:          Label         = $Center/StageSelectPanel/SSStage2
@onready var _ss_stage3:          Label         = $Center/StageSelectPanel/SSStage3
@onready var _hint_lbl:           Label         = $HintLabel


func _ready() -> void:
	AudioManager.play_bgm("res://assets/music/bgm_lobby.wav")
	_sub_lbl.text = Loc.t("game_subtitle")
	_show_menu(Menu.MAIN)


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return

	if _menu == Menu.MAIN:
		_check_cheat(event)

	if event.is_action("game_up"):
		_move_cursor(-1)
		accept_event()
	elif event.is_action("game_down"):
		_move_cursor(1)
		accept_event()
	elif event.is_action("game_left") and _menu == Menu.OPTIONS:
		_adjust_volume(-10)
		accept_event()
	elif event.is_action("game_right") and _menu == Menu.OPTIONS:
		_adjust_volume(10)
		accept_event()
	elif event.is_action("game_confirm"):
		_confirm()
		accept_event()
	elif event.is_action("game_cancel"):
		if _menu == Menu.OPTIONS or _menu == Menu.STAGE_SELECT:
			_show_menu(Menu.MAIN)
			accept_event()


func _check_cheat(event: InputEvent) -> void:
	if event.unicode == 0:
		return
	const CODE := "irvin"
	var ch := String.chr(event.unicode).to_lower()
	_cheat_buffer += ch
	if _cheat_buffer == CODE:
		_cheat_buffer   = ""
		_cheat_unlocked = not _cheat_unlocked
		_opt_stage_select.visible = _cheat_unlocked
		AudioManager.play_ui_confirm()
		_refresh_cursor()
	elif not CODE.begins_with(_cheat_buffer):
		_cheat_buffer = "i" if ch == "i" else ""


func _get_main_count() -> int:
	return 4 if _cheat_unlocked else 3


func _move_cursor(dir: int) -> void:
	var count: int
	match _menu:
		Menu.MAIN:         count = _get_main_count()
		Menu.OPTIONS:      count = OPTIONS_COUNT
		Menu.STAGE_SELECT: count = STAGE_COUNT
	_cursor = (_cursor + dir + count) % count
	_refresh_cursor()


func _confirm() -> void:
	match _menu:
		Menu.MAIN:
			match _cursor:
				0: GameManager.start_game()
				1: _show_menu(Menu.OPTIONS)
				2:
					if _cheat_unlocked:
						_show_menu(Menu.STAGE_SELECT)
					else:
						get_tree().quit()
				3: get_tree().quit()
		Menu.OPTIONS:
			match _cursor:
				0, 1, 2:
					pass  # adjusted with left/right
				3:
					_show_menu(Menu.MAIN)
		Menu.STAGE_SELECT:
			GameManager.change_scene_to_stage(_cursor + 1)


func _adjust_volume(delta: int) -> void:
	match _cursor:
		0:
			_bgm_vol = clampi(_bgm_vol + delta, 0, 100)
			AudioManager.set_bgm_volume(_bgm_vol)
			_refresh_cursor()
		1:
			_sfx_vol = clampi(_sfx_vol + delta, 0, 100)
			AudioManager.set_sfx_volume(_sfx_vol)
			_refresh_cursor()
		2:
			_lang_idx = (_lang_idx + 1) % LANG_CODES.size() if delta > 0 \
				else (_lang_idx - 1 + LANG_CODES.size()) % LANG_CODES.size()
			Loc.set_lang(LANG_CODES[_lang_idx])
			_opt_title.text = Loc.t("menu_options")
			_sub_lbl.text   = Loc.t("game_subtitle")
			_hint_lbl.text  = Loc.t("hint_options")
			_refresh_cursor()


func _vol_bar(pct: int) -> String:
	var filled := int(pct / 10.0 + 0.5)
	return "█".repeat(filled) + "─".repeat(10 - filled)


func _show_menu(m: Menu) -> void:
	_menu   = m
	_cursor = 0
	_main_panel.visible         = (m == Menu.MAIN)
	_options_panel.visible      = (m == Menu.OPTIONS)
	_stage_select_panel.visible = (m == Menu.STAGE_SELECT)
	_refresh_cursor()
	match m:
		Menu.MAIN:
			_hint_lbl.text = Loc.t("hint_main")
		Menu.OPTIONS:
			_opt_title.text = Loc.t("menu_options")
			_hint_lbl.text  = Loc.t("hint_options")
		Menu.STAGE_SELECT:
			_ss_title.text = Loc.t("ss_title")
			_hint_lbl.text = Loc.t("hint_stage_select")


func _refresh_cursor() -> void:
	match _menu:
		Menu.MAIN:
			var items: Array[Label]
			if _cheat_unlocked:
				items = [_opt_start, _opt_options, _opt_stage_select, _opt_quit]
			else:
				items = [_opt_start, _opt_options, _opt_quit]
			for i in range(items.size()):
				var sel := (i == _cursor)
				items[i].add_theme_color_override("font_color",
					COLOR_SELECTED if sel else COLOR_IDLE)
				items[i].text = ("> %s <" if sel else "  %s  ") % _main_text(i)
		Menu.OPTIONS:
			var items: Array[Label] = [_opt_bgm_vol, _opt_sfx_vol, _opt_lang, _opt_back]
			for i in range(items.size()):
				var sel := (i == _cursor)
				items[i].add_theme_color_override("font_color",
					COLOR_SELECTED if sel else COLOR_IDLE)
				items[i].text = ("> %s <" if sel else "  %s  ") % _options_text(i)
		Menu.STAGE_SELECT:
			var items: Array[Label] = [_ss_stage1, _ss_stage2, _ss_stage3]
			for i in range(items.size()):
				var sel := (i == _cursor)
				items[i].add_theme_color_override("font_color",
					COLOR_SELECTED if sel else COLOR_IDLE)
				items[i].text = ("> %s <" if sel else "  %s  ") % (Loc.t("ss_stage") % (i + 1))


func _main_text(i: int) -> String:
	if _cheat_unlocked:
		match i:
			0: return Loc.t("menu_start")
			1: return Loc.t("menu_options")
			2: return Loc.t("menu_stage_select")
			3: return Loc.t("menu_quit")
	else:
		match i:
			0: return Loc.t("menu_start")
			1: return Loc.t("menu_options")
			2: return Loc.t("menu_quit")
	return ""


func _options_text(i: int) -> String:
	match i:
		0: return Loc.t("opt_bgm") % [_vol_bar(_bgm_vol), _bgm_vol]
		1: return Loc.t("opt_sfx") % [_vol_bar(_sfx_vol), _sfx_vol]
		2: return Loc.t("opt_language") % Loc.t("lang_name")
		3: return Loc.t("opt_back")
	return ""
