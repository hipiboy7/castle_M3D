"""MPFB2 Realistic Pilot Character Baker (Blender 4.2 headless CLI).

Builds anatomically realistic CC0 MakeHuman/MPFB2 human characters with true PBR
textures (Albedo + Normal + Roughness), recolored CC0 outfits/hair/glasses,
arms-down rest pose, and clean 17-bone Identity-rest skeleton matching Godot's
src/view/puppet_glb.gd.

Usage (via tools/run_blender.sh or direct Blender env):
    blender -b --python tools/bake_realistic.py -- [kim baek risa_p1 risa jintae ojiin kim_coat kim_bare]
"""
import math
import os
import shutil
import sys
import tempfile

import bmesh
import bpy
import numpy as np
from mathutils import Euler, Matrix, Quaternion, Vector

from bl_ext.user_default.mpfb.services.humanservice import HumanService
from bl_ext.user_default.mpfb.services.locationservice import LocationService
from bl_ext.user_default.mpfb.services.targetservice import TargetService

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA_DIR = LocationService.get_user_data()

# Our 17-bone game skeleton hierarchy (matches src/view/puppet_glb.gd BONES)
TARGET_BONES = [
    ("hips", ""),
    ("spine", "hips"),
    ("chest", "spine"),
    ("neck", "chest"),
    ("head", "neck"),
    ("sh_r", "chest"),
    ("el_r", "sh_r"),
    ("hand_r", "el_r"),
    ("sh_l", "chest"),
    ("el_l", "sh_l"),
    ("hand_l", "el_l"),
    ("th_r", "hips"),
    ("kn_r", "th_r"),
    ("ft_r", "kn_r"),
    ("th_l", "hips"),
    ("kn_l", "th_l"),
    ("ft_l", "kn_l"),
]

# Source MPFB2 game_engine bone -> target bone (for joint head positions)
JOINT_SRC = {
    "hips": "pelvis",
    "spine": "spine_01",
    "chest": "spine_03",
    "neck": "neck_01",
    "head": "head",
    "sh_r": "upperarm_r",
    "el_r": "lowerarm_r",
    "hand_r": "hand_r",
    "sh_l": "upperarm_l",
    "el_l": "lowerarm_l",
    "hand_l": "hand_l",
    "th_r": "thigh_r",
    "kn_r": "calf_r",
    "ft_r": "foot_r",
    "th_l": "thigh_l",
    "kn_l": "calf_l",
    "ft_l": "foot_l",
}

# Weight merge table: MPFB2 game_engine bone -> our 17 bones
WEIGHT_MAP = {
    "Root": "hips",
    "pelvis": "hips",
    "spine_01": "spine",
    "spine_02": "spine",
    "spine_03": "chest",
    "clavicle_r": "chest",
    "clavicle_l": "chest",
    "neck_01": "neck",
    "head": "head",
    "upperarm_r": "sh_r",
    "lowerarm_r": "el_r",
    "hand_r": "hand_r",
    "upperarm_l": "sh_l",
    "lowerarm_l": "el_l",
    "hand_l": "hand_l",
    "thigh_r": "th_r",
    "calf_r": "kn_r",
    "foot_r": "ft_r",
    "ball_r": "ft_r",
    "thigh_l": "th_l",
    "calf_l": "kn_l",
    "foot_l": "ft_l",
    "ball_l": "ft_l",
}
for _finger in ("thumb", "index", "middle", "ring", "pinky"):
    for _seg in ("01", "02", "03"):
        WEIGHT_MAP[f"{_finger}_{_seg}_r"] = "hand_r"
        WEIGHT_MAP[f"{_finger}_{_seg}_l"] = "hand_l"


