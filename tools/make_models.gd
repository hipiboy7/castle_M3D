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
const Imported = preload("res://tools/import_model.gd")    # 외부 모델로 옮긴 외형(SRC — 김신 2026-11-10 시험)은 여기서 만들지 않는다

var st: SurfaceTool
var bones := {}                  # 이름 → 번호
var sheen_hair = null            # 머리 윤기 — 이 색의 큰 머리 껍질 _blob 은 앞쪽 위 띠 정점을 sheen_col 로(_sheen_on)
var sheen_col := Color.WHITE
var gpos := {}                   # 이름 → 쉬는 자세 위치(뼈대 공간)
const FEM_HEAD := Vector3(0.112, 0.13, 0.117)   # 여성 머리 타원체(갸름하게 — 남성 0.12 · 0.13 · 0.12)
const FACE_LIFT := 0.0007                       # 얼굴 조각(_patch)이 머리 겉면에서 뜨는 기본 높이(머리 단위 — 살과 겹쳐 깜빡이지 않게)
const MALE_HEAD := Vector3(0.12, 0.13, 0.12)    # 남성 머리 타원체(머리 단위 — 머리털 · 모자 껍질이 이 크기에 맞춰져 있다)
## 남성 머리 다듬기(_head_male · 얼굴 조각이 같은 겉면을 따른다): 아래쪽 x 를 (1 - x · low^y) 로 좁히고 z 를 (1 - z · low²) 로,
## 턱은 MALE_CHIN 만큼 아래로 늘인다(둥근 공 얼굴 → 턱선). 각진 턱(jaw)은 늦게(지수 크게) 좁혀 광대 · 턱 모서리가 넓게 남는다
const MALE_WARP := Vector3(0.26, 1.5, 0.08)
const MALE_WARP_JAW := Vector3(0.3, 2.3, 0.05)
const MALE_CHIN := 0.07
var head_warp := Vector3.ZERO    # 지금 머리의 다듬기(남성 머리를 만드는 동안만 — 여성 · 복면은 0)
var tris := 0                    # 마지막으로 만든 메시의 삼각형 수(MODEL 줄 — 폰 예산 확인)


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute("res://assets/models")
	DirAccess.make_dir_recursive_absolute(Looks.ROSTER_DIR + "/models")
	var only := OS.get_cmdline_user_args()
	var done := {}
	for id in Looks.art_names():
		var path := str(Looks.art_of(id)["glb"])
		if done.has(path) or (not only.is_empty() and not only.has(id)):
			continue
		done[path] = true
		if Imported.SRC.has(id):
			print("MODEL %s skip — tools/import_model.gd" % path)
			continue
		var t0 := Time.get_ticks_msec()
		var err := _make(Looks.look(id), path)      # 원작 대조 겉모습(looks_common)을 덮은 표
		print("MODEL %s %s %dms %d tris" % [path, "ok" if err == OK else "error %d" % err, Time.get_ticks_msec() - t0, tris])
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
	tris = mesh.surface_get_array_index_len(0) / 3
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
	var vest := outfit == "vest"                                    # 조끼 · 긴소매 블라우스 — 팔은 셔츠 소매
	var skirt: bool = lk.get("skirt", false)                        # 펜슬 스커트 — 정강이 맨살
	var shorts: bool = lk.get("shorts", false)                      # 반바지 — 정강이 맨살(스커트 자락 없이)
	var fem: bool = lk.get("female", false)                         # 여성 — 가슴 · 가는 허리 · 넓은 골반(전인물 외형 2026-11-06)
	var jacket := outfit == "jacket"                                # 캐주얼 겉옷(봄버 · 트랙 · 후드 · 패딩) — 깃 · 넥타이 없이 지퍼
	var sleeveless: bool = lk.get("sleeveless", false)              # 민소매 — 팔 맨살
	var collar := str(lk.get("collar", "tie"))
	var suit: Color = lk["suit"]
	var pants: Color = lk["pants"]
	var shirt: Color = lk["shirt"]
	var skin: Color = lk["skin"]
	var hair: Color = Looks.hair_lift(lk["hair"])
	var shoe: Color = lk.get("shoe", Color(0.05, 0.05, 0.06))
	var top: Color = shirt if shirt_only else suit                  # 몸통 겉감
	var arm: Color = shirt if shirt_only or vest else suit          # 팔 겉감
	if sleeveless:
		arm = skin
	var g := gpos
	# 골반 · 허리 · 가슴(하나로 이어진 몸통) — 여성은 골반을 넓히고 허리를 조인다
	var hip_k := 1.14 if fem else 1.0
	# 몸통 관의 앞뒤 두께(dz)는 골반 · 가슴 타원체와 겉면이 맞게 — 관이 더 두꺼우면 가슴 아래 턱 · 검은 띠(외곽선)가 생기고
	# 셔츠 앞판이 관 속에 묻혔다(전인물 외형 검토 2026-11-06). bz = 가슴 앞 겉면(머리 · 셔츠 앞판 자리)
	var bz := 0.15 * depth * maxf(1.0, wide)
	# 몸통은 한 겹 관(_loft) 두 벌 — 바지(골반) + 겉옷(밑단 ~ 목). 전에는 골반 · 허리 · 가슴 덩어리 셋이 겹쳐 허리에 턱이 지고
	# 외곽선이 마디마다 그어졌다(폰 리뷰 2026-11-07 '울퉁불퉁'). 단면 너비 표 _torso_prof — 가슴 앞 겉면은 그대로 bz(셔츠 앞판 · 넥타이 자리)
	var hz := 0.13 * depth * maxf(1.0, wide * 0.95)
	var prof := _torso_prof(wide, float(lk.get("shoulder", wide)), hip_k, 0.84 if fem else 1.0, 0.92 if fem else 1.0, hz, bz)
	var hem := -0.09                                                # 겉옷 밑단(골반 뼈 기준 높이) — 정장 · 코트는 엉덩이를 덮는다
	if jacket:
		hem = -0.005                                                # 봄버 · 트랙: 허리 밴드
	elif shirt_only or vest:
		hem = 0.025                                                 # 바지에 넣은 셔츠 · 조끼 + 허리띠
	var thigh_out := 0.095 * wide + 0.095 * limb * wide             # 허벅지 바깥 끝 — 겉옷 밑단이 그보다 넓게(다리가 뚫고 나오지 않게)
	_torso_loft(prof, [-0.14, -0.1, -0.05, 0.0, 0.05, 0.1, 0.14], 0.0, pants, -1.0, -1.0, 0.04, 0.03)
	var ys: Array = [hem, hem + 0.012]
	var yy := hem + 0.055
	while yy < 0.48:
		ys.append(yy)
		yy += 0.06
	ys.append_array([0.505, 0.53, 0.545])
	_torso_loft(prof, ys, 0.008, top, thigh_out + 0.012, 0.122, -1.0, 0.03)
	if jacket:
		_torso_loft(prof, [hem - 0.002, hem + 0.045], 0.016, top.darkened(0.25), thigh_out + 0.018, 0.128, -1.0, -1.0)   # 허리 밴드(골지)
	elif shirt_only or vest:
		_torso_loft(prof, [0.0, 0.045], 0.014, lk.get("belt", pants.darkened(0.55)), -1.0, -1.0, -1.0, -1.0)            # 허리띠
	if fem:                                                         # 가슴
		for sx in [-1.0, 1.0]:
			_blob(g["chest"] + Vector3(0.068 * sx * wide, 0.06, -bz * 0.68), Vector3(0.07 * wide, 0.065, 0.07 * depth), top, "chest")
	if skirt:                                                       # 스커트(골반 ~ 무릎)
		_blob(g["hips"] + Vector3(0, -0.24, 0), Vector3(0.19 * wide, 0.28, 0.14 * depth), pants, "hips")
	if long_coat:                                                   # 옷자락 뒤판 — 앞 두 자락은 허벅지(아래)
		_blob(g["hips"] + Vector3(0, -0.24, 0.1 * depth), Vector3(0.17 * wide, 0.27, 0.05), top, "hips")
	if robe:
		# 가운: 깊게 파인 앞섶(맨가슴 · 가슴털) · 검은 모피 깃 · 허리끈
		_blob(g["chest"] + Vector3(0, 0.1, -bz * 0.92), Vector3(0.07, 0.13, 0.02), skin, "chest")
		if lk.get("chest_hair") != null:
			_blob(g["chest"] + Vector3(0, 0.12, -bz * 1.0), Vector3(0.04, 0.06, 0.012), lk["chest_hair"], "chest")
		var fur: Color = lk.get("fur", Color(0.06, 0.05, 0.05))
		for sx in [-1.0, 1.0]:
			_line(g["chest"] + Vector3(0.1 * sx * wide, 0.24, -bz * 0.55), g["chest"] + Vector3(0.03 * sx, 0.0, -bz * 1.0),
				0.035, fur, "chest")
		_blob(g["chest"] + Vector3(0, 0.25, bz * 0.4), Vector3(0.15 * wide, 0.05, 0.08), fur, "chest")
		_blob(g["hips"] + Vector3(0, 0.07, 0), Vector3(0.175 * wide, 0.03, 0.14 * depth * maxf(1.0, wide * 0.95)), suit.darkened(0.25), "hips")
	elif shirt_only:
		# 셔츠: 깃 푼 목 V(맨살) — 넥타이를 풀어 늘어뜨렸으면 비스듬히(윤덕수). 둥근 목 티(crew)는 V 없음
		if collar != "crew":
			_blob(g["chest"] + Vector3(0, 0.2, -bz * 0.8), Vector3(0.04, 0.05, 0.02), skin, "chest")
		if lk.get("tie") != null:
			_blob(g["chest"] + Vector3(0.015, 0.05, -bz * 1.0), Vector3(0.022, 0.1, 0.015), lk["tie"], "chest")
	elif jacket:
		# 캐주얼 겉옷: 가운데 지퍼 줄 + 목에 안감(셔츠) 띠 — V · 넥타이 없음
		_line(g["chest"] + Vector3(0, 0.22, -bz * 0.93), g["chest"] + Vector3(0, -0.12, -bz * 1.04), 0.006, suit.darkened(0.35), "chest")
		_blob(g["chest"] + Vector3(0, 0.23, -bz * 0.62), Vector3(0.07, 0.03, 0.04), shirt, "chest")
	else:
		# 셔츠 V · 넥타이(가슴 앞, -z) — 깃 푼 셔츠는 V 안에 맨가슴
		# 앞판(가슴 겉면 bz 위로 조금 나오게 — 전에는 가슴 속에 묻혀 흰 셔츠 · 넥타이가 점으로만 보였다): 깃 푼 셔츠 · 티는 넓게,
		# 넥타이 셔츠는 V. 옷깃(라펠) 두 줄이 V 가장자리를 따라 내려와 재킷으로 읽히게(아킬라 · 김용성 — 재킷 색이 살빛에 가까움)
		var vk: float = lk.get("v_k", 1.0) if collar == "open" else 1.0      # 앞섶을 더 풀어헤친 만큼(김성준)
		var pw := 0.085 if collar == "crew" or collar == "turtle" else (0.062 * vk if collar == "open" else 0.055)
		if lk.get("inner") != null:                                 # 겉옷 안 정장(outfit.inner — 크로트 트렌치 안 남색 정장): 열린 앞섶에 넓게
			_blob(g["chest"] + Vector3(0, 0.08, -bz * 0.85), Vector3(0.13 * wide, 0.17, 0.035), lk["inner"], "chest")
			_blob(g["hips"] + Vector3(0, 0.06, -0.12 * depth * maxf(1.0, wide * 0.95)), Vector3(0.12 * wide, 0.09, 0.03), lk["inner"], "hips")
		_blob(g["chest"] + Vector3(0, 0.12, -bz * 0.93), Vector3(pw, 0.12, 0.03), shirt, "chest")
		if collar == "open":
			_blob(g["chest"] + Vector3(0, 0.2 - 0.04 * vk, -bz * 0.97), Vector3(0.03, 0.05, 0.02) * vk, skin, "chest")
		if lk.get("tie") != null:
			_blob(g["chest"] + Vector3(0, 0.08, -bz * 0.97 - 0.012), Vector3(0.022, 0.11, 0.015), lk["tie"], "chest")
		var has_cc: bool = lk.get("coat_collar") != null            # 겉옷 깃 색(outfit.outer.collar — 마준영 롱코트 베이지 깃): 넓은 깃 + 목 뒤 깃
		var lap: Color = suit.darkened(0.3)
		if has_cc:
			lap = lk["coat_collar"]
		for sx in [-1.0, 1.0]:
			_line(g["chest"] + Vector3(0.075 * sx, 0.25, -bz * 0.78), g["chest"] + Vector3((pw + 0.005) * sx, 0.0, -bz * 1.02),
				0.026 if has_cc else 0.01, lap, "chest")
		if has_cc:
			var cc: Color = lk["coat_collar"]
			_blob(g["chest"] + Vector3(0, 0.25, bz * 0.35), Vector3(0.14 * wide, 0.045, 0.08), cc, "chest")
	if lk.get("holster") != null:                                   # 등 X자 가죽 멜빵 + 앞 어깨끈(백도찬 · 황보민철)
		var hcol: Color = lk["holster"]
		for sx in [-1.0, 1.0]:
			_line(g["chest"] + Vector3(0.17 * sx * wide, 0.22, bz * 0.93), g["chest"] + Vector3(-0.13 * sx * wide, -0.1, bz * 0.93), 0.018, hcol, "chest")
			_line(g["chest"] + Vector3(0.13 * sx * wide, 0.24, -bz * 0.67), g["chest"] + Vector3(0.15 * sx * wide, 0.0, -bz * 1.0), 0.016, hcol, "chest")
	if lk.get("suspenders") != null:                                # 멜빵(검지 · 임종태) — 앞 두 줄 곧게
		for sx in [-1.0, 1.0]:
			_line(g["chest"] + Vector3(0.1 * sx * wide, 0.25, -bz * 0.62), g["chest"] + Vector3(0.085 * sx * wide, -0.2, -bz * 1.0), 0.013,
				lk["suspenders"], "chest")
	if lk.get("chain") != null:                                     # 금 사슬 목걸이(김혁주)
		_line(g["chest"] + Vector3(-0.08, 0.22, -bz * 0.67), g["chest"] + Vector3(0, 0.15, -bz * 1.0), 0.011, lk["chain"], "chest")
		_line(g["chest"] + Vector3(0.08, 0.22, -bz * 0.67), g["chest"] + Vector3(0, 0.15, -bz * 1.0), 0.011, lk["chain"], "chest")
	# 목 · 머리(SD — 크게). 터틀넥은 목까지 옷
	var neck_col: Color = shirt if collar == "turtle" and not shirt_only and not robe else skin
	_tube(g["neck"] + Vector3(0, -0.04, 0), g["head"], 0.06 * wide, 0.06 * wide, neck_col, "neck", "chest", "head")
	if lk.get("neck_tattoo") != null:
		_blob(g["neck"] + Vector3(0.055 * wide, 0.04, -0.01), Vector3(0.012, 0.045, 0.025), lk["neck_tattoo"], "neck")
	var hk: float = 1.55 * float(lk.get("head", 1.0))
	var hc: Vector3 = g["head"] + Vector3(0, 0.06 * hk, 0)
	if fem:
		_head_fem(hc, FEM_HEAD * hk, skin)                          # 여성은 갸름하게 + 턱으로 좁아지는 V 라인
	elif lk.get("mask") != null:
		_blob(hc, MALE_HEAD * hk, skin, "head")
	else:
		head_warp = MALE_WARP_JAW if lk.get("jaw", false) else MALE_WARP
		_head_male(hc, MALE_HEAD * hk, skin)                        # 남성은 타원체 아래를 조금 좁혀 턱선(각진 턱은 넓게 남긴다)
	if lk.get("mask") != null:
		_mask(lk, hc, hk)
	else:
		_face(lk, hc, hk)
		_hair(lk, hc, hk, hair)
		_props(lk, hc, hk)
	head_warp = Vector3.ZERO
	# 팔 · 다리
	var tat_side := str(lk.get("tattoo_side", "r"))
	for side in ["r", "l"]:
		var sh: Vector3 = g["sh_" + side]
		var el: Vector3 = g["el_" + side]
		var ha: Vector3 = g["hand_" + side]
		var sb: String = "sh_" + side
		var eb: String = "el_" + side
		var hb: String = "hand_" + side
		var sx := 1.0 if side == "r" else -1.0
		var up := Vector3.UP
		var rolled: bool = (shirt_only and not lk.get("long_sleeve", false)) or (vest and lk.get("rolled", false))
		var fore: Color = skin if rolled else arm
		# 정장 · 코트 소매 끝에 셔츠 소맷부리(흰 띠 — 겉옷과 셔츠가 갈라 보이게)
		var cuff = shirt if not (shirt_only or vest or sleeveless or jacket or robe) and not shirt.is_equal_approx(arm) else null
		_blob(sh + Vector3(-0.008 * sx, -0.01, 0), Vector3(0.068, 0.062, 0.067) * limb, arm if vest or sleeveless else top, sb)   # 조끼 · 민소매는 어깨도 소매 · 맨살
		# 팔: 어깨 ~ 손목 한 줄 관(팔꿈치에서 끊기지 않게 — 위팔 · 아래팔 가중치를 팔꿈치 둘레에서 나눈다) + 팔꿈치 속 채움 공
		var ap: Array = [
			[sh + up * 0.03, 0.056 * limb, [sb, "chest"], [0.5, 0.5], arm],
			[sh, 0.064 * limb, [sb, "chest"], [0.75, 0.25], arm],
			[sh.lerp(el, 0.3), 0.066 * limb, [sb], [1.0], arm],
			[sh.lerp(el, 0.72), 0.06 * limb, [sb], [1.0], arm],
			[el + up * 0.04, 0.056 * limb, [sb, eb], [0.8, 0.2], arm],
			[el, 0.054 * limb, [sb, eb], [0.5, 0.5], arm],
		]
		if rolled:
			ap.append([el, 0.054 * limb, [sb, eb], [0.5, 0.5], fore])
		ap.append_array([
			[el - up * 0.04, 0.055 * limb, [eb, sb], [0.8, 0.2], fore],
			[el.lerp(ha, 0.35), 0.056 * limb, [eb], [1.0], fore],
			[el.lerp(ha, 0.75), 0.049 * limb, [eb], [1.0], fore],
		])
		if cuff != null:
			ap.append_array([[ha + up * 0.04, 0.05 * limb, [eb], [1.0], fore], [ha + up * 0.04, 0.043 * limb, [eb], [1.0], cuff],
				[ha + up * 0.005, 0.043 * limb, [eb, hb], [0.6, 0.4], cuff], [ha - up * 0.015, 0.041 * limb, [eb, hb], [0.5, 0.5], cuff]])
		else:
			ap.append_array([[ha + up * 0.01, 0.044 * limb, [eb, hb], [0.6, 0.4], fore], [ha - up * 0.015, 0.042 * limb, [eb, hb], [0.5, 0.5], fore]])
		_limb(ap, 0.02, 0.01)
		_sq_blob(el, Vector3.ONE * 0.051 * limb, 2.0, shirt if rolled else arm, eb, 10, 6)
		if rolled:
			# 소매 걷음: 팔꿈치 아래 걷어 올린 소매 뭉치 · 팔뚝 문신(비스듬히 감긴 띠)
			_blob(el + Vector3(0, -0.04, 0), Vector3(0.068, 0.04, 0.068) * limb, shirt, "el_" + side)
			if lk.get("tattoo") != null and (tat_side == side or tat_side == "both"):
				var tc: Color = lk["tattoo"].lerp(skin, 0.25)
				for k in 3:
					var p: Vector3 = el.lerp(ha, 0.35 + 0.18 * k)
					_tube(p + Vector3(0, 0.012, 0), p - Vector3(0, 0.012, 0), 0.053 * limb - 0.003 * k, 0.053 * limb - 0.003 * k, tc, "el_" + side)
		# 주먹: 각이 조금 진 둥근 상자 + 엄지(손바닥이 몸 쪽 -x·sx 을 본다)
		var hand_col: Color = lk.get("gloves", skin)                # 장갑(명부)
		_sq_blob(ha + Vector3(0, -0.058, -0.004) * limb, Vector3(0.042, 0.056, 0.054) * limb, 3.0, hand_col, hb)
		_limb([[ha + Vector3(-sx * 0.03, -0.035, -0.036) * limb, 0.016 * limb, [hb], [1.0], hand_col],
			[ha + Vector3(-sx * 0.022, -0.075, -0.05) * limb, 0.014 * limb, [hb], [1.0], hand_col]], 0.012, 0.012, 8)
		var wrist = lk.get("bracelet_" + side, lk.get("bracelet"))  # 손목 금 팔찌 · 검은 밴드
		if wrist != null:
			_tube(ha + Vector3(0, 0.035, 0), ha + Vector3(0, 0.005, 0), 0.052 * limb, 0.05 * limb, wrist, "el_" + side)
		if lk.get("rings") != null:                                 # 손가락 금반지(군터)
			_blob(ha + Vector3(0, -0.085, -0.045) * limb, Vector3(0.05, 0.014, 0.025) * limb, lk["rings"], "hand_" + side)
		var th: Vector3 = g["th_" + side]
		var kn: Vector3 = g["kn_" + side]
		var ft: Vector3 = g["ft_" + side]
		var tb: String = "th_" + side
		var kb: String = "kn_" + side
		var fb: String = "ft_" + side
		var bare := skirt or shorts                                 # 정강이 맨살
		var shin: Color = skin if bare else pants
		var lr := 0.095 * limb * wide
		# 다리: 엉덩이 속 ~ 발목 한 줄 관(허벅지 · 무릎 · 종아리) + 무릎 속 채움 공. 맨살 정강이는 무릎 위 반바지 단에서 색이 바뀐다
		var lp: Array = [
			[th + up * 0.06, lr * 0.86, ["hips", tb], [0.5, 0.5], pants],
			[th, lr * 0.93, [tb, "hips"], [0.65, 0.35], pants],
			[th.lerp(kn, 0.25), lr * 0.97, [tb], [1.0], pants],
			[th.lerp(kn, 0.62), 0.08 * limb * lerpf(1.0, wide, 0.5), [tb], [1.0], pants],
		]
		if bare:
			lp.append_array([[kn + up * 0.07, 0.08 * limb, [tb, kb], [0.85, 0.15], pants], [kn + up * 0.07, 0.071 * limb, [tb, kb], [0.85, 0.15], shin]])
		lp.append_array([
			[kn + up * 0.04, 0.072 * limb, [tb, kb], [0.8, 0.2], shin],
			[kn, 0.07 * limb, [tb, kb], [0.5, 0.5], shin],
			[kn - up * 0.05, 0.07 * limb, [kb, tb], [0.8, 0.2], shin],
			[kn.lerp(ft, 0.3), (0.073 if bare else 0.069) * limb, [kb], [1.0], shin],
			[kn.lerp(ft, 0.75), (0.058 if bare else 0.062) * limb, [kb], [1.0], shin],
			[ft + up * 0.04, (0.052 if bare else 0.06) * limb, [kb, fb], [0.7, 0.3], shin],
			[ft, (0.05 if bare else 0.059) * limb, [kb, fb], [0.5, 0.5], shin],
		])
		_limb(lp, 0.02, 0.01)
		_sq_blob(kn, Vector3.ONE * 0.066 * limb, 2.0, shin, kb, 10, 6)
		if long_coat:                                               # 옷자락 앞 자락 — 허벅지를 덮는다
			_tube(th + Vector3(0, 0.02, 0), kn + Vector3(0, 0.04, 0), 0.105 * limb * wide, 0.09 * limb * wide, top, "th_" + side, "hips")
		if lk.get("stripe") != null:                                # 트랙 바지 옆줄(서진태)
			var o0 := Vector3(sx * 0.093 * limb * wide, 0, 0)
			var o1 := Vector3(sx * 0.07 * limb, 0, 0)
			_tube(th + o0, kn + o1, 0.013, 0.013, lk["stripe"], "th_" + side, "", "kn_" + side)
			_tube(kn + o1, ft + Vector3(sx * 0.054 * limb, 0, 0), 0.013, 0.013, lk["stripe"], "kn_" + side, "th_" + side, "ft_" + side)
		_shoe(ft, sqrt(limb), shoe, lk.get("sole"), fb)


