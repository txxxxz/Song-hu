extends CanvasLayer

signal choice_made(choice: String)

@onready var _bg_dim: ColorRect = $BgDim
@onready var _panel: PanelContainer = $BgDim/Center/Panel
@onready var _title_label: Label = $BgDim/Center/Panel/VBox/TitleLabel
@onready var _choice_a_btn: Button = $BgDim/Center/Panel/VBox/HBox/ChoiceA
@onready var _choice_b_btn: Button = $BgDim/Center/Panel/VBox/HBox/ChoiceB

var _choice_a_id: String = "A"
var _choice_b_id: String = "B"

func _ready() -> void:
	layer = 80
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_choice_a_btn.pressed.connect(func(): _on_choice(_choice_a_id))
	_choice_b_btn.pressed.connect(func(): _on_choice(_choice_b_id))

func show_choice(title: String, option_a: String, option_b: String, desc_a: String = "", desc_b: String = "", id_a: String = "A", id_b: String = "B") -> void:
	_choice_a_id = id_a
	_choice_b_id = id_b
	_title_label.text = _t(title)
	_choice_a_btn.text = _t(option_a) + ("\n" + _t(desc_a) if desc_a != "" else "")
	_choice_b_btn.text = _t(option_b) + ("\n" + _t(desc_b) if desc_b != "" else "")
	visible = true
	GameManager.set_state(GameManager.State.CHOICE)
	_bg_dim.color.a = 0.0
	_panel.modulate = Color(1, 1, 1, 0)
	var tween := create_tween()
	tween.tween_property(_bg_dim, "color:a", 0.58, 0.18)
	tween.tween_property(_panel, "modulate:a", 1.0, 0.25)

func _on_choice(choice_id: String) -> void:
	choice_made.emit(choice_id)
	GameManager.set_state(GameManager.State.PLAYING)
	var tween := create_tween()
	tween.parallel().tween_property(_bg_dim, "color:a", 0.0, 0.15)
	tween.parallel().tween_property(_panel, "modulate:a", 0.0, 0.15)
	tween.tween_callback(queue_free)

func _t(key: String) -> String:
	return tr(key).replace("\\n", "\n")