# 5 Hero Pilot Characters (+ Kim Shin prologue/p1 + Risa variants = 8 GLBs)
PILOT_SPECS = {
    "kim": {
        "out": "assets/models/kimshin_a.glb",
        "height_m": 1.76,
        "macro": {"gender": 1.0, "age": 0.42, "muscle": 0.72, "weight": 0.46, "height": 0.68,
                  "proportions": 0.56, "race": {"asian": 0.88, "caucasian": 0.12, "african": 0.0}},
        "skin": "skins/young_asian_male/young_asian_male.mhmat",
        "skin_tint": (1.02, 0.97, 0.94),
        "eye_mat": "eyes/materials/brown.mhmat",
        "eyebrows": ("eyebrows/eyebrow002/eyebrow002.mhclo", (0.06, 0.06, 0.08)),
        "eyelashes": None,
        "hair": ("hair/short04/short04.mhclo", (0.07, 0.07, 0.10)),
        "clothes": [
            ("clothes/male_elegantsuit01/male_elegantsuit01.mhclo", "kim_suit"),
            ("clothes/shoes04/shoes04.mhclo", ("tint", (0.08, 0.08, 0.10))),
        ],
        "glasses": None,
        "extras": [],
        "scar": True,
    },
    "kim_coat": {
        "out": "assets/models/kimshin_coat_a.glb",
        "height_m": 1.76,
        "macro": {"gender": 1.0, "age": 0.40, "muscle": 0.72, "weight": 0.46, "height": 0.68,
                  "proportions": 0.56, "race": {"asian": 0.88, "caucasian": 0.12, "african": 0.0}},
        "skin": "skins/young_asian_male/young_asian_male.mhmat",
        "skin_tint": (1.02, 0.97, 0.94),
        "eye_mat": "eyes/materials/brown.mhmat",
        "eyebrows": ("eyebrows/eyebrow002/eyebrow002.mhclo", (0.06, 0.06, 0.08)),
        "eyelashes": None,
        "hair": ("hair/short04/short04.mhclo", (0.07, 0.07, 0.10)),
        "clothes": [
            ("clothes/toigo_male_double-breasted_suit/toigo_male_double-breasted_suit.mhclo", "kim_coat_suit"),
            ("clothes/shoes04/shoes04.mhclo", ("tint", (0.08, 0.08, 0.10))),
        ],
        "glasses": None,
        "extras": ["long_coat_tails"],
        "scar": False,
    },
    "kim_bare": {
        "out": "assets/models/kimshin_p1_a.glb",
        "height_m": 1.76,
        "macro": {"gender": 1.0, "age": 0.40, "muscle": 0.72, "weight": 0.46, "height": 0.68,
                  "proportions": 0.56, "race": {"asian": 0.88, "caucasian": 0.12, "african": 0.0}},
        "skin": "skins/young_asian_male/young_asian_male.mhmat",
        "skin_tint": (1.02, 0.97, 0.94),
        "eye_mat": "eyes/materials/brown.mhmat",
        "eyebrows": ("eyebrows/eyebrow002/eyebrow002.mhclo", (0.06, 0.06, 0.08)),
        "eyelashes": None,
        "hair": ("hair/short04/short04.mhclo", (0.07, 0.07, 0.10)),
        "clothes": [
            ("clothes/male_casualsuit05/male_casualsuit05.mhclo", "kim_p1_casual"),
            ("clothes/shoes02/shoes02.mhclo", ("tint", (0.14, 0.14, 0.17))),
        ],
        "glasses": None,
        "extras": [],
        "scar": False,
    },
    "baek": {
        "out": "assets/models/baekdochan_a.glb",
        "height_m": 1.82,
        "macro": {"gender": 1.0, "age": 0.58, "muscle": 0.92, "weight": 0.58, "height": 0.82,
                  "proportions": 0.62, "race": {"asian": 0.85, "caucasian": 0.15, "african": 0.0}},
        "skin": "skins/middleage_asian_male/middleage_asian_male.mhmat",
        "skin_tint": (1.03, 0.97, 0.93),
        "eye_mat": "eyes/materials/brown.mhmat",
        "eyebrows": ("eyebrows/eyebrow005/eyebrow005.mhclo", (0.34, 0.23, 0.14)),
        "eyelashes": None,
        "hair": ("hair/short02/short02.mhclo", (0.48, 0.34, 0.20)),
        "clothes": [
            ("clothes/male_casualsuit01/male_casualsuit01.mhclo", "baek_shirt_pants"),
            ("clothes/shoes03/shoes03.mhclo", ("tint", (0.07, 0.07, 0.08))),
        ],
        "glasses": ("clothes/kwnet_at_optical_glasses/kwnet_at_optical_glasses.mhclo", "baek_glasses"),
        "extras": ["baek_shirt_puff"],
        "scar": False,
    },
    "risa_p1": {
        "out": "assets/models/risa_p1_a.glb",
        "height_m": 1.70,
        "macro": {"gender": 0.0, "age": 0.42, "muscle": 0.36, "weight": 0.43, "height": 0.62,
                  "proportions": 0.58, "cupsize": 0.72, "firmness": 0.78,
                  "race": {"asian": 0.04, "caucasian": 0.96, "african": 0.0}},
        "skin": "skins/toigo_light_skin_with_makeup/toigo_light_skin_with_makeup.mhmat",
        "skin_tint": (1.02, 0.98, 0.96),
        "eye_mat": "eyes/materials/ice.mhmat",
        "eyebrows": ("eyebrows/eyebrow004/eyebrow004.mhclo", (0.52, 0.39, 0.22)),
        "eyelashes": ("eyelashes/eyelashes02/eyelashes02.mhclo", (0.08, 0.07, 0.07)),
        "hair": ("hair/o4saken_long01/o4saken_long01.mhclo", (0.86, 0.68, 0.34)),
        "clothes": [
            ("clothes/toigo_shift_dress/toigo_shift_dress.mhclo", ("tint", (0.06, 0.06, 0.07))),
            ("clothes/toigo_female_double-breasted_suit/toigo_female_double-breasted_suit.mhclo", "risa_mink_jacket"),
            ("clothes/toigo_stiletto_booties/toigo_stiletto_booties.mhclo", ("tint", (0.07, 0.06, 0.07))),
        ],
        "glasses": None,
        "extras": [],
        "scar": False,
    },
    "client_woman": {
        "out": "assets/models/client_woman_a.glb",
        "height_m": 1.66,
        "macro": {"gender": 0.0, "age": 0.46, "muscle": 0.28, "weight": 0.38, "height": 0.54,
                  "proportions": 0.54, "cupsize": 0.55, "firmness": 0.65,
                  "race": {"asian": 0.05, "caucasian": 0.95, "african": 0.0}},
        "skin": "skins/young_caucasian_female/young_caucasian_female.mhmat",
        "skin_tint": (0.98, 0.95, 0.93),
        "eye_mat": "eyes/materials/brownlight.mhmat",
        "eyebrows": ("eyebrows/eyebrow004/eyebrow004.mhclo", (0.22, 0.15, 0.10)),
        "eyelashes": ("eyelashes/eyelashes02/eyelashes02.mhclo", (0.08, 0.07, 0.07)),
        "hair": ("hair/o4saken_long01/o4saken_long01.mhclo", (0.28, 0.18, 0.12)),
        "clothes": [
            ("clothes/female_elegantsuit01/female_elegantsuit01.mhclo", "client_blouse_skirt"),
            ("clothes/toigo_flats/toigo_flats.mhclo", ("tint", (0.10, 0.09, 0.10))),
        ],
        "glasses": None,
        "extras": [],
        "scar": False,
    },
    "risa": {
        "out": "assets/models/risa_a.glb",
        "height_m": 1.70,
        "macro": {"gender": 0.0, "age": 0.44, "muscle": 0.36, "weight": 0.43, "height": 0.62,
                  "proportions": 0.58, "cupsize": 0.72, "firmness": 0.78,
                  "race": {"asian": 0.04, "caucasian": 0.96, "african": 0.0}},
        "skin": "skins/toigo_light_skin_with_makeup/toigo_light_skin_with_makeup.mhmat",
        "skin_tint": (1.02, 0.98, 0.96),
        "eye_mat": "eyes/materials/ice.mhmat",
        "eyebrows": ("eyebrows/eyebrow004/eyebrow004.mhclo", (0.52, 0.39, 0.22)),
        "eyelashes": ("eyelashes/eyelashes02/eyelashes02.mhclo", (0.08, 0.07, 0.07)),
        "hair": ("hair/o4saken_long01/o4saken_long01.mhclo", (0.86, 0.68, 0.34)),
        "clothes": [
            ("clothes/toigo_female_double-breasted_suit/toigo_female_double-breasted_suit.mhclo", ("tint", (0.14, 0.13, 0.16))),
            ("clothes/toigo_stiletto_booties/toigo_stiletto_booties.mhclo", ("tint", (0.07, 0.06, 0.07))),
        ],
        "glasses": None,
        "extras": [],
        "scar": False,
    },
    "jintae": {
        "out": "assets/models/jintae_a.glb",
        "height_m": 1.74,
        "macro": {"gender": 1.0, "age": 0.34, "muscle": 0.68, "weight": 0.45, "height": 0.60,
                  "proportions": 0.55, "race": {"asian": 0.90, "caucasian": 0.10, "african": 0.0}},
        "skin": "skins/young_asian_male/young_asian_male.mhmat",
        "skin_tint": (1.03, 0.98, 0.95),
        "eye_mat": "eyes/materials/brown.mhmat",
        "eyebrows": ("eyebrows/eyebrow001/eyebrow001.mhclo", (0.38, 0.30, 0.18)),
        "eyelashes": None,
        "hair": ("hair/short03/short03.mhclo", (0.90, 0.75, 0.40)),
        "clothes": [
            ("clothes/male_casualsuit05/male_casualsuit05.mhclo", "jintae_pink_track"),
            ("clothes/shoes02/shoes02.mhclo", ("tint", (0.84, 0.84, 0.86))),
        ],
        "glasses": ("clothes/spamrakuen_sagerfrogs_glasses_01/spamrakuen_sagerfrogs_glasses_01.mhclo", "jintae_shades"),
        "extras": [],
        "scar": False,
    },
    "ojiin": {
        "out": "assets/models/ojiin_a.glb",
        "height_m": 1.68,
        "macro": {"gender": 0.0, "age": 0.40, "muscle": 0.32, "weight": 0.38, "height": 0.54,
                  "proportions": 0.56, "cupsize": 0.62, "firmness": 0.74,
                  "race": {"asian": 0.94, "caucasian": 0.06, "african": 0.0}},
        "skin": "skins/onlytheghosts_young_eurasian_female/onlytheghosts_young_eurasian_female.mhmat",
        "skin_tint": (1.03, 0.99, 0.97),
        "eye_mat": "eyes/materials/brown.mhmat",
        "eyebrows": ("eyebrows/eyebrow004/eyebrow004.mhclo", (0.06, 0.06, 0.08)),
        "eyelashes": ("eyelashes/eyelashes02/eyelashes02.mhclo", (0.06, 0.06, 0.07)),
        "hair": ("hair/rehmanpolanski_hair_bun_brown/rehmanpolanski_hair_bun_brown.mhclo", (0.06, 0.06, 0.08)),
        "clothes": [
            ("clothes/female_elegantsuit01/female_elegantsuit01.mhclo", "ojiin_blouse_skirt"),
            ("clothes/toigo_stiletto_booties/toigo_stiletto_booties.mhclo", ("tint", (0.07, 0.06, 0.07))),
        ],
        "glasses": None,
        "extras": [],
        "scar": False,
    },
}


