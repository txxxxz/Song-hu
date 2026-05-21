extends Area2D

@export var item_id: String = "white_fur"
@export var item_texture: Texture2D
@export var closed_texture: Texture2D
@export var open_texture: Texture2D
@export var interact_name: String = "打开箱子"
@export var take_dialog: String = "箱里放着一束白色纤维，箱子上刻着「白毛」，边缘却压得很平，潮了也不会打卷。"
@export var max_player_foot_y_distance: float = 128.0

@onready var _visual: Node2D = $Visual
@onready var _sprite: Sprite2D = $Visual/ChestSprite

var _opened: bool = false
var _sfx_collect: AudioStream = preload("res://assets/audio/sfx/collect.wav")

func _ready() -> void:
	collision_layer = 2
	collision_mask = 0
	add_to_group("interactable")
	_apply_closed_texture()

func interact() -> void:
	if _opened:
		return
	if not GameManager.push_offering(item_id):
		return

	_opened = true
	remove_from_group("interactable")
	_apply_open_texture()
	if take_dialog != "":
		DialogManager.show_single("", take_dialog)
	_play_open_effect()

func get_interact_name() -> String:
	return interact_name

func can_interact_from(player_position: Vector2) -> bool:
	return absf(player_position.y - global_position.y) <= max_player_foot_y_distance

func _apply_closed_texture() -> void:
	if _sprite and closed_texture:
		_sprite.texture = closed_texture

func _apply_open_texture() -> void:
	if _sprite and open_texture:
		_sprite.texture = open_texture

func _play_open_effect() -> void:
	var sfx := AudioStreamPlayer.new()
	sfx.stream = _sfx_collect
	sfx.volume_db = -3.0
	get_tree().root.add_child(sfx)
	sfx.play()
	sfx.finished.connect(sfx.queue_free)

	if _visual:
		var lift := create_tween()
		lift.tween_property(_visual, "position:y", _visual.position.y - 8.0, 0.08)
		lift.tween_property(_visual, "position:y", _visual.position.y, 0.14)

	if item_texture:
		var item_sprite := Sprite2D.new()
		item_sprite.texture = item_texture
		item_sprite.centered = false
		item_sprite.offset = Vector2(-64, -128)
		item_sprite.position = Vector2(0, -78)
		item_sprite.scale = Vector2(0.75, 0.75)
		item_sprite.modulate.a = 0.0
		add_child(item_sprite)

		var reveal := create_tween()
		reveal.set_parallel(true)
		reveal.tween_property(item_sprite, "modulate:a", 1.0, 0.12)
		reveal.tween_property(item_sprite, "position", Vector2(0, -150), 0.34).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		reveal.set_parallel(false)
		reveal.tween_interval(0.2)
		reveal.tween_property(item_sprite, "modulate:a", 0.0, 0.22)
		reveal.tween_callback(item_sprite.queue_free)
