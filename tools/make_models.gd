extends SceneTree
## 그림 A(기획서 03 5절 — 3D SD 모델 · 툰 · 뼈대) 만들기: 스크립트로 피부 메시(관절에서 두 뼈에 나눠 걸린 가중치 — 팔꿈치 · 무릎이
## 종이처럼 꺾이지 않고 휜다) + 뼈대를 만들어 GLB 로 내보낸다. 사람 손 · 외부 업로드 없음.
##   <godot> --headless --path . -s res://tools/make_models.gd [-- 외형이름 ..]  → src/view/looks.gd ART 의 glb 파일
##   (assets/models/<id>_a.glb — 김신 · 신겐 · 0 · 1장 인물. 외형 이름을 주면 그것만 다시 만든다)
## Blender 를 쓰려 했으나 이 서버에서 받아 실행하는 것이 막혀(2026-11-06) Godot GLTFDocument 로 같은 일을 한다 — 게임은 GLB 를
## 가져와 끼우므로(src/view/puppet_glb.gd) 나중에 Blender · Mixamo · ArtCraft GLB 로 바꿔도 뼈 이름만 맞으면 된다.
## 뼈 이름 · 길이는 관절 인형(src/view/puppet3d.gd J)과 같다: hips · spine · chest · neck · head · sh_/el_/hand_ · th_/kn_/ft_ (r · l).
## 쉬는 자세의 뼈 회전은 모두 0(세계 축과 나란히) — 인형의 관절 각도를 그대로 뼈 회전으로 쓴다.
## SD 느낌: 머리를 크게(1.55배) · 몸통 · 팔다리를 둥글고 굵게 · 손발을 크게. 색은 정점 색(툰 재질은 게임에서 입힌다).

const Looks = preload("res://src/view/looks.gd")

var st: SurfaceTool
var bones := {}                  # 이름 → 번호
var gpos := {}                   # 이름 → 쉬는 자세 위치(뼈대 공간)


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute("res://assets/models")
	var only := OS.get_cmdline_user_args()
	var done := {}
	for id in Looks.ART:
		var path := str(Looks.ART[id]["glb"])
		if done.has(path) or (not only.is_empty() and not only.has(id)):
			continue
		done[path] = true
		var t0 := Time.get_ticks_msec()
		var err := _make(Looks.look(id), path)      # 원작 대조 겉모습(looks_common)을 덮은 표
		print("MODEL %s %s %dms" % [path, "ok" if err == OK else "error %d" % err, Time.get_ticks_msec() - t0])
	quit(0)


func _skeleton(lk: Dictionary) -> Skeleton3D:
	var sk := Skeleton3D.new()
	sk.name = "Skeleton3D"
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
	for row in table:
		var i := sk.get_bone_count()
		sk.add_bone(row[0])
		bones[row[0]] = i
		if row[1] != "":
			sk.set_bone_parent(i, bones[row[1]])
		sk.set_bone_rest(i, Transform3D(Basis(), row[2]))
		sk.set_bone_pose_position(i, row[2])
		gpos[row[0]] = (gpos[row[1]] if row[1] != "" else Vector3.ZERO) + row[2]
	return sk


func _make(lk: Dictionary, path: String) -> int:
	bones.clear()
	gpos.clear()
	var root := Node3D.new()
	root.name = path.get_file().get_basename()
	var sk := _skeleton(lk)
	root.add_child(sk)
	sk.owner = root
	st = SurfaceTool.new()
	st.set_skin_weight_count(SurfaceTool.SKIN_4_WEIGHTS)
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_body(lk)
	st.index()
	st.generate_normals()
	var mesh := st.commit()
	var mi := MeshInstance3D.new()
	mi.name = "Body"
	mi.mesh = mesh
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.roughness = 0.8
	mi.material_override = m
	var skin := Skin.new()
	for n in bones:
		skin.add_named_bind(n, Transform3D(Basis(), -gpos[n]))
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


