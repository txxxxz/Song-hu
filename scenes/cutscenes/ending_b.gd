extends Control

var _phase: int = 0
var _labels: Array[Label] = []
var _time: float = 0.0

func _ready() -> void:
	_start()

func _start() -> void:
	await get_tree().create_timer(0.6).timeout
	await _show_lines([
		"你叫出了她的名字。",
		"纱夜。",
	])
	await get_tree().create_timer(1.0).timeout
	await _show_lines([
		"狐火失控，旧纸门、旧木牌和被改写的记录开始燃烧。",
		"「迎狐」剥落，露出底下的「送狐」。",
	])
	await get_tree().create_timer(1.2).timeout
	await _show_lines([
		"山路暂时变得更加危险。",
		"但第二天，村里人开始陆续想起一些本不该忘记的事。",
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
	subtitle.text = "结局 B：真相之灯\n按任意键返回主菜单"
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
