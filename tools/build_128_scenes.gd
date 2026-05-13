extends Node

const VIEW := Vector2(1280, 720)
const TILE := 128

func _ready() -> void:
	if "--level-2-only" in OS.get_cmdline_user_args():
		_make_dirs()
		_build_level_2()
		print("Built Level 2 scene.")
		get_tree().quit()
		return
	_make_dirs()
	_build_player_scene()
	_build_object_scenes()
	_build_hud_scene()
	_build_choice_panel_scene()
	_build_main_menu_scene()
	_build_cutscene("res://scenes/cutscenes/ending_a.tscn", "res://scenes/cutscenes/ending_a.gd", Color(0.025, 0.020, 0.030, 1.0))
	_build_cutscene("res://scenes/cutscenes/ending_b.tscn", "res://scenes/cutscenes/ending_b.gd", Color(0.045, 0.020, 0.018, 1.0))
	_build_level_1()
	_build_level_2()
	_build_level_3()
	print("Built 128 HD placeholder scenes.")
	get_tree().quit()

func _make_dirs() -> void:
	for path in [
		"res://scenes/player",
		"res://scenes/objects",
		"res://scenes/ui",
		"res://scenes/cutscenes",
		"res://scenes/levels",
	]:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path))

func _save_scene(root: Node, path: String) -> void:
	_assign_owner(root, root)
	var scene := PackedScene.new()
	var pack_err := scene.pack(root)
	if pack_err != OK:
		push_error("Failed to pack " + path + ": " + str(pack_err))
		return
	var save_err := ResourceSaver.save(scene, path)
	if save_err != OK:
		push_error("Failed to save " + path + ": " + str(save_err))

func _assign_owner(node: Node, owner: Node) -> void:
	for child in node.get_children():
		child.owner = owner
		if child.scene_file_path != "":
			continue
		_assign_owner(child, owner)

func _tex(path: String) -> Texture2D:
	return load(path) as Texture2D

func _bottom_sprite(name: String, texture_path: String) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = name
	sprite.texture = _tex(texture_path)
	sprite.centered = false
	var size := sprite.texture.get_size()
	sprite.offset = Vector2(-size.x * 0.5, -size.y)
	return sprite

func _top_sprite(name: String, texture_path: String) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = name
	sprite.texture = _tex(texture_path)
	sprite.centered = false
	var size := sprite.texture.get_size()
	sprite.offset = Vector2(-size.x * 0.5, 0)
	return sprite

func _animated_bottom_sprite(name: String, animations: Array[Dictionary], frame_size: Vector2i) -> AnimatedSprite2D:
	var sprite := AnimatedSprite2D.new()
	sprite.name = name
	sprite.centered = false
	sprite.offset = Vector2(-frame_size.x * 0.5, -frame_size.y)
	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")
	for spec in animations:
		var anim := str(spec["name"])
		frames.add_animation(anim)
		frames.set_animation_loop(anim, spec.get("loop", true))
		frames.set_animation_speed(anim, float(spec.get("speed", 8.0)))
		var atlas := _tex(str(spec["path"]))
		var count := int(spec["frames"])
		for i in range(count):
			var frame := AtlasTexture.new()
			frame.atlas = atlas
			frame.region = Rect2(i * frame_size.x, 0, frame_size.x, frame_size.y)
			frames.add_frame(anim, frame)
	sprite.sprite_frames = frames
	sprite.animation = str(animations[0]["name"])
	sprite.play()
	return sprite

func _animated_fx_sprite(name: String, texture_path: String, frame_size: Vector2i, frames_count: int, speed := 8.0) -> AnimatedSprite2D:
	return _animated_bottom_sprite(name, [
		{"name": "loop", "path": texture_path, "frames": frames_count, "speed": speed, "loop": true},
	], frame_size)

func _rect_shape(size: Vector2, pos: Vector2 = Vector2.ZERO, name_value := "CollisionShape2D") -> CollisionShape2D:
	var col := CollisionShape2D.new()
	col.name = name_value
	var shape := RectangleShape2D.new()
	shape.size = size
	col.shape = shape
	col.position = pos
	return col

