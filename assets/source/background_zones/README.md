# Background Zone Source Files

This folder is for production source images only. Godot does not load these files directly.

Generate each background layer as three zone images, then stitch them into the final runtime PNG under `assets/backgrounds/`.

| Level | Layer Source Zones | Core Widths | Final Runtime File Size |
|---|---|---:|---:|
| Level 1 | `level1_*_z01.png`, `level1_*_z02.png`, `level1_*_z03.png` | `3200`, `3200`, `3200` | `9600x720` |
| Level 2 | `level2_*_z01.png`, `level2_*_z02.png`, `level2_*_z03.png` | `4267`, `4266`, `4267` | `12800x720` |
| Level 3 | `level3_*_z01.png`, `level3_*_z02.png`, `level3_*_z03.png` | `3733`, `3734`, `3733` | `11200x720` |

Use `far`, `mid`, or `near` in place of `*`. For example, Level 2 mid-layer source files are:

- `level2_mid_z01.png`
- `level2_mid_z02.png`
- `level2_mid_z03.png`

Recommended overlap workflow:

1. Generate each source zone with a `128px` overlap on shared edges.
2. Blend overlaps manually.
3. Crop to the core widths above.
4. Stitch the three cropped zones into the final runtime file.

Full prompts and visual rules are in `docs/ASSET_SPEC_128.md`, section 6.
