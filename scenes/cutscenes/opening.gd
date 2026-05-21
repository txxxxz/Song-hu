extends Control

@onready var _wash: ColorRect = $Wash
@onready var _title: Label = $Title
@onready var _body: Label = $Body
@onready var _hint: Label = $Hint

const LINES := [
	{
		"title": "狐火未归",
		"body": "昨夜起，山脚的灯接连熄灭。雨停了，石灯还是湿的。\n去邻村送药的人说，她顺着参道下山，走了一晚上，却还在原地打转"
	},
	{
		"title": "迎狐之仪",
		"body": "村里把这叫「狐火离位」。\n若狐火不回本社，山路会鬼打墙，井水会发苦。\n按旧规，山社要举行迎狐之仪，把白狐迎回山上的本社。"
	},
	{
		"title": "见习巫女",
		"body": "你是山社的见习巫女，雨宫铃音。你记得自己曾有一个姐姐，她才是山社真正的巫女。\n但是你忘记了她的名字，你问过大人，他们却闭口不谈"
	},
	{
		"title": "童谣",
		"body": "你只记得那首童谣。\n狐上山，不回头。若回头，莫唤名。\n什么名字？名字像被水泡过的草纸，模糊了形状，念不出来。"
	},
	{
		"title": "装束之祠",
		"body": "山脚的小祠已经开门。门槛下积着一线雨水。\n供桌擦过，木牌立好，御供筒放在老人手边。\n今晚轮到你送狐上山。"
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
