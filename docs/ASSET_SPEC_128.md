# 《送狐》128 HD 素材规格与生成 Prompt

本文件是《送狐》128 高清占位版的正式素材生产说明。当前项目只放占位资源，但场景、碰撞、机关、UI、音频引用已经按这些路径和尺寸写好。替换素材时不要改文件名、目录、画布尺寸、帧数、单帧尺寸、锚点规则，否则 Godot 场景会出现错位、裁切或动画帧错误。

## 0. 交付硬约束

- 逻辑视口：`1280x720`。
- 基础 Tile：`128x128`。
- Sprite 贴图过滤：项目按高清 2D 使用，素材可以是高精度像素风、手绘像素风或 pixel-adjacent 风格，但边缘要干净，不能像低分辨率素材硬放大。
- PNG 要保持透明背景，除背景图、光照贴图、UI 九宫格外不要铺满不透明底色。
- 人物、NPC、物件统一 bottom-center anchor。每帧脚底或落地点在单帧底边中心。白狐和漂浮 FX 可以视觉上偏移，但动画帧画布仍不移动。
- 最终素材不要保留占位图里的边框、十字、帧序号、文字标签。
- 碰撞不依赖像素透明度。碰撞体在 `.tscn/.tres` 中已预设，素材只要视觉上匹配对应碰撞尺寸。
- 图像生成时不要直接复制任何商业游戏画面。可参考“高密度环境细节、现代 2D 光影、强叙事氛围”这些原则，但所有角色、场景、道具都要原创。

通用风格提示词，可以附加在所有图像 prompt 前：

```text
Original refined high-resolution 2D pixel-art game asset, hand-painted pixel-adjacent detail, clean readable silhouettes, Japanese mountain shrine folklore mood, dusk-to-night atmosphere, layered lighting, subtle texture, no text, no watermark, no UI labels, no copied franchise design.
```

通用负面提示词：

```text
blurry, low resolution, muddy silhouette, photorealistic render, 3D render, plastic look, random text, watermark, frame numbers, cropped feet, inconsistent scale, overexposed glow, noisy background, copyrighted character, modern city objects.
```

## 1. 关卡与素材关系

素材不是孤立生成的。它们在当前三章中的用途如下：

| 关卡 | 当前场景宽度 | TileSet | 背景组 | 美术主旨 | 关键素材 |
|---|---:|---|---|---|---|
| Level 1 村口到装束之祠 | `9600px` | `forest_tileset` | `level1_far/mid/near` | 村口小祠、杉林教学、旧鸟居、装束祭坛 | 老人、石碑、小鸟居、大鸟居、石灯笼、杉木、白狐毛、艾草、祭坛、狐火 |
| Level 2 断参道 | `12800px` | `approach_tileset` | `level2_far/mid/near` | 断崖、桥谜题、铃绳机关、隐藏供物路径 | 桥板、隐藏平台、铃绳、水草、灯油、蓝火、第二祭坛 |
| Level 3 本社与内殿 | `11200px` | `shrine_tileset` | `level3_far/mid/near` | 外廊、档案札记、内殿、匾额揭示、最终选择 | 档案札、匾额、内殿灯笼、白狐显现、终局狐火 |

当前地图里核心可玩地形主要使用每套 TileSet 的 `R1C1`、`R2C1`、`R3C1`。其余 tile 是为后续在 Godot Editor 中直接补边角、裂纹、装饰、墙面和无碰撞视觉变体预留，必须一起完成，避免扩图时只能重复同一块地面。

当前 Godot 场景直接引用的 TileSet resource 是：

- `assets/tilesets/forest_tileset.tres`，使用 `assets/tilesets/forest_tileset.png`。
- `assets/tilesets/approach_tileset.tres`，使用 `assets/tilesets/approach_tileset.png`。
- `assets/tilesets/shrine_tileset.tres`，使用 `assets/tilesets/shrine_tileset.png`。

当前 Godot 场景直接引用的角色 sprite sheet 完整路径是：

- `assets/sprites/player/miko_idle.png`
- `assets/sprites/player/miko_run.png`
- `assets/sprites/player/miko_jump.png`
- `assets/sprites/player/miko_fall.png`
- `assets/sprites/player/miko_interact.png`
- `assets/sprites/player/miko_turn.png`
- `assets/sprites/player/miko_pray.png`
- `assets/sprites/npcs/elder_idle.png`
- `assets/sprites/npcs/fox_idle.png`
- `assets/sprites/npcs/fox_walk.png`
- `assets/sprites/npcs/fox_look_back.png`
- `assets/sprites/npcs/fox_appear.png`
- `assets/sprites/npcs/fox_depart.png`
- `assets/sprites/npcs/foxfire_unstable.png`

## 2. 角色 Sprite Sheets

角色统一朝右制作，Godot 里通过 `flip_h` 翻转朝左。人物单帧可见身高不要铺满画布，画布顶部留给头发、袖子和次级动作，底部中心是脚底。

### 2.1 玩家巫女 `assets/sprites/player/`

角色设定：年轻巫女或送狐仪式引路人，深色内衣和浅色外衣，红白仪式元素可保留但不要做成现代 cosplay。发带、衣袖、纸垂有轻微次级动作。真实可见身高 `232-264px`，碰撞体约 `80x216`，所以身体主体要纤细，衣袖和飘带可以超出碰撞体但不能遮挡脚底。

| 文件 | 画布 | 单帧 | 帧数 | 用途 | 生成 Prompt |
|---|---:|---:|---:|---|---|
| `miko_idle.png` | `2048x384` | `256x384` | 8 | 默认待机，主菜单和三章行走前状态 | `Create a transparent horizontal sprite sheet, 8 frames, each 256x384, total 2048x384. A young shrine guide in refined HD pixel-art, standing relaxed, subtle breathing, sleeves and hair ribbon moving gently. Bottom-center foot anchor in every frame, visible body height 232 to 264 pixels, feet stable on the same baseline.` |
| `miko_run.png` | `2048x384` | `256x384` | 8 | 左右移动 | `Create an 8-frame run cycle for the same shrine guide, transparent horizontal sheet 2048x384. Energetic but restrained side-scrolling run, readable foot contacts, sleeves trail behind, head height stays consistent. Keep both feet landing on the bottom-center baseline area, no sliding silhouette.` |
| `miko_jump.png` | `1024x384` | `256x384` | 4 | 起跳和上升 | `Create a 4-frame jump ascent sheet, total 1024x384. The shrine guide crouches then rises, sleeves lift, knees tucked slightly, clear upward motion. Bottom-center anchor remains the imagined foot origin even while the body lifts inside the frame.` |
| `miko_fall.png` | `768x384` | `256x384` | 3 | 下落 | `Create a 3-frame falling loop sheet, total 768x384. The shrine guide descends with robe and hair lifted by air, arms balancing, calm but tense pose. Keep silhouette height consistent with jump, no cropping.` |
| `miko_interact.png` | `1536x384` | `256x384` | 6 | 读碑、拾取、拉绳前的通用交互 | `Create a 6-frame interaction animation sheet, total 1536x384. The shrine guide leans forward and extends one hand toward an object, sleeve swinging, gentle ritual gesture. Feet stay planted on the same bottom-center baseline.` |
| `miko_turn.png` | `1024x384` | `256x384` | 4 | 转身和回头 | `Create a 4-frame turn or look-over-shoulder sheet, total 1024x384. The shrine guide rotates from side view into a slight back glance, hair ribbon and paper charm lag behind. Preserve exact scale and foot anchor.` |
| `miko_pray.png` | `2048x384` | `256x384` | 8 | 祭坛祈祷，可用于后续仪式演出 | `Create an 8-frame prayer animation sheet, total 2048x384. The shrine guide kneels slightly or bows with hands together, sleeves folding naturally, paper charm sways softly, solemn mood. Same bottom-center anchor and scale as idle.` |

