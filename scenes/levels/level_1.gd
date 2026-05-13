extends LevelBase

const FOX_FIRE_TEXTURE := preload("res://assets/sprites/effects/fox_fire.png")
const WARM_LIGHT_TEXTURE := preload("res://assets/sprites/effects/warm_light.png")
const FOX_SCREEN_MARGIN_X := 240.0

@onready var _altar_ref: Area2D = $Narrative/Altar
@onready var _elder_ref: Area2D = $Narrative/Elder
@onready var _fox_spawn_marker: Marker2D = $Narrative/FoxSpawnMarker
@onready var _shrine_portal_marker: Marker2D = $Narrative/ShrinePortalMarker
@onready var _bell_fiber_preview: Node2D = $PropsFront/TopOfferingBellFiberPreview
@onready var _fox_stone_preview: Node2D = $PropsFront/TopOfferingFoxStonePreview
@onready var _fx_layer: Node2D = $FX

var _ending_triggered: bool = false
var _intro_flames: Array[Node2D] = []
var _portal_unlocked: bool = false
var _top_offering_monologue_shown: bool = false

func _on_level_ready() -> void:
	_altar_ref.offering_completed.connect(_on_altar_completed)
	_elder_ref.set_dialog([
		{"speaker": "老人", "text": "山里不太平。若你忘了供物次第，就回来看木牌。"},
		{"speaker": "老人", "text": "送狐途中，不要多说话。尤其不要在它回头时唤它的名。"},
	] as Array[Dictionary])
	_set_offering_tube_visible(false)
	show_area_name("第一章  装束之祠")
	GameManager.set_state(GameManager.State.PLAYING)
	play_bgm(preload("res://assets/audio/bgm/forest_night.wav"))
	play_ambience(preload("res://assets/audio/ambience/night_insects.wav"))
	_start_elder_handoff()

func _process(delta: float) -> void:
	super._process(delta)
	if not player:
		return
	var near_portal := _portal_unlocked and _shrine_portal_marker != null and player.global_position.distance_to(_shrine_portal_marker.global_position) < 260.0
	if near_portal and Input.is_action_just_pressed("interact") and not DialogManager.is_active():
		GameManager.transition_to_level(2)
	if player.has_method("set_external_interact_prompt"):
		player.set_external_interact_prompt("E  进入山路" if near_portal else "", near_portal)
	_try_show_top_offering_monologue()

func _try_show_top_offering_monologue() -> void:
	if _top_offering_monologue_shown or _ending_triggered or DialogManager.is_active():
		return
	var expected_count: int = GameManager.ALTAR_ORDERS.get(1, []).size()
	if GameManager.get_offering_count() != expected_count:
		return
	if player.global_position.x < _top_offering_trigger_x():
		return
	_top_offering_monologue_shown = true
	DialogManager.show_dialog([
		{"speaker": "", "text": "老人说：“这两样都能成礼，只是性子不同。绳子会把狐轻轻地请出来；火石会强行让狐现行。”"},
	] as Array[Dictionary])

func _top_offering_trigger_x() -> float:
	var x := 8000.0
	if _bell_fiber_preview and _fox_stone_preview:
		x = minf(_bell_fiber_preview.global_position.x, _fox_stone_preview.global_position.x)
	return x - 620.0

func _start_elder_handoff() -> void:
	await get_tree().create_timer(0.65).timeout
	if _ending_triggered or DialogManager.is_active():
		return
	DialogManager.show_dialog([
		{"speaker": "老人", "text": "今年山里的狐火没有回社，夜路也开始绕人。再拖下去，村里会更不安。"},
		{"speaker": "老人", "text": "你是山社的见习巫女。今夜由你去装束之祠，替我们把狐送上山。"},
		{"speaker": "", "text": "老人把一支黑漆御供筒交到你手里。筒身很冷，像在雨里放了许久。"},
		{"speaker": "老人", "text": "供物的要求写在前面的木牌上。读清楚，再动手。"},
	] as Array[Dictionary])
	await DialogManager.dialog_finished
	_set_offering_tube_visible(true)
	_spawn_intro_flames()

func _set_offering_tube_visible(active: bool) -> void:
	if hud_layer and hud_layer.has_method("set_offering_tube_visible"):
		hud_layer.set_offering_tube_visible(active)