func _label(name: String, text_value: String, pos: Vector2, size: Vector2, font_size: int, color: Color, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Label.new()
	label.name = name
	label.text = text_value
	label.position = pos
	label.size = size
	label.horizontal_alignment = align
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _panel_style(bg: Color, border: Color, border_width: int = 3) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(0)
	style.set_content_margin_all(20)
	return style

func _texture_style(texture_path: String, margin := 18) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = _tex(texture_path)
	style.texture_margin_left = margin
	style.texture_margin_right = margin
	style.texture_margin_top = margin
	style.texture_margin_bottom = margin
	style.draw_center = true
	return style

func _build_player_scene() -> void:
	var root := CharacterBody2D.new()
	root.name = "Player"
	root.script = load("res://scenes/player/player.gd")
	root.collision_layer = 1
	root.collision_mask = 4
	root.floor_snap_length = 18.0

	var visual := Node2D.new()
	visual.name = "Visual"
	root.add_child(visual)
	visual.add_child(_animated_bottom_sprite("Sprite", [
		{"name": "idle", "path": "res://assets/sprites/player/miko_idle.png", "frames": 8, "speed": 7.0, "loop": true},
		{"name": "run", "path": "res://assets/sprites/player/miko_run.png", "frames": 8, "speed": 11.0, "loop": true},
		{"name": "jump", "path": "res://assets/sprites/player/miko_jump.png", "frames": 4, "speed": 8.0, "loop": false},
		{"name": "fall", "path": "res://assets/sprites/player/miko_fall.png", "frames": 3, "speed": 8.0, "loop": true},
		{"name": "interact", "path": "res://assets/sprites/player/miko_interact.png", "frames": 6, "speed": 8.0, "loop": false},
		{"name": "turn", "path": "res://assets/sprites/player/miko_turn.png", "frames": 4, "speed": 8.0, "loop": false},
		{"name": "pray", "path": "res://assets/sprites/player/miko_pray.png", "frames": 8, "speed": 7.0, "loop": true},
	], Vector2i(256, 384)))

	root.add_child(_rect_shape(Vector2(80, 216), Vector2(0, -108)))

	var interaction := Area2D.new()
	interaction.name = "InteractionArea"
	interaction.collision_layer = 0
	interaction.collision_mask = 2
	interaction.add_child(_rect_shape(Vector2(260, 220), Vector2(0, -150)))
	root.add_child(interaction)

	var prompt := _label("InteractPrompt", "E", Vector2(-160, -430), Vector2(320, 48), 28, Color(1.0, 0.86, 0.45), HORIZONTAL_ALIGNMENT_CENTER)
	prompt.visible = false
	root.add_child(prompt)
	var prompt_frame := Sprite2D.new()
	prompt_frame.name = "InteractPromptFrame"
	prompt_frame.texture = _tex("res://assets/ui/interact_hint.png")
	prompt_frame.position = Vector2(-136, -406)
	prompt_frame.scale = Vector2(0.72, 0.72)
	prompt_frame.visible = false
	root.add_child(prompt_frame)

	var camera := Camera2D.new()
	camera.name = "Camera"
	camera.position = Vector2(0, -220)
	camera.enabled = true
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 4.5
	camera.limit_left = 0
	camera.limit_top = -360
	camera.limit_right = 9600
	camera.limit_bottom = 760
	root.add_child(camera)

	var light := PointLight2D.new()
	light.name = "PlayerLight"
	light.texture = _tex("res://assets/sprites/effects/light_texture.png")
	light.texture_scale = 1.8
	light.energy = 0.18
	light.color = Color(1.0, 0.78, 0.48, 0.85)
	light.position = Vector2(0, -170)
	root.add_child(light)

	var sfx := AudioStreamPlayer.new()
	sfx.name = "SFXPlayer"
	sfx.volume_db = -6.0
	root.add_child(sfx)
	_save_scene(root, "res://scenes/player/player.tscn")

func _build_object_scenes() -> void:
	_build_collectible_scene()
	_build_altar_scene()
	_build_bell_rope_scene()
	_build_elder_scene()
	_build_tablet_scene()
	_build_fox_scene()

func _build_collectible_scene() -> void:
	var root := Area2D.new()
	root.name = "CollectibleItem"
	root.script = load("res://scenes/objects/collectible_item.gd")
	root.collision_layer = 2
	root.collision_mask = 0
	var visual := Node2D.new()
	visual.name = "Visual"
	root.add_child(visual)
	visual.add_child(_bottom_sprite("Sprite", "res://assets/sprites/objects/item_sugi_wood.png"))
	root.add_child(_rect_shape(Vector2(116, 116), Vector2(0, -64)))
	var light := PointLight2D.new()
	light.name = "Glow"
	light.texture = _tex("res://assets/sprites/effects/light_texture.png")
	light.texture_scale = 0.7
	light.energy = 0.10
	light.position = Vector2(0, -62)
	root.add_child(light)
	_save_scene(root, "res://scenes/objects/collectible_item.tscn")

func _build_altar_scene() -> void:
	var root := Area2D.new()
	root.name = "Altar"
	root.script = load("res://scenes/objects/altar.gd")
	root.collision_layer = 2
	root.collision_mask = 0
	root.add_child(_bottom_sprite("Sprite2D", "res://assets/sprites/objects/altar.png"))
	root.add_child(_rect_shape(Vector2(330, 210), Vector2(0, -116)))
	var glow := PointLight2D.new()
	glow.name = "Glow"
	glow.texture = _tex("res://assets/sprites/effects/warm_light.png")
	glow.texture_scale = 1.9
	glow.energy = 0.22
	glow.position = Vector2(0, -150)
	root.add_child(glow)
	root.add_child(_label("Label", "奉纳", Vector2(-140, -335), Vector2(280, 42), 24, Color(0.9, 0.78, 0.48), HORIZONTAL_ALIGNMENT_CENTER))
	_save_scene(root, "res://scenes/objects/altar.tscn")

func _build_bell_rope_scene() -> void:
	var root := Area2D.new()
	root.name = "BellRope"
	root.script = load("res://scenes/objects/bell_rope.gd")
	root.collision_layer = 2
	root.collision_mask = 0
	var visual := Node2D.new()
	visual.name = "Visual"
	root.add_child(visual)
	visual.add_child(_top_sprite("BellSprite", "res://assets/sprites/objects/bell_rope.png"))
	root.add_child(_rect_shape(Vector2(150, 360), Vector2(0, 226)))
	_save_scene(root, "res://scenes/objects/bell_rope.tscn")

func _build_elder_scene() -> void:
	var root := Area2D.new()
	root.name = "Elder"
	root.script = load("res://scenes/objects/npc_elder.gd")
	root.collision_layer = 2
	root.collision_mask = 0
	var visual := Node2D.new()
	visual.name = "Visual"
	root.add_child(visual)
	visual.add_child(_animated_bottom_sprite("Sprite", [
		{"name": "idle", "path": "res://assets/sprites/npcs/elder_idle.png", "frames": 4, "speed": 4.0, "loop": true},
	], Vector2i(256, 352)))
	root.add_child(_rect_shape(Vector2(110, 220), Vector2(0, -112)))
	_save_scene(root, "res://scenes/objects/npc_elder.tscn")

func _build_tablet_scene() -> void:
	var root := Area2D.new()
	root.name = "StoneTablet"
	root.script = load("res://scenes/objects/stone_tablet.gd")
	root.collision_layer = 2
	root.collision_mask = 0
	root.add_child(_bottom_sprite("Sprite2D", "res://assets/sprites/objects/stone_tablet.png"))
	root.add_child(_rect_shape(Vector2(176, 220), Vector2(0, -116)))
	_save_scene(root, "res://scenes/objects/stone_tablet.tscn")

func _build_fox_scene() -> void:
	var root := Node2D.new()
	root.name = "FoxSpirit"
	root.script = load("res://scenes/objects/fox_spirit.gd")
	root.z_index = 20
	var visual := Node2D.new()
	visual.name = "Visual"
	root.add_child(visual)
	visual.add_child(_animated_bottom_sprite("FoxSprite", [
		{"name": "appear", "path": "res://assets/sprites/npcs/fox_appear.png", "frames": 8, "speed": 8.0, "loop": false},
		{"name": "idle", "path": "res://assets/sprites/npcs/fox_idle.png", "frames": 6, "speed": 6.0, "loop": true},
		{"name": "walk", "path": "res://assets/sprites/npcs/fox_walk.png", "frames": 8, "speed": 9.0, "loop": true},
		{"name": "look_back", "path": "res://assets/sprites/npcs/fox_look_back.png", "frames": 5, "speed": 7.0, "loop": false},
		{"name": "depart", "path": "res://assets/sprites/npcs/fox_depart.png", "frames": 8, "speed": 8.0, "loop": false},
	], Vector2i(320, 224)))
	var tail_fx := _animated_fx_sprite("FoxfireTail", "res://assets/sprites/npcs/foxfire_unstable.png", Vector2i(128, 128), 8, 10.0)
	tail_fx.position = Vector2(106, -34)
	tail_fx.z_index = 3
	visual.add_child(tail_fx)

	var light := PointLight2D.new()
	light.name = "FoxLight"
	light.texture = _tex("res://assets/sprites/effects/warm_light.png")
	light.texture_scale = 1.6
	light.energy = 0.7
	light.color = Color(1.0, 0.70, 0.35)
	light.position = Vector2(34, -96)
	root.add_child(light)

	var shadow := Node2D.new()
	shadow.name = "Shadow"
	var sh_sprite := _bottom_sprite("ShadowSprite", "res://assets/sprites/npcs/foxfire_unstable.png")
	sh_sprite.scale = Vector2(1.9, 0.42)
	sh_sprite.modulate = Color(0.10, 0.04, 0.02, 0.40)
	shadow.add_child(sh_sprite)
	root.add_child(shadow)
	_save_scene(root, "res://scenes/objects/fox_spirit.tscn")

func _build_hud_scene() -> void:
	var root := CanvasLayer.new()
	root.name = "HUD"
	root.script = load("res://scenes/ui/hud.gd")
	root.layer = 50

	var area := _label("AreaLabel", "", Vector2(300, 34), Vector2(680, 46), 26, Color(0.92, 0.80, 0.56), HORIZONTAL_ALIGNMENT_CENTER)
	root.add_child(area)

	var panel := PanelContainer.new()
	panel.name = "OfferingPanel"
	panel.position = Vector2(980, 78)
	panel.size = Vector2(256, 384)
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.035, 0.028, 0.040, 0.82), Color(0.62, 0.48, 0.28, 0.78), 3))
	var tube_art := TextureRect.new()
	tube_art.name = "OfferingTubeTexture"
	tube_art.texture = _tex("res://assets/ui/offering_tube.png")
	tube_art.position = panel.position
	tube_art.size = panel.size
	tube_art.stretch_mode = TextureRect.STRETCH_SCALE
	root.add_child(tube_art)
	root.add_child(panel)

	var panel_vbox := VBoxContainer.new()
	panel_vbox.name = "PanelVBox"
	panel_vbox.add_theme_constant_override("separation", 12)
	panel.add_child(panel_vbox)
	var title := _label("Title", "御供筒", Vector2.ZERO, Vector2(210, 34), 22, Color(0.95, 0.80, 0.46), HORIZONTAL_ALIGNMENT_CENTER)
	panel_vbox.add_child(title)
	var offering_vbox := VBoxContainer.new()
	offering_vbox.name = "OfferingVBox"
	offering_vbox.add_theme_constant_override("separation", 10)
	panel_vbox.add_child(offering_vbox)
	_save_scene(root, "res://scenes/ui/hud.tscn")

