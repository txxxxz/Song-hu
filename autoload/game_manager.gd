extends Node

signal offering_changed()
signal branch_selected(level: int, choice: String)
signal state_changed(new_state: int)
signal scene_transition_started()
signal scene_transition_finished()
signal locale_changed(locale: String)

enum State { MENU, PLAYING, DIALOG, CHOICE, CUTSCENE, PAUSED }

var current_state: State = State.MENU
var previous_state: State = State.MENU
var current_level: int = 0
var current_locale: String = ""
var branch_choices: Dictionary = {}
var player_ref: CharacterBody2D = null
var offering_stack: Array[Dictionary] = []

const MAX_OFFERINGS := 4
const DEFAULT_LOCALE := "zh_CN"
const SETTINGS_PATH := "user://settings.cfg"
const SETTINGS_SECTION := "localization"
const SETTINGS_KEY := "locale"

const TRANSLATION_FILES := [
	"res://i18n/ui.zh_CN.translation",
	"res://i18n/ui.en.translation",
	"res://i18n/dialogs.zh_CN.translation",
	"res://i18n/dialogs.en.translation",
	"res://i18n/cutscenes.zh_CN.translation",
	"res://i18n/cutscenes.en.translation",
	"res://i18n/items.zh_CN.translation",
	"res://i18n/items.en.translation",
]

var ITEMS: Dictionary = {
	"sugi_wood": {
		"id": "sugi_wood",
		"name_key": "ITEM_SUGI_WOOD_NAME",
		"desc_key": "ITEM_SUGI_WOOD_DESC",
		"color": Color(0.56, 0.36, 0.22),
		"glow": false,
	},
	"white_fur": {
		"id": "white_fur",
		"name_key": "ITEM_WHITE_FUR_NAME",
		"desc_key": "ITEM_WHITE_FUR_DESC",
		"color": Color(0.94, 0.93, 0.98),
		"glow": false,
	},
	"mugwort": {
		"id": "mugwort",
		"name_key": "ITEM_MUGWORT_NAME",
		"desc_key": "ITEM_MUGWORT_DESC",
		"color": Color(0.30, 0.56, 0.26),
		"glow": false,
	},
	"bell_fiber": {
		"id": "bell_fiber",
		"name_key": "ITEM_BELL_FIBER_NAME",
		"desc_key": "ITEM_BELL_FIBER_DESC",
		"color": Color(0.86, 0.75, 0.54),
		"glow": false,
	},
	"fox_stone": {
		"id": "fox_stone",
		"name_key": "ITEM_FOX_STONE_NAME",
		"desc_key": "ITEM_FOX_STONE_DESC",
		"color": Color(1.0, 0.58, 0.16),
		"glow": true,
	},
	"water_grass": {
		"id": "water_grass",
		"name_key": "ITEM_WATER_GRASS_NAME",
		"desc_key": "ITEM_WATER_GRASS_DESC",
		"color": Color(0.38, 0.70, 0.75),
		"glow": false,
	},
	"lamp_oil": {
		"id": "lamp_oil",
		"name_key": "ITEM_LAMP_OIL_NAME",
		"desc_key": "ITEM_LAMP_OIL_DESC",
		"color": Color(0.76, 0.46, 0.10),
		"glow": true,
	},
}

var ALTAR_ORDERS: Dictionary = {
	1: ["sugi_wood", "white_fur", "mugwort"],
	2: ["sugi_wood", "white_fur", "mugwort"],
}

var ALTAR_TOP_OFFERINGS: Dictionary = {
	1: ["bell_fiber", "fox_stone"],
}

func _enter_tree() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_localization()
	_setup_input_map()

func _setup_localization() -> void:
	for path in TRANSLATION_FILES:
		var translation := load(path)
		if translation is Translation:
			TranslationServer.add_translation(translation)
		else:
			push_warning("Failed to load translation resource: %s" % path)
	set_locale(_load_saved_locale(), false)

func _load_saved_locale() -> String:
	var cfg := ConfigFile.new()
	var err := cfg.load(SETTINGS_PATH)
	if err == OK:
		var saved := str(cfg.get_value(SETTINGS_SECTION, SETTINGS_KEY, ""))
		if saved != "":
			return saved
	var fallback := str(ProjectSettings.get_setting("internationalization/locale/fallback", DEFAULT_LOCALE))
	return fallback if fallback != "" else DEFAULT_LOCALE

func _save_locale(locale: String) -> void:
	var cfg := ConfigFile.new()
	var _err := cfg.load(SETTINGS_PATH)
	cfg.set_value(SETTINGS_SECTION, SETTINGS_KEY, locale)
	cfg.save(SETTINGS_PATH)

func set_locale(locale: String, persist: bool = true) -> void:
	var next_locale := locale.strip_edges()
	if next_locale == "":
		next_locale = DEFAULT_LOCALE
	if current_locale == next_locale:
		if persist:
			_save_locale(next_locale)
		return
	current_locale = next_locale
	TranslationServer.set_locale(next_locale)
	if persist:
		_save_locale(next_locale)
	locale_changed.emit(next_locale)

func _setup_input_map() -> void:
	_add_key_action("move_left", [KEY_A, KEY_LEFT])
	_add_key_action("move_right", [KEY_D, KEY_RIGHT])
	_add_key_action("jump", [KEY_SPACE, KEY_W, KEY_UP])
	_add_key_action("interact", [KEY_E])
	_add_key_action("pause", [KEY_ESCAPE])

