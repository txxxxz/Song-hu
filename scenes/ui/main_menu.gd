extends Control

const LOCALE_OPTIONS := [
	{"locale": "zh_CN", "label_key": "UI_LOCALE_ZH"},
	{"locale": "en", "label_key": "UI_LOCALE_EN"},
]

@onready var _title_label: Label = $TitleLabel
@onready var _subtitle_label: Label = $SubtitleLabel
@onready var _locale_label: Label = $LocaleRow/LocaleLabel
@onready var _locale_option: OptionButton = $LocaleRow/LocaleOption
@onready var _start_btn: Button = $ButtonVBox/StartBtn
@onready var _quit_btn: Button = $ButtonVBox/QuitBtn

var _time: float = 0.0

func _ready() -> void:
	GameManager.set_state(GameManager.State.MENU)
	if not GameManager.locale_changed.is_connected(_refresh_texts):
		GameManager.locale_changed.connect(_refresh_texts)
	if _locale_option and not _locale_option.item_selected.is_connected(_on_locale_selected):
		_locale_option.item_selected.connect(_on_locale_selected)
	_refresh_texts()
	_sync_locale_option()
	_start_btn.pressed.connect(func(): GameManager.start_new_game())
	_quit_btn.pressed.connect(func(): get_tree().quit())
	_start_btn.grab_focus()

func _refresh_texts(_locale: String = "") -> void:
	if _title_label:
		_title_label.text = tr("UI_MENU_TITLE")
	if _subtitle_label:
		_subtitle_label.text = tr("UI_MENU_SUBTITLE")
	if _locale_label:
		_locale_label.text = tr("UI_MENU_LANGUAGE")
	if _start_btn:
		_start_btn.text = tr("UI_MENU_START")
	if _quit_btn:
		_quit_btn.text = tr("UI_MENU_QUIT")
	_refresh_locale_items()

func _refresh_locale_items() -> void:
	if not _locale_option:
		return
	var selected_locale := _current_locale()
	_locale_option.set_block_signals(true)
	_locale_option.clear()
	for option in LOCALE_OPTIONS:
		_locale_option.add_item(tr(str(option["label_key"])))
		_locale_option.set_item_metadata(_locale_option.item_count - 1, str(option["locale"]))
	_sync_locale_option(selected_locale)
	_locale_option.set_block_signals(false)

func _sync_locale_option(selected_locale: String = "") -> void:
	if not _locale_option:
		return
	var locale := selected_locale if selected_locale != "" else _current_locale()
	for index in range(_locale_option.item_count):
		if str(_locale_option.get_item_metadata(index)) == locale:
			_locale_option.select(index)
			return
	_locale_option.select(0)

func _current_locale() -> String:
	if GameManager and str(GameManager.current_locale) != "":
		return str(GameManager.current_locale)
	return str(TranslationServer.get_locale())

func _on_locale_selected(index: int) -> void:
	if not _locale_option:
		return
	if index < 0 or index >= _locale_option.item_count:
		return
	var locale := str(_locale_option.get_item_metadata(index))
	if locale == "":
		return
	GameManager.set_locale(locale)

func _process(delta: float) -> void:
	_time += delta
	if _title_label:
		_title_label.modulate.a = 0.86 + sin(_time * 1.2) * 0.14