func _build_choice_panel_scene() -> void:
	var root := CanvasLayer.new()
	root.name = "ChoicePanel"
	root.script = load("res://scenes/ui/choice_panel.gd")
	root.layer = 80

	var dim := ColorRect.new()
	dim.name = "BgDim"
	dim.color = Color(0, 0, 0, 0.58)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)

	var center := CenterContainer.new()
	center.name = "Center"
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.add_child(center)

	var panel := PanelContainer.new()
	panel.name = "Panel"
	panel.custom_minimum_size = Vector2(900, 310)
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.035, 0.024, 0.040, 0.97), Color(0.72, 0.52, 0.28, 0.95), 4))
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	vbox.add_theme_constant_override("separation", 24)
	panel.add_child(vbox)
	vbox.add_child(_label("TitleLabel", "选择", Vector2.ZERO, Vector2(820, 48), 30, Color(0.95, 0.82, 0.52), HORIZONTAL_ALIGNMENT_CENTER))
	var hbox := HBoxContainer.new()
	hbox.name = "HBox"
	hbox.add_theme_constant_override("separation", 28)
	vbox.add_child(hbox)
	hbox.add_child(_choice_button("ChoiceA"))
	hbox.add_child(_choice_button("ChoiceB"))
	_save_scene(root, "res://scenes/ui/choice_panel.tscn")

func _choice_button(name_value: String) -> Button:
	var button := Button.new()
	button.name = name_value
	button.custom_minimum_size = Vector2(386, 128)
	button.add_theme_font_size_override("font_size", 24)
	button.add_theme_stylebox_override("normal", _texture_style("res://assets/ui/choice_button.png", 20))
	button.add_theme_stylebox_override("hover", _texture_style("res://assets/ui/choice_button.png", 20))
	button.add_theme_stylebox_override("pressed", _texture_style("res://assets/ui/choice_button.png", 20))
	return button

func _build_main_menu_scene() -> void:
	var root := Control.new()
	root.name = "MainMenu"
	root.script = load("res://scenes/ui/main_menu.gd")
	root.set_anchors_preset(Control.PRESET_FULL_RECT)

	var bg := TextureRect.new()
	bg.name = "Background"
	bg.texture = _tex("res://assets/backgrounds/sky.png")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	root.add_child(bg)
	var wash := ColorRect.new()
	wash.name = "Wash"
	wash.color = Color(0.02, 0.01, 0.03, 0.62)
	wash.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(wash)

	var title := _label("TitleLabel", "送狐", Vector2(96, 132), Vector2(560, 94), 72, Color(1.0, 0.83, 0.48), HORIZONTAL_ALIGNMENT_LEFT)
	root.add_child(title)
	var subtitle := _label("SubtitleLabel", "OKURI KITSUNE", Vector2(100, 222), Vector2(560, 44), 26, Color(0.78, 0.64, 0.42), HORIZONTAL_ALIGNMENT_LEFT)
	root.add_child(subtitle)

	var vbox := VBoxContainer.new()
	vbox.name = "ButtonVBox"
	vbox.position = Vector2(100, 360)
	vbox.size = Vector2(340, 190)
	vbox.add_theme_constant_override("separation", 18)
	root.add_child(vbox)
	var start := _menu_button("StartBtn", "开始")
	var quit := _menu_button("QuitBtn", "退出")
	vbox.add_child(start)
	vbox.add_child(quit)
	_save_scene(root, "res://scenes/ui/main_menu.tscn")

