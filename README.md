# Okuri Kitsune / 送狐

<p>
  <a href="#中文"><kbd>中文</kbd></a>
  <a href="#english"><kbd>English</kbd></a>
</p>

## 中文

这是 Godot 版《送狐 / Okuri Kitsune》的项目仓库，包含源工程、游戏素材、场景脚本，以及已经导出的 macOS 和 Windows 可执行版本。

### 目录说明

| 目录 | 用途 |
| --- | --- |
| `assets/` | 游戏美术、音频、背景、UI 等素材。 |
| `autoload/` | Godot 全局脚本，例如游戏状态、对话和存档逻辑。 |
| `data/` | 游戏数据配置。 |
| `i18n/` | 中文和英文翻译资源。 |
| `scenes/` | Godot 场景文件，包括关卡、角色、UI、过场动画和互动对象。 |
| `tools/` | 辅助生成、检查和构建脚本。 |
| `exports/` | 已导出的可玩版本。 |
| `project.godot` | Godot 项目入口文件。 |
| `export_presets.cfg` | macOS 和 Windows 导出配置。 |

### 如何游玩

本仓库使用 Git LFS 保存大体积素材和可执行文件。克隆后请先运行：

```bash
git lfs install
git lfs pull
```

macOS：打开 `exports/macos/playable/送狐 OKURI KITSUNE.app`。如果系统提示来自未识别开发者，请右键点击 app，选择“打开”。

Windows：打开 `exports/windows/OKURI KITSUNE.exe`。

也可以用 Godot 4.6 或更新版本打开 `project.godot`，从编辑器运行或重新导出。

## English

This is the Godot project repository for *Okuri Kitsune / 送狐*. It includes the source project, game assets, scenes, scripts, and exported playable builds for macOS and Windows.

### Directory Guide

| Path | Purpose |
| --- | --- |
| `assets/` | Game art, audio, backgrounds, UI, and other assets. |
| `autoload/` | Godot global scripts for game state, dialogue, and save logic. |
| `data/` | Game data configuration. |
| `i18n/` | Chinese and English translation resources. |
| `scenes/` | Godot scenes for levels, characters, UI, cutscenes, and interactive objects. |
| `tools/` | Helper scripts for generation, checks, and builds. |
| `exports/` | Exported playable builds. |
| `project.godot` | Godot project entry file. |
| `export_presets.cfg` | macOS and Windows export settings. |

### How To Play

This repository uses Git LFS for large assets and executable files. After cloning, run:

```bash
git lfs install
git lfs pull
```

macOS: open `exports/macos/playable/送狐 OKURI KITSUNE.app`. If macOS blocks it as an unidentified app, right-click the app and choose **Open**.

Windows: open `exports/windows/OKURI KITSUNE.exe`.

You can also open `project.godot` with Godot 4.6 or newer to run or export the game from the editor.