func _face(lk: Dictionary, hc: Vector3, hk: float) -> void:
	if lk.get("female", false):
		_face_fem(lk, hc, hk)
	else:
		_face_male(lk, hc, hk)
	_face_marks(lk, hc, hk)


## 여성 얼굴(2026-11-07 폰 "오지인이 대표 미인 캐릭터인데 너무 못생김" — 원작 카드 초상 하성_오지인 · 차수민 대조).
## 전에는 눈 · 코 · 입이 얼굴에서 솟은 작은 타원체라 게임의 검은 외곽선(puppet_glb next_pass grow)이 하나하나를 둘러
## 동그란 왕눈 · 고리 두른 코가 됐다. 이제 겉면을 따라 휜 한 겹 판(_patch)이라 외곽선이 안 걸린다 — 그린 듯한 얼굴: 가는 아몬드 눈(흰자 · 짙은 눈동자 · 눈빛 · 굵은 윗눈꺼풀 선과 올라간 눈꼬리) · 가는 아치 눈썹 · 작은 코 그늘 ·
## 도톰한 입술 · 옅은 볼 · 금 고리 귀걸이(piercing). 눈 높이 eye_h ≤ 0.008 은 날카로운 눈(오지인)
func _face_fem(lk: Dictionary, hc: Vector3, hk: float) -> void:
	var sk: Color = lk["skin"]
	var R := FEM_HEAD * hk
	var sharp: bool = float(lk.get("eye_h", 0.011)) <= 0.008
	var eh := 0.0062 if sharp else 0.0075                           # 눈 반높이
	var eye: Color = lk.get("eye_col", Color(0.1, 0.06, 0.05))
	var lash := Color(0.04, 0.03, 0.035)
	var brow: Color = Looks.hair_lift(lk["hair"]).darkened(0.2)
	for sx in [-1.0, 1.0]:
		var e := Vector3(0.042 * sx, 0.004, -0.11)
		_patch(hc, R, e, 0.0175, eh, 0.0012, 4.0 * sx, Color(0.97, 0.96, 0.94), hk)                       # 흰자
		_patch(hc, R, e + Vector3(-0.002 * sx, -0.0008, 0), 0.0078, eh * 1.02, 0.0022, 0.0, eye, hk)        # 눈동자
		_patch(hc, R, e + Vector3(0.0015 * sx, 0.0025, 0), 0.0024, 0.0024, 0.0032, 0.0, Color.WHITE, hk)   # 눈빛
		_patch(hc, R, e + Vector3(0.0015 * sx, eh * 0.95, 0), 0.0205, 0.0032, 0.003, 8.0 * sx, lash, hk)   # 윗눈꺼풀 선
		_patch(hc, R, e + Vector3(0.0215 * sx, eh * 1.5, 0), 0.0075, 0.0022, 0.003, 30.0 * sx, lash, hk)   # 올라간 눈꼬리
		_patch(hc, R, e + Vector3(0.003 * sx, -eh * 1.05, 0), 0.011, 0.0012, 0.0008, -4.0 * sx, sk.darkened(0.28), hk)   # 아랫눈꺼풀(옅게)
		var b := Vector3(0.044 * sx, 0.035 if sharp else 0.038, -0.11)                                    # 눈썹: 안쪽은 오르고 바깥 끝이 내려오는 아치
		_patch(hc, R, b + Vector3(-0.006 * sx, 0, 0), 0.014, 0.0026, 0.002, 8.0 * sx, brow, hk)
		_patch(hc, R, b + Vector3(0.0145 * sx, -0.0016, 0), 0.0095, 0.002, 0.002, -18.0 * sx, brow, hk)
		_patch(hc, R, Vector3(0.058 * sx, -0.028, -0.1), 0.016, 0.009, 0.0008, 0.0, sk.lerp(Color(0.95, 0.5, 0.52), 0.2), hk)   # 옅은 볼
		if lk.get("piercing", false):                               # 금 고리 귀걸이(looks.json piercing ring #c8a040 — 오지인 · 차수민)
			var ear := _on_ell(hc, R, Vector3(sx, -0.32, 0.05))
			_line(ear + Vector3(0, -0.004, 0) * hk, ear + Vector3(0.004 * sx, -0.03, -0.004) * hk, 0.0035 * hk, Color(0.86, 0.68, 0.3), "head")
	_patch(hc, R, Vector3(0, -0.02, -0.12), 0.0055, 0.0075, 0.0035, 0.0, sk.darkened(0.04), hk)           # 작은 코(콧등 끝)
	_patch(hc, R, Vector3(0, -0.031, -0.12), 0.0065, 0.0014, 0.0012, 0.0, sk.darkened(0.3), hk)          # 콧망울 그늘
	var lips: Color = lk.get("lips", sk.lerp(Color(0.8, 0.36, 0.4), 0.45))
	_patch(hc, R, Vector3(0, -0.0515, -0.12), 0.0145, 0.0038, 0.0026, 0.0, lips.darkened(0.12), hk)       # 윗입술
	_patch(hc, R, Vector3(0, -0.0595, -0.12), 0.0125, 0.0048, 0.0034, 0.0, lips, hk)                      # 아랫입술(도톰하게)
	_patch(hc, R, Vector3(0, -0.0552, -0.12), 0.0125, 0.0009, 0.0036, 0.0, lips.darkened(0.55), hk)      # 입술 사이 선


