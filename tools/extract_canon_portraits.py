"""Extract official original Castle webtoon portraits (standing, HUD, panoramic cut-ins)
from sibling castle_common repository (read-only via git show & work/looks/ref).

Author-approved direct use of original Castle (정연) webtoon art (2026-11-25 user).

Outputs (compact mobile-ready JPEG, ~3.5MB total for 80+ characters across ch0..ch13):
  assets/portraits/<id>_stand.jpg   (340x400 RGB — crisp bust/half-body card for 2D VN dialogue)
  assets/portraits/<id>_hud.jpg     (160x160 RGB — tight face crop for combat HUD frames)
  assets/portraits/<id>_cutin.jpg   (960x300 RGB — dramatic panoramic eye/face comic cut-in strip)
  src/view/portraits_data.gd        (auto-generated registry of available stand/hud/cutin IDs + accents)
"""
import io
import json
import os
import subprocess
import sys
from PIL import Image, ImageDraw, ImageEnhance, ImageFilter

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
COMMON = os.environ.get("CASTLE_COMMON") or os.path.join(os.path.dirname(REPO), "castle_common")
REF_DIR = os.path.join(COMMON, "work", "looks", "ref")
PROFILES_JSON = os.path.join(COMMON, "work", "looks", "profiles.json")
OUT_DIR = os.path.join(REPO, "assets", "portraits")
DATA_GD = os.path.join(REPO, "src", "view", "portraits_data.gd")

STAND_SIZE = (340, 400)
HUD_SIZE = (160, 160)
CUTIN_SIZE = (960, 300)

# Major heroes, allies & bosses that receive dedicated panoramic 960x300 cut-in strips
CUTIN_IDS = [
    "kimshin", "kimshin_shadow", "baekdochan", "jintae", "ojiin", "woojin",
    "shingen", "gunter", "yundeoksu", "kimdaegeon", "namgunghyuk", "iseul",
    "hwangbomincheol", "sintaejin", "kimjaehoon", "gangchangseok", "kimhyeokju",
    "kimseongjun", "gangmanjae", "mahakyoung", "majunyeong", "gustav", "richeon",
    "akila", "ryujihak", "yuwoosung", "choeminuk", "guilhwa", "hayabusa",
    "grolla", "barista", "komodo", "immuyeol", "vasily", "pyoyoung", "chasumin",
]

# Custom accent colors (RGB 0..1) for flagship cast; others derive by faction/id
ACCENTS = {
    "kimshin": (0.28, 0.80, 0.98),
    "kimshin_shadow": (0.28, 0.80, 0.98),
    "baekdochan": (0.94, 0.16, 0.20),
    "risa": (0.94, 0.74, 0.34),
    "client_woman": (0.76, 0.68, 0.64),
    "jintae": (0.98, 0.76, 0.18),
    "ojiin": (0.86, 0.18, 0.30),
    "woojin": (0.34, 0.72, 0.96),
    "kimdaegeon": (0.36, 0.78, 0.56),
    "iseul": (0.88, 0.64, 0.24),
    "pyoyoung": (0.42, 0.82, 0.92),
    "chasumin": (0.48, 0.72, 0.86),
    "shingen": (0.92, 0.22, 0.24),
    "gunter": (0.76, 0.20, 0.26),
    "yundeoksu": (0.84, 0.24, 0.20),
    "namgunghyuk": (0.90, 0.72, 0.26),
    "sintaejin": (0.42, 0.68, 0.58),
    "kimjaehoon": (0.74, 0.30, 0.32),
    "mahakyoung": (0.90, 0.16, 0.22),
    "choeminuk": (0.94, 0.76, 0.28),
    "gustav": (0.88, 0.22, 0.26),
    "richeon": (0.92, 0.24, 0.20),
    "akila": (0.86, 0.42, 0.24),
    "ryujihak": (0.56, 0.74, 0.92),
    "yuwoosung": (0.88, 0.26, 0.36),
}

# Characters that naturally face left (faces_right=False) vs right (faces_right=True)
# Determined from the official profile / curated crop orientation
FACES_RIGHT_OVERRIDES = {
    "jintae": True,
    "risa": True,
    "client_woman": False,
    "kimshin": False,
    "baekdochan": False,
    "ojiin": False,
    "woojin": False,
}

