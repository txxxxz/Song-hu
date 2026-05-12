extends Node2D
## 狐火粒子效果 - 飘浮的灵异火焰
## 用于环境氛围、引路指示、狐灵身上
## 现在使用预生成的精灵纹理

var _particles: Array[Node2D] = []
var _time: float = 0.0
var _count: int = 8
var _color_base: Color = Color(1.0, 0.65, 0.2)
var _spread: float = 60.0
var _intensity: float = 1.0

func setup(count: int = 8, color: Color = Color(1.0, 0.65, 0.2), spread: float = 60.0, intensity: float = 1.0) -> void:
	_count = count
	_color_base = color
	_spread = spread
	_intensity = intensity
	_rebuild()

func _ready() -> void:
	_rebuild()

func _rebuild() -> void:
	for p in _particles:
		p.queue_free()
	_particles.clear()

	for i in range(_count):
		var orb := Node2D.new()
		orb.position = Vector2(
			randf_range(-_spread, _spread),
			randf_range(-_spread * 0.5, _spread * 0.3)
		)
		add_child(orb)

		# 光晕
		var light := PointLight2D.new()
		light.color = _color_base.lerp(Color(0.6, 0.8, 1.0, 0.5), randf())
		light.energy = randf_range(0.2, 0.6) * _intensity
		light.texture = preload("res://assets/sprites/effects/warm_light.png")
		light.texture_scale = randf_range(0.3, 0.8)
		orb.add_child(light)

		# 可见的火球精灵
		var sprite := Sprite2D.new()
		sprite.texture = preload("res://assets/sprites/effects/particle.png")
		sprite.modulate = _color_base.lerp(Color.WHITE, 0.3)
		sprite.modulate.a = 0.7
		var s: float = randf_range(0.5, 1.5)
		sprite.scale = Vector2(s, s)
		orb.add_child(sprite)

		_particles.append(orb)

func _process(delta: float) -> void:
	_time += delta
	for i in range(_particles.size()):
		var p: Node2D = _particles[i]
		var phase: float = i * 1.3
		p.position.x += sin(_time * 0.8 + phase) * 12.0 * delta
		p.position.y += cos(_time * 0.6 + phase) * 8.0 * delta - 3.0 * delta
		if p.position.length() > _spread * 1.5:
			p.position = p.position.normalized() * _spread * 0.5
		p.modulate.a = 0.5 + sin(_time * 3.0 + phase) * 0.3

func set_agitated(agitated: bool) -> void:
	if agitated:
		_color_base = Color(1.0, 0.35, 0.05)
		_intensity = 1.8
	else:
		_color_base = Color(1.0, 0.65, 0.2)
		_intensity = 1.0
	_rebuild()