### 2.2 老人 NPC `assets/sprites/npcs/elder_idle.png`

老人是 Level 1 村口教学 NPC，站在玩家左侧附近，真实身高略低于玩家。可见身高 `220-244px`，碰撞体约 `88x208`。

| 文件 | 画布 | 单帧 | 帧数 | 用途 | 生成 Prompt |
|---|---:|---:|---:|---|---|
| `elder_idle.png` | `1024x352` | `256x352` | 4 | 老人待机和对话 | `Create a transparent 4-frame idle sprite sheet, total 1024x352. Elder shrine caretaker in weathered rural clothing, slightly stooped, holding a small walking stick or folded paper, gentle warning expression. Visible height 220 to 244 pixels, bottom-center foot anchor, subtle breathing only.` |

### 2.3 白狐 `assets/sprites/npcs/`

白狐是叙事核心。真实身长约玩家身高的 `0.75-0.9`，主体占单帧 `190-230px` 宽，尾部和狐火可以超出主体但不能触碰画布边缘。白狐脚点仍以 bottom-center 为动画基准，避免站在地面时漂浮。

| 文件 | 画布 | 单帧 | 帧数 | 用途 | 生成 Prompt |
|---|---:|---:|---:|---|---|
| `fox_idle.png` | `1920x224` | `320x224` | 6 | 白狐待机 | `Create a transparent 6-frame horizontal sprite sheet, total 1920x224. Mystical white fox, elegant long tail, faint warm foxfire accents, calm breathing, ears twitching. Body length 190 to 230 pixels, paws align to bottom-center ground baseline.` |
| `fox_walk.png` | `2560x224` | `320x224` | 8 | 白狐移动或过场引导 | `Create an 8-frame walk cycle sheet, total 2560x224. The same white fox walks with quiet ceremonial grace, tail counter-sways, paws have clear contact timing, body height remains stable.` |
| `fox_look_back.png` | `1600x224` | `320x224` | 5 | 回头提示、引路 | `Create a 5-frame look-back animation, total 1600x224. The white fox pauses and turns its head toward the player, one ear lifted, tail glow pulsing faintly. Final frame is a readable side-profile with emotional recognition.` |
| `fox_appear.png` | `2560x224` | `320x224` | 8 | 显现 | `Create an 8-frame materialization animation, total 2560x224. The white fox forms from low foxfire and drifting shrine paper motes, opacity grows from silhouette to solid body. Keep final frame exactly matching fox_idle scale and anchor.` |
| `fox_depart.png` | `2560x224` | `320x224` | 8 | 离去或消散 | `Create an 8-frame departure animation, total 2560x224. The white fox dissolves into warm foxfire particles and ribbon-like tail light, beginning from the idle pose and ending almost transparent. Do not move the ground anchor.` |
| `foxfire_unstable.png` | `1024x128` | `128x128` | 8 | 白狐尾部 FX 层 | `Create an 8-frame transparent sprite sheet, total 1024x128. Small unstable orange-white foxfire flame for the fox tail, asymmetrical flicker, soft core, pixel-art edge, center anchor, loopable.` |

## 3. 互动对象与场景道具

所有物件 PNG 都是单图，除桥和隐藏平台外都使用 bottom-center anchor。替换时要让视觉接触点和当前碰撞体吻合。

| 文件 | 尺寸 | 当前用途 | 视觉描述 | 生成 Prompt |
|---|---:|---|---|---|
| `assets/sprites/objects/item_sugi_wood.png` | `128x128` | Level 1 村口拾取，Level 2 修桥供物 | 一小束带香气的杉木枝，不要像普通木柴，需有祭仪感 | `Create a transparent 128x128 game item icon sprite. A small bundle of sacred cedar wood tied with faded cord, a few green cedar needles, subtle warm rim light, bottom-center placement, readable at HUD size.` |
| `assets/sprites/objects/item_white_fur.png` | `128x128` | Level 1 低平台，Level 2 铃绳段 | 一撮白狐毛，轻、亮、偏神秘 | `Create a transparent 128x128 item sprite. A tuft of white fox fur with soft curved strands, faint pale glow, small paper charm thread, bottom-center placement, no background.` |
| `assets/sprites/objects/item_mugwort.png` | `128x128` | Level 1 祭坛前拾取 | 艾草束，绿色供物，和水草区分明显 | `Create a transparent 128x128 item sprite. A bundle of mugwort leaves tied for ritual use, muted green leaves, dry stem ends, tiny dew highlights, bottom-center anchor, clean silhouette.` |
| `assets/sprites/objects/item_water_grass.png` | `128x128` | Level 2 隐藏路线供物 | 湿润水草，偏青蓝，暗示断参道下方水域 | `Create a transparent 128x128 item sprite. A small offering bundle of water grass, blue-green wet blades, a few droplets, cool light reflection, bottom-center anchor, distinct from mugwort.` |
| `assets/sprites/objects/item_bell_fiber.png` | `128x128` | Level 1 祭坛顶部供物预览 | 铃绳纤维，用于第一次分支提示 | `Create a transparent 128x128 ritual item sprite. Frayed golden bell-rope fiber tied in a small loop, tiny red cord, ceremonial but worn, bottom-center anchor.` |
| `assets/sprites/objects/item_fox_stone.png` | `128x128` | Level 1 祭坛顶部供物预览 | 狐火石，暖色、半透明、比普通石头更神异 | `Create a transparent 128x128 item sprite. A small foxfire stone, warm amber core inside pale stone, faint flame-shaped crack, subtle glow, bottom-center anchor.` |
| `assets/sprites/objects/item_lamp_oil.png` | `128x128` | Level 2 第二祭坛顶部供物预览 | 小油瓶，和灯笼机关关联 | `Create a transparent 128x128 item sprite. A small old ceramic lamp-oil flask with tied paper label, amber oil visible, warm highlight, bottom-center anchor.` |
| `assets/sprites/objects/stone_tablet.png` | `192x256` | 可读碑文、教学提示 | 矮石碑，不能像 UI 面板，要像真实可触碰场景物 | `Create a transparent 192x256 object sprite. Weathered shrine stone tablet with engraved but unreadable marks, moss in cracks, chipped corners, bottom-center anchor, visible contact base around 160px wide.` |
| `assets/sprites/objects/altar.png` | `384x288` | 三章祭坛互动 | 主供桌，玩家站前方能读懂是交互终点 | `Create a transparent 384x288 shrine altar sprite. Low wooden ritual altar with cloth runner, small offering plates, candle sockets, aged lacquer, readable front-facing 2D game object, bottom-center anchor, base width about 320px.` |
| `assets/sprites/objects/stone_lantern.png` | `128x256` | 各章灯笼地标 | 石灯笼，和 `lantern_flame.png` 叠加 | `Create a transparent 128x256 stone lantern sprite. Old Japanese shrine stone lantern, square cap, hollow light chamber, moss and chips, bottom-center anchor, leave visible opening for flame overlay.` |
| `assets/sprites/objects/bell_rope.png` | `128x448` | Level 2 铃绳机关 | 从上垂下的粗绳，顶部在场景中挂住 | `Create a transparent 128x448 vertical bell rope sprite. Thick braided shrine rope with tassel and aged fibers, top-center hanging origin, lower pull section readable, no bell body unless small silhouette at top.` |
| `assets/sprites/objects/torii_small.png` | `384x448` | Level 1 村口小鸟居 | 小型入口地标 | `Create a transparent 384x448 small torii gate sprite. Weathered red shrine gate, mossy stone bases, slight side-scrolling perspective, bottom-center anchor, opening wide enough to frame the player.` |
| `assets/sprites/objects/torii.png` | `640x576` | Level 1 旧鸟居和祭坛门 | 大型鸟居，作为中后段强地标 | `Create a transparent 640x576 large old torii gate sprite. Tall weathered red shrine gate, faded paint, rope and paper shide, cracked stone footings, strong silhouette, bottom-center anchor.` |
| `assets/sprites/objects/bridge_plank.png` | `1152x96` | Level 2 桥机制，`StaticBody2D` 预摆 | 一整段可显隐桥，不属于 TileSet | `Create a transparent 1152x96 side-view wooden bridge platform. Multiple old cedar planks tied with rope, broken edges, underside shadows, seamless horizontal top walking surface, no background.` |
| `assets/sprites/objects/hidden_platform.png` | `1024x96` | Level 2 铃绳后显现隐藏平台 | 半透明灵性平台，出现后可站 | `Create a transparent 1024x96 mystical hidden platform sprite. Pale blue shrine-spirit bridge made of faint boards and foxfire lines, readable solid top edge, softly glowing underside, no background.` |
| `assets/sprites/objects/plaque.png` | `384x192` | Level 3 匾额揭示 | 匾额，不要写真实可读文字，可留模糊符号 | `Create a transparent 384x192 old shrine plaque sprite. Dark wooden signboard with worn gold trim, unreadable ancient marks, cracked lacquer, bottom-center anchor, solemn reveal object.` |
| `assets/sprites/objects/archive_note.png` | `192x192` | Level 3 五个档案点 | 札记、残纸、木牌通用图 | `Create a transparent 192x192 archive note sprite. A visible old shrine record made of torn paper and thin wooden backing, tied with red thread, unreadable marks, bottom-center anchor, meant for direct interaction.` |