# ----------------------------------------------------------------------
# 몸 — 관절을 지나는 관은 두 뼈에 가중치를 나눠 건다(부드러운 굽힘)
# 차림(look 칸 — 관절 인형 src/view/puppet3d.gd 와 같은 뜻): outfit suit · shirt(소매 걷은 셔츠) · coat(무릎까지 오는 코트) ·
# robe(가운 — 앞섶이 열리고 모피 깃) / collar tie · open(깃 푼 셔츠) · turtle(터틀넥)
func _body(lk: Dictionary) -> void:
	var big: bool = lk.get("big", false)
	var wide: float = lk.get("wide", 1.08 if big else 1.0)
	var limb: float = lk.get("limb", 1.0) * 1.12
	var depth: float = lk.get("depth", 1.0)
	var outfit := str(lk.get("outfit", "suit"))
	var shirt_only := outfit == "shirt"
	var robe := outfit == "robe"
	var long_coat := outfit == "coat" or robe
	var collar := str(lk.get("collar", "tie"))
	var suit: Color = lk["suit"]
	var pants: Color = lk["pants"]
	var shirt: Color = lk["shirt"]
	var skin: Color = lk["skin"]
	var hair: Color = lk["hair"]
	var shoe: Color = lk.get("shoe", Color(0.05, 0.05, 0.06))
	var top: Color = shirt if shirt_only else suit                  # 몸통 · 위팔 겉감
	var g := gpos
	# 골반 · 허리 · 가슴(하나로 이어진 몸통)
	_blob(g["hips"] + Vector3(0, -0.02, 0), Vector3(0.17 * wide, 0.13, 0.13 * depth), pants, "hips")
	_tube(g["hips"], g["chest"] + Vector3(0, 0.05, 0), 0.16 * wide, 0.19 * wide, top, "spine", "hips", "chest", depth)
	_blob(g["chest"] + Vector3(0, 0.1, 0), Vector3(0.23 * wide, 0.16, 0.15 * depth), top, "chest")
	if long_coat:                                                   # 옷자락 뒤판 — 앞 두 자락은 허벅지(아래)
		_blob(g["hips"] + Vector3(0, -0.24, 0.1 * depth), Vector3(0.17 * wide, 0.27, 0.05), top, "hips")
	if robe:
		# 가운: 깊게 파인 앞섶(맨가슴 · 가슴털) · 검은 모피 깃 · 허리끈
		_blob(g["chest"] + Vector3(0, 0.1, -0.135 * depth), Vector3(0.07, 0.13, 0.02), skin, "chest")
		if lk.get("chest_hair") != null:
			_blob(g["chest"] + Vector3(0, 0.12, -0.15 * depth), Vector3(0.04, 0.06, 0.012), lk["chest_hair"], "chest")
		var fur: Color = lk.get("fur", Color(0.06, 0.05, 0.05))
		for sx in [-1.0, 1.0]:
			_line(g["chest"] + Vector3(0.1 * sx * wide, 0.24, -0.08 * depth), g["chest"] + Vector3(0.03 * sx, 0.0, -0.15 * depth),
				0.035, fur, "chest")
		_blob(g["chest"] + Vector3(0, 0.25, 0.06 * depth), Vector3(0.15 * wide, 0.05, 0.08), fur, "chest")
		_blob(g["hips"] + Vector3(0, 0.07, 0), Vector3(0.175 * wide, 0.03, 0.135 * depth), suit.darkened(0.25), "hips")
	elif shirt_only:
		# 셔츠: 깃 푼 목 V(맨살) — 넥타이를 풀어 늘어뜨렸으면 비스듬히(윤덕수)
		_blob(g["chest"] + Vector3(0, 0.2, -0.13 * depth), Vector3(0.04, 0.05, 0.02), skin, "chest")
		if lk.get("tie") != null:
			_blob(g["chest"] + Vector3(0.015, 0.05, -0.15 * depth), Vector3(0.022, 0.1, 0.015), lk["tie"], "chest")
	else:
		# 셔츠 V · 넥타이(가슴 앞, -z) — 깃 푼 셔츠는 V 안에 맨가슴
		var vk: float = lk.get("v_k", 1.0) if collar == "open" else 1.0      # 앞섶을 더 풀어헤친 만큼(김성준)
		_blob(g["chest"] + Vector3(0, 0.12, -0.13 * depth), Vector3(0.05 * vk, 0.1, 0.02), shirt, "chest")
		if collar == "open":
			_blob(g["chest"] + Vector3(0, 0.22 - 0.05 * vk, -0.14 * depth), Vector3(0.028, 0.05, 0.015) * vk, skin, "chest")
		if lk.get("tie") != null:
			_blob(g["chest"] + Vector3(0, 0.06, -0.15 * depth), Vector3(0.022, 0.11, 0.015), lk["tie"], "chest")
	if lk.get("chain") != null:                                     # 금 사슬 목걸이(김혁주)
		_line(g["chest"] + Vector3(-0.08, 0.22, -0.1 * depth), g["chest"] + Vector3(0, 0.15, -0.15 * depth), 0.011, lk["chain"], "chest")
		_line(g["chest"] + Vector3(0.08, 0.22, -0.1 * depth), g["chest"] + Vector3(0, 0.15, -0.15 * depth), 0.011, lk["chain"], "chest")
	# 목 · 머리(SD — 크게). 터틀넥은 목까지 옷
	var neck_col: Color = shirt if collar == "turtle" and not shirt_only and not robe else skin
	_tube(g["neck"] + Vector3(0, -0.04, 0), g["head"], 0.06 * wide, 0.06 * wide, neck_col, "neck", "chest", "head")
	if lk.get("neck_tattoo") != null:
		_blob(g["neck"] + Vector3(0.055 * wide, 0.04, -0.01), Vector3(0.012, 0.045, 0.025), lk["neck_tattoo"], "neck")
	var hk: float = 1.55 * float(lk.get("head", 1.0))
	var hc: Vector3 = g["head"] + Vector3(0, 0.06 * hk, 0)
	_blob(hc, Vector3(0.12, 0.13, 0.12) * hk, skin, "head")
	if lk.get("mask") != null:
		_mask(lk, hc, hk)
	else:
		_face(lk, hc, hk)
		_hair(lk, hc, hk, hair)
		_props(lk, hc, hk)
	# 팔 · 다리
	var tat_side := str(lk.get("tattoo_side", "r"))
	for side in ["r", "l"]:
		var sh: Vector3 = g["sh_" + side]
		var el: Vector3 = g["el_" + side]
		var ha: Vector3 = g["hand_" + side]
		_blob(sh, Vector3(0.085, 0.08, 0.08) * limb, top, "sh_" + side)
		_tube(sh, el, 0.065 * limb, 0.055 * limb, top, "sh_" + side, "chest", "el_" + side)
		if shirt_only:
			# 소매 걷음: 아래팔은 맨살 + 팔꿈치 아래 걷어 올린 소매 뭉치 · 팔뚝 문신(비스듬히 감긴 띠)
			_tube(el, ha, 0.055 * limb, 0.045 * limb, skin, "el_" + side, "sh_" + side, "hand_" + side)
			_blob(el + Vector3(0, -0.04, 0), Vector3(0.068, 0.04, 0.068) * limb, shirt, "el_" + side)
			if lk.get("tattoo") != null and (tat_side == side or tat_side == "both"):
				var tc: Color = lk["tattoo"].lerp(skin, 0.25)
				for k in 3:
					var p: Vector3 = el.lerp(ha, 0.35 + 0.18 * k)
					_tube(p + Vector3(0, 0.012, 0), p - Vector3(0, 0.012, 0), 0.053 * limb - 0.003 * k, 0.053 * limb - 0.003 * k, tc, "el_" + side)
		else:
			_tube(el, ha, 0.055 * limb, 0.045 * limb, suit, "el_" + side, "sh_" + side, "hand_" + side)
		_blob(ha + Vector3(0, -0.05, 0), Vector3(0.055, 0.065, 0.05) * limb, skin, "hand_" + side)
		var wrist = lk.get("bracelet_" + side, lk.get("bracelet"))  # 손목 금 팔찌 · 검은 밴드
		if wrist != null:
			_tube(ha + Vector3(0, 0.035, 0), ha + Vector3(0, 0.005, 0), 0.052 * limb, 0.05 * limb, wrist, "el_" + side)
		if lk.get("rings") != null:                                 # 손가락 금반지(군터)
			_blob(ha + Vector3(0, -0.085, -0.03), Vector3(0.05, 0.014, 0.025) * limb, lk["rings"], "hand_" + side)
		var th: Vector3 = g["th_" + side]
		var kn: Vector3 = g["kn_" + side]
		var ft: Vector3 = g["ft_" + side]
		var sx := 1.0 if side == "r" else -1.0
		_tube(th, kn, 0.095 * limb * wide, 0.072 * limb, pants, "th_" + side, "hips", "kn_" + side)
		_tube(kn, ft, 0.07 * limb, 0.055 * limb, pants, "kn_" + side, "th_" + side, "ft_" + side)
		if long_coat:                                               # 옷자락 앞 자락 — 허벅지를 덮는다
			_tube(th + Vector3(0, 0.02, 0), kn + Vector3(0, 0.04, 0), 0.105 * limb * wide, 0.09 * limb * wide, top, "th_" + side, "hips")
		if lk.get("stripe") != null:                                # 트랙 바지 옆줄(서진태)
			var o0 := Vector3(sx * 0.093 * limb * wide, 0, 0)
			var o1 := Vector3(sx * 0.07 * limb, 0, 0)
			_tube(th + o0, kn + o1, 0.013, 0.013, lk["stripe"], "th_" + side, "", "kn_" + side)
			_tube(kn + o1, ft + Vector3(sx * 0.054 * limb, 0, 0), 0.013, 0.013, lk["stripe"], "kn_" + side, "th_" + side, "ft_" + side)
		_blob(ft + Vector3(0, -0.02, -0.06), Vector3(0.06, 0.045, 0.12) * sqrt(limb), shoe, "ft_" + side)
		if lk.get("sole") != null:                                  # 운동화 밑창
			_blob(ft + Vector3(0, -0.05, -0.06), Vector3(0.064, 0.016, 0.128) * sqrt(limb), lk["sole"], "ft_" + side)


