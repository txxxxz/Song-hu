extends LevelBase

@onready var _altar_ref: Area2D = $Narrative/Altar
@onready var _bell_ref: Area2D = $Narrative/BellRope
@onready var _bridge_ref: StaticBody2D = $Mechanisms/Bridge
@onready var _hidden_platform: StaticBody2D = $Mechanisms/HiddenPlatform
@onready var _bridge_marker: Marker2D = $Mechanisms/BridgeMarker

var _bridge_placed: bool = false
var _ending_triggered: bool = false

func _on_level_ready() -> void:
	_altar_ref.offering_completed.connect(_on_altar_completed)
	_bell_ref.bell_pulled.connect(_on_bell_pulled)
	_set_platform_enabled(_bridge_ref, false)
	_set_platform_enabled(_hidden_platform, false)
	show_area_name("第二章  断参道")
	GameManager.set_state(GameManager.State.PLAYING)
	play_bgm(preload("res://assets/audio/bgm/approach_theme.wav"))
	play_ambience(preload("res://assets/audio/ambience/broken_approach.wav"))
	await get_tree().create_timer(0.8).timeout
	if GameManager.is_a_path():
		DialogManager.show_dialog([
			{"speaker": "", "text": "白狐沿着参道向上走，偶尔停下回望。"},
			{"speaker": "", "text": "它的步伐很轻，狐火温柔地照亮前路。"},
		] as Array[Dictionary])
	else:
		DialogManager.show_dialog([
			{"speaker": "", "text": "狐火在前方忽明忽灭，照出断裂的参道。"},
			{"speaker": "", "text": "空气里有淡淡焦味，也有一种说不清的压迫感。"},
		] as Array[Dictionary])

func _process(delta: float) -> void:
	super._process(delta)
	if not player:
		return
	var can_bridge_interact := false
	if not _bridge_placed and _bridge_marker:
		can_bridge_interact = player.global_position.distance_to(_bridge_marker.global_position) < 240.0
		if can_bridge_interact and Input.is_action_just_pressed("interact") and not DialogManager.is_active():
			_try_place_bridge()
	if player.has_method("set_external_interact_prompt"):
		if can_bridge_interact:
			var top := GameManager.peek_offering()
			var item_name := str(top.get("name", "供物")) if not top.is_empty() else "需要杉木"
			player.set_external_interact_prompt("E  搭桥：" + item_name, true)
		else:
			player.set_external_interact_prompt("", false)

func _try_place_bridge() -> void:
	var top := GameManager.peek_offering()
	if top.get("id", "") != "sugi_wood":
		DialogManager.show_single("", "断崖太宽了，需要能承托道路的供物。")
		return
	GameManager.pop_offering()
	_bridge_placed = true
	DialogManager.show_dialog([
		{"speaker": "", "text": "你将杉木板架在断崖上。"},
		{"speaker": "", "text": "它托住了你的路，但祭坛仍需要新的杉木作为底层供物。"},
	] as Array[Dictionary])
	_set_platform_enabled(_bridge_ref, true)
	_bridge_ref.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(_bridge_ref, "modulate:a", 1.0, 0.45)

func _on_bell_pulled() -> void:
	_set_platform_enabled(_hidden_platform, true)
	_hidden_platform.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(_hidden_platform, "modulate:a", 1.0, 0.8)

func _set_platform_enabled(node: Node, enabled: bool) -> void:
	if not node:
		return
	node.visible = enabled
	node.process_mode = Node.PROCESS_MODE_INHERIT if enabled else Node.PROCESS_MODE_DISABLED
	if node is CollisionObject2D:
		node.collision_layer = 4 if enabled else 0
	for child in node.get_children():
		if child is CollisionShape2D:
			child.disabled = not enabled
		_set_platform_enabled(child, enabled)

func _on_altar_completed(success: bool) -> void:
	if not success or _ending_triggered:
		return
	_ending_triggered = true
	await get_tree().create_timer(0.8).timeout
	DialogManager.show_dialog([
		{"speaker": "", "text": "供物再次奉上。参道尽头的灯微微亮了。"},
		{"speaker": "", "text": "还差最后一道顶礼供物。"},
	] as Array[Dictionary])
	await DialogManager.dialog_finished
	show_choice(
		"选择顶礼供物",
		"清水草", "灯芯油",
		"镇静，安抚", "继续放大狐火",
		_on_final_choice
	)

func _on_final_choice(choice: String) -> void:
	if choice == "A":
		GameManager.set_branch(2, "A2")
		_play_ending_a2()
	else:
		GameManager.set_branch(2, "B2")
		_play_ending_b2()

func _play_ending_a2() -> void:
	DialogManager.show_dialog([
		{"speaker": "", "text": "你将清水草覆在供物之中。"},
		{"speaker": "", "text": "前方狐火安静下来，白狐的身影在参道尽头若隐若现。"},
	] as Array[Dictionary])
	await DialogManager.dialog_finished
	await get_tree().create_timer(0.8).timeout
	GameManager.transition_to_level(3)

func _play_ending_b2() -> void:
	DialogManager.show_dialog([
		{"speaker": "", "text": "你将灯芯油注入火中。狐火突然爆燃，照亮参道两侧。"},
		{"speaker": "", "text": "石狐像的影子被拉得很长，却不像狐，倒像穿着白衣的人。"},
	] as Array[Dictionary])
	await DialogManager.dialog_finished
	await get_tree().create_timer(0.8).timeout
	GameManager.transition_to_level(3)