## 4. 特效与光照素材

动画特效使用横向 sprite sheet。Light2D 贴图使用中心光晕，不要有硬边。

| 文件 | 尺寸 | 单帧 | 帧数 | 用途 | 生成 Prompt |
|---|---:|---:|---:|---|---|
| `assets/sprites/effects/fox_fire.png` | `1024x128` | `128x128` | 8 | 场景狐火、提示点 | `Create an 8-frame transparent 1024x128 sprite sheet. Small orange-white foxfire flame, loopable flicker, bright core and soft pixel-art edge, centered in each 128x128 frame.` |
| `assets/sprites/effects/lantern_flame.png` | `1024x128` | `128x128` | 8 | 石灯笼火焰 | `Create an 8-frame transparent 1024x128 sprite sheet. Warm lantern flame for stone shrine lanterns, compact teardrop shape, subtle wind sway, loopable, centered.` |
| `assets/sprites/effects/blue_flame.png` | `1024x128` | `128x128` | 8 | Level 2 隐藏路径提示 | `Create an 8-frame transparent 1024x128 sprite sheet. Cool blue spirit flame, quieter and narrower than fox_fire, faint cyan core, loopable, centered.` |
| `assets/sprites/effects/warm_light.png` | `512x512` | `512x512` | 1 | 灯笼和祭坛 Light2D | `Create a 512x512 radial warm light texture. Transparent background, soft amber center fading smoothly to alpha, no hard edge, no visible circle border.` |
| `assets/sprites/effects/cold_light.png` | `512x512` | `512x512` | 1 | 备用冷光、隐藏路线 | `Create a 512x512 radial cold light texture. Transparent background, pale blue center fading smoothly to alpha, no hard edge, no noise.` |
| `assets/sprites/effects/light_texture.png` | `512x512` | `512x512` | 1 | 白狐和通用 PointLight2D | `Create a 512x512 neutral soft light texture. Transparent radial glow, warm white center, smooth alpha falloff, suitable for PointLight2D.` |
| `assets/sprites/effects/particle.png` | `64x64` | `64x64` | 1 | 后续粒子备用 | `Create a transparent 64x64 tiny ritual mote sprite. Soft glowing paper-dust particle, warm center, alpha feathered edge.` |

## 5. TileSet 总规格

三套 TileSet 都是 `1024x768`，`8列 x 6行`，单格 `128x128`。坐标用 1-based 表示：`R1C1` 是第 1 行第 1 列。每套 `.tres` 已按同样规则配置碰撞：

| 行 | 碰撞 | 用途 |
|---:|---|---|
| R1 | solid，physics layer 3 / collision bit 4 | 地面顶面、边缘、角 |
| R2 | solid，physics layer 3 / collision bit 4 | 实心填充、裂缝、斜坡占位 |
| R3 | one-way platform | 一方通行平台、桥板、台阶 |
| R4 | solid，physics layer 3 / collision bit 4 | 墙、柱、门框、建筑硬碰撞 |
| R5 | 无碰撞 | 小装饰 |
| R6 | 无碰撞 | 视觉变体、贴花、阴影、雾边 |

整张 atlas 生成通用 prompt：

```text
Create a 1024x768 transparent-background tileset atlas for a 2D side-scrolling HD pixel-art game. The atlas is exactly 8 columns by 6 rows, each cell exactly 128x128. No labels, no grid lines, no numbers. Keep tiles aligned to the 128px grid. Top-surface tiles must tile seamlessly left and right. Solid tiles may fill the whole cell. Decorative rows must have transparent background where empty. Use clean readable silhouettes and consistent lighting from upper left.
```

### 5.1 `assets/tilesets/forest_tileset.png`

主题：Level 1 村口、杉林、旧鸟居、装束之祠。材质为湿润泥土、杉树根、苔藓、碎石和少量旧参道石。整体偏夜色青绿，但地形顶面必须清楚可读。

