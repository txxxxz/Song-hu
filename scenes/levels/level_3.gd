extends LevelBase

const BGM_FINAL_CHOICE_VOID := preload("res://assets/audio/bgm/final_choice_void.wav")
const SFX_PLAQUE_REVEAL := preload("res://assets/audio/sfx/plaque_reveal.wav")
const SFX_SAYO_SHADOW_REVEAL := preload("res://assets/audio/sfx/sayo_shadow_reveal.wav")
const PLAQUE_INTERACT_DISTANCE := 420.0
const FOXFIRE_PICKUP_DISTANCE := 280.0
const FINAL_REFLECTION_DISTANCE := 360.0
const BLUE_FLAME_TEXTURE := preload("res://assets/sprites/effects/blue_flame.png")
const COLD_LIGHT_TEXTURE := preload("res://assets/sprites/effects/cold_light.png")
const FOXFIRE_FLAME_OFFSET := Vector2(0, -150)

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
@onready var _foxfire_pickup_marker: Marker2D = get_node_or_null("Narrative/FoxfirePickupMarker") as Marker2D
@onready var _foxfire_pickup_flame: AnimatedSprite2D = get_node_or_null("FX/BlueFlame_FoxfirePickup") as AnimatedSprite2D
@onready var _foxfire_pickup_light: PointLight2D = get_node_or_null("Lighting/BlueLanternLight_FoxfirePickup") as PointLight2D
@onready var _plaque_foxfire: AnimatedSprite2D = get_node_or_null("FX/Foxfire_PlaqueReveal") as AnimatedSprite2D

const PAPER_MASKED := preload("res://assets/sprites/objects/paper_note_with_patch.png")
const PAPER_REVEALED := preload("res://assets/sprites/objects/paper_note_blank.png")

const ARCHIVE_DIALOGS := [
	[
		{"speaker": "UI_ARCHIVE_OLD_PLAQUE", "text": "DIALOG_L3_ARCHIVE_01_01"},
		{"speaker": "UI_ARCHIVE_OLD_PLAQUE", "text": "DIALOG_L3_ARCHIVE_01_02"},
		{"speaker": "UI_ARCHIVE_OLD_PLAQUE", "text": "DIALOG_L3_ARCHIVE_01_03"},
		{"speaker": "CHAR_PLAYER", "text": "DIALOG_L3_ARCHIVE_01_04"},
	],
	[
		{"speaker": "UI_ARCHIVE_SCROLL", "text": "DIALOG_L3_ARCHIVE_02_01"},
		{"speaker": "UI_ARCHIVE_SCROLL", "text": "DIALOG_L3_ARCHIVE_02_02"},
		{"speaker": "UI_ARCHIVE_SCROLL", "text": "DIALOG_L3_ARCHIVE_02_03"},
		{"speaker": "UI_ARCHIVE_SCROLL", "text": "DIALOG_L3_ARCHIVE_02_04"},
		{"speaker": "CHAR_PLAYER", "text": "DIALOG_L3_ARCHIVE_02_05"},
	],
	[
		{"speaker": "UI_ARCHIVE_CHEST_TAG", "text": "DIALOG_L3_ARCHIVE_03_01"},
		{"speaker": "", "text": "DIALOG_L3_ARCHIVE_03_02"},
	],
	[
		{"speaker": "UI_SPEAKER_WOOD_PLATE", "text": "DIALOG_L3_ARCHIVE_04_01"},
		{"speaker": "UI_SPEAKER_WOOD_PLATE", "text": "DIALOG_L3_ARCHIVE_04_02"},
	],
	[
		{"speaker": "UI_ARCHIVE_INNER", "text": "DIALOG_L3_ARCHIVE_05_01"},
		{"speaker": "UI_ARCHIVE_INNER", "text": "DIALOG_L3_ARCHIVE_05_02"},
		{"speaker": "UI_ARCHIVE_INNER", "text": "DIALOG_L3_ARCHIVE_05_03"},
		{"speaker": "CHAR_PLAYER", "text": "DIALOG_L3_ARCHIVE_05_04"},
		{"speaker": "CHAR_PLAYER", "text": "DIALOG_L3_ARCHIVE_05_05"},
		{"speaker": "", "text": "DIALOG_L3_ARCHIVE_05_06"},
		{"speaker": "CHAR_PLAYER", "text": "DIALOG_L3_ARCHIVE_05_07"},
	],
]

