"""CC0 Quaternius Universal Animation Library -> 17-Bone Godot AnimationLibrary Baker.

Retargets selected locomotion & combat mocap clips from Quaternius's CC0
AnimationLibrary_Godot_Standard.gltf onto our exact 17-bone Identity-rest
skeleton (arms-down rest pose, facing Godot -Z) and exports a compact shared
GLB: assets/animations/humanoid_cc0.glb.

Usage:
    blender -b --python tools/bake_anims.py
"""
import math
import os
import sys

import bpy
from mathutils import Matrix, Vector

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC_GLTF = "/data/users/juho.hong/tools/blender/anim/AnimationLibrary_Godot_Standard.gltf"
OUT_GLB = os.path.join(REPO_ROOT, "assets", "animations", "humanoid_cc0.glb")

TARGET_BONES = [
    ("hips", "", Vector((0.0, 0.0, 0.92))),
    ("spine", "hips", Vector((0.0, 0.0, 1.05))),
    ("chest", "spine", Vector((0.0, 0.0, 1.25))),
    ("neck", "chest", Vector((0.0, 0.0, 1.48))),
    ("head", "neck", Vector((0.0, 0.0, 1.57))),
    ("sh_r", "chest", Vector((0.19, 0.0, 1.44))),
    ("el_r", "sh_r", Vector((0.19, 0.0, 1.15))),
    ("hand_r", "el_r", Vector((0.19, 0.0, 0.88))),
    ("sh_l", "chest", Vector((-0.19, 0.0, 1.44))),
    ("el_l", "sh_l", Vector((-0.19, 0.0, 1.15))),
    ("hand_l", "el_l", Vector((-0.19, 0.0, 0.88))),
    ("th_r", "hips", Vector((0.09, 0.0, 0.92))),
    ("kn_r", "th_r", Vector((0.09, 0.0, 0.52))),
    ("ft_r", "kn_r", Vector((0.09, 0.0, 0.10))),
    ("th_l", "hips", Vector((-0.09, 0.0, 0.92))),
    ("kn_l", "th_l", Vector((-0.09, 0.0, 0.52))),
    ("ft_l", "kn_l", Vector((-0.09, 0.0, 0.10))),
]

# Our 17 bones -> Quaternius DEF-* bones
SRC_OF = {
    "hips": "DEF-hips",
    "spine": "DEF-spine.001",
    "chest": "DEF-spine.003",
    "neck": "DEF-neck",
    "head": "DEF-head",
    "sh_r": "DEF-upper_arm.R",
    "el_r": "DEF-forearm.R",
    "hand_r": "DEF-hand.R",
    "sh_l": "DEF-upper_arm.L",
    "el_l": "DEF-forearm.L",
    "hand_l": "DEF-hand.L",
    "th_r": "DEF-thigh.R",
    "kn_r": "DEF-shin.R",
    "ft_r": "DEF-foot.R",
    "th_l": "DEF-thigh.L",
    "kn_l": "DEF-shin.L",
    "ft_l": "DEF-foot.L",
}

# Core locomotion + cutscene + combat clips to include (keeps shared GLB tiny!)
WANT_CLIPS = [
    "Idle_Loop",
    "Idle_Talking_Loop",
    "Walk_Loop",
    "Walk_Formal_Loop",
    "Jog_Fwd_Loop",
    "Sprint_Loop",
    "Crouch_Idle_Loop",
    "Crouch_Fwd_Loop",
    "Jump_Start",
    "Jump_Loop",
    "Roll",
    "Sitting_Idle_Loop",
    "Sitting_Talking_Loop",
    "Sword_Idle",
    "Sword_Attack",
    "Punch_Jab",
    "Punch_Cross",
    "Hit_Chest",
    "Hit_Head",
    "Death01",
]


