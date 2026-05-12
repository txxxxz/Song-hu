# 《送狐》(OKURI KITSUNE) 开发指南

> **重要**：本项目采用「编辑器优先」架构。所有可视化节点（精灵、碰撞体、光源、UI 控件、视差背景、装饰物等）均需在 Godot 编辑器中手动创建与配置。GDScript 仅负责游戏逻辑（物理、交互、对话、状态机）。

---

## 目录

1. [项目概览与设置](#1-项目概览与设置)
2. [资源清单](#2-资源清单)
3. [玩家场景 (player.tscn)](#3-玩家场景-playertscn)
4. [物品场景 (collectible_item.tscn)](#4-物品场景-collectible_itemtscn)
5. [祭坛场景 (altar.tscn)](#5-祭坛场景-altartscn)
6. [石碑场景 (stone_tablet.tscn)](#6-石碑场景-stone_tablettscn)
7. [NPC老人场景 (npc_elder.tscn)](#7-npc老人场景-npc_eldertscn)
8. [白狐场景 (fox_spirit.tscn)](#8-白狐场景-fox_spirittscn)
9. [铃绳场景 (bell_rope.tscn)](#9-铃绳场景-bell_ropetscn)
10. [HUD场景 (hud.tscn)](#10-hud场景-hudtscn)
11. [选择面板场景 (choice_panel.tscn)](#11-选择面板场景-choice_paneltscn)
12. [主菜单场景 (main_menu.tscn)](#12-主菜单场景-main_menutscn)
13. [第一关 (level_1.tscn)](#13-第一关-level_1tscn)
14. [第二关 (level_2.tscn)](#14-第二关-level_2tscn)
15. [第三关 (level_3.tscn)](#15-第三关-level_3tscn)
16. [结局A场景 (ending_a.tscn)](#16-结局a场景-ending_atscn)
17. [结局B场景 (ending_b.tscn)](#17-结局b场景-ending_btscn)
18. [TileMap 绘制教程](#18-tilemap-绘制教程)
19. [视差背景搭建教程](#19-视差背景搭建教程)
20. [游戏设计数据参考](#20-游戏设计数据参考)

---

## 1. 项目概览与设置

### 1.1 引擎版本

- Godot 4.6, Forward Plus 渲染器

### 1.2 项目设置 (project.godot 已配置)

| 设置         | 值                                  |
| ------------ | ----------------------------------- |
| 视口大小     | 480 × 270 (像素风)                  |
| 窗口大小     | 1920 × 1080 (4× 放大)               |
| Stretch Mode | canvas_items                        |
| 默认纹理过滤 | Nearest (0)                         |
| Pixel Snap   | 开启 (2d_transforms + vertices)     |
| 默认清屏色   | Color(0.02, 0.01, 0.04, 1) 深蓝黑夜 |

### 1.3 输入映射 (project.godot 已配置)

| 动作名       | 按键                       |
| ------------ | -------------------------- |
| `move_left`  | A / ←                      |
| `move_right` | D / →                      |
| `jump`       | Space (代码中也加了 W / ↑) |
| `interact`   | E                          |
| `pause`      | Escape                     |

### 1.4 物理层 (project.godot 已配置)

| 层      | 名称         | 用途                              |
| ------- | ------------ | --------------------------------- |
| Layer 1 | Player       | 玩家碰撞体                        |
| Layer 2 | Interactable | 可交互区域（物品、NPC、祭坛等）   |
| Layer 3 | Environment  | 地形碰撞（TileMap、StaticBody2D） |

### 1.5 自动加载 (Autoload)

| 名称          | 路径                         | 说明                                     |
| ------------- | ---------------------------- | ---------------------------------------- |
| GameManager   | `autoload/game_manager.gd`   | 全局状态机、御供筒栈、分支记录、场景切换 |
| DialogManager | `autoload/dialog_manager.gd` | 全局对话覆盖层（打字机效果）             |

### 1.6 文件夹结构

```
song-hu/
├── autoload/
│   ├── game_manager.gd        (不需修改)
│   └── dialog_manager.gd      (不需修改)
├── assets/
│   ├── audio/bgm/             (背景音乐 .wav)
│   ├── audio/ambience/        (环境音 .wav)
│   ├── audio/sfx/             (音效 .wav)
│   ├── backgrounds/           (视差背景图片 480×270)
│   ├── sprites/player/        (巫女精灵图)
│   ├── sprites/npcs/          (白狐/老人精灵图)
│   ├── sprites/objects/       (物品/建筑精灵图)
│   ├── sprites/effects/       (特效贴图)
│   ├── tilesets/              (.tres + .png)
│   └── ui/                    (UI贴图)
├── scenes/
│   ├── player/player.tscn
│   ├── objects/               (fox_spirit, collectible_item, altar, stone_tablet, npc_elder, bell_rope)
│   ├── ui/                    (main_menu, hud, choice_panel)
│   ├── levels/                (level_1, level_2, level_3)
│   ├── cutscenes/             (ending_a, ending_b)
│   └── effects/fox_fire.gd   (纯代码特效，不需编辑器操作)
└── project.godot
```

---

## 2. 资源清单

### 2.1 玩家精灵图 (assets/sprites/player/)

每张图都是**水平条形图**（sprite sheet），每帧 64×96 像素。

| 文件                | 帧数 | 帧尺寸 | 总图尺寸 | 动画名   | FPS | 循环 |
| ------------------- | ---- | ------ | -------- | -------- | --- | ---- |
| `miko_idle.png`     | 6    | 64×96  | 384×96   | idle     | 8   | ✓    |
| `miko_run.png`      | 8    | 64×96  | 512×96   | run      | 10  | ✓    |
| `miko_jump.png`     | 3    | 64×96  | 192×96   | jump     | 6   | ✗    |
| `miko_fall.png`     | 2    | 64×96  | 128×96   | fall     | 6   | ✓    |
| `miko_interact.png` | 4    | 64×96  | 256×96   | interact | 6   | ✗    |

### 2.2 白狐精灵图 (assets/sprites/npcs/)

每帧 64×48 像素。

| 文件                | 帧数 | 帧尺寸 | 总图尺寸 | 动画名    | FPS | 循环 |
| ------------------- | ---- | ------ | -------- | --------- | --- | ---- |
| `fox_idle.png`      | 4    | 64×48  | 256×48   | idle      | 6   | ✓    |
| `fox_walk.png`      | 6    | 64×48  | 384×48   | walk      | 8   | ✓    |
| `fox_look_back.png` | 3    | 64×48  | 192×48   | look_back | 4   | ✗    |

### 2.3 老人精灵图 (assets/sprites/npcs/)

| 文件             | 帧数 | 帧尺寸 | 总图尺寸 | 动画名 | FPS | 循环 |
| ---------------- | ---- | ------ | -------- | ------ | --- | ---- |
| `elder_idle.png` | 2    | 64×96  | 128×96   | idle   | 2   | ✓    |

### 2.4 物品/建筑精灵图 (assets/sprites/objects/)

全为 32×32 单帧静态图。

| 文件                   | 用途             |
| ---------------------- | ---------------- |
| `item_sugi_wood.png`   | 收集物：杉木     |
| `item_white_fur.png`   | 收集物：白毛     |
| `item_mugwort.png`     | 收集物：蓬草     |
| `item_bell_fiber.png`  | 收集物：铃绳纤维 |
| `item_fox_stone.png`   | 收集物：狐火石   |
| `item_water_grass.png` | 收集物：清水草   |
| `item_lamp_oil.png`    | 收集物：灯芯油   |
| `altar.png`            | 祭坛             |
| `stone_tablet.png`     | 石碑             |
| `bell_rope.png`        | 铃绳             |
| `torii.png`            | 鸟居             |
| `stone_lantern.png`    | 石灯笼           |

### 2.5 背景图 (assets/backgrounds/) — 均为 480×270

| 文件                  | 用途               |
| --------------------- | ------------------ |
| `sky.png`             | 夜空（最远层）     |
| `far_mountains.png`   | 远山轮廓           |
| `near_trees.png`      | 近景树木           |
| `fog.png`             | 雾气层             |
| `shrine_interior.png` | 神社内部（第三关） |

### 2.6 TileSet

| 文件                                  | 用途                                  |
| ------------------------------------- | ------------------------------------- |
| `assets/tilesets/forest_tileset.tres` | 森林TileSet资源                       |
| `assets/tilesets/forest_tileset.png`  | 森林瓦片图 (256×160, 32×32 网格, 8×5) |
| `assets/tilesets/shrine_tileset.png`  | 神社瓦片图 (256×160, 32×32 网格, 8×5) |

#### 森林瓦片图 (forest_tileset.png) —— 逐格内容

> **使用场景**：Level 1（杉の森）、Level 2（深い森）

| 行\列 | Col 0     | Col 1       | Col 2       | Col 3       | Col 4   | Col 5   | Col 6 | Col 7 |
| ----- | --------- | ----------- | ----------- | ----------- | ------- | ------- | ----- | ----- |
| Row 0 | 草地A     | 草地B(变体) | 平台顶部    | 左上角      | 右上角  | 土地    | 石砖A | 石砖B |
| Row 1 | 草地填充A | 草地填充B   | 左壁        | 右壁        | 木桥A   | 木桥B   | 石阶A | 石阶B |
| Row 2 | 鸟居·左柱 | 鸟居·右柱   | 鸟居·横梁左 | 鸟居·横梁右 | 石灯笼A | 石灯笼B | 灌木  | 蘑菇  |
| Row 3 | 木墙      | 纸门        | 柱子        | 瓦屋顶      | (空)    | (空)    | (空)  | (空)  |
| Row 4 | 单向平台  | 绳索        | 铃铛        | 注连绳      | (空)    | (空)    | (空)  | (空)  |

- **草地/土地 (Row 0-1)**：构建地面和平台的主要瓦片。用 Col 0-1 铺底部填充，Col 2 做平台表面，Col 3-4 做拐角。
- **鸟居装饰 (Row 2, Col 0-3)**：4 格组合成完整鸟居门（放置于场景装饰，非碰撞体）。
- **单向平台 (Row 4, Col 0)**：角色可从下方跳上去的木质平台。

#### 神社瓦片图 (shrine_tileset.png) —— 逐格内容

> **使用场景**：Level 3（山頂神社）

| 行\列 | Col 0      | Col 1   | Col 2       | Col 3       | Col 4    | Col 5       | Col 6     | Col 7       |
| ----- | ---------- | ------- | ----------- | ----------- | -------- | ----------- | --------- | ----------- |
| Row 0 | 木板地A    | 木板地B | 畳A(横纹)   | 畳B(纵纹)   | 暗木地板 | 石板地      | 古木地板A | 古木地板B   |
| Row 1 | 木壁A      | 木壁B   | 障子A(完整) | 障子B(半開) | 朱柱     | 木柱        | 朱壁A     | 朱壁B       |
| Row 2 | 漆喰壁A    | 漆喰壁B | 欄間        | 格子窓A     | 格子窓B  | 賽銭箱      | 苔石A     | 苔石B       |
| Row 3 | 瓦屋顶A    | 瓦屋顶B | 鬼瓦        | 木天井A     | 木天井B  | 注連縄+紙垂 | 提灯A(丸) | 提灯B(行灯) |
| Row 4 | 朱色单向台 | 燭台    | 匾額        | 神棚        | 御幣     | 階段A       | 階段B     | 方石台      |

- **地板 (Row 0)**：8 种不同地面——木板、畳(榻榻米)、暗木、石板、古木。用来区分神社不同区域。
- **壁面 (Row 1)**：木壁、障子(纸门)、柱子、朱红墙。组合构成神社室内墙体。
- **装饰 (Row 2-3)**：漆喰(灰泥)墙、欄間(透雕)、格子窓(格栅窗)、賽銭箱(功德箱)、鬼瓦(鬼面脊瓦)、提灯、注連縄。
- **功能 (Row 4)**：朱色单向台、燭台、匾額、神棚(神龛)、御幣(祓串)、階段、方石台。

### 2.7 音频

| 目录              | 文件                | 用途                     |
| ----------------- | ------------------- | ------------------------ |
| `audio/bgm/`      | `forest_night.wav`  | 森林夜晚BGM（第一/二关） |
| `audio/bgm/`      | `shrine_theme.wav`  | 神社主题BGM（第三关）    |
| `audio/ambience/` | `night_insects.wav` | 夜虫环境音               |
| `audio/sfx/`      | `jump.wav`          | 跳跃音效                 |
| `audio/sfx/`      | `footstep.wav`      | 脚步音效                 |
| `audio/sfx/`      | `collect.wav`       | 拾取物品音效             |
| `audio/sfx/`      | `bell.wav`          | 铃声音效                 |
| `audio/sfx/`      | `interact.wav`      | 交互音效                 |

---

## 3. 玩家场景 (player.tscn)

> 文件：`scenes/player/player.tscn`
> 脚本：`scenes/player/player.gd`

### 3.1 节点树结构

```
Player (CharacterBody2D)              ← 根节点，已有脚本
├── Visual (Node2D)                    ← 容器，用于翻转朝向
│   └── Sprite (AnimatedSprite2D)      ← 动画精灵
├── CollisionShape (CollisionShape2D)  ← 物理碰撞体
├── InteractionArea (Area2D)           ← 交互检测区域
│   └── InteractShape (CollisionShape2D) ← 交互范围
├── Camera (Camera2D)                  ← 跟随相机
├── PlayerLight (PointLight2D)         ← 微弱环境光
├── InteractPrompt (Label)             ← "E" 提示文字
└── SFXPlayer (AudioStreamPlayer)      ← 音效播放器
```

### 3.2 逐步操作

#### 步骤 1：打开 player.tscn

双击 `scenes/player/player.tscn`。当前只有根节点 `Player (CharacterBody2D)`。

#### 步骤 2：设置根节点 Player

1. 选中 `Player`
2. 在检视器 (Inspector) 中确认：
   - **Collision > Layer**: 勾选 `1 (Player)`
   - **Collision > Mask**: 勾选 `3 (Environment)`
   - **Script**: 已挂载 `player.gd`

#### 步骤 3：添加 Visual (Node2D)

1. 右键 `Player` → **Add Child Node** → 搜索 `Node2D` → 创建
2. 重命名为 `Visual`
3. **Transform > Position**: `(0, 0)`

#### 步骤 4：添加 Sprite (AnimatedSprite2D)

1. 右键 `Visual` → **Add Child Node** → 搜索 `AnimatedSprite2D` → 创建
2. 重命名为 `Sprite`
3. 在检视器中，找到 **Sprite Frames** 属性 → 点击 `<empty>` → **New SpriteFrames**
4. 点击新创建的 SpriteFrames，底部会出现 **SpriteFrames 编辑面板**

##### 配置 idle 动画：

1. 左侧动画列表中，已有一个 `default` 动画，双击重命名为 `idle`
2. 右下方设置 **FPS**: `8`
3. 勾选 **Loop** ✓
4. 点击面板顶部「从精灵图集添加帧」按钮（网格图标 🔲）
5. 在弹出的文件选择对话框中，选择 `assets/sprites/player/miko_idle.png`
6. 在 Atlas 切割对话框中设置：
   - **Horizontal**: `6`
   - **Vertical**: `1`
   - 点击 **Select All** 选中全部 6 帧
   - 点击 **Add 6 Frame(s)**

##### 配置 run 动画：

1. 点击左侧动画列表底部的 ➕ 按钮，添加新动画，命名为 `run`
2. **FPS**: `10`，**Loop**: ✓
3. 网格图标 → 选择 `miko_run.png` → Horizontal: `8`, Vertical: `1` → Select All → Add

##### 配置 jump 动画：

1. 添加新动画 `jump`
2. **FPS**: `6`，**Loop**: ✗（不勾选）
3. 网格图标 → `miko_jump.png` → H: `3`, V: `1` → Select All → Add

##### 配置 fall 动画：

1. 添加新动画 `fall`
2. **FPS**: `6`，**Loop**: ✓
3. 网格图标 → `miko_fall.png` → H: `2`, V: `1` → Select All → Add

##### 配置 interact 动画：

1. 添加新动画 `interact`
2. **FPS**: `6`，**Loop**: ✗
3. 网格图标 → `miko_interact.png` → H: `4`, V: `1` → Select All → Add

##### 设置 Sprite 位置：

- 选中 `Sprite` 节点
- **Transform > Position**: `(0, -48)` — 锚点在脚底，精灵向上偏移（96px 高度的一半）
- **或者**你可以设置 **Offset > Y**: `-48`，看哪种方式对你更方便

#### 步骤 5：添加 CollisionShape (CollisionShape2D)

1. 右键 `Player` → **Add Child Node** → `CollisionShape2D`
2. 重命名为 `CollisionShape`
3. 在检视器中：
   - **Shape**: 点击 `<empty>` → **New CapsuleShape2D**
   - 点击 CapsuleShape2D 展开：
     - **Radius**: `17`
     - **Height**: `74`
   - **Transform > Position**: `(0, -50)` — 胶囊中心偏上，让脚接触地面

#### 步骤 6：添加 InteractionArea (Area2D)

1. 右键 `Player` → **Add Child Node** → `Area2D`
2. 重命名为 `InteractionArea`
3. 检视器设置：
   - **Collision > Layer**: 全部取消（不占任何层）
   - **Collision > Mask**: 勾选 `2 (Interactable)` — 检测可交互物体

#### 步骤 7：添加 InteractionArea 的子碰撞形状

1. 右键 `InteractionArea` → **Add Child Node** → `CollisionShape2D`
2. 重命名为 `InteractShape`
3. 检视器：
   - **Shape**: **New CircleShape2D** → **Radius**: `30`
   - **Transform > Position**: `(0, -50)`

#### 步骤 8：添加 Camera (Camera2D)

1. 右键 `Player` → **Add Child Node** → `Camera2D`
2. 重命名为 `Camera`
3. 检视器设置：
   - **Position Smoothing > Enabled**: ✓
   - **Position Smoothing > Speed**: `5`
   - **Drag > Left Margin**: `0.15`
   - **Drag > Right Margin**: `0.15`
   - **Drag > Top Margin**: `0.1`
   - **Drag > Bottom Margin**: `0.1`
   - **Drag > Horizontal Enabled**: ✓
   - **Drag > Vertical Enabled**: ✓
   - **Limit > Left**: `-100`
   - **Limit > Right**: `2000` （根据关卡宽度调整）
   - **Limit > Top**: `-500`
   - **Limit > Bottom**: `300`

#### 步骤 9：添加 PlayerLight (PointLight2D)

1. 右键 `Player` → **Add Child Node** → `PointLight2D`
2. 重命名为 `PlayerLight`
3. 检视器设置：
   - **Texture**: 选择 `assets/sprites/effects/warm_light.png`
   - **Color**: `Color(0.95, 0.85, 0.6, 0.4)` — 温暖微弱光
   - **Energy**: `0.3`
   - **Texture Scale**: `2.0`
   - **Transform > Position**: `(0, -50)`

#### 步骤 10：添加 InteractPrompt (Label)

1. 右键 `Player` → **Add Child Node** → `Label`
2. 重命名为 `InteractPrompt`
3. 检视器设置：
   - **Text**: `E`
   - **Horizontal Alignment**: Center
   - **Transform > Position**: `(5, −80)` — 在头顶上方
   - **Theme Overrides > Colors > Font Color**: `Color(1.0, 0.9, 0.6, 0.8)` 淡金色
   - **Theme Overrides > Font Sizes > Font Size**: `16`
   - **Visible**: ✗（默认不可见，脚本控制显隐）

#### 步骤 11：添加 SFXPlayer (AudioStreamPlayer)

1. 右键 `Player` → **Add Child Node** → `AudioStreamPlayer`
2. 重命名为 `SFXPlayer`
3. **Volume dB**: `-5`
4. **Bus**: `Master`（默认即可）

#### 步骤 12：保存

`Ctrl+S` 保存场景。

---

## 4. 物品场景 (collectible_item.tscn)

> 文件：`scenes/objects/collectible_item.tscn`
> 脚本：`scenes/objects/collectible_item.gd`
> **注意：此场景作为模板。放置到关卡中时，需设置 `@export var item_id`。**

### 4.1 节点树

```
CollectibleItem (Area2D)          ← 根节点
├── Visual (Node2D)               ← 视觉容器（代码控制浮动旋转）
│   └── ItemSprite (Sprite2D)     ← 物品精灵
├── CollisionShape (CollisionShape2D)  ← 碰撞检测
└── Glow (PointLight2D)           ← 可选发光（狐火石/灯芯油用）
```

### 4.2 逐步操作

1. 打开 `scenes/objects/collectible_item.tscn`
2. 选中根节点 `CollectibleItem`：
   - **Collision > Layer**: `2 (Interactable)`
   - **Collision > Mask**: 全部取消
3. 右键根节点 → Add Child → `Node2D`，命名 `Visual`
4. 右键 `Visual` → Add Child → `Sprite2D`，命名 `ItemSprite`
   - **Texture**: 先设为 `item_sugi_wood.png`（模板默认；实例化后按需更改）
5. 右键根节点 → Add Child → `CollisionShape2D`，命名 `CollisionShape`
   - **Shape**: New CircleShape2D → **Radius**: `8`
6. （可选）右键根节点 → Add Child → `PointLight2D`，命名 `Glow`
   - **Texture**: `assets/sprites/effects/warm_light.png`
   - **Color**: `Color(1.0, 0.8, 0.3, 0.5)`
   - **Energy**: `0.3`
   - **Texture Scale**: `0.5`
7. 保存

### 4.3 在关卡中放置物品

在关卡 .tscn 中：

1. 创建一个 `Node2D` 子节点，命名 `Items`
2. 右键 `Items` → **Instance Child Scene** → 选择 `collectible_item.tscn`
3. 在实例的检视器中设置 `Item Id` 属性（如 `sugi_wood`、`white_fur`、`mugwort`）
4. 更换 `Visual/ItemSprite` 的 Texture 为对应物品的 .png 文件
5. 调整 Position 放到关卡中合适位置

---

## 5. 祭坛场景 (altar.tscn)

> 文件：`scenes/objects/altar.tscn`
> 脚本：`scenes/objects/altar.gd`

### 5.1 节点树

```
Altar (Area2D)                    ← 根节点
├── AltarSprite (Sprite2D)        ← 祭坛图片
├── CollisionShape (CollisionShape2D) ← 碰撞
├── Glow (PointLight2D)           ← 祭坛光晕
└── Label (Label)                 ← "奉納" 文字
```

### 5.2 逐步操作

1. 打开 `scenes/objects/altar.tscn`
2. 根节点 `Altar`：
   - **Collision > Layer**: `2`
   - **Collision > Mask**: 全部取消
3. 添加 `Sprite2D`，命名 `AltarSprite`
   - **Texture**: `assets/sprites/objects/altar.png`
4. 添加 `CollisionShape2D`
   - **Shape**: New RectangleShape2D → **Size**: `(40, 30)`
   - **Position**: `(0, 5)` — 稍微偏下
5. 添加 `PointLight2D`，命名 `Glow`
   - **Texture**: `assets/sprites/effects/warm_light.png`
   - **Color**: `Color(0.7, 0.5, 0.2, 0.5)`
   - **Energy**: `0.3`
   - **Texture Scale**: `1.5`
   - **Position**: `(0, -5)`
6. 添加 `Label`
   - **Name**: `Label`
   - **Text**: `奉納`
   - **Horizontal Alignment**: Center
   - **Position**: `(−16, −20)`
   - **Theme Overrides > Font Color**: `Color(0.8, 0.7, 0.5, 0.8)`
   - **Theme Overrides > Font Size**: `6`
7. 保存

### 5.3 在关卡中放置

实例化后设置 `@export var level`（第一关=1，第二关=2）。

---

## 6. 石碑场景 (stone_tablet.tscn)

> 文件：`scenes/objects/stone_tablet.tscn`
> 脚本：`scenes/objects/stone_tablet.gd`

### 6.1 节点树

```
StoneTablet (Area2D)
├── TabletSprite (Sprite2D)
└── CollisionShape (CollisionShape2D)
```

### 6.2 逐步操作

1. 打开 `scenes/objects/stone_tablet.tscn`
2. 根节点设置：Layer=`2`, Mask=无
3. 添加 Sprite2D → Texture: `assets/sprites/objects/stone_tablet.png`
4. 添加 CollisionShape2D → New RectangleShape2D → Size: `(20, 40)`
5. 保存

### 6.3 在关卡中放置

- 实例化后在检视器中设置：
  - `Tablet Text`: 多行文字用 `\n` 分隔。例如：`此处乃送狐古道之始。\n行者须依序奉上三道供物。\n杉木为底，白毛覆身，蓬草盖顶。`
  - `Speaker Name`: 留空或填 `石碑`

---

## 7. NPC老人场景 (npc_elder.tscn)

> 文件：`scenes/objects/npc_elder.tscn`
> 脚本：`scenes/objects/npc_elder.gd`

### 7.1 节点树

```
NpcElder (Area2D)
├── Visual (Node2D)
│   └── ElderSprite (AnimatedSprite2D)
└── CollisionShape (CollisionShape2D)
```

### 7.2 逐步操作

1. 打开 `scenes/objects/npc_elder.tscn`
2. 根节点：Layer=`2`, Mask=无
3. 添加 `Node2D`，命名 `Visual`
4. 在 `Visual` 下添加 `AnimatedSprite2D`，命名 `ElderSprite`
   - 创建 **New SpriteFrames**
   - 添加 `idle` 动画：
     - 文件：`assets/sprites/npcs/elder_idle.png`
     - Horizontal: `2`, Vertical: `1`
     - FPS: `2`, Loop: ✓
     - 选中两帧 → Add
   - 设置 **Animation**: `idle`，勾选 **Autoplay** ✓
5. 添加 `CollisionShape2D` → RectangleShape2D → Size: `(20, 60)`
6. 保存

### 7.3 在关卡中放置

- 实例化后，对话内容通常由关卡脚本在 `_on_level_ready()` 中通过代码 `npc.set_dialog()` 设置
- 也可以将 NPC 直接放在关卡场景中作为内嵌节点（不用实例化），然后在关卡脚本中引用

---

## 8. 白狐场景 (fox_spirit.tscn)

> 文件：`scenes/objects/fox_spirit.tscn`
> 脚本：`scenes/objects/fox_spirit.gd`
> **白狐由 `level_base.gd` 的 `spawn_fox()` 在运行时实例化，不需手动放入关卡。但场景需要完整配置。**

### 8.1 节点树

```
FoxSpirit (Node2D)
├── Visual (Node2D)
│   └── FoxSprite (AnimatedSprite2D)
├── FoxLight (PointLight2D)
└── Shadow (Node2D)
    └── ShadowSprite (Sprite2D)      ← 可选：人影轮廓
```

### 8.2 逐步操作

1. 打开 `scenes/objects/fox_spirit.tscn`
2. 添加 `Node2D`，命名 `Visual`
3. 在 `Visual` 下添加 `AnimatedSprite2D`，命名 `FoxSprite`
   - 创建 SpriteFrames，添加 3 个动画：
     - `idle`: `fox_idle.png` H:4 V:1 → 4帧 6FPS ✓循环
     - `walk`: `fox_walk.png` H:6 V:1 → 6帧 8FPS ✓循环
     - `look_back`: `fox_look_back.png` H:3 V:1 → 3帧 4FPS ✗循环
   - Autoplay: `idle`
4. 添加 `PointLight2D`，命名 `FoxLight`
   - Texture: `assets/sprites/effects/warm_light.png`
   - Color: `Color(0.9, 0.7, 0.3, 0.7)`
   - Energy: `0.7`
   - Texture Scale: `1.5`
   - Position: `(0, -10)`
5. 添加 `Node2D`，命名 `Shadow`
   - 在 `Shadow` 下添加 `Sprite2D`，命名 `ShadowSprite`
   - 可以用纯色的小人轮廓图片，或使用 `assets/sprites/effects/particle.png` 做占位
   - Modulate: `Color(0, 0, 0, 0.3)`
   - Position: `(0, 15)`
6. 保存

---

## 9. 铃绳场景 (bell_rope.tscn)

> 文件：`scenes/objects/bell_rope.tscn`
> 脚本：`scenes/objects/bell_rope.gd`

### 9.1 节点树

```
BellRope (Area2D)
├── Visual (Node2D)
│   └── BellSprite (Sprite2D)
└── CollisionShape (CollisionShape2D)
```

### 9.2 逐步操作

1. 打开 `scenes/objects/bell_rope.tscn`
2. 根节点：Layer=`2`, Mask=无
3. 添加 `Node2D`，命名 `Visual`
4. 在 `Visual` 下添加 `Sprite2D`，命名 `BellSprite`
   - Texture: `assets/sprites/objects/bell_rope.png`
5. 添加 `CollisionShape2D` → RectangleShape2D → Size: `(20, 100)`
6. 保存

---

## 10. HUD场景 (hud.tscn)

文件：`scenes/ui/hud.tscn`  
脚本：`scenes/ui/hud.gd`

### 10.1 节点树

```
HUD (CanvasLayer)                          ← layer = 50
├── Container (MarginContainer)            ← 用于整体安全边距（可选扩展用）
├── AreaLabel (Label)                      ← 区域名称（顶部居中）
└── OfferingPanel (PanelContainer)         ← 右上角御供筒面板
    └── PanelVBox (VBoxContainer)
        ├── TitleLabel (Label)             ← "御供筒"
        ├── HSeparator
        └── OfferingVBox (VBoxContainer)   ← 物品列表（代码动态填充）
```

### 10.2 逐步操作

1. 打开 `scenes/ui/hud.tscn`

2. 选中根节点 **HUD**：
   - **Layer**: 50

3. 添加 **MarginContainer**，命名为 **Container**
   - **Layout > Anchors Preset**: Full Rect（铺满整个 HUD）
   - **Theme Overrides > Constants > Margin**：
     - Left = 4
     - Top = 4
     - Right = 4
     - Bottom = 4

4. **直接在 HUD 节点下**（而非 Container 下）添加 **Label**，命名为 **AreaLabel**
   - **Layout > Anchors Preset**: Top Wide（推荐）或 **Top**
   - **Horizontal Alignment**: Center
   - **Theme Overrides > Font Color**: Color(0.8, 0.7, 0.5, 0.9)
   - **Theme Overrides > Font Size**: 8
   - **Modulate > Alpha**: 0（默认隐藏，由代码控制淡入淡出）

5. **直接在 HUD 节点下**（而非 Container 下）添加 **PanelContainer**，命名为 **OfferingPanel**
   - **Layout > Anchors Preset**: Top Right
   - **Custom Minimum Size**: (70, 40)
   - 创建 **Theme Override > Styles > Panel**：New StyleBoxFlat
     - **BG Color**: Color(0.05, 0.03, 0.08, 0.75)
     - **Border Color**: Color(0.3, 0.25, 0.15, 0.5)
     - **Border Width**: 1（全部方向）
     - **Corner Radius**: 2（全部方向）
     - **Content Margin**: left=3, top=2, right=3, bottom=2

6. 在 **OfferingPanel** 下添加 **VBoxContainer**，命名为 **PanelVBox**
   - **Separation**: 2

7. 在 **PanelVBox** 下添加 **Label**，命名为 **TitleLabel**
   - **Text**: 御供筒
   - **Horizontal Alignment**: Center
   - **Font Color**: Color(0.7, 0.6, 0.4)
   - **Font Size**: 6

8. 在 **PanelVBox** 下添加 **HSeparator**

9. 在 **PanelVBox** 下添加 **VBoxContainer**，命名为 **OfferingVBox**
   - **Separation**: 1
   - （内容由代码动态生成，此处留空）

10. 保存场景

---

## 11. 选择面板场景 (choice_panel.tscn)

文件：`scenes/ui/choice_panel.tscn`  
脚本：`scenes/ui/choice_panel.gd`

### 11.1 节点树

```
ChoicePanel (CanvasLayer)              ← layer = 80
└── BgDim (ColorRect)                  ← 半透明遮罩（全屏）
    └── Center (CenterContainer)       ← 居中容器
        └── Panel (PanelContainer)     ← 选择面板
            └── VBox (VBoxContainer)
                ├── TitleLabel (Label)
                └── HBox (HBoxContainer)
                    ├── ChoiceA (Button)
                    └── ChoiceB (Button)
```

### 11.2 逐步操作

1. 打开 `scenes/ui/choice_panel.tscn`

2. 选中根节点 **ChoicePanel**：
   - **Layer**: 80

3. 在 ChoicePanel 下添加 **ColorRect**，命名为 **BgDim**
   - **Layout > Anchors Preset**: Full Rect
   - **Color**: Color(0, 0, 0, 0.5)

4. 在 **BgDim** 下添加 **CenterContainer**，命名为 **Center**  
   （无需设置 Anchors Preset，CenterContainer 会自动居中其子节点）

5. 在 **Center** 下添加 **PanelContainer**，命名为 **Panel**
   - **Layout > Anchors Preset**: Center（推荐）或保持默认
   - **Custom Minimum Size**: (200, 60)
   - 在 **Theme Overrides > Styles** 中找到 **Panel**：
     - 点击右侧资源区域（或 ▼ 下拉箭头）→ **New StyleBoxFlat**
     - 点击新建的 **StyleBoxFlat** 资源，展开属性并设置：
       - **Bg Color**: Color(0.06, 0.04, 0.1, 0.9)
       - **Border Color**: Color(0.4, 0.3, 0.15, 0.8)
       - **Border Width**: 1（全部方向）
       - **Corner Radius**: 3（全部方向）
       - **Content Margins**: 8（全部方向，或分别设置）

6. 在 **Panel** 下添加 **VBoxContainer**，命名为 **VBox**
   - **Separation**: 6
   - **Alignment**: Center

7. 在 **VBox** 下添加 **Label**，命名为 **TitleLabel**
   - **Text**: （留空，运行时由代码填充）
   - **Horizontal Alignment**: Center
   - **Theme Overrides > Colors > Font Color**: Color(0.9, 0.8, 0.6)
   - **Theme Overrides > Constants > Font Size**: 7

8. 在 **VBox** 下添加 **HBoxContainer**，命名为 **HBox**
   - **Separation**: 10
   - **Alignment**: Center

9. 在 **HBox** 下添加两个 **Button**：
   - 第一个命名为 **ChoiceA**，Text 留空（代码填充）
   - 第二个命名为 **ChoiceB**，Text 留空（代码填充）
   - 两个按钮设置相同样式：
     - **Custom Minimum Size**: (80, 30)
     - **Theme Overrides > Styles > Normal**：
       - 点击右侧 → **New StyleBoxFlat**
       - **Bg Color**: Color(0.15, 0.1, 0.2, 0.8)
       - **Border Color**: Color(0.5, 0.4, 0.2, 0.6)
       - **Border Width**: 1（全部）
       - **Corner Radius**: 2（全部）
     - **Theme Overrides > Styles > Hover**：
       - 点击右侧 → **New StyleBoxFlat**
       - **Bg Color**: Color(0.25, 0.18, 0.1, 0.9)
       - **Border Color**: Color(0.7, 0.5, 0.2, 0.8)
       - **Border Width**: 1（全部）
       - **Corner Radius**: 2（全部）
     - **Theme Overrides > Colors > Font Color**: Color(0.85, 0.75, 0.6)
     - **Theme Overrides > Constants > Font Size**: 6

10. 选中根节点 **ChoicePanel**，将 **Visible** 设为 **false**（默认隐藏）

11. 保存

---

## 12. 主菜单场景 (main_menu.tscn)

文件：`scenes/ui/main_menu.tscn`  
脚本：`scenes/ui/main_menu.gd`

### 12.1 节点树

```
MainMenu (Control)                     ← Full Rect
├── Background (ColorRect)             ← 深色背景
├── SkyTexture (TextureRect)           ← 可选远景
├── TitleLabel (Label)                 ← "送狐"
├── SubtitleLabel (Label)              ← "OKURI KITSUNE"
└── ButtonVBox (VBoxContainer)         ← 按钮容器
    ├── StartBtn (Button)
    └── QuitBtn (Button)
```

### 12.2 逐步操作

1. 打开 `scenes/ui/main_menu.tscn`（根节点 MainMenu 已存在）

2. 选中 **MainMenu**：
   - **Layout > Anchors Preset**: Full Rect

3. 在 MainMenu 下添加 **ColorRect**，命名为 **Background**
   - **Layout > Anchors Preset**: Full Rect
   - **Color**: Color(0.02, 0.01, 0.04, 1)

4. 在 MainMenu 下添加 **TextureRect**，命名为 **SkyTexture**（可选）
   - **Layout > Anchors Preset**: Full Rect
   - **Texture**: assets/backgrounds/sky.png
   - **Stretch Mode**: Keep Aspect Covered
   - **Modulate**: Color(1, 1, 1, 0.3)

5. 在 MainMenu 下添加 **Label**，命名为 **TitleLabel**
   - **Text**: 送狐
   - **Horizontal Alignment**: Center
   - **Layout > Anchors Preset**: Center
   - **Position**: (180, 60)
   - **Size**: (120, 30)
   - **Theme Overrides > Colors > Font Color**: Color(0.95, 0.85, 0.55)
   - **Theme Overrides > Constants > Font Size**: 24

6. 在 MainMenu 下添加 **Label**，命名为 **SubtitleLabel**
   - **Text**: OKURI KITSUNE
   - **Horizontal Alignment**: Center
   - **Layout > Anchors Preset**: Center
   - **Position**: (180, 90)
   - **Size**: (120, 15)
   - **Theme Overrides > Colors > Font Color**: Color(0.6, 0.5, 0.35, 0.7)
   - **Theme Overrides > Constants > Font Size**: 6

7. 在 MainMenu 下添加 **VBoxContainer**，命名为 **ButtonVBox**
   - **Layout > Anchors Preset**: Center
   - **Position**: (190, 130)
   - **Size**: (100, 60)
   - **Separation**: 6
   - **Alignment**: Center

8. 在 **ButtonVBox** 下添加 **Button**，命名为 **StartBtn**
   - **Text**: 开始旅途
   - **Custom Minimum Size**: (80, 18)
   - **Font Size**: 7（通过 Theme Overrides > Constants > Font Size）
   - 样式参考 ChoiceA/ChoiceB 的 Normal 和 Hover（使用 StyleBoxFlat，颜色可适当调暗一些）

9. 在 **ButtonVBox** 下添加 **Button**，命名为 **QuitBtn**
   - **Text**: 离开
   - 其他设置同 StartBtn

10. 保存

---

## 13. 第一关 (level_1.tscn)

> 文件：`scenes/levels/level_1.tscn`
> 脚本：`scenes/levels/level_1.gd`（继承 `LevelBase`）

### 13.1 节点树

```
Level1 (Node2D)                         ← 脚本：level_1.gd
├── ParallaxBackground                  ← 视差背景（见第19节）
│   ├── SkyLayer (ParallaxLayer)
│   ├── MountainLayer (ParallaxLayer)
│   ├── TreeLayer (ParallaxLayer)
│   └── FogLayer (ParallaxLayer)
├── TileMapLayer                        ← 已有！(forest_tileset)
├── Platforms (Node2D)                  ← 额外平台容器
│   └── (StaticBody2D 节点们)
├── Player ← 实例化 player.tscn
├── Items (Node2D)                      ← 物品容器
│   ├── Sugi (CollectibleItem)          ← item_id="sugi_wood"
│   ├── WhiteFur (CollectibleItem)      ← item_id="white_fur"
│   └── Mugwort (CollectibleItem)       ← item_id="mugwort"
├── Narrative (Node2D)
│   ├── Elder (NpcElder)                ← NPC老人
│   ├── Tablet1 (StoneTablet)
│   ├── Tablet2 (StoneTablet)
│   ├── Tablet3 (StoneTablet)
│   └── Altar (Altar)                   ← level=1
├── Decorations (Node2D)
│   ├── Torii (Sprite2D)               ← torii.png
│   └── Lantern1 (Sprite2D + PointLight2D)
├── HUD ← 实例化 hud.tscn
├── BGM (AudioStreamPlayer)
├── Ambience (AudioStreamPlayer)
└── SFX (AudioStreamPlayer)
```

### 13.2 逐步操作

#### 步骤 1：基础结构

1. 打开 `scenes/levels/level_1.tscn`
2. 根节点已有 `Level1 (Node2D)` + `TileMapLayer`
3. 在根节点下添加以下空 Node2D 容器（保持组织清晰）：
   - `Platforms` (Node2D)
   - `Items` (Node2D)
   - `Narrative` (Node2D)
   - `Decorations` (Node2D)

#### 步骤 2：放置玩家

1. 右键 `Level1` → **Instance Child Scene** → 选择 `player.tscn`
2. 命名节点为 `Player`
3. Position: `(50, 235)` — 关卡左侧起始点（配合 TileMap 地形高度调整）

#### 步骤 3：绘制 TileMap 地形

参见 [第18节 TileMap 绘制教程](#18-tilemap-绘制教程)。

地形布局建议（第一关「装束之祠」）：

- 主地面：从 x=0 到 x=1000，y≈224（32px 网格的第 7 行）
- 左侧入口台阶：x=0~96，从 y=192 下降到 y=224
- 中段可能有小土坡（y=192 的短平台）
- 右侧鸟居附近需要留出空间
- 总宽度约 1200px

#### 步骤 4：添加平台（可选的 StaticBody2D）

如果 TileMap 不够用，可在 `Platforms` 下手动添加 StaticBody2D：

1. 右键 `Platforms` → Add Child → `StaticBody2D`
2. 添加 `CollisionShape2D` → `RectangleShape2D` → 设置 Size
3. 添加 `ColorRect` 或 `Sprite2D` 作为视觉
4. 设置 `Collision > Layer`: `3 (Environment)`

#### 步骤 5：放置收集物品

##### 在编辑器中直接操作 —— Make Unique + Local to Scene

1. 在主场景（比如你的 Items 父节点）中，选中你刚刚实例化的某个收集物品（例如 Sugi）。
2. 在 **Scene 树** 里右键这个实例 → **Editable Children**（可编辑子节点），让它展开。
3. 展开后选中里面的 **Sprite**（或叫 ItemSprite、Visual 等）节点。
4. 在 **Inspector** 面板里找到 **Texture** 属性。
5. 点击 Texture 旁边的下拉箭头 → **Make Unique**（或直接在 Texture 资源上右键 → Make Unique）。
6. 然后在同一个 Texture 资源上，勾选 **Local to Scene**（本地到场景）。

7. 右键 `Items` → **Instance Child Scene** → `collectible_item.tscn`
8. 杉木 - 命名 `Sugi`：
   - `Item Id`: `sugi_wood`
   - Position: `(200, 200)` — 在地面附近
   - 更改 `Visual/ItemSprite` Texture → `item_sugi_wood.png`
9. 白毛 - 命名 `WhiteFur`：
   - `Item Id`: `white_fur`
   - Position: `(450, 180)` — 稍高处
   - Texture → `item_white_fur.png`
10. 蓬草 - 命名 `Mugwort`：
    - `Item Id`: `mugwort`
    - Position: `(700, 200)`
    - Texture → `item_mugwort.png`

> **收集顺序提示**：祭坛验证从栈底到栈顶。第一关正确顺序 = `[sugi_wood, white_fur, mugwort]`（bottom→top）。
> 先收集的 push 到栈底，所以玩家应该先收集 `sugi_wood`，再 `white_fur`，最后 `mugwort`。请安排关卡路线让玩家自然按此顺序遇到物品。

#### 步骤 6：放置叙事节点

1. **老人 NPC**：右键 `Narrative` → Instance → `npc_elder.tscn`
   - Position: `(100, 190)` — 关卡入口处
   - 对话由 `level_1.gd` 在代码中设置（可日后添加代码）

2. **石碑1**：Instance → `stone_tablet.tscn`，命名 `Tablet1`
   - Position: `(300, 200)`
   - `Tablet Text`: `此处乃送狐古道之始。\n行者须依序奉上三道供物。\n杉木为底，白毛覆身，蓬草盖顶。`

3. **石碑2**：Instance → `stone_tablet.tscn`，命名 `Tablet2`
   - Position: `(550, 200)`
   - `Tablet Text`: `狐上山，不回头；\n若回头，就莫再唤其名。`

4. **石碑3**：Instance → `stone_tablet.tscn`，命名 `Tablet3`
   - Position: `(1000, 200)`
   - `Tablet Text`: `白狐乃神使，引灵路之灯。\n行送狐之仪者，不可出声。`

5. **祭坛**：Instance → `altar.tscn`
   - 命名 `Altar`
   - Position: `(900, 200)`
   - `Level`: `1`

#### 步骤 7：装饰物

1. 在 `Decorations` 下添加 `Sprite2D`，命名 `Torii`
   - Texture: `assets/sprites/objects/torii.png`
   - Position: `(950, 185)` — 祭坛后方
2. 添加 `Sprite2D` + `PointLight2D` 组合做石灯笼：
   - Sprite2D → Texture: `stone_lantern.png`，Position: `(850, 210)`
   - PointLight2D 作为 Sprite2D 的子节点 → Texture: `warm_light.png`
     - Color: `Color(0.8, 0.6, 0.3, 0.5)`, Energy: `0.4`, Position: `(0, -10)`

#### 步骤 8：HUD

右键 `Level1` → Instance Child Scene → `hud.tscn`

#### 步骤 9：音频播放器

在 `Level1` 下添加 3 个 `AudioStreamPlayer`（不需要设置 Stream，代码在 `_on_level_ready()` 中设置）：

1. `BGM` (AudioStreamPlayer)
2. `Ambience` (AudioStreamPlayer) — Volume: `-10` dB
3. `SFX` (AudioStreamPlayer)

#### 步骤 10：视差背景

参见 [第19节](#19-视差背景搭建教程)。

#### 步骤 11：保存并测试

`Ctrl+S` → `F5` 运行

### 13.3 关于脚本中的节点引用

脚本中有：

```gdscript
@onready var _altar_ref: Area2D = $Narrative/Altar
```

这要求你在编辑器中将祭坛放在 `Narrative` 节点下，且命名为 `Altar`。如果你的命名或层级不同，请相应修改脚本中的节点路径。

---

## 14. 第二关 (level_2.tscn)

> 文件：`scenes/levels/level_2.tscn`
> 脚本：`scenes/levels/level_2.gd`（继承 `LevelBase`）

### 14.1 节点树

```
Level2 (Node2D)                          ← 脚本：level_2.gd
├── ParallaxBackground                   ← 视差背景（见第19节）
│   ├── SkyLayer (ParallaxLayer)
│   ├── MountainLayer (ParallaxLayer)
│   ├── TreeLayer (ParallaxLayer)
│   └── FogLayer (ParallaxLayer)
├── TileMapLayer                         ← forest_tileset（需要配置）
├── Platforms (Node2D)
│   ├── HiddenPlatform (StaticBody2D)    ← 铃绳拉下后才显现的隐藏平台
│   └── BridgeMarker (Marker2D)          ← 搭桥位置标记（无碰撞，纯位置）
├── Player ← 实例化 player.tscn
├── Items (Node2D)
│   ├── Sugi1 (CollectibleItem)          ← item_id="sugi_wood"（用于搭桥）
│   ├── Sugi2 (CollectibleItem)          ← item_id="sugi_wood"（用于祭坛底层）
│   ├── WhiteFur (CollectibleItem)       ← item_id="white_fur"
│   └── WaterGrass (CollectibleItem)     ← item_id="water_grass"（隐藏平台上）
├── Narrative (Node2D)
│   ├── BellRope (BellRope)              ← 铃绳场景实例
│   ├── Tablet1 (StoneTablet)
│   ├── Tablet2 (StoneTablet)
│   ├── Tablet3 (StoneTablet)
│   └── Altar (Altar)                    ← level=2
├── Decorations (Node2D)
│   ├── Torii (Sprite2D)
│   ├── Lantern1 (Sprite2D + PointLight2D)
│   └── Lantern2 (Sprite2D + PointLight2D)
├── HUD ← 实例化 hud.tscn
├── BGM (AudioStreamPlayer)
├── Ambience (AudioStreamPlayer)
└── SFX (AudioStreamPlayer)
```

> **为何有两个 sugi_wood？**
> 脚本的搭桥解谜会消耗御供筒顶层的 `sugi_wood`（`GameManager.pop_offering()`）。
> 因此玩家需要先拾取 Sugi1 → 用于搭桥（消耗）→ 再拾取 Sugi2 + 白毛 + 清水草放入祭坛。
> 祭坛正确顺序（底→顶）：`[sugi_wood, white_fur, water_grass]`。

### 14.2 逐步操作

#### 步骤 1：基础结构

1. 打开 `scenes/levels/level_2.tscn`
2. 根节点已有 `Level2 (Node2D)` + `TileMapLayer`，脚本已挂载 `level_2.gd`
3. 在根节点下添加以下空 `Node2D` 容器（保持组织清晰）：
   - `Platforms` (Node2D)
   - `Items` (Node2D)
   - `Narrative` (Node2D)
   - `Decorations` (Node2D)

#### 步骤 2：放置玩家

1. 右键 `Level2` → **Instance Child Scene** → 选择 `player.tscn`
2. 命名节点为 `Player`
3. **Position**: `(50, 235)` — 关卡左侧起始位置（与 TileMap 地面 y=224 对齐）
4. 选中 `Player` 下的 `Camera` 节点，调整相机边界：
   - **Limit > Left**: `-100`
   - **Limit > Right**: `2600`（比第一关更宽）
   - **Limit > Top**: `-500`
   - **Limit > Bottom**: `300`

#### 步骤 3：绘制 TileMap 地形（forest_tileset）

参见 [第18节 TileMap 绘制教程](#18-tilemap-绘制教程)。

第二关「断参道」地形布局（总宽约 1500px，38 列 × 32px）：

```
X=0                X=352     X=416     X=640    X=832     X=1248   X=1500
│                  │         │         │        │         │        │
│───地面起步区────│  断崖  │──参道中段──│─铃绳区─│─隐藏平台区─│──祭坛区──│
│  平坦，有石阶   │ gap≈64px │          │  铃绳  │（隐藏平台）│  终点祭坛  │
│  y=224 地面     │无TileMap │          │        │ y=160平台 │  鸟居+祭坛 │
```

具体绘制建议：

- **主地面**（y=224，Row 7）：从 x=0 到 x=352（11 列），间断，再从 x=416 到 x=1500 继续
- **断崖区域**（x=352~416）：此处**不绘制**任何地面瓦片，留出 64px 宽的空隙
- **断崖边缘**：x=320~352 右边用 (4,0) 右上角瓦片做悬崖边；x=416~448 左边用 (3,0) 左上角
- **铃绳区墙壁**（x=640~672）：垂直叠放 2 格 (2,1) 左壁或 (0,3) 木墙，作为挂铃绳的建筑侧面
- **隐藏平台区**（x=736~864，y=160）：暂时不铺瓦片（代码在铃绳触发后动态创建桥并显示 HiddenPlatform）

#### 步骤 4：配置 Platforms 容器中的特殊节点

##### HiddenPlatform（铃绳触发后显现）

1. 右键 `Platforms` → **Add Child Node** → `StaticBody2D`，命名 `HiddenPlatform`
2. 添加子 `CollisionShape2D`：
   - **Shape**: New RectangleShape2D → **Size**: `(128, 16)`
   - **Position**: `(0, 0)`
3. 添加子 `ColorRect` 做视觉：
   - **Size**: `(128, 16)`
   - **Position**: `(-64, -8)`
   - **Color**: `Color(0.50, 0.34, 0.20, 1.0)` — 木色
4. 设置 StaticBody2D：
   - **Collision > Layer**: 勾选 `3 (Environment)`
   - **Collision > Mask**: 全部取消
   - **Transform > Position**: `(1000, 210)` — 铃绳右侧上方的隐藏夹层平台
5. **不需要手动隐藏**：脚本 `_on_level_ready()` 会自动将其设为 `visible=false` 并禁用

##### BridgeMarker（搭桥交互检测点）

1. 右键 `Platforms` → **Add Child Node** → `Marker2D`，命名 `BridgeMarker`
2. **Transform > Position**: `(384, 220)` — 正好在断崖中间
3. 此节点无碰撞、无视觉，仅作为空间坐标参考（脚本检测玩家距此点 < 30px 时允许搭桥）

#### 步骤 5：放置收集物品

> 关键：玩家需按 **Sugi1 → 搭桥消耗 → Sugi2 → WhiteFur → WaterGrass** 的顺序推进，确保祭坛获得正确的栈 `[sugi_wood, white_fur, water_grass]`。

##### 在编辑器中放置步骤（每个物品）：

1. 右键 `Items` → **Instance Child Scene** → `collectible_item.tscn`
2. 设置实例 Inspector 中的 `Item Id` 属性
3. 右键该实例 → **Editable Children** 展开，选中 `Visual/ItemSprite`
4. Texture 旁点击下拉箭头 → **Make Unique** → 勾选 **Local to Scene**
5. 重新选择对应物品的 .png

##### 各物品放置位置：

| 节点名       | item_id       | Position      | Texture                | 说明                             |
| ------------ | ------------- | ------------- | ---------------------- | -------------------------------- |
| `Sugi1`      | `sugi_wood`   | `(160, 200)`  | `item_sugi_wood.png`   | 断崖左侧，玩家必经路线上         |
| `Sugi2`      | `sugi_wood`   | `(512, 200)`  | `item_sugi_wood.png`   | 过桥后第一个发现的物品           |
| `WhiteFur`   | `white_fur`   | `(720, 196)`  | `item_white_fur.png`   | 铃绳左侧墙边                     |
| `WaterGrass` | `water_grass` | `(1000, 130)` | `item_water_grass.png` | 隐藏平台上（铃绳拉响后才能到达） |

#### 步骤 6：放置叙事节点

##### 铃绳 (BellRope)

1. 右键 `Narrative` → **Instance Child Scene** → `bell_rope.tscn`
2. 命名为 `BellRope`
3. **Position**: `(656, 160)` — 靠近右壁的悬挂位置（确保在 TileMap 墙壁旁边）
4. 脚本引用路径：`$Narrative/BellRope`

##### 石碑

1. **Tablet1**：右键 `Narrative` → Instance → `stone_tablet.tscn`
   - **Position**: `(128, 200)`
   - `Tablet Text`: `此处为断参道。\n昔年山洪冲毁，参道一截为二。\n仪式中断多年，神灯由此熄灭。`
   - `Speaker Name`: `石碑`

2. **Tablet2**：Instance → `stone_tablet.tscn`
   - **Position**: `(300, 200)`
   - `Tablet Text`: `过此断崖者，须以承托之物搭桥。\n——杉木坚实，可托万物。\n然祭坛亦需此物为底，莫要用尽。`
   - `Speaker Name`: `石碑`

3. **Tablet3**：Instance → `stone_tablet.tscn`
   - **Position**: `(880, 200)`
   - `Tablet Text`: `此处曾有隐门。\n铃声一响，门开一道缝。\n仪式所需之物，藏于其内。`
   - `Speaker Name`: `石碑`

##### 祭坛

1. 右键 `Narrative` → Instance → `altar.tscn`，命名 `Altar`
2. **Position**: `(1344, 200)`
3. **Level**: `2`
4. 脚本引用路径：`$Narrative/Altar`

> **收集顺序提示**：祭坛验证从栈底到栈顶。  
> 第二关正确顺序 = `[sugi_wood, white_fur, water_grass]`（bottom→top）。  
> 玩家收集 Sugi2（桥后）→ WhiteFur → WaterGrass（隐藏平台），顺序恰好正确。

#### 步骤 7：装饰物

1. 在 `Decorations` 下添加 `Sprite2D`，命名 `Torii`
   - **Texture**: `assets/sprites/objects/torii.png`
   - **Position**: `(64, 186)` — 关卡入口处
2. 添加石灯笼 × 2（在参道两侧成对放置）：
   - 每个灯笼由 `Sprite2D` + 子 `PointLight2D` 组成
   - **Sprite2D Texture**: `stone_lantern.png`
   - 位置参考：`(256, 208)` 和 `(960, 208)`
   - **PointLight2D**（作为 Sprite2D 的子节点）：
     - Texture: `warm_light.png`
     - Color: `Color(0.8, 0.6, 0.3, 0.5)`, Energy: `0.4`, Scale: `1.2`
     - Position: `(0, -10)`
3. （可选）在铃绳墙壁上方添加 `Sprite2D` 用鸟居横梁瓦片做建筑感（非碰撞纯装饰）

#### 步骤 8：HUD

右键 `Level2` → **Instance Child Scene** → `hud.tscn`

#### 步骤 9：音频播放器

在 `Level2` 下添加 3 个 `AudioStreamPlayer`（Stream 由脚本代码设置，不需在 Inspector 手动指定）：

1. `BGM` (AudioStreamPlayer) — 脚本会加载 `forest_night.wav`
2. `Ambience` (AudioStreamPlayer) — 脚本会加载 `night_insects.wav`；手动设置 **Volume dB**: `-10`
3. `SFX` (AudioStreamPlayer)

#### 步骤 10：视差背景

参见 [第19节 · 森林夜景配置](#19-视差背景搭建教程)，与第一关配置完全相同（sky / far_mountains / near_trees / fog）。

`ParallaxBackground` 节点须位于场景树中 `TileMapLayer` **上方**（先于地面渲染）。

#### 步骤 11：检查脚本节点路径

第二关脚本 `level_2.gd` 中的 `@onready` 引用如下，对应编辑器中的节点命名**必须完全一致**：

```gdscript
@onready var _altar_ref:       Area2D       = $Narrative/Altar
@onready var _bell_ref:        Area2D       = $Narrative/BellRope
@onready var _hidden_platform: StaticBody2D = $Platforms/HiddenPlatform
@onready var _bridge_marker:   Marker2D     = $Platforms/BridgeMarker
```

| 脚本引用           | 对应节点路径               | 节点类型     |
| ------------------ | -------------------------- | ------------ |
| `_altar_ref`       | `Narrative/Altar`          | Area2D       |
| `_bell_ref`        | `Narrative/BellRope`       | Area2D       |
| `_hidden_platform` | `Platforms/HiddenPlatform` | StaticBody2D |
| `_bridge_marker`   | `Platforms/BridgeMarker`   | Marker2D     |

#### 步骤 12：保存并测试

`Ctrl+S` → `F6` 运行当前场景。

测试清单：

- [ ] 玩家可正常行走至断崖
- [ ] 拾取 Sugi1 后靠近 BridgeMarker，按 E 可触发对话并生成桥
- [ ] 桥生成后可跨越断崖
- [ ] 拾取 Sugi2、WhiteFur
- [ ] 靠近铃绳按 E，铃绳触发，HiddenPlatform 淡入显现
- [ ] 可跳上 HiddenPlatform 拾取 WaterGrass
- [ ] 到达祭坛，御供筒顺序正确时祭坛接受供物
- [ ] 分支选择面板弹出（清水草 vs 灯芯油）

### 14.3 地形设计建议（补充）

- **断崖宽度**：精确控制在 60~64px（2 格），玩家无法直接跳过，必须搭桥
- **铃绳位置**：放在断崖右侧约 240px 处，玩家过桥后自然看到
- **隐藏平台高度**：比主地面高 64px（y=160 vs y=224），需要一次跳跃到达
- **WaterGrass 位置**：放在隐藏平台上且稍偏内侧，视觉上不容易一眼看到
- **祭坛前留白**：祭坛前方 200px 内不放障碍物，给玩家安静确认供物顺序的空间

---

## 15. 第三关 (level_3.tscn)

> 文件：`scenes/levels/level_3.tscn`
> 脚本：`scenes/levels/level_3.gd`（继承 `LevelBase`）

### 15.1 节点树

```
Level3 (Node2D)                          ← 脚本：level_3.gd
├── ParallaxBackground                   ← 神社内部风格（见第19节）
│   ├── ShrineLayer (ParallaxLayer)
│   └── FogLayer (ParallaxLayer)
├── TileMapLayer                         ← shrine_tileset（需要配置）
├── Platforms (Node2D)                   ← 额外碰撞平台（内殿高台等）
│   └── InnerSanctum (StaticBody2D)      ← 本殿高台（玩家可站立）
├── Player ← 实例化 player.tscn
├── Narrative (Node2D)
│   ├── ArchiveTrigger1 (Area2D)         ← 档案触发区 1（带 CollisionShape2D）
│   ├── ArchiveTrigger2 (Area2D)         ← 档案触发区 2
│   ├── ArchiveTrigger3 (Area2D)         ← 档案触发区 3
│   ├── ArchiveTrigger4 (Area2D)         ← 档案触发区 4
│   └── ArchiveTrigger5 (Area2D)         ← 档案触发区 5
├── Decorations (Node2D)
│   ├── Torii (Sprite2D)                 ← 入口鸟居
│   ├── Pillar1 (Sprite2D)               ← 回廊朱柱
│   ├── Pillar2 (Sprite2D)
│   ├── Pillar3 (Sprite2D)
│   ├── PaperDoor1 (Sprite2D)            ← 障子（纸门）
│   ├── PaperDoor2 (Sprite2D)
│   ├── Lantern1 (Sprite2D + PointLight2D)
│   ├── Lantern2 (Sprite2D + PointLight2D)
│   ├── Lantern3 (Sprite2D + PointLight2D)
│   ├── ShamiNote (Sprite2D)             ← 注連縄装饰（悬于内殿入口）
│   └── Plaque (Sprite2D)               ← 匾额（位于 x≈900，y≈70）
├── HUD ← 实例化 hud.tscn
├── BGM (AudioStreamPlayer)
├── Ambience (AudioStreamPlayer)
└── SFX (AudioStreamPlayer)
```

> **第三关没有收集物品。** 核心玩法是探索→发现档案→真相揭示→最终选择。

### 15.2 逐步操作

#### 步骤 1：基础结构

1. 打开 `scenes/levels/level_3.tscn`
2. 根节点已有 `Level3 (Node2D)` + `TileMapLayer`，脚本已挂载 `level_3.gd`
3. 在根节点下添加以下空 `Node2D` 容器：
   - `Platforms` (Node2D)
   - `Narrative` (Node2D)
   - `Decorations` (Node2D)

#### 步骤 2：放置玩家

1. 右键 `Level3` → **Instance Child Scene** → 选择 `player.tscn`
2. 命名节点为 `Player`
3. **Position**: `(40, 235)` — 关卡左侧起始点
4. 选中 `Player` 下的 `Camera` 节点，调整相机边界：
   - **Limit > Left**: `-100`
   - **Limit > Right**: `1400`
   - **Limit > Top**: `-200`（需要能看到高台上方）
   - **Limit > Bottom**: `300`

#### 步骤 3：配置 shrine_tileset 并绘制 TileMap 地形

##### 3-1：创建 shrine_tileset 资源

第三关需要使用 `shrine_tileset.tres`。若尚未存在，步骤如下：

1. 选中场景中的 `TileMapLayer` 节点
2. 在 Inspector 中，找到 **Tile Set** 属性 → 点击 `<empty>` → **New TileSet**
3. 在底部 **TileSet 编辑器** 中点击 ➕ → **Add Atlas Source**
4. 在弹出的文件选择中选择 `assets/tilesets/shrine_tileset.png`
5. 设置 **Tile Size**: `32 × 32`，Separation/Margin: `0`
6. 点击 **Inspector** 右上角的保存图标，将 TileSet 保存为 `assets/tilesets/shrine_tileset.tres`
7. 为需要碰撞的瓦片添加 Physics Layer（参见 [第18节 18.3 & 18.4](#18-tilemap-绘制教程)）

##### 3-2：第三关地形布局（总宽约 1200px，参道+本殿）

第三关「本社·不返之灯」是一座横向展开的神社建筑，分为三个区域：

```
X=0         X=480       X=704       X=864      X=960      X=1200
│           │           │           │          │          │
│──外参道──│──回廊走廊──│──石阶上升──│──本殿高台──│──内殿深处──│
│ 地面y=224 │  地面y=224 │ 阶梯y下降  │  地面y=80  │  地面y=80  │
│           │            │ 至y=80    │  匾额在此  │            │
```

**外参道**（x=0~480，y=224）：

- 主地面：用 (5,0) 石板地 + (0,0)(1,0) 木板地 交替铺设，体现不同材质区域
- 两侧 TileMap 地面下方用 (0,1)(1,1) 木壁填充
- 顶部（y≤192）铺 (0,3)(1,3) 瓦屋顶 A/B，模拟廊道屋顶边缘

**回廊走廊**（x=480~704，y=224）：

- 地面全部用 (2,0)(3,0) 畳 A/B 交替，体现室内榻榻米
- 两侧间隔放 (4,1) 朱柱、(5,1) 木柱瓦片（垂直 2-3 格）
- 中间装饰 (2,1)(3,1) 障子（纸门），做墙体区分

**石阶区域**（x=704~864，y 从 224 降至 80）：

- 用 (5,4)(6,4) 階段 A/B 交替、垂直叠放约 5 行，搭出石阶
- 石阶两侧用 (4,1)(5,1) 朱柱/木柱做扶手支撑感
- 注意：石阶需要在 TileSet 中设置完整碰撞，玩家才能踩上去

**本殿高台**（x=864~1200，y=80）：

- 地面全部用 (4,0) 暗木地板，体现最神圣的内部区域
- 两侧用 (6,1)(7,1) 朱壁 A/B 做墙体，上方配 (0,2)(1,2) 漆喰壁
- 入口处（x=864）放 (5,3) 注連縄+紙垂（2 格横向）
- 深处（x=1100~1200）放 (3,4) 神棚 + (4,4) 御幣 组合
- 匾额**不用** TileMap 绘制，用 Decorations 下的独立 Sprite2D（见步骤 7）

#### 步骤 4：配置本殿高台碰撞（InnerSanctum）

TileMap 的石阶+高台区域应已通过 shrine_tileset 的 Physics Layer 提供碰撞。  
若需要补充或调整，可在 `Platforms` 下添加额外 StaticBody2D：

1. 右键 `Platforms` → Add Child → `StaticBody2D`，命名 `InnerSanctum`
2. 添加子 `CollisionShape2D`：
   - **Shape**: New RectangleShape2D → **Size**: `(352, 32)`
   - **Position**: `(0, 0)`
3. **Collision > Layer**: 勾选 `3 (Environment)`
4. **Transform > Position**: `(1040, 80)` — 高台地面（碰撞体上边缘 = y=64，玩家踩此处时 `position.y≈64~80` < 87.5 ✓）
5. 此 StaticBody2D **不添加视觉节点**，视觉由 TileMap 负责

> **与脚本的关联**：  
> 脚本检测 `player.position.y < 87.5` 来判断玩家是否在本殿高台上。  
> 确保高台碰撞体上边缘在 y=64 附近，玩家站立时 `position.y ≈ 64~80`，满足条件。

#### 步骤 5：放置 5 个档案触发区域（ArchiveTrigger）

脚本引用：

```gdscript
@onready var _archive_triggers: Array[Area2D] = [
    $Narrative/ArchiveTrigger1,
    $Narrative/ArchiveTrigger2,
    $Narrative/ArchiveTrigger3,
    $Narrative/ArchiveTrigger4,
    $Narrative/ArchiveTrigger5,
]
```

每个 ArchiveTrigger 的创建步骤（以 ArchiveTrigger1 为例，其余相同）：

1. 右键 `Narrative` → **Add Child Node** → `Area2D`，命名 `ArchiveTrigger1`
2. 在检视器中设置 Area2D：
   - **Collision > Layer**: 全部取消
   - **Collision > Mask**: 勾选 `1 (Player)`
   - **Monitoring**: ✓（确保开启才能检测 body_entered）
3. 右键 `ArchiveTrigger1` → **Add Child Node** → `CollisionShape2D`
   - **Shape**: New RectangleShape2D → **Size**: `(28, 40)`
4. 重复以上步骤创建 ArchiveTrigger2~5，按下表放置位置：

| 节点名          | Position     | 所在区域           | 说明                                 |
| --------------- | ------------ | ------------------ | ------------------------------------ |
| ArchiveTrigger1 | `(200, 204)` | 外参道入口段       | 描述此地的来历（较轻松的叙述）       |
| ArchiveTrigger2 | `(440, 204)` | 外参道中段         | 关于村子送狐仪式的记载               |
| ArchiveTrigger3 | `(600, 204)` | 回廊走廊           | 提及某年有个孩子「被送走」           |
| ArchiveTrigger4 | `(960, 40)`  | 本殿高台（入口处） | 仪式装束的详细记录（白衣/杉木/蓬草） |
| ArchiveTrigger5 | `(1100, 40)` | 本殿高台（内殿）   | 最后一条记录，揭示仪式的真实性质     |

> 触发全部 5 个区域后，脚本自动播放「真相揭示」对话序列，提示玩家去与匾额交互。

#### 步骤 6：为每个档案触发区添加可视标记（可选但推荐）

在开发阶段，给每个 ArchiveTrigger 添加一个微弱的视觉指示，方便调试：

1. 选中某个 ArchiveTrigger 节点
2. 右键 → **Add Child Node** → `Sprite2D` 或 `PointLight2D`
   - 若用 Sprite2D：Texture = `assets/sprites/effects/particle.png`，Modulate Alpha = 0.5
   - 若用 PointLight2D：Texture = `warm_light.png`，Energy = 0.2，Color = 淡金色
3. 此标记是开发辅助，游戏上线前可删除或隐藏

#### 步骤 7：放置装饰物

##### 入口鸟居

1. 在 `Decorations` 下添加 `Sprite2D`，命名 `Torii`
   - **Texture**: `assets/sprites/objects/torii.png`

##### 朱柱（TileMap 内已有，这里补充作为独立精灵的选项）

若不想在 TileMap 上绘制柱子，可在 Decorations 下添加单独的 Sprite2D 节点并使用 shrine_tileset 精灵（截取对应 tile 区域）。建议间隔 128px 放置一对柱子。

##### 纸门（Sprite2D）

- 在 `Decorations` 下添加 2 个 `Sprite2D`，命名 `PaperDoor1`、`PaperDoor2`
- 放置在回廊与高台之间的分界处（x≈858）
- 使用 shrine_tileset 截取的障子图，或统一用 TileMap 绘制

##### 提灯（石灯笼 × 3，带光源）

每个提灯由 `Sprite2D` + 子 `PointLight2D` 组成：

| 节点名   | Position     | 颜色（PointLight2D）        | Energy |
| -------- | ------------ | --------------------------- | ------ |
| Lantern1 | `(192, 208)` | `Color(0.9, 0.7, 0.3, 0.6)` | 0.5    |
| Lantern2 | `(576, 208)` | `Color(0.9, 0.7, 0.3, 0.6)` | 0.5    |
| Lantern3 | `(960, 64)`  | `Color(1.0, 0.8, 0.4, 0.8)` | 0.7    |

- Sprite2D Texture: `assets/sprites/objects/stone_lantern.png`
- PointLight2D Texture: `assets/sprites/effects/warm_light.png`，Scale: `1.2`，Position: `(0, -10)`

##### 注連縄（ShamiNote）

1. 在 `Decorations` 下添加 `Sprite2D`，命名 `ShamiNote`
   - **Texture**: 使用 shrine_tileset.png 中 (5,3) 注連縄+紙垂 的截取图，或直接使用 TileMap 绘制装饰层
   - **Position**: `(864, 48)` — 悬挂于本殿入口上方

##### 匾额（Plaque）⭐ 重要

匾额是第三关的核心交互点，脚本通过位置检测触发最终剧情：

```gdscript
# level_3.gd 中的检测条件
if player.position.x > 875 and player.position.x < 925:
    if player.position.y < 87.5 and Input.is_action_just_pressed("interact"):
```

1. 在 `Decorations` 下添加 `Sprite2D`，命名 `Plaque`
   - **Texture**: 使用 shrine_tileset.png 中 (2,4) 匾額 对应的截取图，或占位图
   - **Position**: `(900, 16)` — 挂在本殿深处墙上，x=875~925 范围内，y 小于 87.5 的区域
2. 确保玩家在游戏中可以走到 `(875<x<925, y<87.5)` 的坐标范围内（即本殿高台地板上）

> **白狐生成位置**：脚本在匾额交互后调用 `spawn_fox(Vector2(950, 62.5), 0)` 动态生成白狐。  
> 不需要在编辑器中手动放置白狐场景，代码会自动处理。

#### 步骤 8：HUD

右键 `Level3` → **Instance Child Scene** → `hud.tscn`

#### 步骤 9：音频播放器

在 `Level3` 下添加 3 个 `AudioStreamPlayer`（Stream 由脚本代码设置）：

1. `BGM` (AudioStreamPlayer) — 脚本加载 `shrine_theme.wav`
2. `Ambience` (AudioStreamPlayer) — 脚本加载 `night_insects.wav`；手动设置 **Volume dB**: `-10`
3. `SFX` (AudioStreamPlayer)

#### 步骤 10：视差背景（神社内部风格）

参见 [第19节 · 神社内部配置](#19-视差背景搭建教程)：

1. 在 `Level3` 下添加 `ParallaxBackground`（放在 TileMapLayer 上方）
2. 添加 `ParallaxLayer` 命名 `ShrineLayer`：
   - 在其下添加 `Sprite2D`，Texture: `shrine_interior.png`，Position: `(240, 150)`
   - ParallaxLayer **Motion Scale**: `(0.1, 0.05)`
3. 添加 `ParallaxLayer` 命名 `FogLayer`：
   - Sprite2D Texture: `fog.png`，Position: `(240, 150)`
   - Motion Scale: `(0.2, 0.0)`

#### 步骤 11：检查脚本节点路径

第三关脚本 `level_3.gd` 中的 `@onready` 引用如下，对应节点命名**必须完全一致**：

```gdscript
@onready var _archive_triggers: Array[Area2D] = [
    $Narrative/ArchiveTrigger1,
    $Narrative/ArchiveTrigger2,
    $Narrative/ArchiveTrigger3,
    $Narrative/ArchiveTrigger4,
    $Narrative/ArchiveTrigger5,
]
```

| 脚本引用               | 对应节点路径                | 节点类型 |
| ---------------------- | --------------------------- | -------- |
| `_archive_triggers[0]` | `Narrative/ArchiveTrigger1` | Area2D   |
| `_archive_triggers[1]` | `Narrative/ArchiveTrigger2` | Area2D   |
| `_archive_triggers[2]` | `Narrative/ArchiveTrigger3` | Area2D   |
| `_archive_triggers[3]` | `Narrative/ArchiveTrigger4` | Area2D   |
| `_archive_triggers[4]` | `Narrative/ArchiveTrigger5` | Area2D   |

> 匾额交互（`_process` 中的位置检测）和白狐生成（`spawn_fox`）**不依赖编辑器节点路径**，均为纯代码逻辑，无需额外配置。

#### 步骤 12：保存并测试

`Ctrl+S` → `F6` 运行当前场景。

测试清单：

- [ ] 玩家可从外参道走到回廊再走到石阶
- [ ] 石阶可正常上下行走（碰撞正确）
- [ ] 站上本殿高台后 `player.position.y < 87.5` 成立（调试时在 Remote 面板观察 Player 的 position.y）
- [ ] 走进每个 ArchiveTrigger 区域都有对应对话触发，且触发一次后消失（`queue_free`）
- [ ] 集齐全部 5 个档案后出现「真相揭示」对话序列
- [ ] 真相揭示完成后，在 x=875~925、y<87.5 区域按 E 触发匾额交互
- [ ] 最终选择面板弹出（沉默 vs 叫出名字）
- [ ] 选择后跳转到对应结局场景

### 15.3 地形设计建议（补充）

- **神社空间感**：回廊走廊部分（畳地板）建议在 TileMap 上方再画 1~2 行瓦屋顶瓦片（(0,3)/(1,3)），让玩家感受到被建筑包裹，与开放式外参道形成对比
- **石阶过渡**：石阶区域的每一阶高度约 16px（半格），宽度 32px，共 9~10 阶，从 y=224 升至 y=80，横向距离约 160px
- **本殿高度差**：本殿高台与外参道地面之间的 144px 高度差应在视觉上清晰可见，建议在石阶侧面用朱壁/木壁瓦片填充，不留空洞
- **档案触发区间距**：5 个触发区尽量均匀分布在整个关卡长度上，避免集中，让玩家有充足的探索时间
- **光照氛围**：本殿高台区域光线应比外参道更暗，可通过减少 PointLight2D 密度或降低 Energy 值体现「幽暗内殿」的感觉

---

## 16. 结局A场景 (ending_a.tscn)

> 文件：`scenes/cutscenes/ending_a.tscn`
> 脚本：`scenes/cutscenes/ending_a.gd`

### 16.1 节点树

```
EndingA (Control)              ← Full Rect，已有
└── Background (ColorRect)     ← 纯黑底
```

### 16.2 操作

1. 打开 `ending_a.tscn`
2. 在 `EndingA` 下添加 `ColorRect`，命名 `Background`
   - Anchors Preset: Full Rect
   - Color: `Color(0.02, 0.01, 0.04, 1)`
3. 保存

> 结局场景的所有文字/特效都由脚本在运行时动态创建（Label 淡入淡出序列），不需要预先在编辑器中放置。

---

## 17. 结局B场景 (ending_b.tscn)

> 文件：`scenes/cutscenes/ending_b.tscn`
> 脚本：`scenes/cutscenes/ending_b.gd`

### 17.1 节点树

```
EndingB (Control)
└── Background (ColorRect)
```

### 17.2 操作

同结局A。添加 `ColorRect` Background，Color: `Color(0.02, 0.01, 0.04, 1)`，Anchors Preset: Full Rect。

---

## 18. TileMap 绘制教程

### 18.1 TileSet 配置（通用步骤）

`assets/tilesets/forest_tileset.tres` 已存在。如果你需要配置新 TileSet（例如为神社创建 `shrine_tileset.tres`）：

1. 在 FileSystem 面板中，选中瓦片图 .png 文件
2. 检查 Import 设置（双击 .import 文件或在 Import 选项卡中）：
   - Filter: **Nearest**
   - Repeat: Disabled
3. 打开需要 TileMap 的关卡场景
4. 如果场景中已有 `TileMapLayer`（如 level_1），选中它
5. 如果需要新建 TileMapLayer：Add Child → TileMapLayer
6. 在检视器中设置/创建 **Tile Set** 资源
7. 在 TileSet 编辑面板（底部）中：
   - 点击 ➕ 添加 Atlas 源
   - 选择 .png 瓦片图
   - **Tile Size**: `32 × 32`
   - Separation/Margin: `0`
8. Atlas 加载后你将看到 8 列 × 5 行 = 40 个瓦片格。

### 18.2 森林 TileSet 配置详解 (forest_tileset)

> 适用于 Level 1 和 Level 2。

#### 需要碰撞的瓦片（必须设置 Physics Layer）

以下瓦片为**实心地面/墙壁**，角色会站在上面或被它阻挡，必须添加碰撞：

| 位置       | 名称          | 碰撞区域     |
| ---------- | ------------- | ------------ |
| (0,0)(1,0) | 草地A/B       | 整个 32×32   |
| (2,0)      | 平台顶部      | 整个 32×32   |
| (3,0)(4,0) | 左上角/右上角 | 整个 32×32   |
| (5,0)      | 土地          | 整个 32×32   |
| (6,0)(7,0) | 石砖A/B       | 整个 32×32   |
| (0,1)(1,1) | 草地填充      | 整个 32×32   |
| (2,1)(3,1) | 左壁/右壁     | 整个 32×32   |
| (4,1)(5,1) | 木桥A/B       | 上半部 32×16 |
| (6,1)(7,1) | 石阶A/B       | 整个 32×32   |
| (0,3)      | 木墙          | 整个 32×32   |

#### 单向平台（特殊碰撞）

| 位置  | 名称     | 碰撞区域    | 设置                         |
| ----- | -------- | ----------- | ---------------------------- |
| (0,4) | 单向平台 | 上边缘 32×4 | Physics Layer → One Way = ON |

#### 纯装饰瓦片（不需要碰撞）

(0,2)-(3,2) 鸟居、(4,2)-(5,2) 石灯笼、(6,2) 灌木、(7,2) 蘑菇、(1,3) 纸门、(2,3) 柱子、(3,3) 瓦屋顶、(1,4) 绳索、(2,4) 铃铛、(3,4) 注连绳

#### 绘制建议

- **地面**：先用 (0,0) 和 (1,0) 交替铺一行作为地表，下方用 (0,1)(1,1) 填充
- **平台**：用 (2,0) 做平台顶面，(3,0)(4,0) 做两端拐角
- **墙壁**：(2,1) 左壁 + (3,1) 右壁，垂直堆叠
- **桥梁**：(4,1)(5,1) 横向连接
- **鸟居**：将 (0,2)(1,2)(2,2)(3,2) 四格组合放置（2 列 × 2 行）

### 18.3 神社 TileSet 配置详解 (shrine_tileset)

> 适用于 Level 3。需要先创建 `shrine_tileset.tres`，步骤同 18.1，但选择 `shrine_tileset.png`。

#### 需要碰撞的瓦片

| 位置        | 名称        | 碰撞区域                                   |
| ----------- | ----------- | ------------------------------------------ |
| (0,0)-(7,0) | 各类地板    | 整个 32×32                                 |
| (0,1)(1,1)  | 木壁A/B     | 整个 32×32                                 |
| (2,1)       | 障子A(完整) | 整个 32×32                                 |
| (4,1)(5,1)  | 朱柱/木柱   | 中央 8×32 (**注意：柱子碰撞只取中间窄条**) |
| (6,1)(7,1)  | 朱壁A/B     | 整个 32×32                                 |
| (0,2)(1,2)  | 漆喰壁A/B   | 整个 32×32                                 |
| (0,3)(1,3)  | 瓦屋顶A/B   | 整个 32×32                                 |
| (2,3)       | 鬼瓦        | 整个 32×32                                 |
| (7,4)       | 方石台      | 整个 32×32                                 |
| (5,4)(6,4)  | 階段A/B     | 整个 32×32                                 |

#### 单向平台（特殊碰撞）

| 位置  | 名称       | 碰撞区域    | 设置                         |
| ----- | ---------- | ----------- | ---------------------------- |
| (0,4) | 朱色单向台 | 上边缘 32×4 | Physics Layer → One Way = ON |

#### 纯装饰瓦片

(3,1) 障子B(半開)、(2,2) 欄間、(3,2)(4,2) 格子窓、(5,2) 賽銭箱、(6,2)(7,2) 苔石、(3,3)(4,3) 木天井、(5,3) 注連縄+紙垂、(6,3)(7,3) 提灯、(1,4) 燭台、(2,4) 匾額、(3,4) 神棚、(4,4) 御幣

#### 绘制建议

- **地面区分**：用 (0,0)(1,0) 木板做走廊，(2,0)(3,0) 畳做房间内部，(4,0) 暗木做重点区域，(5,0) 石板做入口
- **墙体组合**：底部 (0,1)(1,1) 木壁，上方 (0,2)(1,2) 漆喰壁，中间插入 (2,2) 欄間装饰
- **障子门**：(2,1) 关闭状态做碰撞墙，(3,1) 半开状态做装饰（暗示可通行）
- **柱子**：(4,1)(5,1) 间隔放置，分割空间感
- **屋顶**：(0,3)(1,3) 交替铺顶部边缘，(2,3) 鬼瓦放在屋脊两端
- **氛围**：角落放 (6,3)(7,3) 提灯，门口放 (5,3) 注連縄，(1,4) 燭台沿走廊间隔放置
- **神社核心**：最深处放 (3,4) 神棚 + (4,4) 御幣，前方放 (5,2) 賽銭箱

### 18.4 给瓦片添加物理碰撞（操作步骤）

1. 在 TileSet 编辑器中，选中 **Physics Layers** 标签
2. 点击 **Add Physics Layer**
3. 设置该层的 **Collision Layer**: `3 (Environment)`
4. 切换到 **Paint** 模式
5. 选择一个瓦片 → 在右侧找到 **Physics** 部分
6. 用矩形工具绘制碰撞多边形（通常为整个瓦片大小的矩形）
7. 对于**单向平台**：绘制碰撞后，勾选 **One Way** 属性
8. 对于**柱子**：碰撞多边形不要覆盖整个瓦片，只画中间窄条（约 8px 宽）
9. 对所有上方列出的「需要碰撞」瓦片重复此操作

### 18.5 绘制地形

1. 选中场景中的 `TileMapLayer`
2. 底部出现 TileMap 绘制面板
3. 选择一个瓦片
4. 用画笔工具在视口中绘制
5. 快捷键：
   - `B` 画笔
   - `R` 矩形
   - `L` 线条
   - `E` 橡皮
   - `Ctrl+Z` 撤销

### 18.6 关卡参考尺寸（480×270 视口）

| 关卡    | 建议地图宽度       | 建议地图高度      | 地面Y              |
| ------- | ------------------ | ----------------- | ------------------ |
| Level 1 | ~1200px (37 tiles) | ~300px (10 tiles) | y=224 (tile row 7) |
| Level 2 | ~1500px (47 tiles) | ~300px            | y=224              |
| Level 3 | ~1200px            | ~270px            | y=224              |

---

## 19. 视差背景搭建教程

### 19.1 创建 ParallaxBackground

1. 在关卡根节点下添加 `ParallaxBackground` 节点
2. 确保它在节点列表中位于 TileMapLayer **上方**（先渲染=在后面）

### 19.2 添加 ParallaxLayer

对每个背景层重复：

1. 右键 `ParallaxBackground` → Add Child → `ParallaxLayer`
2. 在 ParallaxLayer 下添加 `Sprite2D`（或 `TextureRect`）作为背景图片

### 19.3 森林夜景（Level 1 / Level 2）配置

| ParallaxLayer 名 | 图片              | Motion Scale | Sprite Position |
| ---------------- | ----------------- | ------------ | --------------- |
| SkyLayer         | sky.png           | `(0.0, 0.0)` | `(240, 135)`    |
| MountainLayer    | far_mountains.png | `(0.2, 0.1)` | `(240, 135)`    |
| TreeLayer        | near_trees.png    | `(0.5, 0.2)` | `(240, 135)`    |
| FogLayer         | fog.png           | `(0.3, 0.0)` | `(240, 135)`    |

> **Motion Scale** 说明：值越小，移动越慢（看起来越远）。`(0, 0)` = 完全静止的天空。

> **Sprite Position** `(240, 135)` 是 480÷2, 270÷2 —— 图片中心对齐视口中心。

### 19.4 神社内部（Level 3）

| ParallaxLayer 名 | 图片                | Motion Scale  |
| ---------------- | ------------------- | ------------- |
| ShrineLayer      | shrine_interior.png | `(0.1, 0.05)` |
| FogLayer         | fog.png             | `(0.2, 0.0)`  |

---

## 20. 游戏设计数据参考

### 20.1 物品数据 (GameManager.ITEMS)

| ID          | 名称     | 描述                                             | 颜色               | 发光 |
| ----------- | -------- | ------------------------------------------------ | ------------------ | ---- |
| sugi_wood   | 杉木     | 山间古杉的木料，坚实沉稳。承托之物。             | (0.55, 0.35, 0.2)  | ✗    |
| white_fur   | 白毛     | 洁白如雪的柔软毛皮。——还是说，那原本是「白衣」？ | (0.95, 0.93, 0.97) | ✗    |
| mugwort     | 蓬草     | 气味清烈的野草。覆于顶部，遮味避秽。             | (0.3, 0.55, 0.25)  | ✗    |
| bell_fiber  | 铃绳纤维 | 取自神社铃绳的纤维。温和地呼唤着什么。           | (0.85, 0.75, 0.55) | ✗    |
| fox_stone   | 狐火石   | 触之微温的奇石，内有火色流光。强行引燃狐火。     | (1.0, 0.6, 0.15)   | ✓    |
| water_grass | 清水草   | 生于清泉边的苔草。镇静安抚。                     | (0.4, 0.7, 0.75)   | ✗    |
| lamp_oil    | 灯芯油   | 可燃之油。能放大狐火，但火焰会变得难以控制。     | (0.75, 0.45, 0.1)  | ✓    |

### 20.2 祭坛正确顺序 (从底到顶)

| 关卡    | 底层             | 中层             | 顶层                 |
| ------- | ---------------- | ---------------- | -------------------- |
| Level 1 | sugi_wood (杉木) | white_fur (白毛) | mugwort (蓬草)       |
| Level 2 | sugi_wood (杉木) | white_fur (白毛) | water_grass (清水草) |

### 20.3 分支选择

| 关卡    | A 路线               | B 路线             |
| ------- | -------------------- | ------------------ |
| Level 1 | 铃绳纤维（温柔呼唤） | 狐火石（强行引燃） |
| Level 2 | 清水草（镇静安抚）   | 灯芯油（放大狐火） |
| Level 3 | 沉默（完成仪式）     | 叫出"纱夜"的名字   |

### 20.4 玩家物理参数

| 参数             | 值   | 说明                   |
| ---------------- | ---- | ---------------------- |
| SPEED            | 60   | 水平移动速度           |
| ACCELERATION     | 500  | 地面加速度             |
| FRICTION         | 650  | 地面摩擦力             |
| AIR_ACCELERATION | 350  | 空中加速度             |
| AIR_FRICTION     | 100  | 空中摩擦力             |
| JUMP_VELOCITY    | -110 | 跳跃初速度             |
| JUMP_CUT_FACTOR  | 0.4  | 松开跳跃键时的速度衰减 |
| GRAVITY          | 245  | 重力                   |
| MAX_FALL_SPEED   | 162  | 最大下落速度           |
| COYOTE_TIME      | 0.12 | 土狼时间(秒)           |
| JUMP_BUFFER      | 0.1  | 跳跃缓冲(秒)           |

---

## 常见问题

### Q: 修改了节点名称或路径后游戏报错？

A: 脚本中使用 `@onready var xxx = $NodePath` 引用节点。如果你更改了节点名或层级，需要同步修改对应 `.gd` 文件中的路径。

### Q: 物品收集顺序不对？

A: 御供筒是**栈**结构。先收集的物品在栈底。`ALTAR_ORDERS` 定义了从底到顶的正确顺序。安排关卡路线让玩家按正确顺序遇到物品。

### Q: 生成的占位资源不好看？

A: `generate_assets.py` 只生成占位图。你可以用任何像素画工具替换 `assets/` 下的 .png 文件，只要保持相同的尺寸和帧数即可。

### Q: 如何测试单个关卡？

A: 打开关卡 .tscn → `F6`（运行当前场景）。注意：需要 GameManager/DialogManager 自动加载正常工作。

---

_本文档为《送狐》项目的完整编辑器操作指南。所有游戏逻辑由 GDScript 处理，所有可视化内容由你在编辑器中手动搭建。_
