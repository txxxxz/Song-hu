from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageEnhance, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
BG = ROOT / "assets" / "backgrounds"
SOURCE_BG = ROOT / "assets_1" / "assets" / "backgrounds"
SOURCE_ZONES = ROOT / "assets_1" / "level1_mid_near_alpha_pngs_3200x720"
TILESETS = ROOT / "assets" / "tilesets"
OBJECTS = ROOT / "assets" / "sprites" / "objects"
DOCS = ROOT / "docs"


def open_rgba(path: Path) -> Image.Image:
    return Image.open(path).convert("RGBA")


def save_png(img: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path)


def lerp(a: int, b: int, t: float) -> int:
    return round(a + (b - a) * t)


def vertical_gradient(size: tuple[int, int], top: tuple[int, int, int], bottom: tuple[int, int, int]) -> Image.Image:
    width, height = size
    img = Image.new("RGBA", size)
    px = img.load()
    for y in range(height):
        t = y / max(height - 1, 1)
        col = (
            lerp(top[0], bottom[0], t),
            lerp(top[1], bottom[1], t),
            lerp(top[2], bottom[2], t),
            255,
        )
        for x in range(width):
            px[x, y] = col
    return img


def add_soft_disc(draw: ImageDraw.ImageDraw, center: tuple[int, int], radius: int, color: tuple[int, int, int, int]) -> None:
    x, y = center
    for i in range(radius, 0, -8):
        alpha = round(color[3] * (1.0 - i / radius) ** 1.6)
        draw.ellipse((x - i, y - i, x + i, y + i), fill=(color[0], color[1], color[2], alpha))


def add_mist(width: int, height: int, seed_phase: float, alpha: int = 32) -> Image.Image:
    mist = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(mist)
    for band in range(5):
        y_base = 410 + band * 42
        points: list[tuple[int, int]] = []
        for x in range(0, width + 96, 96):
            wave = math.sin(x * 0.004 + seed_phase + band * 1.3) * 18
            wave += math.sin(x * 0.0017 + seed_phase * 0.7) * 22
            points.append((x, round(y_base + wave)))
        poly = [(0, height)] + points + [(width, height)]
        draw.polygon(poly, fill=(156, 184, 200, max(8, alpha - band * 4)))
    return mist.filter(ImageFilter.GaussianBlur(24))


