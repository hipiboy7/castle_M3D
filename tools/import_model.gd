extends SceneTree
## 그림 A 를 남이 만든 리깅 모델(CC0)로 — 받은 glTF/GLB 의 피부 메시를 이 판의 뼈대(make_models.gd 와 같은 이름 · 자리, 쉬는 회전 0)에
## 옮겨 앉혀 assets/models/<id>_a.glb 로 내보낸다. Blender 없이 Godot GLTFDocument 만 쓴다(2026-11-10 시험 — 김신 하나).
##   <godot> --headless --path . -s res://tools/import_model.gd [-- 외형이름 ..]      (기본: 표 SRC 의 전부)
## 원본은 저장소에 넣지 않는다 — .tools/model_src/ 에 받아 둔다(주소는 SRC 의 url, 받기: curl -L -o <src> <url>).
## 하는 일(정점마다 원본 가중치로 섞는 선형 피부 — 원본 묶음 자세(T 자세)를 우리 쉬는 자세(팔 내림)로 옮긴다):
##  1. 원본 묶음 자세(역묶음 행렬)의 관절 · 정점을 세계로, Y 축 180° 돌려 앞을 -Z(우리 앞)로, 골반 앞뒤 자리를 0 으로
##  2. 원본 뼈마다 옮김 W: 몸통(Hips ~ Chest · Shoulder · Neck)은 높이별 너비 배율(엉덩이 관절 → 어깨 관절) · 높이 맞춤,
##     팔다리는 원본 관절 → 우리 관절(방향 · 길이 맞춤, 굵기 t 배), 손은 아래팔 회전 + 크기 hand 배 + 손가락 말기(주먹), 발은 발바닥이 땅에
##  3. 원본 뼈 → 우리 뼈 가중치 합치기(RIG 표 — 손가락 → hand, 쇄골 → chest ..), 재질 이름 → 외형 색(정점 색 — 툰 재질은 게임이 입힌다)
##  4. 머리는 게임이 머리 뼈를 Looks.HEAD_K 배로 줄이므로(puppet_glb) 미리 1/HEAD_K 배 — 화면에서는 원본 비율 × head
## 다른 인물: SRC 에 한 줄(원본 · 외형 이름 · 색 표 · 굵기) — 뼈 이름이 다른 리그면 RIG 표를 하나 더. 이 표에 든 외형은 make_models.gd 가 건너뛴다.

const Looks = preload("res://src/view/looks.gd")

## 원본 리그(Quaternius 사람 리그 — Ultimate Modular Men 등) 뼈 → 우리 뼈 · 옮김 종류
## kind: torso(몸통 너비 · 높이 맞춤) · head · ua(위팔) · la(아래팔) · hand(손 · 손가락) · ul(허벅지) · ll(정강이) · foot
const RIG_QUATERNIUS := {
	"Root": ["hips", "torso"], "Body": ["hips", "torso"], "Hips": ["hips", "torso"], "Abdomen": ["spine", "torso"],
	"Torso": ["chest", "torso"], "Chest": ["chest", "torso"], "Neck": ["neck", "torso"], "Head": ["head", "head"],
	"Shoulder": ["chest", "torso"], "UpperArm": ["sh", "ua"], "LowerArm": ["el", "la"], "Wrist": ["hand", "hand"],
	"Index": ["hand", "hand"], "Middle": ["hand", "hand"], "Ring": ["hand", "hand"], "Pinky": ["hand", "hand"], "Thumb": ["hand", "hand"],
	"UpperLeg": ["th", "ul"], "LowerLeg": ["kn", "ll"], "Foot": ["ft", "foot"], "PT": ["ft", "foot"],
}