var _archives_found: int = 0
var _total_archives: int = 5
var _truth_revealed: bool = false
var _final_choice_shown: bool = false
var _plaque_transformed: bool = false
var _all_archives_found: bool = false
var _truth_reveal_in_progress: bool = false
var _foxfire_pickup_unlocked: bool = false
var _foxfire_collected: bool = false
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
var _plaque_font: Font = null
var _paper_font: Font = null
var _foxfire_sources: Array[Node2D] = []
var _blue_flame_frames: SpriteFrames = null

func _on_level_ready() -> void:
	_clues_found.resize(_total_archives)
	_clues_found.fill(false)
	_set_offering_tube_visible(false)
	_create_interpretation_board()
	_configure_scene_foxfires()
	for index in _archive_triggers.size():
		var trigger := _archive_triggers[index]
		if trigger:
			if trigger.has_signal("clue_activated"):
				trigger.connect("clue_activated", Callable(self, "_on_info_clue_activated"))
			else:
				trigger.body_entered.connect(_on_archive_body_entered.bind(index, trigger))
	if _paper_chest and _paper_chest.has_signal("chest_rechecked"):
		_paper_chest.connect("chest_rechecked", Callable(self, "_on_chest_rechecked"))
	_set_plaque_state("UI_PLAQUE_REVEAL_INITIAL")
	_set_archive_sequence_step(0)
	_set_plaque_foxfire_visible(false)
	show_area_name("UI_AREA_FINAL")
	GameManager.set_state(GameManager.State.PLAYING)
	play_bgm(preload("res://assets/audio/bgm/shrine_theme.wav"))
	play_ambience(preload("res://assets/audio/ambience/shrine_roomtone.wav"))
	await get_tree().create_timer(0.8).timeout
	DialogManager.show_dialog([
		{"speaker": "", "text": "DIALOG_L3_OPEN_01"},
		{"speaker": "", "text": "DIALOG_L3_OPEN_02"},
		{"speaker": "", "text": "DIALOG_L3_OPEN_03"},
		{"speaker": "CHAR_PLAYER", "text": "DIALOG_L3_OPEN_04"},
		{"speaker": "CHAR_PLAYER", "text": "DIALOG_L3_OPEN_05"},
	] as Array[Dictionary])

func _process(delta: float) -> void:
	super._process(delta)
	if _final_choice_shown or not player:
		return
	if _all_archives_found and not _truth_revealed and not _truth_reveal_in_progress and _is_near_final_reflection_spot() and not DialogManager.is_active():
		_show_final_reflection()
	var near_plaque := _plaque_marker and player.global_position.distance_to(_plaque_marker.global_position) < PLAQUE_INTERACT_DISTANCE
	var near_foxfire := _is_near_foxfire_source()
	var near_inner := _fox_spawn_marker and player.global_position.distance_to(_fox_spawn_marker.global_position) < 360.0
	var should_show_foxfire_prompt := near_foxfire and _foxfire_pickup_unlocked and not _foxfire_collected
	var should_show_plaque_prompt := near_plaque and _truth_revealed and _foxfire_collected and not _plaque_transformed
	var should_show_inner_prompt := near_inner and _paper_rechecked and not _inner_reveal_started
	if player.has_method("set_external_interact_prompt"):
		if should_show_foxfire_prompt:
			player.set_external_interact_prompt(tr("UI_PROMPT_PICK_FOXFIRE"), true)
		elif should_show_plaque_prompt:
			player.set_external_interact_prompt(tr("UI_PROMPT_VIEW_PLAQUE"), true)
		elif should_show_inner_prompt:
			player.set_external_interact_prompt(tr("UI_PROMPT_VIEW_INNER"), true)
		else:
			player.set_external_interact_prompt("", false)
	if should_show_foxfire_prompt and Input.is_action_just_pressed("interact") and not DialogManager.is_active():
		_on_foxfire_pickup()
	elif should_show_plaque_prompt and Input.is_action_just_pressed("interact") and not DialogManager.is_active():
		_on_plaque_interact()
	elif should_show_inner_prompt and Input.is_action_just_pressed("interact") and not DialogManager.is_active():
		_on_inner_reveal_interact()

