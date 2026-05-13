extends Area2D

signal offering_completed(success: bool)
signal altar_activated()

@export var level: int = 1

@onready var _glow: PointLight2D = $Glow
@onready var _label_node: Label = $Label

var _activated: bool = false

func _ready() -> void:
	collision_layer = 2
	collision_mask = 0
	add_to_group("interactable")

func interact() -> void:
	if _activated:
		return
	if GameManager.get_offering_count() == 0:
		DialogManager.show_single("", "御供筒中还没有供物。")
		return

	var expected_count: int = GameManager.get_required_offering_count(level)
	if GameManager.get_offering_count() < expected_count:
		DialogManager.show_single("", "供物似乎还不够。")
		return

	_activated = true
	altar_activated.emit()
	var success := GameManager.validate_altar_order(level)
	if success:
		_play_success_effect()
	else:
		_play_fail_effect()
	offering_completed.emit(success)

func get_interact_name() -> String:
	return "祭坛"

func _play_success_effect() -> void:
	if _glow:
		var tween := create_tween()
		tween.tween_property(_glow, "energy", 1.6, 0.8)
		tween.tween_property(_glow, "color", Color(0.95, 0.78, 0.36, 0.95), 0.4)
	if _label_node:
		_label_node.text = "奉纳完成"
		_label_node.add_theme_color_override("font_color", Color(1.0, 0.88, 0.55))

func _play_fail_effect() -> void:
	if _glow:
		var tween := create_tween()
		tween.tween_property(_glow, "color", Color(0.65, 0.20, 0.18, 0.85), 0.25)
		tween.tween_property(_glow, "energy", 0.9, 0.25)
	if _label_node:
		_label_node.text = "供物次第有误"
		_label_node.add_theme_color_override("font_color", Color(0.9, 0.36, 0.28))
	var reset_tween := create_tween()
	reset_tween.tween_interval(1.2)
	reset_tween.tween_callback(func():
		GameManager.clear_offerings()
		GameManager.restart_current_level()
	)

func reset() -> void:
	_activated = false
	if _label_node:
		_label_node.text = "奉纳"
