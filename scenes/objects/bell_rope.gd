extends Area2D

signal bell_pulled()

const AudioHelpers = preload("res://autoload/audio_helpers.gd")
const SFX_BELL := preload("res://assets/audio/sfx/bell.wav")

@onready var _visual: Node2D = $Visual

var _pulled: bool = false
var _rope_swing: float = 0.0

func _ready() -> void:
	collision_layer = 2
	collision_mask = 0
	add_to_group("interactable")

func interact() -> void:
	if _pulled:
		DialogManager.show_single("", "UI_BELL_ALREADY_PULLED")
		return
	_pulled = true
	_play_pull_animation()
	bell_pulled.emit()

func get_interact_name() -> String:
	return tr("UI_INTERACT_BELL_ROPE")

func _play_pull_animation() -> void:
	AudioHelpers.play_one_shot(self, SFX_BELL)
	if _visual:
		var tween := create_tween()
		tween.tween_property(_visual, "rotation", 0.15, 0.18)
		tween.tween_property(_visual, "rotation", -0.12, 0.18)
		tween.tween_property(_visual, "rotation", 0.06, 0.16)
		tween.tween_property(_visual, "rotation", 0.0, 0.12)
		tween.tween_callback(func():
			DialogManager.show_single("", "UI_BELL_ECHO")
		)

func _process(delta: float) -> void:
	if not _pulled:
		return
	_rope_swing += delta
	if _visual:
		_visual.rotation = sin(_rope_swing * 0.6) * 0.025