def asset_path(rel):
    return os.path.join(DATA_DIR, rel)


def _img_pixels_np(img):
    w, h = img.size
    arr = np.empty(w * h * 4, dtype=np.float32)
    img.pixels.foreach_get(arr)
    return arr.reshape((h, w, 4))


def _set_img_pixels_np(img, arr):
    arr = np.clip(arr, 0.0, 1.0).astype(np.float32)
    img.pixels.foreach_set(arr.ravel())
    img.update()


def _recolor_hair_img(img, col):
    arr = _img_pixels_np(img)
    luma = 0.299 * arr[:, :, 0] + 0.587 * arr[:, :, 1] + 0.114 * arr[:, :, 2]
    # Normalize luminance around mid-tone so blondes/blacks both preserve realistic strand variation
    med = float(np.median(luma[arr[:, :, 3] > 0.2])) if np.any(arr[:, :, 3] > 0.2) else 0.4
    gain = np.clip(luma / max(med, 0.15), 0.35, 1.45)
    for c in range(3):
        arr[:, :, c] = col[c] * gain
    _set_img_pixels_np(img, arr)


def _recolor_outfit_img(img, mode):
    arr = _img_pixels_np(img)
    h, w, _ = arr.shape
    luma = 0.299 * arr[:, :, 0] + 0.587 * arr[:, :, 1] + 0.114 * arr[:, :, 2]
    # Note: Blender image rows are bottom-to-top (row 0 = bottom, row h-1 = top).
    # In PIL/top-down uv_sheet.png, y_top = 1.0 - (row / h).
    yy = np.linspace(1.0, 0.0, h, dtype=np.float32)[:, None]
    xx = np.linspace(0.0, 1.0, w, dtype=np.float32)[None, :]

    if isinstance(mode, tuple) and mode[0] == "tint":
        col = mode[1]
        med = float(np.median(luma[luma > 0.03])) if np.any(luma > 0.03) else 0.4
        gain = np.clip(luma / max(med, 0.12), 0.30, 1.45)
        for c in range(3):
            arr[:, :, c] = col[c] * gain
    elif mode == "kim_suit":
        # Preserve bright white dress shirt collar/cuffs, dark charcoal-navy suit with visible folds/lapels
        white_mask = luma > 0.52
        suit_gain = np.clip(luma / 0.28, 0.40, 1.40)
        for c, tc in enumerate((0.15, 0.15, 0.19)):
            arr[:, :, c] = np.where(white_mask, np.clip(arr[:, :, c] * 1.05, 0.0, 0.95), tc * suit_gain)
    elif mode == "kim_coat_suit":
        white_mask = luma > 0.62
        gain = np.clip(luma / 0.25, 0.42, 1.45)
        for c, tc in enumerate((0.13, 0.13, 0.16)):
            arr[:, :, c] = np.where(white_mask, 0.14, tc * gain)
    elif mode == "kim_p1_casual":
        # male_casualsuit05: blue jeans -> charcoal slacks, jacket -> obsidian black
        pants_mask = (yy > 0.53) & (xx < 0.65)
        gain = np.clip(luma / 0.35, 0.38, 1.40)
        for c, (jc, pc) in enumerate(zip((0.14, 0.14, 0.18), (0.28, 0.28, 0.33))):
            arr[:, :, c] = np.where(pants_mask, pc * gain, jc * gain)
    elif mode == "baek_shirt_pants":
        # male_casualsuit01: center column (0.33..0.72) = black slacks; top-left shoes = black leather; rest = white dress shirt
        pants_mask = (xx >= 0.33) & (xx <= 0.72)
        shoe_mask = (xx < 0.33) & (yy <= 0.30)
        shirt_mask = ~(pants_mask | shoe_mask)
        shirt_shade = np.clip(0.78 + (luma - 0.30) * 0.72, 0.68, 0.97)
        pants_gain = np.clip(luma / 0.32, 0.38, 1.38)
        for c, (sc, pc, bc) in enumerate(zip((0.96, 0.96, 0.98), (0.12, 0.12, 0.15), (0.08, 0.075, 0.08))):
            out = np.where(shirt_mask, sc * shirt_shade, np.where(pants_mask, pc * pants_gain, bc * pants_gain))
            arr[:, :, c] = out
    elif mode == "risa_mink_jacket":
        # Rich luxury mink brown coat jacket (trimmed to upper body) with soft cream collar highlight
        collar_mask = luma > 0.58
        gain = np.clip(luma / 0.30, 0.45, 1.38)
        for c, (mc, fc) in enumerate(zip((0.40, 0.24, 0.15), (0.86, 0.78, 0.66))):
            arr[:, :, c] = np.where(collar_mask, fc, mc * gain)
    elif mode == "client_blouse_skirt":
        # female_elegantsuit01: skirt -> dark charcoal, blouse -> ivory/beige distressed blouse
        skirt_mask = (yy < 0.52) & (xx < 0.78)
        sk_gain = np.clip(luma / 0.32, 0.45, 1.30)
        bl_gain = np.clip(0.76 + (luma - 0.30) * 0.55, 0.62, 1.05)
        for c, (bc, sc) in enumerate(zip((0.78, 0.74, 0.67), (0.18, 0.17, 0.20))):
            arr[:, :, c] = np.where(skirt_mask, sc * sk_gain, bc * bl_gain)
    elif mode == "jintae_pink_track":
        # male_casualsuit05: jeans -> jet black track pants, jacket -> dusty rose pink-beige
        pants_mask = (yy > 0.53) & (xx < 0.65)
        stripe_mask = (arr[:, :, 0] > arr[:, :, 1] + 0.08) & (~pants_mask)
        gain = np.clip(luma / 0.32, 0.35, 1.40)
        for c, (jc, pc, tc) in enumerate(zip((0.84, 0.56, 0.66), (0.10, 0.10, 0.12), (0.08, 0.08, 0.10))):
            arr[:, :, c] = np.where(pants_mask, pc * gain, np.where(stripe_mask, tc * gain, jc * gain))
    elif mode == "ojiin_blouse_skirt":
        # female_elegantsuit01: upper-left solid grey rectangle = burgundy pencil skirt; striped blouse -> sleek jet-black silk
        skirt_mask = (yy < 0.52) & (xx < 0.78)
        sk_gain = np.clip(luma / 0.32, 0.45, 1.30)
        bl_gain = np.clip(0.70 + luma * 0.65, 0.55, 1.25)
        for c, (bc, sc) in enumerate(zip((0.12, 0.12, 0.15), (0.44, 0.14, 0.19))):
            arr[:, :, c] = np.where(skirt_mask, sc * sk_gain, bc * bl_gain)
    elif mode == "baek_glasses":
        # Bright gleaming silver-white rimless glasses (Baek Dochan signature glint)
        arr[:, :, 0] = 0.94
        arr[:, :, 1] = 0.96
        arr[:, :, 2] = 1.00
        if arr.shape[2] == 4:
            arr[:, :, 3] = np.where(luma > 0.35, 0.45, 0.95)
    elif mode == "jintae_shades":
        # Dark black frames, amber-yellow lens tint (brighter pixels = lens, dark = frame)
        lens_mask = luma > 0.26
        for c, (fc, lc) in enumerate(zip((0.05, 0.05, 0.06), (0.98, 0.78, 0.14))):
            arr[:, :, c] = np.where(lens_mask, lc, fc)
    _set_img_pixels_np(img, arr)


