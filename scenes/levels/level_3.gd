extends LevelBase

@onready var _archive_triggers: Array[Area2D] = [
	$Narrative/ArchiveTrigger1,
	$Narrative/ArchiveTrigger2,
	$Narrative/ArchiveTrigger3,
	$Narrative/ArchiveTrigger4,
	$Narrative/ArchiveTrigger5,
]
@onready var _plaque_marker: Marker2D = $Narrative/PlaqueMarker
@onready var _fox_spawn_marker: Marker2D = $Narrative/FoxSpawnMarker

const ARCHIVE_DIALOGS := [
	[
		{"speaker": "旧木额", "text": "表层写着「迎狐」。狐火靠近时，底下有一道旧刻痕像是「送」。"},
		{"speaker": "我", "text": "这不是完整答案。只是两个互相抵触的字。"},
	],
	[
		{"speaker": "回廊牌", "text": "祭次表里反复出现「送行」二字，却没有一次写成「迎接」。"},
		{"speaker": "我", "text": "后来的人把这个仪式讲得温顺，好像它从一开始就是祝福。"},
	],
	[
		{"speaker": "衣箱残签", "text": "白衣一领。童身用。不得沾血。"},
		{"speaker": "我", "text": "白色的不是毛。至少这张签上不是。"},
	],
	[
		{"speaker": "装束札", "text": "杉木为底。白衣覆身。蓬草盖顶。送行前不得呼名。"},
		{"speaker": "我", "text": "一路收集的供物，像是在复原某个人的装束。"},
	],
	[
		{"speaker": "内殿档案", "text": "今夜送行者：纱夜，年九岁。不得呼名。不得回望。"},
		{"speaker": "内殿档案", "text": "若狐回首，是因仍记得家人。"},
	],
]

var _archives_found: int = 0
var _total_archives: int = 5
var _truth_revealed: bool = false
var _final_choice_shown: bool = false
var _fox_ref: Node2D = null
var _clues_found: Array[bool] = []
var _insights_unlocked: Dictionary = {}
var _interpretation_layer: CanvasLayer = null
var _interpretation_rows: Dictionary = {}

func _on_level_ready() -> void:
	_clues_found.resize(_total_archives)
	_clues_found.fill(false)
	_create_interpretation_board()
	for index in _archive_triggers.size():
		var trigger := _archive_triggers[index]
		if trigger:
			if trigger.has_signal("clue_activated"):
				trigger.connect("clue_activated", Callable(self, "_on_info_clue_activated"))
			else:
				trigger.body_entered.connect(_on_archive_body_entered.bind(index, trigger))
	show_area_name("终章  本社・维持的空壳")
	GameManager.set_state(GameManager.State.PLAYING)
	play_bgm(preload("res://assets/audio/bgm/shrine_theme.wav"))
	play_ambience(preload("res://assets/audio/ambience/shrine_roomtone.wav"))
	await get_tree().create_timer(0.8).timeout
	DialogManager.show_dialog([
		{"speaker": "", "text": "主社到了。这里没有明显倒塌，灯笼、回廊和纸门都还维持着完整。"},
		{"speaker": "", "text": "可是木地板没有脚印，供桌没有香灰，门轴也没有被使用过的磨痕。"},
		{"speaker": "", "text": "这不是被保存下来的地方，更像是被迫维持成「还在使用」的样子。"},
	] as Array[Dictionary])

func _process(delta: float) -> void:
	super._process(delta)
	if _final_choice_shown or not player or not _plaque_marker:
		return
	var near_plaque := player.global_position.distance_to(_plaque_marker.global_position) < 260.0
	if player.has_method("set_external_interact_prompt"):
		player.set_external_interact_prompt("E  用狐火照匾额", near_plaque and _truth_revealed)
	if near_plaque and _truth_revealed and Input.is_action_just_pressed("interact") and not DialogManager.is_active():
		_on_plaque_interact()

func _on_info_clue_activated(clue_index: int, clue: Node2D) -> void:
	_on_archive_found(clue_index, clue as Area2D)

func _on_archive_body_entered(body: Node2D, archive_index: int, trigger: Area2D) -> void:
	if body != player:
		return
	if not is_instance_valid(trigger) or not trigger.monitoring:
		return
	trigger.set_deferred("monitoring", false)
	_on_archive_found(archive_index, trigger)

