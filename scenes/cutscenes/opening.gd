extends Control

@onready var _wash: ColorRect = $Wash
@onready var _title: Label = $Title
@onready var _body: Label = $Body
@onready var _hint: Label = $Hint

const LINES := [
	{
		"title": "山路入夜",
		"body": "村口的灯一盏盏熄了。\n只有通往旧社的参道，还浮着一点狐火。"
	},
	{
		"title": "送狐之仪",
		"body": "老人说，今夜要送走白狐。\n不可出声，不可回头，也不可叫出它的名字。"
	},
	{
		"title": "御供筒",
		"body": "杉木为底，白衣覆身，蓬草盖顶。\n你抱着空空的御供筒，踏进林中。"
	},
]

var _index := -1
var _locked := false

func _ready() -> void:
	GameManager.set_state(GameManager.State.CUTSCENE)
	_title.modulate.a = 0.0
	_body.modulate.a = 0.0
	_hint.modulate.a = 0.0
	_hint.text = "按 E 或 Space 继续"
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
	_title.text = line.get("title", "")
	_body.text = line.get("body", "")
	_title.modulate.a = 0.0
	_body.modulate.a = 0.0
	_hint.modulate.a = 0.0

	var tween := create_tween()
	tween.tween_property(_title, "modulate:a", 1.0, 0.35)
	tween.tween_property(_body, "modulate:a", 1.0, 0.45)
	tween.tween_property(_hint, "modulate:a", 0.72, 0.25)
	tween.tween_callback(func(): _locked = false)

func _fade_to_game() -> void:
	var tween := create_tween()
	tween.tween_property(_wash, "color:a", 1.0, 0.45)
	tween.tween_callback(GameManager.start_after_opening)
