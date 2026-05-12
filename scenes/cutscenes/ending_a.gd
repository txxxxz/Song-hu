extends Control

var _phase: int = 0
var _labels: Array[Label] = []

func _ready() -> void:
	_start()

func _start() -> void:
	await get_tree().create_timer(0.6).timeout
	await _show_lines([
		"你没有出声。",
		"白狐转回头，走进本社长明灯的光中。",
	])
	await get_tree().create_timer(1.0).timeout
	await _show_lines([
		"秩序被重新点燃。",
		"村子得救了，山路也恢复安静。",
		"只是有一个名字，再次被温柔地抹去。",
	])
	await get_tree().create_timer(1.2).timeout
	_show_credits()

func _show_lines(lines: Array[String]) -> void:
	_clear()
	for i in range(lines.size()):
		var label := Label.new()
		label.text = lines[i]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.set_anchors_preset(Control.PRESET_CENTER)
		label.position = Vector2(-420, -72 + i * 52)
		label.size = Vector2(840, 48)
		label.add_theme_color_override("font_color", Color(0.86, 0.80, 0.66))
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
	title.add_theme_color_override("font_color", Color(0.95, 0.80, 0.46))
	title.add_theme_font_size_override("font_size", 56)
	add_child(title)

	var subtitle := Label.new()
	subtitle.text = "结局 A：秩序之灯\n按任意键返回主菜单"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.set_anchors_preset(Control.PRESET_CENTER)
	subtitle.position = Vector2(-300, 18)
	subtitle.size = Vector2(600, 90)
	subtitle.add_theme_color_override("font_color", Color(0.74, 0.62, 0.42))
	subtitle.add_theme_font_size_override("font_size", 26)
	add_child(subtitle)
	_phase = 99

func _input(event: InputEvent) -> void:
	if _phase == 99 and event is InputEventKey and event.pressed:
		GameManager.go_to_menu()