## 얼굴 겉면에 붙인 조각(머리 단위): 머리 타원체 R 위 dir 쪽에 겉면을 따라 휜 얇은 한 겹 판 — 가로 반폭 rx · 세로 반폭 ry 의 타원,
## 겉면에서 lift 만큼 떠 있다(겹치는 조각은 lift 로 위아래). 한 겹 앞면뿐이라 외곽선 판(뒷면만 그린다)에 안 걸린다 — 작은 덩어리를
## 붙이면 외곽선이 하나하나를 굵게 둘러 왕눈 · 고리 코가 됐다(2026-11-07). tilt: 얼굴 앞에서 본 기울기(도, + 는 +x 끝이 올라감)
## sq: 테두리 모양(2 = 타원, 클수록 네모 — 색안경 알 · 안대). 남성 머리는 다듬은 겉면(head_warp)을 따른다
func _patch(hc: Vector3, R: Vector3, dir: Vector3, rx: float, ry: float, lift: float, tilt: float, col: Color, hk: float, sq := 2.0) -> void:
	var p := _on_ell(hc, R, dir)
	var n := _ell_normal(hc, R, p)
	var tx := n.cross(Vector3.UP).normalized()
	var ty := tx.cross(n)
	var a := deg_to_rad(tilt)
	var bx := tx * cos(a) + ty * sin(a)
	var by := -tx * sin(a) + ty * cos(a)
	var seg := 14 if sq == 2.0 else 20
	var rings := 3
	var grid: Array = []
	for i in rings + 1:
		var rho := float(i) / rings
		var row: Array = []
		for j in seg:
			var u := TAU * j / seg
			var cu := cos(u)
			var su := sin(u)
			if sq != 2.0:                                           # 초타원(네모에 가까운 테두리)
				cu = signf(cu) * pow(absf(cu), 2.0 / sq)
				su = signf(su) * pow(absf(su), 2.0 / sq)
			var q := _on_ell(hc, R, p - hc + (bx * cu * rx + by * su * ry) * rho * hk)
			row.append(_hw(hc, R, q) + _ell_normal(hc, R, q) * (lift + FACE_LIFT) * hk)
		grid.append(row)
	for i in rings:
		for j in seg:
			var j2 := (j + 1) % seg
			_tri_out(grid[i][j], grid[i + 1][j], grid[i + 1][j2], n, col)
			_tri_out(grid[i][j], grid[i + 1][j2], grid[i][j2], n, col)


## 여성 머리: 타원체의 아래쪽(뺨 → 턱)을 좁히고 조금 늘인 한 덩어리(턱을 덧붙이면 외곽선이 턱에 금을 그었다 — 2026-11-07).
## 얼굴 조각(_patch)은 타원체 R 위에 놓는다 — 좁힌 아래쪽에서는 조금 떠도 lift 보다 작다(뺨 · 입술 자리)
func _head_fem(c: Vector3, r: Vector3, col: Color) -> void:
	var seg := 16
	var rings := 10
	var grid: Array = []
	for i in rings + 1:
		var v := PI * i / rings
		var row: Array = []
		for j in seg:
			var u := TAU * j / seg
			var n := Vector3(sin(v) * cos(u), cos(v), sin(v) * sin(u))
			var low := maxf(0.0, -n.y)
			var p := Vector3(n.x * r.x * (1.0 - 0.3 * pow(low, 1.6)), n.y * r.y * (1.0 + 0.06 * low), n.z * r.z * (1.0 - 0.08 * pow(low, 2.0)))
			row.append([c + p, ["head"], [1.0]])
		grid.append(row)
	for i in rings:
		for j in seg:
			var j2 := (j + 1) % seg
			_quad(grid[i][j], grid[i][j2], grid[i + 1][j2], grid[i + 1][j], [col], [])