| Cell | 画面描述和生成 Prompt |
|---|---|
| R1C1 | `Solid flat top ground. Mossy cedar forest path tile, flat walkable top edge with dark soil below, cedar needles and small stones, seamless left and right.` |
| R1C2 | `Solid left edge ground. Same forest path, flat top continues from right side, left side exposed with roots and soil wall, clear vertical edge.` |
| R1C3 | `Solid right edge ground. Same forest path, flat top continues from left side, right side exposed with roots and soil wall, clear vertical edge.` |
| R1C4 | `Solid outer corner left. Forest path top turns down at left outside corner, moss cap and exposed root corner, readable collision shape.` |
| R1C5 | `Solid outer corner right. Forest path top turns down at right outside corner, moss cap and exposed root corner, readable collision shape.` |
| R1C6 | `Solid inner corner left. Dark recess under an overhanging mossy top, left inner notch, useful for carved gaps.` |
| R1C7 | `Solid inner corner right. Dark recess under an overhanging mossy top, right inner notch, useful for carved gaps.` |
| R1C8 | `Solid broken top transition. Uneven forest path top with cracked stone and roots, still reads as a full walkable 128px tile.` |
| R2C1 | `Solid fill block. Dense dark soil and cedar roots, no top highlight, seamless on all sides for underground fill.` |
| R2C2 | `Solid darker fill. Deeper soil block with heavier shadow, roots and embedded stones, seamless all sides.` |
| R2C3 | `Solid cracked fill A. Soil and old stone with a vertical crack and moss, still fills full tile.` |
| R2C4 | `Solid cracked fill B. Soil fill with diagonal root crack and pebbles, full collision tile.` |
| R2C5 | `Solid embedded root block. Large cedar root crossing through soil, full tile, strong forest identity.` |
| R2C6 | `Solid moss variation. Soil fill with thick moss patches and damp highlights, seamless.` |
| R2C7 | `Solid vertical side face. Exposed compacted earth wall with hanging roots, useful for cliff faces.` |
| R2C8 | `Solid underside. Dark underside of a dirt ledge with root shadows, full tile.` |
| R3C1 | `One-way platform center. Narrow mossy fallen cedar plank or root bridge with transparent lower half, walkable top visually around y=40.` |
| R3C2 | `One-way platform left cap. Left end of mossy root platform, transparent background, rounded broken end.` |
| R3C3 | `One-way platform right cap. Right end of mossy root platform, transparent background, rounded broken end.` |
| R3C4 | `One-way forest step center. Short flat stone-and-root step, transparent below, readable as pass-through platform.` |
| R3C5 | `One-way bridge board. Weathered small plank over forest gap, rope fibers, transparent below.` |
| R3C6 | `One-way stair up-left. Diagonal-looking forest step rising visually from right to left, collision still one-way flat in engine.` |
| R3C7 | `One-way stair up-right. Diagonal-looking forest step rising visually from left to right, collision still one-way flat in engine.` |
| R3C8 | `One-way broken variant. Cracked root platform with missing chunks, still visually safe to stand on.` |
| R4C1 | `Solid forest retaining wall. Stacked old stones with moss, full tile, for shrine approach walls.` |
| R4C2 | `Solid wall top trim. Stone wall top cap with moss and cedar needles, full tile.` |
| R4C3 | `Solid cedar pillar base. Thick dark cedar post embedded in stone, full tile.` |
| R4C4 | `Solid wooden gate frame left. Left vertical fragment of old shrine gate, full collision.` |
| R4C5 | `Solid wooden gate frame right. Right vertical fragment of old shrine gate, full collision.` |
| R4C6 | `Solid threshold block. Old stone threshold slab with moss, full tile.` |
| R4C7 | `Solid dark recess wall. Shadowed forest shrine wall with roots, full tile.` |
| R4C8 | `Solid cracked wall. Mossy stacked stone with large crack and small roots, full tile.` |
| R5C1 | `No collision grass tuft. Small cedar forest grass and fern cluster, transparent background.` |
| R5C2 | `No collision small stones. Three mossy pebbles and fallen needles, transparent background.` |
| R5C3 | `No collision paper seal. Torn shrine paper charm stuck to a root, transparent background.` |
| R5C4 | `No collision broken wood. Small snapped cedar branch and bark pieces, transparent background.` |
| R5C5 | `No collision mushroom or moss clump. Low detail cluster, transparent background, not too bright.` |
| R5C6 | `No collision small shrine marker. Tiny old stone marker fragment, transparent background.` |
| R5C7 | `No collision fallen leaves. Sparse leaf scatter, transparent background.` |
| R5C8 | `No collision hanging vine. Thin cedar root or vine hanging from top of cell, transparent background.` |
| R6C1 | `No collision ground decal A. Thin moss overlay and needle scatter, transparent outside shape.` |
| R6C2 | `No collision ground decal B. Dark damp patch, soft pixel-art alpha edge.` |
| R6C3 | `No collision root shadow. Horizontal root shadow decal, transparent background.` |
| R6C4 | `No collision mist edge. Low pale forest mist strip, transparent background.` |
| R6C5 | `No collision light spill. Very subtle warm lantern spill on ground, transparent background.` |
| R6C6 | `No collision background trunk slice. Dark cedar trunk silhouette edge, transparent background.` |
| R6C7 | `No collision transition dirt-to-stone decal. Small broken path fragments, transparent background.` |
| R6C8 | `No collision empty-safe variant. Very faint texture specks only, transparent background, useful for manual painting.` |

### 5.2 `assets/tilesets/approach_tileset.png`

主题：Level 2 断参道、断崖、杉木桥、铃绳机关。材质为破碎石参道、断裂木板、绳索、苔痕和崖壁。整体更冷、更破败，顶面要比背景亮一档。

| Cell | 画面描述和生成 Prompt |
|---|---|
| R1C1 | `Solid flat top ground. Broken stone shrine approach path, flat walkable top edge, cracked paving stones with dirt between, seamless left and right.` |
| R1C2 | `Solid left edge ground. Stone path top continues from right side, exposed cliff dirt and broken masonry on left edge.` |
| R1C3 | `Solid right edge ground. Stone path top continues from left side, exposed cliff dirt and broken masonry on right edge.` |
| R1C4 | `Solid outer corner left. Broken stone top turns down at left outside corner, chipped slab and dark cliff face.` |
| R1C5 | `Solid outer corner right. Broken stone top turns down at right outside corner, chipped slab and dark cliff face.` |
| R1C6 | `Solid inner corner left. Recessed broken stone ledge with left inner notch and dark gap.` |
| R1C7 | `Solid inner corner right. Recessed broken stone ledge with right inner notch and dark gap.` |
| R1C8 | `Solid broken top transition. Missing and misaligned stone slabs, still reads as fully walkable.` |
| R2C1 | `Solid fill block. Dark cliff earth and old masonry fill, seamless all sides.` |
| R2C2 | `Solid darker fill. Deep ravine-facing stone fill, heavy shadow and damp cracks, seamless.` |
| R2C3 | `Solid cracked fill A. Old retaining stone with vertical crack and loose gravel.` |
| R2C4 | `Solid cracked fill B. Diagonal fracture through stone and packed dirt, full tile.` |
| R2C5 | `Solid embedded timber block. Broken cedar beam trapped in cliff stone, full tile.` |
| R2C6 | `Solid moss variation. Stone fill with green-black moss and water stains, seamless.` |
| R2C7 | `Solid cliff side face. Vertical broken approach wall, exposed strata and small roots.` |
| R2C8 | `Solid underside. Dark underside of stone ledge, broken slab shadows.` |
| R3C1 | `One-way platform center. Narrow weathered stone step or plank, transparent below, pass-through platform.` |
| R3C2 | `One-way platform left cap. Left broken end of stone step, transparent background.` |
| R3C3 | `One-way platform right cap. Right broken end of stone step, transparent background.` |
| R3C4 | `One-way approach step center. Flat stair slab, transparent below, slightly brighter top.` |
| R3C5 | `One-way bridge board. Small cedar bridge board with rope lashings, transparent below.` |
| R3C6 | `One-way stair up-left. Visual diagonal broken step rising from right to left, collision remains one-way flat.` |
| R3C7 | `One-way stair up-right. Visual diagonal broken step rising from left to right, collision remains one-way flat.` |
| R3C8 | `One-way broken variant. Cracked pass-through stone slab with missing corner, still readable as safe.` |
| R4C1 | `Solid retaining wall. Stacked shrine approach stones, darker than floor, full tile.` |
| R4C2 | `Solid wall top trim. Chipped stone wall cap with wet highlights, full tile.` |
| R4C3 | `Solid rope pillar base. Old post and rope anchor embedded in stone, full tile.` |
| R4C4 | `Solid gate frame left. Broken left wooden support from old approach structure, full tile.` |
| R4C5 | `Solid gate frame right. Broken right wooden support from old approach structure, full tile.` |
| R4C6 | `Solid threshold block. Heavy stone threshold slab with cracks, full tile.` |
| R4C7 | `Solid dark recess wall. Shadowed ravine masonry, full tile.` |
| R4C8 | `Solid cracked wall. Large fractured stone wall with missing chips, full tile.` |
| R5C1 | `No collision dry grass. Sparse cliff grass tuft, transparent background.` |
| R5C2 | `No collision gravel stones. Loose broken stones, transparent background.` |
| R5C3 | `No collision paper seal. Wet torn paper charm on stone, transparent background.` |
| R5C4 | `No collision broken plank. Small snapped bridge plank pieces, transparent background.` |
| R5C5 | `No collision rope scrap. Frayed rope coil and fiber, transparent background.` |
| R5C6 | `No collision tiny offering shard. Broken ceramic or lamp-oil shard, transparent background.` |
| R5C7 | `No collision fallen leaves. Sparse dark leaves and dirt, transparent background.` |
| R5C8 | `No collision hanging rope strand. Thin rope or root hanging from top, transparent background.` |
| R6C1 | `No collision paving decal A. Extra cracks for stone path, transparent outside linework.` |
| R6C2 | `No collision damp stain. Cool water stain decal, soft edge.` |
| R6C3 | `No collision ravine shadow. Horizontal dark cliff shadow decal.` |
| R6C4 | `No collision low fog edge. Pale blue ravine mist strip, transparent background.` |
| R6C5 | `No collision lamp spill. Subtle amber light spill for bell area, transparent background.` |
| R6C6 | `No collision distant post silhouette. Dark broken post edge, transparent background.` |
| R6C7 | `No collision stone-to-wood transition. Small plank and stone fragments, transparent background.` |
| R6C8 | `No collision empty-safe variant. Faint dust specks only, transparent background.` |