func _set_offering_tube_visible(active: bool) -> void:
	if hud_layer and hud_layer.has_method("set_offering_tube_visible"):
		hud_layer.set_offering_tube_visible(active)

func _set_archive_sequence_step(active_index: int) -> void:
	for index in _archive_triggers.size():
		var trigger := _archive_triggers[index]
		if not trigger or _clues_found[index]:
			continue
		_set_archive_trigger_enabled(trigger, index == active_index)

func _set_archive_trigger_enabled(trigger: Area2D, enabled: bool) -> void:
	if enabled:
		trigger.add_to_group("interactable")
		trigger.collision_layer = 2
	else:
		trigger.remove_from_group("interactable")
		trigger.collision_layer = 0

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
		await _show_paper_note(false, "DIALOG_L3_ARCHIVE_03_02")
	elif archive_index >= 0 and archive_index < ARCHIVE_DIALOGS.size():
		DialogManager.show_dialog(_get_archive_dialog(archive_index))
		await DialogManager.dialog_finished
	if archive_index == 0:
		_set_plaque_state("UI_PLAQUE_MISSING_CHAR")
	await _update_understanding_links()
	if _archives_found >= _total_archives and not _truth_revealed:
		_all_archives_found = true
	else:
		_set_archive_sequence_step(archive_index + 1)

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
	panel.position = Vector2(24, 24)
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
	title.text = tr("UI_NOTEBOARD_TITLE")
	title.add_theme_font_size_override("font_size", 19)
	title.add_theme_color_override("font_color", Color(0.92, 0.74, 0.42))
	vbox.add_child(title)
	_add_board_row(vbox, "ritual", "UI_NOTE_RITUAL_INITIAL")
	_add_board_row(vbox, "garment", "UI_NOTE_GARMENT_INITIAL")
	_add_board_row(vbox, "person", "UI_NOTE_PERSON_INITIAL")
	_interpretation_layer.visible = true

func _add_board_row(parent: VBoxContainer, row_id: String, text_value: String) -> void:
	var label := Label.new()
	label.name = "Row_" + row_id
	label.text = tr(text_value)
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
	label.text = tr(text_value)
	label.add_theme_color_override("font_color", color)

func _configure_scene_foxfires() -> void:
	_foxfire_sources.clear()
	_hide_warm_lantern_fire()
	for root_path in ["PropsBack", "PropsFront"]:
		var root := get_node_or_null(root_path)
		if not root:
			continue
		for child in root.get_children():
			var lantern := child as Node2D
			if lantern and str(lantern.name).begins_with("StoneLantern_"):
				_register_foxfire_source(lantern)
	_reposition_legacy_foxfire_marker()

func _hide_warm_lantern_fire() -> void:
	var fx := get_node_or_null("FX")
	if fx:
		for child in fx.get_children():
			if str(child.name).begins_with("LanternFlame_") and child is CanvasItem:
				(child as CanvasItem).visible = false
	var lighting := get_node_or_null("Lighting")
	if lighting:
		for child in lighting.get_children():
			if str(child.name).begins_with("LanternLight_") and child is CanvasItem:
				(child as CanvasItem).visible = false

func _register_foxfire_source(lantern: Node2D) -> void:
	_foxfire_sources.append(lantern)
	var source_id := str(lantern.name).trim_prefix("StoneLantern_")
	var flame_position := lantern.global_position + FOXFIRE_FLAME_OFFSET
	_ensure_blue_lantern_light(source_id, flame_position)
	_ensure_blue_lantern_flame(source_id, flame_position)

