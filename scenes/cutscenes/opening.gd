extends Control

const AudioHelpers = preload("res://autoload/audio_helpers.gd")
const BGM_OPENING_MEMORY := preload("res://assets/audio/bgm/opening_memory.wav")

@onready var _wash: ColorRect = $Wash
@onready var _title: Label = $Title
@onready var _body: Label = $Body
@onready var _hint: Label = $Hint

const LINES := [
	{
		"title": "CUT_OPENING_TITLE_01",
		"body": "CUT_OPENING_BODY_01"
	},
	{
		"title": "CUT_OPENING_TITLE_02",
		"body": "CUT_OPENING_BODY_02"
	},
	{
		"title": "CUT_OPENING_TITLE_03",
		"body": "CUT_OPENING_BODY_03"
	},
	{
		"title": "CUT_OPENING_TITLE_04",
		"body": "CUT_OPENING_BODY_04"
	},
	{
		"title": "CUT_OPENING_TITLE_05",
		"body": "CUT_OPENING_BODY_05"
	},
]

var _index := -1
var _locked := false

func _ready() -> void:
	GameManager.set_state(GameManager.State.CUTSCENE)
	AudioHelpers.play_music(self, BGM_OPENING_MEMORY)
	_title.modulate.a = 0.0
	_body.modulate.a = 0.0
	_hint.modulate.a = 0.0
	_hint.text = _t("UI_PROMPT_CONTINUE")
	await get_tree().create_timer(0.35).timeout
	_next_line()

func _unhandled_input(event: InputEvent) -> void:
	if _locked:
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("jump"):
		_next_line()
		get_viewport().set_input_as_handled()

func _next_line() -> void:
	if _locked:
		return
	_index += 1
	if _index >= LINES.size():
		_locked = true
		_fade_to_game()
		return
	_show_line(LINES[_index])

func _show_line(line: Dictionary) -> void:
	_locked = true
	_title.text = _t(str(line.get("title", "")))
	_body.text = _t(str(line.get("body", "")))
	_title.modulate.a = 0.0
	_body.modulate.a = 0.0
	_hint.modulate.a = 0.0

	var tween := create_tween()
	tween.tween_property(_title, "modulate:a", 1.0, 0.35)
	tween.tween_property(_body, "modulate:a", 1.0, 0.45)
	tween.tween_property(_hint, "modulate:a", 0.72, 0.25)
	tween.tween_callback(func(): _locked = false)

func _t(key: String) -> String:
	return tr(key).replace("\\n", "\n")

func _fade_to_game() -> void:
	var tween := create_tween()
	tween.tween_property(_wash, "color:a", 1.0, 0.45)
	tween.tween_callback(GameManager.start_after_opening)
