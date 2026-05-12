"""
《送狐》(OKURI KITSUNE) — 高精细像素美术 & 程序化音乐 生成器 v2
=================================================================
2× 分辨率角色/物件 + 精细像素手法 (抖动、色相偏移阴影、亚像素细节)
+ 程序化日本五声音阶环境音乐 (wave PCM)
"""
from PIL import Image, ImageDraw, ImageFilter
import os, math, random, struct, wave, array

ROOT = os.path.dirname(os.path.abspath(__file__))
ASSETS = os.path.join(ROOT, "assets")

def ensure_dir(p):
    os.makedirs(p, exist_ok=True)

def px(img, x, y, c):
    if 0 <= int(x) < img.width and 0 <= int(y) < img.height:
        img.putpixel((int(x), int(y)), c)

def gpx(img, x, y):
    if 0 <= int(x) < img.width and 0 <= int(y) < img.height:
        return img.getpixel((int(x), int(y)))
    return (0,0,0,0)

def fill_rect(img, x, y, w, h, c):
    d = ImageDraw.Draw(img)
    d.rectangle([x, y, x+w-1, y+h-1], fill=c)

def fill_ellipse(img, x, y, w, h, c):
    d = ImageDraw.Draw(img)
    d.ellipse([x, y, x+w-1, y+h-1], fill=c)

def blend(c1, c2, t):
    """线性插值两个 RGBA 颜色"""
    return tuple(int(a + (b - a) * t) for a, b in zip(c1, c2))

def hue_shift_shadow(c, amount=20):
    """阴影色相偏移 - 暖色偏紫，冷色偏蓝"""
    r, g, b = c[0], c[1], c[2]
    a = c[3] if len(c) > 3 else 255
    r2 = max(0, int(r * 0.65) - amount)
    g2 = max(0, int(g * 0.55))
    b2 = min(255, int(b * 0.7) + amount)
    return (r2, g2, b2, a)

def dither_fill(img, x, y, w, h, c1, c2, pattern="checker"):
    """有序抖动填充"""
    for dy in range(h):
        for dx in range(w):
            if pattern == "checker":
                use_c1 = (dx + dy) % 2 == 0
            elif pattern == "horizontal":
                use_c1 = dy % 2 == 0
            else:
                use_c1 = dx % 2 == 0
            px(img, x+dx, y+dy, c1 if use_c1 else c2)

def draw_circle(img, cx, cy, r, c):
    """Bresenham 圆"""
    for angle_i in range(360):
        a = math.radians(angle_i)
        px(img, int(cx + r * math.cos(a)), int(cy + r * math.sin(a)), c)

def fill_circle(img, cx, cy, r, c):
    for dy in range(-int(r)-1, int(r)+2):
        for dx in range(-int(r)-1, int(r)+2):
            if dx*dx + dy*dy <= r*r:
                px(img, int(cx+dx), int(cy+dy), c)

# ═══════════════════════════════════════════════════════
# 色板定义 (扩展版，含更多渐变阶)
# ═══════════════════════════════════════════════════════
class P:
    # 巫女
    HAIR_DARK = (26, 15, 41, 255)
    HAIR_MID = (48, 30, 68, 255)
    HAIR_LIGHT = (62, 42, 82, 255)
    HAIR_SHINE = (90, 62, 110, 255)
    SKIN = (245, 222, 204, 255)
    SKIN_SHADOW = (225, 190, 170, 255)
    SKIN_DEEP = (200, 160, 145, 255)
    SKIN_BLUSH = (250, 195, 185, 255)
    WHITE_TOP = (245, 240, 248, 255)
    WHITE_MID = (225, 220, 232, 255)
    WHITE_SHADOW = (195, 190, 210, 255)
    WHITE_DEEP = (165, 160, 185, 255)
    RED_HAKAMA = (186, 31, 31, 255)
    RED_MID = (160, 25, 28, 255)
    RED_DARK = (120, 18, 20, 255)
    RED_DEEP = (85, 12, 18, 255)
    OBI_GOLD = (210, 175, 90, 255)
    OBI_DARK = (170, 130, 55, 255)
    TABI_WHITE = (240, 235, 230, 255)
    GETA_WOOD = (130, 85, 45, 255)
    RIBBON_RED = (220, 50, 50, 255)
    # 白狐
    FOX_WHITE = (248, 245, 252, 255)
    FOX_LIGHT = (235, 230, 242, 255)
    FOX_SHADOW = (205, 198, 218, 255)
    FOX_DEEP = (175, 168, 195, 255)
    FOX_EAR = (255, 200, 180, 255)
    FOX_EAR_DARK = (230, 170, 150, 255)
    FOX_EYE = (180, 50, 35, 255)
    FOX_EYE_BRIGHT = (220, 80, 50, 255)
    FOX_NOSE = (35, 25, 25, 255)
    FOX_TAIL_TIP = (255, 200, 100, 128)
    # 环境
    GROUND_DARK = (42, 31, 26, 255)
    GROUND_MID = (74, 55, 40, 255)
    GROUND_LIGHT = (95, 72, 52, 255)
    GROUND_HIGHLIGHT = (115, 90, 65, 255)
    GRASS_DARK = (25, 50, 28, 255)
    GRASS_MID = (40, 75, 38, 255)
    GRASS_LIGHT = (58, 100, 48, 255)
    GRASS_TIP = (75, 120, 60, 255)
    STONE_DARK = (40, 40, 56, 255)
    STONE_MID = (68, 68, 88, 255)
    STONE_LIGHT = (92, 92, 112, 255)
    STONE_HIGHLIGHT = (115, 115, 132, 255)
    MOSS = (55, 85, 45, 255)
    MOSS_DARK = (38, 62, 32, 255)
    # 神社
    TORII_RED = (204, 51, 51, 255)
    TORII_LIGHT = (225, 75, 65, 255)
    TORII_DARK = (150, 32, 32, 255)
    TORII_DEEP = (105, 20, 22, 255)
    WOOD_DARK = (58, 38, 20, 255)
    WOOD_MID = (100, 64, 36, 255)
    WOOD_LIGHT = (138, 96, 55, 255)
    WOOD_HIGHLIGHT = (165, 120, 72, 255)
    PAPER_WHITE = (245, 238, 225, 255)
    PAPER_SHADOW = (220, 210, 195, 255)
    ROPE_STRAW = (195, 175, 120, 255)
    ROPE_DARK = (155, 135, 85, 255)
    # 天空
    SKY_TOP = (9, 8, 32, 255)
    SKY_HIGH = (14, 12, 48, 255)
    SKY_MID = (20, 14, 56, 255)
    SKY_LOW = (28, 18, 68, 255)
    STAR_BRIGHT = (255, 252, 240, 255)
    STAR_DIM = (180, 175, 200, 255)
    STAR_WARM = (255, 230, 180, 255)
    MOON_BRIGHT = (255, 250, 225, 255)
    MOON_MID = (230, 220, 200, 255)
    MOON_DARK = (190, 180, 170, 255)
    MOUNTAIN_FAR = (12, 22, 38, 255)
    MOUNTAIN_MID = (18, 32, 50, 255)
    MOUNTAIN_NEAR = (24, 42, 62, 255)
    TREE_DARK = (12, 38, 22, 255)
    TREE_MID = (22, 52, 30, 255)
    TREE_LIGHT = (34, 68, 40, 255)
    FOG = (140, 145, 170, 40)
    FOG_THICK = (120, 125, 155, 70)
    # 狐火
    FOXFIRE_CORE = (255, 250, 220, 255)
    FOXFIRE_BRIGHT = (255, 225, 120, 255)
    FOXFIRE_MID = (255, 160, 68, 255)
    FOXFIRE_OUTER = (200, 80, 30, 128)
    FOXFIRE_FAINT = (160, 50, 15, 60)
    # UI
    UI_BG = (15, 10, 25, 220)
    UI_BORDER = (120, 100, 80, 255)
    UI_BORDER_LIGHT = (160, 140, 110, 255)
    UI_TEXT = (220, 200, 160, 255)
    UI_HIGHLIGHT = (255, 230, 170, 255)
    # 供物 (更丰富的色阶)
    ITEM_SUGI = (140, 89, 51, 255)
    ITEM_SUGI_LIGHT = (175, 118, 70, 255)
    ITEM_SUGI_DARK = (100, 62, 35, 255)
    ITEM_FUR = (248, 243, 252, 255)
    ITEM_FUR_SHADOW = (220, 215, 232, 255)
    ITEM_MUGWORT = (77, 140, 64, 255)
    ITEM_MUGWORT_LIGHT = (100, 165, 82, 255)
    ITEM_MUGWORT_DARK = (52, 105, 44, 255)
    ITEM_BELL = (217, 191, 140, 255)
    ITEM_BELL_LIGHT = (240, 215, 165, 255)
    ITEM_BELL_DARK = (180, 155, 105, 255)
    ITEM_FOXSTONE = (255, 153, 38, 255)
    ITEM_FOXSTONE_BRIGHT = (255, 200, 100, 255)
    ITEM_FOXSTONE_DARK = (200, 110, 20, 255)
    ITEM_WATER = (102, 179, 191, 255)
    ITEM_WATER_LIGHT = (135, 205, 215, 255)
    ITEM_WATER_DARK = (70, 140, 155, 255)
    ITEM_OIL = (191, 115, 26, 255)
    ITEM_OIL_LIGHT = (220, 145, 50, 255)
    ITEM_OIL_DARK = (145, 82, 15, 255)
    T = (0, 0, 0, 0)


