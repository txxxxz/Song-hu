# Song Hu 128 HD Level Design

All coordinates are Godot pixels in a `1280x720` viewport. Floor baseline is usually `y=512`; the player origin is the feet.

## Shared Scene Layers
`BackgroundZones`, `Background_Far`, `Background_Mid`, `Background_Near`, `Terrain`, `OneWayPlatforms`, `PropsBack`, `Items`, `Narrative`, `Actors`, `Mechanisms`, `PropsFront`, `Lighting`, `FX`, `HUD`, `Audio`.

## Zone Background Runtime
The current build uses full-width zone-authored background layers, not looping `Parallax2D` ribbons. Level 1 and Level 2 backgrounds are native-width long strips matched to the shortened playable scene length, so they render at `scale.x = 1.0` instead of stretching a smaller panorama to fit.

| Layer | Node | Texture Size | Parallax Factor | Z Index | Repeat |
|---|---|---:|---:|---:|---|
| Far | `Background_Far` | level width x `720` | `1.0` | `-80` | none |
| Mid | `Background_Mid` | level width x `720` | `1.0` | `-70` | none |
| Near | `Background_Near` | level width x `720` | `1.0` | `-60` | none |

`BackgroundZones/Zone01-03` are meaningful editor reference markers. They divide each level into world-coordinate thirds for background planning and QA. They still do not run gameplay logic. Because the layers parallax at runtime, background landmarks are region-aligned rather than pixel-locked to gameplay objects.

| Level | World Width | Background Size | Zone01 | Zone02 | Zone03 |
|---|---:|---:|---:|---:|---:|
| Level 1 | `8000` | `8000x720` | `0-2667` | `2667-5333` | `5333-8000` |
| Level 2 | `10240` | `10240x720` | `0-3413` | `3413-6827` | `6827-10240` |
| Level 3 | `11200` | `11200x720` | `0-3733` | `3733-7467` | `7467-11200` |

The player stands on a baseline near `y=512`; the visible body usually occupies `y=248-512`. Keep the `y=280-560` background band low-contrast so items, NPCs, tablets, platforms, and shrine props remain readable.

## Editor Readability Rules
- No scene node should use Godot auto names such as `@Area2D@23`, `@Sprite2D@11`, or `@CollisionShape2D@13`.
- Repeated props must carry semantic suffixes, for example `StoneLantern_ForestBend`, `ToriiLarge_AltarGate`, `LanternLight_HiddenRoute`.
- Instanced scenes should expose root-level override properties such as `item_id`, `item_texture`, and `level_width`; level scenes must not save internal children of instances.
- If a reusable scene needs a different sprite, add an exported property to the reusable scene script instead of editing `Visual/Sprite` from the parent level.

## Level 1: Village Gate To Dressing Shrine
- Width: `8000px` (shortened to end shortly after the shrine portal).
- Flow: background cutscene -> elder handoff and HUD reveal -> wooden requirement plaque -> platform-supported offering route -> altar choice -> shrine gate portal.
- Design intent: L1 should minimize explicit explanation. The cutscene carries village unease, the elder gives the duty and the offering tube, the plaque gives the ritual requirement, and the map itself teaches order through offering placement and route shape.
- Main floor tile row: `4`; lower fill rows: `5-7`.

| Beat | X Range | Key Nodes |
|---|---:|---|
| Village gate | `0-1600` | player `160,512`, elder `470,512`, wooden plaque `760,512`, `SugiTreeSource` for chopping `sugi_wood`, `ToriiSmall_VillageGate`, HUD hidden until elder handoff |
| Cedar platform | `1600-3600` | one-way platform route,童谣札记 `2480,384`, `WhiteFurChest` containing `white_fur`; platform is part of the offering route, not decoration |
| Old torii rise | `3600-5600` | `ToriiLarge_OldTorii`, flickering foxfire guide, `MugwortGrassSource` for harvesting `mugwort` from a grass pile reached by the second raised route |
| Quiet approach | `5600-7600` | rain-damaged note, sparse guide foxfire, return to floor-level travel before the altar |
| Altar and portal | `6400-8000` | altar, interactable `bell_fiber` / `fox_stone` top offerings, fox marker, shrine portal marker; Level 2 transition requires entering the lit shrine gate |

## Level 2: Broken Approach
- Width: `10240px` (shortened to end shortly after the second altar gate).
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
| Second altar | `8800-10240` | altar `9158,554`, transition to Level 3 |

## Level 3: Main Shrine Information Puzzle
- Width: `11200px` (`88` tiles).
- Flow: 外大殿 -> 回廊 -> 内殿. The three-room layout keeps the investigation readable while preserving the five-record reveal chain.
- Design intent: L3 is no longer a collection route. It is an information puzzle where the player interacts with short contradictory records, then watches the interface assemble three interpretation links: `迎狐/送狐`, `白毛/白衣`, and `白狐/纱夜`.

| Room | X Range | Purpose | Key Nodes |
|---|---:|---|---|
| 外大殿 | `0-3400` | Opening unease: complete architecture with no lived-in traces, plus the altered old wooden plaque | `ArchiveTrigger1`, `PlaqueMarker`, `Foxfire_OldWood` |
| 回廊 | `3400-7200` | Read the bamboo slip, open the clothing chest, and compare the outfit-order tablet as a single evidence chain | `ArchiveTrigger2`, `ArchiveTrigger3` as paper chest, `ArchiveTrigger4`, `DressingRoomLongTable` |
| 内殿 | `7200-11200` | Name Sayo after the player rechecks the chest paper, then force the final choice | `ArchiveTrigger5` as a table bamboo slip, `FoxSpawnMarker` |

`ArchiveTrigger1`, `2`, `4`, and `5` are interactable `info_clue.gd` nodes. `ArchiveTrigger3` is an interactable clothing chest using `paper_chest_clue.gd`: opening it shows the blocked paper as a centered inspection overlay; after the entrance plaque changes, the same chest can be checked again to reveal the covered character. The archive sequence is gated in order, and the final plaque prompt is disabled until all five clues are understood and the player reaches the final hall.

The final reveal must stay staged:
1. The entrance plaque cycles from `迎狐之仪` to `送*之仪`, then foxfire changes it to `送狐之以`.
2. The protagonist is prompted to return to the clothing chest and recheck the paper slip.
3. The archive meaning flips from ritual blessing to child send-off.
4. The white fox shadow becomes a human shape, naming the sister as `纱夜`.

Ending A completes the ritual and restores stability, but the back-wall cuts imply erasure continues. Ending B breaks the ritual shell and makes memory return, without presenting either choice as a clean moral answer.

## Playability Targets
- Player speed `260px/s`; jump `-560px/s`; gravity `980px/s^2`; max fall `720px/s`.
- A full tile vertical rise is `128px`; jump height is tuned to clear one-tile one-way platforms without forcing pixel-perfect input.
- Horizontal travel contains a pickup, readable object, visual landmark, or jump/interaction beat every `800-1400px`.
- No required gameplay object is runtime-drawn. Runtime scripts only toggle visibility/collision or play dialogue/audio.