## 인물 표: src(.tools/model_src 아래) · url · 저작자 · 라이선스 · 외형 이름(looks.gd) · 출력 · 색(원본 재질[메시:재질] → 외형 칸) ·
## 굵기(arm · leg — 원본 대비) · hand(손 크기) · head(화면 머리 크기 — 원본 = 1) · depth(몸통 앞뒤) · curl(손가락 말기 도)
const SRC := {
	"kim": {"src": "res://.tools/model_src/polypizza/businessman_JFrLIKqvCH.glb",
		"url": "https://poly.pizza/m/JFrLIKqvCH (static.poly.pizza/e599abbe-7d73-488c-9d7e-3ead281e705c.glb)",
		"author": "Quaternius (Ultimate Modular Men — Suit)", "license": "CC0 1.0",
		"rig": "quaternius", "out": "res://assets/models/kimshin_a.glb",
		"colors": {"Suit_Legs:Suit": "pants", "Suit": "suit", "White": "shirt", "Tie": "tie", "Skin": "skin", "Hair": "hair",
			"Eyebrows": "brow", "Eye": "eye", "Black": "shoe"},
		"arm": 1.15, "leg": 0.95, "hand": 0.72, "head": 1.12, "depth": 1.15, "curl": [80.0, 95.0, 70.0],
		# 2026-11-11 화풍 2단계(사용자 '(가)' — 김신도 스크립트로 다시 깎기): 로우폴리라 각지고(rc.7 폰 리뷰) 안쪽 먹선 · 칠을 넣을 수 없어
		# make_models.gd 로 돌렸다. 표 · 도구는 남겨 둔다(active true 로 되돌리면 다시 이 원본으로)
		"active": false},
}

var tris := 0


func _initialize() -> void:
	var only := OS.get_cmdline_user_args()
	for id in SRC:
		if (not only.is_empty() and not only.has(id)) or not SRC[id].get("active", true):
			continue
		var t0 := Time.get_ticks_msec()
		var err := _convert(id, SRC[id])
		print("IMPORT %s %s %dms %d tris" % [SRC[id]["out"], "ok" if err == OK else "error %d" % err, Time.get_ticks_msec() - t0, tris])
	quit(0)


# ----------------------------------------------------------------------
# 우리 뼈대(make_models.gd _skeleton · 관절 인형 puppet3d 와 같은 자리)
func _our_joints(lk: Dictionary) -> Array:
	var wide: float = lk.get("wide", 1.08 if lk.get("big", false) else 1.0)
	var sh_wide: float = lk.get("shoulder", wide)
	var table := [
		["hips", "", Vector3(0, 0.97, 0)], ["spine", "hips", Vector3(0, 0.02, 0)], ["chest", "spine", Vector3(0, 0.27, 0)],
		["neck", "chest", Vector3(0, 0.215, 0)], ["head", "neck", Vector3(0, 0.135, 0)],
	]
	for side in ["r", "l"]:
		var sx := 1.0 if side == "r" else -1.0
		table.append(["sh_" + side, "chest", Vector3(sx * 0.2 * sh_wide, 0.165, 0)])
		table.append(["el_" + side, "sh_" + side, Vector3(0, -0.29, 0)])
		table.append(["hand_" + side, "el_" + side, Vector3(0, -0.26, 0)])
		table.append(["th_" + side, "hips", Vector3(sx * 0.095 * wide, -0.03, 0)])
		table.append(["kn_" + side, "th_" + side, Vector3(0, -0.45, 0)])
		table.append(["ft_" + side, "kn_" + side, Vector3(0, -0.44, 0)])
	return table


## 원본 뼈 이름 → [우리 뼈(쪽 붙임), 종류, 쪽 "r"|"l"|""]
static func _map_bone(rig: Dictionary, name: String) -> Array:
	var base := name
	var side := ""
	if name.ends_with(".L") or name.ends_with(".R"):
		base = name.substr(0, name.length() - 2)
		side = "l" if name.ends_with(".L") else "r"
	var key := base.rstrip("0123456789")
	if not rig.has(key):
		return []
	var ours: String = rig[key][0]
	if side != "" and ours in ["sh", "el", "hand", "th", "kn", "ft"]:
		ours += "_" + side
	return [ours, rig[key][1], side, key]


## 방향 a→b 를 A→B 로: 회전 + 뼈 방향으로 길이 배, 옆으로 t 배
static func _seg_fit(a: Vector3, b: Vector3, A: Vector3, B: Vector3, t: float) -> Transform3D:
	var d := (b - a).normalized()
	var D := (B - A).normalized()
	var L := (B - A).length() / maxf((b - a).length(), 1e-6)
	var S := Basis.from_scale(Vector3.ONE * t)
	# t·I + (L - t)·d dᵀ
	var dd := Basis(d * d.x, d * d.y, d * d.z)                     # 열 = d * d_i → d dᵀ
	S = Basis(S.x + dd.x * (L - t), S.y + dd.y * (L - t), S.z + dd.z * (L - t))
	var R := Basis(Quaternion(d, D)) if d.dot(D) > -0.9999 else Basis(Vector3.FORWARD, PI)
	var M := R * S
	return Transform3D(M, A - M * a)


