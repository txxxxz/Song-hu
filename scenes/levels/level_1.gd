extends LevelBase

const FOX_FIRE_TEXTURE := preload("res://assets/sprites/effects/fox_fire.png")
const WARM_LIGHT_TEXTURE := preload("res://assets/sprites/effects/warm_light.png")
const SFX_BRANCH_A_BELL_ACCEPT := preload("res://assets/audio/sfx/branch_a_bell_accept.wav")
const SFX_BRANCH_B_FOXFIRE_FORCE := preload("res://assets/audio/sfx/branch_b_foxfire_force.wav")
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
	_elder_ref.set_dialog([] as Array[Dictionary])
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
		{"speaker": "", "text": "两样顶礼供物：旧铃铛和狐火石。"},
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
		{"speaker": "老人", "text": "来了就好。昨晚山路又开始鬼打墙。"},
		{"speaker": "老人", "text": "今晚上要照老规矩，把白狐迎回本社。这是御供筒"},
		{"speaker": "", "text": "老人把黑漆御供筒递给你。筒身冰冷，漆面沾着水，边上刻着细小的狐纹。"},
		{"speaker": "老人", "text": "供物按顺序入筒。杉木、白毛、蓬草。"},
		{"speaker": "老人", "text": "若有什么不懂，按照山上的木牌做，千万别做错了。"},
		{"speaker": "", "text": "老人转过身，又记起来什么的样子，沙哑的声音悠悠传来，在山谷中回响"},
		{"speaker": "老人", "text": "狐上山，不回头。若回头，莫唤名。"},
		{"speaker": "我", "text": "什么名字？"},
		{"speaker": "老人", "text": "想不起来，就不要想。守规矩的人，活得久些。去吧。"},
	] as Array[Dictionary])
	await DialogManager.dialog_finished
	_retire_elder_after_handoff()
	_set_offering_tube_visible(true)
	_spawn_intro_flames()

func _retire_elder_after_handoff() -> void:
	if not _elder_ref:
		return
	_elder_ref.visible = false
	_elder_ref.process_mode = Node.PROCESS_MODE_DISABLED
	_elder_ref.remove_from_group("interactable")
	_elder_ref.collision_layer = 0
	_elder_ref.monitoring = false

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
		{"speaker": "", "text": "御供筒被放上祭坛。杉木、白色纤维和蓬草按顺序落定。"},
		{"speaker": "", "text": "白色纤维摊开时，盖住了中间那层影子。"},
		{"speaker": "", "text": "祠后的纸门轻响。门缝里没有风。"},
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
	play_sfx(SFX_BRANCH_A_BELL_ACCEPT)
	DialogManager.show_dialog([
		{"speaker": "", "text": "你把旧铃铛放在供物最上方。"},
		{"speaker": "", "text": "铃声很远，从山上的雾里落下来。"},
	] as Array[Dictionary])
	await DialogManager.dialog_finished
	var fox := spawn_fox(_fox_pos(), 0)
	await get_tree().create_timer(1.2).timeout
	DialogManager.show_dialog([
		{"speaker": "", "text": "白狐从鸟居后走出。它没有靠近，只看了你一眼。眼睛湿得发亮。"},
		{"speaker": "", "text": "它转身上山，尾端的狐火平稳地亮着。"},
	] as Array[Dictionary])
	await DialogManager.dialog_finished
	fox.depart(Vector2(1.0, -0.08))
	await get_tree().create_timer(1.0).timeout
	_unlock_shrine_portal()

func _play_ending_b() -> void:
	play_sfx(SFX_BRANCH_B_FOXFIRE_FORCE)
	DialogManager.show_dialog([
		{"speaker": "", "text": "你把狐火石嵌进供物之间。"},
		{"speaker": "", "text": "火纹猛地亮起，供桌边缘冒出焦味。"},
	] as Array[Dictionary])
	await DialogManager.dialog_finished
	var fox := spawn_fox(_fox_pos(), 1)
	await get_tree().create_timer(1.2).timeout
	DialogManager.show_dialog([
		{"speaker": "", "text": "白狐从火光里走出。它跑得很急，像被什么东西催促前行。"},
		{"speaker": "", "text": "它转身上山，影子被火拉得很长。"},
	] as Array[Dictionary])
	await DialogManager.dialog_finished
	fox.depart(Vector2(1.0, -0.08))
	await get_tree().create_timer(1.0).timeout
	_unlock_shrine_portal()

func _unlock_shrine_portal() -> void:
	_portal_unlocked = true
	DialogManager.show_dialog([
		{"speaker": "", "text": "旧鸟居后的山路在浓雾中亮了一下。"},
		{"speaker": "", "text": "白狐没有回头。狐火在门后等你。"},
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