def add_tree_silhouettes(base: Image.Image, color: tuple[int, int, int, int], y_ground: int, spacing: int, phase: float) -> None:
    draw = ImageDraw.Draw(base)
    width, _height = base.size
    for x in range(-160, width + 160, spacing):
        h = 90 + int(45 * (0.5 + 0.5 * math.sin(x * 0.009 + phase)))
        trunk_w = 8 + int(5 * (0.5 + 0.5 * math.sin(x * 0.013 + phase)))
        draw.rectangle((x - trunk_w // 2, y_ground - h, x + trunk_w // 2, y_ground), fill=color)
        for k in range(5):
            yy = y_ground - h + 18 + k * 20
            half = max(18, 54 - k * 7)
            draw.polygon([(x, yy - 34), (x - half, yy + 22), (x + half, yy + 22)], fill=color)


def polish_level1_backgrounds() -> None:
    width, height = 9600, 720

    far = vertical_gradient((width, height), (8, 13, 30), (24, 31, 43))
    draw = ImageDraw.Draw(far, "RGBA")
    add_mountain_bands(draw, width, height)
    add_blurred_moon(far, (width - 1420, 112), 68)
    for i in range(240):
        x = (i * 619 + 137) % width
        y = 26 + ((i * 173) % 245)
        a = 34 + (i * 19) % 56
        draw.rectangle((x, y, x + 1, y + 1), fill=(222, 232, 218, a))
    add_tree_silhouettes(far, (9, 18, 29, 118), 612, 360, 1.7)
    far = Image.alpha_composite(far, add_mist(width, height, 0.3, 26))
    save_png(far, BG / "level1_far.png")

    mid = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    add_tree_silhouettes(mid, (55, 80, 93, 168), 642, 260, 0.8)
    add_tree_silhouettes(mid, (33, 55, 66, 142), 640, 430, 3.2)
    mid = Image.alpha_composite(mid, add_mist(width, height, 1.1, 42))
    save_png(mid, BG / "level1_mid.png")

    near = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(near, "RGBA")
    for x in range(-120, width + 120, 260):
        sway = int(math.sin(x * 0.006) * 30)
        draw.polygon(
            [
                (x - 160, 0),
                (x + 80 + sway, 0),
                (x + 150 + sway, 86),
                (x + 30, 118),
                (x - 120, 92),
            ],
            fill=(18, 34, 40, 112),
        )
        draw.rectangle((x + 10, 40, x + 22, 196), fill=(15, 27, 32, 74))
    for x in range(0, width, 72):
        h = 20 + int(18 * (0.5 + 0.5 * math.sin(x * 0.025)))
        draw.polygon([(x, 640), (x + 18, 640 - h), (x + 36, 640), (x + 74, 668), (x - 8, 668)], fill=(11, 21, 25, 92))
    near = Image.alpha_composite(near, add_mist(width, height, 2.2, 18))
    save_png(near, BG / "level1_near.png")


def add_blurred_moon(base: Image.Image, center: tuple[int, int], radius: int) -> None:
    glow = Image.new("RGBA", base.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(glow, "RGBA")
    x, y = center
    draw.ellipse((x - radius * 5, y - radius * 5, x + radius * 5, y + radius * 5), fill=(130, 166, 193, 24))
    glow = glow.filter(ImageFilter.GaussianBlur(radius * 2))
    draw = ImageDraw.Draw(glow, "RGBA")
    draw.ellipse((x - radius, y - radius, x + radius, y + radius), fill=(206, 224, 224, 150))
    base.alpha_composite(glow)


def add_mountain_bands(draw: ImageDraw.ImageDraw, width: int, height: int) -> None:
    for band, color in enumerate([(39, 55, 70, 92), (28, 42, 54, 118), (18, 30, 39, 142)]):
        y_base = 300 + band * 78
        points: list[tuple[int, int]] = []
        for x in range(0, width + 240, 240):
            y = y_base
            y += math.sin(x * 0.0017 + band * 0.9) * (38 + band * 10)
            y += math.sin(x * 0.0041 + band * 1.7) * 18
            points.append((x, round(y)))
        draw.polygon([(0, height)] + points + [(width, height)], fill=color)


def load_zone_stack(prefix: str, fallback: Path) -> Image.Image:
    zone_paths = [SOURCE_ZONES / f"{prefix}_zone{i}_3200x720_alpha.png" for i in range(1, 4)]
    if not all(path.exists() for path in zone_paths):
        return open_rgba(fallback)
    width, height = 9600, 720
    out = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    for index, path in enumerate(zone_paths):
        zone = open_rgba(path)
        zone = feather_horizontal_edges(zone, 96)
        out.alpha_composite(zone, (index * 3200, 0))
    soften_stack_seams(out, [3200, 6400], 92)
    return out


def feather_horizontal_edges(img: Image.Image, feather: int) -> Image.Image:
    out = img.copy()
    alpha = out.getchannel("A")
    px = alpha.load()
    width, height = alpha.size
    for x in range(width):
        edge = min(x, width - 1 - x)
        if edge >= feather:
            continue
        factor = max(0.0, min(1.0, edge / feather))
        for y in range(height):
            px[x, y] = round(px[x, y] * factor)
    out.putalpha(alpha)
    return out


def soften_stack_seams(img: Image.Image, seams: list[int], radius: int) -> None:
    alpha = img.getchannel("A")
    px = alpha.load()
    width, height = alpha.size
    for seam in seams:
        left = max(0, seam - radius)
        right = min(width, seam + radius)
        for x in range(left, right):
            distance = abs(x - seam)
            factor = min(1.0, distance / radius)
            factor = factor * factor
            for y in range(height):
                px[x, y] = round(px[x, y] * factor)
    img.putalpha(alpha)


def clear_vertical_alpha(img: Image.Image, seams: list[int], radius: int) -> None:
    alpha = img.getchannel("A")
    px = alpha.load()
    width, height = alpha.size
    for seam in seams:
        left = max(0, seam - radius)
        right = min(width, seam + radius)
        for x in range(left, right):
            distance = abs(x - seam)
            factor = min(1.0, max(0.0, (distance - radius * 0.35) / (radius * 0.65)))
            factor = factor * factor
            for y in range(height):
                px[x, y] = round(px[x, y] * factor)
    img.putalpha(alpha)


def tint_layer(src: Image.Image, tint: tuple[int, int, int], amount: float, contrast: float) -> Image.Image:
    rgb = src.convert("RGB")
    rgb = ImageEnhance.Contrast(rgb).enhance(contrast)
    overlay = Image.new("RGB", src.size, tint)
    rgb = Image.blend(rgb, overlay, amount)
    out = rgb.convert("RGBA")
    out.putalpha(src.getchannel("A"))
    return out


def alpha_shadow_no_wrap(src: Image.Image, radius: int, offset: tuple[int, int], color: tuple[int, int, int, int]) -> Image.Image:
    alpha = src.getchannel("A").filter(ImageFilter.GaussianBlur(radius))
    shifted = Image.new("L", src.size, 0)
    shifted.paste(alpha, offset)
    shadow = Image.new("RGBA", src.size, color)
    shadow.putalpha(shifted.point(lambda p: min(p, color[3])))
    return shadow


def add_ground_mist(img: Image.Image, seams: list[int], color: tuple[int, int, int, int], radius: int) -> None:
    width, height = img.size
    overlay = Image.new("RGBA", img.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay, "RGBA")
    for seam in seams:
        for i in range(radius, 0, -6):
            a = round(color[3] * (1.0 - i / radius) ** 1.25)
            draw.ellipse((seam - i, 430 - i // 5, seam + i, 700 + i // 5), fill=(color[0], color[1], color[2], a))
    img.alpha_composite(overlay.filter(ImageFilter.GaussianBlur(18)))


def polish_platform_art(path: Path, contrast: float = 0.95, saturation: float = 0.86, brightness: float = 0.88) -> None:
    src = open_rgba(resolve_platform_source(path))
    alpha = src.getchannel("A")
    rgb = src.convert("RGB")
    rgb = ImageEnhance.Contrast(rgb).enhance(contrast)
    rgb = ImageEnhance.Color(rgb).enhance(saturation)
    rgb = ImageEnhance.Brightness(rgb).enhance(brightness)
    cool = Image.new("RGB", src.size, (34, 44, 48))
    rgb = Image.blend(rgb, cool, 0.13)
    polished = rgb.convert("RGBA")
    polished.putalpha(alpha)

    outline = alpha.filter(ImageFilter.MaxFilter(5)).filter(ImageFilter.GaussianBlur(1.0))
    outline_img = Image.new("RGBA", src.size, (3, 6, 8, 110))
    outline_img.putalpha(outline.point(lambda p: min(p, 120)))
    out = Image.alpha_composite(outline_img, polished)

    if path.name.endswith("_tileset.png"):
        out = add_tileset_edge_bleed(out)
    save_png(out, path)


def add_tileset_edge_bleed(img: Image.Image, tile_size: int = 128, bleed: int = 3) -> Image.Image:
    out = img.copy()
    cols = out.width // tile_size
    rows = out.height // tile_size
    solid_rows = {0, 1, 3}
    platform_rows = {2}
    for row in range(rows):
        for col in range(cols):
            box = (col * tile_size, row * tile_size, (col + 1) * tile_size, (row + 1) * tile_size)
            tile = out.crop(box)
            if row == 0:
                tile = fill_border_transparency(tile, border=18, left=True, right=True, top=True, bottom=True)
                tile = bleed_cell_edges(tile, bleed, left=True, right=True, top=True, bottom=True)
            elif row in {1, 3}:
                tile = fill_border_transparency(tile, border=18, left=True, right=True, top=True, bottom=True)
                tile = bleed_cell_edges(tile, bleed, left=True, right=True, top=True, bottom=True)
            elif row in platform_rows:
                tile = fill_border_transparency(tile, border=18, left=True, right=True, top=True, bottom=False)
                tile = bleed_cell_edges(tile, bleed, left=True, right=True, top=True, bottom=False)
            out.paste(tile, box)
    out = polish_repeatable_core_tiles(out, tile_size)
    return out


def fill_border_transparency(
    tile: Image.Image,
    border: int,
    left: bool,
    right: bool,
    top: bool,
    bottom: bool,
    alpha_threshold: int = 12,
) -> Image.Image:
    tile = tile.copy()
    px = tile.load()
    width, height = tile.size

    def in_border(x: int, y: int) -> bool:
        return (
            (left and x < border)
            or (right and x >= width - border)
            or (top and y < border)
            or (bottom and y >= height - border)
        )

    for _ in range(border + 4):
        updates: list[tuple[int, int, tuple[int, int, int, int]]] = []
        for y in range(height):
            for x in range(width):
                if not in_border(x, y):
                    continue
                if px[x, y][3] >= alpha_threshold:
                    continue
                neighbors: list[tuple[int, int, int, int]] = []
                for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
                    if 0 <= nx < width and 0 <= ny < height and px[nx, ny][3] >= alpha_threshold:
                        neighbors.append(px[nx, ny])
                if neighbors:
                    count = len(neighbors)
                    updates.append(
                        (
                            x,
                            y,
                            (
                                sum(p[0] for p in neighbors) // count,
                                sum(p[1] for p in neighbors) // count,
                                sum(p[2] for p in neighbors) // count,
                                max(180, sum(p[3] for p in neighbors) // count),
                            ),
                        )
                    )
        if not updates:
            break
        for x, y, color in updates:
            px[x, y] = color
    return tile


def bleed_cell_edges(tile: Image.Image, bleed: int, left: bool, right: bool, top: bool, bottom: bool) -> Image.Image:
    tile = tile.copy()
    width, height = tile.size
    if left:
        src = tile.crop((bleed, 0, bleed + 1, height))
        for x in range(bleed):
            tile.paste(src, (x, 0))
    if right:
        src = tile.crop((width - bleed - 1, 0, width - bleed, height))
        for x in range(width - bleed, width):
            tile.paste(src, (x, 0))
    if top:
        src = tile.crop((0, bleed, width, bleed + 1))
        for y in range(bleed):
            tile.paste(src, (0, y))
    if bottom:
        src = tile.crop((0, height - bleed - 1, width, height - bleed))
        for y in range(height - bleed, height):
            tile.paste(src, (0, y))
    return tile


def polish_repeatable_core_tiles(atlas: Image.Image, tile_size: int) -> Image.Image:
    out = atlas.copy()
    replacements = {
        (0, 0): ("horizontal", 20),
        (1, 0): ("both", 22),
        (2, 0): ("horizontal", 16),
    }
    for (row, col), (mode, blend) in replacements.items():
        box = (col * tile_size, row * tile_size, (col + 1) * tile_size, (row + 1) * tile_size)
        tile = out.crop(box)
        if row == 0:
            tile = crop_repeated_outline(tile, crop_x=14, crop_y=0)
        elif row == 1:
            tile = crop_repeated_outline(tile, crop_x=14, crop_y=12)
        elif row == 2:
            tile = crop_repeated_outline(tile, crop_x=14, crop_y=0)
        if mode == "horizontal":
            tile = make_horizontal_tileable(tile, blend)
        else:
            tile = make_horizontal_tileable(tile, blend)
            tile = make_vertical_tileable(tile, blend)
        out.paste(tile, box)
    return out


def crop_repeated_outline(tile: Image.Image, crop_x: int, crop_y: int) -> Image.Image:
    width, height = tile.size
    cropped = tile.crop((crop_x, crop_y, width - crop_x, height - crop_y))
    return cropped.resize((width, height), Image.Resampling.LANCZOS)


def make_horizontal_tileable(tile: Image.Image, blend: int) -> Image.Image:
    tile = tile.copy()
    px = tile.load()
    width, height = tile.size
    for i in range(blend):
        t = (i + 1) / (blend + 1)
        left_x = i
        right_x = width - blend + i
        for y in range(height):
            left = px[left_x, y]
            right = px[right_x, y]
            mixed = mix_rgba(left, right, 0.5)
            px[left_x, y] = mix_rgba(left, mixed, 1.0 - t)
            px[right_x, y] = mix_rgba(right, mixed, t)
    return tile


def make_vertical_tileable(tile: Image.Image, blend: int) -> Image.Image:
    tile = tile.copy()
    px = tile.load()
    width, height = tile.size
    for i in range(blend):
        t = (i + 1) / (blend + 1)
        top_y = i
        bottom_y = height - blend + i
        for x in range(width):
            top = px[x, top_y]
            bottom = px[x, bottom_y]
            mixed = mix_rgba(top, bottom, 0.5)
            px[x, top_y] = mix_rgba(top, mixed, 1.0 - t)
            px[x, bottom_y] = mix_rgba(bottom, mixed, t)
    return tile


def mix_rgba(a: tuple[int, int, int, int], b: tuple[int, int, int, int], t: float) -> tuple[int, int, int, int]:
    return (
        lerp(a[0], b[0], t),
        lerp(a[1], b[1], t),
        lerp(a[2], b[2], t),
        lerp(a[3], b[3], t),
    )


def polish_platforms() -> None:
    polish_platform_art(TILESETS / "forest_tileset.png", 0.98, 0.84, 0.86)
    polish_platform_art(TILESETS / "approach_tileset.png", 0.95, 0.78, 0.84)
    polish_platform_art(TILESETS / "shrine_tileset.png", 0.92, 0.82, 0.88)
    polish_platform_art(OBJECTS / "bridge_plank.png", 0.95, 0.82, 0.86)
    polish_platform_art(OBJECTS / "hidden_platform.png", 1.0, 0.9, 0.92)


def resolve_platform_source(path: Path) -> Path:
    rel = path.relative_to(ROOT)
    candidates = [
        ROOT / "assets_1" / rel,
        ROOT / "assets_1" / "assets" / rel.relative_to("assets") if rel.parts[0] == "assets" else path,
        ROOT / "assets_1" / "objects" / path.name if "objects" in rel.parts else path,
    ]
    for candidate in candidates:
        if candidate.exists():
            return candidate
    return path


def write_manifest() -> None:
    manifest = """# L1 Art Polish Pass

This pass improves the first level's perceived production quality without changing gameplay nodes.

- `level1_far.png`: rebuilt as an opaque night sky layer with moon glow, stars, distant silhouettes, and low mist.
- `level1_mid.png`: retinted forest silhouettes, added depth shadow and mist bands over zone joins.
- `level1_near.png`: retinted foreground vegetation, added darker ground foliage and seam mist.
- `forest_tileset.png`, `approach_tileset.png`, `shrine_tileset.png`: unified colder night palette, reduced saturation/brightness, added subtle alpha-backed dark edge support.
- `bridge_plank.png`, `hidden_platform.png`: matched platform objects to the same night palette.

This is an integration polish pass over existing generated/source art, not a final bespoke redraw.
"""
    (DOCS / "ART_POLISH_L1.md").write_text(manifest, encoding="utf-8")


def main() -> None:
    polish_level1_backgrounds()
    polish_platforms()
    write_manifest()
    print("Polished Level 1 backgrounds and platform art.")


if __name__ == "__main__":
    main()