### 5.3 `assets/tilesets/shrine_tileset.png`

主题：Level 3 本社、外廊、内殿、档案点。材质为暗木地板、神社石基、旧漆、纸门、梁柱。整体比前两章更室内、更庄重，色温偏紫褐和暖金。

| Cell | 画面描述和生成 Prompt |
|---|---|
| R1C1 | `Solid flat top ground. Dark polished shrine floor or stone base, flat walkable top edge, worn wood grain and dust, seamless left and right.` |
| R1C2 | `Solid left edge ground. Shrine floor top continues from right, exposed wooden floor thickness and stone base on left edge.` |
| R1C3 | `Solid right edge ground. Shrine floor top continues from left, exposed wooden floor thickness and stone base on right edge.` |
| R1C4 | `Solid outer corner left. Floor or stone base turns down at left outside corner, chipped lacquer trim.` |
| R1C5 | `Solid outer corner right. Floor or stone base turns down at right outside corner, chipped lacquer trim.` |
| R1C6 | `Solid inner corner left. Dark recessed floor notch with left inner corner shadow.` |
| R1C7 | `Solid inner corner right. Dark recessed floor notch with right inner corner shadow.` |
| R1C8 | `Solid broken top transition. Worn shrine floor top with cracked board and old dust, still fully walkable.` |
| R2C1 | `Solid fill block. Dark wood and stone foundation fill, seamless all sides.` |
| R2C2 | `Solid darker fill. Deep under-floor shadow block, old beams barely visible.` |
| R2C3 | `Solid cracked fill A. Wooden foundation with vertical crack and dust.` |
| R2C4 | `Solid cracked fill B. Diagonal split through wood and plaster, full tile.` |
| R2C5 | `Solid embedded beam block. Large shrine beam crossing foundation, full tile.` |
| R2C6 | `Solid aged variation. Dark wood fill with dust, old lacquer flecks, seamless.` |
| R2C7 | `Solid vertical side face. Exposed shrine foundation wall, planks and stone base.` |
| R2C8 | `Solid underside. Dark underside of raised shrine floor with beam shadow.` |
| R3C1 | `One-way platform center. Narrow interior wooden ledge or archive shelf step, transparent below.` |
| R3C2 | `One-way platform left cap. Left end of interior wooden ledge, transparent background.` |
| R3C3 | `One-way platform right cap. Right end of interior wooden ledge, transparent background.` |
| R3C4 | `One-way shrine step center. Flat interior stair tread, transparent below, warm worn edge.` |
| R3C5 | `One-way board platform. Thin dark wood board with rope or paper strip, transparent below.` |
| R3C6 | `One-way stair up-left. Visual diagonal interior step rising from right to left, one-way flat collision.` |
| R3C7 | `One-way stair up-right. Visual diagonal interior step rising from left to right, one-way flat collision.` |
| R3C8 | `One-way broken variant. Cracked interior ledge with missing lacquer, still readable as safe.` |
| R4C1 | `Solid shrine wall. Dark wooden wall panel or plaster section, full tile.` |
| R4C2 | `Solid wall top trim. Horizontal shrine beam trim with worn gold detail, full tile.` |
| R4C3 | `Solid pillar. Thick dark shrine pillar with subtle red lacquer, full tile.` |
| R4C4 | `Solid door frame left. Left side of paper door or inner hall frame, full tile.` |
| R4C5 | `Solid door frame right. Right side of paper door or inner hall frame, full tile.` |
| R4C6 | `Solid threshold block. Heavy interior threshold beam, full tile.` |
| R4C7 | `Solid dark recess wall. Deep inner hall shadow with faint paper texture, full tile.` |
| R4C8 | `Solid cracked wall. Old plaster and wood wall with cracks, full tile.` |
| R5C1 | `No collision dust grass equivalent. Small dust pile and straw bits, transparent background.` |
| R5C2 | `No collision small stones. Tiny shrine foundation stones or plaster chips, transparent background.` |
| R5C3 | `No collision paper seal. Old paper talisman stuck to wall or floor, transparent background.` |
| R5C4 | `No collision broken wood. Splintered shrine floor pieces, transparent background.` |
| R5C5 | `No collision candle wax. Small wax drips or burnt incense ash, transparent background.` |
| R5C6 | `No collision archive scrap. Tiny folded record scrap, transparent background.` |
| R5C7 | `No collision fallen paper. Sparse old paper strips, transparent background.` |
| R5C8 | `No collision hanging paper strip. Thin shide or paper streamer hanging from top, transparent background.` |
| R6C1 | `No collision floor decal A. Dust and worn lacquer overlay, transparent outside shape.` |
| R6C2 | `No collision dark stain. Old water stain or smoke mark, soft alpha edge.` |
| R6C3 | `No collision beam shadow. Horizontal interior shadow decal.` |
| R6C4 | `No collision low incense haze. Pale indoor haze strip, transparent background.` |
| R6C5 | `No collision candle light spill. Subtle warm floor glow, transparent background.` |
| R6C6 | `No collision background pillar edge. Dark pillar silhouette slice, transparent background.` |
| R6C7 | `No collision wood-to-paper transition. Small paper and plank fragments, transparent background.` |
| R6C8 | `No collision empty-safe variant. Faint dust specks only, transparent background.` |

## 6. Zone 长图背景精确定义

当前实现是“Zone 长图源素材 + 运行时视差偏移”，不是循环视差横条。这样 `BackgroundZones` 有区域设计意义：每个 zone 对应关卡的真实世界 X 段，可以按区域设计村口、杉林、旧鸟居、断桥、铃绳、内殿等氛围；运行时 Far/Mid/Near 会按不同系数跟随相机移动，形成视差。

运行规则：

- 每章有三张长背景图：Far、Mid、Near。
- 每张图宽度等于该关卡世界宽度，高度固定 `720`。
- 背景节点是 `Sprite2D`，`centered = false`。Editor 里的 `position` 是该层的基准偏移，运行时 `LevelBase` 只在这个基准上叠加视差位移；所以可以在场景里直接微调每层的水平/垂直位置。
- 为了让长图在有视差时仍覆盖完整关卡，`LevelBase` 会按视差系数自动调整背景层 `scale.x`，但会把 editor 里的 `scale.x` 当作倍率保留；`scale.y` 完全按 editor 设置保留。
- 不再使用 `Parallax2D.repeat_size`，不再要求左右循环。
- `x=0` 是关卡起点背景，最右边是关卡终点背景。左右边缘不需要无缝相接。
- zone 边界需要自然过渡，不能像三张硬拼图。
- 由于视差层会相对地形移动，背景地标只能做区域级对齐，不能当作可交互物件的像素级坐标参考。
- 不要在背景里画“真正可交互”的关键物件，例如桥、隐藏平台、祭坛、档案札、匾额。这些已经是 `.tscn` 场景节点。背景可以画远处剪影或环境暗示。

