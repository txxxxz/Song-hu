#!/usr/bin/env python3
"""Assemble processed transparent sprite frames into Godot atlas strips."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image


def load_frame(path: Path, flip: bool = False) -> Image.Image:
    frame = Image.open(path).convert("RGBA")
    if flip:
        frame = frame.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
    return frame


def despill_magenta(img: Image.Image) -> Image.Image:
    pixels = img.load()
    for y in range(img.height):
        for x in range(img.width):
            r, g, b, a = pixels[x, y]
            if a == 0:
                continue
            magenta_strength = ((r + b) / 2) - g
            if r > 70 and b > 70 and g < 90 and magenta_strength > 70 and abs(r - b) < 110:
                pixels[x, y] = (r, g, b, 0)
    return img


def fit_to_cell(
    frame: Image.Image,
    cell_width: int,
    cell_height: int,
    fit: float,
    align: str,
    despill: bool,
    target_height: int | None,
    x_offset: int,
) -> Image.Image:
    if despill:
        frame = despill_magenta(frame.copy())
    bbox = frame.getbbox()
    if bbox:
        frame = frame.crop(bbox)
    canvas = Image.new("RGBA", (cell_width, cell_height), (0, 0, 0, 0))
    if frame.width == 0 or frame.height == 0:
        return canvas

    if target_height:
        scale = target_height / frame.height
    else:
        scale = min(cell_width / frame.width, cell_height / frame.height) * fit
    out_width = max(1, round(frame.width * scale))
    out_height = max(1, round(frame.height * scale))
    resized = frame.resize((out_width, out_height), Image.Resampling.LANCZOS)

    x = (cell_width - out_width) // 2 + x_offset
    if align == "bottom":
        y = cell_height - out_height
    elif align == "feet":
        y = cell_height - out_height - max(0, round(cell_height * 0.04))
    else:
        y = (cell_height - out_height) // 2
    src_x0 = max(0, -x)
    src_y0 = max(0, -y)
    src_x1 = min(out_width, cell_width - x)
    src_y1 = min(out_height, cell_height - y)
    if src_x1 > src_x0 and src_y1 > src_y0:
        cropped = resized.crop((src_x0, src_y0, src_x1, src_y1))
        canvas.alpha_composite(cropped, (max(0, x), max(0, y)))
    return canvas


def assemble(
    paths: list[Path],
    output: Path,
    cell_width: int,
    cell_height: int,
    fit: float,
    align: str,
    despill: bool,
    target_height: int | None,
    flip_indices: set[int],
    x_offset: int,
) -> None:
    frames = [
        fit_to_cell(
            load_frame(path, index + 1 in flip_indices),
            cell_width,
            cell_height,
            fit,
            align,
            despill,
            target_height,
            x_offset,
        )
        for index, path in enumerate(paths)
    ]
    sheet = Image.new("RGBA", (cell_width * len(frames), cell_height), (0, 0, 0, 0))
    for index, frame in enumerate(frames):
        sheet.alpha_composite(frame, (index * cell_width, 0))
    output.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(output)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--frames", nargs="+", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--cell-width", type=int, required=True)
    parser.add_argument("--cell-height", type=int, required=True)
    parser.add_argument("--fit", type=float, default=0.94)
    parser.add_argument("--align", choices=["center", "bottom", "feet"], default="bottom")
    parser.add_argument("--despill-magenta", action="store_true")
    parser.add_argument("--target-height", type=int)
    parser.add_argument("--flip-indices", nargs="*", type=int, default=[])
    parser.add_argument("--x-offset", type=int, default=0)
    args = parser.parse_args()
    assemble(
        args.frames,
        args.output,
        args.cell_width,
        args.cell_height,
        args.fit,
        args.align,
        args.despill_magenta,
        args.target_height,
        set(args.flip_indices),
        args.x_offset,
    )


if __name__ == "__main__":
    main()