## 타원체 겉면 점 q 의 바깥 법선
func _ell_normal(c: Vector3, R: Vector3, q: Vector3) -> Vector3:
	var d := q - c
	return Vector3(d.x / (R.x * R.x), d.y / (R.y * R.y), d.z / (R.z * R.z)).normalized()


## 삼각형 하나(머리 뼈) — 앞면이 n 쪽(바깥)을 보게 감기 방향을 맞춘다
func _tri_out(a: Vector3, b: Vector3, c: Vector3, n: Vector3, col: Color) -> void:
	if (b - a).cross(c - a).dot(n) > 0.0:
		var t := b
		b = c
		c = t
	for v in [a, b, c]:
		_vert(v, col, ["head"], [1.0])


## 남성 얼굴(2026-11-08 사용자 "남성 얼굴도 진행해" — 여성 _face_fem 과 같은 방법). 전에는 눈 · 눈썹 · 코 · 입 · 수염이 얼굴에서 솟은
## 작은 타원체라 외곽선이 하나하나를 둘러 고리 눈 · 고리 코 · 턱 밑 선반(수염 그늘)이 됐다. 이제 다듬은 머리 겉면에 붙인 한 겹 판(_patch ·
## _stroke)으로 그린다 — 만화 남자 얼굴: 가늘고 날카로운 눈(흰자 · 짙은 눈동자 · 굵은 윗눈꺼풀 선이 바깥으로 길게) · 낮고 굵은 일자 눈썹
## (brow_tilt 만큼 바깥 끝이 올라간다 — 김신 날카로운 눈매, brow_k 굵기 — 윤덕수) · 콧등 한쪽 그늘 + 코끝 선 · 일자 입 + 아랫입술 그늘.
## 눈 높이 eye_h: ≤ 0.006 실눈 · ≤ 0.008 날카로운 눈 · 나머지 보통. 수염(턱 · 콧수염 · 염소 · 구레나룻 · 그늘)도 판 — 색 beard_col
func _face_male(lk: Dictionary, hc: Vector3, hk: float) -> void:
	var sk: Color = lk["skin"]
	var R := MALE_HEAD * hk
	var eh_k := float(lk.get("eye_h", 0.011))
	var eh: float = 0.0036 if eh_k <= 0.006 else (0.0058 if eh_k <= 0.008 else 0.0072)   # 눈 반높이(실눈 · 날카로운 눈 · 보통)
	var eye: Color = lk.get("eye_col", Color(0.1, 0.07, 0.06))
	var lash := Color(0.05, 0.035, 0.035)
	var brow: Color = Looks.hair_lift(lk["hair"]).darkened(0.3)
	var brow_k: float = lk.get("brow_k", 1.0)
	var brow_tilt: float = lk.get("brow_tilt", 6.0)
	var blind := str(lk.get("blind_eye", ""))                       # 먼 눈(인물 자기 쪽 — 흰자에 흐린 눈동자)
	var line := sk.darkened(0.42)
	# 수염 그늘 · 수염은 맨 밑(입 · 코 선이 그 위에 놓인다)
	var beard: Color = lk.get("beard_col", lk["hair"])             # 수염 색(looks.json facial_hair_color — 없으면 머리색)
	var bc := Looks.hair_lift(beard).darkened(0.1)
	if lk.get("stubble", false):                                    # 턱 수염 그늘 — looks.json facial_hair stubble 일 때만(턱선 · 윗입술)
		var stc := sk.lerp(skin_stubble(lk), 0.75)                   # 옅게(진하면 턱 밑에 검은 띠처럼 보였다)
		_patch(hc, R, Vector3(0, -0.104, -0.08), 0.066, 0.034, 0.0003, 0.0, stc, hk)
		_patch(hc, R, Vector3(0, -0.044, -0.12), 0.019, 0.0055, 0.0003, 0.0, stc, hk)
	if lk.get("beard", false):                                      # 짧은 턱수염(턱 · 턱선) + 윗입술 수염
		_patch(hc, R, Vector3(0, -0.1, -0.085), 0.07, 0.042, 0.0012, 0.0, bc, hk)
		_patch(hc, R, Vector3(0, -0.044, -0.12), 0.021, 0.0055, 0.0012, 0.0, bc, hk)
	for sx in [-1.0, 1.0]:
		var white := Color(0.95, 0.94, 0.92)
		var e := Vector3(0.044 * sx, 0.006, -0.11)
		var dead: bool = lk.get("blank_eyes", false) or blind == ("l" if sx < 0.0 else "r")
		_patch(hc, R, e, 0.019, eh, 0.0012, 3.0 * sx, white, hk)                                           # 흰자
		if not lk.get("blank_eyes", false):                         # 동공 없는 흰자(샤모)는 눈동자를 안 그린다
			var ic: Color = Color(0.72, 0.73, 0.74) if dead else eye
			_patch(hc, R, e + Vector3(-0.0015 * sx, 0.0005, 0), 0.0075, eh * 1.02, 0.0022, 0.0, ic, hk)       # 눈동자
			if eh > 0.004 and not dead:
				_patch(hc, R, e + Vector3(0.001 * sx, eh * 0.35, 0), 0.0016, 0.0016, 0.0032, 0.0, Color(0.95, 0.95, 0.95), hk)   # 눈빛(작게)
		_patch(hc, R, e + Vector3(0.0015 * sx, eh * 0.9, 0), 0.0215, 0.0038, 0.003, 4.0 * sx, lash, hk)    # 굵은 윗눈꺼풀 선
		_patch(hc, R, e + Vector3(0.023 * sx, eh * 0.45, 0), 0.007, 0.0025, 0.003, -10.0 * sx, lash, hk)    # 바깥으로 길게 뺀 눈꼬리
		_patch(hc, R, e + Vector3(0.003 * sx, -eh * 1.05, 0), 0.012, 0.0011, 0.0008, -3.0 * sx, line.lightened(0.15), hk)   # 아랫눈꺼풀(옅게)
		# 눈썹: 눈 가까이 낮고 굵은 일자 — 안쪽 끝이 굵고 바깥 끝이 가늘게, brow_tilt 만큼 바깥이 올라간다
		var bt: float = brow_tilt * 0.7 * sx
		var b := Vector3(0.046 * sx, 0.031, -0.11)
		_patch(hc, R, b, 0.022, 0.0042 * brow_k, 0.002, bt, brow, hk)
		_patch(hc, R, b + Vector3(-0.013 * sx, -0.0012 * signf(brow_tilt), 0), 0.0095, 0.0055 * brow_k, 0.0024, bt, brow, hk)
	# 코: 콧등 한쪽 그늘 선 · 코끝 아래 선 · 콧구멍 그늘
	_stroke(hc, R, Vector3(-0.009, 0.004, -0.12), Vector3(-0.012, -0.024, -0.12), 0.0016, 0.0016, sk.darkened(0.2), hk)
	_patch(hc, R, Vector3(0, -0.032, -0.12), 0.011, 0.0018, 0.0026, 0.0, line, hk)
	for sx in [-1.0, 1.0]:
		_patch(hc, R, Vector3(0.0075 * sx, -0.0295, -0.12), 0.0035, 0.0016, 0.0028, -25.0 * sx, sk.darkened(0.3), hk)
	# 입: 일자 선(입술 색이 있으면 그 색) · 아랫입술 그늘
	var lips = lk.get("lips")
	var mouth: Color = sk.darkened(0.5) if lips == null else (lips as Color).darkened(0.25)
	_patch(hc, R, Vector3(0, -0.059, -0.12), 0.0185, 0.0019 if lips == null else 0.0032, 0.0034, 0.0, mouth, hk)
	_patch(hc, R, Vector3(0, -0.067, -0.12), 0.007, 0.0013, 0.0026, 0.0, sk.darkened(0.1), hk)
	if lk.get("mustache", false):                                   # 콧수염: 윗입술 위 막대 + 입꼬리로 처진 끝(군터)
		_patch(hc, R, Vector3(0, -0.045, -0.12), 0.021, 0.0055, 0.004, 0.0, bc, hk)
		for sx in [-1.0, 1.0]:
			_stroke(hc, R, Vector3(0.016 * sx, -0.046, -0.12), Vector3(0.026 * sx, -0.068, -0.115), 0.0042, 0.004, bc, hk)
	if lk.get("goatee", false):                                     # 염소수염(김성준): 아랫입술 아래 ~ 턱 끝
		_patch(hc, R, Vector3(0, -0.104, -0.1), 0.019, 0.016, 0.004, 0.0, bc, hk)        # 턱 끝 수염(가로로 넓게 — 세로 타원은 벌린 입처럼 보였다)
		_patch(hc, R, Vector3(0, -0.077, -0.12), 0.0055, 0.006, 0.004, 0.0, bc, hk)       # 아랫입술 밑 한 점
	if lk.get("sideburns", false):                                  # 구레나룻 — 귀 앞에서 턱 모서리로(염소수염이 있으면 턱끈처럼 턱 끝까지 — 크리사)
		for sx in [-1.0, 1.0]:
			var jaw := Vector3(0.078 * sx, -0.085, -0.08)
			_stroke(hc, R, Vector3(0.105 * sx, 0.0, -0.045), jaw, 0.009, 0.003, bc, hk)
			if lk.get("goatee", false):
				_stroke(hc, R, jaw, Vector3(0.018 * sx, -0.112, -0.095), 0.006, 0.0035, bc, hk)


## 남성 머리: 타원체(MALE_HEAD)를 head_warp 로 아래쪽만 좁힌 한 덩어리(_head_fem 과 같은 짜임 — 턱을 덧붙이면 외곽선이 금을 긋는다)
func _head_male(c: Vector3, r: Vector3, col: Color) -> void:
	var seg := 16
	var rings := 10
	var grid: Array = []
	for i in rings + 1:
		var v := PI * i / rings
		var row: Array = []
		for j in seg:
			var u := TAU * j / seg
			row.append([_hw(c, r, c + Vector3(sin(v) * cos(u) * r.x, cos(v) * r.y, sin(v) * sin(u) * r.z)), ["head"], [1.0]])
		grid.append(row)
	for i in rings:
		for j in seg:
			var j2 := (j + 1) % seg
			_quad(grid[i][j], grid[i][j2], grid[i + 1][j2], grid[i + 1][j], [col], [])


## 머리 겉면 점 q 를 지금 머리 다듬기(head_warp)로 옮긴다 — 0 이면 그대로(여성 · 복면)
func _hw(c: Vector3, r: Vector3, q: Vector3) -> Vector3:
	if head_warp == Vector3.ZERO:
		return q
	var d := q - c
	var low := maxf(0.0, -d.y / r.y)
	return c + Vector3(d.x * (1.0 - head_warp.x * pow(low, head_warp.y)), d.y * (1.0 + MALE_CHIN * low), d.z * (1.0 - head_warp.z * low * low))


