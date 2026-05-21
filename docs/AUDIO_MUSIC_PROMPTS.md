# 《送狐》音乐与音效 Prompt 设计文档

## 1. 文档用途

本文档用于正式存放《送狐》的音乐、环境声和交互音效设计方案，方便后续使用 Suno / Suno Sounds 生成音频素材，并接入 Godot 工程。

当前工程已经存在以下占位音频路径：

| 类型 | 当前路径 | 当前用途 |
|---|---|---|
| BGM | `assets/audio/bgm/forest_night.wav` | 第一关夜林 / 装束之祠 |
| BGM | `assets/audio/bgm/approach_theme.wav` | 第二关断参道 |
| BGM | `assets/audio/bgm/shrine_theme.wav` | 第三关本社 |
| Ambience | `assets/audio/ambience/night_insects.wav` | 第一关夜虫与远风 |
| Ambience | `assets/audio/ambience/broken_approach.wav` | 第二关断参道环境 |
| Ambience | `assets/audio/ambience/shrine_roomtone.wav` | 第三关本社室内环境 |
| SFX | `assets/audio/sfx/*.wav` | 通用交互、拾取、铃、祭坛、狐火等 |

替换已有占位文件时，应保持文件名和路径不变。新增分支 BGM 或揭示音效时，可在 `assets/audio/bgm/`、`assets/audio/ambience/`、`assets/audio/sfx/` 下新增文件，再由关卡脚本按剧情状态切换。

## 2. 整体音乐原则

《送狐》的音乐不应只按关卡换风格，而应配合玩家对仪式的理解逐渐变化：

1. 第一关让玩家相信仪式是正确的：音乐平和、民俗、夜林感强，但不能过于明亮。
2. 第二关让玩家开始怀疑供物的真实用途：音乐更紧张，节奏更不稳定。
3. 第三关把误读翻成真相：音乐转为阴暗、室内、调查感和压迫感。
4. 最终选择处应明显抽空音乐，让玩家听见长明灯、远铃、低频心跳等细节。
5. A 路线代表安抚白狐，音乐应更克制、悲伤、留有呼吸。
6. B 路线代表刺激白狐，音乐应更急促、阴森、低频更近，狐火与影子变化更强。

## 3. Suno 生成建议

### 3.1 BGM 生成方式

使用 Suno 的 `Custom` 模式，并开启 `Instrumental`。把本文档中的英文 prompt 放入音乐风格描述区域。

生成后建议处理：

1. 选择最干净、最少突兀旋律的一版。
2. 剪成自然循环，BGM 通常保留 `60-90s`，第三关可保留 `90-120s`。
3. 导出为 WAV，建议 `44.1kHz` 或 `48kHz`。
4. 统一响度约 `-18 LUFS`。
5. 检查循环点，避免开头和结尾有明显断裂。

### 3.2 SFX 与环境声生成方式

使用 Suno Sounds：

| 音频类型 | Suno Sounds 类型 | 建议长度 |
|---|---|---:|
| 单次交互音效 | One Shot | `0.2-3.0s` |
| 揭示音效 / 结局短音效 | One Shot | `1.5-4.0s` |
| 环境声 | Loop | `30-90s` |

SFX 峰值不要超过 `-3 dB`。交互音效要短、清楚、不要带长音乐尾巴；环境声不要抢 BGM。

## 4. 游戏流程与音乐触发