func _ensure_blue_lantern_light(source_id: String, global_pos: Vector2) -> void:
	var lighting := get_node_or_null("Lighting")
	if not lighting:
		return
	var light := lighting.get_node_or_null("BlueLanternLight_" + source_id) as PointLight2D
	if not light:
		light = PointLight2D.new()
		light.name = "BlueLanternLight_" + source_id
		lighting.add_child(light)
	light.texture = COLD_LIGHT_TEXTURE
	light.texture_scale = 1.18
	light.energy = 0.34
	light.color = Color(0.42, 0.72, 1.0, 0.92)
	light.global_position = global_pos
	light.visible = true

func _ensure_blue_lantern_flame(source_id: String, global_pos: Vector2) -> void:
	var fx := get_node_or_null("FX")
	if not fx:
		return
	var flame := fx.get_node_or_null("BlueFlame_" + source_id) as AnimatedSprite2D
	if not flame:
		flame = AnimatedSprite2D.new()
		flame.name = "BlueFlame_" + source_id
		fx.add_child(flame)
	flame.sprite_frames = _get_blue_flame_frames()
	flame.animation = &"loop"
	flame.centered = false
	flame.offset = Vector2(-64, -128)
	flame.scale = Vector2(0.72, 0.72)
	flame.global_position = global_pos
	flame.visible = true
	flame.play("loop")

func _get_blue_flame_frames() -> SpriteFrames:
	if _blue_flame_frames:
		return _blue_flame_frames
	var frames := SpriteFrames.new()
	frames.add_animation(&"loop")
	frames.set_animation_loop(&"loop", true)
	frames.set_animation_speed(&"loop", 8.0)
	for i in range(8):
		var atlas := AtlasTexture.new()
		atlas.atlas = BLUE_FLAME_TEXTURE
		atlas.region = Rect2(i * 128, 0, 128, 128)
		frames.add_frame(&"loop", atlas)
	_blue_flame_frames = frames
	return _blue_flame_frames

func _reposition_legacy_foxfire_marker() -> void:
	if not _foxfire_pickup_marker:
		return
	for source in _foxfire_sources:
		if source and source.name == &"StoneLantern_FoxfirePickup":
			_foxfire_pickup_marker.global_position = source.global_position
			return

func _is_near_foxfire_source() -> bool:
	if not player:
		return false
	for source in _foxfire_sources:
		if is_instance_valid(source) and player.global_position.distance_to(source.global_position) < FOXFIRE_PICKUP_DISTANCE:
			return true
	if _foxfire_pickup_marker:
		return player.global_position.distance_to(_foxfire_pickup_marker.global_position) < FOXFIRE_PICKUP_DISTANCE
	return false

func _is_near_final_reflection_spot() -> bool:
	if not player or not _foxfire_pickup_marker:
		return false
	return player.global_position.distance_to(_foxfire_pickup_marker.global_position) < FINAL_REFLECTION_DISTANCE

func _update_understanding_links() -> void:
	if _clues_found[0] and _clues_found[1]:
		_set_board_row("ritual", "UI_NOTE_RITUAL_SHIFTED", Color(0.90, 0.82, 0.56))
	if _clues_found[2] and _clues_found[3]:
		_set_board_row("garment", "UI_NOTE_GARMENT_SHIFTED", Color(0.86, 0.88, 0.96))
	if _clues_found[4] and (_clues_found[2] or _clues_found[3]):
		_set_board_row("person", "UI_NOTE_PERSON_SHIFTED", Color(0.96, 0.76, 0.60))

	if _clues_found[0] and _clues_found[1] and not _insights_unlocked.has("ritual_name"):
		_insights_unlocked["ritual_name"] = true
		DialogManager.show_dialog([
			{"speaker": "CHAR_PLAYER", "text": "DIALOG_L3_INSIGHT_RITUAL_01"},
			{"speaker": "CHAR_PLAYER", "text": "DIALOG_L3_INSIGHT_RITUAL_02"},
		] as Array[Dictionary])
		await DialogManager.dialog_finished

	if _clues_found[2] and not _insights_unlocked.has("paper_masked"):
		_insights_unlocked["paper_masked"] = true
		DialogManager.show_dialog([
			{"speaker": "CHAR_PLAYER", "text": "DIALOG_L3_INSIGHT_PAPER_01"},
		] as Array[Dictionary])
		await DialogManager.dialog_finished

	if _clues_found[2] and _clues_found[3] and not _insights_unlocked.has("white_misread"):
		_insights_unlocked["white_misread"] = true
		DialogManager.show_dialog([
			{"speaker": "CHAR_PLAYER", "text": "DIALOG_L3_INSIGHT_GARMENT_01"},
		] as Array[Dictionary])
		await DialogManager.dialog_finished

	if _clues_found[4] and (_clues_found[2] or _clues_found[3]) and not _insights_unlocked.has("sayo"):
		_insights_unlocked["sayo"] = true
		DialogManager.show_dialog([
			{"speaker": "CHAR_PLAYER", "text": "DIALOG_L3_INSIGHT_PERSON_01"},
			{"speaker": "CHAR_PLAYER", "text": "DIALOG_L3_INSIGHT_PERSON_02"},
			{"speaker": "CHAR_PLAYER", "text": "DIALOG_L3_INSIGHT_PERSON_03"},
		] as Array[Dictionary])
		await DialogManager.dialog_finished