## 얼굴 겉면의 가는 선(머리 단위 방향 a → b): 두 점 사이에 놓은 길쭉한 판 — 끝이 가늘어지는 흉터 · 콧등 그늘 · 수염 줄. w 반폭
func _stroke(hc: Vector3, R: Vector3, a: Vector3, b: Vector3, w: float, lift: float, col: Color, hk: float) -> void:
	var pa := _on_ell(hc, R, a)
	var pb := _on_ell(hc, R, b)
	var m := (pa + pb) * 0.5
	var n := _ell_normal(hc, R, _on_ell(hc, R, m - hc))
	var tx := n.cross(Vector3.UP).normalized()
	var ty := tx.cross(n)
	var d := pb - pa
	_patch(hc, R, m - hc, d.length() * 0.5 / hk + w * 0.5, w, lift, rad_to_deg(atan2(d.dot(ty), d.dot(tx))), col, hk)


## 얼굴 표시(남녀 공통): 피어싱 · 안대 · 복면 · 흉터
func _face_marks(lk: Dictionary, hc: Vector3, hk: float) -> void:
	if lk.get("face_ring") != null:                                 # 입술 · 눈썹 피어싱(라텔 · 판테라)
		_blob(hc + Vector3(0.016, -0.068, -0.118) * hk, Vector3(0.007, 0.007, 0.006) * hk, lk["face_ring"], "head")
	var R := (FEM_HEAD if lk.get("female", false) else MALE_HEAD) * hk
	if lk.get("eyepatch") != null:                                  # 안대(남일호) — 눈 위 검은 네모 판 + 끈(판이라 외곽선 고리가 없다)
		var ex := -0.045 if str(lk["eyepatch"]) == "l" else 0.045
		_patch(hc, R, Vector3(ex, 0.008, -0.11), 0.026, 0.021, 0.006, 0.0, Color(0.04, 0.04, 0.05), hk, 3.0)
		_stroke(hc, R, Vector3(ex * 0.25, 0.05, -0.11), Vector3(ex * 2.4, 0.03, -0.03), 0.003, 0.0055, Color(0.04, 0.04, 0.05), hk)
	if lk.get("mouth_mask") != null:                                # 코 아래를 가리는 복면 · 높은 깃(주로 · 샤이어)
		_blob(hc + Vector3(0, -0.07, -0.05) * hk, Vector3(0.112, 0.06, 0.08) * hk, lk["mouth_mask"], "head")
	var sc = lk.get("scar", false)
	if sc is String or sc:
		# 흉터는 가는 짙은 선(붉게 섞으면 도트 · 먼 화면에서 볼터치처럼 번졌다 — 전인물 외형 검토 2026-11-06)
		for kind in (str(sc) if sc is String else "cheek_l").split("+"):
			_scar(kind, hc, hk, Looks.scar_col(lk), R)


## 수염 그늘 색: 살빛에 머리색을 조금 섞어 어둡게(살빛만 어둡게 하면 흰 입마개처럼 보였다 — 2026-11-06 검토)
func skin_stubble(lk: Dictionary) -> Color:
	return (lk["skin"] as Color).darkened(0.16).lerp(Looks.hair_lift(lk.get("beard_col", lk["hair"])).darkened(0.2), 0.12)   # 늘 살빛보다 어둡게(흰 머리 · 짙은 살 — 신겐)


## 흉터 자리(인형과 같은 이름): nose — 콧등에서 왼뺨 광대로 사선 + 입술 아래 ~ 턱 세로 · brow — 이마에서 눈썹으로 · double — 왼뺨 두 줄.
## 점은 머리 중심에서 본 방향(머리 단위). 얼굴의 흉터는 겉면에 붙인 가는 판(_stroke — 전에는 관이라 외곽선이 굵게 둘렀다 · 2026-11-08),
## 정수리(head)는 머리털 위라 관 그대로
func _scar(kind: String, hc: Vector3, hk: float, col: Color, R: Vector3) -> void:
	var w := 0.0024
	var lf := 0.0045
	if kind == "head":                                               # 정수리에서 옆머리로(메드베디 · 어광득)
		_line(_on_head(hc, hk, Vector3(0.01, 0.13, -0.03)), _on_head(hc, hk, Vector3(0.07, 0.08, 0.06)), 0.0038 * hk * 1.3, col, "head")
	elif kind == "cheek_l" or kind == "cheek_r":                       # 뺨 사선 한 줄(인물 자기 쪽 — 왼뺨은 -x)
		var sx := -1.0 if kind == "cheek_l" else 1.0
		_stroke(hc, R, Vector3(0.055 * sx, 0.0, -0.11), Vector3(0.085 * sx, -0.055, -0.095), w, lf, col, hk)
	elif kind == "chin":                                             # 입술 아래 ~ 턱 세로
		_stroke(hc, R, Vector3(0.012, -0.075, -0.12), Vector3(0.014, -0.115, -0.1), w, lf, col, hk)
	elif kind == "nose":
		_stroke(hc, R, Vector3(0.0, 0.03, -0.12), Vector3(-0.08, -0.03, -0.1), w, lf, col, hk)
		_stroke(hc, R, Vector3(0.012, -0.075, -0.12), Vector3(0.014, -0.11, -0.1), w, lf, col, hk)
	elif kind == "brow":
		_stroke(hc, R, Vector3(0.036, 0.1, -0.1), Vector3(0.05, 0.03, -0.12), w, lf, col, hk)
	elif kind == "eye_l" or kind == "eye_r":                         # 눈썹 위에서 눈을 지나 뺨으로 세로 한 줄(인물 자기 쪽)
		var ex := -0.045 if kind == "eye_l" else 0.045
		_stroke(hc, R, Vector3(ex, 0.07, -0.11), Vector3(ex * 1.05, -0.04, -0.11), w, lf, col, hk)
	elif kind == "x":                                                # 콧등에서 엇갈리는 긴 두 줄(최민욱): 오른 이마 → 왼뺨 · 왼 눈썹 안 → 오른뺨
		var m := Vector3(0.0, 0.015, -0.12)
		_stroke(hc, R, Vector3(0.06, 0.095, -0.1), m, w, lf, col, hk)
		_stroke(hc, R, m, Vector3(-0.075, -0.045, -0.1), w, lf, col, hk)
		_stroke(hc, R, Vector3(-0.022, 0.06, -0.115), m, w, lf, col, hk)
		_stroke(hc, R, m, Vector3(0.075, -0.05, -0.1), w, lf, col, hk)
	elif kind == "double":
		for k in 2:
			var o := Vector3(-0.014 * k, -0.016 * k, 0)
			_stroke(hc, R, Vector3(-0.045, 0.0, -0.12) + o, Vector3(-0.09, -0.04, -0.1) + o, w, lf, col, hk)


## 머리(타원체 0.12 · 0.13 · 0.12 × hk) 중심에서 dir 쪽 겉면 바로 바깥 점
func _on_head(hc: Vector3, hk: float, dir: Vector3) -> Vector3:
	var q := Vector3(dir.x / 0.12, dir.y / 0.13, dir.z / 0.12)
	return hc + dir / q.length() * hk * 1.015


## 눈만 뚫린 복면(DS 습격조): 머리 전체를 덮고 눈 자리만 살색 띠
func _mask(lk: Dictionary, hc: Vector3, hk: float) -> void:
	var mc: Vector3 = hc + Vector3(0, 0.003, 0) * hk
	var mr := Vector3(0.128, 0.138, 0.128) * hk
	_blob(mc, mr, lk["mask"], "head")
	# 눈 구멍 띠 · 눈은 복면 겉면에 붙인 판(덩어리면 외곽선이 눈마다 고리를 둘렀다 — 2026-11-08)
	_patch(mc, mr, Vector3(0, 0.009, -0.12), 0.07, 0.019, 0.001, 0.0, lk["skin"], hk, 3.0)
	for sx in [-1.0, 1.0]:
		_patch(mc, mr, Vector3(0.04 * sx, 0.009, -0.12), 0.016, 0.0055, 0.0025, 3.0 * sx, Color(0.95, 0.94, 0.92), hk)
		_patch(mc, mr, Vector3(0.039 * sx, 0.009, -0.12), 0.0065, 0.0056, 0.0035, 0.0, Color(0.08, 0.06, 0.05), hk)
		_patch(mc, mr, Vector3(0.0405 * sx, 0.0145, -0.12), 0.0185, 0.0026, 0.0045, 4.0 * sx, Color(0.05, 0.035, 0.035), hk)