| 阶段 | 游戏内容 | 音乐设计 | 触发条件 | 建议文件 |
|---|---|---|---|---|
| 标题 / 开场 | 村里异常、狐火未归、童谣、见习巫女上山 | 稀薄童谣动机，像记忆碎片 | `opening.tscn` 开始 | `assets/audio/bgm/opening_memory.wav` |
| 第一关 | 装束之祠，收集杉木、白毛、蓬草，第一次顶礼 | 平和夜林，但带不安；低弦、木管、远铃 | `level_1.gd` ready | `assets/audio/bgm/forest_night.wav` |
| 第一关 A | 选旧铃铛，安抚白狐 | 短铃声、风停、白狐安静出现 | L1 祭坛成功后选 A | `assets/audio/sfx/branch_a_bell_accept.wav` |
| 第一关 B | 选狐火石，逼白狐现形 | 火纹、低频冲击、影子短暂变人 | L1 祭坛成功后选 B | `assets/audio/sfx/branch_b_foxfire_force.wav` |
| 第二关 A 路 | 白狐等玩家，断参道仍危险 | 紧张但克制，像谨慎前进 | L1 分支为 A，进入 L2 | `assets/audio/bgm/approach_a_tense.wav` |
| 第二关 B 路 | 狐火很急，焦黑脚印和人影更明显 | 更快、更阴森、低鼓更近 | L1 分支为 B，进入 L2 | `assets/audio/bgm/approach_b_panic.wav` |
| 第二关机关 | 搭桥、搭梯、拉铃、取灯油 | 每个动作有明确 SFX | 对应交互点按 E | 见 SFX 表 |
| 第二关 A2 | 清水草压火 | 蓝火降温，节奏放慢 | L2 选择清水草 | `assets/audio/sfx/water_grass_calm.wav` |
| 第二关 B2 | 灯芯油添火 | 火势暴涨，影子拉长 | L2 选择灯芯油 | `assets/audio/sfx/lamp_oil_flare.wav` |
| 第三关 | 本社完整但空，五个档案逐步揭示 | 阴暗室内、慢速、调查压迫 | `level_3.gd` ready | `assets/audio/bgm/shrine_theme.wav` |
| 第三关真相推进 | 迎狐变送狐、白毛变白衣、白狐变纱夜 | 使用短揭示音效，不换成大悲歌 | 解锁解释面板、匾额、纸条复查、人影出现 | 见 reveal SFX 表 |
| 最终选择 | 不呼唤 vs 叫出纱夜 | 音乐抽空，只留长明灯、心跳、远铃 | 最终 choice 显示前 | `assets/audio/bgm/final_choice_void.wav` |
| 结局 A | 村庄恢复，纱夜被遗忘 | 表面安定但冷，铃声干净，尾音空 | `ending_a.tscn` | `assets/audio/bgm/ending_a_eternal_lamp.wav` |
| 结局 B | 纱夜回名，灾厄与记忆一起回来 | 情感释放和灾厄回潮同时存在 | `ending_b.tscn` | `assets/audio/bgm/ending_b_name_return.wav` |

## 5. BGM Prompt 合集

### 5.1 Opening Memory

| 项目 | 内容 |
|---|---|
| 建议文件 | `assets/audio/bgm/opening_memory.wav` |
| 时长 | `45-60s` |
| 循环 | 不需要循环 |
| 放置位置 | 开场 cutscene |
| 触发条件 | `opening.tscn` 开始时播放 |

Prompt:

```text
Instrumental Japanese folklore horror opening cue for a 2D narrative puzzle game. Sparse koto harmonics, distant shrine bell, breathy shakuhachi, soft rain, a broken children’s song motif played only as notes, no vocals, no drums, no modern synth lead. Quiet, intimate, unsettling memory, slow tempo, cinematic game intro.
```

### 5.2 Forest Night

| 项目 | 内容 |
|---|---|
| 建议文件 | `assets/audio/bgm/forest_night.wav` |
| 时长 | `60-90s` |
| 循环 | 无缝循环 |
| 放置位置 | 第一关：装束之祠 |
| 触发条件 | `level_1.gd` 的 `_on_level_ready()` |

Prompt:

```text
Seamless loop instrumental for a calm but uneasy night forest shrine path. Soft low strings, gentle woodwinds, distant suzu bell, light hand percussion, subtle insects and wind bed. Japanese folk ritual atmosphere, peaceful on the surface but slightly haunted, no vocals, no melody that feels heroic, suitable for 2D exploration.
```

### 5.3 Approach A Tense

