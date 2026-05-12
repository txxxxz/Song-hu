extends CanvasLayer

const ITEM_ICON_TEXTURES := {
	"sugi_wood": preload("res://assets/sprites/objects/item_sugi_wood.png"),
	"white_fur": preload("res://assets/sprites/objects/item_white_fur.png"),
	"mugwort": preload("res://assets/sprites/objects/item_mugwort.png"),
	"bell_fiber": preload("res://assets/sprites/objects/item_bell_fiber.png"),
	"fox_stone": preload("res://assets/sprites/objects/item_fox_stone.png"),
	"water_grass": preload("res://assets/sprites/objects/item_water_grass.png"),
	"lamp_oil": preload("res://assets/sprites/objects/item_lamp_oil.png"),
}

@onready var _area_label: Label = $AreaLabel
@onready var _offering_vbox: VBoxContainer = $OfferingTube/OfferingVBox

func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not GameManager.offering_changed.is_connected(_update_offerings):
		GameManager.offering_changed.connect(_update_offerings)
	_update_offerings()

func set_area_name(area_name: String) -> void:
	if not _area_label:
		return
	_area_label.text = area_name
	_area_label.modulate = Color(1, 1, 1, 0)
	var tween := create_tween()
	tween.tween_property(_area_label, "modulate:a", 1.0, 0.55)
	tween.tween_interval(2.0)
	tween.tween_property(_area_label, "modulate:a", 0.0, 0.8)

func _update_offerings() -> void:
	if not _offering_vbox:
		return
	for child in _offering_vbox.get_children():
		child.queue_free()

	var stack: Array[Dictionary] = GameManager.get_offerings_bottom_to_top()
	if stack.is_empty():
		var empty := Label.new()
		empty.text = "（空）"
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.add_theme_color_override("font_color", Color(0.58, 0.54, 0.48, 0.70))
		empty.add_theme_font_size_override("font_size", 18)
		empty.custom_minimum_size = Vector2(192, 36)
		_offering_vbox.add_child(empty)
		return

	for i in range(stack.size() - 1, -1, -1):
		var item: Dictionary = stack[i]
		var hbox := HBoxContainer.new()
		hbox.custom_minimum_size = Vector2(192, 42)
		hbox.add_theme_constant_override("separation", 8)

		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(36, 36)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture = ITEM_ICON_TEXTURES.get(item.get("id", ""), null)
		hbox.add_child(icon)

		var name_label := Label.new()
		name_label.text = item.get("name", "???")
		name_label.add_theme_color_override("font_color", Color(0.88, 0.82, 0.70))
		name_label.add_theme_font_size_override("font_size", 17)
		name_label.clip_text = true
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(name_label)

		var idx_label := Label.new()
		if i == 0:
			idx_label.text = "底"
		elif i == stack.size() - 1:
			idx_label.text = "顶"
		else:
			idx_label.text = str(i + 1)
		idx_label.add_theme_color_override("font_color", Color(0.62, 0.56, 0.45, 0.72))
		idx_label.add_theme_font_size_override("font_size", 16)
		hbox.add_child(idx_label)

		_offering_vbox.add_child(hbox)