### 6.1 当前运行参数

| 关卡 | 世界宽度 | 背景文件尺寸 | Zone01 | Zone02 | Zone03 |
|---|---:|---:|---:|---:|---:|
| Level 1 | `9600` | `9600x720` | `0-3200` | `3200-6400` | `6400-9600` |
| Level 2 | `12800` | `12800x720` | `0-4267` | `4267-8533` | `8533-12800` |
| Level 3 | `11200` | `11200x720` | `0-3733` | `3733-7467` | `7467-11200` |

| 层 | 节点 | Parallax Factor | Z Index | 透明度策略 | 主要作用 |
|---|---|---:|---:|---|---|
| Far | `Background_Far` | `0.78` | `-80` | 建议不透明 | 天空、远山、远处建筑大剪影、室内深处 |
| Mid | `Background_Mid` | `0.90` | `-70` | 部分透明 | 中距离树干、柱廊、桥架、墙面、建筑轮廓 |
| Near | `Background_Near` | `0.98` | `-60` | 大量透明 | 前景枝叶、雾、纸垂、边缘遮罩，但仍在玩法层后方 |

注意：这里保留了 zone 长图的区域设计，同时使用较温和的视差系数。Far 的移动明显慢于地形，Mid 稍慢，Near 基本贴近地形速度。

### 6.2 透明度和高度带

玩家站立时脚底大约在 `y=512`，可见身体大约覆盖 `y=248-512`。拾取物、石碑、祭坛、铃绳等交互物集中在 `y=256-560`。背景不能在这个高度带做高对比噪声。

| Y 范围 | Far 层 | Mid 层 | Near 层 |
|---:|---|---|---|
| `0-120` | 天空、月色、远处屋檐，可不透明 | 树冠顶、梁顶，建议有透明空隙 | 可放少量顶部枝叶或纸垂，必须透明背景 |
| `120-280` | 远山和远建筑主轮廓，低对比 | 主要中景剪影区，树干、柱、桥架 | 可放稀疏前景枝条，不要密集遮挡 |
| `280-560` | 低对比环境色，避免强边线 | 只能放柔和、低对比的大形，不要贴着角色轮廓 | 尽量保持透明或很淡的雾，不要有高对比物件 |
| `560-720` | 远地平或暗部 | 远处地面、阴影 | 可放底部草影、雾边、柱脚剪影，但不要像可站平台 |

每层透明规则：

- Far：建议整张不透明，负责铺满天空和远景。不要透明洞，否则会露出 `BackdropWash` 色块。
- Mid：PNG 可以有透明区域。画“中景物体”而不是整张满版插画，透明区域让 Far 层露出来。覆盖率建议 `35%-65%`。
- Near：必须大量透明。只在顶部、底部和极少数边缘放前景元素，覆盖率建议 `15%-35%`。不要把可玩区域画花。

### 6.3 生成和拼接工作流

推荐工作流是“每层 3 张 zone 源图，最后手工拼成 1 张游戏用长图”。游戏运行时只读取 `assets/backgrounds/level*_far.png`、`level*_mid.png`、`level*_near.png`，不会读取 zone 源图。zone 源图建议放在 `assets/source/background_zones/`，作为制作源文件保存。

最终游戏文件仍然是：

| 最终文件 | 最终尺寸 | 来源 |
|---|---:|---|
| `assets/backgrounds/level1_far.png` | `9600x720` | `level1_far_z01/z02/z03` 拼接 |
| `assets/backgrounds/level1_mid.png` | `9600x720` | `level1_mid_z01/z02/z03` 拼接 |
| `assets/backgrounds/level1_near.png` | `9600x720` | `level1_near_z01/z02/z03` 拼接 |
| `assets/backgrounds/level2_far.png` | `12800x720` | `level2_far_z01/z02/z03` 拼接 |
| `assets/backgrounds/level2_mid.png` | `12800x720` | `level2_mid_z01/z02/z03` 拼接 |
| `assets/backgrounds/level2_near.png` | `12800x720` | `level2_near_z01/z02/z03` 拼接 |
| `assets/backgrounds/level3_far.png` | `11200x720` | `level3_far_z01/z02/z03` 拼接 |
| `assets/backgrounds/level3_mid.png` | `11200x720` | `level3_mid_z01/z02/z03` 拼接 |
| `assets/backgrounds/level3_near.png` | `11200x720` | `level3_near_z01/z02/z03` 拼接 |

Zone 核心尺寸：

| 关卡 | Z01 核心 | Z02 核心 | Z03 核心 | 拼接后 |
|---|---:|---:|---:|---:|
| Level 1 | `3200x720` | `3200x720` | `3200x720` | `9600x720` |
| Level 2 | `4267x720` | `4266x720` | `4267x720` | `12800x720` |
| Level 3 | `3733x720` | `3734x720` | `3733x720` | `11200x720` |

为了过渡自然，推荐每张 zone 源图额外带重叠区：

- Z01：核心宽度 + 右侧 `128px` overlap。
- Z02：左侧 `128px` overlap + 核心宽度 + 右侧 `128px` overlap。
- Z03：左侧 `128px` overlap + 核心宽度。
- 拼接时把 overlap 区域用蒙版、渐变或手绘修边混合，最后裁掉 overlap，只保留核心宽度。
- 如果 AI 工具不能生成奇数宽度或超出 `4096px`，可以先生成接近尺寸的较大图，再裁切到上表核心宽度。

每张 zone 源图生成时都使用这些硬要求：

```text
single zone segment for a world-aligned 2D game background, exact height 720px, not loopable, not tileable, no vertical dividers, no text, no UI, consistent horizon and lighting with adjacent zones, leave soft transition space near the left and right edges, gameplay-safe low contrast in the y=280 to y=560 band.
```

拼接检查：

1. Level 1 检查 `x=3200`、`x=6400`。
2. Level 2 检查 `x=4267`、`x=8533`。
3. Level 3 检查 `x=3733`、`x=7467`。
4. 边界附近不能出现明显接缝、透视跳变、突然换色、重复强地标或被切断的大物件。
5. 三层同一个 zone 的 Far/Mid/Near 必须共享同一时间、天气、色温和地平线高度。

### 6.4 Level 1 背景 brief

Level 1 的真实场景节点已经放了老人、石碑、石灯笼、小鸟居、大鸟居和祭坛。背景只做远处村口、杉林深度和旧参道氛围，不要再画一个清晰可交互的祭坛或大鸟居正面。

