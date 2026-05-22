extends CharacterBody2D

const SPEED := 260.0
const ACCELERATION := 1900.0
const FRICTION := 2400.0
const AIR_ACCELERATION := 1250.0
const AIR_FRICTION := 420.0
const JUMP_VELOCITY := -560.0
const JUMP_CUT_FACTOR := 0.42
const GRAVITY := 980.0
const MAX_FALL_SPEED := 720.0
const COYOTE_TIME := 0.12
const JUMP_BUFFER := 0.10
const FOOTSTEP_INTERVAL := 0.26
const PLAYER_DRAW_Z_INDEX := 1000

signal interacted(target: Node2D)

@onready var visual: Node2D = $Visual
@onready var sprite: AnimatedSprite2D = $Visual/Sprite
@onready var interact_prompt: Control = $InteractPrompt
@onready var interact_prompt_key_label: Label = $InteractPrompt/KeyLabel
@onready var interact_prompt_action_label: Label = $InteractPrompt/ActionLabel
@onready var camera: Camera2D = $Camera
@onready var player_light: PointLight2D = $PlayerLight
@onready var interaction_area: Area2D = $InteractionArea
@onready var _sfx_player: AudioStreamPlayer = $SFXPlayer

var facing_right: bool = true
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var was_on_floor: bool = false
var nearest_interactable: Node2D = null
var _nearby_interactables: Array[Node2D] = []
var _external_prompt_text: String = ""
var _external_prompt_active: bool = false
var _footstep_timer: float = 0.0
var _forced_anim_name: String = ""
var _forced_anim_timer: float = 0.0
var _jump_sfx_index: int = 0
var _wood_footstep_sfx_index: int = 0
var _sfx_jump_variants: Array[AudioStream] = [
	preload("res://assets/audio/sfx/jump.wav"),
	preload("res://assets/audio/sfx/jump_1.wav"),
]
var _sfx_footstep: AudioStream = preload("res://assets/audio/sfx/footstep.wav")
var _sfx_wood_footsteps: Array[AudioStream] = [
	preload("res://assets/audio/sfx/footstep_wood_bridge.wav"),
	preload("res://assets/audio/sfx/footstep_wood_bridge_1.wav"),
	preload("res://assets/audio/sfx/footstep_wood_bridge_2.wav"),
	preload("res://assets/audio/sfx/footstep_wood_bridge_3.wav"),
]

func _ready() -> void:
	_configure_draw_order()
	GameManager.player_ref = self
	_layout_interact_prompt()
	interaction_area.body_entered.connect(_on_interaction_entered)
	interaction_area.body_exited.connect(_on_interaction_exited)
	interaction_area.area_entered.connect(_on_interact_area_entered)
	interaction_area.area_exited.connect(_on_interact_area_exited)

func _configure_draw_order() -> void:
	z_as_relative = false
	z_index = PLAYER_DRAW_Z_INDEX

func _layout_interact_prompt() -> void:
	if not interact_prompt:
		return
	interact_prompt.scale = Vector2.ONE

func _physics_process(delta: float) -> void:
	if GameManager.current_state != GameManager.State.PLAYING:
		return

	if not is_on_floor():
		velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL_SPEED)

	if is_on_floor():
		coyote_timer = COYOTE_TIME
	elif was_on_floor:
		coyote_timer -= delta

	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = JUMP_BUFFER
	if jump_buffer_timer > 0.0:
		jump_buffer_timer -= delta

	if jump_buffer_timer > 0.0 and coyote_timer > 0.0:
		velocity.y = JUMP_VELOCITY
		jump_buffer_timer = 0.0
		coyote_timer = 0.0
		_play_sfx(_next_jump_sfx())

	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= JUMP_CUT_FACTOR

	var input_dir := Input.get_axis("move_left", "move_right")
	if is_on_floor():
		velocity.x = move_toward(velocity.x, input_dir * SPEED, (ACCELERATION if input_dir != 0.0 else FRICTION) * delta)
	else:
		velocity.x = move_toward(velocity.x, input_dir * SPEED, (AIR_ACCELERATION if input_dir != 0.0 else AIR_FRICTION) * delta)

	var previous_facing := facing_right
	if input_dir > 0.0:
		facing_right = true
	elif input_dir < 0.0:
		facing_right = false
	if previous_facing != facing_right and is_on_floor():
		_force_anim("turn", 0.18)
	visual.scale.x = 1.0 if facing_right else -1.0
	if interact_prompt:
		interact_prompt.scale.x = 1.0

	if _forced_anim_timer > 0.0:
		_forced_anim_timer -= delta

	was_on_floor = is_on_floor()
	move_and_slide()
	_refresh_nearest_interactable()
	_update_animation()
	_update_footsteps(delta)
	_update_prompt()

func set_external_interact_prompt(prompt_text: String, active: bool) -> void:
	_external_prompt_text = prompt_text
	_external_prompt_active = active

