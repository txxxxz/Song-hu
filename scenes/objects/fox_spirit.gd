extends Node2D

signal fox_appeared()
signal fox_departed()

enum FoxMode { CALM, AGITATED }

@onready var _fox_visual: Node2D = $Visual
@onready var _fox_light: PointLight2D = $FoxLight
@onready var _shadow_visual: Node2D = $Shadow

var mode: FoxMode = FoxMode.CALM
var _time: float = 0.0
var _is_visible: bool = false

func _ready() -> void:
	visible = false
	if _shadow_visual:
		_shadow_visual.modulate = Color(1, 1, 1, 0)

func appear(at_position: Vector2, fox_mode: FoxMode = FoxMode.CALM) -> void:
	global_position = at_position
	mode = fox_mode
	visible = true
	_is_visible = true
	modulate = Color(1, 1, 1, 0)
	var sprite := _sprite()
	if sprite:
		if sprite.sprite_frames.has_animation("appear"):
			sprite.play("appear")
			sprite.animation_finished.connect(func():
				if is_instance_valid(sprite) and sprite.sprite_frames.has_animation("idle"):
					sprite.play("idle")
			, CONNECT_ONE_SHOT)
		else:
			sprite.play("idle")
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 1.0)
	tween.tween_callback(func(): fox_appeared.emit())
	if mode == FoxMode.AGITATED and _fox_light:
		_fox_light.color = Color(1.0, 0.45, 0.13)
		_fox_light.energy = 1.7

func depart(direction: Vector2) -> void:
	var target_pos := global_position + direction.normalized() * 1000.0
	var sprite := _sprite()
	if sprite:
		if sprite.sprite_frames.has_animation("depart"):
			sprite.play("depart")
		elif sprite.sprite_frames.has_animation("walk"):
			sprite.play("walk")
	var tween := create_tween()
	tween.tween_property(self, "global_position", target_pos, 2.4).set_ease(Tween.EASE_IN)
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 2.0).set_delay(0.4)
	tween.set_parallel(false)
	tween.tween_callback(func():
		_is_visible = false
		fox_departed.emit()
		queue_free()
	)

func look_back() -> void:
	var sprite := _sprite()
	if sprite and sprite.sprite_frames.has_animation("look_back"):
		sprite.play("look_back")
		await sprite.animation_finished
		sprite.play("idle")

func _process(delta: float) -> void:
	if not _is_visible:
		return
	_time += delta
	if _fox_light:
		if mode == FoxMode.CALM:
			_fox_light.energy = 0.75 + sin(_time * 2.0) * 0.12
		else:
			_fox_light.energy = 1.25 + sin(_time * 5.0) * 0.38 + sin(_time * 13.0) * 0.22
			_fox_light.color = Color(1.0, 0.42 + sin(_time * 3.0) * 0.12, 0.10)
	if mode == FoxMode.AGITATED and _shadow_visual:
		_shadow_visual.modulate.a = clampf(sin(_time * 1.5) * 0.25 + 0.12, 0.0, 0.45)
		_shadow_visual.position = Vector2(sin(_time * 2.0) * 12.0, 0)
	if _fox_visual:
		_fox_visual.position.y = sin(_time * 1.8) * 8.0

func _sprite() -> AnimatedSprite2D:
	return _fox_visual.get_node_or_null("FoxSprite") if _fox_visual else null
