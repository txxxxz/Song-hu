extends LevelBase

const BGM_FINAL_CHOICE_VOID := preload("res://assets/audio/bgm/final_choice_void.wav")
const SFX_PLAQUE_REVEAL := preload("res://assets/audio/sfx/plaque_reveal.wav")
const SFX_SAYO_SHADOW_REVEAL := preload("res://assets/audio/sfx/sayo_shadow_reveal.wav")

@onready var _archive_triggers: Array[Area2D] = [
	$Narrative/ArchiveTrigger1,
	$Narrative/ArchiveTrigger2,
	$Narrative/ArchiveTrigger3,
	$Narrative/ArchiveTrigger4,
	$Narrative/ArchiveTrigger5,
]
@onready var _plaque_marker: Marker2D = $Narrative/PlaqueMarker
@onready var _fox_spawn_marker: Marker2D = $Narrative/FoxSpawnMarker
@onready var _plaque_sprite: Sprite2D = $Narrative/ArchiveTrigger1/ArchiveSprite
@onready var _paper_chest: Node2D = $Narrative/ArchiveTrigger3

const PAPER_MASKED := preload("res://assets/sprites/objects/paper_note_with_patch.png")
const PAPER_REVEALED := preload("res://assets/sprites/objects/paper_note_blank.png")

const ARCHIVE_DIALOGS := [
	[
		{"speaker": "旧木额", "text": "表面的金漆写着「迎狐之仪」。"},
		{"speaker": "旧木额", "text": "陈旧的木匾被潮气浸润，侵蚀了金漆，用狐火靠近查看，泡软的金漆斑驳"},
		{"speaker": "旧木额", "text": "下面一层的金漆更加陈旧，你使劲擦却只能擦出「送*之仪」的字样。"},
		{"speaker": "我", "text": "迎狐是后来印上去的字，原来这个仪式是送行，为什么是送，要送什么？"},
	],
	[
		{"speaker": "回廊竹简", "text": "大疫第三年，山路七日不通。井水发黑，死者二十七。村人不再入山。"},
		{"speaker": "回廊竹简", "text": "社中择送行者一名。白衣覆身，于子时送至本社。"},
		{"speaker": "回廊竹简", "text": "是夜后，山雾散。道路复正。井水渐清。病者亦退热。"},
		{"speaker": "回廊竹简", "text": "次年重修神社。村中改称此仪为「迎狐」。旧称自此不再记于木额。"},
		{"speaker": "我", "text": "送行者……送的是人？为什么要送人进神社？"},
	],
	[
		{"speaker": "衣箱残签", "text": "白*一领。童身用。袖口束紧。"},
		{"speaker": "", "text": "有人用纸遮住了这个字，粘得很死，无法强行撕开"},
	],
	[
		{"speaker": "装束札", "text": "杉木为轿。白□覆身。蓬草盖顶，以遮人气。"},
		{"speaker": "装束札", "text": "送行后，狐神归位，再不得呼其名。"},
	],
	[
		{"speaker": "内殿档案", "text": "本次送行者：雨宫纱夜，九岁。山社巫女。签选。家不得辞。"},
		{"speaker": "内殿档案", "text": "送行后，名册除名。村中不得呼其名。家人不得回望。"},
		{"speaker": "内殿档案", "text": "狐位者，生身入位，化狐守灯，镇山路与旧病。若至亲呼名，狐位松动；狐位一空，诸灾复归。"},
		{"speaker": "我", "text": "雨宫纱夜。"},
		{"speaker": "我", "text": "为什么她也叫雨宫，这个名字为什么如此耳熟。"},
		{"speaker": "", "text": "大脑剧烈的疼痛，有什么东西要记起来了，你反复咀嚼着这个名字"},
		{"speaker": "我", "text": "雨宫纱夜，这是姐姐的名字。"},
	],
]

