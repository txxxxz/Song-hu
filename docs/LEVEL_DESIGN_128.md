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
- Flow: background cutscene -> elder handoff and HUD reveal -> wooden requirement plaque -> platform-supported offering route -> altar choice -> shrine gate portal.
- Design intent: L1 should minimize explicit explanation. The cutscene carries village unease, the elder gives the duty and the offering tube, the plaque gives the ritual requirement, and the map itself teaches order through offering placement and route shape.
- Main floor tile row: `4`; lower fill rows: `5-7`.

| Beat | X Range | Key Nodes |
|---|---:|---|
| Village gate | `0-1600` | player `160,512`, elder `470,512`, wooden plaque `760,512`, `SugiTreeSource` for chopping `sugi_wood`, `ToriiSmall_VillageGate`, HUD hidden until elder handoff |
| Cedar platform | `1600-3600` | one-way platform route,童谣札记 `2480,384`, `WhiteFurChest` containing `white_fur`; platform is part of the offering route, not decoration |
| Old torii rise | `3600-5600` | `ToriiLarge_OldTorii`, flickering foxfire guide, `MugwortGrassSource` for harvesting `mugwort` from a grass pile reached by the second raised route |
| Quiet approach | `5600-7600` | rain-damaged note, sparse guide foxfire, return to floor-level travel before the altar |
| Altar and portal | `7600-9600` | altar, interactable `bell_fiber` / `fox_stone` top offerings, fox marker, shrine portal marker; Level 2 transition requires entering the lit shrine gate |

## Level 2: Broken Approach
- Width: `12800px` (`100` tiles).
- Flow: cliff -> bridge puzzle -> corrupted post-bridge clue -> misordered offering yard -> ladder to high grass ledge -> bell rope -> blue-flame oil lantern -> second altar.
- Design intent: L2 deliberately stops feeding offerings in altar order. After the first bridge, the white-fur chest is seen before the cedar source; the damaged sign only exposes the middle slot, so players must infer the bottom/top slots from Level 1 and spend extra cedar as tools for bridges and the grass ladder.
- Bridge, ladder, oil, and hidden platform hooks are preplaced under `Mechanisms`.

| Mechanism | Initial | Trigger | Result |
|---|---|---|---|
| `Bridge` / `BridgeSecond` / `BridgeThird` | invisible, collision disabled | interact near the matching bridge marker while stack top is `sugi_wood` | consumes one cedar and enables the bridge |
| `LadderGrass` | hidden, collision disabled | interact near `LadderMarker 4240,512` while stack top is `sugi_wood` | consumes one cedar and enables a sloped cedar ladder the player can walk up |
| `OilMarker_HiddenRoute` | available once | interact at the blue-flame lantern | adds `lamp_oil`; ordinary warm lanterns do not expose this interaction |
| `HiddenPlatform` | invisible, collision disabled | pull `BellRope` | fades in and enables collision |

| Beat | X Range | Key Nodes |
|---|---:|---|
| Broken cliff | `0-3200` | `SugiTreeSource_bridge` for repeat cedar, `BridgeMarker 1660,512`, `Bridge 2300,512` |
| First far shore | `3200-5600` | `Tablet_RitualClue 3060,512`, `WhiteFurChest 3380,512`, `SugiTreeSource_altar 3920,512`, `LadderMarker 4240,512`, sloped `LadderGrass`, `MugwortGrassSource 4820,232` |
| Bell mechanism | `5600-7600` | `BridgeMarkerSecond 5760,512`, `BridgeSecond 6144,512`, bell rope `6400,128` |
| Hidden route | `7600-10000` | `BridgeMarkerThird 7280,512`, `BridgeThird 7936,512`, `HiddenPlatform 7240,352`, `OilMarker_HiddenRoute 9480,512` |
| Second altar | `10000-12800` | altar `11840,512`, transition to Level 3 |

## Level 3: Main Shrine Information Puzzle
- Width: `11200px` (`88` tiles).
- Flow: maintained community area -> ritual-name corridor -> dressing room -> raised archive loft -> inner archive -> stone steps and long-burning lamps.
- Design intent: L3 is no longer a collection route. It is an information puzzle where the player interacts with short contradictory records, then watches the interface assemble three interpretation links: `迎狐/送狐`, `白毛/白衣`, and `白狐/纱夜`.

| Room | X Range | Purpose | Key Nodes |
|---|---:|---|---|
| Maintained community | `0-1960` | Opening unease: complete architecture with no lived-in traces | `ArchiveTrigger1 1320,512`, `Foxfire_OldWood` |
| Name corridor | `1960-3520` | Establish that records say sending rather than receiving | `ArchiveTrigger2 2780,512` |
| Dressing room | `3520-5200` | Reframe white fur as white clothing | `ArchiveTrigger3 4240,512`, `DressingRoomLongTable` |
| Archive loft | `5200-7040` | Low-complexity raised reading platform for outfit order | `ArchiveTrigger4 5980,384`, `ShrineOneWay` |
| Inner archive | `7040-8880` | Name Sayo and tie the rule to family memory | `ArchiveTrigger5 7820,512` |
| Stone steps | `8880-11200` | Three-step reveal and final choice | `PlaqueMarker 9820,384`, `FoxSpawnMarker 10180,420` |

`ArchiveTrigger1-5` are interactable `info_clue.gd` nodes, not pickups. Reading them dims the physical record but keeps it in the room. The final plaque prompt is disabled until all five clues are understood.

The final reveal must stay staged:
1. Foxfire reveals `送狐` beneath `迎狐`.
2. The archive meaning flips from ritual blessing to child send-off.
3. The white fox shadow becomes a human shape, naming the sister as `纱夜`.

Ending A completes the ritual and restores stability, but the back-wall cuts imply erasure continues. Ending B breaks the ritual shell and makes memory return, without presenting either choice as a clean moral answer.

## Playability Targets
- Player speed `260px/s`; jump `-560px/s`; gravity `980px/s^2`; max fall `720px/s`.
- A full tile vertical rise is `128px`; jump height is tuned to clear one-tile one-way platforms without forcing pixel-perfect input.
- Horizontal travel contains a pickup, readable object, visual landmark, or jump/interaction beat every `800-1400px`.
- No required gameplay object is runtime-drawn. Runtime scripts only toggle visibility/collision or play dialogue/audio.