func _show_final_reflection() -> void:
	_truth_reveal_in_progress = true
	await _unlock_plaque()
	_truth_revealed = true
	_truth_reveal_in_progress = false

func _unlock_plaque() -> void:
	await get_tree().create_timer(0.45).timeout
	DialogManager.show_dialog([
		{"speaker": "", "text": "DIALOG_L3_UNLOCK_PLAQUE_01"},
		{"speaker": "", "text": "DIALOG_L3_UNLOCK_PLAQUE_02"},
		{"speaker": "CHAR_PLAYER", "text": "DIALOG_L3_UNLOCK_PLAQUE_03"},
		{"speaker": "CHAR_PLAYER", "text": "DIALOG_L3_UNLOCK_PLAQUE_04"},
	] as Array[Dictionary])
	await DialogManager.dialog_finished
	_foxfire_pickup_unlocked = true
	_set_foxfire_pickup_visible(true)

func _on_foxfire_pickup() -> void:
	if not _foxfire_pickup_unlocked or _foxfire_collected:
		return
	_foxfire_collected = true
	if player and player.has_method("set_external_interact_prompt"):
		player.set_external_interact_prompt("", false)
	play_sfx(SFX_FOXFIRE)
	DialogManager.show_dialog([
		{"speaker": "", "text": "DIALOG_L3_FOXFIRE_PICKUP_01"},
		{"speaker": "CHAR_PLAYER", "text": "DIALOG_L3_FOXFIRE_PICKUP_02"},
	] as Array[Dictionary])
	await DialogManager.dialog_finished

func _on_plaque_interact() -> void:
	if _plaque_transformed or not _foxfire_collected:
		return
	_plaque_transformed = true
	if player and player.has_method("set_external_interact_prompt"):
		player.set_external_interact_prompt("", false)
	_set_plaque_foxfire_visible(true)
	play_sfx(SFX_PLAQUE_REVEAL)
	_set_plaque_state("UI_PLAQUE_REVEAL_FINAL")
	DialogManager.show_dialog([
		{"speaker": "", "text": "DIALOG_L3_PLAQUE_REVEAL_01"},
		{"speaker": "", "text": "DIALOG_L3_PLAQUE_REVEAL_02"},
		{"speaker": "", "text": "DIALOG_L3_PLAQUE_REVEAL_03"},
		{"speaker": "", "text": "DIALOG_L3_PLAQUE_REVEAL_04"},
		{"speaker": "CHAR_PLAYER", "text": "DIALOG_L3_PLAQUE_REVEAL_05"},
	] as Array[Dictionary])
	await DialogManager.dialog_finished
	_set_board_row("ritual", "UI_NOTE_RITUAL_REVEALED", Color(1.00, 0.76, 0.42))
	_paper_recheck_unlocked = true
	if _paper_chest and _paper_chest.has_method("enable_final_recheck"):
		_paper_chest.call("enable_final_recheck")

