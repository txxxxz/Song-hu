extends Node

signal offering_changed()
signal branch_selected(level: int, choice: String)
signal state_changed(new_state: int)
signal scene_transition_started()
signal scene_transition_finished()

enum State { MENU, PLAYING, DIALOG, CHOICE, CUTSCENE, PAUSED }

var current_state: State = State.MENU
var previous_state: State = State.MENU
var current_level: int = 0
var branch_choices: Dictionary = {}
var player_ref: CharacterBody2D = null
var offering_stack: Array[Dictionary] = []

const MAX_OFFERINGS := 4

var ITEMS: Dictionary = {
	"sugi_wood": {
		"id": "sugi_wood",
		"name": "杉木",
		"desc": "山间古杉的木料，沉而稳，是承托之物。",
		"color": Color(0.56, 0.36, 0.22),
		"glow": false,
	},
	"white_fur": {
		"id": "white_fur",
		"name": "白毛",
		"desc": "洁白如雪的毛束。也许它本应被称作白衣。",
		"color": Color(0.94, 0.93, 0.98),
		"glow": false,
	},
	"mugwort": {
		"id": "mugwort",
		"name": "蓬草",
		"desc": "气味清烈的野草。覆于顶端，遮味避秽。",
		"color": Color(0.30, 0.56, 0.26),
		"glow": false,
	},
	"bell_fiber": {
		"id": "bell_fiber",
		"name": "铃绳纤维",
		"desc": "取自神社铃绳的细纤维，能温和地呼唤。",
		"color": Color(0.86, 0.75, 0.54),
		"glow": false,
	},
	"fox_stone": {
		"id": "fox_stone",
		"name": "狐火石",
		"desc": "触之微温的奇石，内部有火色流光。",
		"color": Color(1.0, 0.58, 0.16),
		"glow": true,
	},
	"water_grass": {
		"id": "water_grass",
		"name": "清水草",
		"desc": "生于清泉边的苔草，可以镇静安抚。",
		"color": Color(0.38, 0.70, 0.75),
		"glow": false,
	},
	"lamp_oil": {
		"id": "lamp_oil",
		"name": "灯芯油",
		"desc": "可燃之油。能放大狐火，也会让火势难控。",
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

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_input_map()

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
		DialogManager.show_single("我", "桶已经塞不下东西了。")
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
