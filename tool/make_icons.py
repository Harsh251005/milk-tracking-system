"""Draws the app icon, adaptive icon layers, notification icon and splash.

Run: python tool/make_icons.py   (needs Pillow). Outputs to assets/icon/.
Everything is drawn at 4x and downsampled for smooth edges.
"""
from pathlib import Path

from PIL import Image, ImageDraw

NAVY = (30, 58, 95, 255)
CREAM = (247, 243, 236, 255)
GREEN = (47, 125, 91, 255)
WHITE = (255, 255, 255, 255)
OUT = Path(__file__).resolve().parent.parent / "assets" / "icon"
S = 4  # supersampling


GLASS = (92, 124, 163, 255)  # empty glass above the milk


def bottle_mask(size, cx, cy, h):
    """Classic milk bottle silhouette as an L-mode mask (drawn at size*S)."""
    mask = Image.new("L", (size, size), 0)
    d = ImageDraw.Draw(mask)
    w = h * 0.54
    neck_w = w * 0.50
    top = cy - h / 2
    cap_h = h * 0.10
    # cap, slightly wider than the neck
    d.rounded_rectangle([cx - neck_w * 0.60, top, cx + neck_w * 0.60, top + cap_h],
                        radius=h * 0.035, fill=255)
    # neck
    neck_top = top + cap_h * 0.85
    neck_bottom = top + h * 0.30
    d.rectangle([cx - neck_w / 2, neck_top, cx + neck_w / 2, neck_bottom], fill=255)
    # rounded shoulders: an ellipse spanning the body width
    shoulder_h = h * 0.22
    d.ellipse([cx - w / 2, neck_bottom - shoulder_h * 0.35,
               cx + w / 2, neck_bottom + shoulder_h * 1.3], fill=255)
    # body
    d.rounded_rectangle([cx - w / 2, neck_bottom + shoulder_h * 0.45, cx + w / 2, cy + h / 2],
                        radius=w * 0.18, fill=255)
    return mask, (cx - w / 2, cx + w / 2, neck_bottom + shoulder_h * 0.55)


def milk_layer(size, left, right, level, h, color):
    """Everything below a gentle wave at [level], in [color]."""
    layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    import math
    amp, n = h * 0.025, 60
    pts = [(left + (right - left) * i / n,
            level + amp * math.sin(i / n * 2 * math.pi * 1.5)) for i in range(n + 1)]
    d.polygon(pts + [(right, size), (left, size)], fill=color)
    return layer


def bottle(img, cx, cy, h, glass, milk):
    """Composites a milk bottle onto [img]: glass on top, milk below a wave."""
    size = img.size[0]
    mask, (left, right, level) = bottle_mask(size, cx, cy, h)
    art = Image.new("RGBA", (size, size), glass)
    art.alpha_composite(milk_layer(size, left - 2, right + 2, level, h, milk))
    img.paste(art, (0, 0), mask)


def check_badge(draw, cx, cy, r):
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=GREEN, outline=CREAM,
                 width=int(r * 0.16))
    t = r * 0.16
    draw.line([(cx - r * 0.42, cy + r * 0.02), (cx - r * 0.1, cy + r * 0.34),
               (cx + r * 0.45, cy - r * 0.32)], fill=WHITE, width=int(t),
              joint="curve")


def canvas(size, bg=(0, 0, 0, 0)):
    img = Image.new("RGBA", (size * S, size * S), bg)
    return img, ImageDraw.Draw(img)


def save(img, size, name):
    img.resize((size, size), Image.LANCZOS).save(OUT / name)


def foreground(size=1024, scale=1.0):
    """Bottle + badge on transparent, kept inside the adaptive-icon safe zone."""
    img, d = canvas(size)
    c = size * S / 2
    bottle(img, c - size * S * 0.03 * scale, c, size * S * 0.50 * scale, GLASS, CREAM)
    check_badge(ImageDraw.Draw(img), c + size * S * 0.15 * scale,
                c + size * S * 0.16 * scale, size * S * 0.095 * scale)
    return img


def main():
    OUT.mkdir(parents=True, exist_ok=True)

    # Full legacy icon: navy rounded square + artwork.
    img, d = canvas(1024)
    d.rounded_rectangle([0, 0, 1024 * S, 1024 * S], radius=230 * S, fill=NAVY)
    img.alpha_composite(foreground(1024, scale=1.35))
    save(img, 1024, "icon.png")

    # Adaptive icon foreground. flutter_launcher_icons already insets it by
    # 16% into Android's safe zone, so the artwork here fills the canvas.
    save(foreground(1024, scale=1.45), 1024, "foreground.png")

    # Monochrome layer for Android 13 themed icons, and the notification icon.
    # Glass part semi-transparent so the milk still reads in one colour.
    for name, size, h in [("monochrome.png", 1024, 0.72),
                          ("notification.png", 96, 0.86)]:
        img, d = canvas(size)
        bottle(img, size * S / 2, size * S / 2, size * S * h,
               (255, 255, 255, 110), WHITE)
        save(img, size, name)

    # Splash (pre-Android 12): the full icon, smaller.
    save(Image.open(OUT / "icon.png"), 288, "splash.png")


if __name__ == "__main__":
    main()
