"""
将所有 GDScript 的 Polygon2D 程序化绘制替换为加载真实精灵素材。
保留碰撞、交互、游戏逻辑不变，仅替换 _build_visual() 或等效视觉构建函数。
"""
import os, re

ROOT = os.path.dirname(os.path.abspath(__file__))

def write(path, content):
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"  ✓ {os.path.relpath(path, ROOT)}")

# ═══════════════════════════════════════════════════════
# 1. player.gd — AnimatedSprite2D
# ═══════════════════════════════════════════════════════
def migrate_player():
    path = os.path.join(ROOT, "scenes", "player", "player.gd")
    with open(path, 'r', encoding='utf-8') as f:
        src = f.read()

    # Replace _build_visual() method
    old_visual = r'func _build_visual\(\) -> void:.*?(?=\nfunc )'
    new_visual = """func _build_visual() -> void:
\tvisual = Node2D.new()
\tvisual.name = "Visual"
\tadd_child(visual)

\tvar sprite := AnimatedSprite2D.new()
\tsprite.name = "Sprite"
\tsprite.position = Vector2(0, -6)

\t# 构建 SpriteFrames
\tvar frames := SpriteFrames.new()

\t# idle 动画 (6帧, 32x48)
\tframes.add_animation("idle")
\tframes.set_animation_speed("idle", 8.0)
\tframes.set_animation_loop("idle", true)
\tvar idle_tex := preload("res://assets/sprites/player/miko_idle.png")
\tfor i in range(6):
\t\tvar atlas := AtlasTexture.new()
\t\tatlas.atlas = idle_tex
\t\tatlas.region = Rect2(i * 32, 0, 32, 48)
\t\tframes.add_frame("idle", atlas)

\t# run 动画 (8帧, 32x48)
\tframes.add_animation("run")
\tframes.set_animation_speed("run", 10.0)
\tframes.set_animation_loop("run", true)
\tvar run_tex := preload("res://assets/sprites/player/miko_run.png")
\tfor i in range(8):
\t\tvar atlas := AtlasTexture.new()
\t\tatlas.atlas = run_tex
\t\tatlas.region = Rect2(i * 32, 0, 32, 48)
\t\tframes.add_frame("run", atlas)

\t# jump 动画 (3帧)
\tframes.add_animation("jump")
\tframes.set_animation_speed("jump", 6.0)
\tframes.set_animation_loop("jump", false)
\tvar jump_tex := preload("res://assets/sprites/player/miko_jump.png")
\tfor i in range(3):
\t\tvar atlas := AtlasTexture.new()
\t\tatlas.atlas = jump_tex
\t\tatlas.region = Rect2(i * 32, 0, 32, 48)
\t\tframes.add_frame("jump", atlas)

\t# fall 动画 (2帧)
\tframes.add_animation("fall")
\tframes.set_animation_speed("fall", 6.0)
\tframes.set_animation_loop("fall", true)
\tvar fall_tex := preload("res://assets/sprites/player/miko_fall.png")
\tfor i in range(2):
\t\tvar atlas := AtlasTexture.new()
\t\tatlas.atlas = fall_tex
\t\tatlas.region = Rect2(i * 32, 0, 32, 48)
\t\tframes.add_frame("fall", atlas)

\t# interact 动画 (4帧)
\tframes.add_animation("interact")
\tframes.set_animation_speed("interact", 6.0)
\tframes.set_animation_loop("interact", false)
\tvar interact_tex := preload("res://assets/sprites/player/miko_interact.png")
\tfor i in range(4):
\t\tvar atlas := AtlasTexture.new()
\t\tatlas.atlas = interact_tex
\t\tatlas.region = Rect2(i * 32, 0, 32, 48)
\t\tframes.add_frame("interact", atlas)

\t# 删除默认动画
\tif frames.has_animation("default"):
\t\tframes.remove_animation("default")

\tsprite.sprite_frames = frames
\tsprite.play("idle")
\tvisual.add_child(sprite)

"""

    src = re.sub(old_visual, new_visual, src, flags=re.DOTALL)

    # Also remove _circle_points helper if it exists
    src = re.sub(r'\nfunc _circle_points\(.*?\n(?=func |$)', '\n', src, flags=re.DOTALL)

    # Add animation state switching in _physics_process
    # Find the facing/flip logic and add animation calls
    if '_update_animation()' not in src:
        src = src.replace(
            '\twas_on_floor = is_on_floor()\n\tmove_and_slide()',
            '\twas_on_floor = is_on_floor()\n\tmove_and_slide()\n\t_update_animation()'
        )
        # Add the _update_animation function
        src += """
func _update_animation() -> void:
\tvar sprite: AnimatedSprite2D = visual.get_node_or_null("Sprite") if visual else null
\tif not sprite:
\t\treturn
\tif not is_on_floor():
\t\tif velocity.y < 0:
\t\t\tif sprite.animation != "jump":
\t\t\t\tsprite.play("jump")
\t\telse:
\t\t\tif sprite.animation != "fall":
\t\t\t\tsprite.play("fall")
\telif abs(velocity.x) > 5:
\t\tif sprite.animation != "run":
\t\t\tsprite.play("run")
\telse:
\t\tif sprite.animation != "idle":
\t\t\tsprite.play("idle")
"""

    # Simplify _create_light_texture if it uses procedural generation - replace with preloaded
    if '_create_light_texture' in src:
        old_light = r'func _create_light_texture\(\).*?return tex\n'
        new_light = """func _create_light_texture() -> Texture2D:
\treturn preload("res://assets/sprites/effects/light_texture.png")
"""
        src = re.sub(old_light, new_light, src, flags=re.DOTALL)

    write(path, src)