func _add_key_action(action_name: String, keys: Array) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	for key in keys:
		var exists := false
		for event in InputMap.action_get_events(action_name):
			if event is InputEventKey and event.physical_keycode == key:
				exists = true
				break
		if exists:
			continue
		var ev := InputEventKey.new()
		ev.physical_keycode = key
		InputMap.action_add_event(action_name, ev)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if current_state == State.PLAYING:
			set_state(State.PAUSED)
			get_tree().paused = true
		elif current_state == State.PAUSED:
			set_state(State.PLAYING)
			get_tree().paused = false

func set_state(new_state: State) -> void:
	previous_state = current_state
	current_state = new_state
	state_changed.emit(new_state)

func is_playing() -> bool:
	return current_state == State.PLAYING

func push_offering(item_id: String) -> bool:
	if not ITEMS.has(item_id):
		return false
	if offering_stack.size() >= MAX_OFFERINGS:
		DialogManager.show_single("CHAR_PLAYER", "UI_OFFERING_TUBE_FULL")
		return false
	offering_stack.push_back(ITEMS[item_id].duplicate())
	offering_changed.emit()
	return true

func pop_offering() -> Dictionary:
	if offering_stack.is_empty():
		return {}
	var item: Dictionary = offering_stack.pop_back()
	offering_changed.emit()
	return item

func peek_offering() -> Dictionary:
	if offering_stack.is_empty():
		return {}
	return offering_stack.back()

func get_offerings_bottom_to_top() -> Array[Dictionary]:
	return offering_stack.duplicate()

func clear_offerings() -> void:
	offering_stack.clear()
	offering_changed.emit()

func get_offering_count() -> int:
	return offering_stack.size()

func get_required_offering_count(level: int) -> int:
	var expected_count: int = ALTAR_ORDERS.get(level, []).size()
	if ALTAR_TOP_OFFERINGS.has(level):
		expected_count += 1
	return expected_count

func get_item_name_key(item_id: String) -> String:
	if ITEMS.has(item_id):
		return str(ITEMS[item_id].get("name_key", ""))
	return ""

func get_item_desc_key(item_id: String) -> String:
	if ITEMS.has(item_id):
		return str(ITEMS[item_id].get("desc_key", ""))
	return ""

func get_item_name(item_id: String) -> String:
	var key := get_item_name_key(item_id)
	return tr(key) if key != "" else ""

func get_item_desc(item_id: String) -> String:
	var key := get_item_desc_key(item_id)
	return tr(key) if key != "" else ""

func validate_altar_order(level: int) -> bool:
	if not ALTAR_ORDERS.has(level):
		return true
	var expected: Array = ALTAR_ORDERS[level]
	if offering_stack.size() < get_required_offering_count(level):
		return false
	for i in range(expected.size()):
		if offering_stack[i].get("id", "") != expected[i]:
			return false
	if ALTAR_TOP_OFFERINGS.has(level):
		var top_id := str(offering_stack[get_required_offering_count(level) - 1].get("id", ""))
		if not ALTAR_TOP_OFFERINGS[level].has(top_id):
			return false
	return true

func set_branch(level: int, choice: String) -> void:
	branch_choices[level] = choice
	branch_selected.emit(level, choice)

func get_branch(level: int) -> String:
	return branch_choices.get(level, "")

func is_a_path() -> bool:
	return get_branch(1) == "A"

func is_b_path() -> bool:
	return get_branch(1) == "B"

func change_scene(path: String) -> void:
	scene_transition_started.emit()
	var canvas := CanvasLayer.new()
	canvas.layer = 100
	add_child(canvas)

	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(overlay)

	var tween := create_tween()
	tween.tween_property(overlay, "color:a", 1.0, 0.35)
	tween.tween_callback(func():
		get_tree().paused = false
		get_tree().change_scene_to_file(path)
	)
	tween.tween_interval(0.15)
	tween.tween_property(overlay, "color:a", 0.0, 0.35)
	tween.tween_callback(func():
		canvas.queue_free()
		scene_transition_finished.emit()
	)

func transition_to_level(level: int) -> void:
	current_level = level
	clear_offerings()
	set_state(State.PLAYING)
	match level:
		1:
			change_scene("res://scenes/levels/level_1.tscn")
		2:
			change_scene("res://scenes/levels/level_2.tscn")
		3:
			change_scene("res://scenes/levels/level_3.tscn")

func restart_current_level() -> void:
	if current_level > 0:
		transition_to_level(current_level)

func transition_to_ending(ending: String) -> void:
	set_state(State.CUTSCENE)
	match ending:
		"A":
			change_scene("res://scenes/cutscenes/ending_a.tscn")
		"B":
			change_scene("res://scenes/cutscenes/ending_b.tscn")

func go_to_menu() -> void:
	current_level = 0
	branch_choices.clear()
	offering_stack.clear()
	set_state(State.MENU)
	change_scene("res://scenes/ui/main_menu.tscn")

func start_new_game() -> void:
	current_level = 0
	branch_choices.clear()
	offering_stack.clear()
	set_state(State.CUTSCENE)
	change_scene("res://scenes/cutscenes/opening.tscn")

func start_after_opening() -> void:
	transition_to_level(1)