func _face(lk: Dictionary, hc: Vector3, hk: float) -> void:
	var eye: Color = lk.get("eye_col", Color(0.06, 0.05, 0.05))
	var eh: float = 0.012 if float(lk.get("eye_h", 0.011)) < 0.009 else 0.02
	var brow_k: float = lk.get("brow_k", 1.0)
	for sx in [-1.0, 1.0]:
		_blob(hc + Vector3(0.045 * sx, 0.01, -0.112) * hk, Vector3(0.02, eh, 0.01) * hk, eye, "head")
		_blob(hc + Vector3(0.045 * sx, 0.045, -0.108) * hk, Vector3(0.026, 0.006 * brow_k, 0.01) * hk, lk["hair"].darkened(0.1), "head")
	_blob(hc + Vector3(0, -0.02, -0.118) * hk, Vector3(0.016, 0.022, 0.016) * hk, lk["skin"].darkened(0.08), "head")
	if lk.get("beard", false):
		_blob(hc + Vector3(0, -0.085, -0.085) * hk, Vector3(0.06, 0.035, 0.035) * hk, lk["hair"], "head")
	if lk.get("mustache", false):                                   # 끝이 처진 콧수염(군터)
		_blob(hc + Vector3(0, -0.045, -0.113) * hk, Vector3(0.042, 0.011, 0.012) * hk, lk["hair"], "head")
		for sx in [-1.0, 1.0]:
			_blob(hc + Vector3(0.04 * sx, -0.06, -0.104) * hk, Vector3(0.01, 0.02, 0.01) * hk, lk["hair"], "head")
	if lk.get("goatee", false):                                     # 염소수염(김성준)
		_blob(hc + Vector3(0, -0.11, -0.092) * hk, Vector3(0.024, 0.034, 0.02) * hk, lk["hair"], "head")
	var sc = lk.get("scar", false)
	var scol: Color = lk["skin"].darkened(0.35)
	if sc is String:
		_scar(str(sc), hc, hk, scol.lerp(Color(0.6, 0.2, 0.2), 0.3))
	elif sc:
		_blob(hc + Vector3(-0.07, -0.03, -0.1) * hk, Vector3(0.006, 0.03, 0.006) * hk, scol, "head")