func _on_archive_found(archive_index: int, trigger: Area2D) -> void:
	if archive_index < 0 or archive_index >= _clues_found.size():
		return
	if _clues_found[archive_index]:
		return
	_clues_found[archive_index] = true
	_archives_found += 1
	if trigger and not trigger.has_method("mark_understood"):
		trigger.call_deferred("queue_free")
	if archive_index >= 0 and archive_index < ARCHIVE_DIALOGS.size():
		DialogManager.show_dialog(_get_archive_dialog(archive_index))
		await DialogManager.dialog_finished
	await _update_understanding_links()
	if _archives_found >= _total_archives and not _truth_revealed:
		_truth_revealed = true
		await _unlock_plaque()

func _get_archive_dialog(archive_index: int) -> Array[Dictionary]:
	var archive_dialog: Array[Dictionary] = []
	for line in ARCHIVE_DIALOGS[archive_index]:
		archive_dialog.append(line)
	return archive_dialog

func _create_interpretation_board() -> void:
	_interpretation_layer = CanvasLayer.new()
	_interpretation_layer.name = "InterpretationBoard"
	_interpretation_layer.layer = 55
	add_child(_interpretation_layer)

	var panel := PanelContainer.new()
	panel.name = "BoardPanel"
	panel.position = Vector2(42, 82)
	panel.custom_minimum_size = Vector2(430, 174)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.030, 0.024, 0.038, 0.74)
	style.border_color = Color(0.58, 0.45, 0.28, 0.78)
	style.set_border_width_all(2)
	style.set_corner_radius_all(0)
	style.set_content_margin_all(14)
	panel.add_theme_stylebox_override("panel", style)
	_interpretation_layer.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "解释结构"
	title.add_theme_font_size_override("font_size", 19)
	title.add_theme_color_override("font_color", Color(0.92, 0.74, 0.42))
	vbox.add_child(title)
	_add_board_row(vbox, "ritual", "仪式名：迎狐 / 送狐 未定")
	_add_board_row(vbox, "garment", "装束：白毛 / 白衣 未定")
	_add_board_row(vbox, "person", "身份：白狐 / 家人 未定")
	_interpretation_layer.visible = false

func _add_board_row(parent: VBoxContainer, row_id: String, text_value: String) -> void:
	var label := Label.new()
	label.name = "Row_" + row_id
	label.text = text_value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 17)
	label.add_theme_color_override("font_color", Color(0.80, 0.78, 0.70))
	label.custom_minimum_size = Vector2(390, 26)
	parent.add_child(label)
	_interpretation_rows[row_id] = label

func _set_board_row(row_id: String, text_value: String, color := Color(0.95, 0.84, 0.54)) -> void:
	if not _interpretation_rows.has(row_id):
		return
	_interpretation_layer.visible = true
	var label := _interpretation_rows[row_id] as Label
	label.text = text_value
	label.add_theme_color_override("font_color", color)

func _update_understanding_links() -> void:
	if _clues_found[0] or _clues_found[1]:
		_set_board_row("ritual", "仪式名：迎狐 与 送狐 冲突", Color(0.90, 0.82, 0.56))
	if _clues_found[2] or _clues_found[3]:
		_set_board_row("garment", "装束：白毛 可能是 白衣 的误读", Color(0.86, 0.88, 0.96))
	if _clues_found[4]:
		_set_board_row("person", "身份：送行者 纱夜，仍记得家人", Color(0.96, 0.76, 0.60))

	if _clues_found[0] and _clues_found[1] and not _insights_unlocked.has("ritual_name"):
		_insights_unlocked["ritual_name"] = true
		DialogManager.show_dialog([
			{"speaker": "解释", "text": "「迎狐」和「送行」无法同时成立。"},
			{"speaker": "解释", "text": "如果旧字先于新字，那么现在看到的仪式名可能是后来覆盖的。"},
		] as Array[Dictionary])
		await DialogManager.dialog_finished

	if _clues_found[2] and _clues_found[3] and not _insights_unlocked.has("white_misread"):
		_insights_unlocked["white_misread"] = true
		DialogManager.show_dialog([
			{"speaker": "解释", "text": "白色不一定是白毛。衣箱和装束札都指向白衣。"},
			{"speaker": "解释", "text": "所谓白狐，可能是被白衣、杉木和蓬草共同制造出来的形象。"},
		] as Array[Dictionary])
		await DialogManager.dialog_finished

	if _clues_found[4] and (_clues_found[2] or _clues_found[3]) and not _insights_unlocked.has("sayo"):
		_insights_unlocked["sayo"] = true
		DialogManager.show_dialog([
			{"speaker": "解释", "text": "「纱夜」不是旁支记录。她就是被装束遮住的人。"},
			{"speaker": "解释", "text": "不得呼名、不得回望，不是在约束狐，而是在抹去一个孩子。"},
		] as Array[Dictionary])
		await DialogManager.dialog_finished

