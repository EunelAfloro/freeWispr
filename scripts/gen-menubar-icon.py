#!/usr/bin/env python3
"""Generate menu bar icon: sonic boom — jet with vapor cone."""

from PIL import Image, ImageDraw
import math


def draw_icon(size: int) -> Image.Image:
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    s = size
    cx = s * 0.55  # jet slightly right of center
    cy = s / 2

    # --- Vapor cone ring (perpendicular to fuselage, around the tail) ---
    stroke = max(round(s * 0.05), 1)
    ring_x = cx - s * 0.12  # centered on rear of fuselage
    for radius_frac in [0.28, 0.40]:
        r = s * radius_frac
        bbox = [ring_x - s * 0.06, cy - r, ring_x + s * 0.06, cy + r]
        # Full vertical ellipse (perpendicular disc around fuselage)
        draw.arc(bbox, start=0, end=360, fill=(0, 0, 0, 255), width=stroke)

    # --- Jet silhouette (small rightward arrow/chevron) ---
    # Fuselage
    fuse_len = s * 0.38
    fuse_h = max(round(s * 0.09), 1)
    fx = cx - fuse_len * 0.3
    draw.rounded_rectangle(
        [fx, cy - fuse_h / 2, fx + fuse_len, cy + fuse_h / 2],
        radius=max(fuse_h // 2, 1),
        fill=(0, 0, 0, 255),
    )

    # Nose cone (triangle pointing right)
    nose_x = fx + fuse_len
    nose_len = s * 0.12
    draw.polygon(
        [(nose_x, cy - fuse_h / 2),
         (nose_x + nose_len, cy),
         (nose_x, cy + fuse_h / 2)],
        fill=(0, 0, 0, 255),
    )

    # Wings (swept back)
    wing_span = s * 0.18
    wing_root_x = cx + s * 0.02
    wing_tip_back = s * 0.12
    wing_w = max(round(s * 0.05), 1)

    for direction in [-1, 1]:  # top and bottom wing
        tip_y = cy + direction * wing_span
        draw.polygon(
            [(wing_root_x, cy),
             (wing_root_x - wing_tip_back, tip_y),
             (wing_root_x - wing_tip_back + wing_w, tip_y)],
            fill=(0, 0, 0, 255),
        )

    return img


if __name__ == "__main__":
    import sys
    out_dir = sys.argv[1] if len(sys.argv) > 1 else "."

    for px, suffix in [(18, ""), (36, "@2x")]:
        icon = draw_icon(px)
        path = f"{out_dir}/MenuBarIcon{suffix}.png"
        icon.save(path)
        print(f"Saved {path} ({px}x{px})")