| Zone 源图 | 核心尺寸 | 透明度 | Zone 设计 | 生成 Prompt |
|---|---:|---|---|---|
| `level1_far_z01.png` | `3200x720` | 不透明 | 村口远山、村屋屋顶、小祠方向的远景。右边缘要逐渐变成杉林山线，方便接 Z02。 | `Create Level 1 Far Zone 01, 3200x720 core background segment, opaque. Rural mountain village gate at dusk, distant low roofs, soft mountain line, faint roadside shrine atmosphere. Low contrast blue-green palette, no foreground trunks, no readable interactable objects. Right edge transitions into deeper cedar forest hills for the next zone.` |
| `level1_far_z02.png` | `3200x720` | 不透明 | 杉林深处远山。左右边缘都保持杉林山线，左接村口，右接旧参道。 | `Create Level 1 Far Zone 02, 3200x720 core background segment, opaque. Deep cedar forest hills, layered distant tree masses, dusk haze, quiet shrine-road mood. Left edge can still hint at village distance, right edge gradually becomes older shrine approach terrain. Low contrast, stable horizon.` |
| `level1_far_z03.png` | `3200x720` | 不透明 | 旧参道和装束之祠方向的远山。左边缘接杉林，右边缘像关卡终点边界。 | `Create Level 1 Far Zone 03, 3200x720 core background segment, opaque. Old shrine approach mountain backdrop, distant dressing-shrine ridge, slightly warmer ritual glow in the far distance. Left edge continues cedar forest hills, right edge resolves as the level end, no loop requirement.` |
| `level1_mid_z01.png` | `3200x720` | 部分透明 | 小祠远影、篱笆、低树干。右边缘树干密度提高接 Z02。 | `Create Level 1 Mid Zone 01, 3200x720 transparent PNG segment. Distant roadside shrine fence silhouettes, small shrine shape far behind the playfield, sparse cedar trunks. Transparent sky gaps. Keep y=280 to y=560 low contrast. Right edge increases cedar density for transition.` |
| `level1_mid_z02.png` | `3200x720` | 部分透明 | 多层杉木树干、旧鸟居远影，但不能像可交互鸟居。 | `Create Level 1 Mid Zone 02, 3200x720 transparent PNG segment. Layered cedar trunks, old torii silhouette far in the background, shrine-road depth. Transparent negative space, no interactable-looking torii, no hard central clutter. Edges transition softly to adjacent zones.` |
| `level1_mid_z03.png` | `3200x720` | 部分透明 | 祭坛方向的柱影、纸垂、旧木结构远影，不画真正祭坛。 | `Create Level 1 Mid Zone 03, 3200x720 transparent PNG segment. Old approach posts, hanging paper strips, distant dressing-shrine wooden structure silhouettes. Do not draw the actual altar. Keep gameplay band uncluttered, left edge continues cedar forest.` |
| `level1_near_z01.png` | `3200x720` | 大量透明 | 顶部少量杉枝、底部草雾、村口边缘氛围。 | `Create Level 1 Near Zone 01, 3200x720 mostly transparent foreground segment. Sparse cedar branches near the top edge, low grasses and soft mist near the bottom, village-gate edge atmosphere. Central gameplay band clear, no solid platforms.` |
| `level1_near_z02.png` | `3200x720` | 大量透明 | 杉林前景枝叶和雾，不能遮挡跳跃平台。 | `Create Level 1 Near Zone 02, 3200x720 mostly transparent foreground segment. Cedar branch silhouettes at top, drifting forest mist at bottom, subtle depth. Keep y=280 to y=560 very clear, no dense foreground over platforms.` |
| `level1_near_z03.png` | `3200x720` | 大量透明 | 祭坛区域边缘暖雾、纸垂和少量灯光。 | `Create Level 1 Near Zone 03, 3200x720 mostly transparent foreground segment. Sparse paper strips, low shrine mist, tiny warm lantern haze near the edges, ceremonial mood. Do not cover the altar area or draw interactable props.` |

### 6.5 Level 2 背景 brief

Level 2 的桥、隐藏平台和铃绳都是真实场景节点。背景只表达断崖深度、破参道结构和隐藏路线气氛，不要把桥画成玩家会误判的平台。

| Zone 源图 | 核心尺寸 | 透明度 | Zone 设计 | 生成 Prompt |
|---|---:|---|---|---|
| `level2_far_z01.png` | `4267x720` | 不透明 | 断崖远山和冷夜天空，右边缘过渡到山谷雾。 | `Create Level 2 Far Zone 01, 4267x720 core background segment, opaque. Distant cliff mountains, broken approach atmosphere, cool night sky, low contrast. Right edge transitions into misty ravine valley, no bridge in playable plane.` |
| `level2_far_z02.png` | `4266x720` | 不透明 | 山谷和旧参道深度，远处可以有非常淡的桥影。 | `Create Level 2 Far Zone 02, 4266x720 core background segment, opaque. Misty valley depth, distant broken shrine approach, very faint old bridge silhouette far below and behind. Stable horizon, cool gray-blue palette, no walkable-looking shapes.` |
| `level2_far_z03.png` | `4267x720` | 不透明 | 第二祭坛方向远山脊，略有终点肃穆感。 | `Create Level 2 Far Zone 03, 4267x720 core background segment, opaque. Far ridge behind the second altar direction, solemn mountain silhouette, cooler night haze. Left edge continues valley mist, right edge resolves as level end.` |
| `level2_mid_z01.png` | `4267x720` | 部分透明 | 断石参道远结构和崖壁剪影。 | `Create Level 2 Mid Zone 01, 4267x720 transparent PNG segment. Broken stone approach silhouettes, distant cliff masonry, sparse dead grasses. Transparent sky gaps, low contrast gameplay band, right edge hints at bridge supports.` |
| `level2_mid_z02.png` | `4266x720` | 部分透明 | 旧桥支架、绳索结构、铃绳机关远影。不能画成可站平台。 | `Create Level 2 Mid Zone 02, 4266x720 transparent PNG segment. Distant bridge supports far behind the playfield, hanging rope structures, bell-mechanism silhouettes in the background. All horizontal structures must look distant and non-walkable, transparent negative space.` |
| `level2_mid_z03.png` | `4267x720` | 部分透明 | 隐藏路线和第二祭坛远景暗示。 | `Create Level 2 Mid Zone 03, 4267x720 transparent PNG segment. Hidden side path hints in blue-gray mist, distant shrine approach stones, subtle second-altar direction silhouettes. Do not draw the actual altar, keep edges soft.` |
| `level2_near_z01.png` | `4267x720` | 大量透明 | 崖边草影、底部雾，不遮挡起点。 | `Create Level 2 Near Zone 01, 4267x720 mostly transparent foreground segment. Cliff grass silhouettes along the bottom edge, low ravine fog, a few broken stone fragments at extreme edges. Central gameplay band clear.` |
| `level2_near_z02.png` | `4266x720` | 大量透明 | 断桥碎木和低雾，绝不形成可站横条。 | `Create Level 2 Near Zone 02, 4266x720 mostly transparent foreground segment. Broken plank fragments at extreme edges, rope strands, low ravine fog. Never draw bridge-like horizontal walkable shapes, keep y=280 to y=560 clear.` |
| `level2_near_z03.png` | `4267x720` | 大量透明 | 隐藏路线蓝色雾线和祭坛前低雾。 | `Create Level 2 Near Zone 03, 4267x720 mostly transparent foreground segment. Subtle blue spirit haze around hidden path areas, bottom-edge fog and cliff grass, solemn approach to second altar. Do not obscure items or altar.` |

### 6.6 Level 3 背景 brief

Level 3 的档案札、匾额和白狐显现点是场景节点。背景只做本社空间深度、纸门、梁柱和内殿暗影，不要画可读文字或可交互札记。

