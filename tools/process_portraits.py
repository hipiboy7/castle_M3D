"""Process generated noir webtoon illustrations into clean mobile-ready RGBA PNG assets.

Creates:
  assets/portraits/<id>_stand.png  (512x680 RGBA, chroma-key green cleanly removed + despilled)
  assets/portraits/<id>_hud.png    (192x192 RGBA, crisp head/face crop for HUD panels)
  assets/portraits/<id>_cutin.png  (960x300 RGB/PNG, panoramic eye-focus comic cut-in strip)
"""
import collections
import os
import sys
from PIL import Image

BRAIN = "/home/juho.hong/.gemini/antigravity-cli/brain/a6178d67-6358-4892-981b-19f710dddbeb"
REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_DIR = os.path.join(REPO, "assets", "portraits")

# (id, raw_filename, hud_crop_box_norm (x0, y0, x1, y1) focused on face/head)
STAND_SPECS = [
    ("kimshin", "kimshin_stand_final_1795569035541.jpg", (0.24, 0.03, 0.74, 0.44)),
    ("baekdochan", "baekdochan_stand_1795569047957.jpg", (0.24, 0.01, 0.72, 0.38)),
    ("risa", "risa_stand_1795569005110.jpg", (0.22, 0.03, 0.74, 0.46)),
    ("jintae", "jintae_stand_1795569008520.jpg", (0.30, 0.02, 0.84, 0.46)),
    ("ojiin", "ojiin_stand_1795569010253.jpg", (0.27, 0.05, 0.75, 0.44)),
    ("client_woman", "client_woman_stand_v2_1795569034682.jpg", (0.31, 0.04, 0.80, 0.44)),
]

# (id, raw_filename, vertical_center_norm 0..1 for 3.2:1 panoramic strip)
CUTIN_SPECS = [
    ("kimshin", "kimshin_cutin_1795569051376.jpg", 0.42),
    ("baekdochan", "baekdochan_cutin_1795569053447.jpg", 0.50),
    ("jintae", "jintae_cutin_1795569055168.jpg", 0.56),
    ("ojiin", "ojiin_cutin_1795569057563.jpg", 0.48),
]


def is_chroma_green(r: int, g: int, b: int) -> bool:
    """Detect vivid chroma-key green background pixels safely (zero false positives on skin/clothes)."""
    mx = r if r > b else b
    return g >= 115 and (g - mx) >= 38 and g > int(r * 1.18) and g > int(b * 1.18)