func _menu_button(name_value: String, text_value: String) -> Button:
	var button := Button.new()
	button.name = name_value
	button.text = text_value
	button.custom_minimum_size = Vector2(300, 72)
	button.add_theme_font_size_override("font_size", 28)
	button.add_theme_stylebox_override("normal", _panel_style(Color(0.08, 0.055, 0.060, 0.96), Color(0.64, 0.45, 0.24, 0.86), 3))
	button.add_theme_stylebox_override("hover", _panel_style(Color(0.15, 0.085, 0.065, 0.98), Color(0.90, 0.65, 0.35, 0.96), 4))
	button.add_theme_stylebox_override("pressed", _panel_style(Color(0.06, 0.040, 0.040, 1.0), Color(0.95, 0.76, 0.46, 1.0), 4))
	return button

func _build_cutscene(path: String, script_path: String, color: Color) -> void:
	var root := Control.new()
	root.name = path.get_file().get_basename().capitalize()
	root.script = load(script_path)
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.name = "Background"
	bg.color = color
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)
	_save_scene(root, path)

func _level_root(name_value: String, script_path: String, width: int, bg_paths: Array[String], bg_tints: Array[Color]) -> Node2D:
	var root := Node2D.new()
	root.name = name_value
	root.script = load(script_path)
	root.set("level_width", width)

	var zones := Node2D.new()
	zones.name = "BackgroundZones"
	root.add_child(zones)
	for i in range(3):
		var marker := Marker2D.new()
		marker.name = "Zone%02d" % (i + 1)
		marker.position = Vector2(i * (width / 3.0), 0)
		marker.set_meta("width", width / 3.0)
		zones.add_child(marker)

	var wash := ColorRect.new()
	wash.name = "BackdropWash"
	wash.color = bg_tints[0]
	wash.size = Vector2(width, 720)
	wash.z_index = -100
	root.add_child(wash)

	_add_background_layer(root, "Background_Far", bg_paths[0], -80, 0.78)
	_add_background_layer(root, "Background_Mid", bg_paths[1], -70, 0.90)
	_add_background_layer(root, "Background_Near", bg_paths[2], -60, 0.98)

	for layer_name in ["Terrain", "OneWayPlatforms", "PropsBack", "Items", "Narrative", "Actors", "Mechanisms", "PropsFront", "Lighting", "FX"]:
		var n := Node2D.new()
		n.name = layer_name
		root.add_child(n)

	var hud: Node = load("res://scenes/ui/hud.tscn").instantiate()
	hud.name = "HUD"
	root.add_child(hud)

	var audio := Node.new()
	audio.name = "Audio"
	for n in ["BGM", "Ambience", "SFX"]:
		var p := AudioStreamPlayer.new()
		p.name = n
		p.volume_db = -6.0 if n != "SFX" else -3.0
		audio.add_child(p)
	root.add_child(audio)
	return root

func _add_background_layer(root: Node2D, name_value: String, texture_path: String, z: int, parallax_factor: float) -> void:
	var sprite := Sprite2D.new()
	sprite.name = name_value
	sprite.texture = _tex(texture_path)
	sprite.centered = false
	sprite.position = Vector2.ZERO
	sprite.z_index = z
	sprite.set_meta("parallax_factor", parallax_factor)
	root.add_child(sprite)

func _terrain_layer(name_value: String, tileset_path: String) -> TileMapLayer:
	var tm := TileMapLayer.new()
	tm.name = name_value
	tm.tile_set = load(tileset_path)
	return tm

func _fill_ground(tm: TileMapLayer, start_tile: int, end_tile: int, top_row: int = 4) -> void:
	for x in range(start_tile, end_tile):
		tm.set_cell(Vector2i(x, top_row), 0, Vector2i(0, 0), 0)
		for y in range(top_row + 1, 8):
			tm.set_cell(Vector2i(x, y), 0, Vector2i(0, 1), 0)

func _fill_oneway(tm: TileMapLayer, start_tile: int, end_tile: int, row: int) -> void:
	for x in range(start_tile, end_tile):
		tm.set_cell(Vector2i(x, row), 0, Vector2i(0, 2), 0)

func _add_player(root: Node2D, pos: Vector2, width: int) -> Node:
	var player: Node = load("res://scenes/player/player.tscn").instantiate()
	player.name = "Player"
	player.position = pos
	var actors := root.get_node("Actors")
	actors.add_child(player)
	return player

func _add_item(root: Node2D, item_id: String, texture_path: String, pos: Vector2, name_suffix := "") -> Node:
	var item: Node = load("res://scenes/objects/collectible_item.tscn").instantiate()
	item.name = _unique_child_name(root.get_node("Items"), "Item_" + item_id + ("_" + name_suffix if name_suffix != "" else ""))
	item.position = pos
	item.item_id = item_id
	item.item_texture = _tex(texture_path)
	root.get_node("Items").add_child(item)
	return item

func _add_named_item(root: Node2D, parent_path: String, name_value: String, item_id: String, texture_path: String, pos: Vector2) -> Node:
	var parent := root.get_node(parent_path)
	var item: Node = load("res://scenes/objects/collectible_item.tscn").instantiate()
	item.name = _unique_child_name(parent, name_value)
	item.position = pos
	item.item_id = item_id
	item.item_texture = _tex(texture_path)
	parent.add_child(item)
	return item

func _add_white_fur_chest(root: Node2D, pos: Vector2) -> Node:
	var chest := Area2D.new()
	chest.name = _unique_child_name(root.get_node("Mechanisms"), "WhiteFurChest")
	chest.position = pos
	chest.script = load("res://scenes/objects/white_fur_chest.gd")
	chest.set("item_id", "white_fur")
	chest.set("item_texture", _tex("res://assets/sprites/objects/item_white_fur.png"))
	chest.set("closed_texture", _tex("res://assets/sprites/objects/old_wooden_chest/old_wooden_chest_closed.png"))
	chest.set("open_texture", _tex("res://assets/sprites/objects/old_wooden_chest/old_wooden_chest_open.png"))
	chest.set("interact_name", "打开箱子")
	chest.set("take_dialog", "你打开旧箱，白毛被干燥的纸包着，没有沾到泥。")

	var visual := Node2D.new()
	visual.name = "Visual"
	visual.scale = Vector2(0.58, 0.58)
	chest.add_child(visual)

	var sprite := Sprite2D.new()
	sprite.name = "ChestSprite"
	sprite.texture = _tex("res://assets/sprites/objects/old_wooden_chest/old_wooden_chest_closed.png")
	sprite.centered = false
	sprite.offset = Vector2(-192, -358)
	visual.add_child(sprite)

	chest.add_child(_rect_shape(Vector2(210, 150), Vector2(0, -78)))
	root.get_node("Mechanisms").add_child(chest)
	return chest

