#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
TILE_SIZE = 128
COLS = 8
ROWS = 6
MARGIN = 4
SEPARATION = 8

TILESET_DIRS = (
    ROOT / "assets" / "tilesets",
    ROOT / "assets_1" / "assets" / "tilesets",
)

JOBS = (
    ("forest_tileset.png", "forest_tileset_tilemap.png"),
    ("approach_tileset.png", "approach_tileset_tilemap.png"),
    ("shrine_tileset.png", "shrine_tileset_tilemap.png"),
)


def cell_box(col: int, row: int) -> tuple[int, int, int, int]:
    x = col * TILE_SIZE
    y = row * TILE_SIZE
    return x, y, x + TILE_SIZE, y + TILE_SIZE


def paste_edge_bleed(
    atlas: Image.Image,
    tile: Image.Image,
    dest_x: int,
    dest_y: int,
    margin: int,
    separation: int,
) -> None:
    atlas.paste(tile, (dest_x, dest_y))

    left = tile.crop((0, 0, 1, TILE_SIZE))
    right = tile.crop((TILE_SIZE - 1, 0, TILE_SIZE, TILE_SIZE))
    top = tile.crop((0, 0, TILE_SIZE, 1))
    bottom = tile.crop((0, TILE_SIZE - 1, TILE_SIZE, TILE_SIZE))

    for i in range(margin + separation // 2):
        atlas.paste(left, (dest_x - i - 1, dest_y))
        atlas.paste(right, (dest_x + TILE_SIZE + i, dest_y))
        atlas.paste(top, (dest_x, dest_y - i - 1))
        atlas.paste(bottom, (dest_x, dest_y + TILE_SIZE + i))

    corners = {
        (dest_x - margin - separation // 2, dest_y - margin - separation // 2): tile.crop((0, 0, 1, 1)),
        (dest_x + TILE_SIZE, dest_y - margin - separation // 2): tile.crop((TILE_SIZE - 1, 0, TILE_SIZE, 1)),
        (dest_x - margin - separation // 2, dest_y + TILE_SIZE): tile.crop((0, TILE_SIZE - 1, 1, TILE_SIZE)),
        (dest_x + TILE_SIZE, dest_y + TILE_SIZE): tile.crop((TILE_SIZE - 1, TILE_SIZE - 1, TILE_SIZE, TILE_SIZE)),
    }
    corner_size = margin + separation // 2
    for (x, y), corner in corners.items():
        atlas.paste(corner.resize((corner_size, corner_size), Image.Resampling.NEAREST), (x, y))


def make_padded_atlas(src_path: Path, out_path: Path) -> None:
    src = Image.open(src_path).convert("RGBA")
    expected_size = (COLS * TILE_SIZE, ROWS * TILE_SIZE)
    if src.size != expected_size:
        raise ValueError(f"{src_path} must be {expected_size}, got {src.size}")

    width = MARGIN * 2 + COLS * TILE_SIZE + (COLS - 1) * SEPARATION
    height = MARGIN * 2 + ROWS * TILE_SIZE + (ROWS - 1) * SEPARATION
    out = Image.new("RGBA", (width, height), (0, 0, 0, 0))

    for row in range(ROWS):
        for col in range(COLS):
            tile = src.crop(cell_box(col, row))
            dest_x = MARGIN + col * (TILE_SIZE + SEPARATION)
            dest_y = MARGIN + row * (TILE_SIZE + SEPARATION)
            paste_edge_bleed(out, tile, dest_x, dest_y, MARGIN, SEPARATION)

    out.save(out_path)
    print(f"wrote {out_path.relative_to(ROOT)} {out.size[0]}x{out.size[1]}")


def main() -> None:
    for tilesets in TILESET_DIRS:
        for source_name, output_name in JOBS:
            make_padded_atlas(tilesets / source_name, tilesets / output_name)


if __name__ == "__main__":
    main()
