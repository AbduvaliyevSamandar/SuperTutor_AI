"""Generate UNIQUE SuperTutor brand icon — gradient + stylized 'S' + sparkle."""
import math
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter

OUT = Path(__file__).parent.parent / "assets" / "icon"
OUT.mkdir(parents=True, exist_ok=True)

# Purple→Pink brand gradient — distinct from Duolingo's pure green
TOP = (107, 91, 229)       # #6B5BE5 indigo
BOTTOM = (236, 72, 153)    # #EC4899 pink
ACCENT = (255, 200, 0)     # gold sparkle


def _gradient_bg(size: int) -> Image.Image:
    img = Image.new("RGB", (size, size), TOP)
    px = img.load()
    for y in range(size):
        t = y / max(1, size - 1)
        r = int(TOP[0] * (1 - t) + BOTTOM[0] * t)
        g = int(TOP[1] * (1 - t) + BOTTOM[1] * t)
        b = int(TOP[2] * (1 - t) + BOTTOM[2] * t)
        for x in range(size):
            px[x, y] = (r, g, b)
    return img.convert("RGBA")


def _rounded_alpha(size: int, radius: int) -> Image.Image:
    mask = Image.new("L", (size, size), 0)
    d = ImageDraw.Draw(mask)
    d.rounded_rectangle((0, 0, size, size), radius=radius, fill=255)
    return mask


def _draw_st_glyph(canvas: Image.Image, *, size: int, center_y_offset: int = 0) -> None:
    """Draw a stylized 'S' with a graduation-cap tassel above and a sparkle."""
    d = ImageDraw.Draw(canvas, "RGBA")
    w, h = canvas.size
    cx, cy = w // 2, h // 2 + center_y_offset

    white = (255, 255, 255, 255)
    soft_white = (255, 255, 255, 220)

    # Graduation cap (mortarboard) on top
    cap_w = int(size * 0.78)
    cap_h = int(size * 0.16)
    cap_y = cy - int(size * 0.46)
    d.polygon([
        (cx - cap_w // 2, cap_y + cap_h // 2),
        (cx, cap_y - cap_h // 2),
        (cx + cap_w // 2, cap_y + cap_h // 2),
        (cx, cap_y + cap_h),
    ], fill=white)
    # Tassel
    tassel_x = cx + cap_w // 2 - 6
    d.line([(tassel_x, cap_y + cap_h // 2), (tassel_x + 14, cap_y + cap_h + 18)],
           fill=ACCENT, width=4)
    d.ellipse((tassel_x + 8, cap_y + cap_h + 14,
               tassel_x + 22, cap_y + cap_h + 28), fill=ACCENT)

    # Stylized "S" — two arcs of a thick rounded ribbon
    s_top = cy - int(size * 0.18)
    s_bot = cy + int(size * 0.35)
    s_left = cx - int(size * 0.28)
    s_right = cx + int(size * 0.28)
    thickness = int(size * 0.13)

    # Upper curve
    d.arc((s_left, s_top, s_right, cy + int(size * 0.05)),
          start=180, end=360, fill=white, width=thickness)
    # Lower curve
    d.arc((s_left, cy - int(size * 0.04), s_right, s_bot),
          start=0, end=180, fill=white, width=thickness)

    # Sparkles around the S
    spark_pts = [
        (cx + int(size * 0.30), cy - int(size * 0.05)),
        (cx - int(size * 0.34), cy + int(size * 0.20)),
        (cx + int(size * 0.34), cy + int(size * 0.28)),
    ]
    for sx, sy in spark_pts:
        sz = int(size * 0.025)
        d.polygon([
            (sx, sy - sz * 2),
            (sx + sz, sy),
            (sx, sy + sz * 2),
            (sx - sz, sy),
        ], fill=soft_white)


def make_icon(size: int = 1024) -> None:
    bg = _gradient_bg(size)
    bg.putalpha(_rounded_alpha(size, int(size * 0.22)))
    glyph = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    _draw_st_glyph(glyph, size=size, center_y_offset=int(size * 0.02))
    bg.alpha_composite(glyph)
    bg.save(OUT / "icon.png", "PNG")
    print("wrote", OUT / "icon.png")


def make_foreground(size: int = 1024) -> None:
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    _draw_st_glyph(img, size=int(size * 0.70), center_y_offset=0)
    img.save(OUT / "icon_fg.png", "PNG")
    print("wrote", OUT / "icon_fg.png")


if __name__ == "__main__":
    make_icon()
    make_foreground()
