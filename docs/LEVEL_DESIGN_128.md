# Song Hu 128 HD Level Design

All coordinates are Godot pixels in a `1280x720` viewport. Floor baseline is usually `y=512`; the player origin is the feet.

## Shared Scene Layers
`BackgroundZones`, `Background_Far`, `Background_Mid`, `Background_Near`, `Terrain`, `OneWayPlatforms`, `PropsBack`, `Items`, `Narrative`, `Actors`, `Mechanisms`, `PropsFront`, `Lighting`, `FX`, `HUD`, `Audio`.

## Zone Background Runtime
The current build uses full-width zone-authored background layers with runtime camera parallax, not looping `Parallax2D` ribbons. Each level has three long `Sprite2D` background textures with `centered = false`. Editor `position` is preserved as the base offset, and `LevelBase` adds runtime parallax movement on top of that offset. Editor `scale.x` is preserved as a multiplier for the automatic width fit, while `scale.y` is kept exactly as authored.

| Layer | Node | Texture Size | Parallax Factor | Z Index | Repeat |
|---|---|---:|---:|---:|---|
| Far | `Background_Far` | level width x `720` | `0.78` | `-80` | none |
| Mid | `Background_Mid` | level width x `720` | `0.90` | `-70` | none |
| Near | `Background_Near` | level width x `720` | `0.98` | `-60` | none |

`BackgroundZones/Zone01-03` are meaningful editor reference markers. They divide each level into world-coordinate thirds for background planning and QA. They still do not run gameplay logic. Because the layers parallax at runtime, background landmarks are region-aligned rather than pixel-locked to gameplay objects.

| Level | World Width | Background Size | Zone01 | Zone02 | Zone03 |
|---|---:|---:|---:|---:|---:|
| Level 1 | `9600` | `9600x720` | `0-3200` | `3200-6400` | `6400-9600` |
| Level 2 | `12800` | `12800x720` | `0-4267` | `4267-8533` | `8533-12800` |
| Level 3 | `11200` | `11200x720` | `0-3733` | `3733-7467` | `7467-11200` |

The player stands on a baseline near `y=512`; the visible body usually occupies `y=248-512`. Keep the `y=280-560` background band low-contrast so items, NPCs, tablets, platforms, and shrine props remain readable.

## Editor Readability Rules
- No scene node should use Godot auto names such as `@Area2D@23`, `@Sprite2D@11`, or `@CollisionShape2D@13`.
- Repeated props must carry semantic suffixes, for example `StoneLantern_ForestBend`, `ToriiLarge_AltarGate`, `LanternLight_HiddenRoute`.
- Instanced scenes should expose root-level override properties such as `item_id`, `item_texture`, and `level_width`; level scenes must not save internal children of instances.
- If a reusable scene needs a different sprite, add an exported property to the reusable scene script instead of editing `Visual/Sprite` from the parent level.

## Level 1: Village Gate To Dressing Shrine
- Width: `9600px` (`75` tiles).
- Flow: village gate shrine -> cedar teaching path -> old torii -> low platform pickup -> altar choice.
- Main floor tile row: `4`; lower fill rows: `5-7`.

| Beat | X Range | Key Nodes |
|---|---:|---|
| Village gate | `0-1600` | player `160,512`, elder `420,512`, tablet `760,512`, item `sugi_wood 1180,448`, `ToriiSmall_VillageGate` |
| Cedar tutorial | `1600-3600` | one-way platforms, tablet `2480,384`, item `white_fur 3260,320` |
| Old torii | `3600-5600` | `ToriiLarge_OldTorii`, `FoxfireHint_OldTorii`, lanterns, item `mugwort 5400,448` |
| Low platform route | `5600-7600` | readable tablet, mild jump checks |
| Altar choice | `7600-9600` | altar `8840,512`, top-offering previews, fox marker `8540,420`, transition to Level 2 |

## Level 2: Broken Approach
- Width: `12800px` (`100` tiles).
- Flow: cliff -> bridge puzzle -> bell rope -> hidden offering path -> second altar.
- Bridge and hidden platform are preplaced `StaticBody2D` nodes under `Mechanisms`.

| Mechanism | Initial | Trigger | Result |
|---|---|---|---|
| `Bridge` | invisible, collision disabled | interact near `BridgeMarker 1660,512` while stack top is `sugi_wood` | visible and collision enabled |
| `HiddenPlatform` | invisible, collision disabled | pull `BellRope` | fades in and enables collision |

| Beat | X Range | Key Nodes |
|---|---:|---|
| Broken cliff | `0-3200` | item `sugi_wood 900,448`, bridge marker `2300,512` |
| Cedar bridge | `3200-5600` | item `sugi_wood 3420,448`, tablet |
| Bell mechanism | `5600-7600` | bell rope `6400,128`, item `white_fur 6200,448` |
| Hidden route | `7600-10000` | hidden platform, item `water_grass 7600,288` |
| Second altar | `10000-12800` | altar `11840,512`, transition to Level 3 |

## Level 3: Main Shrine And Inner Hall
- Width: `11200px` (`88` tiles).
- Flow: outer corridor -> archive points 1-3 -> raised platform -> archive points 4-5 -> plaque reveal -> final choice.

| Archive | Position | Visual |
|---:|---:|---|
| 1 | `1200,512` | visible wooden note |
| 2 | `2400,512` | visible plaque |
| 3 | `3600,512` | torn paper |
| 4 | `6200,384` | raised platform tablet |
| 5 | `7600,512` | inner hall record |

Final plaque marker: `9800,320`; fox spawn marker: `10100,420`. The script checks marker distance and truth-revealed state; the plaque object remains editable in the scene.

## Playability Targets
- Player speed `260px/s`; jump `-560px/s`; gravity `980px/s^2`; max fall `720px/s`.
- A full tile vertical rise is `128px`; jump height is tuned to clear one-tile one-way platforms without forcing pixel-perfect input.
- Horizontal travel contains a pickup, readable object, visual landmark, or jump/interaction beat every `800-1400px`.
- No required gameplay object is runtime-drawn. Runtime scripts only toggle visibility/collision or play dialogue/audio.
