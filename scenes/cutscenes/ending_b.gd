extends Control

const AudioHelpers = preload("res://autoload/audio_helpers.gd")
const BGM_ENDING_B := preload("res://assets/audio/bgm/ending_b_name_return.wav")

var _phase: int = 0
var _labels: Array[Label] = []
var _time: float = 0.0

func _ready() -> void:
	AudioHelpers.play_music(self, BGM_ENDING_B)
	_start()

func _start() -> void:
	await get_tree().create_timer(0.6).timeout
	await _show_lines([
		"你叫出了她的名字。",
		"……纱夜。",
	])
	await get_tree().create_timer(1.0).timeout
	await _show_lines([
		"白狐停下。狐火从她身上剥落，白衣从火里显出来。",
		"她跪在长明灯前，抓住你的袖子。",
	])
	await get_tree().create_timer(1.2).timeout
	await _show_lines([
		"下一刻，本社的灯同时晃动。屋檐开始滴水。",
		"山路错乱成怪圈，井水悄无声息的涌出井口，",
		"村口的石灯一盏盏熄灭。",
	])
	await get_tree().create_timer(1.2).timeout
	await _show_lines([
		"天亮以后，村里陆续有人开始问：纱夜是谁",
		"有人想起那是一个神社巫女",
		"也有人想起，自己曾经答应过不要说。",
	])
	await get_tree().create_timer(1.2).timeout
	await _show_lines([
		"纱夜的手很冷。",
		"但那是人的手。",
	])
	await get_tree().create_timer(1.2).timeout
	_show_credits()

func _process(delta: float) -> void:
	_time += delta
	for child in get_children():
		if child is Sprite2D:
			child.position.y -= 18.0 * delta
			child.modulate.a = 0.45 + sin(_time * 2.0 + child.position.x) * 0.12

func _show_lines(lines: Array[String]) -> void:
	_clear()
	for i in range(lines.size()):
		var label := Label.new()
		label.text = lines[i]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.set_anchors_preset(Control.PRESET_CENTER)
		label.position = Vector2(-450, -72 + i * 58)
		label.size = Vector2(900, 54)
		label.add_theme_color_override("font_color", Color(0.92, 0.75, 0.52))
		label.add_theme_font_size_override("font_size", 30)
		label.modulate.a = 0
		add_child(label)
		_labels.append(label)
		var tween := create_tween()
		tween.tween_property(label, "modulate:a", 1.0, 0.45).set_delay(i * 0.35)
	await get_tree().create_timer(lines.size() * 0.35 + 1.0).timeout

func _clear() -> void:
	for label in _labels:
		if is_instance_valid(label):
			label.queue_free()
	_labels.clear()

func _show_credits() -> void:
	_clear()
	var title := Label.new()
	title.text = "送狐"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.set_anchors_preset(Control.PRESET_CENTER)
	title.position = Vector2(-300, -70)
	title.size = Vector2(600, 70)
	title.add_theme_color_override("font_color", Color(1.0, 0.76, 0.42))
	title.add_theme_font_size_override("font_size", 56)
	add_child(title)

	var subtitle := Label.new()
	subtitle.text = "结局 B：回名\n按任意键返回主菜单"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.set_anchors_preset(Control.PRESET_CENTER)
	subtitle.position = Vector2(-300, 18)
	subtitle.size = Vector2(600, 90)
	subtitle.add_theme_color_override("font_color", Color(0.86, 0.58, 0.34))
	subtitle.add_theme_font_size_override("font_size", 26)
	add_child(subtitle)
	_phase = 99

func _input(event: InputEvent) -> void:
	if _phase == 99 and event is InputEventKey and event.pressed:
		GameManager.go_to_menu()