| 项目 | 内容 |
|---|---|
| 建议文件 | `assets/audio/bgm/approach_a_tense.wav` |
| 时长 | `60-90s` |
| 循环 | 无缝循环 |
| 放置位置 | 第二关：断参道，A 路线 |
| 触发条件 | 第一关选择旧铃铛，进入第二关 |

Prompt:

```text
Seamless loop instrumental for a broken mountain shrine approach, restrained tension. Low taiko heartbeat very soft, bowed strings, bamboo flute fragments, wet stone ambience, distant foxfire shimmer. The white fox is being calmed, so keep the music controlled and sorrowful, tense but not aggressive, no vocals.
```

### 5.4 Approach B Panic

| 项目 | 内容 |
|---|---|
| 建议文件 | `assets/audio/bgm/approach_b_panic.wav` |
| 时长 | `60-90s` |
| 循环 | 无缝循环 |
| 放置位置 | 第二关：断参道，B 路线 |
| 触发条件 | 第一关选择狐火石，进入第二关 |

Prompt:

```text
Seamless loop instrumental for a cursed broken shrine road after the player forces foxfire brighter. Faster pulse, unstable low drums, scraping strings, distorted shrine bell, cold wind, fire crackle textures. Dark Japanese folk horror, urgent, sinister, claustrophobic, no vocals, no modern EDM beat, loopable game BGM.
```

### 5.5 Shrine Theme

| 项目 | 内容 |
|---|---|
| 建议文件 | `assets/audio/bgm/shrine_theme.wav` |
| 时长 | `90-120s` |
| 循环 | 无缝循环 |
| 放置位置 | 第三关：本社 |
| 触发条件 | `level_3.gd` 的 `_on_level_ready()` |

Prompt:

```text
Seamless loop instrumental for an abandoned main shrine interior that is perfectly preserved but empty. Slow ritual drone, low cello, koto plucks with long silence, paper door creaks, distant bell resonance, cold room tone. Investigative, sacred, oppressive, tragic, no vocals, no big climax, suitable for reading clues.
```

### 5.6 Final Choice Void

| 项目 | 内容 |
|---|---|
| 建议文件 | `assets/audio/bgm/final_choice_void.wav` |
| 时长 | `30-45s` |
| 循环 | 可循环 |
| 放置位置 | 第三关最终选择前 |
| 触发条件 | 白狐回头、人影显现、最终选择框出现前 |

Prompt:

```text
Minimal loop for a final moral choice in a folklore horror game. Almost no rhythm, distant shrine bell, low heartbeat-like drum, faint lamp flame, cold air, unresolved suspended strings. Intimate dread and grief, silence between notes, no vocals, no cinematic explosion, designed to sit under dialogue.
```

### 5.7 Ending A: Eternal Lamp

| 项目 | 内容 |
|---|---|
| 建议文件 | `assets/audio/bgm/ending_a_eternal_lamp.wav` |
| 时长 | `60-90s` |
| 循环 | 不强制循环 |
| 放置位置 | 结局 A |
| 触发条件 | 玩家选择不呼唤纱夜，进入 `ending_a.tscn` |

Prompt:

```text
Instrumental ending cue for a tragic ritual completed. Warm shrine bells and soft koto suggest peace, but underneath is a cold drone and lonely bowed strings. Bittersweet, restrained, village saved but a forgotten child remains trapped. No vocals, slow tempo, delicate, sorrow under calm.
```

### 5.8 Ending B: Name Return

| 项目 | 内容 |
|---|---|
| 建议文件 | `assets/audio/bgm/ending_b_name_return.wav` |
| 时长 | `60-90s` |
| 循环 | 不强制循环 |
| 放置位置 | 结局 B |
| 触发条件 | 玩家叫出纱夜，进入 `ending_b.tscn` |

Prompt:

```text
Instrumental ending cue for calling back a lost sister’s name. Starts with fragile koto and breathy flute, then rising low strings, water surge, unstable bells, foxfire dissolving into human warmth. Emotional release mixed with disaster returning, tragic but alive, no vocals, cinematic folklore horror.
```

