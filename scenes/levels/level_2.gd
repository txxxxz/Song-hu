extends LevelBase

@onready var _altar_ref: Area2D = $Narrative/Altar
@onready var _bell_ref: Area2D = $Narrative/BellRope
@onready var _hidden_platform: StaticBody2D = $Mechanisms/HiddenPlatform
@onready var _ladder_marker: Marker2D = $Mechanisms/LadderMarker
@onready var _ladder_ref: StaticBody2D = $Mechanisms/LadderGrass
@onready var _water_grass_source: Area2D = $Mechanisms/WaterGrassSource
@onready var _bridge_spots: Array[Dictionary] = [
	{
		"bridge": $Mechanisms/Bridge,
		"marker": $Mechanisms/BridgeMarker,
		"placed": false,
		"success": "你将杉木板架在断崖上。",
		"note": "它托住了你的路，但祭坛仍需要新的杉木作为底层供物。",
	},
	{
		"bridge": $Mechanisms/BridgeSecond,
		"marker": $Mechanisms/BridgeMarkerSecond,
		"placed": false,
		"success": "你把杉木铺在第二处断裂的参道上。",
		"note": "木头压住碎石，脚下的空缺暂时安静下来。",
	},
	{
		"bridge": $Mechanisms/BridgeThird,
		"marker": $Mechanisms/BridgeMarkerThird,
		"placed": false,
		"success": "你把最后一段杉木推过缺口。",
		"note": "参道连上了，但远处的灯火比刚才更蓝。",
	},
]

const TOOL_INTERACT_DISTANCE := 240.0
const FLAME_RED := Color(1.0, 0.2, 0.12, 1.0)
const FLAME_BLUE := Color(0.48, 0.78, 1.0, 1.0)
const LIGHT_RED := Color(1.0, 0.18, 0.08, 0.92)
const LIGHT_BLUE := Color(0.42, 0.72, 1.0, 0.92)

var _ladder_used: bool = false
var _lamp_nodes: Array[Dictionary] = []
var _red_flame_frames: SpriteFrames
var _blue_flame_frames: SpriteFrames
var _lamps_are_blue: bool = false
var _ending_triggered: bool = false

func _on_level_ready() -> void:
	_altar_ref.offering_completed.connect(_on_altar_completed)
	_bell_ref.bell_pulled.connect(_on_bell_pulled)
	_setup_lamp_nodes()
	_set_all_lamps_blue(false)
	_configure_ladder_collision()
	for spot in _bridge_spots:
		_set_platform_enabled(spot["bridge"] as Node, false)
	_set_platform_enabled(_hidden_platform, false)
	_set_platform_enabled(_ladder_ref, false)
	_place_water_grass_on_hidden_platform()
	_set_interactable_enabled(_water_grass_source, false)
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
	var action := _nearest_tool_action()
	if not action.is_empty() and Input.is_action_just_pressed("interact") and not DialogManager.is_active():
		_try_tool_action(action)
	if player.has_method("set_external_interact_prompt"):
		if not action.is_empty():
			player.set_external_interact_prompt(_tool_prompt(action), true)
		else:
			player.set_external_interact_prompt("", false)

func _nearest_tool_action() -> Dictionary:
	var best: Dictionary = {}
	var best_distance := INF
	for i in range(_bridge_spots.size()):
		var spot := _bridge_spots[i]
		if bool(spot.get("placed", false)):
			continue
		var marker := spot.get("marker") as Marker2D
		if not marker:
			continue
		var distance := player.global_position.distance_to(marker.global_position)
		if distance < TOOL_INTERACT_DISTANCE and distance < best_distance:
			best = {"kind": "bridge", "index": i}
			best_distance = distance
	if not _ladder_used and _ladder_marker:
		var ladder_distance := player.global_position.distance_to(_ladder_marker.global_position)
		if ladder_distance < TOOL_INTERACT_DISTANCE and ladder_distance < best_distance:
			best = {"kind": "ladder"}
			best_distance = ladder_distance
	if _lamps_are_blue:
		for i in range(_lamp_nodes.size()):
			var lamp: Dictionary = _lamp_nodes[i]
			if bool(lamp.get("oil_taken", false)):
				continue
			var oil_position := _lamp_position(lamp)
			var oil_distance := player.global_position.distance_to(oil_position)
			if oil_distance < TOOL_INTERACT_DISTANCE and oil_distance < best_distance:
				best = {"kind": "oil", "index": i}
				best_distance = oil_distance
	return best