func _convert(id: String, cfg: Dictionary) -> int:
	var lk: Dictionary = Looks.look(id)
	var rig: Dictionary = RIG_QUATERNIUS
	# --- 원본 읽기
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	var err := doc.append_from_file(ProjectSettings.globalize_path(str(cfg["src"])), state)
	if err != OK:
		return err
	var root: Node = doc.generate_scene(state)
	var sk: Skeleton3D = root.find_children("*", "Skeleton3D", true, false)[0]
	var G := Transform3D()
	var n: Node = sk
	while n != null and n is Node3D:
		G = (n as Node3D).transform * G
		n = n.get_parent()
	var flip := Transform3D(Basis(Vector3.UP, PI), Vector3.ZERO)   # 원본 앞 +Z → 우리 앞 -Z
	# 묶음 자세 관절(세계 · 우리 앞)
	var sj := {}                                                    # 원본 뼈 번호 → 자리
	var meshes: Array = root.find_children("*", "MeshInstance3D", true, false)
	for mi in meshes:
		var skin: Skin = mi.skin
		for bi in skin.get_bind_count():
			var b := skin.get_bind_bone(bi)
			if b < 0:
				b = sk.find_bone(skin.get_bind_name(bi))
			sj[b] = (flip * G * skin.get_bind_pose(bi).affine_inverse()).origin
	var info := {}                                                  # 원본 뼈 번호 → _map_bone
	var by_key := {}                                                # "UpperArm_r" → 뼈 번호 (첫 번째)
	for b in sk.get_bone_count():
		var m := _map_bone(rig, sk.get_bone_name(b))
		info[b] = m
		if not m.is_empty():
			var k: String = m[3] + ("_" + m[2] if m[2] != "" else "")
			if not by_key.has(k):
				by_key[k] = b
	var zc: float = sj[by_key["Hips"]].z
	for b in sj:
		sj[b] = sj[b] - Vector3(0, 0, zc)
	var pre := Transform3D(Basis(), Vector3(0, 0, -zc)) * flip * G     # 원본 정점 → 우리 앞 · 앞뒤 0
	# --- 우리 뼈대
	var table := _our_joints(lk)
	var gpos := {}
	var bones := {}
	for row in table:
		bones[row[0]] = bones.size()
		gpos[row[0]] = (gpos[row[1]] if row[1] != "" else Vector3.ZERO) + row[2]
	var P := func(k: String) -> Vector3: return sj[by_key[k]]
	# --- 몸통 옮김: 높이 닻(엉덩이 관절 · 어깨 관절 · 목) · 너비 배율(엉덩이 → 어깨 → 목 1)
	var s_hip: Vector3 = P.call("UpperLeg_r")
	var s_sh: Vector3 = P.call("UpperArm_r")
	var s_neck: Vector3 = P.call("Neck")
	var ys := [s_hip.y, s_sh.y, s_neck.y]
	var yt := [gpos["th_r"].y, gpos["sh_r"].y, gpos["neck"].y]
	var kx := [absf(gpos["th_r"].x / s_hip.x), absf(gpos["sh_r"].x / s_sh.x), 1.0]
	var kz: float = cfg.get("depth", 1.0)
	var torso_k := func(y: float) -> Array:                        # [x 배, 새 y, dy'/dy] — 닻 사이는 직선, 바깥은 기울기 1
		if y <= ys[0]:
			return [kx[0], yt[0] + (y - ys[0]), 1.0]
		if y >= ys[2]:
			return [kx[2], yt[2] + (y - ys[2]), 1.0]
		var i := 0 if y <= ys[1] else 1
		var u: float = (y - ys[i]) / (ys[i + 1] - ys[i])
		var slope: float = (yt[i + 1] - yt[i]) / (ys[i + 1] - ys[i])
		return [lerpf(kx[i], kx[i + 1], u), yt[i] + (y - ys[i]) * slope, slope]
	# --- 팔다리 옮김(쪽마다)
	var W := {}                                                     # 원본 뼈 번호 → Transform3D (몸통은 없음 = torso_k)
	var hand_k: float = cfg.get("hand", 1.0)
	var head_k: float = float(cfg.get("head", 1.0)) / Looks.HEAD_K
	var curl: Array = cfg.get("curl", [])
	var seg := {}
	for side in ["r", "l"]:
		var ua: Vector3 = P.call("UpperArm_" + side)
		var la: Vector3 = P.call("LowerArm_" + side)
		var wr: Vector3 = P.call("Wrist_" + side)
		var ul: Vector3 = P.call("UpperLeg_" + side)
		var ll: Vector3 = P.call("LowerLeg_" + side)
		var ft: Vector3 = P.call("Foot_" + side)
		var ft_t: Vector3 = gpos["ft_" + side]
		ft_t.y = ft.y                                               # 발목 높이는 원본대로 — 발바닥이 땅(y 0)에
		var ta: float = cfg.get("arm", 1.0)
		var tl: float = cfg.get("leg", 1.0)
		seg["ua_" + side] = _seg_fit(ua, la, gpos["sh_" + side], gpos["el_" + side], ta)
		seg["la_" + side] = _seg_fit(la, wr, gpos["el_" + side], gpos["hand_" + side], ta)
		var la_t: Transform3D = seg["la_" + side]
		var hb := la_t.basis.orthonormalized() * Basis.from_scale(Vector3.ONE * hand_k)
		seg["hand_" + side] = Transform3D(hb, gpos["hand_" + side] - hb * wr)
		seg["ul_" + side] = _seg_fit(ul, ll, gpos["th_" + side], gpos["kn_" + side], tl)
		seg["ll_" + side] = _seg_fit(ll, ft, gpos["kn_" + side], ft_t, tl)
		var fb := Basis.from_scale(Vector3(tl, 1.0, 1.0))
		seg["foot_" + side] = Transform3D(fb, ft_t - fb * ft)
	var s_head: Vector3 = P.call("Head")
	var tk: Array = torso_k.call(s_head.y)
	var head_t := Vector3(s_head.x * tk[0], tk[1], s_head.z * kz)   # 원본 목 길이 그대로(우리 머리 관절보다 낮을 수 있다)
	var hpiv: Vector3 = gpos["head"]
	# 머리: 원본 머리 관절 → head_t 로 옮긴 뒤, 우리 머리 관절을 중심으로 head_k 배(게임이 HEAD_K 배로 줄인다)
	var head_w := Transform3D(Basis.from_scale(Vector3.ONE * head_k), hpiv - hpiv * head_k) * Transform3D(Basis(), head_t - s_head)
	# 손가락 말기(주먹): 원본 자리에서 마디마다 돌림 — 손바닥(-y) 쪽으로
	var prepose := {}
	for b in sk.get_bone_count():
		var m: Array = info[b]
		var T := Transform3D()
		var par := sk.get_bone_parent(b)
		if par >= 0 and prepose.has(par):
			T = prepose[par]
		if not m.is_empty() and m[3] in ["Index", "Middle", "Ring", "Pinky"] and not curl.is_empty():
			var num := int(sk.get_bone_name(b).get_slice(".", 0).right(1))
			if num >= 2 and num - 2 < curl.size() and sj.has(b):
				var wr2: Vector3 = P.call("Wrist_" + m[2])
				var dh: Vector3 = (sj[b] - wr2).normalized()
				var axis := dh.cross(Vector3.DOWN).normalized()
				var R := Basis(axis, deg_to_rad(float(curl[num - 2])))
				var j: Vector3 = sj[b]
				T = T * Transform3D(R, j - R * j)
		prepose[b] = T
	for b in sk.get_bone_count():
		var m: Array = info[b]
		if m.is_empty():
			continue
		match m[1]:
			"head":
				W[b] = head_w
			"ua", "la", "ul", "ll", "foot":
				W[b] = seg[m[1] + "_" + m[2]]
			"hand":
				W[b] = seg["hand_" + m[2]] * prepose[b]
	# --- 정점 옮기기
	var cols := {"suit": lk["suit"], "pants": lk["pants"], "shirt": lk["shirt"], "tie": _col(lk, "tie", lk["suit"]),
		"skin": lk["skin"], "hair": Looks.hair_lift(lk["hair"]), "brow": Looks.hair_lift(lk["hair"]).darkened(0.3),
		"eye": _col(lk, "eye_col", Color(0.07, 0.05, 0.05)), "shoe": _col(lk, "shoe", Color(0.05, 0.05, 0.06))}
	var out_v := PackedVector3Array()
	var out_n := PackedVector3Array()
	var out_c := PackedColorArray()
	var out_b := PackedInt32Array()
	var out_w := PackedFloat32Array()
	var out_i := PackedInt32Array()
	var miss := {}
	for mi in meshes:
		var skin: Skin = mi.skin
		var mesh: Mesh = mi.mesh
		for s in mesh.get_surface_count():
			var a := mesh.surface_get_arrays(s)
			var mat := mesh.surface_get_material(s)
			var mname := mat.resource_name if mat else ""
			var ckey: String = cfg["colors"].get("%s:%s" % [mi.name, mname], cfg["colors"].get(mname, ""))
			if ckey == "":
				miss[mname] = true
			var col: Color = cols.get(ckey, Color.MAGENTA)
			var vs: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
			var ns: PackedVector3Array = a[Mesh.ARRAY_NORMAL]
			var bs: PackedInt32Array = a[Mesh.ARRAY_BONES]
			var ws: PackedFloat32Array = a[Mesh.ARRAY_WEIGHTS]
			var nb := bs.size() / vs.size()
			var base := out_v.size()
			for i in vs.size():
				var v: Vector3 = pre * vs[i]
				var nn: Vector3 = (pre.basis * ns[i]).normalized()
				var p := Vector3.ZERO
				var q := Vector3.ZERO
				var acc := {}
				var wsum := 0.0
				for k in nb:
					var w := ws[i * nb + k]
					if w <= 0.0:
						continue
					var bi := bs[i * nb + k]
					var b := skin.get_bind_bone(bi)
					if b < 0:
						b = sk.find_bone(skin.get_bind_name(bi))
					var m: Array = info[b]
					if m.is_empty():
						continue
					if W.has(b):
						var t: Transform3D = W[b]
						p += w * (t * v)
						q += w * (t.basis.inverse().transposed() * nn)
					else:
						var r: Array = torso_k.call(v.y)
						p += w * Vector3(v.x * r[0], r[1], v.z * kz)
						q += w * Vector3(nn.x / r[0], nn.y / r[2], nn.z / kz)
					acc[m[0]] = acc.get(m[0], 0.0) + w
					wsum += w
				out_v.append(p / wsum)
				out_n.append(q.normalized())
				out_c.append(col)
				var keys := acc.keys()
				keys.sort_custom(func(x, y): return acc[x] > acc[y])
				for k in 4:
					if k < keys.size():
						out_b.append(bones[keys[k]])
						out_w.append(acc[keys[k]] / wsum)
					else:
						out_b.append(0)
						out_w.append(0.0)
			var idx: PackedInt32Array = a[Mesh.ARRAY_INDEX]
			for k in idx.size():
				out_i.append(base + idx[k])
	if not miss.is_empty():
		push_warning("색 없는 재질: %s" % [miss.keys()])
	tris = out_i.size() / 3
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = out_v
	arr[Mesh.ARRAY_NORMAL] = out_n
	arr[Mesh.ARRAY_COLOR] = out_c
	arr[Mesh.ARRAY_BONES] = out_b
	arr[Mesh.ARRAY_WEIGHTS] = out_w
	arr[Mesh.ARRAY_INDEX] = out_i
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	root.free()
	return _export(am, table, bones, gpos, str(cfg["out"]))


