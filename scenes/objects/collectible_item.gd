extends Area2D

const AudioHelpers = preload("res://autoload/audio_helpers.gd")
const SFX_COLLECT := preload("res://assets/audio/sfx/collect.wav")

@export var item_id: String = ""
@export var item_texture: Texture2D
@export var max_player_foot_y_distance: float = 72.0
@export var inspect_before_collect: bool = false
@export var inspect_dialog: String = ""
@export var inspect_interact_name: String = "查看"
@export var collect_interact_name: String = "拿走"

@onready var _visual: Node2D = $Visual

var _collected: bool = false
var _inspected: bool = false
var _bob_time: float = 0.0
var _original_y: float = 0.0

func _ready() -> void:
	collision_layer = 2
	collision_mask = 0
	add_to_group("interactable")
	_apply_texture()
	_original_y = position.y

func _apply_texture() -> void:
	if not item_texture or not _visual:
		return
	var sprite := _visual.get_node_or_null("Sprite") as Sprite2D
	if sprite:
		sprite.texture = item_texture

func _process(delta: float) -> void:
	if _collected:
		return
	_bob_time += delta * 2.3
	position.y = _original_y + sin(_bob_time) * 12.0
	if _visual:
		_visual.rotation = sin(_bob_time * 0.8) * 0.045

func interact() -> void:
	if _collected:
		return
	if inspect_before_collect and not _inspected:
		_inspected = true
		if inspect_dialog != "":
			DialogManager.show_single("", inspect_dialog)
		return
	_collected = true
	if GameManager.push_offering(item_id):
		_play_collect_effect()
	else:
		_collected = false

func get_interact_name() -> String:
	if inspect_before_collect:
		return collect_interact_name if _inspected else inspect_interact_name
	if GameManager.ITEMS.has(item_id):
		return str(GameManager.ITEMS[item_id].get("name", "供物"))
	return "供物"

func can_interact_from(player_position: Vector2) -> bool:
	return absf(player_position.y - _stable_global_y()) <= max_player_foot_y_distance

func _stable_global_y() -> float:
	return global_position.y - (position.y - _original_y)

func _play_collect_effect() -> void:
	AudioHelpers.play_one_shot(get_tree().root, SFX_COLLECT)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(0.35, 0.35), 0.18)
	tween.tween_property(self, "modulate:a", 0.0, 0.28)
	tween.set_parallel(false)
	tween.tween_callback(queue_free)