## 6. 环境声 Prompt 合集

| 名称 | 建议文件 | 时长 | 循环 | 触发条件 | Prompt |
|---|---|---:|---|---|---|
| 夜虫环境 | `assets/audio/ambience/night_insects.wav` | `30-90s` | 是 | 第一关开始 | `Looping quiet night forest ambience, insects, distant wind through cedar trees, very subtle shrine bell far away, no music, clean loop.` |
| 断参道环境 | `assets/audio/ambience/broken_approach.wav` | `30-90s` | 是 | 第二关开始 | `Looping broken mountain path ambience, wet stone, valley wind, distant water, occasional wood creak, tense but not musical, clean loop.` |
| 本社室内环境 | `assets/audio/ambience/shrine_roomtone.wav` | `30-90s` | 是 | 第三关开始 | `Looping abandoned shrine interior room tone, low wooden beams creaking, paper door rustle, faint lamp flame, cold air, no melody.` |

## 7. SFX Prompt 合集

### 7.1 通用与移动

| 音效 | 建议文件 | 时长 | 触发条件 | Prompt |
|---|---|---:|---|---|
| 拾取供物 | `assets/audio/sfx/collect.wav` | `0.2-0.5s` | 拾取普通供物、打开箱后获得物品 | `One shot UI pickup sound, soft wooden click, tiny shrine bell sparkle, paper charm rustle, warm but restrained.` |
| 通用交互 | `assets/audio/sfx/interact.wav` | `0.1-0.5s` | 读碑、确认、轻触木石 | `One shot quiet interaction sound, fingertip touching old wood or stone, small paper charm rustle, subtle shrine room echo.` |
| 脚步 | `assets/audio/sfx/footstep.wav` | `0.1-0.25s` | 玩家行走 | `One shot soft cloth shoe footstep on damp stone and soil, quiet game movement sound, no echo tail.` |
| 跳跃 | `assets/audio/sfx/jump.wav` | `0.1-0.35s` | 玩家跳跃 | `One shot light jump sound, cloth movement, small foot push from wet stone, soft and natural, no cartoon bounce.` |
| 木桥脚步 | `assets/audio/sfx/footstep_wood_bridge.wav` | `0.15-0.35s` | 玩家走过木桥时，可后续分地形接入 | `One shot footstep on wet wooden plank, light cloth shoe, small creak, soft impact, game movement sound.` |

### 7.2 供物与机关

| 音效 | 建议文件 | 时长 | 触发条件 | Prompt |
|---|---|---:|---|---|
| 砍杉木 | `assets/audio/sfx/chop_sugi_wood.wav` | `0.6-1.2s` | 采集杉木 | `One shot sound effect, small axe cutting wet cedar wood, dull chop, fibers split, soft forest reverb, game item harvest.` |
| 采蓬草 | `assets/audio/sfx/harvest_mugwort.wav` | `0.3-0.8s` | 采集蓬草 | `One shot sound effect, hand cutting and pulling wet mugwort grass, soft leaves, damp roots, small water droplets, gentle game pickup.` |
| 采清水草 | `assets/audio/sfx/harvest_water_grass.wav` | `0.3-0.8s` | 第二关隐藏平台采集清水草 | `One shot sound effect, hand gathering cold water grass, wet leaves, tiny droplets, soft magical chill, restrained game harvest.` |
| 打开白毛箱 | `assets/audio/sfx/old_chest_open.wav` | `0.8-1.5s` | 打开白毛 / 白衣线索箱 | `One shot sound effect, old wooden chest opening, damp hinge, paper and cloth inside shifting, quiet shrine reverb, eerie but subtle.` |
| 搭木桥 | `assets/audio/sfx/place_bridge.wav` | `0.8-1.4s` | 第二关铺设桥 | `One shot sound effect, wet cedar plank placed across broken stone gap, heavy wood thud, stones shifting, short valley echo.` |
| 搭梯子 | `assets/audio/sfx/place_ladder.wav` | `0.8-1.4s` | 第二关使用杉木搭梯 | `One shot sound effect, wooden ladder or cedar beam leaned against stone ledge, rope scrape, damp wood knock, short echo.` |
| 拉铃 | `assets/audio/sfx/bell.wav` | `1.2-2.5s` | 第二关拉动铃绳，隐藏平台出现 | `One shot old shrine bell pulled by wet rope, rope strain, dull bronze bell, long valley echo, supernatural platform appears.` |
| 蓝火取油 | `assets/audio/sfx/take_lamp_oil.wav` | `0.8-1.8s` | 从蓝火油灯提取灯芯油 | `One shot blue foxfire oil extraction, glass vial, flame lowering, airy magical suction, cold fire crackle, eerie.` |
| 祭坛成功 | `assets/audio/sfx/altar.wav` | `1.5-3.0s` | 祭坛确认供物顺序成功 | `One shot ritual altar accepts offerings, low shrine bell, wood settling, foxfire breath, soft sub bass, sacred and ominous.` |
| 祭坛失败 | `assets/audio/sfx/altar_fail.wav` | `0.8-1.5s` | 供物顺序错误 | `One shot failed ritual altar sound, hollow wood knock, reversed bell shimmer, cold wind through cracks, restrained horror feedback.` |

