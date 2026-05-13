from __future__ import annotations

import math
import shutil
import struct
import wave
import zlib
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


FONT = {
    " ": ["000", "000", "000", "000", "000"],
    "-": ["000", "000", "111", "000", "000"],
    "_": ["000", "000", "000", "000", "111"],
    "/": ["001", "001", "010", "100", "100"],
    ".": ["000", "000", "000", "000", "010"],
    ":": ["000", "010", "000", "010", "000"],
    "0": ["111", "101", "101", "101", "111"],
    "1": ["010", "110", "010", "010", "111"],
    "2": ["111", "001", "111", "100", "111"],
    "3": ["111", "001", "111", "001", "111"],
    "4": ["101", "101", "111", "001", "001"],
    "5": ["111", "100", "111", "001", "111"],
    "6": ["111", "100", "111", "101", "111"],
    "7": ["111", "001", "010", "010", "010"],
    "8": ["111", "101", "111", "101", "111"],
    "9": ["111", "101", "111", "001", "111"],
}

for ch, rows in {
    "A": ["010", "101", "111", "101", "101"],
    "B": ["110", "101", "110", "101", "110"],
    "C": ["111", "100", "100", "100", "111"],
    "D": ["110", "101", "101", "101", "110"],
    "E": ["111", "100", "110", "100", "111"],
    "F": ["111", "100", "110", "100", "100"],
    "G": ["111", "100", "101", "101", "111"],
    "H": ["101", "101", "111", "101", "101"],
    "I": ["111", "010", "010", "010", "111"],
    "J": ["001", "001", "001", "101", "111"],
    "K": ["101", "101", "110", "101", "101"],
    "L": ["100", "100", "100", "100", "111"],
    "M": ["101", "111", "111", "101", "101"],
    "N": ["101", "111", "111", "111", "101"],
    "O": ["111", "101", "101", "101", "111"],
    "P": ["111", "101", "111", "100", "100"],
    "Q": ["111", "101", "101", "111", "001"],
    "R": ["111", "101", "111", "110", "101"],
    "S": ["111", "100", "111", "001", "111"],
    "T": ["111", "010", "010", "010", "010"],
    "U": ["101", "101", "101", "101", "111"],
    "V": ["101", "101", "101", "101", "010"],
    "W": ["101", "101", "111", "111", "101"],
    "X": ["101", "101", "010", "101", "101"],
    "Y": ["101", "101", "010", "010", "010"],
    "Z": ["111", "001", "010", "100", "111"],
}.items():
    FONT[ch] = rows


def ensure_parent(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)


def chunk(tag: bytes, data: bytes) -> bytes:
    return (
        struct.pack(">I", len(data))
        + tag
        + data
        + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)
    )


def write_png(path: Path, width: int, height: int, pixels: bytearray) -> None:
    ensure_parent(path)
    raw = bytearray()
    stride = width * 4
    for y in range(height):
        raw.append(0)
        raw.extend(pixels[y * stride : (y + 1) * stride])
    data = b"\x89PNG\r\n\x1a\n"
    data += chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0))
    data += chunk(b"IDAT", zlib.compress(bytes(raw), 9))
    data += chunk(b"IEND", b"")
    path.write_bytes(data)


def put(px: bytearray, width: int, height: int, x: int, y: int, color: tuple[int, int, int, int]) -> None:
    if x < 0 or y < 0 or x >= width or y >= height:
        return
    i = (y * width + x) * 4
    src_a = color[3] / 255.0
    dst_a = px[i + 3] / 255.0
    out_a = src_a + dst_a * (1.0 - src_a)
    if out_a <= 0.0:
        px[i : i + 4] = b"\x00\x00\x00\x00"
        return
    for c in range(3):
        src = color[c] / 255.0
        dst = px[i + c] / 255.0
        px[i + c] = int(((src * src_a + dst * dst_a * (1.0 - src_a)) / out_a) * 255)
    px[i + 3] = int(out_a * 255)


def rect(px: bytearray, width: int, height: int, x: int, y: int, w: int, h: int, color: tuple[int, int, int, int]) -> None:
    x0 = max(0, x)
    y0 = max(0, y)
    x1 = min(width, x + w)
    y1 = min(height, y + h)
    for yy in range(y0, y1):
        for xx in range(x0, x1):
            put(px, width, height, xx, yy, color)