var _archives_found: int = 0
var _total_archives: int = 5
var _truth_revealed: bool = false
var _final_choice_shown: bool = false
var _plaque_transformed: bool = false
var _paper_recheck_unlocked: bool = false
var _paper_rechecked: bool = false
var _inner_reveal_started: bool = false
var _fox_ref: Node2D = null
var _clues_found: Array[bool] = []
var _insights_unlocked: Dictionary = {}
var _interpretation_layer: CanvasLayer = null
var _interpretation_rows: Dictionary = {}
var _paper_layer: CanvasLayer = null
var _plaque_label: Label = null

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
	if _paper_chest and _paper_chest.has_signal("chest_rechecked"):
		_paper_chest.connect("chest_rechecked", Callable(self, "_on_chest_rechecked"))
	_set_plaque_state("迎狐之仪")
	show_area_name("终章  本社・维持的空壳")
	GameManager.set_state(GameManager.State.PLAYING)
	play_bgm(preload("res://assets/audio/bgm/shrine_theme.wav"))
	play_ambience(preload("res://assets/audio/ambience/shrine_roomtone.wav"))
	await get_tree().create_timer(0.8).timeout
	DialogManager.show_dialog([
		{"speaker": "", "text": "本社到了。"},
		{"speaker": "", "text": "这里没有倒塌。灯笼、回廊和纸门都摆得很整齐。"},
		{"speaker": "", "text": "地上没有脚印，供桌也没有香灰，比山路还干净"},
		{"speaker": "我", "text": "总觉得会有人在里面生活"},
		{"speaker": "我", "text": "可安静的什么声音都没有。"},
	] as Array[Dictionary])

func _process(delta: float) -> void:
	super._process(delta)
	if _final_choice_shown or not player:
		return
	var near_plaque := _plaque_marker and player.global_position.distance_to(_plaque_marker.global_position) < 260.0
	var near_inner := _fox_spawn_marker and player.global_position.distance_to(_fox_spawn_marker.global_position) < 360.0
	var should_show_plaque_prompt := near_plaque and _truth_revealed and not _plaque_transformed
	var should_show_inner_prompt := near_inner and _paper_rechecked and not _inner_reveal_started
	if player.has_method("set_external_interact_prompt"):
		if should_show_plaque_prompt:
			player.set_external_interact_prompt("E  用狐火照匾额", true)
		elif should_show_inner_prompt:
			player.set_external_interact_prompt("E  查看内室", true)
		else:
			player.set_external_interact_prompt("", false)
	if should_show_plaque_prompt and Input.is_action_just_pressed("interact") and not DialogManager.is_active():
		_on_plaque_interact()
	elif should_show_inner_prompt and Input.is_action_just_pressed("interact") and not DialogManager.is_active():
		_on_inner_reveal_interact()

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
	if archive_index == 2:
		await _show_paper_note(false)
	elif archive_index >= 0 and archive_index < ARCHIVE_DIALOGS.size():
		DialogManager.show_dialog(_get_archive_dialog(archive_index))
		await DialogManager.dialog_finished
	if archive_index == 0:
		_set_plaque_state("送*之仪")
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
	title.text = "调查笔记"
	title.add_theme_font_size_override("font_size", 19)
	title.add_theme_color_override("font_color", Color(0.92, 0.74, 0.42))
	vbox.add_child(title)
	_add_board_row(vbox, "ritual", "仪式名：村里称作迎狐，为的是迎接狐火归位")
	_add_board_row(vbox, "garment", "白色供物：木牌称作白狐毛")
	_add_board_row(vbox, "person", "白狐身份：？")
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
	if _clues_found[0] and _clues_found[1]:
		_set_board_row("ritual", "仪式名：迎狐覆盖了送狐", Color(0.90, 0.82, 0.56))
	if _clues_found[2] and _clues_found[3]:
		_set_board_row("garment", "白色供物：白□附身", Color(0.86, 0.88, 0.96))
	if _clues_found[4] and (_clues_found[2] or _clues_found[3]):
		_set_board_row("person", "白狐身份：送行者：雨宫纱夜", Color(0.96, 0.76, 0.60))

	if _clues_found[0] and _clues_found[1] and not _insights_unlocked.has("ritual_name"):
		_insights_unlocked["ritual_name"] = true
		DialogManager.show_dialog([
			{"speaker": "我", "text": "旧字写送，新字写迎。"},
			{"speaker": "我", "text": "有人把仪式的方向改反了，原本的送行变成了迎神"},
		] as Array[Dictionary])
		await DialogManager.dialog_finished

	if _clues_found[2] and _clues_found[3] and not _insights_unlocked.has("white_misread"):
		_insights_unlocked["white_misread"] = true
		DialogManager.show_dialog([
			{"speaker": "我", "text": "纸上写着白，后面的字被框住了。"},
			{"speaker": "我", "text": "装束札也缺了同一处，像是有人故意留下一个空格。"},
		] as Array[Dictionary])
		await DialogManager.dialog_finished

	if _clues_found[4] and (_clues_found[2] or _clues_found[3]) and not _insights_unlocked.has("sayo"):
		_insights_unlocked["sayo"] = true
		DialogManager.show_dialog([
			{"speaker": "我", "text": "送行者是雨宫纱夜。"},
			{"speaker": "我", "text": "怪不得大人从来闭口不谈姐姐的名字，甚者说我是家中独女我从未有过姐姐"},
			{"speaker": "我", "text": "白狐回头时，童谣不让我叫的，都是这个名字。"},
		] as Array[Dictionary])
		await DialogManager.dialog_finished