### 7.3 分支与揭示

| 音效 | 建议文件 | 时长 | 触发条件 | Prompt |
|---|---|---:|---|---|
| A 路旧铃铛接受 | `assets/audio/sfx/branch_a_bell_accept.wav` | `1.0-2.0s` | 第一关选择旧铃铛 | `One shot soft shrine bell acceptance sound, wind calming, tiny paper charm movement, white fox appears peacefully, gentle but sad.` |
| B 路狐火石催逼 | `assets/audio/sfx/branch_b_foxfire_force.wav` | `1.0-2.5s` | 第一关选择狐火石 | `One shot foxfire stone ignition, sudden flame crawl through wood grain, low ominous hit, shadow stretches, supernatural pressure.` |
| 清水草压火 | `assets/audio/sfx/water_grass_calm.wav` | `0.8-1.8s` | 第二关选择清水草 | `One shot water grass placed over blue foxfire, steam cooling, flame softens, low tension releases slightly, magical but restrained.` |
| 灯芯油添火 | `assets/audio/sfx/lamp_oil_flare.wav` | `1.0-2.5s` | 第二关选择灯芯油 | `One shot lamp oil poured into foxfire, sudden blue flame flare, rushing heat, distorted shrine bell, shadow becomes more human.` |
| 狐火出现 | `assets/audio/sfx/foxfire.wav` | `0.8-2.0s` | 狐火引路、白狐出现、关键机关变化 | `One shot foxfire apparition, soft flame whoosh, air shimmer, tiny bell grains, warm-to-cold magical fire, no explosion.` |
| 纸门 / 档案 | `assets/audio/sfx/paper_door.wav` | `0.5-1.2s` | 第三关阅读档案、纸门、人影前置 | `One shot old paper door and archive scroll movement, dry paper scrape, faint wood frame creak, close quiet sound.` |
| 匾额剥落 | `assets/audio/sfx/plaque_reveal.wav` | `1.5-3.0s` | 第三关用狐火照匾额，迎狐变送狐 | `One shot old shrine plaque gold paint peeling under foxfire, tiny cracking lacquer, fire lick, wood groan, truth reveal sting.` |
| 纸条揭开 | `assets/audio/sfx/paper_patch_release.wav` | `0.8-1.6s` | 第三关复查衣箱，白毛变白衣 | `One shot damp paper patch loosening from an old clothing tag, soft tear, wet paper release, quiet realization sting.` |
| 人影显现 | `assets/audio/sfx/sayo_shadow_reveal.wav` | `2.0-4.0s` | 白狐影子变成穿白衣的孩子 | `One shot supernatural reveal, fox shadow stretching into a human child silhouette, low string swell, breath, lamp flame tremble, tragic horror.` |