func _add_sugi_tree_source(root: Node2D, pos: Vector2, name_suffix := "", harvest_dialog := "你从杉木根旁砍下一段湿冷的枝木。", max_harvest_count := 1) -> Node:
	var source := Area2D.new()
	source.name = _unique_child_name(root.get_node("Mechanisms"), "SugiTreeSource" + ("_" + name_suffix if name_suffix != "" else ""))
	source.position = pos
	source.script = load("res://scenes/objects/harvest_source.gd")
	source.set("item_id", "sugi_wood")
	source.set("item_texture", _tex("res://assets/sprites/objects/item_sugi_wood.png"))
	source.set("interact_name", "砍杉木")
	source.set("harvest_dialog", harvest_dialog)
	source.set("max_harvest_count", max_harvest_count)

	var visual := Node2D.new()
	visual.name = "Visual"
	source.add_child(visual)

	var tree := Sprite2D.new()
	tree.name = "TreeBase"
	tree.position = Vector2(-190.97414, -434.66663)
	tree.scale = Vector2(0.6164405, 0.8697918)
	tree.texture = _tex("res://assets/sprites/objects/large_tree/large_tree.png")
	tree.centered = false
	tree.offset = Vector2(-64, -128)
	tree.region_rect = Rect2(0, 0, 1329, 1183)
	tree.region_filter_clip_enabled = true
	visual.add_child(tree)

	source.add_child(_rect_shape(Vector2(210, 280), Vector2(-12, -115)))
	root.get_node("Mechanisms").add_child(source)
	return source

func _add_grass_harvest_source(root: Node2D, name_value: String, item_id: String, texture_path: String, pos: Vector2, interact_name: String, harvest_dialog: String, tileset_path := "res://assets/tilesets/forest_tileset.png") -> Node:
	var source := Area2D.new()
	source.name = _unique_child_name(root.get_node("Mechanisms"), name_value)
	source.position = pos
	source.script = load("res://scenes/objects/harvest_source.gd")
	source.set("item_id", item_id)
	source.set("item_texture", _tex(texture_path))
	source.set("interact_name", interact_name)
	source.set("harvest_dialog", harvest_dialog)

	var visual := Node2D.new()
	visual.name = "Visual"
	source.add_child(visual)

	var grass := Sprite2D.new()
	grass.name = "GrassPile"
	grass.position = Vector2(2, -37)
	grass.scale = Vector2(1.6, 1.6)
	grass.texture = _tex(tileset_path)
	grass.centered = false
	grass.offset = Vector2(-64, -128)
	grass.region_enabled = true
	grass.region_rect = Rect2(0, 512, 128, 128)
	visual.add_child(grass)

	source.add_child(_rect_shape(Vector2(160, 120), Vector2(-6, -136)))
	root.get_node("Mechanisms").add_child(source)
	return source

func _unique_child_name(parent: Node, preferred: String) -> String:
	if parent.get_node_or_null(preferred) == null:
		return preferred
	var index := 2
	while parent.get_node_or_null("%s_%d" % [preferred, index]) != null:
		index += 1
	return "%s_%d" % [preferred, index]

func _add_tablet(root: Node2D, name_value: String, pos: Vector2, text_value: String, texture_path := "res://assets/sprites/objects/stone_tablet.png", speaker := "札记") -> Node:
	var tablet := Area2D.new()
	tablet.name = name_value
	tablet.position = pos
	tablet.script = load("res://scenes/objects/stone_tablet.gd")
	tablet.set("tablet_text", text_value)
	tablet.set("speaker_name", speaker)
	tablet.add_child(_bottom_sprite("Sprite2D", texture_path))
	tablet.add_child(_rect_shape(Vector2(176, 220), Vector2(0, -116)))
	root.get_node("Narrative").add_child(tablet)
	return tablet

func _add_altar(root: Node2D, pos: Vector2, level: int) -> Node:
	var altar: Node = load("res://scenes/objects/altar.tscn").instantiate()
	altar.name = "Altar"
	altar.position = pos
	altar.level = level
	root.get_node("Narrative").add_child(altar)
	return altar

func _add_lantern(root: Node2D, pos: Vector2, front := false, id := "") -> void:
	var readable_id := id if id != "" else ("%d_%d" % [int(pos.x), int(pos.y)])
	var sprite := _bottom_sprite("StoneLantern", "res://assets/sprites/objects/stone_lantern.png")
	sprite.name = _unique_child_name(root.get_node("PropsFront" if front else "PropsBack"), "StoneLantern_" + readable_id)
	sprite.position = pos
	var parent := root.get_node("PropsFront" if front else "PropsBack")
	parent.add_child(sprite)
	var light := PointLight2D.new()
	light.name = _unique_child_name(root.get_node("Lighting"), "LanternLight_" + readable_id)
	light.texture = _tex("res://assets/sprites/effects/warm_light.png")
	light.texture_scale = 1.1
	light.energy = 0.26
	light.position = pos + Vector2(0, -150)
	root.get_node("Lighting").add_child(light)
	_add_fx(root, "LanternFlame_" + readable_id, "res://assets/sprites/effects/lantern_flame.png", pos + Vector2(0, -150), 8, 9.0)

func _add_blue_oil_lantern(root: Node2D, pos: Vector2, id := "") -> void:
	var readable_id := id if id != "" else ("%d_%d" % [int(pos.x), int(pos.y)])
	var sprite := _bottom_sprite("StoneLantern", "res://assets/sprites/objects/stone_lantern.png")
	sprite.name = _unique_child_name(root.get_node("PropsBack"), "StoneLantern_" + readable_id)
	sprite.position = pos
	root.get_node("PropsBack").add_child(sprite)

	var light := PointLight2D.new()
	light.name = _unique_child_name(root.get_node("Lighting"), "BlueLanternLight_" + readable_id)
	light.texture = _tex("res://assets/sprites/effects/cold_light.png")
	light.texture_scale = 1.18
	light.energy = 0.34
	light.color = Color(0.42, 0.72, 1.0, 0.92)
	light.position = pos + Vector2(0, -150)
	root.get_node("Lighting").add_child(light)

	_add_fx(root, "BlueFlame_" + readable_id, "res://assets/sprites/effects/blue_flame.png", pos + Vector2(0, -150), 8, 8.0)

	var marker := Marker2D.new()
	marker.name = "OilMarker_" + readable_id
	marker.position = pos
	root.get_node("Mechanisms").add_child(marker)