func _set_foxfire_pickup_visible(active: bool) -> void:
	for source in _foxfire_sources:
		if not is_instance_valid(source):
			continue
		var source_id := str(source.name).trim_prefix("StoneLantern_")
		var flame := get_node_or_null("FX/BlueFlame_" + source_id) as AnimatedSprite2D
		var light := get_node_or_null("Lighting/BlueLanternLight_" + source_id) as PointLight2D
		if flame:
			flame.visible = true
			flame.modulate = Color(1.0, 1.0, 1.0, 1.0 if active else 0.78)
			flame.play("loop")
		if light:
			light.visible = true
			light.energy = 0.40 if active else 0.30
	if _foxfire_pickup_flame:
		_foxfire_pickup_flame.visible = true
		_foxfire_pickup_flame.play("loop")
	if _foxfire_pickup_light:
		_foxfire_pickup_light.visible = true

func _set_plaque_foxfire_visible(active: bool) -> void:
	if _plaque_foxfire:
		_plaque_foxfire.visible = active
		if active:
			_plaque_foxfire.play("loop")

func _on_chest_rechecked() -> void:
	if not _paper_recheck_unlocked or _paper_rechecked:
		return
	_paper_rechecked = true
	await _show_paper_note(true, "DIALOG_L3_PAPER_RECHECK_CAPTION_01")
	DialogManager.show_dialog([
		{"speaker": "", "text": "DIALOG_L3_PAPER_RECHECK_01"},
		{"speaker": "CHAR_PLAYER", "text": "DIALOG_L3_PAPER_RECHECK_03"},
		{"speaker": "CHAR_PLAYER", "text": "DIALOG_L3_PAPER_RECHECK_04"},
	] as Array[Dictionary])
	await DialogManager.dialog_finished
	_set_board_row("garment", "UI_NOTE_GARMENT_REVEALED", Color(0.96, 0.93, 0.98))

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
		{"speaker": "", "text": "DIALOG_L3_INNER_01"},
		{"speaker": "", "text": "DIALOG_L3_INNER_02"},
		{"speaker": "", "text": "DIALOG_L3_INNER_03"},
		{"speaker": "", "text": "DIALOG_L3_INNER_04"},
		{"speaker": "CHAR_PLAYER", "text": "DIALOG_L3_INNER_05"},
		{"speaker": "", "text": "DIALOG_L3_INNER_06"},
		{"speaker": "CHAR_PLAYER", "text": "DIALOG_L3_INNER_07"},
		{"speaker": "CHAR_PLAYER", "text": "DIALOG_L3_INNER_08"},
	] as Array[Dictionary])
	await DialogManager.dialog_finished
	_set_board_row("person", "UI_NOTE_PERSON_REVEALED", Color(1.00, 0.68, 0.52))
	await get_tree().create_timer(0.45).timeout
	show_choice(
		"UI_CHOICE_L3_TITLE",
		"UI_CHOICE_L3_A", "UI_CHOICE_L3_B",
		"UI_CHOICE_L3_DESC_A", "UI_CHOICE_L3_DESC_B",
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
		_plaque_label.rotation = deg_to_rad(-2.0)
		_plaque_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_plaque_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_plaque_label.add_theme_font_override("font", _get_plaque_font())
		_plaque_label.add_theme_font_size_override("font_size", 38)
		_plaque_label.add_theme_color_override("font_color", Color(0.92, 0.72, 0.34))
		_plaque_label.add_theme_color_override("font_shadow_color", Color(0.05, 0.025, 0.01, 0.86))
		_plaque_label.add_theme_color_override("font_outline_color", Color(0.18, 0.08, 0.025, 0.75))
		_plaque_label.add_theme_constant_override("outline_size", 2)
		_plaque_label.add_theme_constant_override("shadow_offset_x", 2)
		_plaque_label.add_theme_constant_override("shadow_offset_y", 2)
		_plaque_sprite.add_child(_plaque_label)
	_plaque_label.rotation = deg_to_rad(-2.0 if text_value == "UI_PLAQUE_REVEAL_INITIAL" else 1.5)
	_plaque_label.text = tr(text_value)

func _get_plaque_font() -> Font:
	if _plaque_font:
		return _plaque_font
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Kaiti SC", "STKaiti", "HanziPen SC", "Hiragino Mincho ProN", "Songti SC"])
	_plaque_font = font
	return _plaque_font

func _get_paper_font() -> Font:
	if _paper_font:
		return _paper_font
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["HanziPen SC", "Kaiti SC", "STKaiti", "Hiragino Mincho ProN", "Songti SC"])
	_paper_font = font
	return _paper_font