func _play_sfx(stream: AudioStream) -> void:
	if _sfx_player and stream:
		_sfx_player.stream = stream
		_sfx_player.play()

func _update_footsteps(delta: float) -> void:
	if is_on_floor() and absf(velocity.x) > 12.0:
		_footstep_timer -= delta
		if _footstep_timer <= 0.0:
			_play_sfx(_current_footstep_sfx())
			_footstep_timer = FOOTSTEP_INTERVAL
	else:
		_footstep_timer = 0.0

func _next_jump_sfx() -> AudioStream:
	var stream := _sfx_jump_variants[_jump_sfx_index % _sfx_jump_variants.size()]
	_jump_sfx_index += 1
	return stream

func _current_footstep_sfx() -> AudioStream:
	if _is_on_wood_footstep_surface():
		var stream := _sfx_wood_footsteps[_wood_footstep_sfx_index % _sfx_wood_footsteps.size()]
		_wood_footstep_sfx_index += 1
		return stream
	return _sfx_footstep

func _is_on_wood_footstep_surface() -> bool:
	for i in range(get_slide_collision_count()):
		var collision := get_slide_collision(i)
		if not collision or collision.get_normal().y > -0.65:
			continue
		var collider := collision.get_collider()
		if collider is Node and (collider as Node).is_in_group("wood_footstep"):
			return true
	return false

func _update_prompt() -> void:
	if nearest_interactable:
		_show_interact_prompt(_build_interact_prompt_text(nearest_interactable), not DialogManager.is_active())
	elif _external_prompt_active:
		_show_interact_prompt(_external_prompt_text if _external_prompt_text != "" else "E", not DialogManager.is_active())
	else:
		_show_interact_prompt("", false)

func _show_interact_prompt(prompt_text: String, active: bool) -> void:
	if not interact_prompt:
		return
	interact_prompt.visible = active
	if not active:
		return
	var key_text := "E"
	var action_text := prompt_text.strip_edges()
	if interact_prompt_key_label:
		interact_prompt_key_label.text = key_text
	if interact_prompt_action_label:
		interact_prompt_action_label.text = action_text
		interact_prompt_action_label.visible = action_text != ""

func _build_interact_prompt_text(target: Node) -> String:
	if target and target.has_method("get_interact_name"):
		var interact_name := str(target.call("get_interact_name"))
		if interact_name != "":
			return interact_name
	return ""

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact"):
		return
	_refresh_nearest_interactable()
	if nearest_interactable and not DialogManager.is_active():
		interacted.emit(nearest_interactable)
		_force_anim("interact", 0.36)
		if nearest_interactable.has_method("interact"):
			nearest_interactable.interact()
		get_viewport().set_input_as_handled()

func _on_interaction_entered(body: Node2D) -> void:
	if body.is_in_group("interactable"):
		_add_interactable(body)

func _on_interaction_exited(body: Node2D) -> void:
	_remove_interactable(body)

func _on_interact_area_entered(area: Area2D) -> void:
	if area.is_in_group("interactable"):
		_add_interactable(area)

func _on_interact_area_exited(area: Area2D) -> void:
	_remove_interactable(area)

func _add_interactable(target: Node2D) -> void:
	if target and not _nearby_interactables.has(target):
		_nearby_interactables.append(target)
	_refresh_nearest_interactable()

func _remove_interactable(target: Node2D) -> void:
	_nearby_interactables.erase(target)
	if nearest_interactable == target:
		nearest_interactable = null
	_refresh_nearest_interactable()

func _refresh_nearest_interactable() -> void:
	var best: Node2D = null
	var best_distance := INF
	for target in _nearby_interactables.duplicate():
		if not is_instance_valid(target) or not target.is_inside_tree():
			_nearby_interactables.erase(target)
			continue
		if not target.is_in_group("interactable"):
			continue
		if not _can_reach_interactable(target):
			continue
		var distance := global_position.distance_squared_to(target.global_position)
		if distance < best_distance:
			best = target
			best_distance = distance
	nearest_interactable = best

func _can_reach_interactable(target: Node2D) -> bool:
	if target.has_method("can_interact_from"):
		return bool(target.call("can_interact_from", global_position))
	return true

func _update_animation() -> void:
	if not sprite or not sprite.sprite_frames:
		return
	if _forced_anim_timer > 0.0 and _forced_anim_name != "" and sprite.sprite_frames.has_animation(_forced_anim_name):
		_play_anim(_forced_anim_name)
	elif not is_on_floor():
		_play_anim("jump" if velocity.y < 0.0 else "fall")
	elif absf(velocity.x) > 12.0:
		_play_anim("run")
	else:
		_play_anim("idle")

func _force_anim(anim_name: String, duration: float) -> void:
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation(anim_name):
		_forced_anim_name = anim_name
		_forced_anim_timer = duration

func _play_anim(anim_name: String) -> void:
	if sprite.sprite_frames.has_animation(anim_name) and sprite.animation != anim_name:
		sprite.play(anim_name)