func _add_ladder_option(root: Node2D, base_pos: Vector2, top_pos: Vector2) -> void:
	var marker := Marker2D.new()
	marker.name = "LadderMarker"
	marker.position = base_pos
	root.get_node("Mechanisms").add_child(marker)

	var delta := top_pos - base_pos
	var length := delta.length()
	var angle := delta.angle()
	var ladder := StaticBody2D.new()
	ladder.name = "LadderGrass"
	ladder.position = base_pos + delta * 0.5
	ladder.visible = false
	ladder.collision_layer = 0
	ladder.collision_mask = 0

	var sprite := Sprite2D.new()
	sprite.name = "LadderSprite"
	sprite.texture = _tex("res://assets/sprites/objects/bridge_plank.png")
	sprite.centered = true
	sprite.rotation = angle
	sprite.scale = Vector2(length / 1152.0, 0.52)
	sprite.modulate = Color(0.82, 0.74, 0.60, 0.95)
	ladder.add_child(sprite)

	var collision := _rect_shape(Vector2(length, 42), Vector2.ZERO, "LadderCollision")
	collision.rotation = angle
	collision.disabled = true
	ladder.add_child(collision)
	root.get_node("Mechanisms").add_child(ladder)

func _add_torii(root: Node2D, pos: Vector2, large := true, id := "") -> void:
	var readable_id := id if id != "" else ("%d_%d" % [int(pos.x), int(pos.y)])
	var sprite := _bottom_sprite("Torii", "res://assets/sprites/objects/torii.png" if large else "res://assets/sprites/objects/torii_small.png")
	sprite.name = _unique_child_name(root.get_node("PropsBack"), ("ToriiLarge_" if large else "ToriiSmall_") + readable_id)
	sprite.position = pos
	root.get_node("PropsBack").add_child(sprite)

func _add_prop_sprite(root: Node2D, name_value: String, texture_path: String, pos: Vector2, front := false) -> void:
	var parent := root.get_node("PropsFront" if front else "PropsBack")
	var sprite := _bottom_sprite(_unique_child_name(parent, name_value), texture_path)
	sprite.position = pos
	parent.add_child(sprite)

func _add_tileset_region_sprite(root: Node2D, name_value: String, atlas_coord: Vector2i, pos: Vector2, scale := Vector2.ONE, color := Color(1, 1, 1, 1), parent_path := "PropsBack") -> void:
	var parent := root.get_node(parent_path)
	var sprite := Sprite2D.new()
	sprite.name = _unique_child_name(parent, name_value)
	sprite.texture = _tex("res://assets/tilesets/shrine_tileset.png")
	sprite.centered = false
	sprite.region_enabled = true
	sprite.region_rect = Rect2(atlas_coord.x * TILE, atlas_coord.y * TILE, TILE, TILE)
	sprite.offset = Vector2(-TILE * 0.5, -TILE)
	sprite.position = pos
	sprite.scale = scale
	sprite.modulate = color
	parent.add_child(sprite)

func _add_room_frame(root: Node2D, room_id: String, start_x: int, end_x: int, tint: Color) -> void:
	var y_top := 260
	for x in range(start_x + 64, end_x, TILE):
		_add_tileset_region_sprite(root, "RoomBeam_" + room_id, Vector2i(1, 3), Vector2(x, y_top), Vector2(1.0, 0.58), tint)
	for x in [start_x, end_x]:
		_add_tileset_region_sprite(root, "RoomPillar_" + room_id, Vector2i(2, 3), Vector2(x, 512), Vector2(0.72, 2.05), tint)
	for x in range(start_x + 180, end_x - 120, 420):
		_add_tileset_region_sprite(root, "RoomFloorMark_" + room_id, Vector2i(0, 5), Vector2(x, 506), Vector2(1.15, 0.45), Color(tint.r, tint.g, tint.b, 0.46), "PropsFront")

func _add_fx(root: Node2D, name_value: String, texture_path: String, pos: Vector2, frames_count := 8, speed := 8.0) -> AnimatedSprite2D:
	var parent := root.get_node("FX")
	var fx := _animated_fx_sprite(_unique_child_name(parent, name_value), texture_path, Vector2i(128, 128), frames_count, speed)
	fx.position = pos
	parent.add_child(fx)
	return fx

func _add_bridge(root: Node2D, name_value: String, texture_path: String, pos: Vector2, size: Vector2) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.name = name_value
	body.position = pos
	body.collision_layer = 4
	body.collision_mask = 0
	body.add_child(_top_sprite(name_value + "Sprite", texture_path))
	body.add_child(_rect_shape(size, Vector2(0, size.y * 0.5), name_value + "Collision"))
	root.get_node("Mechanisms").add_child(body)
	return body

func _add_canvas_modulate(root: Node2D, color: Color) -> void:
	var modulate := CanvasModulate.new()
	modulate.name = "CanvasModulate"
	modulate.color = color
	root.get_node("Lighting").add_child(modulate)