# ═══════════════════════════════════════════════════════
# 1. 巫女精灵表 (64×96 per frame)
# ═══════════════════════════════════════════════════════
def gen_miko():
    out = os.path.join(ASSETS, "sprites", "player"); ensure_dir(out)
    FW, FH = 64, 96

    def _base(img, fx, fy, arm_dy=0, leg_mode=0, head_tilt=0, squat=0):
        cx = fx + 32
        base_y = fy + 12  # head top

        # ── 头发 (长发垂到腰) ──
        for dy in range(-2, 8):
            w = 9 - abs(dy - 3) if dy < 6 else 8
            for dx in range(-w, w+1):
                c = P.HAIR_DARK if abs(dx) > w-2 else P.HAIR_MID
                px(img, cx+dx+head_tilt, base_y+dy, c)
        # 发丝光泽
        for dy in range(0, 5):
            px(img, cx-3+head_tilt, base_y+dy, P.HAIR_SHINE)
            px(img, cx+4+head_tilt, base_y+dy, P.HAIR_LIGHT)
        # 垂发 (左右两侧长发)
        for dy in range(8, 40):
            w = max(1, 3 - dy // 14)
            for dx in range(w):
                px(img, cx-9-dx+head_tilt, base_y+dy, P.HAIR_DARK if dx > 0 else P.HAIR_MID)
                px(img, cx+9+dx+head_tilt, base_y+dy, P.HAIR_DARK if dx > 0 else P.HAIR_MID)
        # 发饰 (红色蝴蝶结)
        for dx in range(-2, 3):
            for dy in range(-1, 2):
                if abs(dx) + abs(dy) <= 2:
                    px(img, cx+7+dx+head_tilt, base_y+3+dy, P.RIBBON_RED)

        # ── 脸 ──
        face_y = base_y + 5
        for dy in range(0, 8):
            w = 7 - max(0, dy - 5)
            for dx in range(-w, w+1):
                c = P.SKIN
                if dx < -w+1 or dx > w-1:
                    c = P.SKIN_SHADOW
                px(img, cx+dx+head_tilt, face_y+dy, c)
        # 眼睛 (大且有神)
        for ey in range(2):
            px(img, cx-4+head_tilt, face_y+3+ey, P.HAIR_DARK)
            px(img, cx-3+head_tilt, face_y+3+ey, P.HAIR_DARK)
            px(img, cx+3+head_tilt, face_y+3+ey, P.HAIR_DARK)
            px(img, cx+4+head_tilt, face_y+3+ey, P.HAIR_DARK)
        # 高光
        px(img, cx-4+head_tilt, face_y+3, P.STAR_BRIGHT)
        px(img, cx+3+head_tilt, face_y+3, P.STAR_BRIGHT)
        # 腮红
        px(img, cx-5+head_tilt, face_y+5, P.SKIN_BLUSH)
        px(img, cx+5+head_tilt, face_y+5, P.SKIN_BLUSH)
        # 嘴
        px(img, cx+head_tilt, face_y+6, P.SKIN_DEEP)

        # ── 衣领 ──
        neck_y = face_y + 8
        for dy in range(3):
            for dx in range(-3-dy, 4+dy):
                c = P.WHITE_TOP if abs(dx) > 1 else P.WHITE_MID
                px(img, cx+dx, neck_y+dy, c)

        # ── 白衣上身 ──
        body_y = neck_y + 3
        for dy in range(0, 18 - squat):
            w = 8 + dy // 3
            for dx in range(-w, w+1):
                if abs(dx) >= w-1:
                    c = P.WHITE_DEEP
                elif abs(dx) >= w-3:
                    c = P.WHITE_SHADOW
                elif dx < 0:
                    c = P.WHITE_MID
                else:
                    c = P.WHITE_TOP
                px(img, cx+dx, body_y+dy, c)
        # 衣纹线
        for dy in range(3, 16 - squat, 4):
            for dx in range(-1, 2):
                px(img, cx+dx-2, body_y+dy, P.WHITE_SHADOW)

        # ── 袖子 (宽大的巫女袖) ──
        sleeve_y = body_y + 2 + arm_dy
        for dy in range(0, 14):
            sw = 6 + dy // 2
            # 左袖
            for dx in range(sw):
                c = P.WHITE_TOP if dx < sw//2 else P.WHITE_SHADOW
                if dy >= 12:
                    c = blend(c, P.WHITE_DEEP, (dy-12)/3)
                px(img, cx-9-dx, sleeve_y+dy, c)
            # 右袖
            for dx in range(sw):
                c = P.WHITE_TOP if dx > sw//2 else P.WHITE_SHADOW
                px(img, cx+9+dx, sleeve_y+dy, c)
        # 袖口红边
        for dx in range(5):
            px(img, cx-9-dx, sleeve_y+13, P.RED_HAKAMA)
            px(img, cx+9+dx, sleeve_y+13, P.RED_HAKAMA)

        # ── 腰带 (obi) ──
        obi_y = body_y + 16 - squat
        for dy in range(4):
            for dx in range(-9, 10):
                c = P.OBI_GOLD if dy < 3 else P.OBI_DARK
                if abs(dx) >= 7:
                    c = P.OBI_DARK
                px(img, cx+dx, obi_y+dy, c)
        # 腰带结 (中央小装饰)
        for dx in range(-1, 2):
            for dy in range(-1, 2):
                px(img, cx+dx, obi_y+1+dy, P.OBI_DARK if abs(dx)+abs(dy)>1 else P.OBI_GOLD)

        # ── 红袴 (下裙) ──
        hakama_y = obi_y + 4
        hakama_h = 30 + squat
        for dy in range(0, hakama_h):
            w = 10 + dy // 4
            for dx in range(-w, w+1):
                if abs(dx) >= w-1:
                    c = P.RED_DEEP
                elif abs(dx) >= w-3:
                    c = P.RED_DARK
                elif dx < -1:
                    c = P.RED_MID
                else:
                    c = P.RED_HAKAMA
                px(img, cx+dx, hakama_y+dy, c)
            # 袴褶线 
            if dy > 2:
                px(img, cx-3, hakama_y+dy, P.RED_DARK)
                px(img, cx+3, hakama_y+dy, P.RED_DARK)
                px(img, cx, hakama_y+dy, P.RED_DARK)
        # 袴裾 (下摆)
        for dx in range(-w, w+1):
            px(img, cx+dx, hakama_y+hakama_h-1, P.RED_DEEP)

        # ── 足 (白足袋+木屐) ──
        foot_y = hakama_y + hakama_h
        leg_spread = leg_mode * 2
        for side in [-1, 1]:
            fx_ = cx + side * (3 + leg_spread)
            # 足袋
            for dy in range(3):
                for dx in range(-2, 3):
                    px(img, fx_+dx, foot_y+dy, P.TABI_WHITE)
            # 木屐
            for dx in range(-3, 4):
                px(img, fx_+dx, foot_y+3, P.GETA_WOOD)
                px(img, fx_+dx, foot_y+4, P.WOOD_DARK)

    # idle (6帧, 微妙的呼吸动作)
    idle_frames = 6
    img = Image.new("RGBA", (FW * idle_frames, FH), P.T)
    for i in range(idle_frames):
        breath = [0, -1, -1, 0, 1, 0][i]
        _base(img, i * FW, 0, arm_dy=breath, leg_mode=0, squat=0)
    img.save(os.path.join(out, "miko_idle.png"))
    print(f"  miko_idle.png ({FW*idle_frames}x{FH}, {idle_frames}帧)")

    # run (8帧)
    run_frames = 8
    img = Image.new("RGBA", (FW * run_frames, FH), P.T)
    for i in range(run_frames):
        arm = [-2, -1, 0, 1, 2, 1, 0, -1][i]
        leg = [0, 1, 2, 1, 0, 1, 2, 1][i]
        _base(img, i * FW, 0, arm_dy=arm, leg_mode=leg, head_tilt=[0,0,1,0,0,0,-1,0][i])
    img.save(os.path.join(out, "miko_run.png"))
    print(f"  miko_run.png ({FW*run_frames}x{FH}, {run_frames}帧)")

    # jump (3帧)
    jf = 3
    img = Image.new("RGBA", (FW * jf, FH), P.T)
    for i in range(jf):
        arm = [-3, -4, -3][i]
        _base(img, i * FW, 0, arm_dy=arm, leg_mode=i, squat=[-2,0,2][i])
    img.save(os.path.join(out, "miko_jump.png"))
    print(f"  miko_jump.png ({FW*jf}x{FH}, {jf}帧)")

    # fall (2帧)
    ff = 2
    img = Image.new("RGBA", (FW * ff, FH), P.T)
    for i in range(ff):
        _base(img, i * FW, 0, arm_dy=-2+i, leg_mode=1, squat=2)
    img.save(os.path.join(out, "miko_fall.png"))
    print(f"  miko_fall.png ({FW*ff}x{FH}, {ff}帧)")

    # interact (4帧 - 鞠躬/祈祷)
    intf = 4
    img = Image.new("RGBA", (FW * intf, FH), P.T)
    for i in range(intf):
        sq = [0, 3, 5, 3][i]
        _base(img, i * FW, 0, arm_dy=[0, -2, -3, -2][i], leg_mode=0, squat=sq, head_tilt=[0,1,2,1][i])
    img.save(os.path.join(out, "miko_interact.png"))
    print(f"  miko_interact.png ({FW*intf}x{FH}, {intf}帧)")


# ═══════════════════════════════════════════════════════
# 2. 白狐精灵表 (64×48 per frame)
# ═══════════════════════════════════════════════════════
def gen_fox():
    out = os.path.join(ASSETS, "sprites", "npcs"); ensure_dir(out)
    FW, FH = 64, 48

    def _fox(img, fx, fy, tail_phase=0, ear_tilt=0, walk_frame=0, look_back=False):
        cx = fx + 32
        body_y = fy + 24

        # ── 尾巴 (蓬松大尾，带狐火) ──
        tail_base_x = cx - 18 if not look_back else cx + 18
        tail_dir = -1 if not look_back else 1
        for seg in range(18):
            t = seg / 18.0
            ty = body_y - 4 - int(15 * math.sin(t * math.pi) + tail_phase * math.sin(t * 3))
            tx = tail_base_x + tail_dir * seg
            r = max(1, int(4 * (1.0 - t * 0.6)))
            for dy in range(-r, r+1):
                for dx in range(-r, r+1):
                    if dx*dx + dy*dy <= r*r:
                        c = P.FOX_WHITE if abs(dy) < r-1 else P.FOX_SHADOW
                        if t > 0.7:
                            c = blend(c, P.FOX_TAIL_TIP, (t - 0.7) / 0.3)
                        px(img, tx+dx, ty+dy, c)
        # 尾尖狐火微光
        tip_x = tail_base_x + tail_dir * 17
        tip_y = body_y - 4 - int(15 * math.sin(math.pi) + tail_phase)
        for r in [3, 2, 1]:
            c = [P.FOXFIRE_FAINT, P.FOXFIRE_OUTER, P.FOXFIRE_BRIGHT][3-r]
            fill_circle(img, tip_x, tip_y, r, c)

        # ── 身体 ──
        for dy in range(0, 10):
            w = 12 - abs(dy - 5)
            for dx in range(-w, w+1):
                walk_offset = [0, -1, 0, 1, 0, -1][walk_frame % 6] if walk_frame else 0
                yy = body_y + dy + (1 if abs(dx) > w-2 else 0)
                if abs(dx) >= w-1:
                    c = P.FOX_DEEP
                elif abs(dx) >= w-3:
                    c = P.FOX_SHADOW
                elif dy < 3:
                    c = P.FOX_WHITE
                else:
                    c = P.FOX_LIGHT
                px(img, cx+dx, yy + walk_offset, c)

        # ── 腿 (4条) ──
        leg_offsets = [-7, -3, 3, 7]
        for li, lx in enumerate(leg_offsets):
            walk_dy = 0
            if walk_frame:
                walk_dy = [0, 1, 2, 1, 0, -1][((walk_frame + li * 2) % 6)]
            for dy in range(0, 6):
                for dx in range(-1, 2):
                    c = P.FOX_SHADOW if dx == 0 else P.FOX_DEEP
                    px(img, cx+lx+dx, body_y+9+dy+walk_dy, c)

        # ── 头部 ──
        head_x = cx + (14 if not look_back else -14)
        head_y = body_y - 2
        # 头轮廓
        for dy in range(-5, 5):
            w = 8 - abs(dy)
            for dx in range(-w, w+1):
                if not look_back:
                    dx2 = dx
                else:
                    dx2 = -dx
                if abs(dx) >= w-1:
                    c = P.FOX_SHADOW
                elif dy < -2:
                    c = P.FOX_WHITE
                else:
                    c = P.FOX_LIGHT
                px(img, head_x+dx2, head_y+dy, c)

        # 耳朵
        ear_base = head_y - 5
        for side in [-1, 1]:
            ex = head_x + side * 5
            for dy in range(0, 7):
                w = max(1, 3 - dy // 2)
                for dx in range(-w, w+1):
                    c = P.FOX_WHITE if abs(dx) >= w else P.FOX_EAR
                    px(img, ex+dx + ear_tilt * side, ear_base-dy, c)

        # 鼻子 & 眼睛
        nose_x = head_x + (6 if not look_back else -6)
        px(img, nose_x, head_y+1, P.FOX_NOSE)
        px(img, nose_x-1, head_y+1, P.FOX_NOSE)
        # 眼
        eye_x = head_x + (3 if not look_back else -3)
        for side in [-1, 1]:
            ey = head_y - 1 + side * 0
            px(img, eye_x, ey - 1, P.FOX_EYE)
            px(img, eye_x, ey, P.FOX_EYE)
            px(img, eye_x+1, ey - 1, P.FOX_EYE_BRIGHT)

    # idle (4帧)
    nf = 4
    img = Image.new("RGBA", (FW*nf, FH), P.T)
    for i in range(nf):
        _fox(img, i*FW, 0, tail_phase=[0, 1, 0, -1][i], ear_tilt=[0,0,1,0][i])
    img.save(os.path.join(out, "fox_idle.png"))
    print(f"  fox_idle.png ({FW*nf}x{FH}, {nf}帧)")

    # walk (6帧)
    nf = 6
    img = Image.new("RGBA", (FW*nf, FH), P.T)
    for i in range(nf):
        _fox(img, i*FW, 0, tail_phase=[0,1,2,1,0,-1][i], walk_frame=i)
    img.save(os.path.join(out, "fox_walk.png"))
    print(f"  fox_walk.png ({FW*nf}x{FH}, {nf}帧)")

    # look_back (3帧)
    nf = 3
    img = Image.new("RGBA", (FW*nf, FH), P.T)
    for i in range(nf):
        _fox(img, i*FW, 0, tail_phase=i, look_back=(i >= 1), ear_tilt=i)
    img.save(os.path.join(out, "fox_look_back.png"))
    print(f"  fox_look_back.png ({FW*nf}x{FH}, {nf}帧)")


# ═══════════════════════════════════════════════════════
# 3. 老人NPC (64×96, 2帧)
# ═══════════════════════════════════════════════════════
def gen_elder():
    out = os.path.join(ASSETS, "sprites", "npcs"); ensure_dir(out)
    FW, FH = 64, 96
    img = Image.new("RGBA", (FW*2, FH), P.T)
    for i in range(2):
        cx = i * FW + 32
        by = 15
        breath = i

        # 白发
        for dy in range(-2, 6):
            w = 8 - abs(dy - 2)
            for dx in range(-w, w+1):
                c = (200, 195, 210, 255) if abs(dx) < w-1 else (170, 165, 185, 255)
                px(img, cx+dx, by+dy, c)
        # 胡须
        for dy in range(10, 20):
            w = 3 - (dy-10)//4
            if w < 1: w = 1
            for dx in range(-w, w+1):
                px(img, cx+dx, by+dy, (210, 205, 220, 255))

        # 脸
        for dy in range(4, 10):
            w = 6 - max(0, dy-7)
            for dx in range(-w, w+1):
                px(img, cx+dx, by+dy, P.SKIN_SHADOW)
        # 眼
        px(img, cx-3, by+6, P.HAIR_DARK)
        px(img, cx+3, by+6, P.HAIR_DARK)

        # 深色和服
        robe_y = by + 12
        for dy in range(0, 50 + breath):
            w = 10 + dy // 5
            for dx in range(-w, w+1):
                if abs(dx) >= w-1:
                    c = (30, 25, 45, 255)
                elif abs(dx) >= w-3:
                    c = (45, 38, 62, 255)
                else:
                    c = (55, 48, 75, 255)
                px(img, cx+dx, robe_y+dy, c)
        # 拐杖
        stick_x = cx + 14
        for dy in range(0, 55):
            px(img, stick_x, robe_y - 5 + dy, P.WOOD_MID)
            px(img, stick_x+1, robe_y - 5 + dy, P.WOOD_DARK)
        # 脚
        foot_y = robe_y + 51 + breath
        for side in [-1, 1]:
            for dx in range(-2, 3):
                px(img, cx+side*4+dx, foot_y, P.GETA_WOOD)
                px(img, cx+side*4+dx, foot_y+1, P.WOOD_DARK)

    img.save(os.path.join(out, "elder_idle.png"))
    print(f"  elder_idle.png ({FW*2}x{FH}, 2帧)")


# ═══════════════════════════════════════════════════════
# 4. Tileset (16×16 保持, 但更精细的绘制)
# ═══════════════════════════════════════════════════════
def gen_tileset():
    out = os.path.join(ASSETS, "tilesets"); ensure_dir(out)
    TW, TH, COLS, ROWS = 16, 16, 8, 5
    ts = Image.new("RGBA", (TW*COLS, TH*ROWS), P.T)
    random.seed(42)

    def tile(col, row):
        return (col*TW, row*TH)

    # Row 0: 草地×2, 平台顶, 角×2, 泥土, 石块×2
    # 草地A
    tx, ty = tile(0, 0)
    fill_rect(ts, tx, ty, 16, 16, P.GROUND_MID)
    fill_rect(ts, tx, ty, 16, 3, P.GRASS_MID)
    for x in range(16):
        h = random.randint(1, 4)
        for y in range(h):
            px(ts, tx+x, ty+y, P.GRASS_LIGHT if y == 0 else P.GRASS_MID)
        if x % 3 == 0:
            px(ts, tx+x, ty, P.GRASS_TIP)
    # 泥土纹理
    for _ in range(12):
        rx, ry = random.randint(0, 15), random.randint(4, 15)
        px(ts, tx+rx, ty+ry, P.GROUND_LIGHT if random.random() > 0.5 else P.GROUND_DARK)

    # 草地B (变体)
    tx, ty = tile(1, 0)
    fill_rect(ts, tx, ty, 16, 16, P.GROUND_MID)
    fill_rect(ts, tx, ty, 16, 2, P.GRASS_DARK)
    for x in range(16):
        if x % 2 == 0:
            h = random.randint(2, 5)
            for y in range(h):
                px(ts, tx+x, ty+y, [P.GRASS_TIP, P.GRASS_LIGHT, P.GRASS_MID, P.GRASS_DARK, P.GRASS_DARK][y])
    for _ in range(8):
        rx, ry = random.randint(0, 15), random.randint(5, 15)
        px(ts, tx+rx, ty+ry, P.GROUND_HIGHLIGHT)

    # 平台顶
    tx, ty = tile(2, 0)
    fill_rect(ts, tx, ty+2, 16, 14, P.STONE_MID)
    fill_rect(ts, tx, ty, 16, 3, P.STONE_LIGHT)
    px(ts, tx, ty, P.STONE_HIGHLIGHT); px(ts, tx+15, ty, P.STONE_HIGHLIGHT)
    for _ in range(10):
        rx, ry = random.randint(0, 15), random.randint(3, 15)
        px(ts, tx+rx, ty+ry, P.STONE_DARK if random.random() > 0.5 else P.STONE_HIGHLIGHT)

    # 左角, 右角
    for ci, col in enumerate([3, 4]):
        tx, ty = tile(col, 0)
        fill_rect(ts, tx, ty, 16, 16, P.GROUND_MID)
        if ci == 0:  # 左
            for y in range(16):
                px(ts, tx, ty+y, P.GROUND_DARK)
                px(ts, tx+1, ty+y, P.GROUND_DARK)
            fill_rect(ts, tx+2, ty, 14, 3, P.GRASS_MID)
        else:  # 右
            for y in range(16):
                px(ts, tx+14, ty+y, P.GROUND_DARK)
                px(ts, tx+15, ty+y, P.GROUND_DARK)
            fill_rect(ts, tx, ty, 14, 3, P.GRASS_MID)

    # 泥土
    tx, ty = tile(5, 0)
    fill_rect(ts, tx, ty, 16, 16, P.GROUND_MID)
    for _ in range(20):
        rx, ry = random.randint(0, 15), random.randint(0, 15)
        px(ts, tx+rx, ty+ry, random.choice([P.GROUND_DARK, P.GROUND_LIGHT, P.GROUND_HIGHLIGHT]))

    # 石块A, B
    for ci, col in enumerate([6, 7]):
        tx, ty = tile(col, 0)
        fill_rect(ts, tx, ty, 16, 16, P.STONE_MID)
        # 裂纹
        for _ in range(3):
            sx, sy = random.randint(2, 13), random.randint(2, 13)
            for step in range(random.randint(3, 6)):
                px(ts, tx+sx, ty+sy, P.STONE_DARK)
                sx += random.randint(-1, 1)
                sy += random.randint(0, 1)
        # 高光
        fill_rect(ts, tx, ty, 16, 1, P.STONE_HIGHLIGHT)
        # 苔藓
        if ci == 1:
            for x in range(0, 16, 3):
                for y in range(1, 3):
                    px(ts, tx+x, ty+y, P.MOSS)

    # Row 1: 填充×2, 壁×2, 桥板, 桥栏, 阶梯×2
    tx, ty = tile(0, 1)
    fill_rect(ts, tx, ty, 16, 16, P.GROUND_MID)
    dither_fill(ts, tx, ty+8, 16, 8, P.GROUND_MID, P.GROUND_DARK)

    tx, ty = tile(1, 1)
    fill_rect(ts, tx, ty, 16, 16, P.STONE_MID)
    dither_fill(ts, tx, ty+8, 16, 8, P.STONE_MID, P.STONE_DARK)

    # 壁
    for ci, col in enumerate([2, 3]):
        tx, ty = tile(col, 1)
        fill_rect(ts, tx, ty, 16, 16, P.STONE_DARK)
        edge_x = tx if ci == 0 else tx + 15
        for y in range(16):
            px(ts, edge_x, ty+y, P.STONE_MID)
            if ci == 0:
                px(ts, edge_x+1, ty+y, P.STONE_LIGHT)
            else:
                px(ts, edge_x-1, ty+y, P.STONE_LIGHT)

    # 桥板
    tx, ty = tile(4, 1)
    fill_rect(ts, tx, ty, 16, 16, P.WOOD_MID)
    for y in range(0, 16, 4):
        fill_rect(ts, tx, ty+y, 16, 1, P.WOOD_DARK)
    fill_rect(ts, tx, ty, 16, 2, P.WOOD_LIGHT)

    # 桥栏
    tx, ty = tile(5, 1)
    fill_rect(ts, tx+6, ty, 4, 16, P.WOOD_MID)
    fill_rect(ts, tx, ty, 16, 3, P.WOOD_LIGHT)
    fill_rect(ts, tx+7, ty, 2, 16, P.WOOD_DARK)

    # 阶梯
    for ci, col in enumerate([6, 7]):
        tx, ty = tile(col, 1)
        fill_rect(ts, tx, ty, 16, 16, P.STONE_MID)
        if ci == 0:
            for s in range(4):
                fill_rect(ts, tx+s*4, ty+s*4, 16-s*4, 4, P.STONE_LIGHT)
                px(ts, tx+s*4, ty+s*4, P.STONE_HIGHLIGHT)
        else:
            for s in range(4):
                fill_rect(ts, tx, ty+s*4, 16-s*4, 4, P.STONE_LIGHT)

    # Row 2: 鸟居装饰(4格), 灯笼(2格), 草丛, 蘑菇
    # 鸟居上左
    tx, ty = tile(0, 2)
    fill_rect(ts, tx, ty+2, 16, 4, P.TORII_RED)
    fill_rect(ts, tx, ty, 16, 2, P.TORII_LIGHT)
    fill_rect(ts, tx+2, ty+6, 3, 10, P.TORII_RED)
    # 鸟居上右
    tx, ty = tile(1, 2)
    fill_rect(ts, tx, ty+2, 16, 4, P.TORII_RED)
    fill_rect(ts, tx, ty, 16, 2, P.TORII_LIGHT)
    fill_rect(ts, tx+11, ty+6, 3, 10, P.TORII_RED)
    # 鸟居下左
    tx, ty = tile(2, 2)
    fill_rect(ts, tx+2, ty, 3, 16, P.TORII_RED)
    fill_rect(ts, tx+3, ty, 1, 16, P.TORII_DARK)
    # 鸟居下右
    tx, ty = tile(3, 2)
    fill_rect(ts, tx+11, ty, 3, 16, P.TORII_RED)
    fill_rect(ts, tx+12, ty, 1, 16, P.TORII_DARK)

    # 灯笼上
    tx, ty = tile(4, 2)
    fill_rect(ts, tx+5, ty, 6, 8, P.STONE_LIGHT)
    fill_rect(ts, tx+6, ty+1, 4, 6, P.STONE_MID)
    fill_circle(ts, tx+8, ty+4, 2, (255, 200, 100, 180))
    # 灯笼下 (柱)
    tx, ty = tile(5, 2)
    fill_rect(ts, tx+7, ty, 2, 14, P.STONE_MID)
    fill_rect(ts, tx+4, ty+14, 8, 2, P.STONE_DARK)

    # 草丛
    tx, ty = tile(6, 2)
    for x in range(16):
        h = random.randint(4, 12)
        for y in range(16-h, 16):
            t = (y - (16-h)) / h
            c = P.GRASS_TIP if t < 0.2 else (P.GRASS_LIGHT if t < 0.5 else P.GRASS_MID)
            px(ts, tx+x, ty+y, c)

    # 蘑菇
    tx, ty = tile(7, 2)
    # 茎
    fill_rect(ts, tx+6, ty+8, 4, 8, (220, 210, 195, 255))
    # 伞
    fill_ellipse(ts, tx+2, ty+2, 12, 8, (180, 50, 40, 255))
    # 白点
    for pos in [(5, 4), (9, 3), (7, 5), (11, 4)]:
        px(ts, tx+pos[0], ty+pos[1], (255, 245, 235, 255))

    # Row 3: 木墙, 纸门, 柱子, 瓦屋顶, 空×4
    tx, ty = tile(0, 3)
    fill_rect(ts, tx, ty, 16, 16, P.WOOD_MID)
    for y in range(0, 16, 4):
        fill_rect(ts, tx, ty+y, 16, 1, P.WOOD_DARK)
    for x in range(0, 16, 8):
        fill_rect(ts, tx+x, ty, 1, 16, P.WOOD_DARK)

    # 纸门 (障子)
    tx, ty = tile(1, 3)
    fill_rect(ts, tx, ty, 16, 16, P.PAPER_WHITE)
    for y in range(0, 16, 5):
        fill_rect(ts, tx, ty+y, 16, 1, P.WOOD_MID)
    for x in range(0, 16, 5):
        fill_rect(ts, tx+x, ty, 1, 16, P.WOOD_MID)
    fill_rect(ts, tx, ty, 1, 16, P.WOOD_DARK)
    fill_rect(ts, tx+15, ty, 1, 16, P.WOOD_DARK)

    # 柱子
    tx, ty = tile(2, 3)
    fill_rect(ts, tx+5, ty, 6, 16, P.TORII_RED)
    fill_rect(ts, tx+6, ty, 1, 16, P.TORII_LIGHT)
    fill_rect(ts, tx+10, ty, 1, 16, P.TORII_DARK)

    # 瓦屋顶
    tx, ty = tile(3, 3)
    for y in range(16):
        fill_rect(ts, tx, ty+y, 16, 1, (60, 55, 72, 255) if y % 3 == 0 else (50, 45, 62, 255))
    for y in range(0, 16, 3):
        fill_rect(ts, tx, ty+y, 16, 1, (70, 65, 85, 255))

    # Row 4: 单向台, 绳索, 铃铛, 注连绳, 空×4
    tx, ty = tile(0, 4)
    fill_rect(ts, tx, ty, 16, 3, P.WOOD_LIGHT)
    fill_rect(ts, tx, ty+3, 16, 1, P.WOOD_DARK)
    dither_fill(ts, tx, ty+4, 16, 4, P.WOOD_MID, P.T)

    # 绳索
    tx, ty = tile(1, 4)
    for y in range(16):
        w = 1 + (y % 3 == 0)
        fill_rect(ts, tx+7-w, ty+y, w*2+1, 1, P.ROPE_STRAW if y % 2 == 0 else P.ROPE_DARK)

    # 铃铛
    tx, ty = tile(2, 4)
    fill_rect(ts, tx+5, ty, 6, 3, P.OBI_GOLD)
    fill_ellipse(ts, tx+4, ty+3, 8, 10, P.OBI_GOLD)
    fill_ellipse(ts, tx+5, ty+4, 6, 8, P.OBI_DARK)
    fill_rect(ts, tx+7, ty+10, 2, 4, P.ROPE_STRAW)

    # 注连绳
    tx, ty = tile(3, 4)
    for x in range(16):
        y_off = int(2 * math.sin(x * 0.5))
        for dy in range(-2, 3):
            c = P.ROPE_STRAW if abs(dy) < 2 else P.ROPE_DARK
            px(ts, tx+x, ty+7+y_off+dy, c)
    # 纸垂
    for sx in [3, 8, 13]:
        for dy in range(5):
            for dx in range(-1, 2):
                px(ts, tx+sx+dx, ty+10+dy, P.PAPER_WHITE if abs(dx) < 1 else P.PAPER_SHADOW)

    # 放大到2× (32×32每格) 匹配64×96角色比例
    ts = ts.resize((256, 160), Image.NEAREST)
    ts.save(os.path.join(out, "forest_tileset.png"))
    print(f"  forest_tileset.png (256x160, 8x5 @32x32)")

    # ── 神社专用 tileset（完全独立，无复用森林瓦片）──
    random.seed(99)
    ss = Image.new("RGBA", (TW*COLS, TH*ROWS), P.T)

    # --- 神社专用色板 ---
    TATAMI_BASE = (140, 155, 100, 255)
    TATAMI_LINE = (120, 135, 82, 255)
    TATAMI_EDGE = (105, 88, 56, 255)
    DARK_WOOD = (48, 30, 18, 255)
    AGED_WOOD = (85, 58, 34, 255)
    AGED_WOOD_L = (110, 78, 48, 255)
    PLASTER_BASE = (185, 175, 160, 255)
    PLASTER_CRACK = (155, 145, 130, 255)
    PLASTER_DARK = (125, 118, 105, 255)
    TILE_BLUE_D = (40, 42, 62, 255)
    TILE_BLUE_M = (55, 58, 78, 255)
    TILE_BLUE_L = (70, 72, 92, 255)
    LANTERN_RED = (195, 50, 40, 255)
    LANTERN_RED_L = (220, 70, 55, 255)
    GOLD_BRIGHT = (230, 195, 100, 255)
    GOLD_DARK = (160, 125, 50, 255)

    # Row 0: 木板地A, 木板地B, 畳A, 畳B, 暗木地板, 石板地, 古木地板A, 古木地板B
    # (0,0) 木板地A
    tx, ty = tile(0, 0)
    fill_rect(ss, tx, ty, 16, 16, P.WOOD_MID)
    for y in range(0, 16, 4):
        fill_rect(ss, tx, ty+y, 16, 1, P.WOOD_DARK)
    fill_rect(ss, tx, ty, 16, 1, P.WOOD_LIGHT)
    for _ in range(6):
        rx, ry = random.randint(0, 15), random.randint(1, 15)
        px(ss, tx+rx, ty+ry, P.WOOD_HIGHLIGHT if random.random() > 0.5 else P.WOOD_DARK)

    # (1,0) 木板地B
    tx, ty = tile(1, 0)
    fill_rect(ss, tx, ty, 16, 16, P.WOOD_MID)
    for y in range(2, 16, 4):
        fill_rect(ss, tx, ty+y, 16, 1, P.WOOD_DARK)
    for _ in range(8):
        rx, ry = random.randint(0, 15), random.randint(0, 15)
        px(ss, tx+rx, ty+ry, P.WOOD_LIGHT)

    # (2,0) 畳A (横纹)
    tx, ty = tile(2, 0)
    fill_rect(ss, tx, ty, 16, 16, TATAMI_BASE)
    for y in range(0, 16, 2):
        fill_rect(ss, tx, ty+y, 16, 1, TATAMI_LINE)
    fill_rect(ss, tx, ty, 16, 1, TATAMI_EDGE)
    fill_rect(ss, tx, ty+15, 16, 1, TATAMI_EDGE)

    # (3,0) 畳B (纵纹)
    tx, ty = tile(3, 0)
    fill_rect(ss, tx, ty, 16, 16, TATAMI_BASE)
    for x in range(0, 16, 2):
        fill_rect(ss, tx+x, ty, 1, 16, TATAMI_LINE)
    fill_rect(ss, tx, ty, 1, 16, TATAMI_EDGE)
    fill_rect(ss, tx+15, ty, 1, 16, TATAMI_EDGE)

    # (4,0) 暗木地板
    tx, ty = tile(4, 0)
    fill_rect(ss, tx, ty, 16, 16, DARK_WOOD)
    for y in range(0, 16, 3):
        fill_rect(ss, tx, ty+y, 16, 1, (35, 22, 12, 255))
    for _ in range(5):
        rx, ry = random.randint(0, 15), random.randint(0, 15)
        px(ss, tx+rx, ty+ry, P.WOOD_MID)

    # (5,0) 石板地
    tx, ty = tile(5, 0)
    fill_rect(ss, tx, ty, 16, 16, P.STONE_MID)
    fill_rect(ss, tx, ty+7, 16, 1, P.STONE_DARK)
    fill_rect(ss, tx+7, ty, 1, 16, P.STONE_DARK)
    for _ in range(8):
        rx, ry = random.randint(0, 15), random.randint(0, 15)
        px(ss, tx+rx, ty+ry, P.STONE_HIGHLIGHT)

    # (6,0) 古木地板A
    tx, ty = tile(6, 0)
    fill_rect(ss, tx, ty, 16, 16, AGED_WOOD)
    for y in range(0, 16, 5):
        fill_rect(ss, tx, ty+y, 16, 1, P.WOOD_DARK)
    for _ in range(4):
        sx = random.randint(2, 13)
        for dy in range(16):
            px(ss, tx+sx+(dy%3==0), ty+dy, P.WOOD_LIGHT)

    # (7,0) 古木地板B
    tx, ty = tile(7, 0)
    fill_rect(ss, tx, ty, 16, 16, (90, 62, 38, 255))
    for y in range(1, 16, 5):
        fill_rect(ss, tx, ty+y, 16, 1, P.WOOD_DARK)
    for _ in range(3):
        sx = random.randint(3, 12)
        for dy in range(16):
            px(ss, tx+sx-(dy%3==0), ty+dy, AGED_WOOD_L)

    # Row 1: 木壁A, 木壁B, 障子A, 障子B(半开), 朱柱, 木柱, 朱壁A, 朱壁B
    # (0,1) 木壁A (竖板条)
    tx, ty = tile(0, 1)
    fill_rect(ss, tx, ty, 16, 16, P.WOOD_MID)
    for x in range(0, 16, 4):
        fill_rect(ss, tx+x, ty, 1, 16, P.WOOD_DARK)
    fill_rect(ss, tx, ty+14, 16, 2, P.WOOD_DARK)

    # (1,1) 木壁B
    tx, ty = tile(1, 1)
    fill_rect(ss, tx, ty, 16, 16, P.WOOD_MID)
    for x in range(2, 16, 4):
        fill_rect(ss, tx+x, ty, 1, 16, P.WOOD_DARK)
    fill_rect(ss, tx, ty, 16, 2, P.WOOD_LIGHT)

    # (2,1) 障子A (完整格子门)
    tx, ty = tile(2, 1)
    fill_rect(ss, tx, ty, 16, 16, P.PAPER_WHITE)
    for y in range(0, 16, 5):
        fill_rect(ss, tx, ty+y, 16, 1, P.WOOD_MID)
    for x in range(0, 16, 5):
        fill_rect(ss, tx+x, ty, 1, 16, P.WOOD_MID)
    fill_rect(ss, tx, ty, 1, 16, P.WOOD_DARK)
    fill_rect(ss, tx+15, ty, 1, 16, P.WOOD_DARK)

    # (3,1) 障子B (半开，左纸右暗)
    tx, ty = tile(3, 1)
    fill_rect(ss, tx, ty, 8, 16, P.PAPER_WHITE)
    fill_rect(ss, tx+8, ty, 8, 16, (18, 14, 28, 255))
    for y in range(0, 16, 5):
        fill_rect(ss, tx, ty+y, 8, 1, P.WOOD_MID)
    for x in range(0, 8, 5):
        fill_rect(ss, tx+x, ty, 1, 16, P.WOOD_MID)
    fill_rect(ss, tx+7, ty, 1, 16, P.WOOD_MID)

    # (4,1) 朱柱
    tx, ty = tile(4, 1)
    fill_rect(ss, tx+5, ty, 6, 16, P.TORII_RED)
    fill_rect(ss, tx+6, ty, 1, 16, P.TORII_LIGHT)
    fill_rect(ss, tx+10, ty, 1, 16, P.TORII_DARK)

    # (5,1) 木柱
    tx, ty = tile(5, 1)
    fill_rect(ss, tx+5, ty, 6, 16, P.WOOD_MID)
    fill_rect(ss, tx+6, ty, 2, 16, P.WOOD_LIGHT)
    fill_rect(ss, tx+10, ty, 1, 16, P.WOOD_DARK)

    # (6,1) 朱壁A
    tx, ty = tile(6, 1)
    fill_rect(ss, tx, ty, 16, 16, P.TORII_DARK)
    for _ in range(6):
        rx, ry = random.randint(0, 15), random.randint(0, 15)
        px(ss, tx+rx, ty+ry, P.TORII_RED)
    fill_rect(ss, tx, ty+14, 16, 2, P.WOOD_DARK)

    # (7,1) 朱壁B
    tx, ty = tile(7, 1)
    fill_rect(ss, tx, ty, 16, 16, P.TORII_RED)
    fill_rect(ss, tx, ty, 16, 2, P.TORII_LIGHT)
    fill_rect(ss, tx, ty+14, 16, 2, P.TORII_DARK)

    # Row 2: 漆喰壁A, 漆喰壁B, 欄間(装饰横栏), 格子窓A, 格子窓B, 賽銭箱, 苔石A, 苔石B
    # (0,2) 漆喰壁A (白灰泥壁)
    tx, ty = tile(0, 2)
    fill_rect(ss, tx, ty, 16, 16, PLASTER_BASE)
    for _ in range(10):
        rx, ry = random.randint(0, 15), random.randint(0, 15)
        px(ss, tx+rx, ty+ry, PLASTER_CRACK)
    fill_rect(ss, tx, ty+14, 16, 2, PLASTER_DARK)

    # (1,2) 漆喰壁B (带裂痕)
    tx, ty = tile(1, 2)
    fill_rect(ss, tx, ty, 16, 16, PLASTER_BASE)
    # 裂缝
    cx, cy = 5, 3
    for _ in range(8):
        px(ss, tx+cx, ty+cy, PLASTER_DARK)
        cx += random.choice([-1, 0, 1])
        cy += random.choice([0, 1])
        cx = max(0, min(15, cx))
        cy = max(0, min(15, cy))
    fill_rect(ss, tx, ty, 16, 1, PLASTER_DARK)

    # (2,2) 欄間 (装饰横栏)
    tx, ty = tile(2, 2)
    fill_rect(ss, tx, ty, 16, 16, P.WOOD_MID)
    fill_rect(ss, tx, ty+4, 16, 8, P.WOOD_DARK)
    # 镂空图案
    for ox in [2, 6, 10]:
        fill_rect(ss, tx+ox, ty+5, 3, 6, (18, 14, 28, 255))  # 暗透
    fill_rect(ss, tx, ty, 16, 2, P.WOOD_LIGHT)
    fill_rect(ss, tx, ty+14, 16, 2, P.WOOD_LIGHT)

    # (3,2) 格子窓A (格子窗)
    tx, ty = tile(3, 2)
    fill_rect(ss, tx, ty, 16, 16, (20, 18, 40, 255))
    for x in range(1, 16, 3):
        fill_rect(ss, tx+x, ty, 2, 16, P.WOOD_MID)
    for y in range(1, 16, 3):
        fill_rect(ss, tx, ty+y, 16, 2, P.WOOD_MID)

    # (4,2) 格子窓B (稀疏格子)
    tx, ty = tile(4, 2)
    fill_rect(ss, tx, ty, 16, 16, (22, 20, 45, 255))
    for x in range(2, 16, 4):
        fill_rect(ss, tx+x, ty, 1, 16, P.WOOD_MID)
    for y in range(2, 16, 4):
        fill_rect(ss, tx, ty+y, 16, 1, P.WOOD_MID)

    # (5,2) 賽銭箱
    tx, ty = tile(5, 2)
    fill_rect(ss, tx+2, ty+4, 12, 10, P.WOOD_MID)
    fill_rect(ss, tx+3, ty+5, 10, 8, P.WOOD_DARK)
    fill_rect(ss, tx+2, ty+4, 12, 2, P.WOOD_LIGHT)
    fill_rect(ss, tx+6, ty+6, 4, 2, GOLD_BRIGHT)

    # (6,2) 苔石A
    tx, ty = tile(6, 2)
    fill_rect(ss, tx, ty, 16, 16, P.STONE_MID)
    fill_rect(ss, tx, ty, 16, 1, P.STONE_HIGHLIGHT)
    for _ in range(8):
        rx, ry = random.randint(0, 15), random.randint(1, 12)
        px(ss, tx+rx, ty+ry, P.MOSS)
    for _ in range(4):
        rx = random.randint(0, 15)
        px(ss, tx+rx, ty+1, P.MOSS_DARK)

    # (7,2) 苔石B
    tx, ty = tile(7, 2)
    fill_rect(ss, tx, ty, 16, 16, P.STONE_DARK)
    for _ in range(12):
        rx, ry = random.randint(0, 15), random.randint(0, 15)
        px(ss, tx+rx, ty+ry, P.STONE_MID if random.random() > 0.5 else P.MOSS)

    # Row 3: 瓦屋顶A, 瓦屋顶B, 鬼瓦, 木天井A, 木天井B, 注連縄+紙垂, 提灯A, 提灯B
    # (0,3) 瓦屋顶A
    tx, ty = tile(0, 3)
    for y in range(16):
        fill_rect(ss, tx, ty+y, 16, 1, TILE_BLUE_D if y % 3 == 0 else TILE_BLUE_M)
    for y in range(0, 16, 3):
        fill_rect(ss, tx, ty+y, 16, 1, TILE_BLUE_L)

    # (1,3) 瓦屋顶B (弯曲瓦)
    tx, ty = tile(1, 3)
    for y in range(16):
        c = TILE_BLUE_L if y % 4 < 2 else TILE_BLUE_D
        fill_rect(ss, tx, ty+y, 16, 1, c)
    fill_rect(ss, tx, ty+15, 16, 1, (38, 35, 52, 255))

    # (2,3) 鬼瓦 (屋顶装饰兽面)
    tx, ty = tile(2, 3)
    fill_rect(ss, tx, ty, 16, 16, TILE_BLUE_M)
    # 兽面轮廓
    fill_rect(ss, tx+4, ty+3, 8, 10, P.STONE_DARK)
    fill_rect(ss, tx+5, ty+4, 6, 8, P.STONE_MID)
    # 眼
    px(ss, tx+6, ty+6, P.FOXFIRE_BRIGHT)
    px(ss, tx+9, ty+6, P.FOXFIRE_BRIGHT)
    # 口
    fill_rect(ss, tx+6, ty+9, 4, 1, P.STONE_DARK)

    # (3,3) 木天井A (木格天花板)
    tx, ty = tile(3, 3)
    fill_rect(ss, tx, ty, 16, 16, AGED_WOOD)
    for x in range(0, 16, 8):
        fill_rect(ss, tx+x, ty, 1, 16, DARK_WOOD)
    for y in range(0, 16, 8):
        fill_rect(ss, tx, ty+y, 16, 1, DARK_WOOD)
    for _ in range(4):
        rx, ry = random.randint(0, 15), random.randint(0, 15)
        px(ss, tx+rx, ty+ry, AGED_WOOD_L)

    # (4,3) 木天井B (竹天花板)
    tx, ty = tile(4, 3)
    bamboo_base = (115, 130, 85, 255)
    bamboo_line = (95, 110, 65, 255)
    fill_rect(ss, tx, ty, 16, 16, bamboo_base)
    for x in range(0, 16, 2):
        fill_rect(ss, tx+x, ty, 1, 16, bamboo_line)
    for y in range(0, 16, 6):
        fill_rect(ss, tx, ty+y, 16, 1, (80, 95, 55, 255))

    # (5,3) 注連縄+紙垂
    tx, ty = tile(5, 3)
    for x in range(16):
        y_off = int(2 * math.sin(x * 0.5))
        for dy in range(-2, 3):
            c = P.ROPE_STRAW if abs(dy) < 2 else P.ROPE_DARK
            px(ss, tx+x, ty+5+y_off+dy, c)
    for sx in [3, 8, 13]:
        for dy in range(5):
            for dx in range(-1, 2):
                px(ss, tx+sx+dx, ty+8+dy, P.PAPER_WHITE if abs(dx) < 1 else P.PAPER_SHADOW)

    # (6,3) 提灯A (丸提灯赤)
    tx, ty = tile(6, 3)
    fill_ellipse(ss, tx+3, ty+2, 10, 12, LANTERN_RED)
    fill_ellipse(ss, tx+4, ty+3, 8, 10, LANTERN_RED_L)
    fill_rect(ss, tx+6, ty, 4, 2, DARK_WOOD)
    fill_rect(ss, tx+7, ty+14, 2, 2, DARK_WOOD)
    # 灯光
    fill_ellipse(ss, tx+5, ty+4, 6, 6, (255, 200, 120, 120))

    # (7,3) 提灯B (小行灯)
    tx, ty = tile(7, 3)
    fill_rect(ss, tx+4, ty+2, 8, 12, P.PAPER_WHITE)
    fill_rect(ss, tx+4, ty+2, 8, 1, DARK_WOOD)
    fill_rect(ss, tx+4, ty+13, 8, 1, DARK_WOOD)
    fill_rect(ss, tx+4, ty+2, 1, 12, DARK_WOOD)
    fill_rect(ss, tx+11, ty+2, 1, 12, DARK_WOOD)
    fill_ellipse(ss, tx+6, ty+5, 4, 5, (255, 210, 140, 150))

    # Row 4: 単方向台(木), 燭台, 匾額, 神棚, 御幣, 階段A, 階段B, 方石台
    # (0,4) 単方向木台 — 神社用朱色台
    tx, ty = tile(0, 4)
    fill_rect(ss, tx, ty, 16, 3, LANTERN_RED_L)
    fill_rect(ss, tx, ty+3, 16, 1, LANTERN_RED)
    dither_fill(ss, tx, ty+4, 16, 4, LANTERN_RED_L, P.T)

    # (1,4) 燭台
    tx, ty = tile(1, 4)
    fill_rect(ss, tx+6, ty+4, 4, 10, DARK_WOOD)
    fill_rect(ss, tx+4, ty+14, 8, 2, P.WOOD_DARK)
    fill_ellipse(ss, tx+6, ty, 4, 5, P.FOXFIRE_BRIGHT)
    px(ss, tx+7, ty+1, P.FOXFIRE_CORE)
    px(ss, tx+8, ty+1, P.FOXFIRE_CORE)

    # (2,4) 匾額
    tx, ty = tile(2, 4)
    fill_rect(ss, tx+1, ty+3, 14, 10, P.WOOD_MID)
    fill_rect(ss, tx+1, ty+3, 14, 1, P.WOOD_LIGHT)
    fill_rect(ss, tx+1, ty+12, 14, 1, P.WOOD_DARK)
    fill_rect(ss, tx+1, ty+3, 1, 10, P.WOOD_DARK)
    fill_rect(ss, tx+14, ty+3, 1, 10, P.WOOD_DARK)
    for cx in [5, 8, 11]:
        fill_rect(ss, tx+cx, ty+5, 1, 6, GOLD_BRIGHT)

    # (3,4) 神棚 (miniature altar shelf)
    tx, ty = tile(3, 4)
    fill_rect(ss, tx, ty+6, 16, 2, P.WOOD_MID)
    fill_rect(ss, tx, ty+6, 16, 1, P.WOOD_LIGHT)
    # 小社
    fill_rect(ss, tx+4, ty+1, 8, 5, P.WOOD_MID)
    fill_rect(ss, tx+3, ty, 10, 2, P.WOOD_DARK)
    # 供物
    fill_rect(ss, tx+1, ty+4, 3, 2, P.PAPER_WHITE)
    fill_rect(ss, tx+12, ty+4, 3, 2, P.PAPER_WHITE)
    # 脚
    fill_rect(ss, tx+2, ty+8, 2, 6, P.WOOD_DARK)
    fill_rect(ss, tx+12, ty+8, 2, 6, P.WOOD_DARK)

    # (4,4) 御幣 (zigzag paper offering)
    tx, ty = tile(4, 4)
    fill_rect(ss, tx+7, ty, 2, 14, P.WOOD_MID)
    for oy in [3, 7]:
        for dx in [-3, -2, -1, 1, 2, 3]:
            dy = abs(dx) - 1
            px(ss, tx+7+dx, ty+oy+dy, P.PAPER_WHITE)
            px(ss, tx+8+dx, ty+oy+dy, P.PAPER_WHITE)
    fill_rect(ss, tx+5, ty+14, 6, 2, P.WOOD_DARK)

    # (5,4) 階段A (石段上り)
    tx, ty = tile(5, 4)
    fill_rect(ss, tx, ty, 16, 16, P.STONE_MID)
    for s in range(4):
        fill_rect(ss, tx, ty+s*4, 16-s*4, 4, P.STONE_LIGHT)
        px(ss, tx, ty+s*4, P.STONE_HIGHLIGHT)

    # (6,4) 階段B (石段下り)
    tx, ty = tile(6, 4)
    fill_rect(ss, tx, ty, 16, 16, P.STONE_MID)
    for s in range(4):
        fill_rect(ss, tx+s*4, ty+s*4, 16-s*4, 4, P.STONE_LIGHT)
        px(ss, tx+s*4, ty+s*4, P.STONE_HIGHLIGHT)

    # (7,4) 方石台 (raised stone platform)
    tx, ty = tile(7, 4)
    fill_rect(ss, tx, ty, 16, 16, P.STONE_MID)
    fill_rect(ss, tx, ty, 16, 3, P.STONE_LIGHT)
    fill_rect(ss, tx, ty, 16, 1, P.STONE_HIGHLIGHT)
    fill_rect(ss, tx, ty+14, 16, 2, P.STONE_DARK)
    for _ in range(6):
        rx, ry = random.randint(0, 15), random.randint(3, 13)
        px(ss, tx+rx, ty+ry, P.STONE_DARK)

    ss = ss.resize((256, 160), Image.NEAREST)
    ss.save(os.path.join(out, "shrine_tileset.png"))
    print(f"  shrine_tileset.png (256x160, 8x5 @32x32)")


# ═══════════════════════════════════════════════════════
# 5. 游戏物件 (2×尺寸)
# ═══════════════════════════════════════════════════════
def gen_items():
    out = os.path.join(ASSETS, "sprites", "objects"); ensure_dir(out)

    def item_img(name, size, draw_fn):
        img = Image.new("RGBA", size, P.T)
        draw_fn(img)
        img.save(os.path.join(out, name))
        print(f"  {name} ({size[0]}x{size[1]})")

    # ── 供物 (32×32 each) ──
    def draw_sugi(img):
        # 杉木枝 - 带叶子的木片
        fill_rect(img, 8, 18, 16, 4, P.ITEM_SUGI)
        fill_rect(img, 9, 19, 14, 2, P.ITEM_SUGI_LIGHT)
        fill_rect(img, 10, 17, 12, 1, P.ITEM_SUGI_DARK)
        # 叶
        for x, y in [(6, 10), (10, 8), (14, 6), (18, 8), (22, 10)]:
            for dy in range(5):
                w = 3 - abs(dy - 2)
                for dx in range(-w, w+1):
                    px(img, x+dx, y+dy, P.GRASS_MID if abs(dx) < w else P.GRASS_DARK)
        # 光泽
        px(img, 12, 7, P.GRASS_TIP)
        px(img, 16, 5, P.GRASS_TIP)
    item_img("item_sugi_wood.png", (32, 32), draw_sugi)

    def draw_fur(img):
        # 白毛 - 蓬松的狐狸毛
        for dy in range(16):
            w = 10 - abs(dy - 8)
            for dx in range(-w, w+1):
                t = abs(dx) / max(w, 1)
                c = P.ITEM_FUR if t < 0.6 else P.ITEM_FUR_SHADOW
                px(img, 16+dx, 8+dy, c)
        # 毛尖细节
        for x in range(8, 24, 2):
            for y in [8, 9]:
                px(img, x, y, P.ITEM_FUR)
        # 微光
        px(img, 14, 12, P.STAR_BRIGHT)
    item_img("item_white_fur.png", (32, 32), draw_fur)

    def draw_mugwort(img):
        # 蓬草 - 草药束
        fill_rect(img, 13, 20, 6, 8, P.ITEM_SUGI)  # 茎
        for cluster in [(10, 6), (16, 4), (22, 7), (13, 10), (19, 9)]:
            cx, cy = cluster
            for dy in range(-3, 4):
                w = 3 - abs(dy)
                for dx in range(-w, w+1):
                    c = P.ITEM_MUGWORT_LIGHT if dy < 0 else P.ITEM_MUGWORT
                    if abs(dx) >= w:
                        c = P.ITEM_MUGWORT_DARK
                    px(img, cx+dx, cy+dy, c)
    item_img("item_mugwort.png", (32, 32), draw_mugwort)

    def draw_bell_fiber(img):
        # 铃绳纤维 - 编织绳
        for seg in range(8):
            y = 4 + seg * 3
            for x in range(10, 22):
                wave_off = int(1.5 * math.sin(x * 0.8 + seg))
                c = P.ITEM_BELL_LIGHT if (x + seg) % 3 == 0 else P.ITEM_BELL
                px(img, x, y + wave_off, c)
                px(img, x, y + wave_off + 1, P.ITEM_BELL_DARK if (x + seg) % 3 == 0 else P.ITEM_BELL)
    item_img("item_bell_fiber.png", (32, 32), draw_bell_fiber)

    def draw_foxstone(img):
        # 狐火石 - 发光琥珀
        for dy in range(-8, 9):
            w = int(math.sqrt(max(0, 64 - dy*dy)))
            for dx in range(-w, w+1):
                dist = math.sqrt(dx*dx + dy*dy) / 8.0
                if dist < 0.4:
                    c = P.ITEM_FOXSTONE_BRIGHT
                elif dist < 0.7:
                    c = P.ITEM_FOXSTONE
                else:
                    c = P.ITEM_FOXSTONE_DARK
                px(img, 16+dx, 16+dy, c)
        # 内部光纹
        for a in range(0, 360, 45):
            r = 4
            ex = int(16 + r * math.cos(math.radians(a)))
            ey = int(16 + r * math.sin(math.radians(a)))
            px(img, ex, ey, P.FOXFIRE_CORE)
        # 外发光
        for dy in range(-12, 13):
            for dx in range(-12, 13):
                d = math.sqrt(dx*dx + dy*dy)
                if 8 < d < 12:
                    a = max(0, int(60 * (1 - (d - 8) / 4)))
                    px(img, 16+dx, 16+dy, (255, 180, 60, a))
    item_img("item_fox_stone.png", (32, 32), draw_foxstone)

    def draw_water_grass(img):
        # 清水草 - 水中草叶
        for blade in range(5):
            bx = 10 + blade * 3
            for y in range(28, 6, -1):
                sway = int(2 * math.sin((28 - y) * 0.3 + blade))
                c = P.ITEM_WATER_LIGHT if y < 14 else P.ITEM_WATER
                if y > 22:
                    c = P.ITEM_WATER_DARK
                px(img, bx + sway, y, c)
                px(img, bx + sway + 1, y, blend(c, P.ITEM_WATER_DARK, 0.3))
        # 水滴
        for pos in [(8, 12), (22, 10)]:
            fill_circle(img, pos[0], pos[1], 2, (150, 210, 225, 180))
            px(img, pos[0]-1, pos[1]-1, (200, 235, 245, 200))
    item_img("item_water_grass.png", (32, 32), draw_water_grass)

    def draw_oil(img):
        # 灯芯油 - 小陶瓶
        # 瓶身
        for dy in range(0, 16):
            w = 6 + int(3 * math.sin(dy * 0.25))
            for dx in range(-w, w+1):
                t = abs(dx) / max(w, 1)
                c = P.ITEM_OIL_LIGHT if t < 0.3 else (P.ITEM_OIL if t < 0.7 else P.ITEM_OIL_DARK)
                px(img, 16+dx, 10+dy, c)
        # 瓶口
        for dx in range(-3, 4):
            for dy in range(3):
                px(img, 16+dx, 8+dy, P.ITEM_OIL_DARK)
        px(img, 16, 8, P.ITEM_OIL_LIGHT)
        # 油光
        for dy in range(4, 12):
            px(img, 12, 10+dy, P.ITEM_OIL_LIGHT)
    item_img("item_lamp_oil.png", (32, 32), draw_oil)

    # ── 祭坛 (64×48) ──
    def draw_altar(img):
        # 石质祭坛 - 分层结构
        # 基座
        fill_rect(img, 8, 34, 48, 14, P.STONE_MID)
        fill_rect(img, 8, 34, 48, 2, P.STONE_HIGHLIGHT)
        fill_rect(img, 8, 46, 48, 2, P.STONE_DARK)
        # 中层
        fill_rect(img, 12, 22, 40, 14, P.STONE_LIGHT)
        fill_rect(img, 12, 22, 40, 2, P.STONE_HIGHLIGHT)
        dither_fill(img, 14, 26, 36, 8, P.STONE_LIGHT, P.STONE_MID)
        # 上层 (奉纳台)
        fill_rect(img, 16, 14, 32, 10, P.STONE_LIGHT)
        fill_rect(img, 16, 14, 32, 2, P.STONE_HIGHLIGHT)
        # 注连绳装饰
        for x in range(14, 50):
            y_off = int(1.5 * math.sin((x-14) * 0.2))
            px(img, x, 20+y_off, P.ROPE_STRAW)
            px(img, x, 21+y_off, P.ROPE_DARK)
        # 纸垂
        for sx in [18, 28, 38, 48]:
            for dy in range(5):
                px(img, sx, 22+dy, P.PAPER_WHITE)
                px(img, sx+1, 22+dy, P.PAPER_SHADOW)
        # 苔藓
        for x in range(10, 54, 3):
            for dy in range(2):
                px(img, x, 34+dy, P.MOSS)
    item_img("altar.png", (64, 48), draw_altar)

    # ── 石碑 (32×48) ──
    def draw_tablet(img):
        # 身体
        fill_rect(img, 6, 8, 20, 34, P.STONE_MID)
        fill_rect(img, 6, 8, 20, 2, P.STONE_HIGHLIGHT)
        fill_rect(img, 7, 9, 1, 32, P.STONE_LIGHT)  # 左光
        fill_rect(img, 24, 9, 1, 32, P.STONE_DARK)  # 右暗
        # 圆顶
        fill_ellipse(img, 6, 2, 20, 14, P.STONE_MID)
        fill_ellipse(img, 7, 3, 18, 12, P.STONE_LIGHT)
        # 刻字
        for y in range(16, 36, 3):
            for x in range(10, 22, 2):
                if random.random() > 0.4:
                    px(img, x, y, P.STONE_DARK)
        # 苔藓基底
        for x in range(6, 26):
            for dy in range(random.randint(1, 3)):
                px(img, x, 42 - dy, P.MOSS)
        # 基座
        fill_rect(img, 4, 42, 24, 6, P.STONE_DARK)
    item_img("stone_tablet.png", (32, 48), draw_tablet)

    # ── 铃绳 (32×96) ──
    def draw_bell(img):
        # 铃铛
        fill_ellipse(img, 6, 2, 20, 16, P.OBI_GOLD)
        fill_ellipse(img, 8, 4, 16, 12, P.OBI_DARK)
        # 铃舌
        fill_circle(img, 16, 14, 3, P.OBI_GOLD)
        # 绳
        for y in range(18, 90):
            w = 2 + (y % 8 < 4)
            for dx in range(-w, w+1):
                c = P.ROPE_STRAW if (y + dx) % 3 != 0 else P.ROPE_DARK
                px(img, 16+dx, y, c)
        # 编织纹
        for y in range(20, 88, 4):
            px(img, 14, y, P.ROPE_DARK)
            px(img, 18, y+2, P.ROPE_DARK)
        # 流苏
        for dx in range(-4, 5):
            for dy in range(8):
                if (dx + dy) % 2 == 0:
                    px(img, 16+dx, 90+dy, P.ROPE_STRAW)
    item_img("bell_rope.png", (32, 96), draw_bell)

    # ── 鸟居 (64×80) ──
    def draw_torii(img):
        # 笠木 (最上横梁，微弯曲)
        for x in range(4, 60):
            y_curve = int(1.5 * math.sin((x - 32) * 0.05))
            for dy in range(5):
                c = P.TORII_LIGHT if dy < 2 else P.TORII_RED
                if dy >= 4:
                    c = P.TORII_DARK
                px(img, x, 4 + y_curve + dy, c)
        # 島木 (第二横梁)
        fill_rect(img, 8, 12, 48, 4, P.TORII_RED)
        fill_rect(img, 8, 12, 48, 1, P.TORII_LIGHT)
        fill_rect(img, 8, 15, 48, 1, P.TORII_DARK)
        # 額束 (中央牌匾)
        fill_rect(img, 24, 16, 16, 10, P.WOOD_MID)
        fill_rect(img, 25, 17, 14, 8, P.WOOD_LIGHT)
        # 牌匾文字暗示
        for y in range(19, 24):
            for x in range(27, 37, 2):
                px(img, x, y, P.WOOD_DARK)
        # 柱子
        for side in [14, 44]:
            for y in range(16, 76):
                for dx in range(4):
                    c = P.TORII_RED if dx < 3 else P.TORII_DARK
                    if dx == 0:
                        c = P.TORII_LIGHT
                    px(img, side+dx, y, c)
            # 柱脚石
            fill_rect(img, side-2, 72, 8, 8, P.STONE_MID)
            fill_rect(img, side-2, 72, 8, 1, P.STONE_HIGHLIGHT)
        # 贯 (中间横梁)
        fill_rect(img, 14, 28, 36, 3, P.TORII_RED)
        fill_rect(img, 14, 28, 36, 1, P.TORII_LIGHT)
    item_img("torii.png", (64, 80), draw_torii)

    # ── 石灯笼 (32×64) ──
    def draw_lantern(img):
        # 宝珠 (顶)
        fill_circle(img, 16, 6, 3, P.STONE_LIGHT)
        px(img, 15, 5, P.STONE_HIGHLIGHT)
        # 笠 (伞盖)
        for dy in range(4):
            w = 8 + dy * 2
            fill_rect(img, 16-w//2, 10+dy, w, 1, P.STONE_MID if dy < 3 else P.STONE_DARK)
        # 火袋 (灯身)
        fill_rect(img, 10, 14, 12, 14, P.STONE_LIGHT)
        # 窗口发光
        fill_rect(img, 12, 16, 8, 10, (255, 200, 100, 180))
        fill_rect(img, 13, 17, 6, 8, (255, 220, 140, 200))
        # 十字窗框
        fill_rect(img, 15, 16, 2, 10, P.STONE_MID)
        fill_rect(img, 12, 20, 8, 2, P.STONE_MID)
        # 中台
        fill_rect(img, 12, 28, 8, 3, P.STONE_MID)
        # 竿 (柱)
        fill_rect(img, 14, 31, 4, 22, P.STONE_MID)
        fill_rect(img, 15, 31, 1, 22, P.STONE_LIGHT)
        # 基礎 (台座)
        fill_rect(img, 8, 53, 16, 4, P.STONE_MID)
        fill_rect(img, 6, 57, 20, 4, P.STONE_DARK)
        fill_rect(img, 6, 57, 20, 1, P.STONE_LIGHT)
        # 苔藓
        for x in range(8, 24, 2):
            px(img, x, 53, P.MOSS)
    item_img("stone_lantern.png", (32, 64), draw_lantern)


# ═══════════════════════════════════════════════════════
# 6. 背景 (更精细)
# ═══════════════════════════════════════════════════════
def gen_backgrounds():
    out = os.path.join(ASSETS, "backgrounds"); ensure_dir(out)
    random.seed(123)

    # ── 夜空 ──
    sky = Image.new("RGBA", (480, 270), P.SKY_TOP)
    # 分段色带 + 抖动过渡 (像素风格)
    _sky_bands = [P.SKY_TOP, P.SKY_HIGH, P.SKY_MID,
                  blend(P.SKY_MID, P.SKY_LOW, 0.5), P.SKY_LOW,
                  blend(P.SKY_LOW, (35, 22, 75, 255), 0.5)]
    _band_h = 270 // len(_sky_bands)
    for _i, _col in enumerate(_sky_bands):
        fill_rect(sky, 0, _i * _band_h, 480, _band_h + 1, _col)
    for _i in range(len(_sky_bands) - 1):
        _ym = (_i + 1) * _band_h
        dither_fill(sky, 0, _ym - 2, 480, 4, _sky_bands[_i], _sky_bands[_i + 1], "checker")
    # 星星 (多层)
    for _ in range(200):
        sx, sy = random.randint(0, 479), random.randint(0, 180)
        brightness = random.random()
        if brightness > 0.9:
            c = P.STAR_BRIGHT
            px(sky, sx, sy, c)
            # 十字星芒
            for d2 in range(1, 3):
                a = max(0, 255 - d2 * 80)
                px(sky, sx+d2, sy, (*c[:3], a))
                px(sky, sx-d2, sy, (*c[:3], a))
                px(sky, sx, sy+d2, (*c[:3], a))
                px(sky, sx, sy-d2, (*c[:3], a))
        elif brightness > 0.6:
            px(sky, sx, sy, P.STAR_WARM)
        else:
            px(sky, sx, sy, P.STAR_DIM)
    # 月亮 (大且精细)
    mx, my = 380, 55
    for dy in range(-18, 19):
        for dx in range(-18, 19):
            dist = math.sqrt(dx*dx + dy*dy)
            if dist <= 17:
                t = dist / 17.0
                if t < 0.5:
                    c = P.MOON_BRIGHT
                elif t < 0.8:
                    c = P.MOON_MID
                else:
                    c = P.MOON_DARK
                # 月面纹理
                if (dx + 5) ** 2 + (dy - 3) ** 2 < 25:
                    c = P.MOON_MID
                if (dx - 6) ** 2 + (dy + 4) ** 2 < 16:
                    c = blend(c, P.MOON_DARK, 0.3)
                px(sky, mx+dx, my+dy, c)
    # 月晕
    for dy in range(-25, 26):
        for dx in range(-25, 26):
            dist = math.sqrt(dx*dx + dy*dy)
            if 17 < dist < 25:
                a = max(0, int(40 * (1 - (dist - 17) / 8)))
                px(sky, mx+dx, my+dy, (200, 195, 220, a))
    sky.save(os.path.join(out, "sky.png"))
    print("  sky.png (480x270)")

    # ── 远山 (像素风 - 阶梯轮廓) ──
    mtn = Image.new("RGBA", (600, 270), P.T)
    for layer in range(3):
        color = [P.MOUNTAIN_FAR, P.MOUNTAIN_MID, P.MOUNTAIN_NEAR][layer]
        shadow = hue_shift_shadow(color)
        base_y = 120 + layer * 25
        _STEP = 4  # 每4像素一个阶梯
        for xb in range(0, 600, _STEP):
            xm = xb + _STEP // 2
            h = int(50 * math.sin(xm * 0.008 + layer * 2) +
                    30 * math.sin(xm * 0.015 + layer) +
                    15 * math.sin(xm * 0.04 + layer * 3))
            top = base_y - abs(h)
            # 实心填充 (无逐像素渐变)
            fill_rect(mtn, xb, top, _STEP, 270 - top, color)
            # 山脊高光 (1px)
            fill_rect(mtn, xb, top, _STEP, 1,
                      blend(color, (200, 200, 220, 255), 0.15))
            # 底部阴影抖动
            sh = min(30, (270 - top) // 3)
            if sh > 2:
                dither_fill(mtn, xb, 270 - sh, _STEP, sh, color, shadow, "checker")
    # 山脊雾 (抖动横带)
    dither_fill(mtn, 0, 143, 600, 4, P.FOG, P.T, "horizontal")
    mtn.save(os.path.join(out, "far_mountains.png"))
    print("  far_mountains.png (600x270)")

    # ── 近景树林 (像素风 - 方块树冠) ──
    trees = Image.new("RGBA", (800, 270), P.T)
    for txi in range(0, 800, 20):
        tree_h = random.randint(80, 160)
        tree_w = random.randint(16, 32)
        ty_base = 270
        # 树干 (矩形)
        trunk_w = max(2, tree_w // 5)
        trunk_h = tree_h // 3
        trunk_x = txi + tree_w // 2 - trunk_w // 2
        fill_rect(trees, trunk_x, ty_base - trunk_h, trunk_w, trunk_h, P.WOOD_DARK)
        # 树冠 (逐层缩窄的矩形)
        canopy_y = ty_base - tree_h
        _layers = 4
        for li in range(_layers):
            lw = tree_w - li * (tree_w // (_layers + 1))
            lh = (tree_h - trunk_h) // _layers
            lx = txi + (tree_w - lw) // 2
            ly = canopy_y + li * lh
            _c = [P.TREE_LIGHT, P.TREE_MID, P.TREE_MID, P.TREE_DARK][li]
            fill_rect(trees, lx, ly, lw, lh, _c)
            # 顶部高光
            fill_rect(trees, lx, ly, lw, 1, P.TREE_LIGHT)
    trees.save(os.path.join(out, "near_trees.png"))
    print("  near_trees.png (800x270)")

    # ── 雾气 (抖动横带) ──
    fog = Image.new("RGBA", (480, 270), P.T)
    for band_y in [155, 185, 215]:
        for xb in range(0, 480, 8):
            wave_off = int(3 * math.sin(xb * 0.05 + band_y * 0.1))
            dither_fill(fog, xb, band_y + wave_off - 4, 8, 8, P.FOG, P.T, "checker")
            dither_fill(fog, xb, band_y + wave_off - 2, 8, 4, P.FOG_THICK, P.FOG, "checker")
    fog.save(os.path.join(out, "fog.png"))
    print("  fog.png (480x270)")

    # ── 神社内部 ──
    shrine = Image.new("RGBA", (480, 270), (20, 15, 30, 255))
    # 木地板 (色带)
    _fc = [(85, 55, 35, 255), (75, 48, 30, 255), (90, 58, 38, 255), (70, 45, 28, 255)]
    for y in range(180, 270):
        fill_rect(shrine, 0, y, 480, 1, _fc[(y // 4) % len(_fc)])
    for y in range(180, 270, 8):
        fill_rect(shrine, 0, y, 480, 1, (40, 28, 18, 255))
    # 奥の壁
    fill_rect(shrine, 0, 40, 480, 140, (35, 28, 42, 255))
    # 障子 (滑动门)
    for sx in [60, 200, 340]:
        fill_rect(shrine, sx, 50, 80, 125, P.PAPER_WHITE)
        for gy in range(50, 175, 20):
            fill_rect(shrine, sx, gy, 80, 1, P.WOOD_MID)
        for gx in range(sx, sx+80, 20):
            fill_rect(shrine, gx, 50, 1, 125, P.WOOD_MID)
    # 上部暗色梁
    fill_rect(shrine, 0, 35, 480, 10, P.WOOD_DARK)
    # 灯光 (抖动暖光)
    for ring_r, bri in [(20, 28), (35, 20), (50, 12), (65, 6)]:
        xr = int(ring_r * 1.3)
        for dy in range(-ring_r, ring_r + 1):
            for dx in range(-xr, xr + 1):
                if abs(dx) + abs(dy) < int(ring_r * 1.5) and (dx + dy) % 2 == 0:
                    cur = gpx(shrine, 240 + dx, 140 + dy)
                    if cur[3] > 0:
                        px(shrine, 240 + dx, 140 + dy,
                           (min(255, cur[0] + bri), min(255, cur[1] + int(bri * 0.7)), cur[2], 255))
    shrine.save(os.path.join(out, "shrine_interior.png"))
    print("  shrine_interior.png (480x270)")


# ═══════════════════════════════════════════════════════
# 7. UI 素材
# ═══════════════════════════════════════════════════════
def gen_ui():
    out = os.path.join(ASSETS, "ui"); ensure_dir(out)

    # 对话框 NinePatch (96×64)
    dlg = Image.new("RGBA", (96, 64), P.T)
    fill_rect(dlg, 3, 3, 90, 58, P.UI_BG)
    # 外边框
    for x in range(2, 94):
        px(dlg, x, 0, P.UI_BORDER); px(dlg, x, 63, P.UI_BORDER)
    for y in range(2, 62):
        px(dlg, 0, y, P.UI_BORDER); px(dlg, 95, y, P.UI_BORDER)
    # 内边框 (高光)
    for x in range(3, 93):
        px(dlg, x, 2, P.UI_BORDER_LIGHT); px(dlg, x, 61, P.UI_BORDER_LIGHT)
    for y in range(3, 61):
        px(dlg, 2, y, P.UI_BORDER_LIGHT); px(dlg, 93, y, P.UI_BORDER_LIGHT)
    # 角装饰 (L型)
    for cx, cy, sx, sy in [(1, 1, 1, 1), (94, 1, -1, 1), (1, 62, 1, -1), (94, 62, -1, -1)]:
        for _d in range(4):
            px(dlg, cx + sx * _d, cy, P.UI_HIGHLIGHT)
            px(dlg, cx, cy + sy * _d, P.UI_HIGHLIGHT)
        px(dlg, cx, cy, P.OBI_GOLD)
    # 顶部装饰 (中央菱形)
    for _d in range(3):
        px(dlg, 47 - _d, 1 + _d, P.OBI_GOLD); px(dlg, 48 + _d, 1 + _d, P.OBI_GOLD)
    dlg.save(os.path.join(out, "dialog_box.png"))
    print("  dialog_box.png (96x64)")

    # 御供筒 (32×96)
    tube = Image.new("RGBA", (32, 96), P.T)
    # 筒身 (竹筒质感)
    for y in range(8, 88):
        for x in range(6, 26):
            t = abs(x - 16) / 10.0
            if t < 0.5:
                c = P.GRASS_LIGHT
            elif t < 0.8:
                c = P.GRASS_MID
            else:
                c = P.GRASS_DARK
            if y % 16 < 1:
                c = P.GRASS_DARK  # 竹节
            px(tube, x, y, c)
    # 口缘
    fill_rect(tube, 4, 6, 24, 3, P.GRASS_MID)
    fill_rect(tube, 4, 6, 24, 1, P.GRASS_LIGHT)
    # 底部
    fill_rect(tube, 4, 88, 24, 4, P.GRASS_DARK)
    # 绑绳
    for y in [20, 50, 75]:
        for x in range(4, 28):
            px(tube, x, y, P.ROPE_STRAW)
            px(tube, x, y+1, P.ROPE_DARK)
    tube.save(os.path.join(out, "offering_tube.png"))
    print("  offering_tube.png (32x96)")

    # 交互提示 (32×32)
    hint = Image.new("RGBA", (32, 32), P.T)
    # 圆形背景
    fill_circle(hint, 16, 16, 12, P.UI_BG)
    draw_circle(hint, 16, 16, 12, P.UI_BORDER)
    # "E" 字母
    fill_rect(hint, 11, 10, 10, 2, P.UI_HIGHLIGHT)
    fill_rect(hint, 11, 15, 8, 2, P.UI_HIGHLIGHT)
    fill_rect(hint, 11, 20, 10, 2, P.UI_HIGHLIGHT)
    fill_rect(hint, 11, 10, 2, 12, P.UI_HIGHLIGHT)
    hint.save(os.path.join(out, "interact_hint.png"))
    print("  interact_hint.png (32x32)")

    # 选择按钮 (96×32)
    btn = Image.new("RGBA", (96, 32), P.T)
    fill_rect(btn, 2, 2, 92, 28, P.UI_BG)
    for x in range(2, 94):
        px(btn, x, 0, P.UI_BORDER); px(btn, x, 31, P.UI_BORDER)
    for y in range(2, 30):
        px(btn, 0, y, P.UI_BORDER); px(btn, 95, y, P.UI_BORDER)
    # 双层高光边
    for x in range(3, 93):
        px(btn, x, 1, P.UI_BORDER_LIGHT); px(btn, x, 30, P.UI_BORDER_LIGHT)
    for y in range(2, 30):
        px(btn, 1, y, P.UI_BORDER_LIGHT); px(btn, 94, y, P.UI_BORDER_LIGHT)
    # 角点装饰
    for cx, cy in [(1, 1), (94, 1), (1, 30), (94, 30)]:
        px(btn, cx, cy, P.OBI_GOLD)
    btn.save(os.path.join(out, "choice_button.png"))
    print("  choice_button.png (96x32)")


# ═══════════════════════════════════════════════════════
# 8. 特效纹理
# ═══════════════════════════════════════════════════════
def gen_effects():
    out = os.path.join(ASSETS, "sprites", "effects"); ensure_dir(out)

    # 狐火帧 (128×32, 4帧)
    FW, FH = 32, 32
    ff = Image.new("RGBA", (FW*4, FH), P.T)
    for i in range(4):
        cx, cy = i*FW + 16, 20
        phase = i * 0.7
        for r in range(14, 0, -1):
            t = r / 14.0
            if t > 0.7:
                c = P.FOXFIRE_FAINT
            elif t > 0.4:
                c = P.FOXFIRE_OUTER
            elif t > 0.2:
                c = P.FOXFIRE_MID
            else:
                c = P.FOXFIRE_CORE
            for a in range(360):
                angle = math.radians(a)
                rx = r * (1.0 + 0.3 * math.sin(angle * 3 + phase))
                ry = r * (1.2 + 0.2 * math.cos(angle * 2 + phase))
                px(ff, int(cx + rx * math.cos(angle)), int(cy - ry * math.sin(angle)), c)
    ff.save(os.path.join(out, "fox_fire.png"))
    print(f"  fox_fire.png ({FW*4}x{FH}, 4帧)")

    # 光照纹理 (128×128 径向渐变)
    lt = Image.new("RGBA", (128, 128), P.T)
    for y in range(128):
        for x in range(128):
            dx, dy = x - 64, y - 64
            dist = math.sqrt(dx*dx + dy*dy) / 64.0
            if dist < 1.0:
                a = int(120 * (1 - dist) ** 2)
                lt.putpixel((x, y), (255, 240, 200, a))
    lt.save(os.path.join(out, "light_texture.png"))
    print("  light_texture.png (128x128)")

    # 粒子 (16×16)
    pt = Image.new("RGBA", (16, 16), P.T)
    for y in range(16):
        for x in range(16):
            dist = math.sqrt((x-8)**2 + (y-8)**2) / 8.0
            if dist < 1.0:
                a = int(200 * (1 - dist) ** 1.5)
                pt.putpixel((x, y), (255, 255, 255, a))
    pt.save(os.path.join(out, "particle.png"))
    print("  particle.png (16x16)")

    # 暖光纹理 (128×128)
    wl = Image.new("RGBA", (128, 128), P.T)
    for y in range(128):
        for x in range(128):
            dist = math.sqrt((x-64)**2 + (y-64)**2) / 64.0
            if dist < 1.0:
                t = 1 - dist
                a = int(160 * t ** 1.5)
                r = int(255 * min(1, t + 0.2))
                g = int(200 * t)
                b = int(100 * t)
                wl.putpixel((x, y), (r, g, b, a))
    wl.save(os.path.join(out, "warm_light.png"))
    print("  warm_light.png (128x128)")

    # 冷光纹理 (128×128)
    cl = Image.new("RGBA", (128, 128), P.T)
    for y in range(128):
        for x in range(128):
            dist = math.sqrt((x-64)**2 + (y-64)**2) / 64.0
            if dist < 1.0:
                t = 1 - dist
                a = int(100 * t ** 2)
                cl.putpixel((x, y), (150, 180, 255, a))
    cl.save(os.path.join(out, "cold_light.png"))
    print("  cold_light.png (128x128)")


# ═══════════════════════════════════════════════════════
# 9. 程序化音乐 (日本五声音阶)
# ═══════════════════════════════════════════════════════
def gen_music():
    """使用 wave + 正弦合成生成环境音乐"""
    bgm_dir = os.path.join(ASSETS, "audio", "bgm"); ensure_dir(bgm_dir)
    sfx_dir = os.path.join(ASSETS, "audio", "sfx"); ensure_dir(sfx_dir)
    amb_dir = os.path.join(ASSETS, "audio", "ambience"); ensure_dir(amb_dir)

    SR = 22050  # 采样率
    
    def sine_wave(freq, duration, volume=0.3, fade_in=0.05, fade_out=0.1):
        """生成正弦波样本"""
        n = int(SR * duration)
        samples = []
        for i in range(n):
            t = i / SR
            env = 1.0
            if t < fade_in:
                env = t / fade_in
            elif t > duration - fade_out:
                env = (duration - t) / fade_out
            val = volume * env * math.sin(2 * math.pi * freq * t)
            # 加点泛音让音色更丰满
            val += volume * 0.15 * env * math.sin(4 * math.pi * freq * t)
            val += volume * 0.05 * env * math.sin(6 * math.pi * freq * t)
            samples.append(val)
        return samples

    def pad_tone(freq, duration, volume=0.12):
        """柔和的Pad音色"""
        n = int(SR * duration)
        samples = []
        for i in range(n):
            t = i / SR
            env = 1.0
            if t < 0.5:
                env = t / 0.5
            elif t > duration - 0.5:
                env = (duration - t) / 0.5
            val = 0.0
            for h in range(1, 6):
                amp = volume / (h * 1.5)
                val += amp * env * math.sin(2 * math.pi * freq * h * t + math.sin(t * 0.5) * 0.3)
            samples.append(val)
        return samples

    def noise_burst(duration, volume=0.02):
        """风/雨环境噪声"""
        n = int(SR * duration)
        samples = []
        prev = 0
        for i in range(n):
            t = i / SR
            env = 1.0
            if t < 0.3: env = t / 0.3
            elif t > duration - 0.3: env = (duration - t) / 0.3
            raw = random.uniform(-1, 1)
            # 低通滤波
            prev = prev * 0.95 + raw * 0.05
            samples.append(prev * volume * env)
        return samples

    def write_wav(filename, samples):
        """写入 16-bit PCM WAV"""
        with wave.open(filename, 'w') as wf:
            wf.setnchannels(1)
            wf.setsampwidth(2)
            wf.setframerate(SR)
            data = array.array('h')
            for s in samples:
                val = max(-32767, min(32767, int(s * 32767)))
                data.append(val)
            wf.writeframes(data.tobytes())

    def mix(tracks, total_length):
        """混合多个音轨"""
        n = int(SR * total_length)
        result = [0.0] * n
        for offset, samples in tracks:
            start = int(SR * offset)
            for i, s in enumerate(samples):
                idx = start + i
                if 0 <= idx < n:
                    result[idx] += s
        # 软限幅
        peak = max(abs(s) for s in result) if result else 1
        if peak > 0.9:
            scale = 0.85 / peak
            result = [s * scale for s in result]
        return result

    # ── 日本都節音阶 (miyako-bushi) ──
    # C4, Db4, F4, G4, Ab4, C5, Db5, F5, G5
    NOTE_FREQS = {
        'C3': 130.81, 'Db3': 138.59, 'F3': 174.61, 'G3': 196.0, 'Ab3': 207.65,
        'C4': 261.63, 'Db4': 277.18, 'F4': 349.23, 'G4': 392.0, 'Ab4': 415.30,
        'C5': 523.25, 'Db5': 554.37, 'F5': 698.46, 'G5': 784.0,
    }
    
    print("\n生成音乐（这需要一些时间）...")

    # ── BGM: 森林夜 (40秒循环) ──
    duration = 40.0
    tracks = []
    
    # Pad 底层 (C3 + G3 drone)
    tracks.append((0, pad_tone(NOTE_FREQS['C3'], duration, 0.10)))
    tracks.append((0, pad_tone(NOTE_FREQS['G3'], duration, 0.06)))
    
    # 旋律 (pentatonic 随机行走)
    random.seed(77)
    melody_notes = ['C4', 'Db4', 'F4', 'G4', 'Ab4', 'C5', 'Ab4', 'G4', 'F4', 'Db4',
                    'C4', 'F4', 'G4', 'C5', 'Ab4', 'F4', 'G4', 'Db4', 'C4', 'C4']
    t = 1.0
    for note in melody_notes:
        note_dur = random.choice([1.2, 1.5, 1.8, 2.0])
        tracks.append((t, sine_wave(NOTE_FREQS[note], note_dur, 0.15, 0.1, 0.3)))
        t += note_dur + random.uniform(0.2, 0.8)
        if t > duration - 3:
            break

    # 风声背景
    tracks.append((0, noise_burst(duration, 0.015)))
    
    bgm = mix(tracks, duration)
    write_wav(os.path.join(bgm_dir, "forest_night.wav"), bgm)
    print("  forest_night.wav (40s)")

    # ── BGM: 神社 (30秒) ──
    duration = 30.0
    tracks = []
    tracks.append((0, pad_tone(NOTE_FREQS['F3'], duration, 0.08)))
    tracks.append((0, pad_tone(NOTE_FREQS['C4'], duration, 0.05)))
    
    shrine_melody = ['F4', 'Ab4', 'G4', 'F4', 'Db4', 'C4', 'Db4', 'F4',
                     'G4', 'Ab4', 'C5', 'Ab4', 'G4', 'F4']
    t = 0.5
    for note in shrine_melody:
        note_dur = random.choice([1.5, 2.0, 2.5])
        tracks.append((t, sine_wave(NOTE_FREQS[note], note_dur, 0.12, 0.15, 0.4)))
        t += note_dur + random.uniform(0.3, 1.0)
        if t > duration - 3:
            break
    
    bgm2 = mix(tracks, duration)
    write_wav(os.path.join(bgm_dir, "shrine_theme.wav"), bgm2)
    print("  shrine_theme.wav (30s)")

    # ── SFX: 物品收集 ──
    tracks = []
    for i, note in enumerate(['C5', 'F5', 'G5']):
        tracks.append((i * 0.1, sine_wave(NOTE_FREQS[note], 0.2, 0.25, 0.01, 0.1)))
    sfx_collect = mix(tracks, 0.5)
    write_wav(os.path.join(sfx_dir, "collect.wav"), sfx_collect)
    print("  collect.wav (0.5s)")

    # ── SFX: 交互 ──
    tracks = [(0, sine_wave(NOTE_FREQS['G4'], 0.15, 0.2, 0.01, 0.08))]
    sfx_interact = mix(tracks, 0.2)
    write_wav(os.path.join(sfx_dir, "interact.wav"), sfx_interact)
    print("  interact.wav (0.2s)")

    # ── SFX: 铃声 ──
    tracks = []
    bell_freq = 880  # A5
    for h in range(1, 8):
        tracks.append((0, sine_wave(bell_freq * h, 2.0, 0.08 / h, 0.01, 0.8)))
    sfx_bell = mix(tracks, 2.5)
    write_wav(os.path.join(sfx_dir, "bell.wav"), sfx_bell)
    print("  bell.wav (2.5s)")

    # ── SFX: 脚步声 ──
    footstep = noise_burst(0.08, 0.15)
    write_wav(os.path.join(sfx_dir, "footstep.wav"), footstep)
    print("  footstep.wav (0.08s)")

    # ── SFX: 跳跃 ──
    tracks = []
    for i in range(20):
        f = 200 + i * 30
        tracks.append((i * 0.005, sine_wave(f, 0.05, 0.1, 0.005, 0.02)))
    sfx_jump = mix(tracks, 0.15)
    write_wav(os.path.join(sfx_dir, "jump.wav"), sfx_jump)
    print("  jump.wav (0.15s)")

    # ── 环境音: 虫鸣夜 ──
    duration = 20.0
    tracks = []
    # 蟋蟀 (高频脉冲)
    random.seed(99)
    for _ in range(15):
        start = random.uniform(0, duration - 2)
        freq = random.uniform(3500, 5000)
        for chirp in range(random.randint(3, 6)):
            tracks.append((start + chirp * 0.15,
                          sine_wave(freq, 0.06, 0.04, 0.005, 0.02)))
    # 柔和背景噪声
    tracks.append((0, noise_burst(duration, 0.008)))
    amb = mix(tracks, duration)
    write_wav(os.path.join(amb_dir, "night_insects.wav"), amb)
    print("  night_insects.wav (20s)")


# ═══════════════════════════════════════════════════════
# 主入口
# ═══════════════════════════════════════════════════════
if __name__ == "__main__":
    print("=" * 50)
    print("《送狐》像素资源 & 音乐生成器 v2")
    print("=" * 50)

    print("\n[1/8] 巫女精灵表 (64×96)...")
    gen_miko()

    print("\n[2/8] 白狐精灵表 (64×48)...")
    gen_fox()

    print("\n[3/8] 老人NPC (64×96)...")
    gen_elder()

    print("\n[4/8] 地形 Tileset...")
    gen_tileset()

    print("\n[5/8] 游戏物件...")
    gen_items()

    print("\n[6/8] 背景图层...")
    gen_backgrounds()

    print("\n[7/8] UI 素材...")
    gen_ui()

    print("\n[8/8] 特效纹理...")
    gen_effects()

    print("\n[BONUS] 程序化音乐与音效...")
    gen_music()

    print("\n" + "=" * 50)
    print("全部资源生成完成！")
    print("=" * 50)