## 8. 推荐接入顺序

### 8.1 第一阶段：替换现有占位

优先替换当前已被代码引用的音频：

1. `assets/audio/bgm/forest_night.wav`
2. `assets/audio/bgm/approach_theme.wav`
3. `assets/audio/bgm/shrine_theme.wav`
4. `assets/audio/ambience/night_insects.wav`
5. `assets/audio/ambience/broken_approach.wav`
6. `assets/audio/ambience/shrine_roomtone.wav`
7. `assets/audio/sfx/collect.wav`
8. `assets/audio/sfx/interact.wav`
9. `assets/audio/sfx/jump.wav`
10. `assets/audio/sfx/footstep.wav`
11. `assets/audio/sfx/bell.wav`
12. `assets/audio/sfx/altar.wav`
13. `assets/audio/sfx/foxfire.wav`
14. `assets/audio/sfx/paper_door.wav`

这一阶段不需要改代码，只需要保证文件路径和格式不变。

### 8.2 第二阶段：接入第二关 A / B 分支 BGM

新增：

1. `assets/audio/bgm/approach_a_tense.wav`
2. `assets/audio/bgm/approach_b_panic.wav`

建议触发逻辑：

```gdscript
if GameManager.is_a_path():
	play_bgm(preload("res://assets/audio/bgm/approach_a_tense.wav"))
else:
	play_bgm(preload("res://assets/audio/bgm/approach_b_panic.wav"))
```

触发位置：`scenes/levels/level_2.gd` 的 `_on_level_ready()`。

### 8.3 第三阶段：接入关键 SFX

新增并接入以下高优先级音效：

1. `place_bridge.wav`
2. `place_ladder.wav`
3. `take_lamp_oil.wav`
4. `branch_a_bell_accept.wav`
5. `branch_b_foxfire_force.wav`
6. `water_grass_calm.wav`
7. `lamp_oil_flare.wav`
8. `plaque_reveal.wav`
9. `paper_patch_release.wav`
10. `sayo_shadow_reveal.wav`

这些音效会明显增强玩家对“供物其实是送行工具”“白狐其实是纱夜”的理解。

### 8.4 第四阶段：最终选择与结局音乐

新增：

1. `assets/audio/bgm/final_choice_void.wav`
2. `assets/audio/bgm/ending_a_eternal_lamp.wav`
3. `assets/audio/bgm/ending_b_name_return.wav`

最终选择音乐建议在 `show_choice("要叫出她的名字吗？", ...)` 前切入。结局音乐建议分别在 `ending_a.gd` 和 `ending_b.gd` 的 `_ready()` 或 `_start()` 开头播放。

## 9. 音频命名建议

| 类别 | 命名规则 | 示例 |
|---|---|---|
| 关卡 BGM | `level_or_area + mood` | `approach_a_tense.wav` |
| 分支 BGM | `area + branch + mood` | `approach_b_panic.wav` |
| 结局 BGM | `ending + key image` | `ending_a_eternal_lamp.wav` |
| 机关 SFX | `verb + object` | `place_bridge.wav` |
| 揭示 SFX | `story_object + reveal` | `sayo_shadow_reveal.wav` |

## 10. 验收标准

1. BGM 可以循环至少 3 次，不出现明显断点。
2. SFX 不遮挡对话文本出现时的阅读节奏。
3. 第一关听起来平和，但玩家不会误以为这是轻松冒险。
4. 第二关 A / B 分支有明显强度差异，但仍属于同一个游戏的音色体系。
5. 第三关音乐留出足够空间给档案阅读，不要旋律过满。
6. 最终选择处音乐必须明显降密度，突出玩家选择的重量。
7. 结局 A 不能听起来像纯好结局；结局 B 不能听起来像纯坏结局。
8. 所有导入 Godot 的 WAV 音量统一，不出现某条音频突然过响。
