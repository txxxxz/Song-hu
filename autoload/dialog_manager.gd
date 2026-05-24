extends Node

signal dialog_started()
signal dialog_finished()
signal dialog_line_shown(text: String)

var _canvas: CanvasLayer
var _dialog_box: PanelContainer
var _speaker_label: Label
var _text_label: RichTextLabel
var _continue_indicator: Label
var _dialog_queue: Array[Dictionary] = []
var _current_line: int = -1
var _is_showing: bool = false
var _is_typing: bool = false
var _type_speed: float = 0.018
var _tween: Tween
var _voice_player: AudioStreamPlayer
var _persistent_voice_player: AudioStreamPlayer
var _voice_cache: Dictionary = {}
var _dialog_options: Dictionary = {}
var _voice_persistent: bool = false
var _voice_started_for_dialog: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_create_ui()

func _create_ui() -> void:
	_canvas = CanvasLayer.new()
	_canvas.layer = 90
	add_child(_canvas)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	margin.offset_left = 160
	margin.offset_right = -160
	margin.offset_top = -268
	margin.offset_bottom = -44
	_canvas.add_child(margin)

	_dialog_box = PanelContainer.new()
	var style := StyleBoxTexture.new()
	style.texture = preload("res://assets/ui/dialog_box.png")
	style.texture_margin_left = 32
	style.texture_margin_right = 32
	style.texture_margin_top = 32
	style.texture_margin_bottom = 32
	style.content_margin_left = 58
	style.content_margin_right = 58
	style.content_margin_top = 36
	style.content_margin_bottom = 34
	_dialog_box.add_theme_stylebox_override("panel", style)
	margin.add_child(_dialog_box)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	_dialog_box.add_child(vbox)

	_speaker_label = Label.new()
	_speaker_label.add_theme_color_override("font_color", Color(0.95, 0.73, 0.36))
	_speaker_label.add_theme_font_size_override("font_size", 22)
	vbox.add_child(_speaker_label)

	_text_label = RichTextLabel.new()
	_text_label.bbcode_enabled = true
	_text_label.fit_content = true
	_text_label.scroll_active = false
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text_label.add_theme_color_override("default_color", Color(0.94, 0.90, 0.83))
	_text_label.add_theme_font_size_override("normal_font_size", 28)
	_text_label.custom_minimum_size = Vector2(0, 80)
	vbox.add_child(_text_label)

	_continue_indicator = Label.new()
	_continue_indicator.text = "v"
	_continue_indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_continue_indicator.add_theme_color_override("font_color", Color(0.78, 0.58, 0.30, 0.75))
	_continue_indicator.add_theme_font_size_override("font_size", 20)
	vbox.add_child(_continue_indicator)
	_continue_indicator.visible = false

	_voice_player = AudioStreamPlayer.new()
	add_child(_voice_player)
	_persistent_voice_player = AudioStreamPlayer.new()
	add_child(_persistent_voice_player)
	_canvas.visible = false

func show_dialog(lines: Array[Dictionary], options: Dictionary = {}) -> void:
	_dialog_queue = lines
	_current_line = -1
	_is_showing = true
	_dialog_options = options
	_voice_persistent = bool(_dialog_options.get("voice_persistent", false))
	_voice_started_for_dialog = false
	_stop_voice()
	_canvas.visible = true
	GameManager.set_state(GameManager.State.DIALOG)
	dialog_started.emit()
	_advance()

func show_single(speaker: String, text: String) -> void:
	show_dialog([{"speaker": speaker, "text": text}] as Array[Dictionary])

func is_active() -> bool:
	return _is_showing

func _advance() -> void:
	if _is_typing:
		_text_label.visible_ratio = 1.0
		if _tween:
			_tween.kill()
		_is_typing = false
		_continue_indicator.visible = true
		return

	_current_line += 1
	if _current_line >= _dialog_queue.size():
		_close()
		return

	var line := _dialog_queue[_current_line]
	_speaker_label.text = _t(str(line.get("speaker", "")))
	_speaker_label.visible = _speaker_label.text != ""
	var text_key := str(line.get("text", ""))
	_text_label.text = _t(text_key)
	_text_label.visible_ratio = 0.0
	_continue_indicator.visible = false
	_play_voice_for_line(line, text_key)

	_is_typing = true
	var char_count: int = maxi(_text_label.get_total_character_count(), _text_label.text.length())
	var duration: float = maxf(0.12, char_count * _type_speed)
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_text_label, "visible_ratio", 1.0, duration)
	_tween.tween_callback(func():
		_is_typing = false
		_continue_indicator.visible = true
	)
	dialog_line_shown.emit(_text_label.text)

func _t(key: String) -> String:
	return tr(key).replace("\\n", "\n")

func _close() -> void:
	_stop_voice()
	_is_showing = false
	_canvas.visible = false
	_dialog_queue.clear()
	_current_line = -1
	_dialog_options = {}
	_voice_persistent = false
	_voice_started_for_dialog = false
	if GameManager.current_state == GameManager.State.DIALOG:
		GameManager.set_state(GameManager.State.PLAYING)
	dialog_finished.emit()

func _input(event: InputEvent) -> void:
	if not _is_showing:
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("jump"):
		_advance()
		get_viewport().set_input_as_handled()

func _play_voice_for_line(line: Dictionary, text_key: String) -> void:
	var voice_key := str(line.get("voice_key", _dialog_options.get("voice_key", "")))
	if voice_key.is_empty():
		voice_key = text_key

	var voice_persistent := bool(line.get("voice_persistent", _dialog_options.get("voice_persistent", false)))
	var voice_volume_db := float(line.get("voice_volume_db", _dialog_options.get("voice_volume_db", -3.0)))
	var voice_bus := str(line.get("voice_bus", _dialog_options.get("voice_bus", "")))

	if voice_persistent and _voice_started_for_dialog:
		return

	if not voice_persistent:
		_stop_voice()

	if voice_key.is_empty():
		return

	var stream := _get_voice_stream(voice_key)
	if stream == null:
		return

	var player := _persistent_voice_player if voice_persistent else _voice_player
	player.stream = stream
	player.volume_db = voice_volume_db
	player.bus = voice_bus if voice_bus != "" else "Master"
	player.play()
	_voice_started_for_dialog = voice_persistent

func _stop_voice() -> void:
	if _voice_player != null:
		_voice_player.stop()
		_voice_player.stream = null
		_voice_player.bus = "Master"
	if _persistent_voice_player != null:
		_persistent_voice_player.stop()
		_persistent_voice_player.stream = null
		_persistent_voice_player.bus = "Master"

func _get_voice_stream(voice_key: String) -> AudioStream:
	if _voice_cache.has(voice_key):
		return _voice_cache[voice_key] as AudioStream

	var path := ""
	for extension in ["mp3", "wav"]:
		var candidate := "res://assets/audio/dialog/%s.%s" % [voice_key, extension]
		if ResourceLoader.exists(candidate):
			path = candidate
			break

	if path.is_empty():
		_voice_cache[voice_key] = null
		return null

	var stream := load(path) as AudioStream
	_voice_cache[voice_key] = stream
	return stream