func _unlock_plaque() -> void:
	await get_tree().create_timer(0.45).timeout
	DialogManager.show_dialog([
		{"speaker": "", "text": "五份记录对上了。"},
		{"speaker": "", "text": "旧木额、回廊牌、衣箱、装束札和内殿档案，都缺一角，也都湿得发软。"},
		{"speaker": "我", "text": "只差门口那块匾。"},
		{"speaker": "我", "text": "如果狐火能照出旧字，也许能把缺角补上。"},
	] as Array[Dictionary])
	await DialogManager.dialog_finished

func _on_plaque_interact() -> void:
	if _plaque_transformed:
		return
	_plaque_transformed = true
	if player and player.has_method("set_external_interact_prompt"):
		player.set_external_interact_prompt("", false)
	play_sfx(SFX_PLAQUE_REVEAL)
	_set_plaque_state("送狐之仪")
	DialogManager.show_dialog([
		{"speaker": "", "text": "匾额上的「送*之仪」被狐火照亮。"},
		{"speaker": "", "text": "狐火贴近木面。剩余的金漆起泡，一点点自行剥落。"},
		{"speaker": "", "text": "遮住的字露了出来。"},
		{"speaker": "", "text": "木匾变成了「送狐之仪」。"},
		{"speaker": "我", "text": "既然木匾有了变化，我们去看看刚才箱子里的字到底是什么。"},
	] as Array[Dictionary])
	await DialogManager.dialog_finished
	_set_board_row("ritual", "仪式名：送狐", Color(1.00, 0.76, 0.42))
	_paper_recheck_unlocked = true
	if _paper_chest and _paper_chest.has_method("enable_final_recheck"):
		_paper_chest.call("enable_final_recheck")

func _on_chest_rechecked() -> void:
	if not _paper_recheck_unlocked or _paper_rechecked:
		return
	_paper_rechecked = true
	await _show_paper_note(true)
	DialogManager.show_dialog([
		{"speaker": "", "text": "纸片上的遮挡松开了。"},
		{"speaker": "", "text": "刚才被框掉的字，是衣。"},
		{"speaker": "我", "text": "我一路复原的是送行者的装束。"},
		{"speaker": "我", "text": "再往内室走，白狐应该就在那里。"},
	] as Array[Dictionary])
	await DialogManager.dialog_finished
	_set_board_row("garment", "白色供物：白衣", Color(0.96, 0.93, 0.98))

func _on_inner_reveal_interact() -> void:
	if _inner_reveal_started or _final_choice_shown:
		return
	_inner_reveal_started = true
	_final_choice_shown = true
	if player and player.has_method("set_external_interact_prompt"):
		player.set_external_interact_prompt("", false)
	await get_tree().create_timer(0.5).timeout
	_fox_ref = spawn_fox(_fox_spawn_marker.global_position if _fox_spawn_marker else Vector2(5050, 548), 0)
	await get_tree().create_timer(1.0).timeout
	_show_human_shadow()
	play_sfx(SFX_SAYO_SHADOW_REVEAL)
	play_bgm(BGM_FINAL_CHOICE_VOID)
	DialogManager.show_dialog([
		{"speaker": "", "text": "白狐出现在长明灯前。灯下的石板渗着水。"},
		{"speaker": "", "text": "它回过头。童谣里的禁句贴着耳边响起。"},
		{"speaker": "", "text": "纸门上的影子被灯火拉长，狐尾变成袖摆，耳尖变成发结。"},
		{"speaker": "", "text": "长明灯照见一个穿白衣的孩子。"},
		{"speaker": "我", "text": "雨宫……"},
		{"speaker": "", "text": "白狐的耳朵动了一下。它听见了。"},
		{"speaker": "我", "text": "如果姐姐的全名被叫出来，狐位会松动。"},
		{"speaker": "我", "text": "但狐位一空，被压住的东西也会回到村里。"},
	] as Array[Dictionary])
	await DialogManager.dialog_finished
	_set_board_row("person", "白狐身份：雨宫纱夜", Color(1.00, 0.68, 0.52))
	await get_tree().create_timer(0.45).timeout
	show_choice(
		"要叫出她的名字吗？",
		"不呼唤", "纱夜",
		"完成送狐。\n村庄恢复平静，白狐留在本社。", "叫她回来。\n狐位松动，村庄失去镇压，\n疫情肆虐，洪水席卷一切。",
		_on_final_choice
	)

