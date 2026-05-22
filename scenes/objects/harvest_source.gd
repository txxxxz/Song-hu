extends Area2D

const AudioHelpers = preload("res://autoload/audio_helpers.gd")
const SFX_COLLECT := preload("res://assets/audio/sfx/collect.wav")
const SFX_CHOP_SUGI_WOOD := preload("res://assets/audio/sfx/chop_sugi_wood.wav")
const SFX_HARVEST_MUGWORT := preload("res://assets/audio/sfx/harvest_mugwort.wav")
const SFX_HARVEST_WATER_GRASS := preload("res://assets/audio/sfx/harvest_water_grass.wav")

@export var item_id: String = ""
@export var item_texture: Texture2D
@export var interact_name: String = "UI_INTERACT_HARVEST"
@export var harvest_dialog: String = ""
@export var max_player_foot_y_distance: float = 72.0
@export_range(1, 99, 1) var max_harvest_count: int = 1

@onready var _visual: Node2D = $Visual

var _harvest_count: int = 0

func _ready() -> void:
	collision_layer = 2
	collision_mask = 0
	add_to_group("interactable")

func interact() -> void:
	if _harvest_count >= max_harvest_count:
		return
	if not GameManager.push_offering(item_id):
		return
	_harvest_count += 1
	if _harvest_count >= max_harvest_count:
		remove_from_group("interactable")
	if harvest_dialog != "":
		DialogManager.show_single("", harvest_dialog)
	_play_harvest_effect()

func get_interact_name() -> String:
	if max_harvest_count > 1:
		return "%s %d/%d" % [tr(interact_name), _harvest_count + 1, max_harvest_count]
	return tr(interact_name)

func can_interact_from(player_position: Vector2) -> bool:
	return absf(player_position.y - global_position.y) <= max_player_foot_y_distance

func _play_harvest_effect() -> void:
	AudioHelpers.play_one_shot(get_tree().root, _harvest_sfx())

	if _visual:
		var shake := create_tween()
		shake.tween_property(_visual, "rotation", -0.06, 0.08)
		shake.tween_property(_visual, "rotation", 0.06, 0.08)
		shake.tween_property(_visual, "rotation", 0.0, 0.08)

	if item_texture:
		var item_sprite := Sprite2D.new()
		item_sprite.texture = item_texture
		item_sprite.centered = false
		item_sprite.offset = Vector2(-64, -128)
		item_sprite.position = Vector2(0, -190)
		item_sprite.modulate.a = 0.0
		add_child(item_sprite)
		var drop := create_tween()
		drop.set_parallel(true)
		drop.tween_property(item_sprite, "modulate:a", 1.0, 0.12)
		drop.tween_property(item_sprite, "position", Vector2(0, -84), 0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		drop.set_parallel(false)
		drop.tween_interval(0.22)
		drop.tween_property(item_sprite, "modulate:a", 0.0, 0.22)
		drop.tween_callback(item_sprite.queue_free)

func _harvest_sfx() -> AudioStream:
	match item_id:
		"sugi_wood":
			return SFX_CHOP_SUGI_WOOD
		"mugwort":
			return SFX_HARVEST_MUGWORT
		"water_grass":
			return SFX_HARVEST_WATER_GRASS
		_:
			return SFX_COLLECT