## 흉터 자리(인형과 같은 이름): nose — 콧등에서 왼뺨 광대로 사선 + 입술 아래 ~ 턱 세로 · brow — 이마에서 눈썹으로 · double — 왼뺨 두 줄.
## 점은 머리 중심에서 본 방향(머리 크기 단위) — 얼굴 겉면 바로 위로 옮겨 붙인다(_on_head)
func _scar(kind: String, hc: Vector3, hk: float, col: Color) -> void:
	var r := 0.0048 * hk
	if kind == "nose":
		_line(_on_head(hc, hk, Vector3(0.0, 0.03, -0.12)), _on_head(hc, hk, Vector3(-0.08, -0.03, -0.1)), r, col, "head")
		_line(_on_head(hc, hk, Vector3(0.012, -0.075, -0.12)), _on_head(hc, hk, Vector3(0.014, -0.11, -0.1)), r, col, "head")
	elif kind == "brow":
		_line(_on_head(hc, hk, Vector3(0.036, 0.1, -0.1)), _on_head(hc, hk, Vector3(0.05, 0.03, -0.12)), r, col, "head")
	elif kind == "double":
		for k in 2:
			var o := Vector3(-0.014 * k, -0.016 * k, 0)
			_line(_on_head(hc, hk, Vector3(-0.045, 0.0, -0.12) + o), _on_head(hc, hk, Vector3(-0.09, -0.04, -0.1) + o), r, col, "head")