func _unlock_plaque() -> void:
	await get_tree().create_timer(0.45).timeout
	DialogManager.show_dialog([
		{"speaker": "", "text": "碎片没有给出一句完整说明，却互相咬合成了同一个方向。"},
		{"speaker": "", "text": "本殿匾额位于石阶与长明灯前。狐火也许能照出被覆盖的那一层。"},
	] as Array[Dictionary])
	await DialogManager.dialog_finished

func _on_plaque_interact() -> void:
	if _final_choice_shown:
		return
	_final_choice_shown = true
	if player and player.has_method("set_external_interact_prompt"):
		player.set_external_interact_prompt("", false)
	DialogManager.show_dialog([
		{"speaker": "", "text": "匾额上写着「迎狐」。"},
		{"speaker": "", "text": "狐火贴近木面，金漆像一层旧皮慢慢剥开。"},
		{"speaker": "", "text": "底下露出的不是「迎狐」，而是被刮过又盖住的「送狐」。"},
	] as Array[Dictionary])
	await DialogManager.dialog_finished
	_set_board_row("ritual", "仪式名：迎狐 反转为 送狐", Color(1.00, 0.76, 0.42))
	await get_tree().create_timer(0.6).timeout
	DialogManager.show_dialog([
		{"speaker": "", "text": "内殿档案的语序忽然清楚了：送行者不是仪式执行人，而是被送走的人。"},
		{"speaker": "", "text": "杉木为底，白衣覆身，蓬草盖顶。那不是供物顺序，是送行的身体结构。"},
	] as Array[Dictionary])
	await DialogManager.dialog_finished
	_set_board_row("garment", "装束：白衣 被后人讲成 白毛", Color(0.96, 0.93, 0.98))
	await get_tree().create_timer(0.5).timeout
	_fox_ref = spawn_fox(_fox_spawn_marker.global_position if _fox_spawn_marker else Vector2(10100, 420), 0)
	await get_tree().create_timer(1.0).timeout
	_show_human_shadow()
	DialogManager.show_dialog([
		{"speaker": "", "text": "白狐出现在石阶与长明灯之间。它回过头来。"},
		{"speaker": "", "text": "纸门上的影子被灯火拉长，狐尾变成袖摆，耳尖变成发结。"},
		{"speaker": "", "text": "童谣里那句「白毛覆身」此刻改了意思：白衣覆身，不许回家。"},
		{"speaker": "", "text": "纱夜。那是你失踪多年的姐姐。"},
	] as Array[Dictionary])
	await DialogManager.dialog_finished
	_set_board_row("person", "身份：白狐 是 姐姐纱夜", Color(1.00, 0.68, 0.52))
	await get_tree().create_timer(0.45).timeout
	show_choice(
		"你要叫出她的名字吗？",
		"沉默\n完成仪式", "纱夜\n呼唤她的名字",
		"让秩序继续", "让真相回来",
		_on_final_choice
	)

func _show_human_shadow() -> void:
	var shadow := Polygon2D.new()
	shadow.name = "SayoHumanShadow"
	shadow.polygon = PackedVector2Array([
		Vector2(-34, -168),
		Vector2(30, -168),
		Vector2(46, -92),
		Vector2(72, 8),
		Vector2(20, 8),
		Vector2(0, -52),
		Vector2(-20, 8),
		Vector2(-72, 8),
		Vector2(-46, -92),
	])
	shadow.color = Color(0.035, 0.020, 0.028, 0.68)
	shadow.position = Vector2(10290, 502)
	shadow.scale = Vector2(1.15, 1.0)
	shadow.z_index = 18
	shadow.modulate.a = 0.0
	var parent := get_node_or_null("FX")
	if parent:
		parent.add_child(shadow)
	else:
		add_child(shadow)
	var tween := create_tween()
	tween.tween_property(shadow, "modulate:a", 1.0, 0.7)

func _on_final_choice(choice: String) -> void:
	if choice == "A":
		GameManager.transition_to_ending("A")
	else:
		GameManager.transition_to_ending("B")
