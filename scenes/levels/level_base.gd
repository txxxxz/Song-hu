class_name LevelBase
extends Node2D

const FALL_RESTART_Y := 1500.0
const DEFAULT_VIEWPORT_WIDTH := 1280.0
const BACKGROUND_PARALLAX := {
	"Background_Far": 0.78,
	"Background_Mid": 0.90,
	"Background_Near": 0.98,
}
const FoxSpiritScene = preload("res://scenes/objects/fox_spirit.tscn")
const ChoicePanelScene = preload("res://scenes/ui/choice_panel.tscn")

@export var level_width: int = 1280
@export var camera_limit_top: int = -360
@export var camera_limit_bottom: int = 760

@onready var player: CharacterBody2D = _node(["Actors/Player", "Player"]) as CharacterBody2D
@onready var hud_layer: CanvasLayer = _node(["HUD"]) as CanvasLayer
@onready var bgm_player: AudioStreamPlayer = _node(["Audio/BGM", "BGM"]) as AudioStreamPlayer
@onready var ambience_player: AudioStreamPlayer = _node(["Audio/Ambience", "Ambience"]) as AudioStreamPlayer
@onready var sfx_player: AudioStreamPlayer = _node(["Audio/SFX", "SFX"]) as AudioStreamPlayer

var _restart_requested: bool = false
var _background_layers: Array[Dictionary] = []

func _ready() -> void:
	_configure_player_camera()
	_configure_background_layers()
	_on_level_ready()
	_update_background_layers()

func _process(_delta: float) -> void:
	_update_background_layers()
	if _restart_requested:
		return
	if GameManager.current_state != GameManager.State.PLAYING:
		return
	if player and player.global_position.y > FALL_RESTART_Y:
		_restart_requested = true
		_trigger_fall_game_over()

func _trigger_fall_game_over() -> void:
	DialogManager.show_dialog([
		{"speaker": "Game Over", "text": "你坠入黑暗，仪式从这一章重新开始。"},
	] as Array[Dictionary])
	await DialogManager.dialog_finished
	await get_tree().create_timer(0.12).timeout
	_restart_level_after_game_over()

func _restart_level_after_game_over() -> void:
	if GameManager.current_level > 0:
		GameManager.restart_current_level()
		return
	var fallback_scene := scene_file_path
	if fallback_scene == "" and get_tree().current_scene:
		fallback_scene = get_tree().current_scene.scene_file_path
	if fallback_scene == "":
		return
	GameManager.clear_offerings()
	GameManager.set_state(GameManager.State.PLAYING)
	GameManager.change_scene(fallback_scene)

func _node(paths: Array[String]) -> Node:
	for path in paths:
		var found := get_node_or_null(path)
		if found:
			return found
	return null

func _configure_player_camera() -> void:
	if not player:
		return
	var camera := player.get_node_or_null("Camera") as Camera2D
	if not camera:
		return
	camera.limit_left = 0
	camera.limit_top = camera_limit_top
	camera.limit_right = level_width
	camera.limit_bottom = camera_limit_bottom

func _configure_background_layers() -> void:
	_background_layers.clear()
	var viewport_width := _viewport_width()
	var camera_travel = max(float(level_width) - viewport_width, 0.0)
	for layer_name in BACKGROUND_PARALLAX.keys():
		var sprite := get_node_or_null(layer_name) as Sprite2D
		if not sprite or not sprite.texture:
			continue
		var base_position := sprite.position
		var base_scale := sprite.scale
		var factor := float(sprite.get_meta("parallax_factor", BACKGROUND_PARALLAX[layer_name]))
		var texture_width := float(sprite.texture.get_width())
		if texture_width > 0.0:
			var display_width = viewport_width + camera_travel * factor
			sprite.scale.x = base_scale.x * display_width / texture_width
		sprite.scale.y = base_scale.y
		_background_layers.append({
			"sprite": sprite,
			"factor": factor,
			"base_position": base_position,
		})

func _update_background_layers() -> void:
	if not player or _background_layers.is_empty():
		return
	var camera := player.get_node_or_null("Camera") as Camera2D
	if not camera:
		return
	var viewport_width := _viewport_width()
	var max_left = max(float(level_width) - viewport_width, 0.0)
	var camera_left = clamp(camera.global_position.x - viewport_width * 0.5, 0.0, max_left)
	for entry in _background_layers:
		var sprite := entry["sprite"] as Sprite2D
		if not sprite:
			continue
		var factor := float(entry["factor"])
		var base_position := entry["base_position"] as Vector2
		sprite.position.x = base_position.x + camera_left * (1.0 - factor)
		sprite.position.y = base_position.y

func _viewport_width() -> float:
	var viewport := get_viewport()
	if not viewport:
		return DEFAULT_VIEWPORT_WIDTH
	var width := viewport.get_visible_rect().size.x
	return width if width > 0.0 else DEFAULT_VIEWPORT_WIDTH

func _on_level_ready() -> void:
	pass

func play_bgm(stream: AudioStream) -> void:
	if bgm_player:
		bgm_player.stream = stream
		bgm_player.play()

func play_ambience(stream: AudioStream) -> void:
	if ambience_player:
		ambience_player.stream = stream
		ambience_player.play()

func play_sfx(stream: AudioStream) -> void:
	if sfx_player:
		sfx_player.stream = stream
		sfx_player.play()

func fade_bgm(duration: float = 1.0) -> void:
	if not bgm_player or not bgm_player.playing:
		return
	var tween := create_tween()
	tween.tween_property(bgm_player, "volume_db", -40.0, duration)
	tween.tween_callback(bgm_player.stop)

func show_area_name(area_name: String) -> void:
	if hud_layer and hud_layer.has_method("set_area_name"):
		hud_layer.set_area_name(area_name)

func show_choice(title: String, opt_a: String, opt_b: String, desc_a: String = "", desc_b: String = "", callback: Callable = Callable()) -> void:
	var choice_panel = ChoicePanelScene.instantiate()
	add_child(choice_panel)
	choice_panel.show_choice(title, opt_a, opt_b, desc_a, desc_b)
	if callback.is_valid():
		choice_panel.choice_made.connect(callback)

func spawn_fox(pos: Vector2, fox_mode: int = 0) -> Node2D:
	var fox = FoxSpiritScene.instantiate()
	var actor_parent := get_node_or_null("Actors")
	if actor_parent:
		actor_parent.add_child(fox)
	else:
		add_child(fox)
	fox.appear(pos, fox_mode)
	return fox