def _apply_skin_details(img, tint, scar=False):
    arr = _img_pixels_np(img)
    for c in range(3):
        arr[:, :, c] = np.clip(arr[:, :, c] * tint[c], 0.0, 1.0)
    if scar:
        # Subtle realistic cheek scar on MakeHuman base UV left cheek region
        h, w, _ = arr.shape
        yy, xx = np.mgrid[0:h, 0:w]
        # MakeHuman base UV face sits in upper-right quadrant; subtle diagonal mark
        cx, cy = int(w * 0.56), int(h * 0.73)
        dx = (xx - cx) / max(w * 0.014, 1.0)
        dy = (yy - cy) / max(h * 0.022, 1.0)
        dist = np.abs(dx - dy * 0.7)
        within = (np.abs(dx) < 1.1) & (np.abs(dy) < 1.1) & (dist < 0.16)
        arr[:, :, 0] = np.where(within, arr[:, :, 0] * 0.72, arr[:, :, 0])
        arr[:, :, 1] = np.where(within, arr[:, :, 1] * 0.58, arr[:, :, 1])
        arr[:, :, 2] = np.where(within, arr[:, :, 2] * 0.55, arr[:, :, 2])
    _set_img_pixels_np(img, arr)


def _find_principled_textures(mat):
    """Return (bsdf, diffuse_img, normal_img) from a Makeskin Principled BSDF material."""
    if not mat or not mat.use_nodes:
        return None, None, None
    nt = mat.node_tree
    bsdf = next((n for n in nt.nodes if n.type == "BSDF_PRINCIPLED"), None)
    if bsdf is None:
        return None, None, None
    diff_img = None
    norm_img = None
    for n in nt.nodes:
        if n.type == "TEX_IMAGE" and n.image is not None:
            # Check downstream links to distinguish diffuse vs normal/bump
            links = [lk.to_node.type for out in n.outputs for lk in out.links]
            if any(t in ("NORMAL_MAP", "BUMP") for t in links) or "norm" in n.image.name.lower() or "bump" in n.image.name.lower():
                norm_img = n.image
            elif diff_img is None:
                diff_img = n.image
    return bsdf, diff_img, norm_img


def _clone_image(img, name_prefix):
    dup = img.copy()
    dup.name = f"{name_prefix}_{img.name}"
    return dup


def _sanitize_material_for_gltf(mat, kind, recolor=None, tint=None, scar=False):
    """Rebuild clean Principled BSDF material for crisp Godot 4 mobile PBR glTF export."""
    if not mat or not mat.use_nodes:
        return
    bsdf, diff_img, norm_img = _find_principled_textures(mat)
    if diff_img is not None:
        diff_img = _clone_image(diff_img, f"{kind}_diff")
        if kind == "skin" and tint is not None:
            _apply_skin_details(diff_img, tint, scar=scar)
        elif kind in ("hair", "eyebrows", "eyelashes") and recolor is not None:
            _recolor_hair_img(diff_img, recolor)
        elif kind in ("clothes", "glasses") and recolor is not None:
            _recolor_outfit_img(diff_img, recolor)
    if norm_img is not None:
        norm_img = _clone_image(norm_img, f"{kind}_norm")
        norm_img.colorspace_settings.name = "Non-Color"

    nt = mat.node_tree
    nt.nodes.clear()
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    p = nt.nodes.new("ShaderNodeBsdfPrincipled")
    nt.links.new(p.outputs["BSDF"], out.inputs["Surface"])

    # Mobile PBR roughness / metallic tuning per material class
    rough_map = {"skin": 0.56, "hair": 0.44, "eyebrows": 0.62, "eyelashes": 0.55,
                 "eyes": 0.10, "clothes": 0.72, "glasses": 0.14}
    p.inputs["Roughness"].default_value = rough_map.get(kind, 0.7)
    p.inputs["Metallic"].default_value = 0.12 if (kind == "glasses" and recolor == "baek_glasses") else 0.0
    if "Specular IOR Level" in p.inputs:
        p.inputs["Specular IOR Level"].default_value = 0.38 if kind == "skin" else (0.55 if kind == "eyes" else 0.42)

    if diff_img is not None:
        tex = nt.nodes.new("ShaderNodeTexImage")
        tex.image = diff_img
        nt.links.new(tex.outputs["Color"], p.inputs["Base Color"])
        if kind in ("hair", "eyebrows", "eyelashes"):
            nt.links.new(tex.outputs["Alpha"], p.inputs["Alpha"])
            mat.blend_method = "CLIP"
            if hasattr(mat, "alpha_threshold"):
                mat.alpha_threshold = 0.35
        elif kind == "glasses" and recolor == "baek_glasses":
            nt.links.new(tex.outputs["Alpha"], p.inputs["Alpha"])
            if "Emission Color" in p.inputs:
                p.inputs["Emission Color"].default_value = (0.88, 0.92, 1.0, 1.0)
                p.inputs["Emission Strength"].default_value = 0.16
            mat.blend_method = "BLEND"
    else:
        if recolor and isinstance(recolor, tuple) and len(recolor) == 3:
            p.inputs["Base Color"].default_value = (recolor[0], recolor[1], recolor[2], 1.0)
        elif recolor == "baek_glasses":
            p.inputs["Base Color"].default_value = (0.86, 0.88, 0.92, 1.0)
            p.inputs["Alpha"].default_value = 0.86
            mat.blend_method = "BLEND"
        elif recolor == "jintae_shades":
            p.inputs["Base Color"].default_value = (0.96, 0.76, 0.14, 1.0)
            p.inputs["Roughness"].default_value = 0.12

    if norm_img is not None and kind in ("skin", "clothes"):
        ntex = nt.nodes.new("ShaderNodeTexImage")
        ntex.image = norm_img
        nmap = nt.nodes.new("ShaderNodeNormalMap")
        nmap.inputs["Strength"].default_value = 0.45 if kind == "skin" else 0.65
        nt.links.new(ntex.outputs["Color"], nmap.inputs["Color"])
        nt.links.new(nmap.outputs["Normal"], p.inputs["Normal"])

    mat.use_backface_culling = kind not in ("hair", "clothes", "eyelashes")