func _build_level_1() -> void:
	var width := 9600
	var root := _level_root(
		"Level1",
		"res://scenes/levels/level_1.gd",
		width,
		["res://assets/backgrounds/level1_far.png", "res://assets/backgrounds/level1_mid.png", "res://assets/backgrounds/level1_near.png"],
		[Color(0.015, 0.020, 0.035, 1.0)]
	)
	var terrain := _terrain_layer("ForestTerrain", "res://assets/tilesets/forest_tileset.tres")
	root.get_node("Terrain").add_child(terrain)
	_fill_ground(terrain, 0, 75)
	var one := _terrain_layer("ForestOneWay", "res://assets/tilesets/forest_tileset.tres")
	root.get_node("OneWayPlatforms").add_child(one)
	_fill_oneway(one, 18, 25, 3)
	_fill_oneway(one, 39, 45, 3)

	_add_player(root, Vector2(160, 512), width)
	var elder: Node = load("res://scenes/objects/npc_elder.tscn").instantiate()
	elder.name = "Elder"
	elder.position = Vector2(420, 512)
	root.get_node("Narrative").add_child(elder)
	_add_tablet(root, "Tablet_Village", Vector2(760, 512), "参道旧训：先学会拾起供物，再学会把它们按次序放下。")
	_add_sugi_tree_source(root, Vector2(1180, 512))
	_add_tablet(root, "Tablet_Torii", Vector2(2480, 384), "山中有狐，不可直呼其名。若狐回首，莫再唤它。")
	_add_white_fur_chest(root, Vector2(3260, 320))
	_add_grass_harvest_source(root, "MugwortGrassSource", "mugwort", "res://assets/sprites/objects/item_mugwort.png", Vector2(5400, 512), "采蓬草", "你拨开湿草，从草堆里取出一束气味清烈的蓬草。")
	_add_tablet(root, "Tablet_Order", Vector2(6100, 512), "祭坛从下至上读取供物。后取得的供物会压在更上层。")
	_add_altar(root, Vector2(8840, 512), 1)
	var fox_marker := Marker2D.new()
	fox_marker.name = "FoxSpawnMarker"
	fox_marker.position = Vector2(8540, 420)
	root.get_node("Narrative").add_child(fox_marker)
	for data in [
		["VillageShrine", Vector2(650, 512)],
		["ForestBend", Vector2(4200, 512)],
		["AltarApproach", Vector2(7900, 512)],
	]:
		_add_lantern(root, data[1], false, data[0])
	_add_torii(root, Vector2(520, 512), false, "VillageGate")
	_add_torii(root, Vector2(3920, 512), true, "OldTorii")
	_add_torii(root, Vector2(9040, 512), true, "AltarGate")
	_add_prop_sprite(root, "TopOfferingLongTable", "res://assets/sprites/objects/long_table/long_table.png", Vector2(5730, 556), true)
	_add_named_item(root, "PropsFront", "TopOfferingBellFiberPreview", "bell_fiber", "res://assets/sprites/objects/item_bell_fiber.png", Vector2(5560, 455))
	_add_named_item(root, "PropsFront", "TopOfferingFoxStonePreview", "fox_stone", "res://assets/sprites/objects/item_fox_stone.png", Vector2(5890, 455))
	_add_fx(root, "FoxfireHint_OldTorii", "res://assets/sprites/effects/fox_fire.png", Vector2(4040, 392), 8, 8.0)
	_add_canvas_modulate(root, Color(0.78, 0.82, 0.95, 1.0))
	_save_scene(root, "res://scenes/levels/level_1.tscn")

func _build_level_2() -> void:
	var width := 12800
	var root := _level_root(
		"Level2",
		"res://scenes/levels/level_2.gd",
		width,
		["res://assets/backgrounds/level2_far.png", "res://assets/backgrounds/level2_mid.png", "res://assets/backgrounds/level2_near.png"],
		[Color(0.018, 0.018, 0.032, 1.0)]
	)
	var terrain := _terrain_layer("ApproachTerrain", "res://assets/tilesets/approach_tileset.tres")
	root.get_node("Terrain").add_child(terrain)
	for seg in [[0, 14], [22, 46], [50, 58], [66, 100]]:
		_fill_ground(terrain, seg[0], seg[1])
	var one := _terrain_layer("ApproachOneWay", "res://assets/tilesets/approach_tileset.tres")
	root.get_node("OneWayPlatforms").add_child(one)
	_fill_oneway(one, 32, 39, 3)
	_fill_oneway(one, 37, 45, 2)
	_fill_oneway(one, 58, 64, 3)
	_fill_oneway(one, 76, 83, 3)
	_fill_oneway(one, 88, 94, 3)

	_add_player(root, Vector2(160, 512), width)
	_add_sugi_tree_source(root, Vector2(900, 512), "bridge", "你从断崖前的杉木根旁砍下一段枝木。", 5)
	_add_tablet(root, "Tablet_RitualClue", Vector2(3060, 512), "残损告示：□□ / 白毛 / □□\n上下两格被泥水糊住，只剩中段还白。", "res://assets/sprites/objects/archive_note.png", "残损木牌")
	_add_white_fur_chest(root, Vector2(3380, 512))
	_add_sugi_tree_source(root, Vector2(3920, 512), "altar", "你从箱旁的老杉上取下一段湿冷枝木。", 5)
	_add_grass_harvest_source(root, "MugwortGrassSource", "mugwort", "res://assets/sprites/objects/item_mugwort.png", Vector2(4820, 232), "采蓬草", "你绕到杉木后方的高处，采下一束被雾打湿的蓬草。", "res://assets/tilesets/approach_tileset.png")
	_add_tablet(root, "Tablet_Cliff", Vector2(1260, 512), "断处需要承托之物。供物也会成为道路的一部分。")
	_add_tablet(root, "Tablet_Bell", Vector2(5940, 512), "铃声落下时，石狐会转向。路只在回声还在时显形。", "res://assets/sprites/objects/stone_tablet.png", "旧铃札")
	_add_altar(root, Vector2(11840, 512), 2)

	var bell: Node = load("res://scenes/objects/bell_rope.tscn").instantiate()
	bell.name = "BellRope"
	bell.position = Vector2(6400, 128)
	root.get_node("Narrative").add_child(bell)

	var marker := Marker2D.new()
	marker.name = "BridgeMarker"
	marker.position = Vector2(1660, 512)
	root.get_node("Mechanisms").add_child(marker)
	var marker_second := Marker2D.new()
	marker_second.name = "BridgeMarkerSecond"
	marker_second.position = Vector2(5760, 512)
	root.get_node("Mechanisms").add_child(marker_second)
	var marker_third := Marker2D.new()
	marker_third.name = "BridgeMarkerThird"
	marker_third.position = Vector2(7280, 512)
	root.get_node("Mechanisms").add_child(marker_third)
	_add_ladder_option(root, Vector2(4240, 512), Vector2(4820, 256))
	_add_bridge(root, "Bridge", "res://assets/sprites/objects/bridge_plank.png", Vector2(2300, 512), Vector2(1152, 64))
	_add_bridge(root, "BridgeSecond", "res://assets/sprites/objects/bridge_plank.png", Vector2(6144, 512), Vector2(640, 64))
	_add_bridge(root, "BridgeThird", "res://assets/sprites/objects/bridge_plank.png", Vector2(7936, 512), Vector2(1152, 64))
	_add_bridge(root, "HiddenPlatform", "res://assets/sprites/objects/hidden_platform.png", Vector2(7240, 352), Vector2(1024, 64))
	for data in [
		["CliffStart", Vector2(430, 512)],
		["BridgeAfter", Vector2(3000, 512)],
		["TreeShadow", Vector2(4300, 512)],
		["SecondAltar", Vector2(11280, 512)],
	]:
		_add_lantern(root, data[1], false, data[0])
	_add_blue_oil_lantern(root, Vector2(9480, 512), "HiddenRoute")
	_add_torii(root, Vector2(11100, 512), true, "SecondAltarGate")
	_add_prop_sprite(root, "TopOfferingLampOilPreview", "res://assets/sprites/objects/item_lamp_oil.png", Vector2(11600, 512), true)
	_add_canvas_modulate(root, Color(0.74, 0.78, 0.90, 1.0))
	_save_scene(root, "res://scenes/levels/level_2.tscn")