func _set_plaque_state(text_value: String) -> void:
	if not _plaque_sprite:
		return
	if not _plaque_label or not is_instance_valid(_plaque_label):
		_plaque_label = Label.new()
		_plaque_label.name = "PlaqueText"
		_plaque_label.z_index = 3
		_plaque_label.position = Vector2(-154, -132)
		_plaque_label.size = Vector2(308, 64)
		_plaque_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_plaque_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_plaque_label.add_theme_font_size_override("font_size", 34)
		_plaque_label.add_theme_color_override("font_color", Color(0.92, 0.72, 0.34))
		_plaque_label.add_theme_color_override("font_shadow_color", Color(0.05, 0.025, 0.01, 0.86))
		_plaque_label.add_theme_constant_override("shadow_offset_x", 2)
		_plaque_label.add_theme_constant_override("shadow_offset_y", 2)
		_plaque_sprite.add_child(_plaque_label)
	_plaque_label.text = text_value

func _show_paper_note(revealed: bool) -> void:
	if _paper_layer and is_instance_valid(_paper_layer):
		_paper_layer.queue_free()
	_paper_layer = CanvasLayer.new()
	_paper_layer.name = "PaperNoteLayer"
	_paper_layer.layer = 80
	add_child(_paper_layer)

	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.48)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_paper_layer.add_child(dim)

	var note := TextureRect.new()
	note.texture = PAPER_REVEALED if revealed else PAPER_MASKED
	note.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	note.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	note.custom_minimum_size = Vector2(420, 420)
	note.anchor_left = 0.5
	note.anchor_top = 0.5
	note.anchor_right = 0.5
	note.anchor_bottom = 0.5
	note.offset_left = -210
	note.offset_top = -230
	note.offset_right = 210
	note.offset_bottom = 190
	_paper_layer.add_child(note)

	var clue_text := Label.new()
	clue_text.text = "白衣附身" if revealed else "白　附身"
	clue_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	clue_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	clue_text.add_theme_font_size_override("font_size", 42)
	clue_text.add_theme_color_override("font_color", Color(0.20, 0.13, 0.08, 0.95))
	clue_text.add_theme_color_override("font_shadow_color", Color(0.56, 0.38, 0.18, 0.32))
	clue_text.add_theme_constant_override("shadow_offset_x", 2)
	clue_text.add_theme_constant_override("shadow_offset_y", 2)
	clue_text.anchor_left = 0.5
	clue_text.anchor_top = 0.5
	clue_text.anchor_right = 0.5
	clue_text.anchor_bottom = 0.5
	clue_text.offset_left = -150
	clue_text.offset_top = -66
	clue_text.offset_right = 150
	clue_text.offset_bottom = 10
	_paper_layer.add_child(clue_text)

	var hint := Label.new()
	hint.text = "E"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 22)
	hint.add_theme_color_override("font_color", Color(0.86, 0.72, 0.48, 0.86))
	hint.anchor_left = 0.5
	hint.anchor_top = 0.5
	hint.anchor_right = 0.5
	hint.anchor_bottom = 0.5
	hint.offset_left = -20
	hint.offset_top = 204
	hint.offset_right = 20
	hint.offset_bottom = 236
	_paper_layer.add_child(hint)

	GameManager.set_state(GameManager.State.DIALOG)
	while true:
		await get_tree().process_frame
		if Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("jump"):
			break
	_paper_layer.queue_free()
	_paper_layer = null
	GameManager.set_state(GameManager.State.PLAYING)

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
	shadow.position = Vector2(5145, 630)
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