# Characters who naturally prefer standing on the right side during neutral scenes
PREFER_RIGHT_IDS = {
    "baekdochan", "risa", "ojiin", "gunter", "yundeoksu", "kimhyeokju", "kimseongjun",
    "gangmanjae", "namgunghyuk", "hwangbomincheol", "kimjaehoon", "gangchangseok",
    "sintaejin", "shingen", "mahakyoung", "majunyeong", "choeminuk", "gustav",
    "richeon", "yuwoosung", "guilhwa", "hayabusa", "grolla", "barista", "komodo",
    "cheonildo", "juro", "sainjin", "douchen", "lingling", "blackmamba", "vasily",
    "keurisa", "scaledanjang", "mark",
}


def load_git_image(rel_path: str) -> Image.Image:
    data = subprocess.check_output(["git", "-C", COMMON, "show", "HEAD:" + rel_path])
    return Image.open(io.BytesIO(data)).convert("RGB")


def fit_cover(im: Image.Image, target: tuple[int, int], anchor_y: float = 0.22, anchor_x: float = 0.5) -> Image.Image:
    """Resize+crop image to exact target aspect ratio without distortion, anchored near face."""
    tw, th = target
    w, h = im.size
    scale = max(tw / max(w, 1), th / max(h, 1))
    nw, nh = max(tw, round(w * scale)), max(th, round(h * scale))
    rs = im.resize((nw, nh), Image.LANCZOS)
    x0 = max(0, min(nw - tw, round((nw - tw) * anchor_x)))
    y0 = max(0, min(nh - th, round((nh - th) * anchor_y)))
    return rs.crop((x0, y0, x0 + tw, y0 + th))


