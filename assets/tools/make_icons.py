"""MathPull launcher icon and splash logo (drawn with code, no stock art).

Run from the project root:   python tools/make_icons.py
Needs: Python 3, numpy and Pillow (pip install numpy pillow).
It writes assets/icon/icon.png, icon_background.png, icon_foreground.png and
splash_logo.png.
"""
import math
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

N = 1024
S = 3  # supersampling for smooth edges
W = N * S
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "icon")
os.makedirs(OUT, exist_ok=True)

BLUE = (37, 99, 235)
BLUE_LIGHT = (96, 165, 250)
RED = (220, 38, 38)
RED_LIGHT = (248, 113, 113)
GOLD = (245, 179, 1)
GOLD_DARK = (185, 134, 0)
ROPE = (198, 154, 90)
ROPE_DARK = (122, 91, 50)
ROPE_LIGHT = (232, 207, 157)
NAVY = (27, 36, 51)


def P(v):
    return int(round(v * S))


def gradient(c1, c2, vertical=True, size=(W, W)):
    w, h = size
    t = np.linspace(0, 1, h if vertical else w)
    arr = np.zeros((h, w, 3), dtype=np.float64)
    for i in range(3):
        line = c1[i] + (c2[i] - c1[i]) * t
        arr[:, :, i] = line[:, None] if vertical else line[None, :]
    return Image.fromarray(arr.astype(np.uint8), "RGB").convert("RGBA")


