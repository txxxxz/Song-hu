extends Control

@onready var _title_label: Label = $TitleLabel
@onready var _start_btn: Button = $ButtonVBox/StartBtn
@onready var _quit_btn: Button = $ButtonVBox/QuitBtn

var _time: float = 0.0

func _ready() -> void:
	GameManager.set_state(GameManager.State.MENU)
	_start_btn.pressed.connect(func(): GameManager.start_new_game())
	_quit_btn.pressed.connect(func(): get_tree().quit())
	_start_btn.grab_focus()

func _process(delta: float) -> void:
	_time += delta
	if _title_label:
		_title_label.modulate.a = 0.86 + sin(_time * 1.2) * 0.14