func _build_level_3() -> void:
	var width := 11200
	var root := _level_root(
		"Level3",
		"res://scenes/levels/level_3.gd",
		width,
		["res://assets/backgrounds/level3_far.png", "res://assets/backgrounds/level3_mid.png", "res://assets/backgrounds/level3_near.png"],
		[Color(0.018, 0.014, 0.024, 1.0)]
	)
	var terrain := _terrain_layer("ShrineTerrain", "res://assets/tilesets/shrine_tileset.tres")
	root.get_node("Terrain").add_child(terrain)
	_fill_ground(terrain, 0, 88)
	var one := _terrain_layer("ShrineOneWay", "res://assets/tilesets/shrine_tileset.tres")
	root.get_node("OneWayPlatforms").add_child(one)
	_fill_oneway(one, 28, 35, 3)
	_fill_oneway(one, 43, 51, 3)
	_fill_oneway(one, 71, 84, 3)

	_add_player(root, Vector2(160, 512), width)
	for room in [
		["MainCommunity", 640, 1960, Color(0.78, 0.72, 0.70, 0.74)],
		["NameCorridor", 1960, 3520, Color(0.66, 0.68, 0.80, 0.70)],
		["DressingRoom", 3520, 5200, Color(0.72, 0.66, 0.74, 0.70)],
		["ArchiveLoft", 5200, 7040, Color(0.60, 0.70, 0.86, 0.68)],
		["InnerArchive", 7040, 8880, Color(0.70, 0.64, 0.76, 0.70)],
		["StoneSteps", 8880, 10960, Color(0.84, 0.74, 0.60, 0.76)],
	]:
		_add_room_frame(root, room[0], room[1], room[2], room[3])

	_add_torii(root, Vector2(700, 512), false, "OuterGate")
	_add_torii(root, Vector2(1980, 512), false, "CommunityThreshold")
	_add_torii(root, Vector2(8980, 512), true, "StoneStepsGate")
	_add_prop_sprite(root, "DressingRoomLongTable", "res://assets/sprites/objects/long_table/long_table.png", Vector2(4290, 548), true)
	_add_prop_sprite(root, "InnerArchiveTable", "res://assets/sprites/objects/long_table/long_table.png", Vector2(7640, 548), true)
	_add_archive(root, 1, Vector2(1320, 512))
	_add_archive(root, 2, Vector2(2780, 512))
	_add_archive(root, 3, Vector2(4240, 512))
	_add_archive(root, 4, Vector2(5980, 384))
	_add_archive(root, 5, Vector2(7820, 512))
	var plaque := _bottom_sprite("Plaque", "res://assets/sprites/objects/plaque.png")
	plaque.position = Vector2(9820, 310)
	root.get_node("Narrative").add_child(plaque)
	var marker := Marker2D.new()
	marker.name = "PlaqueMarker"
	marker.position = Vector2(9820, 384)
	root.get_node("Narrative").add_child(marker)
	var fox_marker := Marker2D.new()
	fox_marker.name = "FoxSpawnMarker"
	fox_marker.position = Vector2(10180, 420)
	root.get_node("Narrative").add_child(fox_marker)
	for data in [
		["UnusedCommunity", Vector2(960, 512)],
		["NameCorridor", Vector2(2360, 512)],
		["DressingRoom", Vector2(3820, 512)],
		["ArchiveLoft", Vector2(5580, 384)],
		["InnerHall", Vector2(8360, 512)],
		["LongLampLeft", Vector2(9340, 512)],
		["LongLampCenter", Vector2(9860, 512)],
		["LongLampRight", Vector2(10420, 512)],
	]:
		_add_lantern(root, data[1], false, data[0])
	_add_fx(root, "Foxfire_OldWood", "res://assets/sprites/effects/fox_fire.png", Vector2(1390, 322), 8, 7.0)
	_add_fx(root, "Foxfire_PlaqueReveal", "res://assets/sprites/effects/fox_fire.png", Vector2(9910, 248), 8, 7.0)
	_add_canvas_modulate(root, Color(0.70, 0.72, 0.86, 1.0))
	_save_scene(root, "res://scenes/levels/level_3.tscn")

func _add_archive(root: Node2D, index: int, pos: Vector2) -> void:
	var trigger := Area2D.new()
	trigger.name = "ArchiveTrigger%d" % index
	trigger.position = pos
	trigger.script = load("res://scenes/objects/info_clue.gd")
	trigger.set("clue_index", index - 1)
	var interact_names := {
		1: "照看旧木额",
		2: "查看回廊牌",
		3: "查看衣箱残签",
		4: "查看装束札",
		5: "查看内殿档案",
	}
	trigger.set("interact_name", interact_names.get(index, "查看线索"))
	trigger.collision_layer = 2
	trigger.collision_mask = 0
	trigger.monitoring = true
	trigger.add_child(_rect_shape(Vector2(260, 250), Vector2(0, -126), "ArchiveDetectShape"))
	var texture_path := "res://assets/sprites/objects/archive_note.png"
	if index == 1:
		texture_path = "res://assets/sprites/objects/plaque.png"
	elif index == 4:
		texture_path = "res://assets/sprites/objects/stone_tablet.png"
	var visual := _bottom_sprite("ArchiveSprite", texture_path)
	if index == 1:
		visual.scale = Vector2(0.72, 0.72)
	elif index == 4:
		visual.scale = Vector2(0.84, 0.84)
	trigger.add_child(visual)
	root.get_node("Narrative").add_child(trigger)