# ═══════════════════════════════════════════════════════
# 2. collectible_item.gd — Sprite2D
# ═══════════════════════════════════════════════════════
def migrate_collectible():
    path = os.path.join(ROOT, "scenes", "objects", "collectible_item.gd")
    with open(path, 'r', encoding='utf-8') as f:
        src = f.read()

    old = r'func _build_visual\(\) -> void:.*?(?=\nfunc )'
    new = """func _build_visual() -> void:
\t_visual = Node2D.new()
\tadd_child(_visual)

\tvar sprite := Sprite2D.new()
\tsprite.name = "ItemSprite"
\t# 根据 item_id 加载对应图标
\tvar tex_path := "res://assets/sprites/objects/item_" + item_id + ".png"
\tif ResourceLoader.exists(tex_path):
\t\tsprite.texture = load(tex_path)
\telse:
\t\t# 回退：默认菱形
\t\tvar item_data: Dictionary = GameManager.ITEMS.get(item_id, {})
\t\tvar color: Color = item_data.get("color", Color(0.8, 0.8, 0.8))
\t\tvar gem := Polygon2D.new()
\t\tgem.polygon = PackedVector2Array([
\t\t\tVector2(0, -3.5), Vector2(2.5, 0), Vector2(0, 3.5), Vector2(-2.5, 0)
\t\t])
\t\tgem.color = color
\t\t_visual.add_child(gem)
\t\treturn
\t_visual.add_child(sprite)

"""
    src = re.sub(old, new, src, flags=re.DOTALL)
    write(path, src)