func _spawn_intro_flames() -> void:
	var guide_points := [
		Vector2(940, 360),
		Vector2(1680, 330),
		Vector2(2860, 286),
		Vector2(4040, 360),
		Vector2(5480, 286),
		Vector2(7360, 360),
		Vector2(9040, 330),
	]
	for i in range(guide_points.size()):
		var flame := _make_guide_flame(i)
		flame.global_position = guide_points[i]
		flame.modulate.a = 0.0
		_fx_layer.add_child(flame)
		_intro_flames.append(flame)
		var tween := create_tween()
		tween.tween_interval(0.16 * i)
		tween.tween_property(flame, "modulate:a", 0.95, 0.45)
		var bob := create_tween()
		bob.set_loops()
		bob.tween_property(flame, "position:y", flame.position.y - 18.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		bob.tween_property(flame, "position:y", flame.position.y + 4.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		var flicker := create_tween()
		flicker.set_loops()
		flicker.tween_property(flame, "modulate:a", 0.22, 1.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		flicker.tween_property(flame, "modulate:a", 0.82, 1.05).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _make_guide_flame(index: int) -> Node2D:
	var root := Node2D.new()
	root.name = "IntroGuideFoxfire_%d" % (index + 1)
	root.z_index = 18

	var light := PointLight2D.new()
	light.texture = WARM_LIGHT_TEXTURE
	light.texture_scale = 0.9
	light.energy = 0.55 + index * 0.08
	light.color = Color(1.0, 0.62, 0.25, 0.85)
	root.add_child(light)

	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = _make_foxfire_frames()
	sprite.animation = &"loop"
	sprite.autoplay = "loop"
	sprite.centered = false
	sprite.offset = Vector2(-64, -128)
	sprite.scale = Vector2(0.78, 0.78)
	sprite.modulate = Color(1.0, 0.78, 0.42, 0.92)
	root.add_child(sprite)
	return root

func _make_foxfire_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.add_animation(&"loop")
	frames.set_animation_loop(&"loop", true)
	frames.set_animation_speed(&"loop", 8.0)
	for i in range(8):
		var frame_texture := AtlasTexture.new()
		frame_texture.atlas = FOX_FIRE_TEXTURE
		frame_texture.region = Rect2(i * 128, 0, 128, 128)
		frames.add_frame(&"loop", frame_texture)
	return frames

func _fade_intro_flames() -> void:
	for flame in _intro_flames:
		if not is_instance_valid(flame):
			continue
		var tween := create_tween()
		tween.tween_property(flame, "modulate:a", 0.30, 0.8)
		tween.tween_property(flame, "scale", Vector2(0.82, 0.82), 0.8)

func _on_altar_completed(success: bool) -> void:
	if not success or _ending_triggered:
		return
	_ending_triggered = true
	_fade_intro_flames()
	await get_tree().create_timer(0.8).timeout
	DialogManager.show_dialog([
		{"speaker": "", "text": "御供筒被放上祭坛，木、白、草在微光里一层层安静下来。"},
		{"speaker": "", "text": "梁上的纸垂轻轻摆动，像有人从祠后经过。"},
		{"speaker": "", "text": "白狐已经听见了。最后一道顶礼供物也被压在筒顶。"},
	] as Array[Dictionary])
	await DialogManager.dialog_finished
	var top_id := str(GameManager.peek_offering().get("id", ""))
	if top_id == "bell_fiber":
		GameManager.set_branch(1, "A")
		_play_ending_a()
	elif top_id == "fox_stone":
		GameManager.set_branch(1, "B")
		_play_ending_b()

func _on_final_choice(choice: String) -> void:
	if choice == "A":
		GameManager.set_branch(1, "A")
		_play_ending_a()
	else:
		GameManager.set_branch(1, "B")
		_play_ending_b()

func _play_ending_a() -> void:
	DialogManager.show_dialog([
		{"speaker": "", "text": "你将铃绳纤维轻放在供物之上。"},
		{"speaker": "", "text": "风从鸟居方向吹来，带着铃声的残响。"},
	] as Array[Dictionary])
	await DialogManager.dialog_finished
	var fox := spawn_fox(_fox_pos(), 0)
	await get_tree().create_timer(1.2).timeout
	DialogManager.show_dialog([
		{"speaker": "", "text": "一只白狐从鸟居后走出，安静地看了你一眼。"},
		{"speaker": "", "text": "它转过身，向山上跑去。尾端的狐火温和而平稳。"},
	] as Array[Dictionary])
	await DialogManager.dialog_finished
	fox.depart(Vector2(1.0, -0.08))
	await get_tree().create_timer(1.0).timeout
	_unlock_shrine_portal()

func _play_ending_b() -> void:
	DialogManager.show_dialog([
		{"speaker": "", "text": "你将狐火石嵌入供物之间。"},
		{"speaker": "", "text": "石头表面的火纹猛地亮起，祭坛上的供物开始震颤。"},
	] as Array[Dictionary])
	await DialogManager.dialog_finished
	var fox := spawn_fox(_fox_pos(), 1)
	await get_tree().create_timer(1.2).timeout
	DialogManager.show_dialog([
		{"speaker": "", "text": "白狐从火光中走出。它的狐火忽大忽小，像在喘息。"},
		{"speaker": "", "text": "山路被照得忽明忽暗，前方的影子也变长了。"},
	] as Array[Dictionary])
	await DialogManager.dialog_finished
	fox.depart(Vector2(1.0, -0.08))
	await get_tree().create_timer(1.0).timeout
	_unlock_shrine_portal()

func _unlock_shrine_portal() -> void:
	_portal_unlocked = true
	DialogManager.show_dialog([
		{"speaker": "", "text": "旧鸟居后的山路亮了一瞬，又暗下去。"},
		{"speaker": "", "text": "狐火在门后若隐若现，像是在等你踏过去。"},
	] as Array[Dictionary])

func _fox_pos() -> Vector2:
	var pos := _fox_spawn_marker.global_position if _fox_spawn_marker else Vector2(7600, 420)
	if player:
		var camera := player.get_node_or_null("Camera") as Camera2D
		var camera_center_x := camera.global_position.x if camera else player.global_position.x
		var half_viewport_width := _viewport_width() * 0.5
		pos.x = clampf(
			pos.x,
			camera_center_x - half_viewport_width + FOX_SCREEN_MARGIN_X,
			camera_center_x + half_viewport_width - FOX_SCREEN_MARGIN_X
		)
	return pos