def stroke(px: bytearray, width: int, height: int, x: int, y: int, w: int, h: int, color: tuple[int, int, int, int], t: int = 2) -> None:
    rect(px, width, height, x, y, w, t, color)
    rect(px, width, height, x, y + h - t, w, t, color)
    rect(px, width, height, x, y, t, h, color)
    rect(px, width, height, x + w - t, y, t, h, color)


def line_h(px: bytearray, width: int, height: int, x: int, y: int, w: int, color: tuple[int, int, int, int], t: int = 1) -> None:
    rect(px, width, height, x, y, w, t, color)


def line_v(px: bytearray, width: int, height: int, x: int, y: int, h: int, color: tuple[int, int, int, int], t: int = 1) -> None:
    rect(px, width, height, x, y, t, h, color)


def text(px: bytearray, width: int, height: int, x: int, y: int, msg: str, color: tuple[int, int, int, int], scale: int = 3) -> None:
    cursor = x
    for ch in msg.upper():
        rows = FONT.get(ch, FONT[" "])
        for ry, row in enumerate(rows):
            for rx, bit in enumerate(row):
                if bit == "1":
                    rect(px, width, height, cursor + rx * scale, y + ry * scale, scale, scale, color)
        cursor += 4 * scale


def placeholder(path: str, width: int, height: int, label: str, frame_w: int | None = None, frame_h: int | None = None, tint=(90, 180, 220)) -> None:
    frame_w = frame_w or width
    frame_h = frame_h or height
    frames = max(1, width // frame_w)
    px = bytearray(width * height * 4)
    fill = (tint[0], tint[1], tint[2], 34)
    border = (tint[0], tint[1], tint[2], 210)
    safe = (255, 240, 170, 160)
    anchor = (255, 90, 90, 230)
    guide = (255, 255, 255, 80)

    for f in range(frames):
        ox = f * frame_w
        rect(px, width, height, ox, 0, frame_w, frame_h, fill)
        stroke(px, width, height, ox, 0, frame_w, frame_h, border, max(2, frame_w // 128))
        cx = ox + frame_w // 2
        cy = frame_h // 2
        line_v(px, width, height, cx, 0, frame_h, guide, 1)
        line_h(px, width, height, ox, cy, frame_w, guide, 1)
        safe_w = int(frame_w * 0.68)
        safe_h = int(frame_h * 0.74)
        stroke(px, width, height, cx - safe_w // 2, frame_h - safe_h - 10, safe_w, safe_h, safe, 2)
        line_h(px, width, height, cx - 22, frame_h - 1, 44, anchor, 2)
        line_v(px, width, height, cx, frame_h - 24, 24, anchor, 2)
        rect(px, width, height, cx - 4, frame_h - 8, 8, 8, anchor)
        text(px, width, height, ox + 12, 12, f"F{f + 1:02}", (255, 255, 255, 210), 4)

    text(px, width, height, 16, max(8, height - 34), label, (255, 255, 255, 210), 4)
    write_png(ROOT / path, width, height, px)
    mirror_to_placeholder(path)


def tileset(path: str, label: str, tint=(120, 170, 110)) -> None:
    width, height, tile = 1024, 768, 128
    px = bytearray(width * height * 4)
    row_names = ["SOLID TOP", "SOLID FILL", "ONE WAY", "WALL", "DECOR", "VISUAL"]
    row_colors = [
        (tint[0], tint[1], tint[2], 72),
        (tint[0] - 10, tint[1] - 20, tint[2] - 10, 62),
        (210, 165, 85, 70),
        (150, 140, 130, 58),
        (70, 175, 95, 54),
        (95, 115, 180, 40),
    ]
    for y in range(6):
        for x in range(8):
            ox, oy = x * tile, y * tile
            rect(px, width, height, ox, oy, tile, tile, row_colors[y])
            stroke(px, width, height, ox, oy, tile, tile, (255, 255, 255, 120), 2)
            line_v(px, width, height, ox + tile // 2, oy, tile, (255, 255, 255, 45), 1)
            line_h(px, width, height, ox, oy + tile // 2, tile, (255, 255, 255, 45), 1)
            if y in (0, 1, 3):
                stroke(px, width, height, ox + 18, oy + 18, tile - 36, tile - 36, (255, 90, 90, 160), 3)
            elif y == 2:
                line_h(px, width, height, ox + 18, oy + 28, tile - 36, (255, 90, 90, 190), 4)
                text(px, width, height, ox + 20, oy + 82, "ONE", (255, 230, 170, 210), 3)
            text(px, width, height, ox + 10, oy + 10, f"R{y + 1}C{x + 1}", (255, 255, 255, 200), 3)
            text(px, width, height, ox + 10, oy + 104, row_names[y][:8], (255, 255, 255, 150), 2)
    text(px, width, height, 18, 734, label, (255, 255, 255, 210), 4)
    write_png(ROOT / path, width, height, px)
    mirror_to_placeholder(path)


def background(path: str, width: int, height: int, label: str, tint=(80, 120, 180)) -> None:
    px = bytearray(width * height * 4)
    for y in range(height):
        alpha = int(24 + 40 * (y / max(1, height - 1)))
        rect(px, width, height, 0, y, width, 1, (tint[0], tint[1], tint[2], alpha))
    for x in range(0, width, 320):
        line_v(px, width, height, x, 0, height, (255, 255, 255, 55), 1)
    for y in range(0, height, 180):
        line_h(px, width, height, 0, y, width, (255, 255, 255, 45), 1)
    stroke(px, width, height, 0, 0, width, height, (tint[0], tint[1], tint[2], 180), 3)
    text(px, width, height, 30, 30, label, (255, 255, 255, 210), 5)
    text(px, width, height, 30, height - 50, f"{width}X{height}", (255, 255, 255, 160), 4)
    write_png(ROOT / path, width, height, px)
    mirror_to_placeholder(path)


def mirror_to_placeholder(path: str) -> None:
    src = ROOT / path
    dst = ROOT / "assets/placeholders" / path
    ensure_parent(dst)
    shutil.copyfile(src, dst)


def wav(path: str, seconds: float, sample_rate: int = 44100) -> None:
    out = ROOT / path
    ensure_parent(out)
    frames = int(seconds * sample_rate)
    with wave.open(str(out), "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(sample_rate)
        wf.writeframes(b"\x00\x00" * frames)
    mirror_audio_to_placeholder(path)


def mirror_audio_to_placeholder(path: str) -> None:
    src = ROOT / path
    dst = ROOT / "assets/placeholders" / path
    ensure_parent(dst)
    shutil.copyfile(src, dst)


def tileset_resource(path: str, png_path: str) -> None:
    out = ROOT / path
    ensure_parent(out)
    full = "PackedVector2Array(-64, -64, 64, -64, 64, 64, -64, 64)"
    oneway = "PackedVector2Array(-64, -64, 64, -64, 64, -48, -64, -48)"
    lines = [
        '[gd_resource type="TileSet" format=3]',
        "",
        f'[ext_resource type="Texture2D" path="res://{png_path}" id="1_texture"]',
        "",
        '[sub_resource type="TileSetAtlasSource" id="TileSetAtlasSource_128"]',
        'texture = ExtResource("1_texture")',
        "texture_region_size = Vector2i(128, 128)",
    ]
    for y in range(6):
        for x in range(8):
            lines.append(f"{x}:{y}/0 = 0")
            if y in (0, 1, 3):
                lines.append(f"{x}:{y}/0/physics_layer_0/polygon_0/points = {full}")
            elif y == 2:
                lines.append(f"{x}:{y}/0/physics_layer_0/polygon_0/points = {oneway}")
                lines.append(f"{x}:{y}/0/physics_layer_0/polygon_0/one_way = true")
    lines += [
        "",
        "[resource]",
        "tile_size = Vector2i(128, 128)",
        "physics_layer_0/collision_layer = 4",
        'sources/0 = SubResource("TileSetAtlasSource_128")',
        "",
    ]
    out.write_text("\n".join(lines), encoding="utf-8")


def write_docs() -> None:
    asset_doc = ROOT / "docs/ASSET_SPEC_128.md"
    level_doc = ROOT / "docs/LEVEL_DESIGN_128.md"
    ensure_parent(asset_doc)
    if asset_doc.exists() or level_doc.exists():
        print("Docs already exist; leaving hand-maintained 128 docs untouched.")
        return
    asset_doc.write_text(
        """# Song Hu 128 HD Placeholder Asset Specification

This build intentionally ships placeholders only. Replace files in `assets/` with final art/audio using the same path, pixel size, frame count, and bottom-center anchor.

## Global Scale
- Logical viewport: `1280x720`.
- Tile size: `128x128`.
- Character/object anchor: bottom-center, marked by the red cross at each frame bottom.
- Safe visible boxes are drawn in yellow. Keep final silhouettes inside them unless a deliberate overhang is needed.
- Gameplay collision uses Godot scene shapes, not opaque pixels.

## Sprite Sheets
| Path | Total Size | Frame | Frames | Anchor | Collision/Use |
|---|---:|---:|---:|---|---|
| `assets/sprites/player/miko_idle.png` | `2048x384` | `256x384` | 8 | bottom-center | player body `80x216`, foot at origin |
| `assets/sprites/player/miko_run.png` | `2048x384` | `256x384` | 8 | bottom-center | keep feet stable on baseline |
| `assets/sprites/player/miko_jump.png` | `1024x384` | `256x384` | 4 | bottom-center | use same silhouette height |
| `assets/sprites/player/miko_fall.png` | `768x384` | `256x384` | 3 | bottom-center | no frame crop drift |
| `assets/sprites/player/miko_interact.png` | `1536x384` | `256x384` | 6 | bottom-center | sleeves may exceed safe box by 16px |
| `assets/sprites/player/miko_turn.png` | `1024x384` | `256x384` | 4 | bottom-center | optional transition |
| `assets/sprites/player/miko_pray.png` | `2048x384` | `256x384` | 8 | bottom-center | optional altar animation |
| `assets/sprites/npcs/elder_idle.png` | `1024x352` | `256x352` | 4 | bottom-center | elder body `88x208` |
| `assets/sprites/npcs/fox_idle.png` | `1920x224` | `320x224` | 6 | bottom-center | fox body approx `210x110` |
| `assets/sprites/npcs/fox_walk.png` | `2560x224` | `320x224` | 8 | bottom-center | feet/paws stable |
| `assets/sprites/npcs/fox_look_back.png` | `1600x224` | `320x224` | 5 | bottom-center | final frame readable profile |
| `assets/sprites/npcs/fox_appear.png` | `2560x224` | `320x224` | 8 | bottom-center | optional fade/materialize |
| `assets/sprites/npcs/fox_depart.png` | `2560x224` | `320x224` | 8 | bottom-center | optional dissolve |
| `assets/sprites/npcs/foxfire_unstable.png` | `1024x128` | `128x128` | 8 | center | tail/fire FX layer |

## Objects
| Path | Size | Anchor | Collision Suggestion |
|---|---:|---|---|
| `assets/sprites/objects/item_sugi_wood.png` | `128x128` | bottom-center | Area `96x96` |
| `assets/sprites/objects/item_white_fur.png` | `128x128` | bottom-center | Area `96x96` |
| `assets/sprites/objects/item_mugwort.png` | `128x128` | bottom-center | Area `96x96` |
| `assets/sprites/objects/item_water_grass.png` | `128x128` | bottom-center | Area `96x96` |
| `assets/sprites/objects/item_bell_fiber.png` | `128x128` | bottom-center | top-offering option placeholder |
| `assets/sprites/objects/item_fox_stone.png` | `128x128` | bottom-center | top-offering option placeholder |
| `assets/sprites/objects/item_lamp_oil.png` | `128x128` | bottom-center | top-offering option placeholder |
| `assets/sprites/objects/stone_tablet.png` | `192x256` | bottom-center | Area `160x220` |
| `assets/sprites/objects/altar.png` | `384x288` | bottom-center | Area `320x210` |
| `assets/sprites/objects/stone_lantern.png` | `128x256` | bottom-center | static visual |
| `assets/sprites/objects/bell_rope.png` | `128x448` | top-center for rope, placed from top | Area `140x360` |
| `assets/sprites/objects/torii_small.png` | `384x448` | bottom-center | visual/optional wall only |
| `assets/sprites/objects/torii.png` | `640x576` | bottom-center | visual/optional wall only |

## TileSet Atlas Layout
Each tileset is `1024x768`, `8 columns x 6 rows`, `128x128` per tile:

| Row | Collision | Contents |
|---:|---|---|
| 1 | solid, layer 3/collision bit 4 | ground top, left/right edge, inner/outer corner variants |
| 2 | solid, layer 3/collision bit 4 | fill blocks, cracks, slope placeholders |
| 3 | one-way only | one-way platforms, bridge board, steps |
| 4 | solid, layer 3/collision bit 4 | walls, pillars, door frames |
| 5 | none | grass, stones, paper seals, broken wood |
| 6 | none | visual variants and decals |

Tilesets: `forest_tileset`, `approach_tileset`, `shrine_tileset`. Mechanisms such as bridges and hidden platforms are scene nodes, not terrain atlas collision.

## Backgrounds
Segment backgrounds are transparent-guide placeholders sized `3840x720`, split mentally into three `1280x720` zones:

| Level | Far | Mid | Near |
|---|---|---|---|
| 1 | `level1_far.png` | `level1_mid.png` | `level1_near.png` |
| 2 | `level2_far.png` | `level2_mid.png` | `level2_near.png` |
| 3 | `level3_far.png` | `level3_mid.png` | `level3_near.png` |

Final art may be wider, but keep height `720` and horizon alignment consistent across zone boundaries.

## UI And Audio
- Dialog box: `assets/ui/dialog_box.png`, `960x192`, nine-slice capable placeholder.
- Choice button: `assets/ui/choice_button.png`, `384x96`.
- Offering HUD: `assets/ui/offering_tube.png`, `256x384`.
- Interact hint: `assets/ui/interact_hint.png`, `128x128`.
- Audio files are silent WAV placeholders. BGM targets: 60-90 seconds loopable, `-18 LUFS` integrated. SFX targets: short mono/stereo WAV, peak below `-3 dB`.
""",
        encoding="utf-8",
    )
    level_doc.write_text(
        """# Song Hu 128 HD Level Design

All coordinates are Godot pixels in a `1280x720` viewport. Floor baseline is usually `y=512`; the player origin is the feet.

## Shared Scene Layers
`BackgroundZones`, `Parallax2D_Far`, `Parallax2D_Mid`, `Parallax2D_Near`, `Terrain`, `OneWayPlatforms`, `PropsBack`, `Items`, `Narrative`, `Actors`, `Mechanisms`, `PropsFront`, `Lighting`, `FX`, `HUD`, `Audio`.

## Level 1: Village Gate To Dressing Shrine
- Width: `9600px` (`75` tiles).
- Flow: village gate shrine -> cedar teaching path -> old torii -> low platform pickup -> altar choice.
- Main floor tile row: `4`; lower fill rows: `5-7`.

| Beat | X Range | Key Nodes |
|---|---:|---|
| Village gate | `0-1600` | player `160,512`, elder `420,512`, tablet `760,512`, item `sugi_wood 1180,448` |
| Cedar tutorial | `1600-3600` | one-way platforms, tablet `2480,384`, item `white_fur 3260,320` |
| Old torii | `3600-5600` | large torii, lanterns, item `mugwort 5400,448` |
| Low platform route | `5600-7600` | readable tablet, mild jump checks |
| Altar choice | `7600-9600` | altar `8840,512`, fox marker `8540,420`, transition to Level 2 |

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
- Player speed `240px/s`; jump `-440px/s`; gravity `980px/s^2`; max fall `650px/s`.
- Horizontal travel contains a pickup, readable object, visual landmark, or jump/interaction beat every `800-1400px`.
- No required gameplay object is runtime-drawn. Runtime scripts only toggle visibility/collision or play dialogue/audio.
""",
        encoding="utf-8",
    )


def main() -> None:
    placeholder("assets/sprites/player/miko_idle.png", 2048, 384, "PLAYER IDLE", 256, 384, (105, 180, 230))
    placeholder("assets/sprites/player/miko_run.png", 2048, 384, "PLAYER RUN", 256, 384, (105, 210, 190))
    placeholder("assets/sprites/player/miko_jump.png", 1024, 384, "PLAYER JUMP", 256, 384, (130, 190, 245))
    placeholder("assets/sprites/player/miko_fall.png", 768, 384, "PLAYER FALL", 256, 384, (150, 170, 225))
    placeholder("assets/sprites/player/miko_interact.png", 1536, 384, "PLAYER INTERACT", 256, 384, (220, 170, 120))
    placeholder("assets/sprites/player/miko_turn.png", 1024, 384, "PLAYER TURN", 256, 384, (180, 190, 230))
    placeholder("assets/sprites/player/miko_pray.png", 2048, 384, "PLAYER PRAY", 256, 384, (210, 160, 210))

    placeholder("assets/sprites/npcs/elder_idle.png", 1024, 352, "ELDER IDLE", 256, 352, (185, 160, 110))
    placeholder("assets/sprites/npcs/fox_idle.png", 1920, 224, "FOX IDLE", 320, 224, (230, 230, 245))
    placeholder("assets/sprites/npcs/fox_walk.png", 2560, 224, "FOX WALK", 320, 224, (220, 230, 255))
    placeholder("assets/sprites/npcs/fox_look_back.png", 1600, 224, "FOX LOOK", 320, 224, (245, 220, 230))
    placeholder("assets/sprites/npcs/fox_appear.png", 2560, 224, "FOX APPEAR", 320, 224, (250, 215, 160))
    placeholder("assets/sprites/npcs/fox_depart.png", 2560, 224, "FOX DEPART", 320, 224, (190, 210, 250))
    placeholder("assets/sprites/npcs/foxfire_unstable.png", 1024, 128, "FOXFIRE FX", 128, 128, (255, 150, 80))

    objects = [
        ("item_sugi_wood.png", 128, 128, "ITEM WOOD", (160, 115, 75)),
        ("item_white_fur.png", 128, 128, "ITEM FUR", (230, 230, 250)),
        ("item_mugwort.png", 128, 128, "ITEM MUG", (90, 170, 95)),
        ("item_water_grass.png", 128, 128, "ITEM WATER", (90, 185, 190)),
        ("item_bell_fiber.png", 128, 128, "ITEM BELL", (210, 175, 90)),
        ("item_fox_stone.png", 128, 128, "ITEM FIRE", (245, 120, 70)),
        ("item_lamp_oil.png", 128, 128, "ITEM OIL", (205, 145, 70)),
        ("stone_tablet.png", 192, 256, "STONE TABLET", (150, 150, 150)),
        ("altar.png", 384, 288, "ALTAR", (190, 145, 90)),
        ("stone_lantern.png", 128, 256, "LANTERN", (150, 150, 135)),
        ("bell_rope.png", 128, 448, "BELL ROPE", (210, 175, 85)),
        ("torii_small.png", 384, 448, "TORII SMALL", (190, 80, 70)),
        ("torii.png", 640, 576, "TORII LARGE", (190, 70, 65)),
        ("bridge_plank.png", 1152, 96, "BRIDGE PLANK", (155, 105, 65)),
        ("hidden_platform.png", 1024, 96, "HIDDEN PLATFORM", (95, 160, 180)),
        ("plaque.png", 384, 192, "PLAQUE", (170, 120, 70)),
        ("archive_note.png", 192, 192, "ARCHIVE NOTE", (190, 170, 130)),
    ]
    for name, w, h, label, tint in objects:
        placeholder(f"assets/sprites/objects/{name}", w, h, label, w, h, tint)

    placeholder("assets/sprites/effects/fox_fire.png", 1024, 128, "FOX FIRE", 128, 128, (255, 135, 60))
    placeholder("assets/sprites/effects/lantern_flame.png", 1024, 128, "LANTERN FX", 128, 128, (255, 190, 80))
    placeholder("assets/sprites/effects/blue_flame.png", 1024, 128, "BLUE FLAME", 128, 128, (95, 160, 255))
    placeholder("assets/sprites/effects/warm_light.png", 512, 512, "WARM LIGHT", 512, 512, (255, 180, 90))
    placeholder("assets/sprites/effects/cold_light.png", 512, 512, "COLD LIGHT", 512, 512, (120, 170, 255))
    placeholder("assets/sprites/effects/light_texture.png", 512, 512, "LIGHT TEXTURE", 512, 512, (255, 230, 180))
    placeholder("assets/sprites/effects/particle.png", 64, 64, "FX", 64, 64, (255, 160, 90))

    tileset("assets/tilesets/forest_tileset.png", "FOREST TILESET", (95, 165, 115))
    tileset("assets/tilesets/approach_tileset.png", "APPROACH TILESET", (155, 130, 100))
    tileset("assets/tilesets/shrine_tileset.png", "SHRINE TILESET", (145, 115, 140))
    tileset_resource("assets/tilesets/forest_tileset.tres", "assets/tilesets/forest_tileset.png")
    tileset_resource("assets/tilesets/approach_tileset.tres", "assets/tilesets/approach_tileset.png")
    tileset_resource("assets/tilesets/shrine_tileset.tres", "assets/tilesets/shrine_tileset.png")

    background("assets/backgrounds/level1_far.png", 9600, 720, "LEVEL1 FAR", (70, 100, 155))
    background("assets/backgrounds/level1_mid.png", 9600, 720, "LEVEL1 MID", (65, 130, 120))
    background("assets/backgrounds/level1_near.png", 9600, 720, "LEVEL1 NEAR", (75, 150, 95))
    background("assets/backgrounds/level2_far.png", 12800, 720, "LEVEL2 FAR", (90, 90, 140))
    background("assets/backgrounds/level2_mid.png", 12800, 720, "LEVEL2 MID", (120, 105, 100))
    background("assets/backgrounds/level2_near.png", 12800, 720, "LEVEL2 NEAR", (140, 120, 80))
    background("assets/backgrounds/level3_far.png", 11200, 720, "LEVEL3 FAR", (80, 75, 115))
    background("assets/backgrounds/level3_mid.png", 11200, 720, "LEVEL3 MID", (120, 90, 120))
    background("assets/backgrounds/level3_near.png", 11200, 720, "LEVEL3 NEAR", (135, 105, 135))
    background("assets/backgrounds/sky.png", 1280, 720, "LEGACY SKY", (70, 100, 150))
    background("assets/backgrounds/far_mountains.png", 3840, 720, "LEGACY FAR", (90, 100, 145))
    background("assets/backgrounds/near_trees.png", 3840, 720, "LEGACY NEAR", (70, 130, 90))
    background("assets/backgrounds/fog.png", 1280, 720, "LEGACY FOG", (170, 190, 210))
    background("assets/backgrounds/shrine_interior.png", 1280, 720, "SHRINE INTERIOR", (110, 85, 115))

    placeholder("assets/ui/dialog_box.png", 960, 192, "DIALOG 9SLICE", 960, 192, (120, 90, 145))
    placeholder("assets/ui/choice_button.png", 384, 96, "CHOICE BTN", 384, 96, (150, 110, 80))
    placeholder("assets/ui/interact_hint.png", 128, 128, "E HINT", 128, 128, (230, 200, 120))
    placeholder("assets/ui/offering_tube.png", 256, 384, "OFFER HUD", 256, 384, (95, 120, 150))

    wav("assets/audio/bgm/forest_night.wav", 6.0)
    wav("assets/audio/bgm/approach_theme.wav", 6.0)
    wav("assets/audio/bgm/shrine_theme.wav", 6.0)
    wav("assets/audio/ambience/night_insects.wav", 4.0)
    wav("assets/audio/ambience/broken_approach.wav", 4.0)
    wav("assets/audio/ambience/shrine_roomtone.wav", 4.0)
    for name in ["bell", "collect", "footstep", "interact", "jump", "altar", "foxfire", "paper_door"]:
        wav(f"assets/audio/sfx/{name}.wav", 0.25)

    write_docs()
    print("Generated 128 HD placeholders, silent audio, and TileSet resources. Existing docs are preserved.")


if __name__ == "__main__":
    main()