## 머리(타원체 0.12 · 0.13 · 0.12 × hk) 중심에서 dir 쪽 겉면 바로 바깥 점
func _on_head(hc: Vector3, hk: float, dir: Vector3) -> Vector3:
	var q := Vector3(dir.x / 0.12, dir.y / 0.13, dir.z / 0.12)
	return hc + dir / q.length() * hk * 1.015


## 눈만 뚫린 복면(DS 습격조): 머리 전체를 덮고 눈 자리만 살색 띠
func _mask(lk: Dictionary, hc: Vector3, hk: float) -> void:
	_blob(hc + Vector3(0, 0.003, 0) * hk, Vector3(0.128, 0.138, 0.128) * hk, lk["mask"], "head")
	_blob(hc + Vector3(0, 0.012, -0.118) * hk, Vector3(0.075, 0.022, 0.012) * hk, lk["skin"], "head")
	for sx in [-1.0, 1.0]:
		_blob(hc + Vector3(0.042 * sx, 0.012, -0.126) * hk, Vector3(0.018, 0.012, 0.008) * hk, Color(0.06, 0.05, 0.05), "head")


## 얼굴 소품: 색안경(sun — 검은 사각테, 렌즈 색 lens) · 머리띠 붕대 · 시가
func _props(lk: Dictionary, hc: Vector3, hk: float) -> void:
	var gl = lk.get("glasses", false)
	if gl is String:
		var lens: Color = lk.get("lens", Color(0.05, 0.05, 0.06))
		for sx in [-1.0, 1.0]:
			_blob(hc + Vector3(0.046 * sx, 0.012, -0.118) * hk, Vector3(0.034, 0.024, 0.008) * hk, Color(0.05, 0.05, 0.06), "head")
			_blob(hc + Vector3(0.046 * sx, 0.012, -0.124) * hk, Vector3(0.028, 0.019, 0.006) * hk, lens, "head")
			_blob(hc + Vector3(0.105 * sx, 0.02, -0.06) * hk, Vector3(0.006, 0.006, 0.05) * hk, Color(0.05, 0.05, 0.06), "head")
	if lk.get("bandage") != null:                                   # 머리띠처럼 감은 흰 붕대(강만재)
		_blob(hc + Vector3(0, 0.06, 0.005) * hk, Vector3(0.127, 0.03, 0.127) * hk, lk["bandage"], "head")
	if lk.get("cigar", false):                                      # 입에 문 시가(군터)
		var a: Vector3 = hc + Vector3(0.02, -0.065, -0.115) * hk
		var b: Vector3 = hc + Vector3(0.05, -0.075, -0.19) * hk
		_tube(a, b, 0.011 * hk, 0.012 * hk, Color(0.36, 0.22, 0.12), "head")
		_blob(b, Vector3(0.013, 0.013, 0.008) * hk, Color(1.0, 0.35, 0.1), "head")