# ═══════════════════════════════════════════════════════
# 3. fox_spirit.gd — Sprite2D
# ═══════════════════════════════════════════════════════
def migrate_fox():
    path = os.path.join(ROOT, "scenes", "objects", "fox_spirit.gd")
    with open(path, 'r', encoding='utf-8') as f:
        src = f.read()

    old = r'func _build_fox_visual\(\) -> void:.*?(?=\nfunc )'
    new = """func _build_fox_visual() -> void:
\t_fox_visual = Node2D.new()
\tadd_child(_fox_visual)

\tvar sprite := AnimatedSprite2D.new()
\tsprite.name = "FoxSprite"
\tvar frames := SpriteFrames.new()

\t# idle (4帧, 32x24)
\tframes.add_animation("idle")
\tframes.set_animation_speed("idle", 6.0)
\tframes.set_animation_loop("idle", true)
\tvar idle_tex := preload("res://assets/sprites/npcs/fox_idle.png")
\tfor i in range(4):
\t\tvar atlas := AtlasTexture.new()
\t\tatlas.atlas = idle_tex
\t\tatlas.region = Rect2(i * 32, 0, 32, 24)
\t\tframes.add_frame("idle", atlas)

\t# walk (6帧)
\tframes.add_animation("walk")
\tframes.set_animation_speed("walk", 8.0)
\tframes.set_animation_loop("walk", true)
\tvar walk_tex := preload("res://assets/sprites/npcs/fox_walk.png")
\tfor i in range(6):
\t\tvar atlas := AtlasTexture.new()
\t\tatlas.atlas = walk_tex
\t\tatlas.region = Rect2(i * 32, 0, 32, 24)
\t\tframes.add_frame("walk", atlas)

\t# look_back (3帧)
\tframes.add_animation("look_back")
\tframes.set_animation_speed("look_back", 4.0)
\tframes.set_animation_loop("look_back", false)
\tvar lb_tex := preload("res://assets/sprites/npcs/fox_look_back.png")
\tfor i in range(3):
\t\tvar atlas := AtlasTexture.new()
\t\tatlas.atlas = lb_tex
\t\tatlas.region = Rect2(i * 32, 0, 32, 24)
\t\tframes.add_frame("look_back", atlas)

\tif frames.has_animation("default"):
\t\tframes.remove_animation("default")

\tsprite.sprite_frames = frames
\tsprite.play("idle")
\t_fox_visual.add_child(sprite)

"""
    src = re.sub(old, new, src, flags=re.DOTALL)

    # Replace look_back method to play animation
    src = src.replace(
        '''func look_back() -> void:
\t# 白狐回头 - 剧情关键动作
\t_fox_visual.scale.x = -1.0
\tawait get_tree().create_timer(0.5).timeout
\t_fox_visual.scale.x = 1.0''',
        '''func look_back() -> void:
\t# 白狐回头 - 剧情关键动作
\tvar sprite: AnimatedSprite2D = _fox_visual.get_node_or_null("FoxSprite") if _fox_visual else null
\tif sprite:
\t\tsprite.play("look_back")
\t\tawait sprite.animation_finished
\t\tsprite.play("idle")
\telse:
\t\t_fox_visual.scale.x = -1.0
\t\tawait get_tree().create_timer(0.5).timeout
\t\t_fox_visual.scale.x = 1.0'''
    )

    # Remove _circle_pts helper
    src = re.sub(r'\nfunc _circle_pts\(.*?\n(?=func |$)', '\n', src, flags=re.DOTALL)

    write(path, src)


# ═══════════════════════════════════════════════════════
# 4. altar.gd — Sprite2D
# ═══════════════════════════════════════════════════════
def migrate_altar():
    path = os.path.join(ROOT, "scenes", "objects", "altar.gd")
    with open(path, 'r', encoding='utf-8') as f:
        src = f.read()

    old = r'func _build_visual\(\) -> void:.*?(?=\nfunc )'
    new = """func _build_visual() -> void:
\t_visual = Node2D.new()
\tadd_child(_visual)

\tvar sprite := Sprite2D.new()
\tsprite.texture = preload("res://assets/sprites/objects/altar.png")
\tsprite.offset = Vector2(0, -12)
\t_visual.add_child(sprite)

\t# 指示文字
\t_label_node = Label.new()
\t_label_node.text = "奉纳"
\t_label_node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
\t_label_node.position = Vector2(-5, -11.2)
\t_label_node.add_theme_color_override("font_color", Color(0.8, 0.7, 0.5, 0.8))
\t_label_node.add_theme_font_size_override("font_size", 6)
\tadd_child(_label_node)

"""
    src = re.sub(old, new, src, flags=re.DOTALL)
    write(path, src)


# ═══════════════════════════════════════════════════════
# 5. stone_tablet.gd — Sprite2D
# ═══════════════════════════════════════════════════════
def migrate_stone_tablet():
    path = os.path.join(ROOT, "scenes", "objects", "stone_tablet.gd")
    with open(path, 'r', encoding='utf-8') as f:
        src = f.read()

    old = r'func _build_visual\(\) -> void:.*?(?=\nfunc )'
    new = """func _build_visual() -> void:
\t_visual = Node2D.new()
\tadd_child(_visual)

\tvar sprite := Sprite2D.new()
\tsprite.texture = preload("res://assets/sprites/objects/stone_tablet.png")
\tsprite.offset = Vector2(0, -12)
\t_visual.add_child(sprite)

"""
    src = re.sub(old, new, src, flags=re.DOTALL)
    write(path, src)