def split_background():
    left = gradient(BLUE_LIGHT, BLUE)
    right = gradient(RED_LIGHT, RED)
    img = left.copy()
    img.paste(right.crop((W // 2, 0, W, W)), (W // 2, 0))
    return img


def bar(draw, cx, cy, length, thick, fill):
    draw.rounded_rectangle(
        (cx - length / 2, cy - thick / 2, cx + length / 2, cy + thick / 2),
        radius=thick / 2,
        fill=fill,
    )


def symbol_mask(kind, size):
    """A white symbol shape (L mask), size x size in supersampled pixels."""
    big = int(size * 1.5)
    mask = Image.new("L", (big, big), 0)
    d = ImageDraw.Draw(mask)
    t = size * 0.25
    c = big / 2
    if kind == "plus":
        bar(d, c, c, size * 0.9, t, 255)
        d.rounded_rectangle((c - t / 2, c - size * 0.45, c + t / 2, c + size * 0.45), radius=t / 2, fill=255)
    elif kind == "times":
        bar(d, c, c, size * 1.02, t, 255)
        d.rounded_rectangle((c - t / 2, c - size * 0.51, c + t / 2, c + size * 0.51), radius=t / 2, fill=255)
        mask = mask.rotate(45, resample=Image.BICUBIC)
    return mask


def paste_symbol(img, kind, cx, cy, size, color=(255, 255, 255), shadow=True):
    s = P(size)
    mask = symbol_mask(kind, s)
    half = mask.width // 2
    x, y = P(cx) - half, P(cy) - half
    if shadow:
        sh = Image.new("RGBA", img.size, (0, 0, 0, 0))
        blurred = mask.filter(ImageFilter.GaussianBlur(P(6)))
        sh.paste((0, 0, 0, 80), (x + P(0), y + P(12)), blurred)
        img.alpha_composite(sh)
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    layer.paste(color + (255,), (x, y), mask)
    img.alpha_composite(layer)


def draw_rope(img, y, x0, x1, thick, split_colors=None):
    th = P(thick)
    yy = P(y)
    a, b = P(x0), P(x1)
    # soft shadow
    sh = Image.new("RGBA", img.size, (0, 0, 0, 0))
    ImageDraw.Draw(sh).line((a, yy + P(10), b, yy + P(10)), fill=(0, 0, 0, 70), width=th + P(8))
    img.alpha_composite(sh.filter(ImageFilter.GaussianBlur(P(8))))
    d = ImageDraw.Draw(img)
    mid = (a + b) // 2
    if split_colors:
        (ld, lm), (rd, rm) = split_colors
        d.line((a, yy, mid, yy), fill=ld, width=th + P(8))
        d.line((mid, yy, b, yy), fill=rd, width=th + P(8))
        d.line((a, yy, mid, yy), fill=lm, width=th)
        d.line((mid, yy, b, yy), fill=rm, width=th)
    else:
        d.line((a, yy, b, yy), fill=ROPE_DARK, width=th + P(8))
        d.line((a, yy, b, yy), fill=ROPE, width=th)
    # highlight and twisted-strand marks on their own layer, then blended
    marks = Image.new("RGBA", img.size, (0, 0, 0, 0))
    md = ImageDraw.Draw(marks)
    md.line((a, yy - int(th * 0.22), b, yy - int(th * 0.22)), fill=(255, 255, 255, 70), width=int(th * 0.16))
    step = int(th * 0.55)
    x = a
    while x < b:
        md.line((x, yy - th * 0.42, x + th * 0.34, yy + th * 0.42), fill=(0, 0, 0, 55), width=max(2, int(th * 0.07)))
        x += step
    # keep the marks inside the rope only
    limit = Image.new("L", img.size, 0)
    ImageDraw.Draw(limit).line((a, yy, b, yy), fill=255, width=th)
    marks.putalpha(Image.composite(marks.getchannel("A"), Image.new("L", img.size, 0), limit))
    img.alpha_composite(marks)


def draw_knot(img, cx, cy, r):
    d = ImageDraw.Draw(img)
    c = (P(cx), P(cy))
    R = P(r)
    sh = Image.new("RGBA", img.size, (0, 0, 0, 0))
    ImageDraw.Draw(sh).ellipse((c[0] - R, c[1] - R + P(10), c[0] + R, c[1] + R + P(10)), fill=(0, 0, 0, 90))
    img.alpha_composite(sh.filter(ImageFilter.GaussianBlur(P(8))))
    d = ImageDraw.Draw(img)
    d.ellipse((c[0] - R, c[1] - R, c[0] + R, c[1] + R), fill=GOLD_DARK)
    r2 = int(R * 0.88)
    d.ellipse((c[0] - r2, c[1] - r2, c[0] + r2, c[1] + r2), fill=GOLD)
    h = int(R * 0.5)
    d.ellipse((c[0] - int(R * 0.55), c[1] - int(R * 0.6), c[0] - int(R * 0.55) + h, c[1] - int(R * 0.6) + int(h * 0.7)),
              fill=(255, 236, 160, 200))


def finish(bg, fg):
    full = bg.copy()
    full.alpha_composite(fg)
    names = {"full": "icon", "background": "icon_background", "foreground": "icon_foreground"}
    for tag, im in (("full", full), ("background", bg), ("foreground", fg)):
        out = im.resize((N, N), Image.LANCZOS)
        if tag != "foreground":
            out = out.convert("RGB")
        out.save(os.path.join(OUT, f"{names[tag]}.png"))
    return full


def transparent():
    return Image.new("RGBA", (W, W), (0, 0, 0, 0))


# ---- Concept A: blue and red halves, "+" and "x", rope with a gold knot ----
def concept_a():
    bg = split_background()
    fg = transparent()
    paste_symbol(fg, "plus", 360, 395, 205)
    paste_symbol(fg, "times", 664, 395, 205)
    draw_rope(fg, 650, -40, N + 40, 84)
    draw_knot(fg, 512, 650, 80)
    finish("A", bg, fg)


# ---- The icon: blue and red halves, "+" and "x", a rope with a gold knot ----
def make_icon():
    bg = split_background()
    fg = transparent()
    paste_symbol(fg, "plus", 360, 395, 205)
    paste_symbol(fg, "times", 664, 395, 205)
    draw_rope(fg, 650, -40, N + 40, 84)
    draw_knot(fg, 512, 650, 80)
    return finish(bg, fg)


def make_splash_logo(full):
    """A round logo on a transparent 1152 x 1152 canvas. Android 12 shows only
    the middle 768 px circle of this image, so the circle is 760 px wide."""
    size, circle = 1152, 760
    logo = full.resize((circle, circle), Image.LANCZOS).convert("RGBA")
    mask = Image.new("L", (circle * 4, circle * 4), 0)
    ImageDraw.Draw(mask).ellipse((0, 0, circle * 4 - 1, circle * 4 - 1), fill=255)
    logo.putalpha(mask.resize((circle, circle), Image.LANCZOS))
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    canvas.paste(logo, ((size - circle) // 2, (size - circle) // 2), logo)
    canvas.save(os.path.join(OUT, "splash_logo.png"))


if __name__ == "__main__":
    full = make_icon()
    make_splash_logo(full.convert("RGBA"))
    print("done: wrote assets/icon")