| Zone 源图 | 核心尺寸 | 透明度 | Zone 设计 | 生成 Prompt |
|---|---:|---|---|---|
| `level3_far_z01.png` | `3733x720` | 不透明 | 外廊深处，空间要有纵深但不画可交互札。 | `Create Level 3 Far Zone 01, 3733x720 core background segment, opaque. Dark outer shrine corridor depth, distant wooden beams, muted purple-brown interior, warm gold dust haze. Low contrast, no readable text or notes. Right edge transitions to archive wall darkness.` |
| `level3_far_z02.png` | `3734x720` | 不透明 | 档案墙暗部和更密的室内阴影。 | `Create Level 3 Far Zone 02, 3734x720 core background segment, opaque. Archive wall darkness, distant shelves as abstract silhouettes, old paper atmosphere without readable marks. Stable interior horizon, left edge outer corridor, right edge inner sanctum shadow.` |
| `level3_far_z03.png` | `3733x720` | 不透明 | 内殿深影，终局肃穆感。 | `Create Level 3 Far Zone 03, 3733x720 core background segment, opaque. Inner sanctum shadow, solemn shrine depth, faint warm ritual glow, no readable plaque or text. Left edge continues archive darkness, right edge resolves as final chamber.` |
| `level3_mid_z01.png` | `3733x720` | 部分透明 | 外廊梁柱和纸门远影。 | `Create Level 3 Mid Zone 01, 3733x720 transparent PNG segment. Dark shrine beams, pillars, paper-door silhouettes, transparent negative space. Keep central gameplay band readable, no note props.` |
| `level3_mid_z02.png` | `3734x720` | 部分透明 | 纸门、档案架远影，所有文字抽象化。 | `Create Level 3 Mid Zone 02, 3734x720 transparent PNG segment. Paper doors, distant archive shelves, tied paper bundles as abstract shapes. No readable text, no interactable archive notes, smooth transition to inner hall.` |
| `level3_mid_z03.png` | `3733x720` | 部分透明 | 匾额所在内殿结构的远影，但不能画可读匾额。 | `Create Level 3 Mid Zone 03, 3733x720 transparent PNG segment. Inner hall beams and plaque structure as unreadable silhouette in the background, dark pillars, warm candle haze. Do not draw actual readable plaque.` |
| `level3_near_z01.png` | `3733x720` | 大量透明 | 外廊前景柱边和少量纸符。 | `Create Level 3 Near Zone 01, 3733x720 mostly transparent foreground segment. Foreground pillar edges near far sides, sparse hanging paper charms near top, faint dust haze. Keep archive and player silhouettes clear.` |
| `level3_near_z02.png` | `3734x720` | 大量透明 | 档案区纸符、尘雾和边缘柱影。 | `Create Level 3 Near Zone 02, 3734x720 mostly transparent foreground segment. Old paper charm edges, dust and incense haze, subtle pillar silhouettes at edges. Do not cover archive-note interactables.` |
| `level3_near_z03.png` | `3733x720` | 大量透明 | 内殿烛光雾和狐火边缘。 | `Create Level 3 Near Zone 03, 3733x720 mostly transparent foreground segment. Candle haze, soft foxfire mist near final reveal edges, sparse hanging paper strips. Keep final plaque and fox area readable, no dense central clutter.` |

### 6.7 兼容旧背景

这些文件目前作为旧版兼容或主菜单备用，不是三章主地图的核心分段背景。仍可替换，但优先级低于 `level1/2/3_*`。

| 文件 | 尺寸 | 建议内容 |
|---|---:|---|
| `assets/backgrounds/sky.png` | `1280x720` | 通用夜空或菜单底色 |
| `assets/backgrounds/far_mountains.png` | `3840x720` | 通用远山循环层 |
| `assets/backgrounds/near_trees.png` | `3840x720` | 通用近景树林循环层 |
| `assets/backgrounds/fog.png` | `1280x720` | 半透明雾层 |
| `assets/backgrounds/shrine_interior.png` | `1280x720` | 旧内殿背景备用 |

## 7. UI 素材

UI 是高清细边像素风，不要做粗糙纯色按钮。文字由 Godot 字体渲染，PNG 内不要写中文或英文。

| 文件 | 尺寸 | 用途 | 生成 Prompt |
|---|---:|---|---|
| `assets/ui/dialog_box.png` | `960x192` | 对话框 `StyleBoxTexture` | `Create a 960x192 transparent nine-slice capable dialogue box texture for a refined shrine folklore 2D game UI. Thin pixel-art border, dark translucent lacquer center, subtle gold and red trim, clean corners, no text.` |
| `assets/ui/choice_button.png` | `384x96` | 选择按钮 normal/hover/pressed 共用 | `Create a 384x96 transparent UI button texture. Thin pixel-art shrine border, dark wood center, warm highlight edge, readable at 1280x720, no text, suitable for nine-slice style stretching.` |
| `assets/ui/interact_hint.png` | `128x128` | 玩家头顶交互按键框 | `Create a 128x128 transparent interact hint key frame. Small shrine-paper charm frame with warm outline and a clear central safe area for a single Godot-rendered key letter such as E. Do not bake letters into the image. Longer action text is rendered beside the frame in Godot, not inside this PNG.` |
| `assets/ui/offering_tube.png` | `256x384` | HUD 供物栈容器 | `Create a 256x384 transparent HUD offering tube panel. Vertical wooden or paper talisman holder, fine pixel border, slots implied for stacked offerings, dark translucent interior, no text.` |

## 8. 音频占位替换规格

当前 WAV 是静音占位，路径已被脚本引用。替换时保留文件名和格式。BGM 建议 `44.1kHz` 或 `48kHz` WAV，循环自然，整体响度约 `-18 LUFS`。SFX 峰值不要超过 `-3 dB`。

| 文件 | 类型 | 长度建议 | 内容方向 |
|---|---|---:|---|
| `assets/audio/bgm/forest_night.wav` | BGM | `60-90s` loop | Level 1 夜林，低弦/木管/轻铃，温柔但不明亮 |
| `assets/audio/bgm/approach_theme.wav` | BGM | `60-90s` loop | Level 2 断参道，更多低频风声和不稳定节奏 |
| `assets/audio/bgm/shrine_theme.wav` | BGM | `60-120s` loop | Level 3 本社，庄重、慢速、带最终揭示张力 |
| `assets/audio/ambience/night_insects.wav` | Ambience | `30-90s` loop | 夜虫、远风、偶尔树叶，不要抢 BGM |
| `assets/audio/ambience/broken_approach.wav` | Ambience | `30-90s` loop | 山谷风、木板轻响、远处水声 |
| `assets/audio/ambience/shrine_roomtone.wav` | Ambience | `30-90s` loop | 室内低频、木梁轻响、微弱纸门声 |
| `assets/audio/sfx/bell.wav` | SFX | `0.6-2.0s` | 铃绳机关，铜铃加绳索摩擦 |
| `assets/audio/sfx/collect.wav` | SFX | `0.2-0.7s` | 拾取供物，轻木/纸/铃亮点 |
| `assets/audio/sfx/footstep.wav` | SFX | `0.1-0.25s` | 通用脚步，布鞋踩石土，可后续按地形分层 |
| `assets/audio/sfx/interact.wav` | SFX | `0.1-0.5s` | 读碑、确认、轻触木石 |
| `assets/audio/sfx/jump.wav` | SFX | `0.1-0.35s` | 布料和脚步起跳，轻 |
| `assets/audio/sfx/altar.wav` | SFX | `0.8-2.5s` | 祭坛确认，低铃和狐火呼吸 |
| `assets/audio/sfx/foxfire.wav` | SFX | `0.5-2.0s` | 狐火出现，柔和火焰加空气颤动 |
| `assets/audio/sfx/paper_door.wav` | SFX | `0.5-1.5s` | 纸门或档案翻动，干燥纸声 |

## 9. 替换检查清单

1. PNG 文件尺寸必须和表格一致，sprite sheet 总宽度必须等于 `单帧宽 x 帧数`。
2. 所有角色和物件打开后，脚底或落地点应在单帧底边中心附近。
3. 背景图不需要左右循环；必须是关卡等宽长图，zone 边界不要突然换色、换透视或硬切。
4. TileSet 不要移动格子语义。即使某些 tile 当前地图暂未大量使用，也要按本表完成，方便后续直接在 Godot Editor 中铺图。
5. UI PNG 内不要烘焙文字。中文、按钮文字、提示文字由 Godot 控件显示。
6. 替换后运行 Godot 导入，确认没有尺寸导致的导入错误或场景错位。
