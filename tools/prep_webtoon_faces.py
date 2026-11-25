"""Prepare landmark-aligned 512x512 original Castle webtoon face textures for Blender 3D projection.

Reads original Jeongyeon artwork from sibling castle_common (read-only) and aligns each character's
eyes, nose, mouth, and chin onto a standardized frontal-planar UV template:
  - Canvas: 512 x 512 RGB (filled with character's exact webtoon cheek skin color at outer edges)
  - Standardized UV landmarks (matching tools/bake_webtoon3d.py frontal face projection):
      center X = 0.50 (px 256)
      eye line Y = 0.43 from top (px 220)   [inter-pupillary distance ~ 0.34 width = 174px]
      nose tip Y = 0.60 from top (px 307)
      mouth   Y = 0.75 from top (px 384)
      chin    Y = 0.90 from top (px 461)

Outputs into a specified directory (default: .tools/webtoon_faces/) so textures stay outside assets/
and get embedded cleanly inside the baked GLBs by tools/bake_webtoon3d.py.
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
OUT_DIR = os.path.join(REPO, ".tools", "webtoon_faces")
SIZE = 512


def load_git_image(rel_path: str) -> Image.Image:
    data = subprocess.check_output(["git", "-C", COMMON, "show", "HEAD:" + rel_path])
    return Image.open(io.BytesIO(data)).convert("RGB")


def crop_profile(fn: str) -> Image.Image:
    im = load_git_image("sources/character_profile/" + fn)
    w, h = im.size
    return im.crop((int(w * 0.072), int(h * 0.145), int(w * 0.528), int(h * 0.494)))


def build_aligned_face(src: Image.Image, crop_box: tuple, skin_rgb: tuple,
                       flip_x: bool = False, brighten: float = 1.04,
                       contrast: float = 1.06, feather: bool = True,
                       oval_rx: float = 0.42, oval_ry: float = 0.46, oval_cy: float = 0.54) -> Image.Image:
    """Crop the facial region (forehead to chin, cheek to cheek) and composite softly onto skin_rgb."""
    w, h = src.size
    x0, y0, x1, y1 = (int(w * crop_box[0]), int(h * crop_box[1]), int(w * crop_box[2]), int(h * crop_box[3]))
    face = src.crop((x0, y0, x1, y1))
    if flip_x:
        face = face.transpose(Image.FLIP_LEFT_RIGHT)
    face = face.resize((SIZE, SIZE), Image.LANCZOS)
    if brighten != 1.0:
        face = ImageEnhance.Brightness(face).enhance(brighten)
    if contrast != 1.0:
        face = ImageEnhance.Contrast(face).enhance(contrast)
    face = ImageEnhance.Sharpness(face).enhance(1.18)

    base = Image.new("RGB", (SIZE, SIZE), skin_rgb)
    if not feather:
        return face
    # Elliptical feathered mask so facial features (brows/eyes/nose/lips/chin/cheeks) sit 100% opaque
    # while outer hairline/ears blend invisibly into the character's exact webtoon skin color!
    mask = Image.new("L", (SIZE, SIZE), 0)
    dr = ImageDraw.Draw(mask)
    cx, cy = SIZE * 0.5, SIZE * oval_cy
    rx, ry = SIZE * oval_rx, SIZE * oval_ry
    dr.ellipse((cx - rx, cy - ry, cx + rx, cy + ry), fill=255)
    mask = mask.filter(ImageFilter.GaussianBlur(radius=28))
    return Image.composite(face, base, mask)


def sample_skin(im: Image.Image, fx: float, fy: float) -> tuple:
    w, h = im.size
    cx, cy = int(w * fx), int(h * fy)
    rs, gs, bs = [], [], []
    for dy in range(-4, 5):
        for dx in range(-4, 5):
            r, g, b = im.getpixel((max(0, min(w - 1, cx + dx)), max(0, min(h - 1, cy + dy))))
            rs.append(r); gs.append(g); bs.append(b)
    rs.sort(); gs.sort(); bs.sort()
    m = len(rs) // 2
    return (rs[m], gs[m], bs[m])


def main() -> int:
    os.makedirs(OUT_DIR, exist_ok=True)
    meta = {}

    # 1. Kim Shin (frontal sharp eyes + nose + lips + cheek scar from work/looks/ref/kimshin.png — EXACT frontal!)
    ks_src = Image.open(os.path.join(REF_DIR, "kimshin.png")).convert("RGB")
    ks_skin = sample_skin(ks_src, 0.58, 0.50)  # clean webtoon cheek tone
    # Tighten lower chin feather slightly so dark collar shadow never smudges the 3D chin!
    ks_face = build_aligned_face(ks_src, (0.08, 0.04, 0.92, 0.78), ks_skin, brighten=1.07, oval_rx=0.40, oval_ry=0.40, oval_cy=0.50)
    ks_face.save(os.path.join(OUT_DIR, "kim_face.png"))
    meta["kim"] = {"skin_rgb": list(ks_skin)}

    # 2. Baek Dochan (warmed slightly so face seamlessly blends with warm neck skin + crisp intense square jaw!)
    bd_src = crop_profile("선진_백도찬.jpg")
    bd_skin = (204, 182, 168)
    bd_face = build_aligned_face(bd_src, (0.50, 0.09, 0.83, 0.43), bd_skin, brighten=1.14, contrast=1.06, oval_rx=0.38, oval_ry=0.41, oval_cy=0.53)
    # Warm the cool night-cyan cast on Baek's profile cheek slightly toward natural webtoon skin while keeping gleaming white glasses bright
    bpx = bd_face.load()
    for y in range(SIZE):
        for x in range(SIZE):
            r, g, b = bpx[x, y]
            if not (r > 215 and g > 225 and b > 225):
                bpx[x, y] = (min(255, int(r * 1.09)), min(255, int(g * 1.01)), max(0, int(b * 0.93)))
    bd_face.save(os.path.join(OUT_DIR, "baek_face.png"))
    meta["baek"] = {"skin_rgb": list(bd_skin)}

    # 3. Ojiin (exact frontal razor-sharp beauty from official profile card — gentle warm ivory skin so legs don't blow out!)
    oj_src = crop_profile("하성_오지인.jpg")
    oj_skin = (232, 212, 204)
    # In oj_src: face spans x=0.35..0.77, y=0.10..0.54 -> eyes y=0.29, nose y=0.37, mouth y=0.43, chin y=0.51
    oj_face = build_aligned_face(oj_src, (0.34, 0.12, 0.76, 0.54), oj_skin, brighten=1.00, contrast=1.05, oval_rx=0.40, oval_ry=0.43, oval_cy=0.52)
    oj_face.save(os.path.join(OUT_DIR, "ojiin_face.png"))
    meta["ojiin"] = {"skin_rgb": list(oj_skin)}

    # 4. Risa (clean close-up from ep002/010 — rotate +28 deg CCW to level her eyes horizontally!)
    ep002_010 = load_git_image("sources/castle1/002화/010.jpg")
    risa_raw = ep002_010.crop((95, 1300, 465, 1600))
    risa_rot = risa_raw.rotate(28, resample=Image.BICUBIC, expand=True, fillcolor=(224, 196, 188))
    risa_skin = (224, 196, 188)
    risa_face = build_aligned_face(risa_rot, (0.20, 0.15, 0.78, 0.77), risa_skin, brighten=1.06, contrast=1.06, oval_rx=0.39, oval_ry=0.42, oval_cy=0.52)
    risa_face.save(os.path.join(OUT_DIR, "risa_face.png"))
    meta["risa"] = {"skin_rgb": list(risa_skin)}

    # 5. Client Woman (bruised face from ep002/011 — rotate +8 deg and shift down slightly so eyes sit on y=0.43!)
    ep002_011 = load_git_image("sources/castle1/002화/011.jpg")
    cw_raw = ep002_011.crop((235, 595, 565, 920))
    cw_rot = cw_raw.rotate(8, resample=Image.BICUBIC, expand=True, fillcolor=(196, 166, 156))
    cw_skin = (196, 166, 156)
    cw_face = build_aligned_face(cw_rot, (0.14, 0.12, 0.80, 0.84), cw_skin, brighten=1.08, contrast=1.06, oval_rx=0.39, oval_ry=0.42, oval_cy=0.53)
    cw_face.save(os.path.join(OUT_DIR, "client_woman_face.png"))
    meta["client_woman"] = {"skin_rgb": list(cw_skin)}

    # 6. Seo Jintae — crisp upright neutral-lit face from castle2/003화/024.jpg (rotate -15 deg CW to level shades & grin!)
    jt_ep = load_git_image("sources/castle2/003화/024.jpg")
    jt_raw = jt_ep.crop((235, 160, 465, 395))
    jt_rot = jt_raw.rotate(-15, resample=Image.BICUBIC, expand=True, fillcolor=(214, 192, 178))
    jt_skin = (214, 192, 178)
    jt_face = build_aligned_face(jt_rot, (0.14, 0.10, 0.82, 0.84), jt_skin, brighten=1.04, contrast=1.08, oval_rx=0.39, oval_ry=0.42, oval_cy=0.53)
    jt_face.save(os.path.join(OUT_DIR, "jintae_face.png"))
    meta["jintae"] = {"skin_rgb": list(jt_skin)}

    with open(os.path.join(OUT_DIR, "meta.json"), "w", encoding="utf-8") as f:
        json.dump(meta, f, indent=2)

    # Save visual alignment QA sheet with standardized landmark crosshair lines (eye=0.43, nose=0.60, mouth=0.75, chin=0.90)
    names = ["kim", "baek", "ojiin", "risa", "client_woman", "jintae"]
    sheet = Image.new("RGB", (256 * 3, 256 * 2), (20, 20, 24))
    for i, nm in enumerate(names):
        im = Image.open(os.path.join(OUT_DIR, f"{nm}_face.png")).resize((256, 256), Image.LANCZOS)
        dr = ImageDraw.Draw(im)
        dr.line((128, 0, 128, 255), fill=(80, 255, 120), width=1)
        for frac, col in [(0.43, (60, 220, 255)), (0.60, (255, 90, 90)), (0.75, (255, 220, 60)), (0.90, (240, 120, 255))]:
            y = int(256 * frac)
            dr.line((0, y, 255, y), fill=col, width=1)
        r, c = divmod(i, 3)
        sheet.paste(im, (c * 256, r * 256))
    qa_path = os.path.join(OUT_DIR, "qa_faces.jpg")
    sheet.save(qa_path, quality=90)
    print("OK prepared 6 aligned original webtoon face textures ->", qa_path)
    return 0


if __name__ == "__main__":
    sys.exit(main())