func _tool_prompt(action: Dictionary) -> String:
	var kind := str(action.get("kind", ""))
	if kind == "oil":
		return "E  提取灯油"
	var top := GameManager.peek_offering()
	var item_name := str(top.get("name", "需要杉木")) if not top.is_empty() else "需要杉木"
	if kind == "ladder":
		return "E  使用梯子：" + item_name
	return "E  铺设桥：" + item_name

func _try_tool_action(action: Dictionary) -> void:
	match str(action.get("kind", "")):
		"bridge":
			_try_place_bridge(int(action.get("index", -1)))
		"ladder":
			_try_use_ladder()
		"oil":
			_try_take_lamp_oil(int(action.get("index", -1)))

func _try_place_bridge(index: int) -> void:
	if index < 0 or index >= _bridge_spots.size():
		return
	if not _consume_sugi_tool("断处太宽了，需要能承托道路的杉木。"):
		return
	var spot := _bridge_spots[index]
	spot["placed"] = true
	_bridge_spots[index] = spot
	DialogManager.show_dialog([
		{"speaker": "", "text": str(spot.get("success", "你铺下杉木桥。"))},
		{"speaker": "", "text": str(spot.get("note", "杉木临时托住了空缺。"))},
	] as Array[Dictionary])
	var bridge := spot.get("bridge") as Node
	_set_platform_enabled(bridge, true)
	if bridge:
		bridge.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_property(bridge, "modulate:a", 1.0, 0.45)

func _try_use_ladder() -> void:
	if not _consume_sugi_tool("这里太高了，需要一段杉木临时架成梯子。"):
		return
	_ladder_used = true
	_configure_ladder_collision()
	_set_platform_enabled(_ladder_ref, true)
	if _ladder_ref:
		_ladder_ref.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_property(_ladder_ref, "modulate:a", 1.0, 0.35)
	DialogManager.show_single("", "你把杉木斜搭在地面和高台之间。")

func _try_take_lamp_oil(index: int) -> void:
	if index < 0 or index >= _lamp_nodes.size():
		return
	if not _lamps_are_blue:
		DialogManager.show_single("", "红色火焰烧得太浊，取不出能用的灯芯油。")
		return
	if not GameManager.push_offering("lamp_oil"):
		return
	var lamp: Dictionary = _lamp_nodes[index]
	lamp["oil_taken"] = true
	_lamp_nodes[index] = lamp
	_apply_lamp_state(lamp)
	DialogManager.show_single("", "你从灯火里取出一小瓶灯芯油。火苗压低，仍在轻轻跳动。")

func _consume_sugi_tool(fail_dialog: String) -> bool:
	var top := GameManager.peek_offering()
	if top.get("id", "") != "sugi_wood":
		DialogManager.show_single("", fail_dialog)
		return false
	GameManager.pop_offering()
	return true

func _on_bell_pulled() -> void:
	_set_platform_enabled(_hidden_platform, true)
	_hidden_platform.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(_hidden_platform, "modulate:a", 1.0, 0.8)
	_set_interactable_enabled(_water_grass_source, true)
	if _water_grass_source:
		_water_grass_source.modulate.a = 0.0
		var grass_tween := create_tween()
		grass_tween.tween_property(_water_grass_source, "modulate:a", 1.0, 0.45)
	_set_all_lamps_blue(true)

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

func _configure_ladder_collision() -> void:
	if not _ladder_ref:
		return
	var collision := _ladder_ref.get_node_or_null("LadderCollision") as CollisionShape2D
	if not collision:
		return
	collision.one_way_collision = true
	collision.one_way_collision_margin = 10.0

