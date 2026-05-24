#!/usr/bin/env python3
"""Generate liquid glass 'b' logo for Beacon Biometric (logo-b.png)."""

from PIL import Image, ImageDraw, ImageFilter, ImageFont
import numpy as np
import os

W, H = 480, 540
CORNER = 48
OUT = os.path.join(os.path.dirname(__file__), "logo-b.png")

# --- shadow layer ---
shadow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
sd = ImageDraw.Draw(shadow)
for i in range(8):
    a = int(38 * (1 - i / 8))
    sd.rounded_rectangle([8 + i, 12 + i, W - 8 - i, H - 8 - i], radius=CORNER, fill=(30, 90, 200, a))
shadow = shadow.filter(ImageFilter.GaussianBlur(8))

# --- glass base ---
base = Image.new("RGBA", (W, H), (0, 0, 0, 0))
bd = ImageDraw.Draw(base)
bd.rounded_rectangle([8, 8, W - 8, H - 8], radius=CORNER, fill=(255, 255, 255, 56))

# --- specular cap (numpy radial gradient) ---
spec = Image.new("RGBA", (W, H), (0, 0, 0, 0))
spec_arr = np.zeros((H, W), dtype=np.float32)
cx, cy = W // 2, int(H * 0.28)
rx, ry = W * 0.42, H * 0.30
y_idx, x_idx = np.mgrid[0:H, 0:W]
dx = (x_idx - cx) / rx
dy = (y_idx - cy) / ry
raw = np.clip(1 - (dx ** 2 + dy ** 2), 0, 1) ** 0.9
spec_arr = (raw * 215).astype(np.uint8)
spec_rgba = np.zeros((H, W, 4), dtype=np.uint8)
spec_rgba[:, :, 0] = 255
spec_rgba[:, :, 1] = 255
spec_rgba[:, :, 2] = 255
spec_rgba[:, :, 3] = spec_arr
spec = Image.fromarray(spec_rgba, "RGBA").filter(ImageFilter.GaussianBlur(4))

# --- top shine ---
shine = Image.new("RGBA", (W, H), (0, 0, 0, 0))
shine_arr = np.zeros((H, W, 4), dtype=np.uint8)
for row in range(H):
    t = 1 - row / (H * 0.28)
    a = int(max(0, min(217, 217 * t)))
    shine_arr[row, :, :] = [255, 255, 255, a]
shine = Image.fromarray(shine_arr, "RGBA").filter(ImageFilter.GaussianBlur(6))

# --- secondary shimmer band ---
shimmer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
shimmer_arr = np.zeros((H, W, 4), dtype=np.uint8)
band_center = int(H * 0.55)
band_half = int(H * 0.07)
for row in range(H):
    dist = abs(row - band_center)
    if dist < band_half:
        a = int(48 * (1 - dist / band_half))
        shimmer_arr[row, :, :] = [255, 255, 255, a]
shimmer = Image.fromarray(shimmer_arr, "RGBA").filter(ImageFilter.GaussianBlur(2))

# --- bottom edge shimmer ---
btm = Image.new("RGBA", (W, H), (0, 0, 0, 0))
btm_arr = np.zeros((H, W, 4), dtype=np.uint8)
for row in range(H):
    t = (row - H * 0.80) / (H * 0.18)
    if 0 < t < 1:
        a = int(60 * t)
        btm_arr[row, :, :] = [255, 255, 255, a]
btm = Image.fromarray(btm_arr, "RGBA").filter(ImageFilter.GaussianBlur(2))

# --- composite glass layers ---
glass = Image.new("RGBA", (W, H), (0, 0, 0, 0))
glass = Image.alpha_composite(glass, shadow)
glass = Image.alpha_composite(glass, base)
glass = Image.alpha_composite(glass, spec)
glass = Image.alpha_composite(glass, shine)
glass = Image.alpha_composite(glass, shimmer)
glass = Image.alpha_composite(glass, btm)

# --- white border ---
bd2 = ImageDraw.Draw(glass)
bd2.rounded_rectangle([8, 8, W - 8, H - 8], radius=CORNER,
                       outline=(255, 255, 255, 173), width=2, fill=None)

# --- "b" glyph ---
FONT_PATH = "/Library/Fonts/SF-Pro-Display-Bold.otf"
FONT_FALLBACK = "/System/Library/Fonts/Helvetica.ttc"
font_path = FONT_PATH if os.path.exists(FONT_PATH) else FONT_FALLBACK
font = ImageFont.truetype(font_path, 300)

# glow layer
glow_layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
gd = ImageDraw.Draw(glow_layer)
bbox = font.getbbox("b")
tx = (W - (bbox[2] - bbox[0])) // 2 - bbox[0] + 4
ty = (H - (bbox[3] - bbox[1])) // 2 - bbox[1] - 18
gd.text((tx, ty), "b", font=font, fill=(255, 255, 255, 140))
glow_layer = glow_layer.filter(ImageFilter.GaussianBlur(20))

# sharp "b"
letter = Image.new("RGBA", (W, H), (0, 0, 0, 0))
ld = ImageDraw.Draw(letter)
ld.text((tx, ty), "b", font=font, fill=(255, 255, 255, 235))

glass = Image.alpha_composite(glass, glow_layer)
glass = Image.alpha_composite(glass, letter)

glass.save(OUT)
print(f"Saved → {OUT}")
