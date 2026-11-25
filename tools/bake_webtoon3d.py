"""Stage 3 Local Webtoon 3D Pilot Baker (Blender 4.2 headless CLI).

Transforms MPFB2 anatomical bases into authentic Castle (정연) 3D noir-webtoon fighters:
  1. 8.4-head stylized manhwa hero proportions (sharp jawline, heroic V-taper, sleek limbs).
  2. Closed smooth face plane + frontal-planar projection of ACTUAL original Jeongyeon webtoon
     face artwork (.tools/webtoon_faces/<face>_face.png) seamlessly blended into webtoon skin.
  3. Bold 3D sculpted manga/webtoon hair clumps matching each character's exact silhouette
     (Kim Shin jagged bangs, Baek Dochan parted crown + glowing white glasses, Jintae two-block
     blonde undercut + amber shades, Ojiin chignon bun + framing lock, Risa cascading blonde waves).
  4. Inked comic outfit textures (posterized cel folds + Sobel ink seams + Baek's heavy-ink shirt
     muscle contours + sculpted leather X-holster + Risa's draped beige mink coat + Kim's long trench).
  5. Clean 17-bone Identity-rest Skeleton3D ("Webtoon_Body" + optional "Glasses") driving Godot's
     src/view/shaders/webtoon_3d.gdshader + ink_line.gdshader + CC0 MocapDriver.

Usage:
    LD_LIBRARY_PATH=$HOME/.local-opt/xvfb/root/usr/lib64 \
    BLENDER_USER_CONFIG=/data/users/juho.hong/tools/blender/user_config \
    BLENDER_USER_DATA=/data/users/juho.hong/tools/blender/user_data \
    BLENDER_USER_SCRIPTS=/data/users/juho.hong/tools/blender/user_scripts \
    BLENDER_USER_EXTENSIONS=/data/users/juho.hong/tools/blender/user_extensions \
    /data/users/juho.hong/tools/blender/blender-4.2.23-linux-x64/blender \
      -b --python tools/bake_webtoon3d.py -- [kim baek risa_p1 ...]
"""
import json
import math
import os
import shutil
import sys
import tempfile

import bmesh
import bpy
import numpy as np
from mathutils import Matrix, Vector

from bl_ext.user_default.mpfb.services.humanservice import HumanService
from bl_ext.user_default.mpfb.services.locationservice import LocationService
from bl_ext.user_default.mpfb.services.targetservice import TargetService

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA_DIR = LocationService.get_user_data()
FACES_DIR = os.path.join(REPO_ROOT, ".tools", "webtoon_faces")

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
for _f in ("thumb", "index", "middle", "ring", "pinky"):
    for _s in ("01", "02", "03"):
        WEIGHT_MAP[f"{_f}_{_s}_r"] = "hand_r"
        WEIGHT_MAP[f"{_f}_{_s}_l"] = "hand_l"