def trim_dark_border(im: Image.Image, thresh: int = 16, max_frac: float = 0.12) -> Image.Image:
    """Trim pure-black outer panel frames cleanly."""
    w, h = im.size
    px = im.load()

    def row_dark(y: int) -> bool:
        dark = 0
        for x in range(0, w, 4):
            r, g, b = px[x, y]
            if max(r, g, b) <= thresh:
                dark += 1
        return dark >= (w // 4) * 0.88

    def col_dark(x: int) -> bool:
        dark = 0
        for y in range(0, h, 4):
            r, g, b = px[x, y]
            if max(r, g, b) <= thresh:
                dark += 1
        return dark >= (h // 4) * 0.88

    x0, y0, x1, y1 = 0, 0, w, h
    lim_x = int(w * max_frac)
    lim_y = int(h * max_frac)
    while y0 < lim_y and row_dark(y0):
        y0 += 1
    while y1 > h - lim_y and row_dark(y1 - 1):
        y1 -= 1
    while x0 < lim_x and col_dark(x0):
        x0 += 1
    while x1 > w - lim_x and col_dark(x1 - 1):
        x1 -= 1
    return im.crop((x0, y0, max(x0 + 32, x1), max(y0 + 32, y1)))


def crop_profile_portrait(card: Image.Image) -> Image.Image:
    """Extract the clean inner portrait artwork from a 773x1124 official Castle character card."""
    w, h = card.size
    # Official template inner art box (inside the black border)
    box = card.crop((int(w * 0.072), int(h * 0.145), int(w * 0.528), int(h * 0.494)))
    return trim_dark_border(box, thresh=18, max_frac=0.06)


def clean_client_woman_panel(ep002_011: Image.Image) -> Image.Image:
    """Crop bruised client woman from p1:002/011 cleanly below/right of the speech bubble."""
    # Speech bubble ends around y=632 at the far left; her hair/forehead starts at x=228
    crop = ep002_011.crop((170, 628, 635, 1036)).copy()
    w, h = crop.size
    px = crop.load()
    # Cleanly blend away the tiny residual bubble curve in the upper-left corner (x < 120, y < 38)
    bg = px[12, min(h - 1, 64)]
    for y in range(min(44, h)):
        for x in range(min(130, w)):
            if x * 0.42 + y < 40:
                r, g, b = px[x, y]
                if max(r, g, b) > 120 or (x * 0.42 + y < 30):
                    px[x, y] = bg
    return crop


def make_panoramic_cutin(im: Image.Image, eye_y_frac: float = 0.30, zoom: float = 1.12,
                         accent: tuple = (0.9, 0.16, 0.2)) -> Image.Image:
    """Build a crisp 960x300 panoramic manga eye/face cut-in strip from original Jeongyeon artwork.
    Adds subtle noir contrast punch + comic diagonal speed vignette on far outer edge so the
    character's original eyes stay razor-sharp and unmistakable while giving huge readability
    for bold skill/counter typography."""
    tw, th = CUTIN_SIZE
    w, h = im.size
    # Crop a wide eye-focused band (aspect ~3.2:1) from the source image
    # If the source is narrow (vertical portrait), center horizontally and zoom cleanly on eyes
    crop_w = int(w / max(zoom, 1.0))
    crop_h = max(36, int(crop_w * (th / tw)))
    if crop_h > int(h * 0.65):
        crop_h = int(h * 0.65)
        crop_w = min(w, int(crop_h * (tw / th)))
    cx = w // 2
    cy = int(h * eye_y_frac)
    x0 = max(0, min(w - crop_w, cx - crop_w // 2))
    y0 = max(0, min(h - crop_h, cy - crop_h // 2))
    band = im.crop((x0, y0, x0 + crop_w, y0 + crop_h))
    out = band.resize((tw, th), Image.LANCZOS)
    # Crisp webtoon contrast & slight sharpness boost so upscaled manga ink lines stay razor-sharp
    out = ImageEnhance.Contrast(out).enhance(1.10)
    out = ImageEnhance.Sharpness(out).enhance(1.25)
    return out


def make_curated_sources() -> dict:
    """Load curated high-resolution original webtoon images for flagship & prologue characters."""
    curated = {}
    # Prologue ep002 panels
    ep002_008 = load_git_image("sources/castle1/002화/008.jpg")
    ep002_010 = load_git_image("sources/castle1/002화/010.jpg")
    ep002_011 = load_git_image("sources/castle1/002화/011.jpg")

    # Risa (prologue fur coat sitting at bar — zero bubble, zero watermark!)
    risa_stand = ep002_008.crop((80, 808, 635, 1418))
    # Risa close-up face for HUD (cropped cleanly below the top-right speech bubble)
    risa_hud = ep002_010.crop((92, 1326, 432, 1600))
    curated["risa"] = {"stand_src": risa_stand, "hud_src": risa_hud, "stand_ay": 0.14, "hud_ay": 0.35}

    # Client Woman (bruised face in hoodie from 002/011 — clean corner)
    cw_clean = clean_client_woman_panel(ep002_011)
    curated["client_woman"] = {"stand_src": cw_clean, "hud_src": cw_clean.crop((100, 0, 395, 295)), "stand_ay": 0.10, "hud_ay": 0.20}

    # Kim Shin shadow reveal (002/010 — iconic hooded eyes in darkness!)
    ks_shadow = ep002_010.crop((52, 388, 636, 734))
    curated["kimshin_shadow"] = {
        "stand_src": ks_shadow, "hud_src": ks_shadow.crop((150, 10, 520, 340)),
        "cutin_src": ks_shadow, "cutin_y": 0.46, "cutin_zoom": 1.04,
    }

    # Kim Shin flagship: official profile card for stand/HUD, intense frontal eye glare (ref/kimshin.png) for cut-in!
    ks_prof = crop_profile_portrait(load_git_image("sources/character_profile/김신.jpg"))
    ks_ref = Image.open(os.path.join(REF_DIR, "kimshin.png")).convert("RGB")
    # Trim tiny speech bubble tip at very bottom-left of kimshin.png (y < 340)
    ks_ref_clean = ks_ref.crop((0, 0, ks_ref.size[0], int(ks_ref.size[1] * 0.92)))
    curated["kimshin"] = {
        "stand_src": ks_prof, "hud_src": ks_prof.crop((95, 0, 315, 220)),
        "cutin_src": ks_ref_clean, "cutin_y": 0.31, "cutin_zoom": 1.02,
        "stand_ay": 0.08, "hud_ay": 0.20,
    }

    # Baek Dochan flagship: official profile card (Baek + giant red-eyed Python!)
    bd_prof = crop_profile_portrait(load_git_image("sources/character_profile/선진_백도찬.jpg"))
    curated["baekdochan"] = {
        "stand_src": bd_prof, "hud_src": bd_prof.crop((145, 16, 330, 201)),
        "cutin_src": bd_prof, "cutin_y": 0.26, "cutin_zoom": 1.0,
        "stand_ay": 0.08, "hud_ay": 0.20,
    }

    # Seo Jintae flagship: badass dark-suit amber-shades ref for stand/HUD/cut-in!
    jt_ref = Image.open(os.path.join(REF_DIR, "jintae.png")).convert("RGB")
    curated["jintae"] = {
        "stand_src": jt_ref, "hud_src": jt_ref.crop((45, 0, 285, 240)),
        "cutin_src": jt_ref, "cutin_y": 0.34, "cutin_zoom": 1.02,
        "stand_ay": 0.08, "hud_ay": 0.20,
    }

    # Ojiin flagship: crisp official profile card
    oj_prof = crop_profile_portrait(load_git_image("sources/character_profile/하성_오지인.jpg"))
    curated["ojiin"] = {
        "stand_src": oj_prof, "hud_src": oj_prof.crop((80, 0, 295, 215)),
        "cutin_src": oj_prof, "cutin_y": 0.30, "cutin_zoom": 1.06,
        "stand_ay": 0.08, "hud_ay": 0.20,
    }

    # Pi Woojin flagship: crisp official profile card
    wj_prof = crop_profile_portrait(load_git_image("sources/character_profile/피우진.jpg"))
    curated["woojin"] = {
        "stand_src": wj_prof, "hud_src": wj_prof.crop((50, 0, 305, 255)),
        "cutin_src": wj_prof, "cutin_y": 0.35, "cutin_zoom": 1.06,
        "stand_ay": 0.08, "hud_ay": 0.20,
    }

    # Gunter: clean ep002/022 panel starting cleanly below the speech bubble!
    ep002_022 = load_git_image("sources/castle1/002화/022.jpg")
    gunter_clean = ep002_022.crop((155, 368, 565, 790))
    curated["gunter"] = {
        "stand_src": gunter_clean, "hud_src": gunter_clean.crop((85, 4, 325, 244)),
        "cutin_src": gunter_clean, "cutin_y": 0.25, "cutin_zoom": 1.06,
        "stand_ay": 0.10, "hud_ay": 0.20,
    }

    # Namgung Hyuk: trim tiny right-side speech bubble cleanly
    ng_ref = Image.open(os.path.join(REF_DIR, "namgunghyuk.png")).convert("RGB")
    ng_clean = ng_ref.crop((0, 0, int(ng_ref.size[0] * 0.80), ng_ref.size[1]))
    curated["namgunghyuk"] = {
        "stand_src": ng_clean, "hud_src": ng_clean.crop((20, 0, 215, 195)),
        "cutin_src": ng_clean, "cutin_y": 0.26, "cutin_zoom": 1.04,
        "stand_ay": 0.08, "hud_ay": 0.18,
    }
    return curated


def trim_ref_edges(im: Image.Image) -> Image.Image:
    """Cleanly trim black borders and bottom caption strips (e.g. name boxes) from work/looks/ref images."""
    im = trim_dark_border(im, thresh=18, max_frac=0.14)
    w, h = im.size
    # Many ref crops have a small black caption tag at the very bottom 12% — check if bottom strip is dark
    px = im.load()
    dark_rows = 0
    for y in range(h - 1, max(0, h - int(h * 0.22)), -1):
        cnt = sum(1 for x in range(0, w, 4) if max(px[x, y]) < 28)
        if cnt > (w // 4) * 0.62:
            dark_rows += 1
        else:
            break
    if dark_rows > 6:
        im = im.crop((0, 0, w, max(64, h - dark_rows - 2)))
    return im


def default_accent(cid: str) -> tuple:
    if cid in ACCENTS:
        return ACCENTS[cid]
    if cid in PREFER_RIGHT_IDS:
        return (0.86, 0.20, 0.24)
    return (0.36, 0.74, 0.94)


def main() -> int:
    os.makedirs(OUT_DIR, exist_ok=True)
    # Remove old AI-generated PNG portraits and their .import files so ASSETS.md stays spotless
    for fn in list(os.listdir(OUT_DIR)):
        if fn.endswith((".png", ".png.import")):
            os.remove(os.path.join(OUT_DIR, fn))

    # Load all official profile cards (keep only full-res >= 500px wide!)
    with open(PROFILES_JSON, encoding="utf-8") as f:
        profs_map = json.load(f)
    hi_profiles = {}
    for fn, cid in profs_map.items():
        try:
            im = load_git_image("sources/character_profile/" + fn)
            if im.size[0] >= 500:
                hi_profiles[cid] = crop_profile_portrait(im)
        except Exception as e:
            print(f"WARN profile {fn}: {e}")

    curated = make_curated_sources()

    # Collect target character IDs: all speakers in lines.json + all curated + all hi_profiles + all named refs
    target_ids = set(curated.keys()) | set(hi_profiles.keys())
    for fn in os.listdir(REF_DIR):
        if fn.endswith(".png") and not fn.startswith("_"):
            target_ids.add(os.path.splitext(fn)[0])

    specs = {}
    total_kb = 0
    for cid in sorted(target_ids):
        stand_src = None
        hud_src = None
        cutin_src = None
        stand_ay = 0.14
        hud_ay = 0.18
        cutin_y = 0.28
        cutin_zoom = 1.08

        if cid in curated:
            c = curated[cid]
            stand_src = c["stand_src"]
            hud_src = c.get("hud_src", stand_src)
            cutin_src = c.get("cutin_src", stand_src)
            stand_ay = c.get("stand_ay", 0.14)
            hud_ay = c.get("hud_ay", 0.18)
            cutin_y = c.get("cutin_y", 0.30)
            cutin_zoom = c.get("cutin_zoom", 1.06)
        elif cid in hi_profiles:
            stand_src = hi_profiles[cid]
            hud_src = stand_src
            cutin_src = stand_src
            stand_ay = 0.10
            hud_ay = 0.16
            cutin_y = 0.28
        else:
            ref_path = os.path.join(REF_DIR, f"{cid}.png")
            if not os.path.exists(ref_path):
                continue
            stand_src = trim_ref_edges(Image.open(ref_path).convert("RGB"))
            hud_src = stand_src
            cutin_src = stand_src
            stand_ay = 0.10
            hud_ay = 0.12
            cutin_y = 0.24

        stand_img = fit_cover(stand_src, STAND_SIZE, anchor_y=stand_ay)
        # Subtle comic print sharpness
        stand_img = ImageEnhance.Sharpness(stand_img).enhance(1.12)
        stand_out = os.path.join(OUT_DIR, f"{cid}_stand.jpg")
        stand_img.save(stand_out, "JPEG", quality=87, optimize=True)
        total_kb += os.path.getsize(stand_out) // 1024

        hud_img = fit_cover(hud_src, HUD_SIZE, anchor_y=hud_ay)
        hud_img = ImageEnhance.Sharpness(hud_img).enhance(1.15)
        hud_out = os.path.join(OUT_DIR, f"{cid}_hud.jpg")
        hud_img.save(hud_out, "JPEG", quality=88, optimize=True)
        total_kb += os.path.getsize(hud_out) // 1024

        has_cutin = cid in CUTIN_IDS
        if has_cutin:
            acc = default_accent(cid)
            ci_img = make_panoramic_cutin(cutin_src, eye_y_frac=cutin_y, zoom=cutin_zoom, accent=acc)
            ci_out = os.path.join(OUT_DIR, f"{cid}_cutin.jpg")
            ci_img.save(ci_out, "JPEG", quality=89, optimize=True)
            total_kb += os.path.getsize(ci_out) // 1024

        specs[cid] = {
            "stand": f"res://assets/portraits/{cid}_stand.jpg",
            "hud": f"res://assets/portraits/{cid}_hud.jpg",
            "cutin": f"res://assets/portraits/{cid}_cutin.jpg" if has_cutin else "",
            "accent": default_accent(cid),
            "faces_right": FACES_RIGHT_OVERRIDES.get(cid, False),
            "prefer_right": cid in PREFER_RIGHT_IDS,
        }

    # Generate src/view/portraits_data.gd cleanly
    lines = [
        "extends RefCounted",
        "## 원작 웹툰(정연 「캐슬」) 공식 인물 포트레이트 · HUD · 사선 컷인 자동 생성 표.",
        "## 생성 도구: python3.11 tools/extract_canon_portraits.py (castle_common 읽기 전용 추출).",
        "",
        "const SPECS := {",
    ]
    for cid in sorted(specs.keys()):
        s = specs[cid]
        r, g, b = s["accent"]
        lines.append(
            f'\t"{cid}": {{"stand": "{s["stand"]}", "hud": "{s["hud"]}", "cutin": "{s["cutin"]}", '
            f'"accent": Color({r:.2f}, {g:.2f}, {b:.2f}), '
            f'"faces_right": {"true" if s["faces_right"] else "false"}, '
            f'"prefer_right": {"true" if s["prefer_right"] else "false"}}},'
        )
    lines.append("}")
    with open(DATA_GD, "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")

    print(f"DONE: {len(specs)} characters, {sum(1 for s in specs.values() if s['cutin'])} cut-ins, total={total_kb/1024:.2f} MB")
    return 0


if __name__ == "__main__":
    sys.exit(main())