# ═══════════════════════════════════════════════════════
# 6. bell_rope.gd — Sprite2D
# ═══════════════════════════════════════════════════════
def migrate_bell_rope():
    path = os.path.join(ROOT, "scenes", "objects", "bell_rope.gd")
    with open(path, 'r', encoding='utf-8') as f:
        src = f.read()

    old = r'func _build_visual\(\) -> void:.*?(?=\nfunc )'
    new = """func _build_visual() -> void:
\t_visual = Node2D.new()
\tadd_child(_visual)

\tvar sprite := Sprite2D.new()
\tsprite.name = "BellSprite"
\tsprite.texture = preload("res://assets/sprites/objects/bell_rope.png")
\tsprite.offset = Vector2(0, -24)
\t_visual.add_child(sprite)

"""
    src = re.sub(old, new, src, flags=re.DOTALL)

    # Update pull animation reference (was "Rope", now shakes the whole visual)
    src = src.replace(
        'var rope_node = _visual.get_node_or_null("Rope")\n\tif not rope_node:\n\t\treturn',
        '# 摇动铃绳精灵'
    )
    write(path, src)


# ═══════════════════════════════════════════════════════
# 7. npc_elder.gd — Sprite2D
# ═══════════════════════════════════════════════════════
def migrate_elder():
    path = os.path.join(ROOT, "scenes", "objects", "npc_elder.gd")
    with open(path, 'r', encoding='utf-8') as f:
        src = f.read()

    old = r'func _build_visual\(\) -> void:.*?(?=\nfunc )'
    new = """func _build_visual() -> void:
\t_visual = Node2D.new()
\tadd_child(_visual)

\tvar sprite := AnimatedSprite2D.new()
\tsprite.name = "ElderSprite"
\tsprite.position = Vector2(0, -7)
\tvar frames := SpriteFrames.new()

\tframes.add_animation("idle")
\tframes.set_animation_speed("idle", 2.0)
\tframes.set_animation_loop("idle", true)
\tvar tex := preload("res://assets/sprites/npcs/elder_idle.png")
\tfor i in range(2):
\t\tvar atlas := AtlasTexture.new()
\t\tatlas.atlas = tex
\t\tatlas.region = Rect2(i * 32, 0, 32, 48)
\t\tframes.add_frame("idle", atlas)

\tif frames.has_animation("default"):
\t\tframes.remove_animation("default")

\tsprite.sprite_frames = frames
\tsprite.play("idle")
\t_visual.add_child(sprite)

"""
    src = re.sub(old, new, src, flags=re.DOTALL)

    # Remove _circle_pts helper
    src = re.sub(r'\nfunc _circle_pts\(.*?\n(?=func |$)', '\n', src, flags=re.DOTALL)

    write(path, src)