WEBTOON_SPECS = {
    "kim": {
        "out": "assets/models/kimshin_a.glb",
        "face": "kim",
        "height_m": 1.83,
        "macro": {"gender": 1.0, "age": 0.36, "muscle": 0.76, "weight": 0.44, "height": 0.72,
                  "proportions": 0.58, "race": {"asian": 0.90, "caucasian": 0.10, "african": 0.0}},
        "stylize": {"shoulder_x": 1.07, "waist_x": 0.94, "head_s": 0.94, "jaw_taper": 0.14},
        "hair": {"style": "kim_bangs", "col": (0.12, 0.13, 0.17)},
        "clothes": [
            ("clothes/male_elegantsuit01/male_elegantsuit01.mhclo", "kim_suit"),
            ("clothes/shoes04/shoes04.mhclo", ("leather", (0.08, 0.08, 0.10))),
        ],
        "glasses": None,
        "extras": [],
    },
    "kim_coat": {
        "out": "assets/models/kimshin_coat_a.glb",
        "face": "kim",
        "height_m": 1.83,
        "macro": {"gender": 1.0, "age": 0.36, "muscle": 0.76, "weight": 0.44, "height": 0.72,
                  "proportions": 0.58, "race": {"asian": 0.90, "caucasian": 0.10, "african": 0.0}},
        "stylize": {"shoulder_x": 1.08, "waist_x": 0.96, "head_s": 0.94, "jaw_taper": 0.14},
        "hair": {"style": "kim_bangs", "col": (0.12, 0.13, 0.17)},
        "clothes": [
            ("clothes/toigo_male_double-breasted_suit/toigo_male_double-breasted_suit.mhclo", "kim_coat_suit"),
            ("clothes/shoes04/shoes04.mhclo", ("leather", (0.08, 0.08, 0.10))),
        ],
        "glasses": None,
        "extras": ["long_coat_skirt"],
    },
    "kim_bare": {
        "out": "assets/models/kimshin_p1_a.glb",
        "face": "kim",
        "height_m": 1.83,
        "macro": {"gender": 1.0, "age": 0.35, "muscle": 0.76, "weight": 0.44, "height": 0.72,
                  "proportions": 0.58, "race": {"asian": 0.90, "caucasian": 0.10, "african": 0.0}},
        "stylize": {"shoulder_x": 1.07, "waist_x": 0.94, "head_s": 0.94, "jaw_taper": 0.14},
        "hair": {"style": "kim_bangs", "col": (0.12, 0.13, 0.17)},
        "clothes": [
            ("clothes/male_casualsuit05/male_casualsuit05.mhclo", "kim_p1_casual"),
            ("clothes/shoes02/shoes02.mhclo", ("leather", (0.12, 0.12, 0.15))),
        ],
        "glasses": None,
        "extras": [],
    },
    "baek": {
        "out": "assets/models/baekdochan_a.glb",
        "face": "baek",
        "height_m": 1.90,
        "macro": {"gender": 1.0, "age": 0.52, "muscle": 0.96, "weight": 0.58, "height": 0.86,
                  "proportions": 0.64, "race": {"asian": 0.85, "caucasian": 0.15, "african": 0.0}},
        "stylize": {"shoulder_x": 1.15, "waist_x": 0.95, "head_s": 0.92, "jaw_taper": 0.04},
        "hair": {"style": "baek_parted", "col": (0.28, 0.21, 0.17)},
        "clothes": [
            ("clothes/male_casualsuit01/male_casualsuit01.mhclo", "baek_shirt_pants"),
            ("clothes/shoes03/shoes03.mhclo", ("leather", (0.07, 0.07, 0.09))),
        ],
        "glasses": "baek_white",
        "extras": ["shoulder_holster"],
    },
    "jintae": {
        "out": "assets/models/jintae_a.glb",
        "face": "jintae",
        "height_m": 1.79,
        "macro": {"gender": 1.0, "age": 0.30, "muscle": 0.72, "weight": 0.44, "height": 0.64,
                  "proportions": 0.56, "race": {"asian": 0.92, "caucasian": 0.08, "african": 0.0}},
        "stylize": {"shoulder_x": 1.06, "waist_x": 0.94, "head_s": 0.95, "jaw_taper": 0.16},
        "hair": {"style": "jintae_undercut", "col": (0.88, 0.76, 0.44), "col2": (0.14, 0.13, 0.15)},
        "clothes": [
            ("clothes/male_casualsuit05/male_casualsuit05.mhclo", "jintae_pink_track"),
            ("clothes/shoes02/shoes02.mhclo", ("leather", (0.86, 0.86, 0.88))),
        ],
        "glasses": "jintae_amber",
        "extras": [],
    },
    "ojiin": {
        "out": "assets/models/ojiin_a.glb",
        "face": "ojiin",
        "height_m": 1.69,
        "macro": {"gender": 0.0, "age": 0.36, "muscle": 0.32, "weight": 0.36, "height": 0.56,
                  "proportions": 0.58, "cupsize": 0.64, "firmness": 0.78,
                  "race": {"asian": 0.95, "caucasian": 0.05, "african": 0.0}},
        "stylize": {"shoulder_x": 0.97, "waist_x": 0.91, "head_s": 0.93, "jaw_taper": 0.20},
        "hair": {"style": "ojiin_bun", "col": (0.08, 0.08, 0.11)},
        "clothes": [
            ("clothes/female_elegantsuit01/female_elegantsuit01.mhclo", "ojiin_blouse_skirt"),
            ("clothes/toigo_stiletto_booties/toigo_stiletto_booties.mhclo", ("leather", (0.08, 0.07, 0.09))),
        ],
        "glasses": None,
        "extras": [],
    },
    "risa_p1": {
        "out": "assets/models/risa_p1_a.glb",
        "face": "risa",
        "height_m": 1.72,
        "macro": {"gender": 0.0, "age": 0.38, "muscle": 0.34, "weight": 0.40, "height": 0.64,
                  "proportions": 0.60, "cupsize": 0.74, "firmness": 0.82,
                  "race": {"asian": 0.04, "caucasian": 0.96, "african": 0.0}},
        "stylize": {"shoulder_x": 0.98, "waist_x": 0.91, "head_s": 0.93, "jaw_taper": 0.18},
        "hair": {"style": "risa_glamour", "col": (0.86, 0.74, 0.48)},
        "clothes": [
            ("clothes/toigo_shift_dress/toigo_shift_dress.mhclo", ("tint", (0.07, 0.07, 0.09))),
            ("clothes/toigo_female_double-breasted_suit/toigo_female_double-breasted_suit.mhclo", "risa_mink_jacket"),
            ("clothes/toigo_stiletto_booties/toigo_stiletto_booties.mhclo", ("leather", (0.07, 0.06, 0.08))),
        ],
        "glasses": None,
        "extras": ["risa_fur_collar"],
    },
    "risa": {
        "out": "assets/models/risa_a.glb",
        "face": "risa",
        "height_m": 1.72,
        "macro": {"gender": 0.0, "age": 0.38, "muscle": 0.34, "weight": 0.40, "height": 0.64,
                  "proportions": 0.60, "cupsize": 0.74, "firmness": 0.82,
                  "race": {"asian": 0.04, "caucasian": 0.96, "african": 0.0}},
        "stylize": {"shoulder_x": 0.98, "waist_x": 0.91, "head_s": 0.93, "jaw_taper": 0.18},
        "hair": {"style": "risa_glamour", "col": (0.86, 0.74, 0.48)},
        "clothes": [
            ("clothes/toigo_female_double-breasted_suit/toigo_female_double-breasted_suit.mhclo", ("tint", (0.14, 0.13, 0.17))),
            ("clothes/toigo_stiletto_booties/toigo_stiletto_booties.mhclo", ("leather", (0.07, 0.06, 0.08))),
        ],
        "glasses": None,
        "extras": [],
    },
    "client_woman": {
        "out": "assets/models/client_woman_a.glb",
        "face": "client_woman",
        "height_m": 1.66,
        "macro": {"gender": 0.0, "age": 0.42, "muscle": 0.28, "weight": 0.36, "height": 0.54,
                  "proportions": 0.55, "cupsize": 0.54, "firmness": 0.68,
                  "race": {"asian": 0.08, "caucasian": 0.92, "african": 0.0}},
        "stylize": {"shoulder_x": 0.96, "waist_x": 0.93, "head_s": 0.94, "jaw_taper": 0.16},
        "hair": {"style": "client_messy", "col": (0.12, 0.10, 0.11)},
        "clothes": [
            ("clothes/female_elegantsuit01/female_elegantsuit01.mhclo", "client_hoodie_skirt"),
            ("clothes/toigo_flats/toigo_flats.mhclo", ("leather", (0.10, 0.09, 0.11))),
        ],
        "glasses": None,
        "extras": [],
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


def _sobel_ink_lines(luma, strength=0.38, thresh=0.06):
    """Extract crisp hand-inked crease/seam lines from cloth luminance via Sobel gradient."""
    gx = np.abs(np.roll(luma, -1, axis=1) - np.roll(luma, 1, axis=1))
    gy = np.abs(np.roll(luma, -1, axis=0) - np.roll(luma, 1, axis=0))
    mag = np.sqrt(gx * gx + gy * gy)
    ink = np.clip((mag - thresh) / max(thresh * 2.2, 0.02), 0.0, 1.0)
    return 1.0 - ink * strength


def _cel_band(luma, low=0.22, mid=0.45, hi=0.68):
    """Quantize smooth photo cloth shading into crisp 3-step Jeongyeon webtoon cel bands."""
    return np.where(luma < low, 0.62, np.where(luma < mid, 0.86, np.where(luma < hi, 1.02, 1.14)))


def _stylize_outfit_img(img, mode):
    arr = _img_pixels_np(img)
    h, w, _ = arr.shape
    luma = 0.299 * arr[:, :, 0] + 0.587 * arr[:, :, 1] + 0.114 * arr[:, :, 2]
    yy = np.linspace(1.0, 0.0, h, dtype=np.float32)[:, None]  # top=0 -> bottom=1 (Blender bottom-up inverted)
    xx = np.linspace(0.0, 1.0, w, dtype=np.float32)[None, :]
    ink = _sobel_ink_lines(luma, strength=0.44, thresh=0.05)
    band = _cel_band(luma)

    if isinstance(mode, tuple) and mode[0] in ("tint", "leather"):
        col = mode[1]
        for c in range(3):
            arr[:, :, c] = col[c] * band * ink
    elif mode == "kim_suit":
        # Crisp obsidian-noir suit + bright white collar + bold black tie + cel folds
        white_mask = luma > 0.50
        for c, tc in enumerate((0.12, 0.125, 0.165)):
            base = np.where(white_mask, 0.94 * (0.90 + 0.10 * band), tc * band)
            arr[:, :, c] = base * ink
    elif mode == "kim_coat_suit":
        # Jet-black prologue turtleneck + black double-breasted coat (zero white shirt!)
        for c, tc in enumerate((0.095, 0.098, 0.125)):
            arr[:, :, c] = tc * band * ink
    elif mode == "kim_p1_casual":
        # Black turtleneck + sleek black jacket + dark charcoal slacks
        pants_mask = (yy > 0.53) & (xx < 0.65)
        for c, (jc, pc) in enumerate(zip((0.11, 0.115, 0.15), (0.24, 0.245, 0.29))):
            arr[:, :, c] = np.where(pants_mask, pc, jc) * band * ink
    elif mode == "baek_shirt_pants":
        # Iconic Baek Dochan: stark crisp white shirt with BOLD BLACK INK muscle crease shadows + jet-black slacks!
        pants_mask = (xx >= 0.33) & (xx <= 0.72)
        shoe_mask = (xx < 0.33) & (yy <= 0.30)
        shirt_mask = ~(pants_mask | shoe_mask)
        # Heavy comic ink creases on the white dress shirt (Jeongyeon style!)
        shirt_ink = _sobel_ink_lines(luma, strength=0.62, thresh=0.04)
        shirt_cel = np.where(luma < 0.24, 0.56, np.where(luma < 0.38, 0.84, 0.97))
        for c, (sc, pc, bc) in enumerate(zip((0.95, 0.96, 0.99), (0.09, 0.092, 0.115), (0.07, 0.07, 0.08))):
            out = np.where(shirt_mask, sc * shirt_cel * shirt_ink,
                           np.where(pants_mask, pc * band * ink, bc * band * ink))
            arr[:, :, c] = out
    elif mode == "jintae_pink_track":
        # Iconic dusty rose-pink jacket + jet black track pants + crisp white stripes
        pants_mask = (yy > 0.53) & (xx < 0.65)
        stripe_mask = (arr[:, :, 0] > arr[:, :, 1] + 0.08) & (~pants_mask)
        for c, (jc, pc, tc) in enumerate(zip((0.86, 0.56, 0.66), (0.09, 0.092, 0.115), (0.94, 0.94, 0.96))):
            arr[:, :, c] = np.where(pants_mask, pc, np.where(stripe_mask, tc, jc)) * band * ink
    elif mode == "ojiin_blouse_skirt":
        # Jet-black V-neck silk wrap blouse + deep burgundy pencil skirt
        skirt_mask = (yy < 0.52) & (xx < 0.78)
        for c, (bc, sc) in enumerate(zip((0.10, 0.10, 0.13), (0.48, 0.13, 0.18))):
            arr[:, :, c] = np.where(skirt_mask, sc, bc) * band * ink
    elif mode == "risa_mink_jacket":
        # Champagne-beige luxury mink coat jacket (ep002/008 exact tone!) with warm cream collar & crisp comic folds
        collar_mask = luma > 0.56
        for c, (mc, fc) in enumerate(zip((0.78, 0.68, 0.55), (0.90, 0.82, 0.70))):
            arr[:, :, c] = np.where(collar_mask, fc, mc) * band * ink
    elif mode == "client_hoodie_skirt":
        # Dark slate-navy open hoodie/jacket + deep charcoal skirt matching ep002/011!
        skirt_mask = (yy < 0.52) & (xx < 0.78)
        for c, (bc, sc) in enumerate(zip((0.20, 0.21, 0.26), (0.12, 0.12, 0.15))):
            arr[:, :, c] = np.where(skirt_mask, sc, bc) * band * ink
    _set_img_pixels_np(img, arr)


def _find_diffuse_img(mat):
    if not mat or not mat.use_nodes:
        return None
    for n in mat.node_tree.nodes:
        if n.type == "TEX_IMAGE" and n.image is not None:
            links = [lk.to_node.type for out in n.outputs for lk in out.links]
            if any(t in ("NORMAL_MAP", "BUMP") for t in links) or "norm" in n.image.name.lower():
                continue
            return n.image
    return None


def _srgb_to_lin(col):
    return tuple(pow(max(0.0, min(1.0, float(c))), 2.2) for c in col)


def _make_webtoon_mat(name, col=(1.0, 1.0, 1.0), img=None, double_sided=False, already_linear=False):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    nt.nodes.clear()
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    p = nt.nodes.new("ShaderNodeBsdfPrincipled")
    p.inputs["Roughness"].default_value = 0.85
    p.inputs["Metallic"].default_value = 0.0
    nt.links.new(p.outputs["BSDF"], out.inputs["Surface"])
    if img is not None:
        tex = nt.nodes.new("ShaderNodeTexImage")
        tex.image = img
        nt.links.new(tex.outputs["Color"], p.inputs["Base Color"])
    else:
        lc = col if already_linear else _srgb_to_lin(col)
        p.inputs["Base Color"].default_value = (lc[0], lc[1], lc[2], 1.0)
    mat.use_backface_culling = not double_sided
    return mat


def _stylize_cloth_material(mat, mode, idx):
    diff_img = _find_diffuse_img(mat)
    is_leather = isinstance(mode, tuple) and mode[0] == "leather"
    prefix = "WT_Leather" if is_leather else "WT_Cloth"
    if diff_img is not None:
        dup = diff_img.copy()
        dup.name = f"{prefix}_{idx}_{diff_img.name}"
        _stylize_outfit_img(dup, mode)
        new_m = _make_webtoon_mat(f"{prefix}_{idx}", img=dup, double_sided=True)
    else:
        col = mode[1] if isinstance(mode, tuple) else (0.14, 0.14, 0.17)
        new_m = _make_webtoon_mat(f"{prefix}_{idx}", col=col, double_sided=True)
    return new_m


def _load_face_meta(face_key):
    with open(os.path.join(FACES_DIR, "meta.json"), encoding="utf-8") as f:
        meta = json.load(f)
    skin_255 = meta[face_key]["skin_rgb"]
    skin_lin = tuple(pow(c / 255.0, 2.2) for c in skin_255)
    skin_srgb = tuple(c / 255.0 for c in skin_255)
    img_path = os.path.join(FACES_DIR, f"{face_key}_face.png")
    img = bpy.data.images.load(img_path)
    img.name = f"WT_FaceTex_{face_key}"
    return img, skin_srgb, skin_lin


def _apply_webtoon_face_and_proportions(basemesh, clothes_objs, rig_obj, spec):
    """Sculpt 8.4-head stylized manhwa proportions + smooth closed face plane + exact original Jeongyeon face projection."""
    # Bake shape keys first on basemesh so vertex coordinates reflect exact character build
    bpy.ops.object.select_all(action="DESELECT")
    bpy.context.view_layer.objects.active = basemesh
    basemesh.select_set(True)
    if basemesh.data.shape_keys:
        bpy.ops.object.shape_key_remove(all=True, apply_mix=True)

    p_hips = rig_obj.matrix_world @ rig_obj.data.bones["pelvis"].head_local
    p_chest = rig_obj.matrix_world @ rig_obj.data.bones["spine_03"].head_local
    p_neck = rig_obj.matrix_world @ rig_obj.data.bones["neck_01"].head_local
    p_head = rig_obj.matrix_world @ rig_obj.data.bones["head"].head_local
    z_top = max(v.co.z for v in basemesh.data.vertices)
    st = spec["stylize"]

    # Measure front face landmarks BEFORE deformation
    fverts = [v for v in basemesh.data.vertices if v.co.z > p_neck.z + 0.02 and v.co.y < -0.02]
    nose_v = min(fverts, key=lambda v: v.co.y)
    nose_z0 = nose_v.co.z
    head_cy = sum(v.co.y for v in basemesh.data.vertices if v.co.z > p_neck.z + 0.02) / max(1, sum(1 for v in basemesh.data.vertices if v.co.z > p_neck.z + 0.02))

    # 1. Smoothly sculpt 8.4-head proportions across basemesh AND all fitted clothes identically
    def deform_pt(co: Vector) -> Vector:
        x, y, z = co.x, co.y, co.z
        # Broaden athletic V-taper shoulders & taper waist slightly
        if p_hips.z < z < p_neck.z:
            u = (z - p_hips.z) / max(p_neck.z - p_hips.z, 0.01)
            # Waist dip around u=0.25, shoulder flare around u=0.82
            w_k = 1.0 + (st["waist_x"] - 1.0) * math.exp(-((u - 0.22) / 0.25) ** 2)
            s_k = 1.0 + (st["shoulder_x"] - 1.0) * math.exp(-((u - 0.82) / 0.28) ** 2)
            x *= w_k * s_k
        # Sleek 8.4-head scale + sharp manhwa V-chin sculpting
        if z > p_neck.z:
            hk = max(0.0, min(1.0, (z - p_neck.z) / 0.06))
            hs = 1.0 + (st["head_s"] - 1.0) * hk
            x = x * hs
            y = head_cy + (y - head_cy) * hs
            z = p_head.z + (z - p_head.z) * hs
            # Taper lower jaw/chin cleanly into sharp comic V-line
            if z < nose_z0 - 0.008 and y < head_cy:
                jk = max(0.0, min(1.0, (nose_z0 - 0.008 - z) / 0.075))
                x *= (1.0 - st["jaw_taper"] * jk)
        return Vector((x, y, z))

    for obj in [basemesh] + clothes_objs:
        bpy.ops.object.select_all(action="DESELECT")
        bpy.context.view_layer.objects.active = obj
        obj.select_set(True)
        if obj.data.shape_keys:
            bpy.ops.object.shape_key_remove(all=True, apply_mix=True)
        for v in obj.data.vertices:
            v.co = deform_pt(v.co)
        obj.data.update()

    # 2. Smooth/close deep realistic hollow eye sockets on basemesh so painted Jeongyeon eyes sit cleanly!
    fverts2 = [v for v in basemesh.data.vertices if v.co.z > p_neck.z + 0.02 and v.co.y < head_cy]
    nose_v2 = min(fverts2, key=lambda v: v.co.y)
    nose_z = nose_v2.co.z
    nose_y = nose_v2.co.y
    eye_z = nose_z + 0.026
    eye_plane_y = nose_y + 0.017  # clean corneal surface plane slightly behind nose tip
    for v in fverts2:
        # Target left & right orbital cavities around (±0.032, eye_z)
        for ex in (-0.032, 0.032):
            dx = (v.co.x - ex) / 0.024
            dz = (v.co.z - eye_z) / 0.015
            d2 = dx * dx + dz * dz
            if d2 < 1.25 and v.co.y > eye_plane_y:
                blend = max(0.0, 1.0 - d2 / 1.25)
                v.co.y = v.co.y * (1.0 - blend * 0.88) + eye_plane_y * (blend * 0.88)
    # Also gently soften deep mouth cavity inside lips so painted webtoon lips never crease awkwardly
    mouth_z = nose_z - 0.030
    mouth_plane_y = nose_y + 0.014
    for v in fverts2:
        dx = v.co.x / 0.028
        dz = (v.co.z - mouth_z) / 0.012
        d2 = dx * dx + dz * dz
        if d2 < 1.15 and v.co.y > mouth_plane_y:
            blend = max(0.0, 1.0 - d2 / 1.15)
            v.co.y = v.co.y * (1.0 - blend * 0.85) + mouth_plane_y * (blend * 0.85)
    basemesh.data.update()

    # 3. Assign WT_Skin (slot 0) + WT_Face (slot 1) with EXACT frontal-planar UV projection!
    face_img, skin_srgb, skin_lin = _load_face_meta(spec["face"])
    mat_skin = _make_webtoon_mat("WT_Skin", col=skin_lin, already_linear=True)
    mat_face = _make_webtoon_mat("WT_Face", img=face_img)
    basemesh.data.materials.clear()
    basemesh.data.materials.append(mat_skin)
    basemesh.data.materials.append(mat_face)

    # Landmark-locked frontal UV mapping matching prep_webtoon_faces.py:
    # Slightly tightened scale (0.146 x 0.156) so Jeongyeon's eyes & lips read BOLD at 35 deg camera!
    face_h = 0.156 * st["head_s"]
    face_w = 0.146 * st["head_s"]
    v_at_nose = 0.40  # (1.0 - 0.60)
    chin_z = nose_z - 0.068 * st["head_s"]
    forehead_top_z = nose_z + 0.096 * st["head_s"]

    uv_layer = basemesh.data.uv_layers.active.data
    face_poly_count = 0
    for poly in basemesh.data.polygons:
        c = poly.center
        # Select crisp front face oval (chin to forehead, ear-to-ear, facing forward -Y)
        if c.z >= chin_z - 0.012 and c.z <= forehead_top_z and c.y < head_cy - 0.008 and abs(c.x) < face_w * 0.54 and poly.normal.y < -0.14:
            poly.material_index = 1
            face_poly_count += 1
            for li in poly.loop_indices:
                vco = basemesh.data.vertices[basemesh.data.loops[li].vertex_index].co
                u = 0.5 + (vco.x / face_w)
                v = v_at_nose + (vco.z - nose_z) / face_h
                uv_layer[li].uv = (max(0.01, min(0.99, u)), max(0.01, min(0.99, v)))
        else:
            poly.material_index = 0
    basemesh.data.update()
    print(f"  Projected original Jeongyeon face '{spec['face']}' onto {face_poly_count} front-face polys (nose_z={nose_z:.3f}m)")
    return {"nose_z": nose_z, "nose_y": nose_y, "eye_z": eye_z, "head_cy": head_cy, "head_z": p_head.z, "top_z": max(v.co.z for v in basemesh.data.vertices), "head_s": st["head_s"]}


def _add_lock(bm, pts, widths, thicks, mat_idx=0):
    """Build a sculpted 6-sided tapered anime/webtoon hair lock along a 3D spine curve."""
    rings = []
    n = len(pts)
    for i, pt in enumerate(pts):
        p = Vector(pt)
        if i == 0:
            tang = (Vector(pts[1]) - p).normalized()
        elif i == n - 1:
            tang = (p - Vector(pts[i - 1])).normalized()
        else:
            tang = (Vector(pts[i + 1]) - Vector(pts[i - 1])).normalized()
        # Outward radial direction from approximate skull center
        ref = Vector((p.x, p.y, 0.0))
        if ref.length < 1e-4:
            ref = Vector((0.0, -1.0, 0.0))
        out = ref.normalized()
        side = tang.cross(out)
        if side.length < 1e-4:
            side = Vector((1.0, 0.0, 0.0))
        else:
            side.normalize()
        out = side.cross(tang).normalized()
        w = widths[i]
        th = thicks[i]
        # Crisp diamond-hex cross-section (sharp manga ridge along outer center!)
        offs = [
            side * (-w),
            side * (-w * 0.45) + out * (th * 0.85),
            out * (th * 1.10),
            side * (w * 0.45) + out * (th * 0.85),
            side * w,
            -out * (th * 0.55),
        ]
        rings.append([bm.verts.new(p + o) for o in offs])

    for i in range(n - 1):
        r0, r1 = rings[i], rings[i + 1]
        for k in range(6):
            f = bm.faces.new((r0[k], r0[(k + 1) % 6], r1[(k + 1) % 6], r1[k]))
            f.material_index = mat_idx
    # Tapered sharp point tip at end
    tip_pt = Vector(pts[-1]) + (Vector(pts[-1]) - Vector(pts[-2])).normalized() * max(0.015, widths[-1] * 0.8)
    v_tip = bm.verts.new(tip_pt)
    for k in range(6):
        f = bm.faces.new((rings[-1][k], rings[-1][(k + 1) % 6], v_tip))
        f.material_index = mat_idx


def _build_manga_hair(basemesh, rig_obj, head_info, hspec):
    """Build sleek, clean 3D sculpted manga/webtoon hair wrapped STRICTLY outside the real skull surface."""
    style = hspec["style"]
    col1 = hspec["col"]
    col2 = hspec.get("col2", col1)

    hs = head_info["head_s"]
    eye_z = head_info["eye_z"]
    nose_z = head_info["nose_z"]
    nose_y = head_info["nose_y"]

    # Measure EXACT deformed cranium vertices (exclude protruding ears so hair hugs temples tightly, never helmet-flared!)
    raw_skull = [v.co.copy() for v in basemesh.data.vertices if v.co.z >= nose_z - 0.055]
    # Crown/upper cranium width above ear line gives true head half-width without ear protrusion
    upper_x = max((abs(v.x) for v in raw_skull if v.z >= eye_z + 0.015), default=0.078 * hs)
    skull_verts = [v for v in raw_skull if not (v.z < eye_z + 0.012 and abs(v.x) > upper_x * 1.03)]
    z_top = max(v.z for v in skull_verts)
    y_front = min(v.y for v in skull_verts)
    y_back = max(v.y for v in skull_verts)
    x_half = upper_x

    # True cranium center sits behind face center, near mid-eye-to-crown height
    cx = 0.0
    cy = (y_front + y_back) * 0.5 + 0.015
    cz = (eye_z + z_top) * 0.5 - 0.008
    center = Vector((cx, cy, cz))

    rx = max(0.076 * hs, x_half)
    ry = max(0.100 * hs, max(y_back - cy, cy - y_front))
    rz = max(0.090 * hs, z_top - cz)

    # Precompute skull unit directions + radial distances for guaranteed clearance in ANY direction!
    s_dirs = []
    s_rads = []
    for sv in skull_verts:
        d = sv - center
        ln = d.length
        if ln > 1e-4:
            s_dirs.append(d / ln)
            s_rads.append(ln)

    def skull_surface_pt(theta, phi, clearance=0.012):
        """Return a 3D point strictly `clearance` meters outside the actual basemesh skull along (theta, phi)."""
        dx = math.cos(theta) * math.sin(phi)
        dy = math.sin(theta) * math.sin(phi)
        dz = math.cos(phi)
        d_vec = Vector((dx, dy, dz)).normalized()
        # Baseline ellipsoid radius in this direction
        ell_r = 1.0 / math.sqrt((dx / max(rx, 0.05)) ** 2 + (dy / max(ry, 0.05)) ** 2 + (dz / max(rz, 0.05)) ** 2)
        # Actual max skull vertex radius within a 20-degree cone around d_vec
        max_r = ell_r
        for sd, sr in zip(s_dirs, s_rads):
            if sd.dot(d_vec) > 0.935:
                if sr > max_r:
                    max_r = sr
        return center + d_vec * (max_r + clearance)

    bm = bmesh.new()

    # 1. Sleek fitted skull cap — hugs crown & temples tightly (NEVER flared helmet!) and covers 100% of back occiput!
    is_short = style in ("kim_bangs", "baek_parted", "jintae_undercut", "ojiin_bun")
    cap_mat_idx = 1 if style == "jintae_undercut" else 0
    lat_n, lon_n = 14, 28
    cap_rows = []
    nape_z = nose_z - (0.022 if style == "baek_parted" else (0.030 if is_short else 0.040))
    for i in range(lat_n):
        u = i / (lat_n - 1)  # 0=crown apex -> 1=hairline/nape rim
        row = []
        for j in range(lon_n):
            theta = (j / lon_n) * math.tau  # 0=+X, pi/2=+Y(back), pi=-X, 3pi/2=-Y(front)
            front_k = max(0.0, -math.sin(theta))
            back_k = max(0.0, math.sin(theta))
            side_k = max(0.0, 1.0 - front_k - back_k)
            front_phi = 0.43 if style == "kim_bangs" else (0.38 if style == "baek_parted" else 0.36)
            side_phi = 0.48 if is_short else 0.54
            back_phi = 0.74 if style == "baek_parted" else 0.78
            max_phi = math.pi * (front_phi * front_k + back_phi * back_k + side_phi * side_k)
            phi_eff = max(0.02, u * max_phi)
            # Taper clearance cleanly toward skull at rim (u->1) so hair hugs temples/nape like real tailored hair!
            base_cl = 0.008 if style == "jintae_undercut" else (0.010 if is_short else 0.013)
            rim_taper = 1.0 - 0.55 * (u ** 1.8) if is_short else 1.0
            cl = max(0.0045, base_cl * rim_taper + (0.004 if not is_short else 0.002) * math.sin(u * math.pi))
            pt = skull_surface_pt(theta, phi_eff, clearance=cl)
            # On the back half, extend bottom rows smoothly down to nape_z while hugging the skull!
            if back_k > 0.15 and u > 0.76:
                nk = (u - 0.76) / 0.24
                target_z = pt.z * (1.0 - nk * back_k) + nape_z * (nk * back_k)
                pt.z = min(pt.z, target_z)
            row.append(bm.verts.new(pt))
        cap_rows.append(row)
    for i in range(lat_n - 1):
        for j in range(lon_n):
            jn = (j + 1) % lon_n
            f = bm.faces.new((cap_rows[i][j], cap_rows[i][jn], cap_rows[i + 1][jn], cap_rows[i + 1][j]))
            f.material_index = cap_mat_idx
    # Close crown apex pole cleanly so top view never has a pinhole
    top_pt = skull_surface_pt(0.0, 0.001, clearance=0.011 if is_short else 0.014)
    v_apex = bm.verts.new(top_pt)
    for j in range(lon_n):
        jn = (j + 1) % lon_n
        f = bm.faces.new((v_apex, cap_rows[0][jn], cap_rows[0][j]))
        f.material_index = cap_mat_idx

    def sk(theta, phi, dr=0.012):
        p = skull_surface_pt(theta, phi, clearance=dr)
        return (p.x, p.y, p.z)

    # 2. Style-specific sculpted manga hair volumes & crisp bangs
    if style == "kim_bangs":
        # Kim Shin: sleek Jeongyeon parted comma/tousled bangs reaching right to eyebrows (sharp & natural!)
        bang_specs = [
            (-0.54, 0.044, -0.006, 0.014),  # left temple sideburn hugging cheek
            (-0.36, 0.036, -0.009, 0.015),
            (-0.20, 0.032, -0.006, 0.015),
            (-0.05, 0.026, -0.003, 0.014),  # subtle natural part right of center
            (0.14, 0.030, 0.006, 0.015),
            (0.28, 0.036, 0.010, 0.015),
            (0.42, 0.040, 0.010, 0.014),
            (0.56, 0.044, 0.006, 0.013),    # right temple sideburn hugging cheek
        ]
        for ang, drop_base, sweep_base, w_base in bang_specs:
            th = -math.pi * 0.5 + ang
            drop = drop_base * hs
            sweep = sweep_base * hs
            p0 = sk(th, 0.34, 0.011)
            p1 = sk(th, 0.80, 0.012)
            p2 = (p1[0] + sweep * 0.65, p1[1] - 0.005, p1[2] - drop * 0.60)
            p3 = (p1[0] + sweep * 1.05, p1[1] - 0.002, p1[2] - drop)
            w = w_base * hs
            _add_lock(bm, [p0, p1, p2, p3], [w, w * 0.85, w * 0.55, 0.0025], [0.006, 0.007, 0.004, 0.0018], 0)
        # Sleek tapered nape locks hugging back neck closely
        for j in range(9):
            th = 0.22 + (j / 8.0) * (math.pi - 0.44)
            p0 = sk(th, 1.15, 0.009)
            p1 = sk(th, 1.78, 0.009)
            p2 = (p1[0] * 0.88, p1[1] - 0.008, nape_z - 0.012 * hs)
            _add_lock(bm, [p0, p1, p2], [0.018, 0.014, 0.004], [0.006, 0.006, 0.002], 0)

    elif style == "baek_parted":
        # Baek Dochan: crisp short gentleman's slicked-back parted hair sweeping tightly over temples!
        for sx in (-1.0, 1.0):
            for k in range(4):
                frac = k / 3.0
                th0 = -math.pi * 0.5 + sx * (0.10 + frac * 0.42)
                th1 = -math.pi * 0.5 + sx * (0.42 + frac * 0.46)
                th2 = -math.pi * 0.5 + sx * (0.82 + frac * 0.44)
                p0 = sk(th0, 0.44, 0.012)
                p1 = sk(th1, 0.66 + frac * 0.14, 0.014)
                p2 = sk(th2, 1.18 + frac * 0.12, 0.010)
                p3 = (p2[0] * 0.94, p2[1], nape_z + 0.008 * hs)
                _add_lock(bm, [p0, p1, p2, p3], [0.018, 0.019, 0.013, 0.004], [0.008, 0.009, 0.006, 0.002], 0)

    elif style == "jintae_undercut":
        # Seo Jintae: wide, lush golden-blonde swept-back two-block crown over tight buzzed dark undercut!
        rings_n, segs_n = 10, 18
        top_rows = []
        crown_top = skull_surface_pt(0.0, 0.01, clearance=0.012).z
        front_edge_y = skull_surface_pt(-math.pi * 0.5, 0.50, clearance=0.012).y
        back_edge_y = skull_surface_pt(math.pi * 0.5, 1.05, clearance=0.012).y
        for r in range(rings_n):
            u = r / (rings_n - 1)  # 0=front blonde hairline -> 1=swept back crown over occiput
            row = []
            for s in range(segs_n):
                v = (s / (segs_n - 1)) * 2.0 - 1.0  # -1..+1 left-to-right
                arch = math.sqrt(max(0.0, 1.0 - v * v * 0.92))
                w_x = (rx + 0.014) * (1.02 - 0.08 * u) * (0.90 + 0.10 * math.sin(u * math.pi))
                x = v * w_x
                y = front_edge_y * (1.0 - u) + back_edge_y * u
                z_curve = crown_top + 0.022 * hs * math.sin(u * math.pi * 0.78) * arch - 0.062 * hs * (u ** 1.5)
                z_edge = z_curve - 0.050 * hs * (1.0 - arch)
                ripple = 0.003 * hs * math.cos(v * math.pi * 3.0) * math.sin(u * math.pi)
                row.append(bm.verts.new((x, y, z_edge + ripple)))
            top_rows.append(row)
        for r in range(rings_n - 1):
            for s in range(segs_n - 1):
                f = bm.faces.new((top_rows[r][s], top_rows[r][s + 1], top_rows[r + 1][s + 1], top_rows[r + 1][s]))
                f.material_index = 0
        # Soft side rim tucking smoothly onto the dark undercut cap
        for r in range(rings_n - 1):
            for side_idx in (0, segs_n - 1):
                p_a = top_rows[r][side_idx].co
                p_b = top_rows[r + 1][side_idx].co
                va = bm.verts.new((p_a.x * 0.92, p_a.y, p_a.z - 0.012 * hs))
                vb = bm.verts.new((p_b.x * 0.92, p_b.y, p_b.z - 0.012 * hs))
                f = bm.faces.new((top_rows[r][side_idx], top_rows[r + 1][side_idx], vb, va))
                f.material_index = 0
        # 5 low-profile swept-back golden flow locks (sleek wave, ZERO spiky crown!)
        for k in range(5):
            v = (k / 4.0) * 1.4 - 0.7
            p0 = (v * rx * 0.85, front_edge_y + 0.008, crown_top - 0.014)
            p1 = (v * rx * 0.92, cy, crown_top + 0.022 * hs * (1.0 - abs(v) * 0.45))
            p2 = (v * rx * 0.84, back_edge_y + 0.006, crown_top - 0.044 * hs)
            _add_lock(bm, [p0, p1, p2], [0.018, 0.020, 0.006], [0.006, 0.008, 0.002], 0)

    elif style == "ojiin_bun":
        # Ojiin: sleek jet-black pulled-back crown + sculpted round chignon bun + signature single curved cheek strand!
        bun_base = skull_surface_pt(math.pi * 0.5, 1.38, clearance=0.028)
        bmesh.ops.create_icosphere(bm, subdivisions=2, radius=0.050 * hs, matrix=Matrix.Translation(bun_base))
        # Delicate signature framing strand sweeping gently alongside her left cheek (+X, outside eye!)
        p0 = sk(-math.pi * 0.5 + 0.34, 0.48, 0.014)
        p1 = (0.064 * hs, nose_y + 0.008, eye_z + 0.006)
        p2 = (0.068 * hs, nose_y + 0.012, nose_z - 0.018)
        p3 = (0.054 * hs, nose_y + 0.016, nose_z - 0.058)
        _add_lock(bm, [p0, p1, p2, p3], [0.011, 0.010, 0.007, 0.002], [0.005, 0.005, 0.004, 0.002], 0)

    elif style in ("risa_glamour", "client_messy"):
        # Smooth continuous sleek flowing hair mantle hugging temples tightly (zero hood gap, zero bald spot!)
        is_risa = style == "risa_glamour"
        length = (0.28 if is_risa else 0.16) * hs
        rings_n, segs_n = 11, 22
        curtain_rows = []
        # Span cleanly from right temple (-0.18*pi) around back (+0.5*pi) to left temple (+1.18*pi)
        a0, a1 = -0.18 * math.pi, 1.18 * math.pi
        top_start_z = cz + rz * 0.30
        bot_end_z = nose_z - 0.04 * hs - length
        for r in range(rings_n):
            u = r / (rings_n - 1)  # 0=temples/upper skull -> 1=flowing hair tips
            z = top_start_z * (1.0 - u) + bot_end_z * u
            row = []
            for s in range(segs_n):
                v = s / (segs_n - 1)
                ang = a0 + (a1 - a0) * v
                # Start strictly hugging skull surface at u=0 (clearance 0.018m), flare gracefully as hair cascades down!
                base_pt = skull_surface_pt(ang, min(1.85, 0.95 + 0.85 * u), clearance=0.018)
                flare = 1.0 + (0.22 if is_risa else 0.10) * math.sin(u * math.pi * 0.72) + (0.12 if is_risa else 0.04) * u
                wave = (0.008 if is_risa else 0.004) * math.sin(v * math.pi * 5.0 + u * 2.4) * u
                dx0 = base_pt.x - cx
                dy0 = base_pt.y - cy
                x = cx + dx0 * flare + math.cos(ang) * wave
                y = cy + dy0 * flare + math.sin(ang) * wave + 0.016 * u
                row.append(bm.verts.new((x, y, z)))
            curtain_rows.append(row)
        for r in range(rings_n - 1):
            for s in range(segs_n - 1):
                f = bm.faces.new((curtain_rows[r][s], curtain_rows[r + 1][s], curtain_rows[r + 1][s + 1], curtain_rows[r][s + 1]))
                f.material_index = 0
        # Sleek cheek-hugging parted front framing locks (hugging cheekbones cleanly, NEVER hood-like!)
        for sx in (-1.0, 1.0):
            p0 = sk(-math.pi * 0.5 + sx * 0.14, 0.36, 0.015)
            p1 = sk(-math.pi * 0.5 + sx * 0.52, 0.68, 0.016)
            p2 = (sx * (x_half + 0.012), nose_y + 0.024, eye_z - 0.022)
            p3 = (sx * (x_half + 0.016), nose_y + 0.038, nose_z - 0.095)
            _add_lock(bm, [p0, p1, p2, p3], [0.015, 0.018, 0.015, 0.004], [0.007, 0.008, 0.006, 0.002], 0)

    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    mesh = bpy.data.meshes.new("MangaHairMesh")
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new("MangaHair", mesh)
    bpy.context.collection.objects.link(obj)
    for poly in obj.data.polygons:
        poly.use_smooth = True

    obj.data.materials.append(_make_webtoon_mat("WT_Hair", col=col1, double_sided=True))
    if style == "jintae_undercut":
        obj.data.materials.append(_make_webtoon_mat("WT_HairDark", col=col2, double_sided=True))

    vg_head = obj.vertex_groups.new(name="head")
    vg_chest = obj.vertex_groups.new(name="spine_03")
    neck_z = (rig_obj.matrix_world @ rig_obj.data.bones["neck_01"].head_local).z
    for v in obj.data.vertices:
        if style == "risa_glamour" and v.co.z < neck_z - 0.02:
            k = max(0.0, min(1.0, (neck_z - 0.02 - v.co.z) / 0.16))
            vg_head.add([v.index], 1.0 - 0.55 * k, "REPLACE")
            vg_chest.add([v.index], 0.55 * k, "REPLACE")
        else:
            vg_head.add([v.index], 1.0, "REPLACE")
    mod = obj.modifiers.new("Armature", "ARMATURE")
    mod.object = rig_obj
    return obj


def _build_webtoon_glasses(rig_obj, head_info, mode):
    """Build bold sculpted iconic webtoon glasses (Baek gleaming white rectangles / Jintae amber shades)."""
    hs = head_info["head_s"]
    ez = head_info["eye_z"]
    ey = head_info["nose_y"] - 0.008 * hs
    bm = bmesh.new()

    is_baek = mode == "baek_white"
    lens_w = (0.0225 if is_baek else 0.028) * hs
    lens_h = (0.0102 if is_baek else 0.0155) * hs
    lens_x = (0.0325 if is_baek else 0.032) * hs

    def add_box(center, size, mat_idx):
        m = Matrix.Translation(center) @ Matrix.Diagonal((size[0], size[1], size[2], 1.0))
        res = bmesh.ops.create_cube(bm, size=1.0, matrix=m)
        for v in res["verts"]:
            for f in v.link_faces:
                f.material_index = mat_idx

    # Two distinct lenses (mat 0 = WT_Glasses luminous) with crisp dark frame separation!
    for sx in (-1.0, 1.0):
        add_box((sx * lens_x, ey, ez), (lens_w * 2.0, 0.004, lens_h * 2.0), 0)
        ft = 0.0024 if is_baek else 0.0045
        add_box((sx * lens_x, ey - 0.001, ez + lens_h + ft * 0.4), (lens_w * 2.0 + ft * 1.6, 0.005, ft), 1)
        add_box((sx * lens_x, ey - 0.001, ez - lens_h - ft * 0.4), (lens_w * 2.0 + ft * 1.6, 0.005, ft * (0.75 if is_baek else 1.0)), 1)
        add_box((sx * (lens_x + lens_w + ft * 0.3), ey - 0.001, ez), (ft, 0.005, lens_h * 2.0 + ft), 1)
        add_box((sx * (lens_x - lens_w - ft * 0.3), ey - 0.001, ez), (ft, 0.005, lens_h * 2.0 + ft), 1)
        # Temples sweeping back to ears
        add_box((sx * (lens_x + lens_w + 0.004), ey + 0.055 * hs, ez + 0.002), (0.0035, 0.11 * hs, 0.004 if is_baek else 0.006), 1)
    # Clean narrow dark nose bridge separating the two lenses
    add_box((0.0, ey - 0.001, ez + 0.002), (0.017 * hs, 0.004, 0.0032 if is_baek else 0.005), 1)

    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    mesh = bpy.data.meshes.new("GlassesMesh")
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new("Glasses", mesh)
    bpy.context.collection.objects.link(obj)

    lens_col = (0.90, 0.96, 1.0) if is_baek else (0.98, 0.78, 0.14)
    frame_col = (0.14, 0.16, 0.20) if is_baek else (0.04, 0.04, 0.05)
    obj.data.materials.append(_make_webtoon_mat("WT_Glasses", col=lens_col))
    obj.data.materials.append(_make_webtoon_mat("WT_Leather_Frame", col=frame_col))

    vg = obj.vertex_groups.new(name="head")
    vg.add([v.index for v in obj.data.vertices], 1.0, "REPLACE")
    mod = obj.modifiers.new("Armature", "ARMATURE")
    mod.object = rig_obj
    return obj


def _build_baek_holster(rig_obj, shirt_obj=None):
    """Build Baek Dochan's iconic dark-brown leather X-shoulder holster densely conformed ON TOP of his shirt."""
    p_chest = rig_obj.matrix_world @ rig_obj.data.bones["spine_03"].head_local
    p_sh_r = rig_obj.matrix_world @ rig_obj.data.bones["upperarm_r"].head_local
    p_spine = rig_obj.matrix_world @ rig_obj.data.bones["spine_01"].head_local

    torso_verts = []
    if shirt_obj is not None:
        deps = bpy.context.evaluated_depsgraph_get()
        ev_obj = shirt_obj.evaluated_get(deps)
        ev_mesh = ev_obj.to_mesh()
        torso_verts = [v.co.copy() for v in ev_mesh.vertices if p_spine.z - 0.04 <= v.co.z <= p_sh_r.z + 0.16 and abs(v.co.x) < 0.28]
        ev_obj.to_mesh_clear()

    def hug(pt: Vector, lift=0.008) -> tuple:
        if not torso_verts:
            return pt, Vector((0.0, 1.0, 0.0))
        best = min(torso_verts, key=lambda v: (v - pt).length_squared)
        out = Vector((best.x, best.y - p_chest.y, (best.z - p_chest.z) * 0.35))
        out = out.normalized() if out.length > 1e-4 else Vector((0.0, 1.0, 0.0))
        return best + out * lift, out

    bm = bmesh.new()
    for sx in (-1.0, 1.0):
        ctrl = [
            Vector((sx * 0.170, p_chest.y - 0.14, p_spine.z + 0.04)),
            Vector((sx * 0.148, p_chest.y - 0.16, p_chest.z + 0.07)),
            Vector((sx * 0.128, p_chest.y - 0.02, p_sh_r.z + 0.11)),
            Vector((sx * 0.115, p_chest.y + 0.14, p_chest.z + 0.09)),
            Vector((0.0, p_chest.y + 0.15, p_chest.z + 0.01)),
            Vector((-sx * 0.145, p_chest.y + 0.13, p_spine.z + 0.04)),
        ]
        # Densely resample polyline (4 sub-steps per segment) so straps NEVER cut chords inside the curved white shirt!
        dense = []
        for idx in range(len(ctrl) - 1):
            a, b = ctrl[idx], ctrl[idx + 1]
            steps = 5 if idx == len(ctrl) - 2 else 4
            for k in range(steps):
                t = k / float(steps)
                dense.append(a.lerp(b, t))
        dense.append(ctrl[-1])

        snapped = [hug(p, lift=0.013) for p in dense]
        pts = [s[0] for s in snapped]
        nrms = [s[1] for s in snapped]
        prev = None
        for i, pt in enumerate(pts):
            t = (pts[min(i + 1, len(pts) - 1)] - pts[max(i - 1, 0)]).normalized()
            nrm = nrms[i]
            side = t.cross(nrm)
            side = side.normalized() if side.length > 1e-4 else Vector((1.0, 0.0, 0.0))
            nrm = side.cross(t).normalized()
            if nrm.dot(nrms[i]) < 0:
                nrm = -nrm
            w, th = 0.020, 0.008
            # Ribbon sits STRICTLY outside the shirt (from -0.002 to +th) so it reads bold & unbroken!
            ring = [
                bm.verts.new(pt - side * w - nrm * 0.002),
                bm.verts.new(pt + side * w - nrm * 0.002),
                bm.verts.new(pt + side * w + nrm * th),
                bm.verts.new(pt - side * w + nrm * th),
            ]
            if prev is not None:
                for k in range(4):
                    bm.faces.new((prev[k], prev[(k + 1) % 4], ring[(k + 1) % 4], ring[k]))
            prev = ring
    # Underarm pistol holster pouch tucked right under left arm (+X in pre-flip MPFB!)
    pouch_pt, _ = hug(Vector((0.185, p_chest.y - 0.01, p_spine.z + 0.08)), lift=0.016)
    m_pouch = Matrix.Translation(pouch_pt + Vector((0.016, 0.0, 0.0))) @ Matrix.Diagonal((0.040, 0.080, 0.130, 1.0))
    bmesh.ops.create_cube(bm, size=1.0, matrix=m_pouch)

    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    mesh = bpy.data.meshes.new("BaekHolsterMesh")
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new("BaekHolster", mesh)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(_make_webtoon_mat("WT_Leather_Holster", col=(0.30, 0.17, 0.10), double_sided=True))
    vg = obj.vertex_groups.new(name="spine_03")
    vg.add([v.index for v in obj.data.vertices], 1.0, "REPLACE")
    mod = obj.modifiers.new("Armature", "ARMATURE")
    mod.object = rig_obj
    return obj


def _build_risa_fur_collar(rig_obj):
    """Build a sleek sculpted plush mink-fur collar resting elegantly around Risa's tailored beige coat neckline."""
    p_neck = rig_obj.matrix_world @ rig_obj.data.bones["neck_01"].head_local
    p_chest = rig_obj.matrix_world @ rig_obj.data.bones["spine_03"].head_local
    bm = bmesh.new()
    segs = 20
    rings = 8
    cy = p_neck.y + 0.010
    cz = p_neck.z - 0.012
    # Plush wrap-around fur stole collar open gracefully at front V-neck
    a0, a1 = -0.32 * math.pi, 1.32 * math.pi
    rows = []
    for s in range(segs):
        u = s / (segs - 1)
        ang = a0 + (a1 - a0) * u
        cx0 = math.cos(ang) * 0.115
        cy0 = cy + math.sin(ang) * 0.105
        cz0 = cz + 0.020 * math.sin(ang) - 0.040 * max(0.0, -math.sin(ang))
        rad = 0.030 * (0.72 + 0.28 * math.sin(u * math.pi))
        tang = Vector((-math.sin(ang), math.cos(ang), 0.0)).normalized()
        up = Vector((0.0, 0.0, 1.0))
        out = tang.cross(up).normalized()
        ring = []
        for r in range(rings):
            phi = (r / rings) * math.tau
            p = Vector((cx0, cy0, cz0)) + (out * math.cos(phi) + up * math.sin(phi)) * rad
            ring.append(bm.verts.new(p))
        rows.append(ring)
    for s in range(segs - 1):
        for r in range(rings):
            rn = (r + 1) % rings
            bm.faces.new((rows[s][r], rows[s][rn], rows[s + 1][rn], rows[s + 1][r]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    mesh = bpy.data.meshes.new("RisaFurCollarMesh")
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new("RisaFurCollar", mesh)
    bpy.context.collection.objects.link(obj)
    for poly in obj.data.polygons:
        poly.use_smooth = True
    obj.data.materials.append(_make_webtoon_mat("WT_Cloth_RisaFur", col=(0.88, 0.80, 0.68), double_sided=True))
    vg = obj.vertex_groups.new(name="spine_03")
    vg.add([v.index for v in obj.data.vertices], 1.0, "REPLACE")
    mod = obj.modifiers.new("Armature", "ARMATURE")
    mod.object = rig_obj
    return obj


def _build_risa_fur_drape(rig_obj):
    """Build Risa's opulent champagne-beige fur-collared draped coat matching ep002/008!"""
    p_chest = rig_obj.matrix_world @ rig_obj.data.bones["spine_03"].head_local
    p_neck = rig_obj.matrix_world @ rig_obj.data.bones["neck_01"].head_local
    p_sh_r = rig_obj.matrix_world @ rig_obj.data.bones["upperarm_r"].head_local
    p_sh_l = rig_obj.matrix_world @ rig_obj.data.bones["upperarm_l"].head_local
    p_hips = rig_obj.matrix_world @ rig_obj.data.bones["pelvis"].head_local
    p_calf = rig_obj.matrix_world @ rig_obj.data.bones["calf_r"].head_local

    sh_half = abs(p_sh_r.x - p_sh_l.x) * 0.5 + 0.060
    top_z = p_neck.z + 0.010
    bot_z = p_calf.z + 0.14
    cy = p_chest.y + 0.015

    bm = bmesh.new()
    rings, segs = 14, 22
    ring_verts = []
    for r in range(rings):
        u = r / (rings - 1)
        z = top_z * (1.0 - u) + bot_z * u
        rx = sh_half * (0.95 + 0.25 * math.sin(u * math.pi * 0.55) + 0.18 * u)
        ry = 0.155 + 0.065 * u + 0.03 * math.sin(u * math.pi)
        gap = 0.30 + 0.18 * u
        a0 = -math.pi * 0.5 + gap
        a1 = math.pi * 1.5 - gap
        row = []
        for s in range(segs):
            v = s / (segs - 1)
            ang = a0 + (a1 - a0) * v
            ripple = 0.010 * math.sin(v * math.pi * 6.0) * u
            row.append(bm.verts.new((math.cos(ang) * (rx + ripple), cy + math.sin(ang) * (ry + ripple), z)))
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
    sol = obj.modifiers.new("Solidify", "SOLIDIFY")
    sol.thickness = 0.020
    sol.offset = 1.0
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.modifier_apply(modifier="Solidify")
    for poly in obj.data.polygons:
        poly.use_smooth = True

    # Champagne-beige mink coat + plush cream fur collar matching ep002/008!
    obj.data.materials.append(_make_webtoon_mat("WT_Cloth_RisaCoat", col=(0.74, 0.64, 0.52), double_sided=True))
    obj.data.materials.append(_make_webtoon_mat("WT_Cloth_RisaFur", col=(0.86, 0.78, 0.66), double_sided=True))
    for poly in obj.data.polygons:
        if poly.center.z > top_z - 0.095:
            poly.material_index = 1

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


def _build_long_coat_skirt(rig_obj, jacket_obj=None):
    """Build Kim Shin's sleek tailored black trench coat lower drape seamlessly tucked into the jacket waist."""
    p_hips = rig_obj.matrix_world @ rig_obj.data.bones["pelvis"].head_local
    p_calf = rig_obj.matrix_world @ rig_obj.data.bones["calf_r"].head_local
    top_z = p_hips.z + 0.04
    bot_z = p_calf.z + 0.08
    cy = p_hips.y + 0.006

    # Measure actual tailored jacket hip contour so top rim tucks invisibly inside the jacket hem (zero hoop-skirt gap!)
    base_rx, base_ry = 0.175, 0.125
    if jacket_obj is not None:
        wverts = [v.co for v in jacket_obj.data.vertices if top_z - 0.05 <= v.co.z <= top_z + 0.05]
        if wverts:
            base_rx = max(0.145, min(0.205, max(abs(v.x) for v in wverts) * 0.96))
            y_lo = min(v.y for v in wverts)
            y_hi = max(v.y for v in wverts)
            cy = (y_lo + y_hi) * 0.5
            base_ry = max(0.105, min(0.155, (y_hi - y_lo) * 0.48))

    bm = bmesh.new()
    rings, segs = 12, 22
    rows = []
    for r in range(rings):
        u = r / (rings - 1)
        z = top_z * (1.0 - u) + bot_z * u
        # Smooth tailored A-line flare starting flush inside the jacket waist
        flare = 0.94 + 0.30 * (u ** 0.85)
        rx = base_rx * flare
        ry = base_ry * flare
        gap = 0.22 + 0.24 * u
        a0 = -math.pi * 0.5 + gap
        a1 = math.pi * 1.5 - gap
        row = []
        for s in range(segs):
            v = s / (segs - 1)
            ang = a0 + (a1 - a0) * v
            row.append(bm.verts.new((math.cos(ang) * rx, cy + math.sin(ang) * ry, z)))
        rows.append(row)
    for r in range(rings - 1):
        for s in range(segs - 1):
            bm.faces.new((rows[r][s], rows[r + 1][s], rows[r + 1][s + 1], rows[r][s + 1]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    mesh = bpy.data.meshes.new("KimCoatSkirtMesh")
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new("KimCoatSkirt", mesh)
    bpy.context.collection.objects.link(obj)
    for poly in obj.data.polygons:
        poly.use_smooth = True
    obj.data.materials.append(_make_webtoon_mat("WT_Cloth_KimTrench", col=(0.08, 0.082, 0.105), double_sided=True))
    vg_hips = obj.vertex_groups.new(name="pelvis")
    vg_thr = obj.vertex_groups.new(name="thigh_r")
    vg_thl = obj.vertex_groups.new(name="thigh_l")
    for v in obj.data.vertices:
        u = max(0.0, min(1.0, (top_z - v.co.z) / max(top_z - bot_z, 0.01)))
        if u < 0.25:
            vg_hips.add([v.index], 1.0, "REPLACE")
        else:
            side_w = 0.52 * u
            vg_hips.add([v.index], 1.0 - side_w, "REPLACE")
            (vg_thr if v.co.x < 0 else vg_thl).add([v.index], side_w, "REPLACE")
    mod = obj.modifiers.new("Armature", "ARMATURE")
    mod.object = rig_obj
    return obj


def _align_bone_world_dir(rig_obj, bone_name, target_dir):
    pb = rig_obj.pose.bones.get(bone_name)
    if pb is None:
        return
    bpy.context.view_layer.update()
    mw = rig_obj.matrix_world @ pb.matrix
    cur_dir = (mw.to_3x3() @ Vector((0, 1, 0))).normalized()
    want = Vector(target_dir).normalized()
    q_world = cur_dir.rotation_difference(want)
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


def _pose_arms_down(rig_obj):
    bpy.context.view_layer.objects.active = rig_obj
    bpy.ops.object.mode_set(mode="POSE")
    _align_bone_world_dir(rig_obj, "upperarm_r", (-0.07, 0.0, -1.0))
    _align_bone_world_dir(rig_obj, "lowerarm_r", (-0.02, -0.04, -1.0))
    _align_bone_world_dir(rig_obj, "upperarm_l", (0.07, 0.0, -1.0))
    _align_bone_world_dir(rig_obj, "lowerarm_l", (0.02, -0.04, -1.0))
    _align_bone_world_dir(rig_obj, "thigh_r", (0.0, 0.0, -1.0))
    _align_bone_world_dir(rig_obj, "calf_r", (0.0, 0.0, -1.0))
    _align_bone_world_dir(rig_obj, "thigh_l", (0.0, 0.0, -1.0))
    _align_bone_world_dir(rig_obj, "calf_l", (0.0, 0.0, -1.0))
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
    bpy.context.view_layer.update()
    return {t: (rig_obj.matrix_world @ rig_obj.pose.bones[s].head).copy() for t, s in JOINT_SRC.items()}


def _remap_vertex_groups(obj):
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
        top = sorted(acc.items(), key=lambda kv: kv[1], reverse=True)[:4]
        s = sum(w for _, w in top)
        per_vert.append([(k, w / s) for k, w in top])
    obj.vertex_groups.clear()
    new_vgs = {name: obj.vertex_groups.new(name=name) for name, _ in TARGET_BONES}
    for vi, items in enumerate(per_vert):
        for name, w in items:
            new_vgs[name].add([vi], w, "REPLACE")


def _build_17_bone_armature(name, joint_pos):
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
        eb.tail = p + Vector((0.0, 0.0, 0.12))
        eb.roll = 0.0
        if pname:
            eb.parent = ebones[pname]
        ebones[bname] = eb
    bpy.ops.object.mode_set(mode="OBJECT")
    return arm_obj


def _resize_and_compress_images(tmp_dir):
    for img in list(bpy.data.images):
        if img.size[0] == 0 or img.size[1] == 0:
            continue
        max_dim = 512
        w, h = img.size
        if w > max_dim or h > max_dim:
            sc = max_dim / max(w, h)
            img.scale(max(64, int(w * sc)), max(64, int(h * sc)))
        safe_name = "".join(c if c.isalnum() or c in "._-" else "_" for c in img.name)
        fpath = os.path.join(tmp_dir, f"{safe_name}.jpg")
        img.filepath_raw = fpath
        img.file_format = "JPEG"
        bpy.context.scene.render.image_settings.quality = 89
        try:
            img.save()
        except Exception as exc:
            print(f"  WARN save img {img.name}: {exc}")


def build_webtoon_character(char_id, spec):
    print(f"=== BAKE WEBTOON 3D: {char_id} -> {spec['out']} ===")
    bpy.ops.wm.read_factory_settings(use_empty=True)
    tmp_dir = tempfile.mkdtemp(prefix=f"wt3d_{char_id}_")
    try:
        md = TargetService.get_default_macro_info_dict()
        for k, v in spec["macro"].items():
            md[k] = v
        basemesh = HumanService.create_human(mask_helpers=True, detailed_helpers=True,
                                             extra_vertex_groups=True, feet_on_ground=True,
                                             scale=0.1, macro_detail_dict=md)
        rig_obj = HumanService.add_builtin_rig(basemesh, "game_engine", import_weights=True)

        # Attach stylized MPFB2 outfits
        clothes_objs = []
        for idx, (c_path, c_mode) in enumerate(spec["clothes"]):
            cl = HumanService.add_mhclo_asset(asset_path(c_path), basemesh, asset_type="Clothes",
                                              subdiv_levels=0, material_type="MAKESKIN",
                                              set_up_rigging=True, interpolate_weights=True)
            new_mats = [_stylize_cloth_material(m, c_mode, idx) for m in cl.data.materials]
            cl.data.materials.clear()
            for nm in new_mats:
                cl.data.materials.append(nm)
            if c_mode == "baek_shirt_pants":
                disp = cl.modifiers.new("ShirtClearance", "DISPLACE")
                disp.strength = 0.015
                disp.mid_level = 0.0
            elif c_mode == "risa_mink_jacket":
                # Keep tailored beige mink coat jacket over black mini-dress; trim trouser legs below hips so bare legs show cleanly!
                hips_z = (rig_obj.matrix_world @ rig_obj.data.bones["pelvis"].head_local).z
                bm_j = bmesh.new()
                bm_j.from_mesh(cl.data)
                kill = [v for v in bm_j.verts if v.co.z < hips_z - 0.14]
                if kill:
                    bmesh.ops.delete(bm_j, geom=kill, context="VERTS")
                bm_j.to_mesh(cl.data)
                bm_j.free()
                cl.data.update()
                for prev in clothes_objs:
                    if "shift_dress" in prev.name.lower():
                        bm_d = bmesh.new()
                        bm_d.from_mesh(prev.data)
                        kill_d = [v for v in bm_d.verts if v.co.z > hips_z - 0.05]
                        if kill_d:
                            bmesh.ops.delete(bm_d, geom=kill_d, context="VERTS")
                        bm_d.to_mesh(prev.data)
                        bm_d.free()
                        prev.data.update()
                disp = cl.modifiers.new("CoatLayerOffset", "DISPLACE")
                disp.strength = 0.010
                disp.mid_level = 0.0
                for mod in list(basemesh.modifiers):
                    if mod.type == "MASK" and "double-breasted" in mod.name.lower():
                        basemesh.modifiers.remove(mod)
            clothes_objs.append(cl)

        # Apply 8.4-head webtoon proportions + smooth face + original Jeongyeon face projection!
        head_info = _apply_webtoon_face_and_proportions(basemesh, clothes_objs, rig_obj, spec)

        # Build bold sculpted 3D manga hair + optional sculpted glasses + signature accessories
        hair_obj = _build_manga_hair(basemesh, rig_obj, head_info, spec["hair"])
        part_objs = [basemesh] + clothes_objs + [hair_obj]
        glasses_obj = _build_webtoon_glasses(rig_obj, head_info, spec["glasses"]) if spec.get("glasses") else None

        for ex in spec.get("extras", []):
            if ex == "shoulder_holster":
                part_objs.append(_build_baek_holster(rig_obj, clothes_objs[0] if clothes_objs else None))
            elif ex == "risa_fur_collar":
                part_objs.append(_build_risa_fur_collar(rig_obj))
            elif ex == "risa_fur_drape":
                part_objs.append(_build_risa_fur_drape(rig_obj))
            elif ex == "long_coat_skirt":
                part_objs.append(_build_long_coat_skirt(rig_obj, clothes_objs[0] if clothes_objs else None))

        # Pose arms down cleanly into neutral rest pose
        _pose_arms_down(rig_obj)
        joint_pos = _record_joint_positions(rig_obj)

        all_meshes = part_objs + ([glasses_obj] if glasses_obj else [])
        for obj in all_meshes:
            bpy.ops.object.select_all(action="DESELECT")
            bpy.context.view_layer.objects.active = obj
            obj.select_set(True)
            if obj.data.shape_keys:
                bpy.ops.object.shape_key_remove(all=True, apply_mix=True)
            for mod in list(obj.modifiers):
                if mod.type == "SUBSURF":
                    obj.modifiers.remove(mod)
            for mod in list(obj.modifiers):
                try:
                    bpy.ops.object.modifier_apply(modifier=mod.name)
                except Exception as exc:
                    print(f"  WARN apply {obj.name}.{mod.name}: {exc}")
                    obj.modifiers.remove(mod)
            obj.parent = None
            obj.matrix_world = Matrix.Identity(4)

        bpy.data.objects.remove(rig_obj, do_unlink=True)

        # Flip 180 deg around Z (-Y forward -> +Y forward == Godot -Z forward) & normalize exact webtoon height
        rot_flip = Matrix.Rotation(math.pi, 4, "Z")
        for obj in all_meshes:
            obj.data.transform(rot_flip)
            obj.data.update()
        for k in joint_pos:
            joint_pos[k] = rot_flip @ joint_pos[k]

        z_min = min((v.co.z for o in all_meshes for v in o.data.vertices), default=0.0)
        z_max = max((v.co.z for o in all_meshes for v in o.data.vertices), default=1.78)
        scale_k = spec["height_m"] / max(z_max - z_min, 0.5)
        xform = Matrix.Scale(scale_k, 4) @ Matrix.Translation((0.0, 0.0, -z_min))
        for obj in all_meshes:
            obj.data.transform(xform)
            obj.data.update()
        for k in joint_pos:
            joint_pos[k] = xform @ joint_pos[k]

        assert joint_pos["sh_r"].x > 0.05 and joint_pos["sh_l"].x < -0.05, \
            f"Left/right orientation error: sh_r={joint_pos['sh_r']}, sh_l={joint_pos['sh_l']}"

        # Join into ONE SkinnedMesh "Webtoon_Body" (keep Glasses separate for Phase 2 remove_glasses!)
        bpy.ops.object.select_all(action="DESELECT")
        for o in part_objs:
            o.select_set(True)
        bpy.context.view_layer.objects.active = basemesh
        bpy.ops.object.join()
        body_obj = bpy.context.view_layer.objects.active
        body_obj.name = "Webtoon_Body"

        tri_count = sum(len(p.vertices) - 2 for p in body_obj.data.polygons)
        if tri_count > 22000:
            dec = body_obj.modifiers.new("MobileDecimate", "DECIMATE")
            dec.ratio = 18000.0 / tri_count
            bpy.context.view_layer.objects.active = body_obj
            bpy.ops.object.modifier_apply(modifier="MobileDecimate")
            tri_count = sum(len(p.vertices) - 2 for p in body_obj.data.polygons)

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

        _resize_and_compress_images(tmp_dir)

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
            export_jpeg_quality=89,
            export_texcoords=True,
            export_normals=True,
            export_tangents=False,
            export_animations=False,
        )
        kb = os.path.getsize(out_path) // 1024
        print(f"  OK {spec['out']}: {tri_count} tris, {kb} KB, hips_z={joint_pos['hips'].z:.3f}m")
    finally:
        shutil.rmtree(tmp_dir, ignore_errors=True)


def main():
    argv = sys.argv
    only = argv[argv.index("--") + 1:] if "--" in argv else []
    targets = [k for k in WEBTOON_SPECS if not only or k in only]
    for cid in targets:
        build_webtoon_character(cid, WEBTOON_SPECS[cid])


if __name__ == "__main__":
    main()