## 얼굴 소품: 색안경(sun — 검은 사각테, 렌즈 색 lens) · 머리띠 붕대 · 시가
func _props(lk: Dictionary, hc: Vector3, hk: float) -> void:
	var R := (FEM_HEAD if lk.get("female", false) else MALE_HEAD) * hk
	var gl = lk.get("glasses", false)
	if gl is String:
		# 색안경 모양(looks.json glasses.kind): sun — 각진 검은 테(위 막대로 네모나게) · aviator — 금테 물방울(아래 · 바깥으로 처짐) ·
		# goggles — 두 눈을 한 띠로 덮는 스포츠 고글(전에는 셋 다 작은 둥근 알이었다 — 전인물 외형 검토 2026-11-06)
		# 테 · 알은 얼굴 앞에 띄운 판(덩어리면 외곽선이 알마다 굵은 고리를 둘러 동그란 알이 됐다 — 2026-11-08). 다리는 옆머리로
		var lens: Color = lk.get("lens", Color(0.05, 0.05, 0.06))
		var kind := str(gl)
		var frame: Color = lk.get("frame", Color(0.82, 0.64, 0.25) if kind == "aviator" else Color(0.05, 0.05, 0.06))
		if kind == "goggles":
			_patch(hc, R, Vector3(0, 0.012, -0.12), 0.098, 0.03, 0.006, 0.0, frame, hk, 4.0)
			_patch(hc, R, Vector3(0, 0.012, -0.12), 0.09, 0.022, 0.0068, 0.0, lens, hk, 4.0)
		else:
			var av := kind == "aviator"
			for sx in [-1.0, 1.0]:
				var lc := Vector3(0.045 * sx, 0.004 if av else 0.008, -0.11)
				_patch(hc, R, lc, 0.03, 0.024 if av else 0.0185, 0.006, -6.0 * sx if av else 0.0, frame, hk, 2.4 if av else 5.0)
				_patch(hc, R, lc + Vector3(0, -0.0005, 0), 0.0255, 0.0195 if av else 0.0135, 0.0068, -6.0 * sx if av else 0.0, lens, hk,
					2.4 if av else 5.0)
		_glass_arms(hc, R, hk, frame if kind != "goggles" else Color(0.05, 0.05, 0.06), 0.013)
	elif gl:                                                        # 맑은 안경(lens clear · 백도찬) — 가는 테 + 하얀 알(검게 그리지 않는다)
		var fc: Color = lk.get("frame", Color(0.75, 0.77, 0.8))
		for sx in [-1.0, 1.0]:
			var lc := Vector3(0.045 * sx, 0.009, -0.11)
			_patch(hc, R, lc, 0.0275, 0.0175, 0.0055, 0.0, fc.darkened(0.35), hk, 4.0)
			_patch(hc, R, lc, 0.0245, 0.0145, 0.0062, 0.0, Color(0.93, 0.95, 0.97), hk, 4.0)
		_glass_arms(hc, R, hk, fc.darkened(0.35), 0.012)
	if lk.get("hat") != null:                                       # 모자(looks.json headwear — HAT 표)
		var hcol: Color = lk.get("hat_col", Color(0.2, 0.2, 0.22))
		var kind := str(lk["hat"])
		var hr := _hair_shell(str(lk.get("hair_style", "short")))       # 머리 껍질 반지름(띠 · 모자가 머리에 묻히지 않게)
		if kind == "bucket":
			_blob(hc + Vector3(0, 0.1, 0.01) * hk, Vector3(0.13, 0.08, 0.13) * hk, hcol, "head")
			_blob(hc + Vector3(0, 0.055, 0.01) * hk, Vector3(0.18, 0.02, 0.18) * hk, hcol, "head")
		elif kind == "headband" or kind == "bandana":
			# 이마에 두른 띠 — 머리색과 비슷하면(검은 머리 · 검은 띠 — 라텔) 띠를 밝히고 위아래에 밝은 단을 둘러 갈라 보이게
			var hl: float = 0.3 * Looks.hair_lift(lk["hair"]).r + 0.59 * Looks.hair_lift(lk["hair"]).g + 0.11 * Looks.hair_lift(lk["hair"]).b
			var bl: float = 0.3 * hcol.r + 0.59 * hcol.g + 0.11 * hcol.b
			var band := hcol if absf(hl - bl) > 0.14 else hcol.lerp(Color(0.32, 0.32, 0.36), 0.35)
			var rr := hr + 0.01
			if kind == "bandana":                                   # 반다나: 정수리까지 덮고 뒤에서 묶은 매듭
				_blob(hc + Vector3(0, 0.075, 0.02) * hk, Vector3(rr, 0.08, rr) * hk, band, "head")
				_blob(hc + Vector3(0, 0.03, 0.135) * hk, Vector3(0.03, 0.03, 0.02) * hk, band, "head")
			_blob(hc + Vector3(0, 0.058, 0.008) * hk, Vector3(rr, 0.026, rr) * hk, band, "head")
			if absf(hl - bl) <= 0.14:
				var edge := Color(0.62, 0.62, 0.66)
				for dy in [-0.026, 0.026]:
					_blob(hc + Vector3(0, 0.058 + dy, 0.008) * hk, Vector3(rr + 0.002, 0.0035, rr + 0.002) * hk, edge, "head")
		elif kind == "cap":                                         # 모자(야구모자 · 뉴스보이 캡): 둥근 머리통 + 앞 챙
			_blob(hc + Vector3(0, 0.085, 0.01) * hk, Vector3(hr + 0.008, 0.075, hr + 0.008) * hk, hcol, "head")
			_blob(hc + Vector3(0, 0.07, -0.12) * hk, Vector3(0.085, 0.012, 0.06) * hk, hcol.darkened(0.15), "head")
		elif kind == "fedora":                                      # 중절모: 높은 몸통 + 둘레 챙 + 띠
			_blob(hc + Vector3(0, 0.13, 0.01) * hk, Vector3(0.115, 0.075, 0.115) * hk, hcol, "head")
			_blob(hc + Vector3(0, 0.08, 0.01) * hk, Vector3(0.19, 0.014, 0.19) * hk, hcol, "head")
			_blob(hc + Vector3(0, 0.095, 0.01) * hk, Vector3(0.12, 0.016, 0.12) * hk, lk.get("hat_band", hcol.darkened(0.65)), "head")   # 띠(headwear.band — 김황 검은 띠)
		elif kind == "hood":                                        # 후드: 머리 뒤 · 옆 · 위를 감싼다(얼굴은 보이게)
			_blob(hc + Vector3(0, 0.03, 0.05) * hk, Vector3(hr + 0.03, 0.16, 0.13) * hk, hcol, "head")
		elif kind == "helmet":
			_blob(hc + Vector3(0, 0.07, 0.01) * hk, Vector3(hr + 0.02, 0.1, hr + 0.02) * hk, hcol, "head")
		else:
			_blob(hc + Vector3(0, 0.09, 0.014) * hk, Vector3(0.134, 0.085, 0.136) * hk, hcol, "head")
			_blob(hc + Vector3(0, 0.065, 0.012) * hk, Vector3(0.136, 0.02, 0.138) * hk, hcol.darkened(0.12), "head")   # 단(눈썹 위)
	if lk.get("bandage") != null:                                   # 머리띠처럼 감은 흰 붕대(강만재)
		_blob(hc + Vector3(0, 0.06, 0.005) * hk, Vector3(0.127, 0.03, 0.127) * hk, lk["bandage"], "head")
	if lk.get("cigar", false):                                      # 입에 문 시가(군터)
		var a: Vector3 = hc + Vector3(0.02, -0.065, -0.115) * hk
		var b: Vector3 = hc + Vector3(0.05, -0.075, -0.19) * hk
		_tube(a, b, 0.011 * hk, 0.012 * hk, Color(0.36, 0.22, 0.12), "head")
		_blob(b, Vector3(0.013, 0.013, 0.008) * hk, Color(1.0, 0.35, 0.1), "head")


## 안경 코다리(두 알 사이) · 다리(알 바깥 끝 → 옆머리) — 얼굴 판과 같은 높이 y
func _glass_arms(hc: Vector3, R: Vector3, hk: float, col: Color, y: float) -> void:
	_stroke(hc, R, Vector3(-0.018, y, -0.12), Vector3(0.018, y, -0.12), 0.0022, 0.0065, col, hk)
	for sx in [-1.0, 1.0]:
		_stroke(hc, R, Vector3(0.074 * sx, y + 0.004, -0.095), Vector3(0.118 * sx, y + 0.008, -0.01), 0.0028, 0.0055, col, hk)


