extends Area2D

const AudioHelpers = preload("res://autoload/audio_helpers.gd")
const SFX_INTERACT := preload("res://assets/audio/sfx/interact.wav")

@export var dialog_lines: Array[Dictionary] = []

@onready var _visual: Node2D = $Visual

var _time: float = 0.0

func _ready() -> void:
	collision_layer = 2
	collision_mask = 0
	add_to_group("interactable")

func interact() -> void:
	if not dialog_lines.is_empty():
		AudioHelpers.play_one_shot(get_tree().root, SFX_INTERACT)
		DialogManager.show_dialog(dialog_lines)

func get_interact_name() -> String:
	return tr("CHAR_ELDER")

func set_dialog(lines: Array[Dictionary]) -> void:
	dialog_lines = lines

func _process(delta: float) -> void:
	_time += delta
	if _visual:
		_visual.scale.y = 1.0 + sin(_time * 1.4) * 0.01
