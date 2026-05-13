extends Area2D

signal clue_activated(clue_index: int, clue: Node2D)

@export var clue_index: int = 0
@export var interact_name: String = "查看线索"
@export var max_player_foot_y_distance: float = 104.0

var _used: bool = false

func _ready() -> void:
	collision_layer = 2
	collision_mask = 0
	add_to_group("interactable")

func interact() -> void:
	if _used:
		return
	_used = true
	remove_from_group("interactable")
	clue_activated.emit(clue_index, self)
	mark_understood()

func mark_understood() -> void:
	_used = true
	remove_from_group("interactable")
	collision_layer = 0
	for child in get_children():
		if child is CollisionShape2D:
			(child as CollisionShape2D).set_deferred("disabled", true)
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color(0.60, 0.74, 0.95, 0.58), 0.24)

func get_interact_name() -> String:
	return interact_name

func can_interact_from(player_position: Vector2) -> bool:
	return absf(player_position.y - global_position.y) <= max_player_foot_y_distance