def _make_simple_pbr_mat(name, col, roughness=0.65, metallic=0.0):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    p = next(n for n in mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    p.inputs["Base Color"].default_value = (col[0], col[1], col[2], 1.0)
    p.inputs["Roughness"].default_value = roughness
    p.inputs["Metallic"].default_value = metallic
    mat.use_backface_culling = False
    return mat


def _build_risa_fur_drape(rig_obj):
    """Build a sculpted draped mink-fur coat over Risa's shoulders (arms inside sleeves-free cape drape)."""
    p_chest = rig_obj.matrix_world @ rig_obj.data.bones["spine_03"].head_local
    p_neck = rig_obj.matrix_world @ rig_obj.data.bones["neck_01"].head_local
    p_sh_r = rig_obj.matrix_world @ rig_obj.data.bones["upperarm_r"].head_local
    p_sh_l = rig_obj.matrix_world @ rig_obj.data.bones["upperarm_l"].head_local
    p_hips = rig_obj.matrix_world @ rig_obj.data.bones["pelvis"].head_local
    p_calf = rig_obj.matrix_world @ rig_obj.data.bones["calf_r"].head_local

    sh_half = abs(p_sh_r.x - p_sh_l.x) * 0.5 + 0.055
    top_z = p_neck.z + 0.015
    bot_z = p_calf.z + 0.14
    cy = p_chest.y + 0.015

    # Continuous smooth loft around back & sides, open elegantly in front (-Y in MPFB space)
    bm = bmesh.new()
    rings = 14
    segs = 22
    ring_verts = []
    for r in range(rings):
        u = r / (rings - 1)
        z = top_z * (1.0 - u) + bot_z * u
        # Shoulder flare then graceful drape down to knees
        rx = sh_half * (0.94 + 0.24 * math.sin(u * math.pi * 0.55) + 0.18 * u)
        ry = 0.145 + 0.065 * u + 0.03 * math.sin(u * math.pi)
        # Front opening gap (-Y is front in pre-flip MPFB space; angle -pi/2 is front)
        # Arc spans from front-left (-0.34*pi) around back (+0.5*pi) to front-right (+1.34*pi)
        gap = 0.28 + 0.16 * u
        a0 = -math.pi * 0.5 + gap
        a1 = math.pi * 1.5 - gap
        row = []
        for s in range(segs):
            v = s / (segs - 1)
            ang = a0 + (a1 - a0) * v
            # Subtle fabric ripple along hem
            ripple = 0.008 * math.sin(v * math.pi * 6.0) * u
            x = math.cos(ang) * (rx + ripple)
            y = cy + math.sin(ang) * (ry + ripple)
            row.append(bm.verts.new((x, y, z)))
        ring_verts.append(row)

    for r in range(rings - 1):
        for s in range(segs - 1):
            bm.faces.new((ring_verts[r][s], ring_verts[r + 1][s], ring_verts[r + 1][s + 1], ring_verts[r][s + 1]))

    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    mesh = bpy.data.meshes.new("RisaCoatMesh")
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new("RisaCoat", mesh)
    bpy.context.collection.objects.link(obj)

    # Give coat subtle thickness & smooth shading
    sol = obj.modifiers.new("Solidify", "SOLIDIFY")
    sol.thickness = 0.018
    sol.offset = 1.0
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.modifier_apply(modifier="Solidify")
    for poly in obj.data.polygons:
        poly.use_smooth = True

    coat_mat = _make_simple_pbr_mat("RisaMinkCoat", (0.34, 0.20, 0.13), roughness=0.82)
    fur_mat = _make_simple_pbr_mat("RisaFurCollar", (0.86, 0.77, 0.64), roughness=0.92)
    obj.data.materials.append(coat_mat)
    obj.data.materials.append(fur_mat)
    for poly in obj.data.polygons:
        if poly.center.z > top_z - 0.085:
            poly.material_index = 1

    # Smooth skin weights to spine_03 / spine_01 / pelvis based on vertex height
    vg_chest = obj.vertex_groups.new(name="spine_03")
    vg_spine = obj.vertex_groups.new(name="spine_01")
    vg_hips = obj.vertex_groups.new(name="pelvis")
    for v in obj.data.vertices:
        z = v.co.z
        if z >= p_chest.z:
            vg_chest.add([v.index], 1.0, "REPLACE")
        elif z >= p_hips.z:
            k = (z - p_hips.z) / max(p_chest.z - p_hips.z, 0.01)
            vg_chest.add([v.index], k, "REPLACE")
            vg_spine.add([v.index], 1.0 - k, "REPLACE")
        else:
            k = max(0.0, min(1.0, (z - bot_z) / max(p_hips.z - bot_z, 0.01)))
            vg_hips.add([v.index], 0.75 + 0.25 * k, "REPLACE")
            vg_spine.add([v.index], 0.25 * (1.0 - k), "REPLACE")
    mod = obj.modifiers.new("Armature", "ARMATURE")
    mod.object = rig_obj
    return obj


def _build_baek_holster(rig_obj):
    """Build Baek Dochan's brown leather shoulder holster straps across chest/back."""
    p_chest = rig_obj.matrix_world @ rig_obj.data.bones["spine_03"].head_local
    p_sh_r = rig_obj.matrix_world @ rig_obj.data.bones["upperarm_r"].head_local
    p_sh_l = rig_obj.matrix_world @ rig_obj.data.bones["upperarm_l"].head_local
    p_spine = rig_obj.matrix_world @ rig_obj.data.bones["spine_01"].head_local

    bm = bmesh.new()
    # Two leather straps looping over shoulders & crossing in an X on upper back
    for sx in (-1.0, 1.0):
        pts = [
            Vector((sx * 0.145, p_chest.y - 0.125, p_spine.z + 0.04)),
            Vector((sx * 0.135, p_chest.y - 0.145, p_chest.z + 0.10)),
            Vector((sx * 0.125, p_chest.y - 0.04, p_sh_r.z + 0.095)),
            Vector((sx * 0.115, p_chest.y + 0.115, p_chest.z + 0.12)),
            Vector((0.0, p_chest.y + 0.135, p_chest.z + 0.04)),
            Vector((-sx * 0.145, p_chest.y + 0.115, p_spine.z + 0.03)),
        ]
        prev = None
        for i, pt in enumerate(pts):
            t = (pts[min(i + 1, len(pts) - 1)] - pts[max(i - 1, 0)]).normalized()
            nrm = Vector((pt.x, pt.y - p_chest.y, 0.0)).normalized()
            side = t.cross(nrm).normalized()
            w, th = 0.018, 0.007
            ring = [
                bm.verts.new(pt - side * w - nrm * th),
                bm.verts.new(pt + side * w - nrm * th),
                bm.verts.new(pt + side * w + nrm * th),
                bm.verts.new(pt - side * w + nrm * th),
            ]
            if prev is not None:
                for k in range(4):
                    bm.faces.new((prev[k], prev[(k + 1) % 4], ring[(k + 1) % 4], ring[k]))
            prev = ring

    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    mesh = bpy.data.meshes.new("BaekHolsterMesh")
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new("BaekHolster", mesh)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(_make_simple_pbr_mat("BaekLeatherHolster", (0.36, 0.20, 0.10), roughness=0.45))
    vg = obj.vertex_groups.new(name="spine_03")
    vg.add([v.index for v in obj.data.vertices], 1.0, "REPLACE")
    mod = obj.modifiers.new("Armature", "ARMATURE")
    mod.object = rig_obj
    return obj


def _align_bone_world_dir(rig_obj, bone_name, target_dir):
    """Rotate a PoseBone so its world-space direction (head->tail) aligns to target_dir."""
    pb = rig_obj.pose.bones.get(bone_name)
    if pb is None:
        return
    bpy.context.view_layer.update()
    mw = rig_obj.matrix_world @ pb.matrix
    cur_dir = (mw.to_3x3() @ Vector((0, 1, 0))).normalized()
    want = Vector(target_dir).normalized()
    q_world = cur_dir.rotation_difference(want)
    # Apply world-space delta to pose bone
    pb.rotation_mode = "QUATERNION"
    new_world_rot = q_world.to_matrix() @ mw.to_3x3()
    rest_world = (rig_obj.matrix_world @ pb.bone.matrix_local).to_3x3()
    if pb.parent:
        parent_world = (rig_obj.matrix_world @ pb.parent.matrix).to_3x3()
        parent_rest = (rig_obj.matrix_world @ pb.parent.bone.matrix_local).to_3x3()
        local_rest = parent_rest.inverted() @ rest_world
        local_new = parent_world.inverted() @ new_world_rot
        pb.rotation_quaternion = (local_rest.inverted() @ local_new).to_quaternion()
    else:
        pb.rotation_quaternion = (rest_world.inverted() @ new_world_rot).to_quaternion()
    bpy.context.view_layer.update()


def _pose_arms_down_and_relaxed_hands(rig_obj):
    """Bring MPFB2 A-pose arms & legs into clean vertical arms-down neutral rest pose."""
    bpy.context.view_layer.objects.active = rig_obj
    bpy.ops.object.mode_set(mode="POSE")
    # Arms down with gentle 5 deg clearance from hips so suit sleeves never clip thighs
    _align_bone_world_dir(rig_obj, "upperarm_r", (-0.07, 0.0, -1.0))
    _align_bone_world_dir(rig_obj, "lowerarm_r", (-0.02, -0.04, -1.0))
    _align_bone_world_dir(rig_obj, "upperarm_l", (0.07, 0.0, -1.0))
    _align_bone_world_dir(rig_obj, "lowerarm_l", (0.02, -0.04, -1.0))
    # Straighten slight A-stance legs to clean vertical standing stance
    _align_bone_world_dir(rig_obj, "thigh_r", (0.0, 0.0, -1.0))
    _align_bone_world_dir(rig_obj, "calf_r", (0.0, 0.0, -1.0))
    _align_bone_world_dir(rig_obj, "thigh_l", (0.0, 0.0, -1.0))
    _align_bone_world_dir(rig_obj, "calf_l", (0.0, 0.0, -1.0))

    # Gentle natural curl on fingers (relaxed semi-fist for combat/weapons)
    for side in ("r", "l"):
        for finger in ("index", "middle", "ring", "pinky"):
            for seg, deg in (("01", 32.0), ("02", 45.0), ("03", 30.0)):
                pb = rig_obj.pose.bones.get(f"{finger}_{seg}_{side}")
                if pb:
                    pb.rotation_mode = "XYZ"
                    pb.rotation_euler.x += math.radians(deg)
    bpy.context.view_layer.update()
    bpy.ops.object.mode_set(mode="OBJECT")


def _record_joint_positions(rig_obj):
    """Capture world-space joint coordinates in the posed arms-down stance."""
    bpy.context.view_layer.update()
    pos = {}
    for target_name, src_name in JOINT_SRC.items():
        pb = rig_obj.pose.bones[src_name]
        pos[target_name] = (rig_obj.matrix_world @ pb.head).copy()
    return pos


def _remap_vertex_groups(obj):
    """Merge MPFB2 game_engine vertex groups into our 17-bone groups cleanly."""
    mesh = obj.data
    old_names = {vg.index: vg.name for vg in obj.vertex_groups}
    per_vert = []
    for v in mesh.vertices:
        acc = {}
        for g in v.groups:
            tgt = WEIGHT_MAP.get(old_names.get(g.group, ""))
            if tgt and g.weight > 1e-5:
                acc[tgt] = acc.get(tgt, 0.0) + g.weight
        if not acc:
            acc["hips"] = 1.0
        # Keep top 4 weights normalized
        top = sorted(acc.items(), key=lambda kv: kv[1], reverse=True)[:4]
        s = sum(w for _, w in top)
        per_vert.append([(k, w / s) for k, w in top])

    obj.vertex_groups.clear()
    new_vgs = {name: obj.vertex_groups.new(name=name) for name, _ in TARGET_BONES}
    for vi, items in enumerate(per_vert):
        for name, w in items:
            new_vgs[name].add([vi], w, "REPLACE")


def _build_17_bone_armature(name, joint_pos):
    """Build clean 17-bone Armature where every bone has Identity rest rotation in Godot 4 (+Z tail, roll 0)."""
    arm_data = bpy.data.armatures.new(name + "_Armature")
    arm_obj = bpy.data.objects.new("Skeleton3D", arm_data)
    bpy.context.collection.objects.link(arm_obj)
    bpy.context.view_layer.objects.active = arm_obj
    bpy.ops.object.mode_set(mode="EDIT")
    ebones = {}
    for bname, pname in TARGET_BONES:
        eb = arm_data.edit_bones.new(bname)
        p = joint_pos[bname]
        eb.head = p
        eb.tail = p + Vector((0.0, 0.0, 0.12))  # +Z in Blender == +Y in Godot -> Identity Basis!
        eb.roll = 0.0
        if pname:
            eb.parent = ebones[pname]
        ebones[bname] = eb
    bpy.ops.object.mode_set(mode="OBJECT")
    return arm_obj


def _resize_and_compress_images(tmp_dir):
    """Downscale textures for crisp mobile Android performance and compact GLB size."""
    for img in list(bpy.data.images):
        if img.size[0] == 0 or img.size[1] == 0:
            continue
        nm = img.name.lower()
        is_skin = nm.startswith("skin_")
        is_alpha = nm.startswith(("hair_", "eyebrows_", "eyelashes_", "glasses_"))
        max_dim = 1024 if is_skin else 512
        w, h = img.size
        if w > max_dim or h > max_dim:
            scale = max_dim / max(w, h)
            img.scale(max(64, int(w * scale)), max(64, int(h * scale)))
        # Save as PNG for alpha-cutout or normal maps, high-quality JPEG for opaque diffuse
        is_norm = "_norm_" in nm
        ext = "png" if (is_alpha or is_norm) else "jpg"
        safe_name = "".join(c if c.isalnum() or c in "._-" else "_" for c in img.name)
        fpath = os.path.join(tmp_dir, f"{safe_name}.{ext}")
        img.filepath_raw = fpath
        img.file_format = "PNG" if ext == "png" else "JPEG"
        bpy.context.scene.render.image_settings.quality = 88
        try:
            img.save()
        except Exception as exc:
            print(f"  WARN save img {img.name}: {exc}")


def build_character(char_id, spec):
    print(f"=== BAKE REALISTIC: {char_id} -> {spec['out']} ===")
    bpy.ops.wm.read_factory_settings(use_empty=True)
    tmp_dir = tempfile.mkdtemp(prefix=f"mpfb_{char_id}_")

    try:
        # 1. Create anatomical MPFB2 human
        md = TargetService.get_default_macro_info_dict()
        for k, v in spec["macro"].items():
            md[k] = v
        basemesh = HumanService.create_human(mask_helpers=True, detailed_helpers=True,
                                             extra_vertex_groups=True, feet_on_ground=True,
                                             scale=0.1, macro_detail_dict=md)

        # 2. Apply realistic PBR skin
        HumanService.set_character_skin(asset_path(spec["skin"]), basemesh, skin_type="MAKESKIN")
        for m in basemesh.data.materials:
            _sanitize_material_for_gltf(m, "skin", tint=spec.get("skin_tint"), scar=spec.get("scar", False))

        # 3. Add game_engine rig first so all attached assets auto-inherit weights!
        rig_obj = HumanService.add_builtin_rig(basemesh, "game_engine", import_weights=True)

        # 4. Attach eyes, eyebrows, eyelashes, hair, clothes, shoes, glasses
        part_objs = [basemesh]
        glasses_obj = None

        eyes = HumanService.add_mhclo_asset(asset_path("eyes/low-poly/low-poly.mhclo"), basemesh,
                                            asset_type="Eyes", subdiv_levels=0, material_type="MAKESKIN",
                                            set_up_rigging=True, interpolate_weights=True)
        # Load specific eye material (brown / ice blue)
        from bl_ext.user_default.mpfb.entities.material.makeskinmaterial import MakeSkinMaterial
        eye_mat = bpy.data.materials.new(f"EyeMat_{char_id}")
        eye_mat.use_nodes = True
        ms_eye = MakeSkinMaterial()
        ms_eye.populate_from_mhmat(asset_path(spec["eye_mat"]))
        ms_eye.apply_node_tree(eye_mat)
        eyes.data.materials.clear()
        eyes.data.materials.append(eye_mat)
        _sanitize_material_for_gltf(eye_mat, "eyes")
        part_objs.append(eyes)

        if spec.get("eyebrows"):
            eb_path, eb_col = spec["eyebrows"]
            eb = HumanService.add_mhclo_asset(asset_path(eb_path), basemesh, asset_type="Eyebrows",
                                              subdiv_levels=0, material_type="MAKESKIN",
                                              set_up_rigging=True, interpolate_weights=True)
            for m in eb.data.materials:
                _sanitize_material_for_gltf(m, "eyebrows", recolor=eb_col)
            part_objs.append(eb)

        if spec.get("eyelashes"):
            el_path, el_col = spec["eyelashes"]
            el = HumanService.add_mhclo_asset(asset_path(el_path), basemesh, asset_type="Eyelashes",
                                              subdiv_levels=0, material_type="MAKESKIN",
                                              set_up_rigging=True, interpolate_weights=True)
            for m in el.data.materials:
                _sanitize_material_for_gltf(m, "eyelashes", recolor=el_col)
            part_objs.append(el)

        if spec.get("hair"):
            h_path, h_col = spec["hair"]
            hair = HumanService.add_mhclo_asset(asset_path(h_path), basemesh, asset_type="Hair",
                                                subdiv_levels=0, material_type="MAKESKIN",
                                                set_up_rigging=True, interpolate_weights=True)
            for m in hair.data.materials:
                _sanitize_material_for_gltf(m, "hair", recolor=h_col)
            part_objs.append(hair)

        for c_path, c_mode in spec["clothes"]:
            cl = HumanService.add_mhclo_asset(asset_path(c_path), basemesh, asset_type="Clothes",
                                              subdiv_levels=0, material_type="MAKESKIN",
                                              set_up_rigging=True, interpolate_weights=True)
            for m in cl.data.materials:
                _sanitize_material_for_gltf(m, "clothes", recolor=c_mode)
            if c_mode == "risa_mink_jacket":
                # Keep tailored mink coat jacket over black dress, delete lower trouser portion below hips
                hips_z = (rig_obj.matrix_world @ rig_obj.data.bones["pelvis"].head_local).z
                bm = bmesh.new()
                bm.from_mesh(cl.data)
                kill = [v for v in bm.verts if v.co.z < hips_z - 0.14]
                if kill:
                    bmesh.ops.delete(bm, geom=kill, context="VERTS")
                bm.to_mesh(cl.data)
                bm.free()
                cl.data.update()
                # Also trim inner black dress upper torso behind coat so zero black patches poke through mink jacket
                for prev in part_objs:
                    if "shift_dress" in prev.name.lower():
                        bm_d = bmesh.new()
                        bm_d.from_mesh(prev.data)
                        kill_d = [v for v in bm_d.verts if v.co.z > hips_z - 0.05]
                        if kill_d:
                            bmesh.ops.delete(bm_d, geom=kill_d, context="VERTS")
                        bm_d.to_mesh(prev.data)
                        bm_d.free()
                        prev.data.update()
                # Outward puff so tailored mink coat layers cleanly over skirt hem
                disp = cl.modifiers.new("CoatLayerOffset", "DISPLACE")
                disp.strength = 0.010
                disp.mid_level = 0.0
                # Remove the suit's Delete mask on basemesh so Risa's bare legs under the black mini-dress remain visible!
                for mod in list(basemesh.modifiers):
                    if mod.type == "MASK" and "double-breasted" in mod.name.lower():
                        basemesh.modifiers.remove(mod)
            elif c_mode == "baek_shirt_pants":
                # Outward shirt clearance on upper torso so muscular shoulder blades never poke through shirt
                disp = cl.modifiers.new("ShirtClearance", "DISPLACE")
                disp.strength = 0.014
                disp.mid_level = 0.0
            part_objs.append(cl)

        if spec.get("glasses"):
            g_path, g_mode = spec["glasses"]
            glasses_obj = HumanService.add_mhclo_asset(asset_path(g_path), basemesh, asset_type="Clothes",
                                                       subdiv_levels=0, material_type="MAKESKIN",
                                                       set_up_rigging=True, interpolate_weights=True)
            for m in glasses_obj.data.materials:
                _sanitize_material_for_gltf(m, "glasses", recolor=g_mode)

        # Custom sculpted accessories (kept extensible for future accessories)
        for ex in spec.get("extras", []):
            if ex == "risa_fur_drape":
                part_objs.append(_build_risa_fur_drape(rig_obj))
            elif ex == "shoulder_holster":
                part_objs.append(_build_baek_holster(rig_obj))

        # 5. Pose into vertical arms-down neutral rest pose
        _pose_arms_down_and_relaxed_hands(rig_obj)
        joint_pos = _record_joint_positions(rig_obj)

        # 6. Bake shape keys, then apply all modifiers (MASK deletes hidden body skin under suits, ARMATURE bakes arms-down pose!)
        all_meshes = part_objs + ([glasses_obj] if glasses_obj else [])
        for obj in all_meshes:
            bpy.ops.object.select_all(action="DESELECT")
            bpy.context.view_layer.objects.active = obj
            obj.select_set(True)
            if obj.data.shape_keys:
                bpy.ops.object.shape_key_remove(all=True, apply_mix=True)
            # Remove any SUBSURF to keep mobile polycount lean
            for mod in list(obj.modifiers):
                if mod.type == "SUBSURF":
                    obj.modifiers.remove(mod)
            # Apply remaining modifiers in order (MASK + ARMATURE)
            for mod in list(obj.modifiers):
                try:
                    bpy.ops.object.modifier_apply(modifier=mod.name)
                except Exception as exc:
                    print(f"  WARN apply {obj.name}.{mod.name}: {exc}")
                    obj.modifiers.remove(mod)
            # Clear parent while keeping transform
            obj.parent = None
            obj.matrix_world = Matrix.Identity(4)

        # Remove old MPFB2 game_engine armature
        bpy.data.objects.remove(rig_obj, do_unlink=True)

        # 7. Flip 180 deg around Z (MPFB2 -Y forward -> +Y forward == Godot -Z forward) & normalize height/ground
        rot_flip = Matrix.Rotation(math.pi, 4, "Z")
        for obj in all_meshes:
            obj.data.transform(rot_flip)
            obj.data.update()
        for k in joint_pos:
            joint_pos[k] = rot_flip @ joint_pos[k]

        # Measure real min Z and max Z across all meshes to plant feet cleanly at Z=0 and scale height
        z_min = min((v.co.z for o in all_meshes for v in o.data.vertices), default=0.0)
        z_max = max((v.co.z for o in all_meshes for v in o.data.vertices), default=1.74)
        cur_h = max(z_max - z_min, 0.5)
        scale_k = spec["height_m"] / cur_h

        xform = Matrix.Scale(scale_k, 4) @ Matrix.Translation((0.0, 0.0, -z_min))
        for obj in all_meshes:
            obj.data.transform(xform)
            obj.data.update()
        for k in joint_pos:
            joint_pos[k] = xform @ joint_pos[k]

        # Sanity assert: right shoulder at +X, left shoulder at -X
        assert joint_pos["sh_r"].x > 0.05 and joint_pos["sh_l"].x < -0.05, \
            f"Left/right orientation error: sh_r={joint_pos['sh_r']}, sh_l={joint_pos['sh_l']}"

        # 8. Join all body/clothes/hair into ONE SkinnedMesh "PBR_Body" (keep Glasses separate for remove_glasses!)
        bpy.ops.object.select_all(action="DESELECT")
        for o in part_objs:
            o.select_set(True)
        bpy.context.view_layer.objects.active = basemesh
        bpy.ops.object.join()
        body_obj = bpy.context.view_layer.objects.active
        body_obj.name = "PBR_Body"

        # Mobile polycount check — lightly decimate ONLY if over 22k tris
        tri_count = sum(len(p.vertices) - 2 for p in body_obj.data.polygons)
        if tri_count > 22000:
            dec = body_obj.modifiers.new("MobileDecimate", "DECIMATE")
            dec.ratio = 18000.0 / tri_count
            bpy.context.view_layer.objects.active = body_obj
            bpy.ops.object.modifier_apply(modifier="MobileDecimate")
            tri_count = sum(len(p.vertices) - 2 for p in body_obj.data.polygons)

        # 9. Remap vertex groups to our 17 bones & bind to clean Identity-rest Skeleton3D
        _remap_vertex_groups(body_obj)
        if glasses_obj:
            glasses_obj.name = "Glasses"
            glasses_obj.vertex_groups.clear()
            vg_h = glasses_obj.vertex_groups.new(name="head")
            vg_h.add([v.index for v in glasses_obj.data.vertices], 1.0, "REPLACE")

        new_arm = _build_17_bone_armature(char_id, joint_pos)
        for o in [body_obj] + ([glasses_obj] if glasses_obj else []):
            o.parent = new_arm
            mod = o.modifiers.new("Armature", "ARMATURE")
            mod.object = new_arm

        # 10. Downscale & compress packed textures for mobile Android
        _resize_and_compress_images(tmp_dir)

        # 11. Export GLB
        out_path = os.path.join(REPO_ROOT, spec["out"])
        os.makedirs(os.path.dirname(out_path), exist_ok=True)
        bpy.ops.export_scene.gltf(
            filepath=out_path,
            export_format="GLB",
            export_yup=True,
            export_apply=False,
            export_skins=True,
            export_all_influences=False,
            export_materials="EXPORT",
            export_image_format="AUTO",
            export_jpeg_quality=88,
            export_texcoords=True,
            export_normals=True,
            export_tangents=False,
            export_animations=False,
        )
        kb = os.path.getsize(out_path) // 1024
        print(f"  OK {spec['out']}: {tri_count} tris, {kb} KB, hips_z={joint_pos['hips'].z:.3f}m, sh_r_x={joint_pos['sh_r'].x:+.3f}m")
    finally:
        shutil.rmtree(tmp_dir, ignore_errors=True)


def main():
    argv = sys.argv
    only = argv[argv.index("--") + 1:] if "--" in argv else []
    targets = [k for k in PILOT_SPECS if not only or k in only]
    for cid in targets:
        build_character(cid, PILOT_SPECS[cid])


if __name__ == "__main__":
    main()