# ═══════════════════════════════════════════════════════
# 8. parallax_bg.gd — 使用真实背景图片
# ═══════════════════════════════════════════════════════
def migrate_parallax():
    path = os.path.join(ROOT, "scenes", "effects", "parallax_bg.gd")
    
    new_content = '''extends ParallaxBackground
## 大气视差背景 - 使用预生成的背景图层
## sky.png / far_mountains.png / near_trees.png / fog.png / shrine_interior.png

var _time: float = 0.0

func build_background(style: String = "forest") -> void:
\tmatch style:
\t\t"forest": _build_forest_night()
\t\t"shrine": _build_shrine_interior()
\t\t"mountain": _build_mountain_path()
\t\t_: _build_forest_night()

func _build_forest_night() -> void:
\t# 第0层：夜空（固定）
\tvar sky_layer := ParallaxLayer.new()
\tsky_layer.motion_scale = Vector2.ZERO
\tadd_child(sky_layer)
\tvar sky_sprite := Sprite2D.new()
\tsky_sprite.texture = preload("res://assets/backgrounds/sky.png")
\tsky_sprite.centered = false
\tsky_layer.add_child(sky_sprite)

\t# 第1层：远山（缓慢视差）
\tvar mountain_layer := ParallaxLayer.new()
\tmountain_layer.motion_scale = Vector2(0.05, 0.0)
\tadd_child(mountain_layer)
\tvar mountain_sprite := Sprite2D.new()
\tmountain_sprite.texture = preload("res://assets/backgrounds/far_mountains.png")
\tmountain_sprite.centered = false
\tmountain_layer.add_child(mountain_sprite)

\t# 第2层：近景树林（中速视差）
\tvar tree_layer := ParallaxLayer.new()
\ttree_layer.motion_scale = Vector2(0.15, 0.05)
\tadd_child(tree_layer)
\tvar tree_sprite := Sprite2D.new()
\ttree_sprite.texture = preload("res://assets/backgrounds/near_trees.png")
\ttree_sprite.centered = false
\ttree_layer.add_child(tree_sprite)

\t# 第3层：雾气（前景装饰）
\tvar fog_layer := ParallaxLayer.new()
\tfog_layer.motion_scale = Vector2(0.08, 0.02)
\tadd_child(fog_layer)
\tvar fog_sprite := Sprite2D.new()
\tfog_sprite.texture = preload("res://assets/backgrounds/fog.png")
\tfog_sprite.centered = false
\tfog_layer.add_child(fog_sprite)

func _build_shrine_interior() -> void:
\t# 固定背景
\tvar bg_layer := ParallaxLayer.new()
\tbg_layer.motion_scale = Vector2.ZERO
\tadd_child(bg_layer)
\tvar bg_sprite := Sprite2D.new()
\tbg_sprite.texture = preload("res://assets/backgrounds/shrine_interior.png")
\tbg_sprite.centered = false
\tbg_layer.add_child(bg_sprite)

func _build_mountain_path() -> void:
\t_build_forest_night()
'''
    write(path, new_content)


# ═══════════════════════════════════════════════════════
# 9. level_base.gd — 更新装饰工厂方法
# ═══════════════════════════════════════════════════════
def migrate_level_base():
    path = os.path.join(ROOT, "scenes", "levels", "level_base.gd")
    with open(path, 'r', encoding='utf-8') as f:
        src = f.read()

    # Replace add_torii method
    old_torii = r'func add_torii\(.*?\n\treturn torii\n'
    new_torii = """func add_torii(pos: Vector2, scale_factor: float = 1.0, _color: Color = Color(0.65, 0.12, 0.1)) -> Node2D:
\tvar torii := Node2D.new()
\ttorii.position = pos
\ttorii.scale = Vector2.ONE * scale_factor
\tvar sprite := Sprite2D.new()
\tsprite.texture = preload("res://assets/sprites/objects/torii.png")
\tsprite.offset = Vector2(0, -20)
\ttorii.add_child(sprite)
\tplatforms_node.add_child(torii)
\treturn torii
"""
    src = re.sub(old_torii, new_torii, src, flags=re.DOTALL)

    # Replace add_stone_lantern method
    old_lantern = r'func add_stone_lantern\(.*?\n\treturn lantern\n'
    new_lantern = """func add_stone_lantern(pos: Vector2) -> Node2D:
\tvar lantern := Node2D.new()
\tlantern.position = pos
\tvar sprite := Sprite2D.new()
\tsprite.texture = preload("res://assets/sprites/objects/stone_lantern.png")
\tsprite.offset = Vector2(0, -16)
\tlantern.add_child(sprite)
\t# 微光效果
\tvar light := PointLight2D.new()
\tlight.position = Vector2(0, -10)
\tlight.color = Color(1.0, 0.78, 0.35, 0.6)
\tlight.energy = 0.4
\tlight.texture = preload("res://assets/sprites/effects/warm_light.png")
\tlight.texture_scale = 0.5
\tlantern.add_child(light)
\tplatforms_node.add_child(lantern)
\treturn lantern
"""
    src = re.sub(old_lantern, new_lantern, src, flags=re.DOTALL)

    write(path, src)