## 머리 모양(인형과 같은 이름): spiky · bald · crew · buzz · short · long · ponytail · curly · undercut · fringe, 나머지는 뒤로 넘긴 올백
func _hair(lk: Dictionary, hc: Vector3, hk: float, hair: Color) -> void:
	var style := str(lk.get("hair_style", "short"))
	_sheen_on(lk, hair, style)
	if style == "bun" or (lk.get("female", false) and style in ["ponytail", "long", "bob"]):
		_hair_fem(lk, hc, hk, hair, style)
	elif style == "spiky":
		_blob(hc + Vector3(0, 0.05, 0.01) * hk, Vector3(0.125, 0.09, 0.125) * hk, hair, "head")
		for k in 9:
			var a := TAU * k / 9.0
			var base: Vector3 = hc + Vector3(0.07 * cos(a), 0.1, 0.07 * sin(a) + 0.01) * hk
			_cone(base, base + Vector3(0.06 * cos(a), 0.12, 0.06 * sin(a)) * hk, 0.035 * hk, hair, "head")
	elif style == "bald":
		pass
	elif style == "crew" or style == "buzz" or style == "short":
		if style == "buzz":                                         # 짧게 민 머리 — 살빛이 비치는 얇은 껍질
			hair = hair.lerp(lk["skin"], 0.3)
		# 아주 짧게 깎은 머리 — 머리통에 붙은 얇은 껍질. 뒤 · 위로 물려 이마가 보이게(바가지 머리처럼 보였다 — 2026-11-06 검토)
		_blob(hc + Vector3(0, 0.058, 0.028) * hk, Vector3(0.124, 0.088, 0.122) * hk, hair, "head")
		# 뒤통수 ~ 목덜미(위 껍질만으론 뒤 아래 절반이 살이라 위에서 내려다보면 탈모처럼 보였다 — 2026-11-09 폰 '김대건 가운데 머리 뚫림')
		_blob(hc + Vector3(0, -0.01, 0.04) * hk, Vector3(0.13, 0.105, 0.105) * hk, hair, "head")
		if style == "short":                                        # 위로 세워 뒤로 넘긴 앞머리
			_blob(hc + Vector3(0, 0.115, -0.045) * hk, Vector3(0.085, 0.04, 0.06) * hk, hair, "head")
	elif style == "bob":
		# 턱선 단발(차수민): 머리통 + 턱까지 내려오는 옆 · 뒤 + 옆으로 넘긴 앞머리
		_blob(hc + Vector3(0, 0.05, 0.015) * hk, Vector3(0.13, 0.1, 0.13) * hk, hair, "head")
		_blob(hc + Vector3(0, -0.02, 0.05) * hk, Vector3(0.128, 0.11, 0.085) * hk, hair, "head")
		for sx in [-1.0, 1.0]:
			_blob(hc + Vector3(0.105 * sx, -0.03, -0.02) * hk, Vector3(0.036, 0.085, 0.075) * hk, hair, "head")
		_blob(_on_head(hc, hk, Vector3(-0.04, 0.09, -0.1)), Vector3(0.07, 0.03, 0.025) * hk, hair, "head")
	elif style == "long":
		# 어깨까지 오는 장발(가운데 가르마)
		# 긴 머리(hair_long — 가슴 · 허리 기장: 히데 · 리사 · 유세희)는 뒤 · 옆을 길게. 앞 껍질은 위로 물려 일자 앞머리가 안 생기게
		var ln := 1.0 if not lk.get("hair_long", false) else 1.7
		_blob(hc + Vector3(0, 0.058, 0.026) * hk, Vector3(0.13, 0.1, 0.126) * hk, hair, "head")
		_blob(hc + Vector3(0, -0.05 - 0.09 * (ln - 1.0), 0.06) * hk, Vector3(0.125, 0.15 * ln, 0.08) * hk, hair, "head")
		for sx in [-1.0, 1.0]:
			_blob(hc + Vector3(0.105 * sx, -0.045 - 0.08 * (ln - 1.0), -0.005) * hk, Vector3(0.035, 0.13 * ln, 0.08) * hk, hair, "head")
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
			if lk.get("hat") in ["headband", "bandana"]:              # 이마 띠가 앞머리에 묻히지 않게(라텔 — 띠 위로 부푼 머리)
				break
			_blob(hc + Vector3(-0.06 + 0.04 * k, 0.05 - 0.01 * (k % 2), -0.112) * hk, Vector3(0.03, 0.035, 0.02) * hk, hair, "head")
	elif style == "undercut":
		# 옆 · 뒤를 짧게 민 투블럭(hair2) 위로 뒤로 넘긴 머리(서진태 금발 · 윤덕수)
		_blob(hc + Vector3(0, 0.035, 0.015) * hk, Vector3(0.125, 0.1, 0.125) * hk, lk.get("hair2", hair), "head")
		_blob(hc + Vector3(0, 0.1, 0.01) * hk, Vector3(0.105, 0.07, 0.125) * hk, hair, "head")
		_blob(hc + Vector3(0, 0.125, -0.07) * hk, Vector3(0.075, 0.05, 0.06) * hk, hair, "head")
		if lk.get("hair_long", false):                              # 뒤로 묶은 드레드 꼬리(크리사)
			_cone(hc + Vector3(0, 0.06, 0.12) * hk, hc + Vector3(0, -0.24, 0.18) * hk, 0.045 * hk, hair, "head")
	elif style == "messy":
		# 흐트러진 가닥(곱슬 뭉치 아님 — 검토 2026-11-06): 머리 껍질 + 바깥 · 아래로 뻗은 가닥 + 짧은 앞 가닥(눈은 보이게)
		_blob(hc + Vector3(0, 0.065, 0.025) * hk, Vector3(0.13, 0.09, 0.13) * hk, hair, "head")
		_blob(hc + Vector3(0, -0.01, 0.065) * hk, Vector3(0.12, 0.1, 0.08) * hk, hair, "head")
		for k in 10:
			var a := PI * (0.05 + 0.9 * k / 9.0)
			var base: Vector3 = hc + Vector3(0.11 * cos(a), 0.09, 0.11 * sin(a) * 0.6 + 0.04) * hk
			_cone(base, base + Vector3(0.03 * cos(a), -0.1 - 0.025 * (k % 2), 0.03 * sin(a)) * hk, 0.032 * hk, hair, "head")
		for k in 4:
			var x := -0.06 + 0.04 * k
			if lk.get("hat") in ["headband", "bandana"]:
				break
			_cone(_on_head(hc, hk, Vector3(x * 0.9, 0.12, -0.07)), _on_head(hc, hk, Vector3(x * 1.1 + 0.01, 0.06, -0.12)), 0.022 * hk, hair, "head")
		if lk.get("hair_long", false):
			_blob(hc + Vector3(0, -0.1, 0.06) * hk, Vector3(0.12, 0.16, 0.075) * hk, hair, "head")
	else:
		# 뒤로 넘긴 올백: 정수리 · 뒤통수를 덮고 이마 선은 높게 + 앞머리 몇 가닥(fringe 는 눈썹을 덮는 앞머리). 올백 갈래는 이마 선을
		# 위 · 뒤로 물린다(바가지 머리처럼 보였다 — 전인물 외형 검토 2026-11-06)
		var back := style in ["slick", "parted", "wavy_back", "topknot"]   # slick_fringe(김신 · 백도찬)는 앞 가닥이 이마에 놓이게 그대로
		var c0: Vector3 = Vector3(0, 0.074, 0.038) if back else Vector3(0, 0.06, 0.025)
		_blob(hc + c0 * hk, Vector3(0.126, 0.085, 0.122 if back else 0.125) * hk, hair, "head")
		_blob(hc + Vector3(0, 0.0, 0.06) * hk, Vector3(0.115, 0.1, 0.08) * hk, hair, "head")
		if style == "topknot":                                      # 상투(정수리 뒤쪽 — 피우진 · 구일화)
			_blob(hc + Vector3(0, 0.14, 0.075) * hk, Vector3(0.045, 0.045, 0.045) * hk, hair, "head")
		if style == "wavy_back":                                    # 뒤로 넘긴 웨이브 — 목덜미까지 부푼 뒷머리 + 옆 볼륨
			_blob(hc + Vector3(0, -0.06, 0.075) * hk, Vector3(0.115, 0.085, 0.07) * hk, hair, "head")
			for sx in [-1.0, 1.0]:
				_blob(hc + Vector3(0.1 * sx, 0.01, 0.04) * hk, Vector3(0.04, 0.07, 0.07) * hk, hair, "head")
		if lk.get("hair_long", false):                              # 긴 머리를 뒤로 묶은 꼬리 · 땋은 머리(비손)
			_cone(hc + Vector3(0, -0.02, 0.13) * hk, hc + Vector3(0, -0.3, 0.17) * hk, 0.04 * hk, hair, "head")
		if style == "slick_fringe" and lk.get("female", false):    # 이마로 흘러내린 앞 가닥(링링) — 겉면에 붙인 가는 조각(원뿔은 외곽선이 W 자로 찍혔다)
			for k in 3:
				_patch(hc, FEM_HEAD * hk, Vector3(-0.034 + 0.026 * k, 0.07 - 0.004 * k, -0.11), 0.0055, 0.03, 0.004 + 0.0005 * k,
					-18.0 + 6.0 * k, hair, hk)
		elif style == "slick_fringe":
			for k in 3:
				var b: Vector3 = hc + Vector3(-0.03 + 0.03 * k, 0.09, -0.11) * hk
				_cone(b, b + Vector3(0.005, -0.054, -0.01) * hk, 0.012 * hk, hair, "head")   # 끝이 눈썹 위에서 멈춘다(눈썹을 가로지르지 않게)
		elif style == "fringe":
			for k in 7:                                             # 이마를 덮고 눈썹까지 내려오는 가닥(촘촘히 — 모자처럼 안 보이게)
				var x := -0.084 + 0.028 * k
				_cone(_on_head(hc, hk, Vector3(x * 0.9, 0.12, -0.06)), _on_head(hc, hk, Vector3(x * 1.05 + 0.006, 0.03, -0.12)),
					0.026 * hk, hair, "head")
	sheen_hair = null


## 여성 머리(2026-11-07 폰 '오지인 못생김' — 카드 초상 하성_오지인 · 차수민 대조): 껍질을 뒤 · 위로 물려 이마를 드러내고(바가지
## 앞머리 · 헬멧처럼 보였다), 옆 가르마에서 넘긴 앞머리 결 + 얼굴 옆으로 흘러내린 가는 앞 가닥(_patch — 겉면에 붙인 한 겹이라
## 외곽선이 굵게 안 두른다). bun — 낮은 쪽머리(오지인) · ponytail — 뒤로 묶은 꼬리(이리원 · 마리나) · long — 등까지 늘어진 생머리
## (리사 · 유세희, hair_long 이면 더 길게) · bob — 턱선 단발 + 가운데서 갈라진 시스루 앞머리(차수민)
func _hair_fem(lk: Dictionary, hc: Vector3, hk: float, hair: Color, style: String) -> void:
	var hr := FEM_HEAD * hk if lk.get("female", false) else Vector3(0.12, 0.13, 0.12) * hk
	var ln := 1.7 if lk.get("hair_long", false) else 1.0
	if style == "bob":
		_blob(hc + Vector3(0, 0.06, 0.022) * hk, Vector3(0.124, 0.094, 0.126) * hk, hair, "head")
		_blob(hc + Vector3(0, -0.045, 0.03) * hk, Vector3(0.128, 0.11, 0.105) * hk, hair, "head")             # 턱선까지 내려오는 종 모양 옆 · 뒤
		for sx in [-1.0, 1.0]:
			for k in 3:                                                                                     # 가운데서 갈라진 앞머리 가닥
				_patch(hc, hr, Vector3((0.014 + 0.022 * k) * sx, 0.078 - 0.006 * k, -0.1), 0.009, 0.026, 0.004 + 0.0005 * k,
					(-10.0 - 8.0 * k) * sx, hair, hk)
		sheen_hair = null
		return
	_blob(hc + Vector3(0, 0.064, 0.03) * hk, Vector3(0.119, 0.088, 0.122) * hk, hair, "head")
	if style != "long":                                             # 가르마에서 넘긴 앞머리 결(살짝 볼륨 — 생머리는 없이)
		_blob(hc + Vector3(0.008, 0.094, -0.024) * hk, Vector3(0.08, 0.03, 0.066) * hk, hair, "head")
	_blob(hc + Vector3(0, 0.0, 0.065) * hk, Vector3(0.108, 0.1, 0.075) * hk, hair, "head")
	var strand := 1.0                                               # 앞 가닥 길이(턱까지 = 1)
	if style == "bun":                                              # 낮은 쪽머리(뒤에서 보이게 크게) + 틀어 감은 결
		_blob(hc + Vector3(0, -0.02, 0.155) * hk, Vector3(0.066, 0.056, 0.052) * hk, hair, "head")
		_blob(hc + Vector3(0.012, -0.012, 0.196) * hk, Vector3(0.036, 0.03, 0.022) * hk, hair, "head")
	elif style == "ponytail":                                       # 뒤통수 높이 묶음 + 늘어진 꼬리(굵게)
		_blob(hc + Vector3(0, 0.03, 0.14) * hk, Vector3(0.04, 0.04, 0.035) * hk, hair, "head")
		_line(hc + Vector3(0, 0.0, 0.17) * hk, hc + Vector3(0, -0.2, 0.19) * hk, 0.036 * hk, hair, "head")
		strand = 0.7
	else:                                                           # long — 등으로 늘어진 생머리 + 어깨 앞으로 오는 옆머리
		_blob(hc + Vector3(0, -0.06 - 0.09 * (ln - 1.0), 0.07) * hk, Vector3(0.118, 0.15 * ln, 0.075) * hk, hair, "head")
		for sx in [-1.0, 1.0]:
			_blob(hc + Vector3(0.1 * sx, -0.06 - 0.06 * (ln - 1.0), 0.025) * hk, Vector3(0.03, 0.12 * ln, 0.06) * hk, hair, "head")
	for sx in [-1.0, 1.0]:                                          # 앞 가닥: 관자놀이 → 광대 → 턱선(겹치게 이어 붙인다)
		_patch(hc, hr, Vector3(0.084 * sx, 0.04, -0.082), 0.0042, 0.036, 0.004, 12.0 * sx, hair, hk)
		_patch(hc, hr, Vector3(0.094 * sx, -0.02, -0.072), 0.0036, 0.04 * strand, 0.0045, 2.0 * sx, hair, hk)
		if strand >= 1.0:
			_patch(hc, hr, Vector3(0.086 * sx, -0.068, -0.08), 0.003, 0.03, 0.005, -14.0 * sx, hair, hk)
	sheen_hair = null


## 머리 껍질(정수리를 덮는 타원체) 반지름(머리 크기 단위, x · z) — 띠 · 모자 · 윤기 자리
func _hair_shell(style: String) -> float:
	if style == "curly" or style == "messy":
		return 0.138
	if style == "long" or style == "bob":
		return 0.13
	return 0.126


## 짙은 머리 윤기(만화의 검은 머리 하이라이트) — 큰 머리 껍질 타원체의 앞쪽 위 띠 정점만 밝은 색(정점 색 사이가 번져 부드러운 띠).
## 덧붙인 조각은 외곽선이 둘러 꿰맨 자국처럼 보여서(첫 시도) 겉면 색으로만 한다. 검은 덩어리로 안 보이게(전인물 외형 검토 2026-11-06)
func _sheen_on(lk: Dictionary, hair: Color, style: String) -> void:
	sheen_hair = null
	if style in ["bald", "buzz", "crew", "short"] or lk.get("hat") in ["beanie", "bucket", "cap", "fedora", "hood", "helmet", "bandana"]:
		return
	if 0.3 * hair.r + 0.59 * hair.g + 0.11 * hair.b > 0.22:       # 짙은 머리만(짧은 머리 · 회색에선 이마 띠처럼 보였다 — 강만재)
		return
	sheen_hair = hair
	sheen_col = hair.lerp(Color(0.62, 0.66, 0.78), 0.42)


