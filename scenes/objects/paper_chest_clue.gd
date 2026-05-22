extends Area2D

signal clue_activated(clue_index: int, clue: Node2D)
signal chest_rechecked()

const AudioHelpers = preload("res://autoload/audio_helpers.gd")
const SFX_OLD_CHEST_OPEN := preload("res://assets/audio/sfx/old_chest_open.wav")
const SFX_PAPER_PATCH_RELEASE := preload("res://assets/audio/sfx/paper_patch_release.wav")

@export var clue_index: int = 2
@export var interact_name: String = "UI_INTERACT_OPEN_CHEST"
@export var final_interact_name: String = "UI_INTERACT_RECHECK_NOTE"
@export var max_player_foot_y_distance: float = 128.0
@export var closed_texture: Texture2D
@export var open_texture: Texture2D
@export var masked_paper_texture: Texture2D
@export var revealed_paper_texture: Texture2D

@onready var _visual: Node2D = $Visual
@onready var _sprite: Sprite2D = $Visual/ChestSprite
@onready var _paper_sprite: Sprite2D = $Visual/PaperSprite

var _opened := false
var _final_recheck_enabled := false
var _final_seen := false

func _ready() -> void:
	collision_layer = 2
	collision_mask = 0
	add_to_group("interactable")
	_apply_chest_texture(false)
	_apply_paper_texture(false)
	if _paper_sprite:
		_paper_sprite.visible = false

func interact() -> void:
	if not _opened:
		_opened = true
		remove_from_group("interactable")
		_apply_chest_texture(true)
		_pop_paper(false)
		_play_open_effect()
		clue_activated.emit(clue_index, self)
		return

	if _final_recheck_enabled and not _final_seen:
		_final_seen = true
		remove_from_group("interactable")
		_apply_paper_texture(true)
		_pop_paper(true)
		AudioHelpers.play_one_shot(get_tree().root, SFX_PAPER_PATCH_RELEASE)
		chest_rechecked.emit()

func enable_final_recheck() -> void:
	if _final_seen:
		return
	_final_recheck_enabled = true
	interact_name = final_interact_name
	add_to_group("interactable")
	collision_layer = 2
	if _paper_sprite:
		_paper_sprite.visible = true

func mark_understood() -> void:
	modulate = Color(0.70, 0.78, 0.90, 0.76)

func get_interact_name() -> String:
	return tr(interact_name)

func can_interact_from(player_position: Vector2) -> bool:
	return absf(player_position.y - global_position.y) <= max_player_foot_y_distance

func _apply_chest_texture(opened: bool) -> void:
	if not _sprite:
		return
	if opened and open_texture:
		_sprite.texture = open_texture
	elif not opened and closed_texture:
		_sprite.texture = closed_texture

func _apply_paper_texture(revealed: bool) -> void:
	if not _paper_sprite:
		return
	if revealed and revealed_paper_texture:
		_paper_sprite.texture = revealed_paper_texture
	elif masked_paper_texture:
		_paper_sprite.texture = masked_paper_texture

func _pop_paper(revealed: bool) -> void:
	if not _paper_sprite:
		return
	_apply_paper_texture(revealed)
	_paper_sprite.visible = true
	_paper_sprite.modulate.a = 0.0
	_paper_sprite.position = Vector2(0, -108)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_paper_sprite, "modulate:a", 1.0, 0.12)
	tween.tween_property(_paper_sprite, "position", Vector2(0, -174), 0.34).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _play_open_effect() -> void:
	AudioHelpers.play_one_shot(get_tree().root, SFX_OLD_CHEST_OPEN)

	if _visual:
		var lift := create_tween()
		lift.tween_property(_visual, "position:y", _visual.position.y - 8.0, 0.08)
		lift.tween_property(_visual, "position:y", _visual.position.y, 0.14)