static func _col(lk: Dictionary, k: String, dflt: Color) -> Color:
	return lk[k] if lk.get(k) is Color else dflt


func _export(mesh: ArrayMesh, table: Array, bones: Dictionary, gpos: Dictionary, path: String) -> int:
	var root := Node3D.new()
	root.name = path.get_file().get_basename()
	var sk := Skeleton3D.new()
	sk.name = "Skeleton3D"
	for row in table:
		var i := sk.get_bone_count()
		sk.add_bone(row[0])
		if row[1] != "":
			sk.set_bone_parent(i, bones[row[1]])
		sk.set_bone_rest(i, Transform3D(Basis(), row[2]))
		sk.set_bone_pose_position(i, row[2])
	root.add_child(sk)
	sk.owner = root
	var mi := MeshInstance3D.new()
	mi.name = "Body"
	mi.mesh = mesh
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.roughness = 0.8
	mi.material_override = m
	var skin := Skin.new()
	for nm in bones:
		skin.add_named_bind(nm, Transform3D(Basis(), -gpos[nm]))
	mi.skin = skin
	sk.add_child(mi)
	mi.owner = root
	mi.skeleton = NodePath("..")
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	var err := doc.append_from_scene(root, state)
	if err == OK:
		err = doc.write_to_filesystem(state, ProjectSettings.globalize_path(path))
	root.free()
	return err