def remove_chroma_green(img: Image.Image) -> Image.Image:
    """Flood-fill + interior pocket chroma-key removal + green spill suppression (despill)."""
    rgba = img.convert("RGBA")
    w, h = rgba.size
    px = rgba.load()

    # Pass 1: mark definite chroma-key green background (exterior + enclosed pockets like between arm & katana)
    bg = bytearray(w * h)
    q = collections.deque()

    def seed_if_green(x: int, y: int) -> None:
        idx = y * w + x
        if bg[idx]:
            return
        r, g, b, _ = px[x, y]
        if is_chroma_green(r, g, b):
            bg[idx] = 1
            q.append((x, y))

    for x in range(w):
        seed_if_green(x, 0)
        seed_if_green(x, h - 1)
    for y in range(h):
        seed_if_green(0, y)
        seed_if_green(w - 1, y)

    # Also seed any interior pure chroma-green pixels (e.g. gap between arm & sword/torso)
    for y in range(h):
        for x in range(w):
            r, g, b, _ = px[x, y]
            mx = r if r > b else b
            if g >= 130 and (g - mx) >= 48 and r <= 105 and b <= 105:
                idx = y * w + x
                if not bg[idx]:
                    bg[idx] = 1
                    q.append((x, y))

    while q:
        cx, cy = q.popleft()
        for nx, ny in ((cx - 1, cy), (cx + 1, cy), (cx, cy - 1), (cx, cy + 1)):
            if 0 <= nx < w and 0 <= ny < h:
                nidx = ny * w + nx
                if not bg[nidx]:
                    r, g, b, _ = px[nx, ny]
                    if is_chroma_green(r, g, b):
                        bg[nidx] = 1
                        q.append((nx, ny))

    # Pass 2: soft anti-aliased fringe + despill on pixels adjacent to bg
    for y in range(h):
        row = y * w
        for x in range(w):
            if bg[row + x]:
                px[x, y] = (0, 0, 0, 0)
                continue
            r, g, b, a = px[x, y]
            mx = r if r > b else b
            excess = g - mx
            # Check if within 2px of background
            near_bg = False
            for dy in (-2, -1, 0, 1, 2):
                ny = y + dy
                if 0 <= ny < h:
                    nrow = ny * w
                    for dx in (-2, -1, 0, 1, 2):
                        nx = x + dx
                        if 0 <= nx < w and bg[nrow + nx]:
                            near_bg = True
                            break
                if near_bg:
                    break
            if near_bg and excess > 6:
                # Suppress green fringe and gently feather anti-aliased edge
                new_g = mx + min(4, excess // 5)
                if excess > 24 and g > 95:
                    new_a = max(0, min(255, int(255 * (1.0 - (excess - 24) / 42.0))))
                else:
                    new_a = a
                # Keep dark ink outlines crisp & deep black
                if r < 45 and b < 45 and g < 120:
                    new_g = mx
                px[x, y] = (r, new_g, b, new_a)
            elif excess > 16 and g > 130:
                # Residual isolated green JPEG compression pixel
                px[x, y] = (r, mx, b, a)
    return rgba


def make_stand_and_hud(cid: str, fname: str, hud_box: tuple) -> None:
    src = os.path.join(BRAIN, fname)
    img = Image.open(src)
    matted = remove_chroma_green(img)
    w, h = matted.size

    # Trim excess transparent space at top/sides slightly while keeping waist anchored at bottom
    bbox = matted.getbbox()
    if bbox:
        bx0, by0, bx1, by1 = bbox
        pad_x = int((bx1 - bx0) * 0.04)
        pad_top = int((by1 - by0) * 0.03)
        cx0 = max(0, bx0 - pad_x)
        cy0 = max(0, by0 - pad_top)
        cx1 = min(w, bx1 + pad_x)
        cy1 = h  # keep bottom flush
        trimmed = matted.crop((cx0, cy0, cx1, cy1))
    else:
        trimmed = matted

    # Fit cleanly inside 512x680 anchored at bottom-center
    tw, th = trimmed.size
    target_w, target_h = 512, 680
    scale = min(target_w / tw, target_h / th)
    nw, nh = max(1, round(tw * scale)), max(1, round(th * scale))
    resized = trimmed.resize((nw, nh), Image.LANCZOS)
    canvas = Image.new("RGBA", (target_w, target_h), (0, 0, 0, 0))
    canvas.paste(resized, ((target_w - nw) // 2, target_h - nh), resized)
    stand_out = os.path.join(OUT_DIR, f"{cid}_stand.png")
    canvas.save(stand_out, "PNG", optimize=True)

    # HUD face crop (192x192 square RGBA)
    x0 = int(w * hud_box[0])
    y0 = int(h * hud_box[1])
    x1 = int(w * hud_box[2])
    y1 = int(h * hud_box[3])
    # Force square crop centered on box
    bw, bh = x1 - x0, y1 - y0
    side = max(bw, bh)
    cx, cy = (x0 + x1) // 2, (y0 + y1) // 2
    sx0 = max(0, min(w - side, cx - side // 2))
    sy0 = max(0, min(h - side, cy - side // 2))
    hud_crop = matted.crop((sx0, sy0, sx0 + side, sy0 + side)).resize((192, 192), Image.LANCZOS)
    hud_out = os.path.join(OUT_DIR, f"{cid}_hud.png")
    hud_crop.save(hud_out, "PNG", optimize=True)
    print(f"OK {cid}: stand={os.path.getsize(stand_out)//1024}KB hud={os.path.getsize(hud_out)//1024}KB")


def make_cutin(cid: str, fname: str, yc: float) -> None:
    src = os.path.join(BRAIN, fname)
    img = Image.open(src).convert("RGB")
    w, h = img.size
    target_w, target_h = 960, 300
    crop_h = int(w * (target_h / target_w))
    cy = int(h * yc)
    y0 = max(0, min(h - crop_h, cy - crop_h // 2))
    strip = img.crop((0, y0, w, y0 + crop_h)).resize((target_w, target_h), Image.LANCZOS)
    out = os.path.join(OUT_DIR, f"{cid}_cutin.png")
    strip.save(out, "PNG", optimize=True)
    print(f"OK {cid}_cutin: {os.path.getsize(out)//1024}KB")


def main() -> int:
    os.makedirs(OUT_DIR, exist_ok=True)
    for cid, fname, hbox in STAND_SPECS:
        make_stand_and_hud(cid, fname, hbox)
    for cid, fname, yc in CUTIN_SPECS:
        make_cutin(cid, fname, yc)
    return 0


if __name__ == "__main__":
    sys.exit(main())
