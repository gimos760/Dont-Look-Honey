class_name QTEManager
extends CanvasLayer

signal qte_success()
signal qte_fail()

const KEY_POOL    := ["I", "O", "J", "K"]
const SEQ_MIN     := 5
const SEQ_MAX     := 7
const QTE_SECONDS := 5.0

var _sequence: Array[String] = []
var _index: int      = 0
var _active: bool    = false
var _elapsed: float  = 0.0

@onready var _panel: Control          = $Panel
@onready var _key_row: HBoxContainer  = $Panel/VBox/KeyRow
@onready var _bar: ProgressBar        = $Panel/VBox/CountBar
@onready var _title: Label            = $Panel/VBox/Title


func _ready() -> void:
	_panel.visible = false


func start_qte() -> void:
	_sequence = _gen_sequence()
	_index    = 0
	_elapsed  = 0.0
	_active   = true
	_panel.visible = true
	_title.text    = "QTE — Press keys in order!"
	_bar.value     = 100.0
	_rebuild_keys()


func _process(delta: float) -> void:
	if not _active:
		return
	_elapsed += delta
	_bar.value = clamp((1.0 - _elapsed / QTE_SECONDS) * 100.0, 0.0, 100.0)
	if _elapsed >= QTE_SECONDS:
		_resolve(false)


func _input(event: InputEvent) -> void:
	if not _active:
		return
	if not (event is InputEventKey and event.pressed and not event.echo):
		return

	var expected := _sequence[_index]
	var pressed  := _key_to_char(event)

	if pressed == expected:
		_index += 1
		_rebuild_keys()
		if _index >= _sequence.size():
			_resolve(true)
	else:
		_resolve(false)

	get_viewport().set_input_as_handled()


func _resolve(success: bool) -> void:
	_active        = false
	_panel.visible = false
	if success:
		AudioManager.play_qte_success()
		qte_success.emit()
	else:
		AudioManager.play_qte_fail()
		qte_fail.emit()


func _gen_sequence() -> Array[String]:
	var seq: Array[String] = []
	var length := randi_range(SEQ_MIN, SEQ_MAX)
	for _i in range(length):
		seq.append(String(KEY_POOL[randi() % KEY_POOL.size()]))
	return seq


func _rebuild_keys() -> void:
	for c in _key_row.get_children():
		c.queue_free()
	for i in range(_sequence.size()):
		var lbl := Label.new()
		lbl.text = _sequence[i]
		lbl.custom_minimum_size = Vector2(32, 32)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 14)
		if i < _index:
			lbl.add_theme_color_override("font_color", Color.GREEN)
		elif i == _index:
			lbl.add_theme_color_override("font_color", Color.WHITE)
			lbl.add_theme_font_size_override("font_size", 18)
		else:
			lbl.add_theme_color_override("font_color", Color(0.30, 0.30, 0.30))
		_key_row.add_child(lbl)


func _key_to_char(event: InputEventKey) -> String:
	match event.keycode:
		KEY_I: return "I"
		KEY_O: return "O"
		KEY_J: return "J"
		KEY_K: return "K"
	return ""