## 머리 모양(인형과 같은 이름): spiky · bald · crew · buzz · short · long · ponytail · curly · undercut · fringe, 나머지는 뒤로 넘긴 올백
func _hair(lk: Dictionary, hc: Vector3, hk: float, hair: Color) -> void:
	var style := str(lk.get("hair_style", "short"))
	if style == "spiky":
		_blob(hc + Vector3(0, 0.05, 0.01) * hk, Vector3(0.125, 0.09, 0.125) * hk, hair, "head")
		for k in 9:
			var a := TAU * k / 9.0
			var base: Vector3 = hc + Vector3(0.07 * cos(a), 0.1, 0.07 * sin(a) + 0.01) * hk
			_cone(base, base + Vector3(0.06 * cos(a), 0.12, 0.06 * sin(a)) * hk, 0.035 * hk, hair, "head")
	elif style == "bald":
		pass
	elif style == "crew" or style == "buzz" or style == "short":
		# 아주 짧게 깎은 머리 — 머리통에 붙은 얇은 껍질
		_blob(hc + Vector3(0, 0.045, 0.012) * hk, Vector3(0.126, 0.096, 0.126) * hk, hair, "head")
		if style == "short":
			_blob(hc + Vector3(0, 0.1, -0.06) * hk, Vector3(0.08, 0.04, 0.05) * hk, hair, "head")
	elif style == "long":
		# 어깨까지 오는 장발(가운데 가르마)
		_blob(hc + Vector3(0, 0.05, 0.015) * hk, Vector3(0.13, 0.1, 0.13) * hk, hair, "head")
		_blob(hc + Vector3(0, -0.05, 0.06) * hk, Vector3(0.125, 0.15, 0.08) * hk, hair, "head")
		for sx in [-1.0, 1.0]:
			_blob(hc + Vector3(0.105 * sx, -0.045, -0.005) * hk, Vector3(0.035, 0.13, 0.08) * hk, hair, "head")
	elif style == "ponytail":
		# 뒤로 넘겨 하나로 묶은 머리 + 뒤통수에서 늘어진 꼬리
		_blob(hc + Vector3(0, 0.06, 0.025) * hk, Vector3(0.126, 0.085, 0.125) * hk, hair, "head")
		_blob(hc + Vector3(0, 0.0, 0.06) * hk, Vector3(0.115, 0.1, 0.08) * hk, hair, "head")
		_blob(hc + Vector3(0, -0.01, 0.135) * hk, Vector3(0.035, 0.035, 0.03) * hk, hair, "head")
		_cone(hc + Vector3(0, -0.01, 0.14) * hk, hc + Vector3(0, -0.24, 0.17) * hk, 0.04 * hk, hair, "head")
	elif style == "curly":
		# 눈을 덮는 흐트러진 곱슬머리 — 부푼 머리 + 둥근 뭉치, 앞머리가 눈썹까지
		_blob(hc + Vector3(0, 0.06, 0.02) * hk, Vector3(0.135, 0.1, 0.135) * hk, hair, "head")
		for k in 9:
			var a := TAU * k / 9.0
			_blob(hc + Vector3(0.1 * cos(a), 0.11, 0.1 * sin(a) + 0.015) * hk, Vector3(0.045, 0.04, 0.045) * hk, hair, "head")
		for k in 4:
			_blob(hc + Vector3(-0.06 + 0.04 * k, 0.05 - 0.01 * (k % 2), -0.112) * hk, Vector3(0.03, 0.035, 0.02) * hk, hair, "head")
	elif style == "undercut":
		# 옆 · 뒤를 짧게 민 투블럭(hair2) 위로 뒤로 넘긴 머리(서진태 금발 · 윤덕수)
		_blob(hc + Vector3(0, 0.035, 0.015) * hk, Vector3(0.125, 0.1, 0.125) * hk, lk.get("hair2", hair), "head")
		_blob(hc + Vector3(0, 0.1, 0.01) * hk, Vector3(0.105, 0.07, 0.125) * hk, hair, "head")
		_blob(hc + Vector3(0, 0.125, -0.07) * hk, Vector3(0.075, 0.05, 0.06) * hk, hair, "head")
	else:
		# 뒤로 넘긴 올백: 정수리 · 뒤통수를 덮고 이마 선은 높게 + 앞머리 몇 가닥(fringe 는 눈썹을 덮는 앞머리)
		_blob(hc + Vector3(0, 0.06, 0.025) * hk, Vector3(0.126, 0.085, 0.125) * hk, hair, "head")
		_blob(hc + Vector3(0, 0.0, 0.06) * hk, Vector3(0.115, 0.1, 0.08) * hk, hair, "head")
		if style == "slick_fringe":
			for k in 3:
				var b: Vector3 = hc + Vector3(-0.03 + 0.03 * k, 0.09, -0.11) * hk
				_cone(b, b + Vector3(0.005, -0.07, -0.01) * hk, 0.012 * hk, hair, "head")
		elif style == "fringe":
			for k in 7:                                             # 이마를 덮고 눈썹까지 내려오는 가닥(촘촘히 — 모자처럼 안 보이게)
				var x := -0.084 + 0.028 * k
				_cone(_on_head(hc, hk, Vector3(x * 0.9, 0.12, -0.06)), _on_head(hc, hk, Vector3(x * 1.05 + 0.006, 0.03, -0.12)),
					0.026 * hk, hair, "head")