## 중심 c · 반지름 r 타원체의 dir 쪽 겉면 점
func _on_ell(c: Vector3, r: Vector3, dir: Vector3) -> Vector3:
	var q := Vector3(dir.x / r.x, dir.y / r.y, dir.z / r.z)
	return c + dir / q.length()


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
	var shine: bool = sheen_hair != null and col == sheen_hair and r.x >= 0.1 and r.z >= 0.1
	var grid: Array = []
	for i in rings + 1:
		var v := PI * i / rings
		var row: Array = []
		for j in seg:
			var u := TAU * j / seg
			var n := Vector3(sin(v) * cos(u), cos(v), sin(v) * sin(u))
			var vc := sheen_col if shine and i == 2 and n.z < -0.15 else col     # 앞쪽 위(위도 45도) 띠
			row.append([c + Vector3(n.x * r.x, n.y * r.y, n.z * r.z), [bone], [1.0], vc])
		grid.append(row)
	for i in rings:
		for j in seg:
			var j2 := (j + 1) % seg
			var q: Array = [grid[i][j], grid[i][j2], grid[i + 1][j2], grid[i + 1][j]]
			for t in [q[0], q[2], q[1], q[0], q[3], q[2]]:
				_vert(t[0], t[3], t[1], t[2])


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


## 신발: 뒤꿈치 → 발끝 단면 관(바닥이 평평하고 앞이 낮아지는 구두 · 운동화 모양) + 밑창(sole — 조금 넓게 둘러 보이게)
func _shoe(ft: Vector3, s: float, col: Color, sole, bone: String) -> void:
	var bottom := -0.065 * s
	var rows := [[0.06, 0.028, 0.04], [0.04, 0.044, 0.052], [-0.01, 0.048, 0.057], [-0.08, 0.037, 0.061], [-0.14, 0.03, 0.058], [-0.175, 0.022, 0.047]]
	var rings: Array = []
	var srings: Array = []
	for r in rows:
		var h: float = r[1] * s
		var w: float = r[2] * s
		rings.append([ft + Vector3(0, bottom + h + (0.01 * s if sole != null else 0.0), r[0] * s), h, w, [bone], [1.0], col])
		srings.append([ft + Vector3(0, bottom + 0.011 * s, r[0] * s * 1.03), 0.012 * s, w + 0.006 * s, [bone], [1.0], sole])
	_loft(rings, 2.6, 12, 0.015, 0.02)
	if sole != null:
		_loft(srings, 3.0, 12, 0.006, 0.006)


## 몸통 단면 표: [골반 뼈 기준 높이, 옆 반지름, 앞뒤 반지름] — 엉덩이 · 허리 · 가슴 · 어깨 · 목 밑. waist_k · chest_k 는 여성 허리 · 가슴
func _torso_prof(wide: float, sh_wide: float, hip_k: float, waist_k: float, chest_k: float, hz: float, bz: float) -> Array:
	var sw := maxf(0.225 * wide, 0.215 * sh_wide) * chest_k
	return [
		[-0.14, 0.11 * wide * hip_k, hz * 0.7],
		[-0.09, 0.152 * wide * hip_k, hz * 0.93],
		[-0.02, 0.16 * wide * hip_k, hz],
		[0.1, 0.158 * wide * waist_k, hz * 0.94],
		[0.22, 0.186 * wide * lerpf(waist_k, chest_k, 0.5), bz * 0.97],
		[0.33, 0.215 * wide * chest_k, bz],
		[0.42, sw, bz * 0.98],
		[0.47, sw * 0.93, bz * 0.88],
		[0.505, 0.165 * wide, bz * 0.7],
		[0.53, 0.1 * wide, bz * 0.5],
		[0.545, 0.066 * wide, 0.06],
	]


## 단면 표를 높이 y 에서 부드럽게(Catmull-Rom) 읽는다 → Vector2(옆, 앞뒤)
func _prof_at(prof: Array, y: float) -> Vector2:
	var n := prof.size()
	if y <= prof[0][0]:
		return Vector2(prof[0][1], prof[0][2])
	if y >= prof[n - 1][0]:
		return Vector2(prof[n - 1][1], prof[n - 1][2])
	var i := 0
	while prof[i + 1][0] < y:
		i += 1
	var t: float = (y - prof[i][0]) / (prof[i + 1][0] - prof[i][0])
	var out := Vector2.ZERO
	for k in 2:
		var p0: float = prof[maxi(i - 1, 0)][k + 1]
		var p1: float = prof[i][k + 1]
		var p2: float = prof[i + 1][k + 1]
		var p3: float = prof[mini(i + 2, n - 1)][k + 1]
		out[k] = 0.5 * (2.0 * p1 + (p2 - p0) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t * t + (3.0 * p1 - p0 - 3.0 * p2 + p3) * t * t * t)
	return out


## 몸통 관 한 벌: 높이 ys(골반 뼈 기준)마다 단면 + grow(옷 두께). min_a · min_b > 0 이면 밑단을 그만큼 벌려(엉덩이를 덮는 자락)
## 위로 0.16 에 걸쳐 몸에 붙인다. 가중치: 골반 → 허리(spine) → 가슴(chest)
func _torso_loft(prof: Array, ys: Array, grow: float, col: Color, min_a: float, min_b: float, cap0: float, cap1: float) -> void:
	var h: Vector3 = gpos["hips"]
	var rings: Array = []
	for y in ys:
		var s := _prof_at(prof, y) + Vector2(grow, grow)
		if min_a > 0.0:
			var k := clampf((y - float(ys[0])) / 0.16, 0.0, 1.0)
			s.x = maxf(s.x, lerpf(min_a, s.x, k))
			s.y = maxf(s.y, lerpf(min_b, s.y, k))
		var bw: Array
		if y <= 0.0:
			bw = [["hips"], [1.0]]
		elif y < 0.12:
			bw = [["hips", "spine"], [1.0 - y / 0.12, y / 0.12]]
		elif y < 0.22:
			bw = [["spine"], [1.0]]
		elif y < 0.34:
			var t: float = (y - 0.22) / 0.12
			bw = [["spine", "chest"], [1.0 - t, t]]
		else:
			bw = [["chest"], [1.0]]
		rings.append([h + Vector3(0, y, 0), s.x, s.y, bw[0], bw[1], col])
	_loft(rings, 2.5, 16, cap0, cap1)


## 팔 · 다리 한 줄 관: 점 [위치, 반지름, 뼈 목록, 가중치, 색] 을 이어(관절에서 끊기지 않게) — 둥근 단면
func _limb(pts: Array, cap0: float, cap1: float, seg := 12) -> void:
	var rings: Array = []
	for p in pts:
		rings.append([p[0], p[1], p[1], p[2], p[3], p[4]])
	_loft(rings, 2.0, seg, cap0, cap1)


## 단면 고리를 이어 붙인 매끈한 관(몸통 · 팔다리 · 신발 — 마디마다 따로 만든 관 · 뚜껑이 굽힐 때 튀어나와 '울퉁불퉁한 덩어리'로
## 보였다 — 폰 리뷰 2026-11-07). ring = [중심, 옆 반지름, 앞뒤 반지름, 뼈 목록, 가중치, 색]. 단면은 초타원(sq 2 = 타원, 클수록
## 각진 옷 실루엣). 같은 자리에 색만 다른 고리를 두 번 두면 색 경계가 번지지 않고 또렷하다. 축 · 감기 방향은 _tube 와 같다.
func _loft(rings: Array, sq: float, seg: int, cap0: float, cap1: float) -> void:
	var up: Vector3 = (rings[rings.size() - 1][0] - rings[0][0]).normalized()
	var side := up.cross(Vector3.FORWARD if absf(up.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT).normalized()
	var fwd := side.cross(up).normalized()
	var e := 2.0 / sq
	var rows: Array = []
	for rg in rings:
		var row: Array = []
		for j in seg:
			var u := TAU * j / seg
			var cu := cos(u)
			var su := sin(u)
			var p: Vector3 = rg[0] + side * signf(cu) * pow(absf(cu), e) * rg[1] + fwd * signf(su) * pow(absf(su), e) * rg[2]
			row.append([p, rg[3], rg[4], rg[5]])
		rows.append(row)
	for i in rows.size() - 1:
		for j in seg:
			var j2 := (j + 1) % seg
			var a: Array = rows[i][j]
			var b: Array = rows[i + 1][j]
			var c: Array = rows[i + 1][j2]
			var d: Array = rows[i][j2]
			for v in [a, c, b, a, d, c]:
				_vert(v[0], v[3], v[1], v[2])
	if cap0 >= 0.0:                                                  # 끝 뚜껑 — 축 바깥으로 cap 만큼 둥글게 부푼 부채꼴
		_dome(rows[0], rings[0][0] - up * cap0, true)
	if cap1 >= 0.0:
		_dome(rows[rows.size() - 1], rings[rings.size() - 1][0] + up * cap1, false)


## 고리 하나를 가운데 점 c 로 닫는다(가운데 · 중간 고리 두 겹 — 납작한 뚜껑 모서리가 외곽선으로 각지게 보이지 않게)
func _dome(row: Array, c: Vector3, flip: bool) -> void:
	var c0: Vector3 = Vector3.ZERO
	for v in row:
		c0 += v[0]
	c0 /= row.size()
	var mid: Array = []
	for v in row:
		mid.append([v[0].lerp(c0, 0.45) + (c - c0) * 0.7, v[1], v[2], v[3]])
	for j in row.size():
		var j2 := (j + 1) % row.size()
		var a: Array = row[j]
		var b: Array = row[j2]
		var m0: Array = mid[j]
		var m1: Array = mid[j2]
		var cv: Array = [c, a[1], a[2], a[3]]
		var tri: Array = [[a, b, m1], [a, m1, m0], [m0, m1, cv]] if flip else [[a, m1, b], [a, m0, m1], [m0, cv, m1]]
		for t in tri:
			for v in t:
				_vert(v[0], v[3], v[1], v[2])


## 초타원체(각이 조금 진 둥근 상자 — 주먹 · 밑창). n 2 = 타원체, 클수록 상자
func _sq_blob(c: Vector3, r: Vector3, n: float, col: Color, bone: String, seg := 12, rings := 8) -> void:
	var e := 2.0 / n
	var grid: Array = []
	for i in rings + 1:
		var v := PI * i / rings
		var row: Array = []
		for j in seg:
			var u := TAU * j / seg
			var sv := sin(v)
			var cv := cos(v)
			var k := signf(sv) * pow(absf(sv), e)
			var x := k * signf(cos(u)) * pow(absf(cos(u)), e)
			var z := k * signf(sin(u)) * pow(absf(sin(u)), e)
			row.append(c + Vector3(x * r.x, signf(cv) * pow(absf(cv), e) * r.y, z * r.z))
		grid.append(row)
	for i in rings:
		for j in seg:
			var j2 := (j + 1) % seg
			for p in [grid[i][j], grid[i + 1][j2], grid[i][j2], grid[i][j], grid[i + 1][j], grid[i + 1][j2]]:
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