func _show_paper_note(revealed: bool, caption_text := "") -> void:
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
	note.custom_minimum_size = Vector2(500, 500)
	note.anchor_left = 0.5
	note.anchor_top = 0.5
	note.anchor_right = 0.5
	note.anchor_bottom = 0.5
	note.offset_left = -250
	note.offset_top = -270
	note.offset_right = 250
	note.offset_bottom = 230
	_paper_layer.add_child(note)

	_add_vertical_paper_text(revealed)

	if caption_text != "":
		var caption_panel := PanelContainer.new()
		caption_panel.anchor_left = 0.5
		caption_panel.anchor_top = 0.5
		caption_panel.anchor_right = 0.5
		caption_panel.anchor_bottom = 0.5
		caption_panel.offset_left = -420
		caption_panel.offset_top = 236
		caption_panel.offset_right = 420
		caption_panel.offset_bottom = 316
		var caption_style := StyleBoxFlat.new()
		caption_style.bg_color = Color(0.035, 0.028, 0.038, 0.92)
		caption_style.border_color = Color(0.55, 0.42, 0.27, 0.85)
		caption_style.set_border_width_all(2)
		caption_style.set_corner_radius_all(0)
		caption_style.set_content_margin_all(14)
		caption_panel.add_theme_stylebox_override("panel", caption_style)
		_paper_layer.add_child(caption_panel)

		var caption := Label.new()
		caption.text = tr(caption_text)
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		caption.add_theme_font_size_override("font_size", 26)
		caption.add_theme_color_override("font_color", Color(0.90, 0.84, 0.73))
		caption_panel.add_child(caption)

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
	await _wait_for_interact_release()
	while true:
		await get_tree().process_frame
		if Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("jump"):
			break
	_paper_layer.queue_free()
	_paper_layer = null
	GameManager.set_state(GameManager.State.PLAYING)

func _wait_for_interact_release() -> void:
	while Input.is_action_pressed("interact") or Input.is_action_pressed("jump"):
		await get_tree().process_frame

func _add_vertical_paper_text(revealed: bool) -> void:
	var middle_char := "UI_PAPER_NOTE_REVEALED_CHAR" if revealed else "UI_PAPER_NOTE_MASKED_CHAR"
	var entries := [
		{"text": "UI_PAPER_NOTE_WHITE_CHAR", "texture_pos": Vector2(168, 38)},
		{"text": middle_char, "texture_pos": Vector2(168, 126)},
		{"text": "UI_PAPER_NOTE_COVER_CHAR", "texture_pos": Vector2(168, 202)},
		{"text": "UI_PAPER_NOTE_BODY_CHAR", "texture_pos": Vector2(116, 202)},
	]
	for entry in entries:
		_add_paper_character(entry["text"], entry["texture_pos"])

func _add_paper_character(text_value: String, texture_pos: Vector2) -> void:
	var center := Vector2(-250, -270) + texture_pos * (500.0 / 256.0)
	var size := Vector2(76, 76)
	var label := Label.new()
	label.text = tr(text_value)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", _get_paper_font())
	label.add_theme_font_size_override("font_size", 42)
	label.add_theme_color_override("font_color", Color(0.18, 0.11, 0.07, 0.95))
	label.add_theme_color_override("font_shadow_color", Color(0.56, 0.38, 0.18, 0.28))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.anchor_left = 0.5
	label.anchor_top = 0.5
	label.anchor_right = 0.5
	label.anchor_bottom = 0.5
	label.offset_left = center.x - size.x * 0.5
	label.offset_top = center.y - size.y * 0.5
	label.offset_right = center.x + size.x * 0.5
	label.offset_bottom = center.y + size.y * 0.5
	_paper_layer.add_child(label)

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