func _setup_lamp_nodes() -> void:
	_lamp_nodes.clear()
	var red_source := get_node_or_null("FX/LanternFlame_CliffStart") as AnimatedSprite2D
	var blue_source := get_node_or_null("FX/BlueFlame_HiddenRoute") as AnimatedSprite2D
	if red_source:
		_red_flame_frames = red_source.sprite_frames
	if blue_source:
		_blue_flame_frames = blue_source.sprite_frames
	_register_lamp("CliffStart", "FX/LanternFlame_CliffStart", "Lighting/LanternLight_CliffStart")
	_register_lamp("BridgeAfter", "FX/LanternFlame_BridgeAfter", "Lighting/LanternLight_BridgeAfter")
	_register_lamp("TreeShadow", "FX/LanternFlame_TreeShadow", "Lighting/LanternLight_TreeShadow")
	_register_lamp("SecondAltar", "FX/LanternFlame_SecondAltar", "Lighting/LanternLight_SecondAltar")
	_register_lamp("HiddenRoute", "FX/BlueFlame_HiddenRoute", "Lighting/BlueLanternLight_HiddenRoute")

func _register_lamp(id: String, flame_path: String, light_path: String) -> void:
	var flame := get_node_or_null(flame_path) as AnimatedSprite2D
	var light := get_node_or_null(light_path) as PointLight2D
	var position_source := flame as Node2D
	if not position_source:
		position_source = light as Node2D
	if not position_source:
		return
	_lamp_nodes.append({
		"id": id,
		"flame": flame,
		"light": light,
		"base_energy": light.energy if light else 0.26,
		"oil_taken": false,
	})

func _lamp_position(lamp: Dictionary) -> Vector2:
	var flame: Node2D = lamp.get("flame") as Node2D
	if flame:
		return flame.global_position
	var light: Node2D = lamp.get("light") as Node2D
	if light:
		return light.global_position
	return Vector2.INF

func _set_all_lamps_blue(enabled: bool) -> void:
	_lamps_are_blue = enabled
	for lamp_variant in _lamp_nodes:
		var lamp: Dictionary = lamp_variant
		_apply_lamp_state(lamp)

func _apply_lamp_state(lamp: Dictionary) -> void:
	var oil_taken := bool(lamp.get("oil_taken", false))
	var flame := lamp.get("flame") as AnimatedSprite2D
	if flame:
		var frames: SpriteFrames = _red_flame_frames
		if _lamps_are_blue and _blue_flame_frames:
			frames = _blue_flame_frames
		if frames:
			flame.sprite_frames = frames
		var flame_color := FLAME_BLUE if _lamps_are_blue else FLAME_RED
		flame_color.a = 0.38 if oil_taken else 1.0
		flame.modulate = flame_color
		flame.visible = true
		flame.play("loop")
	var light := lamp.get("light") as PointLight2D
	if light:
		light.color = LIGHT_BLUE if _lamps_are_blue else LIGHT_RED
		var base_energy := float(lamp.get("base_energy", light.energy))
		light.energy = maxf(0.06, base_energy * (0.42 if oil_taken else 1.0))

func _set_interactable_enabled(node: Node, enabled: bool) -> void:
	if not node:
		return
	node.visible = enabled
	node.process_mode = Node.PROCESS_MODE_INHERIT if enabled else Node.PROCESS_MODE_DISABLED
	if enabled:
		node.add_to_group("interactable")
	else:
		node.remove_from_group("interactable")
	if node is CollisionObject2D:
		node.collision_layer = 2 if enabled else 0
		node.collision_mask = 0
	for child in node.get_children():
		if child is CollisionShape2D:
			child.disabled = not enabled

func _place_water_grass_on_hidden_platform() -> void:
	if not _water_grass_source or not _hidden_platform:
		return
	var target_position := _hidden_platform.global_position
	var collision := _hidden_platform.get_node_or_null("HiddenPlatformCollision") as CollisionShape2D
	if collision:
		target_position = collision.global_position
		var rect := collision.shape as RectangleShape2D
		if rect:
			target_position.y -= rect.size.y * 0.5 + 25.0
	_water_grass_source.global_position = target_position

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