# ═══════════════════════════════════════════════════════
# 10. fox_fire.gd — Sprite2D 粒子
# ═══════════════════════════════════════════════════════
def migrate_foxfire():
    path = os.path.join(ROOT, "scenes", "effects", "fox_fire.gd")

    new_content = '''extends Node2D
## 狐火粒子效果 - 飘浮的灵异火焰
## 用于环境氛围、引路指示、狐灵身上
## 现在使用预生成的精灵纹理

var _particles: Array[Node2D] = []
var _time: float = 0.0
var _count: int = 8
var _color_base: Color = Color(1.0, 0.65, 0.2)
var _spread: float = 60.0
var _intensity: float = 1.0

func setup(count: int = 8, color: Color = Color(1.0, 0.65, 0.2), spread: float = 60.0, intensity: float = 1.0) -> void:
\t_count = count
\t_color_base = color
\t_spread = spread
\t_intensity = intensity
\t_rebuild()

func _ready() -> void:
\t_rebuild()

func _rebuild() -> void:
\tfor p in _particles:
\t\tp.queue_free()
\t_particles.clear()

\tfor i in range(_count):
\t\tvar orb := Node2D.new()
\t\torb.position = Vector2(
\t\t\trandf_range(-_spread, _spread),
\t\t\trandf_range(-_spread * 0.5, _spread * 0.3)
\t\t)
\t\tadd_child(orb)

\t\t# 光晕
\t\tvar light := PointLight2D.new()
\t\tlight.color = _color_base.lerp(Color(0.6, 0.8, 1.0, 0.5), randf())
\t\tlight.energy = randf_range(0.2, 0.6) * _intensity
\t\tlight.texture = preload("res://assets/sprites/effects/warm_light.png")
\t\tlight.texture_scale = randf_range(0.3, 0.8)
\t\torb.add_child(light)

\t\t# 可见的火球精灵
\t\tvar sprite := Sprite2D.new()
\t\tsprite.texture = preload("res://assets/sprites/effects/particle.png")
\t\tsprite.modulate = _color_base.lerp(Color.WHITE, 0.3)
\t\tsprite.modulate.a = 0.7
\t\tvar s: float = randf_range(0.5, 1.5)
\t\tsprite.scale = Vector2(s, s)
\t\torb.add_child(sprite)

\t\t_particles.append(orb)

func _process(delta: float) -> void:
\t_time += delta
\tfor i in range(_particles.size()):
\t\tvar p: Node2D = _particles[i]
\t\tvar phase: float = i * 1.3
\t\tp.position.x += sin(_time * 0.8 + phase) * 12.0 * delta
\t\tp.position.y += cos(_time * 0.6 + phase) * 8.0 * delta - 3.0 * delta
\t\tif p.position.length() > _spread * 1.5:
\t\t\tp.position = p.position.normalized() * _spread * 0.5
\t\tp.modulate.a = 0.5 + sin(_time * 3.0 + phase) * 0.3

func set_agitated(agitated: bool) -> void:
\tif agitated:
\t\t_color_base = Color(1.0, 0.35, 0.05)
\t\t_intensity = 1.8
\telse:
\t\t_color_base = Color(1.0, 0.65, 0.2)
\t\t_intensity = 1.0
\t_rebuild()
'''
    write(path, new_content)


# ═══════════════════════════════════════════════════════
# 主函数
# ═══════════════════════════════════════════════════════
if __name__ == '__main__':
    print("=" * 60)
    print("迁移脚本：将 Polygon2D 替换为精灵素材")
    print("=" * 60)

    print("\n[1/10] player.gd ...")
    migrate_player()

    print("[2/10] collectible_item.gd ...")
    migrate_collectible()

    print("[3/10] fox_spirit.gd ...")
    migrate_fox()

    print("[4/10] altar.gd ...")
    migrate_altar()

    print("[5/10] stone_tablet.gd ...")
    migrate_stone_tablet()

    print("[6/10] bell_rope.gd ...")
    migrate_bell_rope()

    print("[7/10] npc_elder.gd ...")
    migrate_elder()

    print("[8/10] parallax_bg.gd ...")
    migrate_parallax()

    print("[9/10] level_base.gd ...")
    migrate_level_base()

    print("[10/10] fox_fire.gd ...")
    migrate_foxfire()

    print("\n" + "=" * 60)
    print("✓ 全部迁移完成！10 个脚本已更新为使用精灵素材。")
    print("=" * 60)