# ---- 도형 (정점마다 뼈 · 가중치)
func _vert(p: Vector3, col: Color, b: Array, w: Array) -> void:
	st.set_color(col)
	var bi := PackedInt32Array([0, 0, 0, 0])
	var wi := PackedFloat32Array([0, 0, 0, 0])
	for k in b.size():
		bi[k] = bones[b[k]]
		wi[k] = w[k]
	st.set_bones(bi)
	st.set_weights(wi)
	st.add_vertex(p)


func _quad(a, b, c, d, cols: Array, wts: Array) -> void:
	# a b c d 는 [위치, 뼈 목록, 가중치 목록]
	for v in [a, c, b, a, d, c]:             # Godot 앞면 감기 방향(뒤집으면 외곽선 판만 보인다 — 첫 시도)
		_vert(v[0], cols[0], v[1], v[2])


## 관: p0(own 뼈 시작) → p1. 시작 쪽 30% 는 prev 뼈와, 끝 쪽 30% 는 next 뼈와 가중치를 나눈다(관절 가운데서 반반)
func _tube(p0: Vector3, p1: Vector3, r0: float, r1: float, col: Color, own: String, prev := "", next := "", dz := 1.0) -> void:
	var seg := 12
	var rings := 6
	var axis := (p1 - p0)
	var up := axis.normalized()
	var side := up.cross(Vector3.FORWARD if absf(up.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT).normalized()
	var fwd := side.cross(up).normalized()
	var rows: Array = []
	for i in rings + 1:
		var t := float(i) / rings
		var r := lerpf(r0, r1, t)
		var b: Array = [own]
		var w: Array = [1.0]
		if prev != "" and t < 0.3:
			var k := 0.5 * (1.0 - t / 0.3)
			b = [own, prev]
			w = [1.0 - k, k]
		elif next != "" and t > 0.7:
			var k2 := 0.5 * (t - 0.7) / 0.3
			b = [own, next]
			w = [1.0 - k2, k2]
		var row: Array = []
		for j in seg:
			var a := TAU * j / seg
			var p := p0 + axis * t + (side * cos(a) + fwd * sin(a) * dz) * r
			row.append([p, b, w])
		rows.append(row)
	for i in rings:
		for j in seg:
			var j2 := (j + 1) % seg
			_quad(rows[i][j], rows[i + 1][j], rows[i + 1][j2], rows[i][j2], [col], [])
	_cap(rows[0], p0, col, true)
	_cap(rows[rings], p1, col, false)


func _cap(row: Array, c: Vector3, col: Color, flip: bool) -> void:
	var cv: Array = [c, row[0][1], row[0][2]]
	for j in row.size():
		var a: Array = row[j]
		var b: Array = row[(j + 1) % row.size()]
		if not flip:
			for v in [cv, b, a]:
				_vert(v[0], col, v[1], v[2])
		else:
			for v in [cv, a, b]:
				_vert(v[0], col, v[1], v[2])


## 타원체(한 뼈에 단단히)
func _blob(c: Vector3, r: Vector3, col: Color, bone: String) -> void:
	var seg := 14
	var rings := 8
	var grid: Array = []
	for i in rings + 1:
		var v := PI * i / rings
		var row: Array = []
		for j in seg:
			var u := TAU * j / seg
			row.append([c + Vector3(sin(v) * cos(u) * r.x, cos(v) * r.y, sin(v) * sin(u) * r.z), [bone], [1.0]])
		grid.append(row)
	for i in rings:
		for j in seg:
			var j2 := (j + 1) % seg
			_quad(grid[i][j], grid[i][j2], grid[i + 1][j2], grid[i + 1][j], [col], [])


func _cone(base: Vector3, tip: Vector3, r: float, col: Color, bone: String) -> void:
	var up := (tip - base).normalized()
	var side := up.cross(Vector3.FORWARD if absf(up.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT).normalized()
	var fwd := side.cross(up)
	var n := 6
	for j in n:
		var a0 := TAU * j / n
		var a1 := TAU * (j + 1) / n
		var p0 := base + (side * cos(a0) + fwd * sin(a0)) * r
		var p1 := base + (side * cos(a1) + fwd * sin(a1)) * r
		for p in [p0, p1, tip]:
			_vert(p, col, [bone], [1.0])


## a → b 가는 줄(흉터 · 사슬 · 모피 깃) — a · b 를 끝으로 하는 기운 타원체 하나(조각을 이으면 외곽선이 마디마다 생긴다)
func _line(a: Vector3, b: Vector3, r: float, col: Color, bone: String) -> void:
	var half := (b - a) * 0.5
	var up := half.normalized()
	var side := up.cross(Vector3.FORWARD if absf(up.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT).normalized()
	var fwd := side.cross(up)
	var c := (a + b) * 0.5
	var seg := 10
	var rings := 8
	var grid: Array = []
	for i in rings + 1:
		var v := PI * i / rings
		var row: Array = []
		for j in seg:
			var u := TAU * j / seg
			row.append([c + up * cos(v) * (half.length() + r) + (side * cos(u) + fwd * sin(u)) * sin(v) * r, [bone], [1.0]])
		grid.append(row)
	for i in rings:
		for j in seg:
			var j2 := (j + 1) % seg
			_quad(grid[i][j], grid[i][j2], grid[i + 1][j2], grid[i + 1][j], [col], [])
