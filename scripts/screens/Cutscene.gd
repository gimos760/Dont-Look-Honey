extends Node2D

const DIALOGUE: Array[Dictionary] = [
	{"speaker": "", "text": "A quiet Sunday afternoon at home..."},
	{"speaker": "Wife", "text": "I saw you checking your phone again..."},
	{"speaker": "Wife", "text": "If I catch you trading again, you're DONE!"},
	{"speaker": "Husband", "text": "(Nods obediently)"},
	{"speaker": "Husband", "text": "(But deep down... the charts are calling...)"},
]

const IMAGES: Array[String] = [
	"res://assets/sprites/cutscene_1.png",   # 0: husband on sofa
	"res://assets/sprites/cutscene_2.png",   # 1: same scene
	"res://assets/sprites/cutscene_3.png",   # 2: full room confrontation
	"res://assets/sprites/cutscene_4.png",   # 3: wife angry close-up (split LEFT)
	"res://assets/sprites/cutscene_nod.png", # 4: husband nodding (split RIGHT)
	"res://assets/sprites/cutscene_5.png",   # 5: confident husband (slide 4)
]

const SPLIT_SLIDE: int = 3

var _slide: int = 0

@onready var _scene_image: TextureRect       = $ScenePanel/SceneImage
@onready var _scene_image_right: TextureRect = $ScenePanel/SceneImageRight
@onready var _speaker_lbl: Label             = $DialogueBox/Speaker
@onready var _text_lbl: RichTextLabel        = $DialogueBox/Text
@onready var _hint_lbl: Label                = $HintLabel


func _ready() -> void:
	_show_slide(_slide)


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.is_action("game_confirm") or event.is_action("game_cancel"):
		_next()


func _next() -> void:
	_slide += 1
	if _slide >= DIALOGUE.size():
		GameManager.cutscene_seen = true
		GameManager.change_scene_to_stage(1)
	else:
		_show_slide(_slide)


func _show_slide(idx: int) -> void:
	var d := DIALOGUE[idx]
	_speaker_lbl.text = d["speaker"]
	_speaker_lbl.visible = d["speaker"] != ""
	_text_lbl.text = d["text"]
	_hint_lbl.text = "[Z / X] Next"

	if idx == SPLIT_SLIDE:
		# Split: cutscene_4 (left half) + cutscene_nod (right half), each fills its side
		_scene_image.offset_left = 0.0
		_scene_image.offset_right = 320.0
		_scene_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_scene_image.texture = load(IMAGES[3])
		_scene_image_right.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_scene_image_right.visible = true
		_scene_image_right.texture = load(IMAGES[4])
	elif idx == 4:
		# "But deep down..." — confident husband (Screen5)
		_scene_image.offset_right = 640.0
		_scene_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_scene_image_right.visible = false
		_scene_image.texture = load(IMAGES[5])
	else:
		_scene_image.offset_right = 640.0
		_scene_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_scene_image_right.visible = false
		if idx < IMAGES.size():
			_scene_image.texture = load(IMAGES[idx])