def main():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=SRC_GLTF)
    src_arm = next(o for o in bpy.data.objects if o.type == "ARMATURE")
    bpy.context.scene.render.fps = 30

    # 1. Capture source T-pose rest orientations in Blender world space (flipped +180Z -> +Y forward == Godot -Z)
    flip = Matrix.Rotation(math.pi, 3, "Z")
    r_src_rest_inv = {}
    for tb, sb in SRC_OF.items():
        b = src_arm.data.bones[sb]
        r_rest = flip @ (src_arm.matrix_world.to_3x3() @ b.matrix_local.to_3x3())
        r_src_rest_inv[tb] = r_rest.inverted()

    hips_rest_z = (src_arm.matrix_world @ src_arm.data.bones["DEF-hips"].head_local).z

    # T-pose -> our arms-down neutral offset (after +180Z flip: +X is right arm, -X is left arm)
    # Ry(+90 deg) rotates (+1,0,0) -> (0,0,-1) [right arm down]; Ry(-90 deg) rotates (-1,0,0) -> (0,0,-1) [left arm down]
    t_to_down_inv = {}
    for tb, _p, _pos in TARGET_BONES:
        if tb in ("sh_r", "el_r", "hand_r"):
            t_to_down_inv[tb] = Matrix.Rotation(math.pi * 0.5, 3, "Y").inverted()
        elif tb in ("sh_l", "el_l", "hand_l"):
            t_to_down_inv[tb] = Matrix.Rotation(-math.pi * 0.5, 3, "Y").inverted()
        else:
            t_to_down_inv[tb] = Matrix.Identity(3)

    # 2. Build clean target 17-bone Identity-rest Armature
    tgt_data = bpy.data.armatures.new("HumanoidCC0Armature")
    tgt_arm = bpy.data.objects.new("Skeleton3D", tgt_data)
    bpy.context.collection.objects.link(tgt_arm)
    bpy.context.view_layer.objects.active = tgt_arm
    bpy.ops.object.mode_set(mode="EDIT")
    ebones = {}
    parent_of = {}
    for bname, pname, pos in TARGET_BONES:
        eb = tgt_data.edit_bones.new(bname)
        eb.head = pos
        eb.tail = pos + Vector((0.0, 0.0, 0.12))
        eb.roll = 0.0
        if pname:
            eb.parent = ebones[pname]
        ebones[bname] = eb
        parent_of[bname] = pname
    bpy.ops.object.mode_set(mode="OBJECT")
    for pb in tgt_arm.pose.bones:
        pb.rotation_mode = "QUATERNION"

    # Match source actions via NLA track names AND bpy.data.actions (Blender glTF importer puts clip names on NLA tracks)
    src_actions = {}
    if src_arm.animation_data:
        for trk in src_arm.animation_data.nla_tracks:
            for st in trk.strips:
                if st.action:
                    src_actions[trk.name] = st.action
                    src_actions[st.name] = st.action
    for a in bpy.data.actions:
        src_actions.setdefault(a.name, a)
    print("Source actions available:", len(src_actions), sorted(src_actions.keys())[:10])
    if not src_arm.animation_data:
        src_arm.animation_data_create()
    # Mute/clear source NLA tracks so setting src_arm.animation_data.action directly evaluates cleanly
    for trk in list(src_arm.animation_data.nla_tracks):
        src_arm.animation_data.nla_tracks.remove(trk)
    tgt_arm.animation_data_create()

    baked = []
    for clip in WANT_CLIPS:
        act = src_actions.get(clip)
        if act is None:
            # Fuzzy match (e.g. if glTF importer prefixed Rig|)
            cand = [a for k, a in src_actions.items() if k.endswith(clip)]
            act = cand[0] if cand else None
        if act is None:
            print(f"  SKIP missing clip: {clip}")
            continue

        src_arm.animation_data.action = act
        f0 = int(round(act.frame_range[0]))
        f1 = int(round(act.frame_range[1]))
        new_act = bpy.data.actions.new(name=clip)
        tgt_arm.animation_data.action = new_act

        # Sample every 2nd frame for compact file size (15-30fps smooth slerp in Godot)
        step = 2 if (f1 - f0) >= 16 else 1
        frames = list(range(f0, f1 + 1, step))
        if frames[-1] != f1:
            frames.append(f1)

        prev_q = {}
        for f in frames:
            bpy.context.scene.frame_set(f)
            bpy.context.view_layer.update()
            world_rot = {}
            for tb, sb in SRC_OF.items():
                spb = src_arm.pose.bones[sb]
                r_pose = flip @ (src_arm.matrix_world.to_3x3() @ spb.matrix.to_3x3())
                world_rot[tb] = r_pose @ r_src_rest_inv[tb] @ t_to_down_inv[tb]

            # Hips vertical delta relative to rest height (for organic walk bob / crouch / sit / death drop)
            hips_z = (src_arm.matrix_world @ src_arm.pose.bones["DEF-hips"].head).z
            dy = hips_z - hips_rest_z
            pb_hips = tgt_arm.pose.bones["hips"]
            pb_hips.location = Vector((0.0, dy, 0.0))  # In bone local space (+Y is Blender +Z == Godot +Y!)
            pb_hips.keyframe_insert(data_path="location", frame=f - f0)

            for tb, _p, _pos in TARGET_BONES:
                pname = parent_of[tb]
                r_local = (world_rot[pname].inverted() @ world_rot[tb]) if pname else world_rot[tb]
                q = r_local.to_quaternion()
                if tb in prev_q and prev_q[tb].dot(q) < 0.0:
                    q = -q  # Keep quaternion hemisphere continuous for clean slerp
                prev_q[tb] = q.copy()
                pb = tgt_arm.pose.bones[tb]
                pb.rotation_quaternion = q
                pb.keyframe_insert(data_path="rotation_quaternion", frame=f - f0)

        # Push onto NLA track so glTF exporter writes ALL actions cleanly!
        trk = tgt_arm.animation_data.nla_tracks.new()
        trk.name = clip
        trk.strips.new(clip, 0, new_act)
        baked.append((clip, len(frames)))
        print(f"  BAKED {clip:22s} frames={f0}..{f1} ({len(frames)} keys)")

    # Delete source objects & unused actions, keep ONLY our clean target Skeleton3D + baked actions
    tgt_arm.animation_data.action = None
    for o in list(bpy.data.objects):
        if o != tgt_arm:
            bpy.data.objects.remove(o, do_unlink=True)
    keep_names = {c for c, _ in baked}
    for a in list(bpy.data.actions):
        if a.name not in keep_names:
            bpy.data.actions.remove(a, do_unlink=True)

    os.makedirs(os.path.dirname(OUT_GLB), exist_ok=True)
    bpy.ops.object.select_all(action="DESELECT")
    tgt_arm.select_set(True)
    bpy.context.view_layer.objects.active = tgt_arm
    bpy.ops.export_scene.gltf(
        filepath=OUT_GLB,
        export_format="GLB",
        export_yup=True,
        use_selection=True,
        export_animations=True,
        export_animation_mode="NLA_TRACKS",
        export_nla_strips=True,
        export_optimize_animation_size=True,
        export_optimize_animation_keep_anim_armature=True,
    )
    print(f"EXPORTED {OUT_GLB} ({os.path.getsize(OUT_GLB) // 1024} KB, {len(baked)} clips)")


if __name__ == "__main__":
    main()
