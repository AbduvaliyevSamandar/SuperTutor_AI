"""Generate app icon + foreground PNGs for SuperTutor AI."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

OUT = Path(__file__).parent.parent / "assets" / "icon"
OUT.mkdir(parents=True, exist_ok=True)

GREEN = (88, 204, 2, 255)
DARK_GREEN = (88, 167, 0, 255)
WHITE = (255, 255, 255, 255)
GOLD = (255, 200, 0, 255)


def draw_owl(canvas: Image.Image, *, size: int, offset_y: int = 0) -> None:
    """Draw a stylized owl in the center."""
    d = ImageDraw.Draw(canvas)
    w, h = canvas.size
    cx, cy = w // 2, h // 2 + offset_y

    # Body (rounded square)
    body_w = int(size * 0.62)
    body_h = int(size * 0.7)
    body_box = (cx - body_w // 2, cy - body_h // 2, cx + body_w // 2, cy + body_h // 2)
    d.rounded_rectangle(body_box, radius=int(body_w * 0.35), fill=WHITE)

    # Ears (triangles)
    ear_y = body_box[1]
    ear_w = int(body_w * 0.22)
    d.polygon(
        [(cx - body_w // 2 + 4, ear_y + 6), (cx - body_w // 2 + ear_w, ear_y - ear_w),
         (cx - body_w // 2 + 2 * ear_w, ear_y + 6)],
        fill=WHITE,
    )
    d.polygon(
        [(cx + body_w // 2 - 4, ear_y + 6), (cx + body_w // 2 - ear_w, ear_y - ear_w),
         (cx + body_w // 2 - 2 * ear_w, ear_y + 6)],
        fill=WHITE,
    )

    # Eyes (large white circles + dark pupils)
    eye_r = int(body_w * 0.22)
    eye_y = cy - int(body_h * 0.10)
    left_eye = (cx - int(body_w * 0.22), eye_y)
    right_eye = (cx + int(body_w * 0.22), eye_y)

    for ex, ey in (left_eye, right_eye):
        d.ellipse((ex - eye_r, ey - eye_r, ex + eye_r, ey + eye_r), fill=GREEN)
        pupil = int(eye_r * 0.55)
        d.ellipse((ex - pupil, ey - pupil, ex + pupil, ey + pupil), fill=DARK_GREEN)
        shine = int(pupil * 0.45)
        d.ellipse(
            (ex - pupil + 4, ey - pupil + 4, ex - pupil + 4 + shine, ey - pupil + 4 + shine),
            fill=WHITE,
        )

    # Beak (triangle)
    beak_y = cy + int(body_h * 0.06)
    beak_w = int(body_w * 0.11)
    d.polygon(
        [(cx - beak_w, beak_y),
         (cx + beak_w, beak_y),
         (cx, beak_y + int(beak_w * 1.6))],
        fill=GOLD,
    )

    # Feet (two small ovals at the bottom)
    foot_y = body_box[3] - 4
    foot_w = int(body_w * 0.12)
    foot_h = int(body_w * 0.05)
    d.ellipse((cx - foot_w * 2, foot_y, cx - foot_w * 2 + foot_w * 2, foot_y + foot_h * 2),
              fill=GOLD)
    d.ellipse((cx + foot_w, foot_y, cx + foot_w + foot_w * 2, foot_y + foot_h * 2),
              fill=GOLD)


def make_icon(size: int = 1024) -> None:
    img = Image.new("RGBA", (size, size), GREEN)
    draw_owl(img, size=size)
    img.save(OUT / "icon.png", "PNG")
    print("wrote", OUT / "icon.png")


def make_foreground(size: int = 1024) -> None:
    """Transparent PNG with just the owl (for adaptive icon)."""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw_owl(img, size=int(size * 0.62), offset_y=0)
    img.save(OUT / "icon_fg.png", "PNG")
    print("wrote", OUT / "icon_fg.png")


if __name__ == "__main__":
    make_icon()
    make_foreground()
