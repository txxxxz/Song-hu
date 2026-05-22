extends Area2D

signal offering_completed(success: bool)
signal altar_activated()

const AudioHelpers = preload("res://autoload/audio_helpers.gd")
const SFX_ALTAR := preload("res://assets/audio/sfx/altar.wav")
const SFX_ALTAR_FAIL := preload("res://assets/audio/sfx/altar_fail.wav")

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
		DialogManager.show_single("", "UI_ALTAR_EMPTY")
		return

	var expected_count: int = GameManager.get_required_offering_count(level)
	if GameManager.get_offering_count() < expected_count:
		DialogManager.show_single("", "UI_ALTAR_NOT_ENOUGH")
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
	return tr("UI_INTERACT_ALTAR")

func _play_success_effect() -> void:
	AudioHelpers.play_one_shot(get_tree().root, SFX_ALTAR)
	if _glow:
		var tween := create_tween()
		tween.tween_property(_glow, "energy", 1.6, 0.8)
		tween.tween_property(_glow, "color", Color(0.95, 0.78, 0.36, 0.95), 0.4)
	if _label_node:
		_label_node.text = tr("UI_ALTAR_COMPLETE")
		_label_node.add_theme_color_override("font_color", Color(1.0, 0.88, 0.55))

func _play_fail_effect() -> void:
	AudioHelpers.play_one_shot(get_tree().root, SFX_ALTAR_FAIL)
	if _glow:
		var tween := create_tween()
		tween.tween_property(_glow, "color", Color(0.65, 0.20, 0.18, 0.85), 0.25)
		tween.tween_property(_glow, "energy", 0.9, 0.25)
	if _label_node:
		_label_node.text = tr("UI_ALTAR_ORDER_ERROR")
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
		_label_node.text = tr("UI_ALTAR_PENALTY")
