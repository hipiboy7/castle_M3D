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
const FacePainter = preload("res://tools/face_painter.gd")  # 2D 웹툰 4표정 얼굴 아틀라스(좌상단 256x256)

var bones := {}                  # 이름 → 번호
var sheen_hair = null            # 머리 윤기 — 이 색의 큰 머리 껍질 _blob 은 앞쪽 위 띠 정점을 sheen_col 로(_sheen_on)
var sheen_col := Color.WHITE
var gpos := {}                   # 이름 → 쉬는 자세 위치(뼈대 공간)
const FEM_HEAD := Vector3(0.112, 0.13, 0.117)   # 여성 머리 타원체(갸름하게 — 남성 0.12 · 0.13 · 0.12)
## 여성 글래머 몸(2026-11-12 rc.16 "막대기 같아. 좀더 날씬한 글래머로"): 골반 · 허리 · 가슴 · 엉덩이 · 허벅지 위쪽 배율
const FEM_HIP := 1.26
const FEM_WAIST := 0.72
const FEM_CHEST := 0.94
const FEM_BUST := 1.22
const FEM_SEAT := 0.82
const FEM_THIGH := 1.22
const FACE_LIFT := 0.0007
const MALE_HEAD := Vector3(0.12, 0.13, 0.12)
const MALE_WARP := Vector3(0.26, 1.5, 0.08)
const MALE_WARP_JAW := Vector3(0.3, 2.3, 0.05)
const MALE_CHIN := 0.07
var head_warp := Vector3.ZERO
var tris := 0
const PAINT_LOW := 0.84
const PAINT_HIGH := 1.05
const INK_COL := Color(0.035, 0.028, 0.045)
const INK_W := 0.0072
const INK_LIFT := 0.0032
var paint_k := 0.0
## 512x512 RGB8 풀컬러 아틀라스(v2 — 2026-11-23):
##  - (0,0)-(256,256): 2x2 동적 표정 얼굴 아틀라스(FacePainter, 각 128x128)
##  - (256,0)-(512,16): 단색 팔레트 스와치(4x4 × 최대 64색 — 먹선 띠 · 원뿔 · 귀걸이 · 뚜껑)
##  - 나머지 영역: 몸통 · 팔다리 · 머리 · 옷 UV 셀(선반 쌓기)
## 꼭짓점 COLOR 는 RGB 대신 (mat_id, spec_k, hatch_k, ao_k) 부위 채널을 담아 1 드로우콜로 피부/머리/옷/가죽 셰이딩을 분리한다.
const PAINT_TEX := 512
const FACE_BOX := 256
const SWATCH_H := 16
const CELL_PAD := 2
var cells: Array = []            # [{pos, col, wrap, hint}] — 0 은 스와치, -1 은 얼굴 아틀라스 직접 UV
var vbuf: Array = []             # [위치, 원색 Color, 뼈, 가중치, 칸, 칸 안 uv, 부위 힌트]
var vbuf_glasses: Array = []     # 별도 Glasses 서브메시(백도찬 2차 remove_glasses 복구)
var vbuf_loose: Array = []       # 별도 HairLoose 서브메시(2차 앞머리 풀림)
var _cur_vbuf_mode := "body"
var swatches: Dictionary = {}    # hex → swatch index(0..63)
var swatch_cols: Array = []
var paint_look: Dictionary = {}
var cur_hint := ""               # "hair" · "skin" · "metal" · "leather" · "ink" · ""
var crev: Array = []


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
		if Imported.SRC.has(id) and Imported.SRC[id].get("active", true):
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
	cells = [{"pos": [], "col": [], "wrap": false, "hint": ""}]
	vbuf.clear()
	vbuf_glasses.clear()
	vbuf_loose.clear()
	_cur_vbuf_mode = "body"
	swatches.clear()
	swatch_cols.clear()
	paint_look = lk
	_body(lk)
	var rects := _pack_cells()
	var skin := Skin.new()
	for n in bones:
		skin.add_named_bind(n, Transform3D(Basis(), -gpos[n]))
	# 메시를 먼저 커밋해 스와치 목록(swatch_cols)을 모두 등록한 뒤 512x512 아틀라스를 칠한다
	var body_mesh := _commit_vbuf(vbuf, rects, false)
	var loose_mesh: ArrayMesh = _commit_vbuf(vbuf_loose, rects, false) if not vbuf_loose.is_empty() else null
	var glasses_mesh: ArrayMesh = _commit_vbuf(vbuf_glasses, rects, true) if not vbuf_glasses.is_empty() else null
	var atlas_tex := ImageTexture.create_from_image(_paint(rects))
	tris = body_mesh.surface_get_array_index_len(0) / 3
	var mi := MeshInstance3D.new()
	mi.name = "Body"
	mi.mesh = body_mesh
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.roughness = 0.8
	m.albedo_texture = atlas_tex
	mi.material_override = m
	mi.skin = skin
	sk.add_child(mi)
	mi.owner = root
	mi.skeleton = NodePath("..")
	if glasses_mesh != null:
		var gmi := MeshInstance3D.new()
		gmi.name = "Glasses"
		gmi.mesh = glasses_mesh
		var gmat := StandardMaterial3D.new()
		gmat.vertex_color_use_as_albedo = true
		gmat.roughness = 0.2
		gmat.metallic = 0.6
		gmi.material_override = gmat
		gmi.skin = skin
		sk.add_child(gmi)
		gmi.owner = root
		gmi.skeleton = NodePath("..")
	if loose_mesh != null:
		var lmi := MeshInstance3D.new()
		lmi.name = "HairLoose"
		lmi.mesh = loose_mesh
		lmi.material_override = m
		lmi.skin = skin
		sk.add_child(lmi)
		lmi.owner = root
		lmi.skeleton = NodePath("..")
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	var err := doc.append_from_scene(root, state)
	if err == OK:
		err = doc.write_to_filesystem(state, ProjectSettings.globalize_path(path))
	root.free()
	return err


func _commit_vbuf(buf: Array, rects: Array, direct_rgb: bool) -> ArrayMesh:
	var s := SurfaceTool.new()
	s.set_skin_weight_count(SurfaceTool.SKIN_4_WEIGHTS)
	s.begin(Mesh.PRIMITIVE_TRIANGLES)
	for v in buf:
		var pos: Vector3 = v[0]
		var col: Color = v[1]
		var cid: int = int(v[4])
		var uv_in: Vector2 = v[5]
		var h: String = str(v[6])
		var pk: float = float(v[7])
		var vc: Color = col if direct_rgb else _encode_vcol(pos, col, h, pk)
		s.set_color(vc)
		s.set_bones(v[2])
		s.set_weights(v[3])
		if direct_rgb:
			s.set_uv(Vector2.ZERO)
		elif cid == -1:
			s.set_uv(uv_in)
		elif cid == 0:
			s.set_uv(_swatch_uv(col))
		else:
			s.set_uv(_atlas_uv(rects, cid, uv_in))
		s.add_vertex(pos)
	s.index()
	s.generate_normals()
	return s.commit()


func _encode_vcol(p: Vector3, col: Color, hint: String, pk: float) -> Color:
	var kind := "ink" if col == INK_COL else _kind_of(hint, col)
	var mat_id := 0.0
	var spec_k := 0.0
	var hatch_k := 0.82
	match kind:
		"skin":
			mat_id = 0.33
			spec_k = 0.0
			hatch_k = 0.0
		"hair":
			mat_id = 0.66
			spec_k = 0.38
			hatch_k = 0.25
		"leather":
			mat_id = 0.90
			spec_k = 0.42
			hatch_k = 0.30
		"metal":
			mat_id = 0.98
			spec_k = 0.88
			hatch_k = 0.12
		"ink":
			mat_id = 0.0
			spec_k = 0.0
			hatch_k = 0.0
		_:
			mat_id = 0.0
			spec_k = 0.0
			hatch_k = 0.56
	var ao := 1.0
	if kind != "ink" and pk > 0.0:
		var k := lerpf(PAINT_LOW, PAINT_HIGH, smoothstep(0.08, 1.45, p.y))
		for c in crev:
			var d: float = p.distance_to(c[0])
			if d < c[1]:
				var u: float = 1.0 - d / c[1]
				k *= 1.0 - float(c[2]) * u * u
		ao = clampf((k - 0.55) / 0.5, 0.0, 1.0)
	return Color(mat_id, spec_k, hatch_k, ao)


func _swatch_uv(col: Color) -> Vector2:
	var key := col.to_html(false)
	var idx: int
	if swatches.has(key):
		idx = swatches[key]
	else:
		idx = mini(swatch_cols.size(), 255)
		swatches[key] = idx
		if swatch_cols.size() < 256:
			swatch_cols.append(col)
	var sx := FACE_BOX + (idx % 64) * 4 + 2
	var sy := (idx / 64) * 4 + 2
	return Vector2(float(sx) / float(PAINT_TEX), float(sy) / float(PAINT_TEX))


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
	paint_k = 1.0
	# 근육(Looks.look muscle — 2026-11-12 사용자 "근육질인 것 같은 모형으로"): 0 = 보통, 1 = 큰 인물. 역삼각(어깨 ↑ 허리 ↓) · 가슴 ·
	# 승모 · 어깨세모근 · 이두 · 아래팔 · 허벅지를 키운다(통처럼 넓히는 대신 — 넓이는 Looks BIG_TAME 이 줄였다)
	var mus: float = 0.0 if fem else float(lk.get("muscle", 0.0))
	var shw: float = float(lk.get("shoulder", wide)) * (1.0 + 0.07 * mus)
	crev = [
		[g["hips"] + Vector3(0, -0.15, 0), 0.12, 0.32],                 # 사타구니
		[g["neck"] + Vector3(0, 0.05, -0.05), 0.09, 0.34],              # 목 밑(턱 그늘)
		[g["chest"] + Vector3(0, 0.235, 0.06), 0.09, 0.18],              # 목 뒤 깃 밑
	]
	for side in ["r", "l"]:
		var sx0 := 1.0 if side == "r" else -1.0
		crev.append([g["chest"] + Vector3(0.165 * sx0 * shw, 0.06, 0.0), 0.1, 0.36])   # 겨드랑이
		crev.append([g["kn_" + side] + Vector3(0, 0.0, 0.075), 0.075, 0.28])          # 무릎 뒤
		crev.append([g["el_" + side] + Vector3(0, -0.005, -0.055), 0.055, 0.22])      # 팔꿈치 안
	# 골반 · 허리 · 가슴(하나로 이어진 몸통) — 여성은 골반을 넓히고 허리를 조인다
	# 여성 글래머(2026-11-12 rc.16 사용자 "여자 애들 너무 막대기 같아. 좀더 날씬한 글래머로"): 골반 더 넓게 · 허리 더 조이고 · 가슴 · 엉덩이 ·
	# 허벅지 위쪽을 채운다(팔다리 굵기 limb 는 그대로 — 날씬하게). 수치는 FEM_* (파일 머리)
	var hip_k := FEM_HIP if fem else 1.0
	# 몸통 관의 앞뒤 두께(dz)는 골반 · 가슴 타원체와 겉면이 맞게 — 관이 더 두꺼우면 가슴 아래 턱 · 검은 띠(외곽선)가 생기고
	# 셔츠 앞판이 관 속에 묻혔다(전인물 외형 검토 2026-11-06). bz = 가슴 앞 겉면(머리 · 셔츠 앞판 자리)
	var bz := 0.15 * depth * maxf(1.0, wide)
	# 몸통은 한 겹 관(_loft) 두 벌 — 바지(골반) + 겉옷(밑단 ~ 목). 전에는 골반 · 허리 · 가슴 덩어리 셋이 겹쳐 허리에 턱이 지고
	# 외곽선이 마디마다 그어졌다(폰 리뷰 2026-11-07 '울퉁불퉁'). 단면 너비 표 _torso_prof — 가슴 앞 겉면은 그대로 bz(셔츠 앞판 · 넥타이 자리)
	var hz := 0.13 * depth * maxf(1.0, wide * 0.95)
	var prof := _torso_prof(wide, shw, hip_k, FEM_WAIST if fem else 0.95 - 0.08 * mus, FEM_CHEST if fem else 1.0 + 0.05 * mus, hz, bz)   # 남성 허리 조금 조임(V 자 — Hades 실루엣)
	var hem := -0.09                                                # 겉옷 밑단(골반 뼈 기준 높이) — 정장 · 코트는 엉덩이를 덮는다
	if jacket:
		hem = -0.005                                                # 봄버 · 트랙: 허리 밴드
	elif shirt_only or vest:
		hem = 0.025                                                 # 바지에 넣은 셔츠 · 조끼 + 허리띠
	var thigh_out := 0.095 * wide + 0.095 * limb * wide             # 허벅지 바깥 끝 — 겉옷 밑단이 그보다 넓게(다리가 뚫고 나오지 않게)
	# 골반(바지) — 스커트 · 원피스면 자락 색(맨다리라 pants 가 살빛일 때 골반 옆이 살로 비쳤다 — 2026-11-12)
	_torso_loft(prof, [-0.14, -0.1, -0.05, 0.0, 0.05, 0.1, 0.14], 0.0, lk.get("skirt_col", pants) if skirt else pants, -1.0, -1.0, 0.04, 0.03)
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
	if fem:                                                         # 가슴 · 엉덩이(뒤 = +z)
		for sx in [-1.0, 1.0]:
			_blob(g["chest"] + Vector3(0.072 * sx * wide, 0.06, -bz * 0.66), Vector3(0.078, 0.074, 0.08 * depth) * FEM_BUST, top, "chest")
			if not skirt:                                           # 엉덩이 곡선(바지 — 스커트는 자락이 덮는다). 골반 속으로 묻어 두 덩이로 안 보이게
				_blob(g["hips"] + Vector3(0.06 * sx * wide * hip_k, -0.07, hz * 0.42), Vector3(0.09 * wide * hip_k, 0.085, 0.07 * depth) * FEM_SEAT, pants, "hips")
	elif mus > 0.2 and not robe:
		# 큰가슴근(옷 위로 드러나는 두 판 — 아래 가장자리가 또렷하게) · 승모근(목 옆 비탈을 더 높게)
		var pk := 0.7 + 0.45 * mus
		for sx in [-1.0, 1.0]:
			_sq_blob(g["chest"] + Vector3(0.088 * sx * wide, 0.105, -bz * 0.74), Vector3(0.082 * wide, 0.06, 0.055 * depth) * pk, 2.6, top, "chest", 12, 6)
			if mus > 0.45:
				_blob(g["chest"] + Vector3(0.085 * sx * wide, 0.225, 0.012), Vector3(0.07 * wide, 0.035 + 0.03 * mus, 0.065), top, "chest")
	var skirt_col: Color = lk.get("skirt_col", pants)               # 스커트 · 원피스 자락 색(맨다리면 pants = 살빛 — 리사 프롤로그 · 의뢰인)
	var sl: float = float(lk.get("skirt_len", 1.0))                 # 1 = 무릎(펜슬) · 0.6 = 허벅지 가운데(짧은 원피스)
	if skirt:                                                       # 3본 스키닝 연속 로프트 스커트(다리 움직임 시 허벅지 관통 제거)
		_skirt_loft(g["hips"], wide * hip_k, depth, sl, skirt_col)
		if lk.get("torn", false):                                   # 찢긴 자락 — 밑단에 늘어진 천 조각
			for k in 3:
				var a := -1.1 + 1.1 * k
				var b0: Vector3 = g["hips"] + Vector3(0.16 * wide * sin(a), -0.09 - 0.4 * sl, -0.12 * depth * cos(a))
				_cone(b0, b0 + Vector3(0.008 * sin(a), -0.034, -0.004), 0.017, skirt_col, "hips")
	if lk.get("drape") != null:
		_drape(lk, g, shw, depth)
	if lk.get("torn", false):
		_torn(lk, g, wide, bz, skin, top)
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
		# 캐주얼 겉옷: 가운데 지퍼 줄 + 목을 감싸는 안감(셔츠) 깃 — V · 넥타이 없음
		_line(g["chest"] + Vector3(0, 0.22, -bz * 0.93), g["chest"] + Vector3(0, -0.12, -bz * 1.04), 0.006, suit.darkened(0.35), "chest")
		_blob(g["chest"] + Vector3(0, 0.235, -0.01), Vector3(0.072, 0.024, 0.072), shirt, "chest")
	else:
		# 셔츠 V · 넥타이(가슴 앞, -z) — 깃 푼 셔츠는 V 안에 맨가슴
		# 앞판(가슴 겉면 bz 위로 조금 나오게 — 전에는 가슴 속에 묻혀 흰 셔츠 · 넥타이가 점으로만 보였다): 깃 푼 셔츠 · 티는 넓게,
		# 넥타이 셔츠는 V. 옷깃(라펠) 두 줄이 V 가장자리를 따라 내려와 재킷으로 읽히게(아킬라 · 김용성 — 재킷 색이 살빛에 가까움)
		var vk: float = lk.get("v_k", 1.0) if collar == "open" else 1.0      # 앞섶을 더 풀어헤친 만큼(김성준)
		var pw := 0.085 if collar == "crew" or collar == "turtle" else (0.062 * vk if collar == "open" else 0.055)
		var p_z := bz + 0.018 * mus
		if lk.get("inner") != null:                                 # 겉옷 안 정장(outfit.inner — 크로트 트렌치 안 남색 정장): 열린 앞섶에 넓게
			_blob(g["chest"] + Vector3(0, 0.08, -p_z * 0.85), Vector3(0.13 * wide, 0.17, 0.035), lk["inner"], "chest")
			_blob(g["hips"] + Vector3(0, 0.06, -0.12 * depth * maxf(1.0, wide * 0.95)), Vector3(0.12 * wide, 0.09, 0.03), lk["inner"], "hips")
		_blob(g["chest"] + Vector3(0, 0.12, -p_z * 0.96), Vector3(pw, 0.12, 0.032), shirt, "chest")
		if collar == "open":
			_blob(g["chest"] + Vector3(0, 0.2 - 0.04 * vk, -p_z * 1.01), Vector3(0.03, 0.05, 0.02) * vk, skin, "chest")
		if lk.get("tie") != null:
			_blob(g["chest"] + Vector3(0, 0.08, -p_z * 1.01 - 0.014), Vector3(0.022, 0.11, 0.016), lk["tie"], "chest")
		var has_cc: bool = lk.get("coat_collar") != null            # 겉옷 깃 색(outfit.outer.collar — 마준영 롱코트 베이지 깃): 넓은 깃 + 목 뒤 깃
		var lap: Color = INK_COL                                     # 라펠 가장자리 — 먹선(밝은 정장에서도 재킷으로 읽히게 — 2026-11-11 화풍 2단계)
		if has_cc:
			lap = lk["coat_collar"]
		for sx in [-1.0, 1.0]:
			_line(g["chest"] + Vector3(0.075 * sx, 0.25, -p_z * 0.84), g["chest"] + Vector3((pw + 0.008) * sx, 0.0, -p_z * 1.05),
				0.026 if has_cc else 0.007, lap, "chest")
		if has_cc:
			var cc: Color = lk["coat_collar"]
			_blob(g["chest"] + Vector3(0, 0.25, bz * 0.35), Vector3(0.14 * wide, 0.045, 0.08), cc, "chest")
	if lk.get("holster") != null:                                   # 등 X자 가죽 멜빵 + 앞 어깨끈(백도찬 · 황보민철) — 몸통 표면을 따라 밀착
		var hcol: Color = lk["holster"]
		cur_hint = "leather"
		var fa_h := thigh_out + 0.012
		for sx in [-1.0, 1.0]:
			var back_pts: Array = []
			var front_pts: Array = []
			for k in 6:
				var u := float(k) / 5.0
				var yb := lerpf(0.45, 0.14, u)
				var xb := lerpf(0.14 * sx * wide, -0.11 * sx * wide, u)
				back_pts.append(_torso_pt(_coat_ab(prof, yb, 0.012, fa_h, 0.122, hem), yb, xb, false))
				var yf := lerpf(0.46, 0.16, u)
				var xf := lerpf(0.115 * sx * wide, 0.125 * sx * wide, u)
				front_pts.append(_torso_pt(_coat_ab(prof, yf, 0.012, fa_h, 0.122, hem), yf, xf, true))
			_ink_strip(back_pts, 0.032, [], [], hcol)
			_ink_strip(front_pts, 0.030, [], [], hcol)
		cur_hint = ""
	if lk.get("suspenders") != null:                                # 멜빵(검지 · 임종태) — 앞 두 줄 곧게
		for sx in [-1.0, 1.0]:
			_line(g["chest"] + Vector3(0.1 * sx * wide, 0.25, -bz * 0.62), g["chest"] + Vector3(0.085 * sx * wide, -0.2, -bz * 1.0), 0.013,
				lk["suspenders"], "chest")
	if lk.get("chain") != null:                                     # 금 사슬 목걸이(김혁주)
		_line(g["chest"] + Vector3(-0.08, 0.22, -bz * 0.67), g["chest"] + Vector3(0, 0.15, -bz * 1.0), 0.011, lk["chain"], "chest")
		_line(g["chest"] + Vector3(0.08, 0.22, -bz * 0.67), g["chest"] + Vector3(0, 0.15, -bz * 1.0), 0.011, lk["chain"], "chest")
	# 목 · 머리(SD — 크게). 터틀넥은 목까지 옷
	var neck_col: Color = shirt if collar == "turtle" and not shirt_only and not robe else skin
	_tube(g["neck"] + Vector3(0, -0.04, 0), g["head"], 0.06 * wide * (1.0 + 0.18 * mus), 0.058 * wide * (1.0 + 0.1 * mus), neck_col, "neck", "chest", "head")
	if lk.get("neck_tattoo") != null:
		_blob(g["neck"] + Vector3(0.055 * wide, 0.04, -0.01), Vector3(0.012, 0.045, 0.025), lk["neck_tattoo"], "neck")
	paint_k = 0.0                                                   # 머리 · 얼굴 · 머리털 · 소품은 균일 밝기
	var hk: float = 1.55 * float(lk.get("head", 1.0))
	var hc: Vector3 = g["head"] + Vector3(0, 0.06 * hk, 0)
	cur_hint = "skin"
	if fem:
		_head_mesh(hc, FEM_HEAD * hk, skin, true, false)            # 여성 갸름한 V라인 + 2D 웹툰 얼굴 아틀라스 UV
	elif lk.get("mask") != null:
		_head_mesh(hc, Vector3(0.126, 0.136, 0.126) * hk, lk["mask"], false, true)
	else:
		head_warp = MALE_WARP_JAW if lk.get("jaw", false) else MALE_WARP
		_head_mesh(hc, MALE_HEAD * hk, skin, false, false)          # 남성 턱선 + 2D 웹툰 얼굴 아틀라스 UV
	cur_hint = ""
	if lk.get("mask") == null:
		_face_3d_extras(lk, hc, hk)                                 # 귀걸이 · 입마개 · 피어싱 · 정수리 흉터만 3D(눈코입은 2D 아틀라스)
		cur_hint = "hair"
		_hair(lk, hc, hk, hair)
		_hair_loose_submesh(lk, hc, hk, hair)                       # 2차 페이즈 풀린 앞머리 서브메시(백도찬 · 윤덕수)
		cur_hint = ""
		_props(lk, hc, hk)
	head_warp = Vector3.ZERO
	paint_k = 1.0
	# 팔 · 다리
	var tat_side := str(lk.get("tattoo_side", "r"))
	var arm_base: Color = arm
	for side in ["r", "l"]:
		arm = skin if str(lk.get("torn_sleeve", "")) == side else arm_base   # 소매가 찢겨 나간 팔(의뢰인)
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
		# 팔: 어깨 ~ 손목 한 줄 관(팔꿈치에서 끊기지 않게 — 위팔 · 아래팔 가중치를 팔꿈치 둘레에서 나눈다) + 팔꿈치 속 채움 공.
		# 어깨는 따로 붙인 공이었다 — 먹선(ink_line)이 어깨마다 동그랗게 둘러 '공 · 캡슐 조각'으로 보였다(2026-11-11 화풍 2단계). 이제 관이
		# 몸통 속(승모근 밑)에서 시작해 어깨세모근으로 불룩해졌다가 위팔로 이어진다
		var ap: Array = [
			[sh + Vector3(-0.055 * sx, 0.05, 0), 0.046 * limb, ["chest", sb], [0.75, 0.25], arm],
			[sh + Vector3(-0.018 * sx, 0.038, 0), 0.062 * limb * (1.0 + 0.1 * mus), [sb, "chest"], [0.5, 0.5], arm],
			[sh + Vector3(0.004 * sx, 0.008, 0), 0.071 * limb * (1.0 + 0.14 * mus), [sb, "chest"], [0.75, 0.25], arm],   # 어깨세모근
			[sh + Vector3(0.004 * sx, -0.04, 0), 0.07 * limb * (1.0 + 0.1 * mus), [sb], [1.0], arm],
			[sh.lerp(el, 0.34), 0.066 * limb * (1.0 + 0.04 * mus), [sb], [1.0], arm],
			[sh.lerp(el, 0.5) + Vector3(0, 0, -0.008 * mus), 0.064 * limb * (1.0 + 0.16 * mus), [sb], [1.0], arm],          # 이두(앞으로 조금)
			[sh.lerp(el, 0.72), 0.06 * limb * (1.0 + 0.05 * mus), [sb], [1.0], arm],
			[el + up * 0.04, 0.056 * limb, [sb, eb], [0.8, 0.2], arm],
			[el, 0.054 * limb, [sb, eb], [0.5, 0.5], arm],
		]
		if rolled:
			ap.append([el, 0.054 * limb, [sb, eb], [0.5, 0.5], fore])
		ap.append_array([
			[el - up * 0.04, 0.055 * limb, [eb, sb], [0.8, 0.2], fore],
			[el.lerp(ha, 0.3), 0.059 * limb * (1.0 + 0.13 * mus), [eb], [1.0], fore],                       # 아래팔 — 팔꿈치 밑이 굵고 손목으로 좁게
			[el.lerp(ha, 0.75), 0.047 * limb, [eb], [1.0], fore],
		])
		if cuff != null:
			ap.append_array([[ha + up * 0.04, 0.05 * limb, [eb], [1.0], fore], [ha + up * 0.04, 0.043 * limb, [eb], [1.0], cuff],
				[ha + up * 0.005, 0.043 * limb, [eb, hb], [0.6, 0.4], cuff], [ha - up * 0.015, 0.041 * limb, [eb, hb], [0.5, 0.5], cuff]])
		else:
			ap.append_array([[ha + up * 0.01, 0.044 * limb, [eb, hb], [0.6, 0.4], fore], [ha - up * 0.015, 0.042 * limb, [eb, hb], [0.5, 0.5], fore]])
		_limb(ap, 0.02, 0.01)
		_sq_blob(el, Vector3.ONE * 0.051 * limb, 2.0, shirt if rolled else arm, eb, 10, 6)
		if str(lk.get("torn_sleeve", "")) == side:                  # 어깨에 남은 찢긴 소매 띠 + 늘어진 천 조각
			_blob(sh + Vector3(0.004 * sx, -0.015, 0), Vector3(0.078, 0.045, 0.078) * limb, arm_base, sb)
			for k in 3:
				var cb: Vector3 = sh + Vector3((0.02 + 0.02 * k) * sx, -0.045, -0.04 + 0.04 * k)
				_cone(cb, cb + Vector3(0.006 * sx, -0.045 - 0.015 * (k % 2), 0), 0.02, arm_base, sb)
		if lk.get("bruise") != null:                                # 팔뚝 멍
			_sq_blob(el.lerp(ha, 0.45) + Vector3(0.04 * sx * limb, 0, -0.01), Vector3(0.014, 0.028, 0.03) * limb, 2.0,
				skin.lerp(lk["bruise"], 0.5) if arm.is_equal_approx(skin) else arm.darkened(0.25), eb, 8, 4)
		if rolled:
			# 소매 걷음: 팔꿈치 아래 걷어 올린 소매 뭉치 · 팔뚝 문신(비스듬히 감긴 띠)
			_blob(el + Vector3(0, -0.04, 0), Vector3(0.068, 0.04, 0.068) * limb, shirt, "el_" + side)
			if lk.get("tattoo") != null and (tat_side == side or tat_side == "both"):
				var tc: Color = lk["tattoo"].lerp(skin, 0.25)
				for k in 3:
					var p: Vector3 = el.lerp(ha, 0.35 + 0.18 * k)
					_tube(p + Vector3(0, 0.012, 0), p - Vector3(0, 0.012, 0), 0.053 * limb - 0.003 * k, 0.053 * limb - 0.003 * k, tc, "el_" + side)
		# 주먹(2026-11-12 사용자 "손이 구형인데, 이것부터 시작해서 조금씩 더 다듬었으면" — 공 하나 → 손등 · 말아 쥔 네 손가락 · 엄지):
		# 손등은 납작한 모난 판(손바닥이 몸 쪽 -x·sx), 네 손가락은 첫 마디(주먹 아래 바깥) → 손바닥 쪽으로 감기는 짧은 관 넷을 앞뒤(z)로
		# 늘어놓고, 엄지는 손바닥 쪽에서 둘째 마디 위를 가로질러 덮는다 — 마디 사이 먹선이 손가락으로 읽힌다
		var hand_col: Color = lk.get("gloves", skin)                # 장갑(명부)
		var hl: float = limb * (0.78 if fem else (1.0 + 0.08 * mus)) # 여성은 섬세하고 작게
		_sq_blob(ha + Vector3(sx * 0.004, -0.052, -0.002) * hl, Vector3(0.036, 0.05, 0.052) * hl, 4.2, hand_col, hb, 12, 6)   # 손등 · 손바닥
		for k in 4:
			var fz: float = (-0.039 + 0.026 * k) * hl                 # 검지(앞 -z) → 새끼(뒤)
			var fr: float = (0.0145 - 0.0012 * k) * hl
			var drop: float = 0.006 * k * hl                          # 새끼 쪽이 조금 짧다
			_limb([[ha + Vector3(sx * 0.03 * hl, -0.088 * hl + drop, fz), fr, [hb], [1.0], hand_col],      # 첫 마디(주먹 바깥 · 아래)
				[ha + Vector3(sx * 0.016 * hl, -0.113 * hl + drop, fz), fr * 0.98, [hb], [1.0], hand_col],
				[ha + Vector3(-sx * 0.012 * hl, -0.112 * hl + drop, fz), fr * 0.92, [hb], [1.0], hand_col],  # 둘째 마디(손바닥 쪽으로 감김)
				[ha + Vector3(-sx * 0.026 * hl, -0.092 * hl + drop, fz), fr * 0.85, [hb], [1.0], hand_col]], fr * 0.7, fr * 0.7, 8)
		_limb([[ha + Vector3(-sx * 0.022, -0.03, -0.042) * hl, 0.017 * hl, [hb], [1.0], hand_col],          # 엄지 — 손바닥 쪽 앞에서
			[ha + Vector3(-sx * 0.036, -0.066, -0.048) * hl, 0.015 * hl, [hb], [1.0], hand_col],
			[ha + Vector3(-sx * 0.03, -0.097, -0.03) * hl, 0.013 * hl, [hb], [1.0], hand_col]], 0.011 * hl, 0.011 * hl, 8)   # 검지 · 중지 둘째 마디를 덮는다
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
		var tk := FEM_THIGH if fem else 1.0                         # 여성 허벅지 위쪽(골반에서 이어지는 곡선 — 무릎으로 가늘게)
		# 다리: 엉덩이 속 ~ 발목 한 줄 관(허벅지 · 무릎 · 종아리) + 무릎 속 채움 공. 맨살 정강이는 무릎 위 반바지 단에서 색이 바뀐다
		var lp: Array = [
			[th + up * 0.06, lr * 0.86 * tk, ["hips", tb], [0.5, 0.5], pants],
			[th, lr * 0.93 * tk, [tb, "hips"], [0.65, 0.35], pants],
			[th.lerp(kn, 0.25), lr * 0.97 * (1.0 + 0.08 * mus) * lerpf(1.0, tk, 0.7), [tb], [1.0], pants],
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
		_shoe(ft, sqrt(limb) * 1.07, shoe, lk.get("sole"), fb)       # 조금 크게(굵은 구두 · 장화 — Hades 발)
	_clothes_ink(lk, prof, hem, bz, thigh_out, limb, wide)
	paint_k = 0.0


## 3본 스키닝 연속 로프트 스커트 — 하단 링이 좌우 허벅지(th_r · th_l)와 가중치를 나눠 가져 다리가 스커트를 뚫지 않는다
func _skirt_loft(hips: Vector3, rw: float, depth: float, sl: float, col: Color) -> void:
	var seg := 18
	var rings := 6
	var y_top := 0.04
	var y_bot := -0.06 - 0.42 * sl
	var rows: Array = []
	for i in rings + 1:
		var t := float(i) / rings
		var y := lerpf(y_top, y_bot, t)
		# 골반에서 자연스럽게 퍼지는 라인(달릴 때도 허벅지 관통 방지)
		var rx := (0.178 + 0.036 * sin(t * PI * 0.65) + 0.034 * t) * rw
		var rz := (0.152 + 0.030 * sin(t * PI * 0.65) + 0.040 * t) * depth
		var row: Array = []
		for j in seg:
			var a := TAU * j / seg
			var x := cos(a) * rx
			var z := sin(a) * rz
			var b: Array = ["hips"]
			var w: Array = [1.0]
			var leg_k := smoothstep(0.10, 0.78, t) * 0.88
			if leg_k > 0.01:
				var sx := x / maxf(rx, 0.001)
				var side_w := clampf(absf(sx) * 1.4, 0.0, 1.0)
				if side_w > 0.15:
					var leg_b := "th_r" if x > 0.0 else "th_l"
					var kw := side_w * leg_k
					b = ["hips", leg_b]
					w = [1.0 - kw, kw]
				else:
					# 앞뒤 중앙도 양쪽 허벅지와 반반 섞어 다리 벌림 시 자연스럽게 따라감
					var kw := leg_k * 0.55
					b = ["hips", "th_r", "th_l"]
					w = [1.0 - kw, kw * 0.5, kw * 0.5]
			row.append([hips + Vector3(x, y, z), b, w])
		rows.append(row)
	var cell := _new_cell(_grid_pos(rows), col, true)
	for i in rings:
		for j in seg:
			var j2 := (j + 1) % seg
			_quad(_e(rows[i][j], cell, _cuv(cell, i, j)), _e(rows[i][j2], cell, _cuv(cell, i, j + 1)),
				_e(rows[i + 1][j2], cell, _cuv(cell, i + 1, j + 1)), _e(rows[i + 1][j], cell, _cuv(cell, i + 1, j)), [col], [])


## 어깨에 걸친 모피 코트 v2(리사 프롤로그): 17개 블롭 겹침 대신 매끈한 연속 망토 로프트(앞이 열린 U자 곡면) +
## 목을 감싸는 부드러운 모피 깃 링 + 앞 자락 모피 띠. 위는 chest, 아래는 hips 가중치로 자연스럽게 흐른다.
func _drape(lk: Dictionary, g: Dictionary, shw: float, depth: float) -> void:
	var dc: Color = lk["drape"]
	var fur: Color = lk.get("fur", dc.lightened(0.3))
	var ch: Vector3 = g["chest"]
	var seg := 16
	var ys := [0.22, 0.14, 0.02, -0.14, -0.34, -0.56, -0.78, -0.96]  # chest.y 기준(어깨 위 ~ 무릎 아래)
	var rows: Array = []
	for i in ys.size():
		var t := float(i) / float(ys.size() - 1)
		var y := ch.y + float(ys[i])
		var rx := lerpf(0.24, 0.35, smoothstep(0.0, 0.25, t)) * shw * (1.0 + 0.16 * t)
		var rz := lerpf(0.17, 0.26, smoothstep(0.0, 0.3, t)) * depth * (1.0 + 0.22 * t)
		var b: Array
		var w: Array
		if t < 0.35:
			b = ["chest"]
			w = [1.0]
		elif t < 0.6:
			var k := (t - 0.35) / 0.25
			b = ["chest", "hips"]
			w = [1.0 - k, k]
		else:
			b = ["hips"]
			w = [1.0]
		var row: Array = []
		# 앞(-z) 중앙이 열린 U자 호(오른 앞 -52° → 등 +90° → 왼 앞 +232°)
		for j in seg + 1:
			var u := float(j) / float(seg)
			var ang := lerpf(-0.28 * PI, 1.28 * PI, u)
			var p := Vector3(cos(ang) * rx, y, sin(ang) * rz + 0.03)
			row.append([p, b, w])
		rows.append(row)
	var cell := _new_cell(_grid_pos(rows), dc, false)
	var inner_c := dc.darkened(0.28)
	for i in rows.size() - 1:
		for j in seg:
			var q0: Array = rows[i][j]
			var q1: Array = rows[i + 1][j]
			var q2: Array = rows[i + 1][j + 1]
			var q3: Array = rows[i][j + 1]
			# 바깥면(시계 방향 = 바깥 법선)
			_quad(_e(q0, cell, _cuv(cell, i, j)), _e(q3, cell, _cuv(cell, i, j + 1)),
				_e(q2, cell, _cuv(cell, i + 1, j + 1)), _e(q1, cell, _cuv(cell, i + 1, j)), [dc], [])
			# 안감(안쪽으로 살짝 수축 + 안쪽 법선)
			var in_pt := func(q: Array) -> Array:
				var p: Vector3 = q[0]
				return [Vector3(p.x * 0.94, p.y, (p.z - 0.03) * 0.94 + 0.03), q[1], q[2]]
			_quad(in_pt.call(q0), in_pt.call(q1), in_pt.call(q2), in_pt.call(q3), [inner_c], [])
	# 목을 감싸는 부드러운 모피 깃 링(부드러운 연속 토러스 로프트)
	var col_seg := 18
	var col_r := 0.052
	var col_rows: Array = []
	for j in col_seg + 1:
		var a := TAU * float(j) / float(col_seg)
		var cen := ch + Vector3(cos(a) * 0.145 * shw, 0.245 + 0.015 * sin(a), sin(a) * 0.12 * depth + 0.015)
		var out_d := Vector3(cos(a), 0.15, sin(a)).normalized()
		var up_d := Vector3.UP
		var ring: Array = []
		for k in 8:
			var b_ang := TAU * float(k) / 8.0
			var pt := cen + (out_d * cos(b_ang) + up_d * sin(b_ang)) * col_r
			ring.append([pt, ["chest"], [1.0]])
		col_rows.append(ring)
	var fur_cell := _new_cell(_grid_pos(col_rows), fur, true)
	for j in col_seg:
		for k in 8:
			var k2 := (k + 1) % 8
			_quad(_e(col_rows[j][k], fur_cell, _cuv(fur_cell, j, k)), _e(col_rows[j][k2], fur_cell, _cuv(fur_cell, j, k2)),
				_e(col_rows[j + 1][k2], fur_cell, _cuv(fur_cell, j + 1, k2)), _e(col_rows[j + 1][k], fur_cell, _cuv(fur_cell, j + 1, k)), [fur], [])
	# 앞 열린 양쪽 자락을 따라 내려오는 매끈한 모피 띠
	for edge_j in [0, seg]:
		var pts: Array = []
		for i in rows.size():
			var p: Vector3 = rows[i][edge_j][0]
			pts.append([p, 0.036, rows[i][edge_j][1], rows[i][edge_j][2], fur])
		_limb(pts, 0.02, 0.02, 10)
	# 밑단 모피 띠(뒤~양옆)
	var hem_pts: Array = []
	for j in range(0, seg + 1, 2):
		var p: Vector3 = rows[rows.size() - 1][j][0]
		hem_pts.append([p, 0.034, ["hips"], [1.0], fur])
	if hem_pts.size() >= 2:
		_limb(hem_pts, 0.015, 0.015, 8)


## 찢긴 옷(의뢰인 — 2026-11-12 사용자 "의뢰를 부탁하는 여자는 옷이 찢어져있고"): 겉감 위로 살빛이 비치는 들쭉날쭉한 구멍
## (어깨 · 쇄골 · 옆구리 · 배) + 얼룩. 작은 조각 셋을 겹쳐 가장자리를 들쭉날쭉하게
func _torn(lk: Dictionary, g: Dictionary, wide: float, bz: float, skin: Color, top: Color) -> void:
	var holes := [[Vector3(-0.11 * wide, 0.19, -bz * 0.72), 0.042], [Vector3(0.085 * wide, -0.05, -bz * 0.94), 0.03],
		[Vector3(-0.05 * wide, -0.14, -bz * 0.9), 0.026], [Vector3(0.15 * wide, 0.06, -bz * 0.6), 0.028]]
	for h in holes:
		var c: Vector3 = g["chest"] + (h[0] as Vector3)
		var r: float = h[1]
		_sq_blob(c, Vector3(r, r * 0.8, 0.03), 2.0, top.darkened(0.45), "chest", 10, 4)                     # 찢긴 가장자리(그늘)
		for k in 3:
			var o := Vector3(r * 0.35 * cos(k * 2.1), r * 0.3 * sin(k * 2.1), -0.003)
			_sq_blob(c + o, Vector3(r * 0.62, r * 0.5, 0.031), 2.0, skin, "chest", 10, 4)
	for k in 3:                                                     # 흙 · 얼룩
		var c2: Vector3 = g["chest"] + Vector3(0.1 * wide * (k - 1), -0.2 + 0.1 * k, -bz * 0.92)
		_sq_blob(c2, Vector3(0.03, 0.022, 0.03), 2.0, top.darkened(0.3), "chest", 8, 4)


## 통합 머리 메시(v2): 앞 반구(u ∈ [PI, TAU], -Z 쪽)를 좌상단 2D 얼굴 아틀라스([0..0.25]²)에 심 없이 직접 매핑!
## 뒤 반구(u ∈ [0, PI])는 단색 살빛/복면 스와치로 보내 표정 오프셋과 무관하게 유지한다.
func _head_mesh(c: Vector3, r: Vector3, col: Color, fem: bool, is_mask: bool) -> void:
	var seg := 24
	var rings := 14
	var half := seg / 2
	var grid: Array = []
	for i in rings + 1:
		var v := PI * float(i) / float(rings)
		var row: Array = []
		for j in seg + 1:
			var u := TAU * float(j) / float(seg)
			var n := Vector3(sin(v) * cos(u), cos(v), sin(v) * sin(u))
			var pt: Vector3
			if fem:
				var low := maxf(0.0, -n.y)
				pt = c + Vector3(n.x * r.x * (1.0 - 0.30 * pow(low, 1.6)), n.y * r.y * (1.0 + 0.06 * low), n.z * r.z * (1.0 - 0.08 * low * low))
			elif not is_mask:
				pt = _hw(c, r, c + Vector3(n.x * r.x, n.y * r.y, n.z * r.z))
			else:
				pt = c + Vector3(n.x * r.x, n.y * r.y, n.z * r.z)
			# 앞 반구(j in half..seg): az = -PI/2(-X) .. 0(-Z) .. +PI/2(+X)
			var fx := (float(j - half) / float(half)) * 2.0 - 1.0
			var fy := (float(i) / float(rings)) * 2.0 - 1.0
			var fuv := Vector2(
				lerpf(2.0, float(FacePainter.QUAD - 2), fx * 0.5 + 0.5) / float(PAINT_TEX),
				lerpf(2.0, float(FacePainter.QUAD - 2), fy * 0.5 + 0.5) / float(PAINT_TEX)
			)
			row.append([pt, ["head"], [1.0], fuv])
		grid.append(row)
	for i in rings:
		for j in seg:
			var front := j >= half
			var a: Array = grid[i][j]
			var b: Array = grid[i][j + 1]
			var d: Array = grid[i + 1][j]
			var e: Array = grid[i + 1][j + 1]
			if front:
				for vert in [a, e, b, a, d, e]:
					_vert_uv(vert[0], col, vert[1], vert[2], -1, vert[3])
			else:
				for vert in [a, e, b, a, d, e]:
					_vert_uv(vert[0], col, vert[1], vert[2], 0, Vector2.ZERO)


## 3D 얼굴 부속(귀걸이 · 입마개 · 피어싱 · 정수리 흉터만 — 눈/눈썹/코/입/볼/흉터/수염/안대는 2D 아틀라스가 담당)
func _face_3d_extras(lk: Dictionary, hc: Vector3, hk: float) -> void:
	var fem: bool = lk.get("female", false)
	var R := (FEM_HEAD if fem else MALE_HEAD) * hk
	if fem and lk.get("piercing", false):
		cur_hint = "metal"
		for sx in [-1.0, 1.0]:
			var ear := _on_ell(hc, R, Vector3(sx, -0.32, 0.05))
			_line(ear + Vector3(0, -0.004, 0) * hk, ear + Vector3(0.004 * sx, -0.032, -0.004) * hk, 0.0038 * hk, Color(0.88, 0.70, 0.30), "head")
		cur_hint = ""
	if lk.get("face_ring") != null:
		cur_hint = "metal"
		_blob(hc + Vector3(0.016, -0.068, -0.118) * hk, Vector3(0.007, 0.007, 0.006) * hk, lk["face_ring"], "head")
		cur_hint = ""
	if lk.get("mouth_mask") != null:
		_blob(hc + Vector3(0, -0.07, -0.05) * hk, Vector3(0.112, 0.06, 0.08) * hk, lk["mouth_mask"], "head")
	var sc = lk.get("scar", false)
	if sc is String and str(sc).contains("head"):
		_line(_on_head(hc, hk, Vector3(0.01, 0.13, -0.03)), _on_head(hc, hk, Vector3(0.07, 0.08, 0.06)), 0.0042 * hk, Looks.scar_col(lk), "head")


## 2차 페이즈 풀린 앞머리(백도찬 · 윤덕수): 별도 HairLoose 서브메시로 내보내 puppet_glb.remove_glasses() 시 표시
func _hair_loose_submesh(lk: Dictionary, hc: Vector3, hk: float, hair: Color) -> void:
	var gl = lk.get("glasses", false)
	var need: bool = bool(lk.get("loose", false)) or (gl is bool and gl)
	if not need:
		return
	_cur_vbuf_mode = "loose"
	cur_hint = "hair"
	for k in 5:
		var x := -0.055 + 0.028 * k
		var drop := 0.065 + 0.02 * (k % 2)
		var b: Vector3 = hc + Vector3(x, 0.095, -0.112) * hk
		_cone(b, b + Vector3(0.008 * (k - 2), -drop, -0.018) * hk, 0.014 * hk, hair, "head")
	_cur_vbuf_mode = "body"


## 얼굴 겉면에 붙인 조각(머리 단위): 머리 타원체 R 위 dir 쪽에 겉면을 따라 휜 얇은 한 겹 판(안경 · 앞머리 가닥용)
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


## 머리 겉면 점 q 를 지금 머리 다듬기(head_warp)로 옮긴다 — 0 이면 그대로(여성 · 복면)
func _hw(c: Vector3, r: Vector3, q: Vector3) -> Vector3:
	if head_warp == Vector3.ZERO:
		return q
	var d := q - c
	var low := maxf(0.0, -d.y / r.y)
	return c + Vector3(d.x * (1.0 - head_warp.x * pow(low, head_warp.y)), d.y * (1.0 + MALE_CHIN * low), d.z * (1.0 - head_warp.z * low * low))


## 얼굴 겉면의 가는 선(머리 단위 방향 a → b): 안경 코다리 · 다리
func _stroke(hc: Vector3, R: Vector3, a: Vector3, b: Vector3, w: float, lift: float, col: Color, hk: float) -> void:
	var pa := _on_ell(hc, R, a)
	var pb := _on_ell(hc, R, b)
	var m := (pa + pb) * 0.5
	var n := _ell_normal(hc, R, _on_ell(hc, R, m - hc))
	var tx := n.cross(Vector3.UP).normalized()
	var ty := tx.cross(n)
	var d := pb - pa
	_patch(hc, R, m - hc, d.length() * 0.5 / hk + w * 0.5, w, lift, rad_to_deg(atan2(d.dot(ty), d.dot(tx))), col, hk)


## 머리(타원체 0.12 · 0.13 · 0.12 × hk) 중심에서 dir 쪽 겉면 바로 바깥 점
func _on_head(hc: Vector3, hk: float, dir: Vector3) -> Vector3:
	var q := Vector3(dir.x / 0.12, dir.y / 0.13, dir.z / 0.12)
	return hc + dir / q.length() * hk * 1.015


## 얼굴 소품: 안경(별도 Glasses 서브메시 — 백도찬 2차 remove_glasses 복구!) · 모자 · 붕대 · 시가
func _props(lk: Dictionary, hc: Vector3, hk: float) -> void:
	var R := (FEM_HEAD if lk.get("female", false) else MALE_HEAD) * hk
	var gl = lk.get("glasses", false)
	if (gl is String) or (gl is bool and gl):
		_cur_vbuf_mode = "glasses"
		if gl is String:
			var lens: Color = lk.get("lens", Color(0.06, 0.06, 0.08))
			var kind := str(gl)
			var frame: Color = lk.get("frame", Color(0.84, 0.66, 0.26) if kind == "aviator" else Color(0.06, 0.06, 0.08))
			if kind == "goggles":
				_patch(hc, R, Vector3(0, 0.012, -0.12), 0.098, 0.03, 0.007, 0.0, frame, hk, 4.0)
				_patch(hc, R, Vector3(0, 0.012, -0.12), 0.09, 0.022, 0.008, 0.0, lens, hk, 4.0)
			else:
				var av := kind == "aviator"
				for sx in [-1.0, 1.0]:
					var lc := Vector3(0.045 * sx, 0.004 if av else 0.008, -0.11)
					_patch(hc, R, lc, 0.03, 0.024 if av else 0.0185, 0.007, -6.0 * sx if av else 0.0, frame, hk, 2.4 if av else 5.0)
					_patch(hc, R, lc + Vector3(0, -0.0005, 0), 0.0255, 0.0195 if av else 0.0135, 0.008, -6.0 * sx if av else 0.0, lens, hk, 2.4 if av else 5.0)
			_glass_arms(hc, R, hk, frame if kind != "goggles" else Color(0.06, 0.06, 0.08), 0.013)
		else:
			var fc: Color = lk.get("frame", Color(0.78, 0.80, 0.84))
			for sx in [-1.0, 1.0]:
				var lc := Vector3(0.045 * sx, 0.009, -0.11)
				_patch(hc, R, lc, 0.0275, 0.0175, 0.0065, 0.0, fc.darkened(0.32), hk, 4.0)
				_patch(hc, R, lc, 0.0245, 0.0145, 0.0074, 0.0, Color(0.92, 0.95, 0.98), hk, 4.0)
			_glass_arms(hc, R, hk, fc.darkened(0.32), 0.012)
		_cur_vbuf_mode = "body"
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
	if style == "bun" or (lk.get("female", false) and style in ["ponytail", "long", "bob", "wavy"]):
		_hair_fem(lk, hc, hk, hair, style)
	elif style == "spiky":
		_blob(hc + Vector3(0, 0.05, 0.015) * hk, Vector3(0.125, 0.092, 0.126) * hk, hair, "head")
		_blob(hc + Vector3(0, -0.01, 0.048) * hk, Vector3(0.122, 0.096, 0.098) * hk, hair, "head")
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
			for k in 4:
				var x := -0.042 + 0.028 * k
				var drop := 0.048 + 0.012 * (k % 2)
				var b: Vector3 = hc + Vector3(x, 0.098, -0.106) * hk
				_cone(b, b + Vector3(0.008 * (k - 1.5), -drop, -0.012) * hk, 0.016 * hk, hair, "head")
		elif style == "fringe":
			for k in 7:                                             # 이마를 덮고 눈썹까지 내려오는 가닥(촘촘히 — 모자처럼 안 보이게)
				var x := -0.084 + 0.028 * k
				_cone(_on_head(hc, hk, Vector3(x * 0.9, 0.12, -0.06)), _on_head(hc, hk, Vector3(x * 1.05 + 0.006, 0.03, -0.12)),
					0.026 * hk, hair, "head")
	sheen_hair = null


## 여성 머리 v2: 둥근 정수리~뒷머리 연속 로프트 껍질(이음매/납작 정수리 제거) + 자연스러운 앞머리 · 물결 · 쪽머리
func _hair_fem(lk: Dictionary, hc: Vector3, hk: float, hair: Color, style: String) -> void:
	var hr := FEM_HEAD * hk if lk.get("female", false) else Vector3(0.12, 0.13, 0.12) * hk
	var ln := 1.65 if lk.get("hair_long", false) else 1.0
	if style == "bob":
		# 둥근 정수리 → 턱선 보브컷(정수리 돔 + 아래 열림)
		var bob_rings := [
			[hc + Vector3(0, 0.136, 0.016) * hk, 0.046 * hk, 0.052 * hk, ["head"], [1.0], hair],
			[hc + Vector3(0, 0.114, 0.018) * hk, 0.098 * hk, 0.104 * hk, ["head"], [1.0], hair],
			[hc + Vector3(0, 0.062, 0.022) * hk, 0.124 * hk, 0.124 * hk, ["head"], [1.0], hair],
			[hc + Vector3(0, -0.020, 0.032) * hk, 0.126 * hk, 0.110 * hk, ["head"], [1.0], hair],
			[hc + Vector3(0, -0.100, 0.040) * hk, 0.116 * hk, 0.092 * hk, ["head"], [1.0], hair],
			[hc + Vector3(0, -0.138, 0.044) * hk, 0.094 * hk, 0.074 * hk, ["head"], [1.0], hair],
		]
		_loft(bob_rings, 2.05, 16, 0.014 * hk, -1.0)
		for sx in [-1.0, 1.0]:
			for k in 3:
				_patch(hc, hr, Vector3((0.014 + 0.022 * k) * sx, 0.084 - 0.006 * k, -0.1), 0.010, 0.026, 0.004 + 0.0005 * k,
					(-10.0 - 8.0 * k) * sx, hair, hk)
		sheen_hair = null
		return
	var loose := style == "long" or style == "wavy"
	# 정수리~뒤통수를 둥글고 매끈한 단일 로프트로(이마선까지 자연스럽게 감쌈)
	var cap_z := 0.022 if loose else 0.024
	var shell_rings := [
		[hc + Vector3(0, 0.138, cap_z * 0.65) * hk, 0.044 * hk, 0.048 * hk, ["head"], [1.0], hair],
		[hc + Vector3(0, 0.116, cap_z * 0.85) * hk, 0.096 * hk, 0.100 * hk, ["head"], [1.0], hair],
		[hc + Vector3(0, 0.062, cap_z + 0.004) * hk, 0.120 * hk, 0.118 * hk, ["head"], [1.0], hair],
		[hc + Vector3(0, -0.015, cap_z + 0.022) * hk, 0.114 * hk, 0.096 * hk, ["head"], [1.0], hair],
		[hc + Vector3(0, -0.092, cap_z + 0.036) * hk, 0.098 * hk, 0.072 * hk, ["head"], [1.0], hair],
	]
	_loft(shell_rings, 2.05, 16, 0.014 * hk, 0.012 * hk)
	if loose:
		# 매끈하게 옆으로 쓸어 넘긴 앞머리(이마에 자연스럽게 밀착)
		_blob(hc + Vector3(0.016, 0.096, -0.022) * hk, Vector3(0.088, 0.024, 0.072) * hk, hair, "head")
		_blob(hc + Vector3(-0.046, 0.082, -0.038) * hk, Vector3(0.056, 0.022, 0.058) * hk, hair, "head")
	else:
		_blob(hc + Vector3(0.008, 0.098, -0.022) * hk, Vector3(0.086, 0.024, 0.068) * hk, hair, "head")
	var strand := 1.0
	if style == "bun":
		_blob(hc + Vector3(0, -0.02, 0.155) * hk, Vector3(0.066, 0.056, 0.052) * hk, hair, "head")
		_blob(hc + Vector3(0.012, -0.012, 0.196) * hk, Vector3(0.036, 0.03, 0.022) * hk, hair, "head")
	elif style == "ponytail":
		_blob(hc + Vector3(0, 0.03, 0.14) * hk, Vector3(0.04, 0.04, 0.035) * hk, hair, "head")
		_line(hc + Vector3(0, 0.0, 0.17) * hk, hc + Vector3(0, -0.22, 0.19) * hk, 0.038 * hk, hair, "head")
		strand = 0.7
	elif style == "wavy":
		# 등 쪽 매끈한 웨이브 로프트(블롭 뭉침 제거) + 오른 어깨 앞으로 흘러내린 물결 다발
		var back_r: Array = []
		for k in 6:
			var t := float(k) / 5.0
			var wx := 0.022 * sin(t * TAU * 1.1)
			var wy := -0.02 - 0.34 * t * ln
			var wz := 0.075 + 0.035 * t + 0.012 * cos(t * TAU)
			back_r.append([hc + Vector3(wx, wy, wz) * hk, lerpf(0.112, 0.088, t) * hk, lerpf(0.065, 0.045, t) * hk, ["head"], [1.0], hair])
		_loft(back_r, 2.2, 14, 0.02 * hk, 0.015 * hk)
		var lock_r: Array = []
		for k in 5:
			var t := float(k) / 4.0
			var lx := 0.102 + 0.016 * sin(t * PI * 2.0)
			var ly := -0.06 - 0.28 * t
			var lz := 0.01 - 0.05 * t
			lock_r.append([hc + Vector3(lx, ly, lz) * hk, lerpf(0.036, 0.018, t) * hk, lerpf(0.042, 0.022, t) * hk, ["head"], [1.0], hair])
		_loft(lock_r, 2.0, 10, 0.015 * hk, 0.01 * hk)
		strand = 0.7
	else:
		# 생머리 등 로프트(정수리에서 허리/등까지 매끈하게 연결)
		var back_l: Array = []
		for k in 6:
			var t := float(k) / 5.0
			var wy := -0.02 - 0.32 * t * ln
			back_l.append([hc + Vector3(0, wy, 0.072 + 0.022 * t) * hk, lerpf(0.118, 0.098, t) * hk, lerpf(0.068, 0.044, t) * hk, ["head"], [1.0], hair])
		_loft(back_l, 2.2, 14, 0.018 * hk, 0.015 * hk)
		for sx in [-1.0, 1.0]:
			var side_l: Array = []
			for k in 4:
				var t := float(k) / 3.0
				side_l.append([hc + Vector3(0.098 * sx, -0.02 - 0.22 * t * ln, 0.02 - 0.015 * t) * hk,
					lerpf(0.028, 0.016, t) * hk, lerpf(0.052, 0.030, t) * hk, ["head"], [1.0], hair])
			_loft(side_l, 2.0, 10, 0.012 * hk, 0.01 * hk)
	if lk.get("messy", false):
		_patch(hc, hr, Vector3(0.05, 0.07, -0.095), 0.006, 0.042, 0.0075, 16.0, hair, hk)
		_patch(hc, hr, Vector3(-0.072, 0.02, -0.09), 0.005, 0.05, 0.0075, -8.0, hair, hk)
		_patch(hc, hr, Vector3(0.0, 0.092, -0.085), 0.024, 0.008, 0.0078, 28.0, hair, hk)
	for sx in [-1.0, 1.0]:
		_patch(hc, hr, Vector3(0.084 * sx, 0.04, -0.082), 0.0042, 0.036, 0.004, 12.0 * sx, hair, hk)
		_patch(hc, hr, Vector3(0.094 * sx, -0.02, -0.072), 0.0036, 0.04 * strand, 0.0045, 2.0 * sx, hair, hk)
		if strand >= 1.0:
			_patch(hc, hr, Vector3(0.086 * sx, -0.068, -0.08), 0.003, 0.03, 0.005, -14.0 * sx, hair, hk)
	sheen_hair = null


## 머리 껍질(정수리를 덮는 타원체) 반지름(머리 크기 단위, x · z) — 띠 · 모자 · 윤기 자리
func _hair_shell(style: String) -> float:
	if style == "curly" or style == "messy":
		return 0.138
	if style == "long" or style == "bob" or style == "wavy":
		return 0.13
	return 0.126


## 짙은 머리 윤기 — v2 는 ink_cel 셰이더의 실시간 엔젤링 스페큘러가 담당하므로 회색 정점 덧칠을 끈다
func _sheen_on(_lk: Dictionary, _hair: Color, _style: String) -> void:
	sheen_hair = null


## 중심 c · 반지름 r 타원체의 dir 쪽 겉면 점
func _on_ell(c: Vector3, r: Vector3, dir: Vector3) -> Vector3:
	var q := Vector3(dir.x / r.x, dir.y / r.y, dir.z / r.z)
	return c + dir / q.length()


# ---- 도형 (정점마다 뼈 · 가중치)
func _vert(p: Vector3, col: Color, b: Array, w: Array) -> void:
	_vert_uv(p, col, b, w, 0, Vector2.ZERO)


## 칸 cell 의 칸 안 uv(0 ~ 1)로 꼭짓점 하나. 칸 0 = 스와치 · 칸 -1 = 얼굴 아틀라스 직접 UV
func _vert_uv(p: Vector3, col: Color, b: Array, w: Array, cell: int, uv: Vector2) -> void:
	var bi := PackedInt32Array([0, 0, 0, 0])
	var wi := PackedFloat32Array([0, 0, 0, 0])
	for k in b.size():
		bi[k] = bones[b[k]]
		wi[k] = w[k]
	var rec := [p, col, bi, wi, cell, uv, cur_hint, paint_k]
	if _cur_vbuf_mode == "glasses":
		vbuf_glasses.append(rec)
	elif _cur_vbuf_mode == "loose":
		vbuf_loose.append(rec)
	else:
		vbuf.append(rec)


## 새 UV 칸: pos = 행(v 방향) × 열(u 방향) 겉면 점, col = 같은 모양의 바탕색(칠하기 전 — 종류 가르기) 또는 Color 하나, wrap = 열이 둘레로 닫힘
func _new_cell(pos: Array, col, wrap: bool) -> int:
	var cg: Array = []
	if col is Array:
		cg = col
	else:
		for row in pos:
			var r: Array = []
			r.resize(row.size())
			r.fill(col)
			cg.append(r)
	cells.append({"pos": pos, "col": cg, "wrap": wrap, "hint": cur_hint})
	return cells.size() - 1


## 칸 격자 (i 행, j 열)의 uv — 닫힌 둘레는 j = 열 수(이음매)에서 u = 1
func _cuv(cell: int, i: int, j: int) -> Vector2:
	var c: Dictionary = cells[cell]
	var rows: int = (c["pos"] as Array).size()
	var cols: int = (c["pos"][0] as Array).size()
	return Vector2(float(j) / float(cols if c["wrap"] else maxi(cols - 1, 1)), float(i) / float(maxi(rows - 1, 1)))


func _quad(a, b, c, d, cols: Array, _wts: Array) -> void:
	# a b c d 는 [위치, 뼈 목록, 가중치 목록]
	for v in [a, c, b, a, d, c]:             # Godot 앞면 감기 방향(뒤집으면 외곽선 판만 보인다 — 첫 시도)
		if v.size() > 4:
			_vert_uv(v[0], cols[0], v[1], v[2], v[3], v[4])
		else:
			_vert(v[0], cols[0], v[1], v[2])


## 격자 점 [위치, 뼈, 가중치] 에 칸 · uv 를 붙인 꼭짓점(_quad 가 읽는다)
func _e(entry: Array, cell: int, uv: Vector2) -> Array:
	return [entry[0], entry[1], entry[2], cell, uv]


## 격자(행 × 열 [위치, ..])의 위치만
func _grid_pos(grid: Array) -> Array:
	var out: Array = []
	for row in grid:
		var r: Array = []
		for v in row:
			r.append(v[0] if v is Array else v)
		out.append(r)
	return out


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
	var cell := _new_cell(_grid_pos(rows), col, true)
	for i in rings:
		for j in seg:
			var j2 := (j + 1) % seg
			_quad(_e(rows[i][j], cell, _cuv(cell, i, j)), _e(rows[i + 1][j], cell, _cuv(cell, i + 1, j)),
				_e(rows[i + 1][j2], cell, _cuv(cell, i + 1, j + 1)), _e(rows[i][j2], cell, _cuv(cell, i, j + 1)), [col], [])
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
	var cg: Array = []
	for row in grid:
		cg.append(row.map(func(e): return e[3]))
	var cell := _new_cell(_grid_pos(grid), cg, true)
	for i in rings:
		for j in seg:
			var j2 := (j + 1) % seg
			var q: Array = [grid[i][j], grid[i][j2], grid[i + 1][j2], grid[i + 1][j]]
			var qu: Array = [_cuv(cell, i, j), _cuv(cell, i, j + 1), _cuv(cell, i + 1, j + 1), _cuv(cell, i + 1, j)]
			for k in [0, 2, 1, 0, 3, 2]:
				_vert_uv(q[k][0], q[k][3], q[k][1], q[k][2], cell, qu[k])


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
	var sw := maxf(0.232 * wide, 0.222 * sh_wide) * chest_k        # 어깨 — 조금 넓게(2026-11-11 Hades 실루엣)
	return [
		[-0.14, 0.11 * wide * hip_k, hz * 0.7],
		[-0.09, 0.152 * wide * hip_k, hz * 0.93],
		[-0.02, 0.16 * wide * hip_k, hz],
		[0.1, 0.158 * wide * waist_k, hz * 0.94],
		[0.22, 0.186 * wide * lerpf(waist_k, chest_k, 0.5), bz * 0.97],
		[0.33, 0.215 * wide * chest_k, bz],
		[0.42, sw, bz * 0.98],
		[0.47, sw * 0.93, bz * 0.88],
		[0.505, 0.175 * wide, bz * 0.72],                           # 승모근 비탈(목 → 어깨가 불룩하게 — 공 어깨를 없앤 자리)
		[0.53, 0.112 * wide, bz * 0.52],
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
	var cg: Array = []
	for row in rows:
		cg.append(row.map(func(e): return e[3]))
	var cell := _new_cell(_grid_pos(rows), cg, true)
	for i in rows.size() - 1:
		for j in seg:
			var j2 := (j + 1) % seg
			var q: Array = [rows[i][j], rows[i + 1][j], rows[i + 1][j2], rows[i][j2]]
			var qu: Array = [_cuv(cell, i, j), _cuv(cell, i + 1, j), _cuv(cell, i + 1, j + 1), _cuv(cell, i, j + 1)]
			for k in [0, 2, 1, 0, 3, 2]:
				_vert_uv(q[k][0], q[k][3], q[k][1], q[k][2], cell, qu[k])
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
		var tri: Array = [[a, m1, b], [a, m0, m1], [m0, cv, m1]] if flip else [[a, b, m1], [a, m1, m0], [m0, m1, cv]]
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
	var cell := _new_cell(grid, col, true)
	for i in rings:
		for j in seg:
			var j2 := (j + 1) % seg
			var q: Array = [[grid[i][j], i, j], [grid[i + 1][j2], i + 1, j + 1], [grid[i][j2], i, j + 1], [grid[i][j], i, j],
				[grid[i + 1][j], i + 1, j], [grid[i + 1][j2], i + 1, j + 1]]
			for t in q:
				_vert_uv(t[0], col, [bone], [1.0], cell, _cuv(cell, t[1], t[2]))


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
	var cell := _new_cell(_grid_pos(grid), col, true)
	for i in rings:
		for j in seg:
			var j2 := (j + 1) % seg
			_quad(_e(grid[i][j], cell, _cuv(cell, i, j)), _e(grid[i][j2], cell, _cuv(cell, i, j + 1)),
				_e(grid[i + 1][j2], cell, _cuv(cell, i + 1, j + 1)), _e(grid[i + 1][j], cell, _cuv(cell, i + 1, j)), [col], [])


# ---- 안쪽 먹선(② — 2026-11-11 화풍 2단계)
## 겉면에 붙인 납작한 붓 자국 띠. pts = [[위치, 바깥 법선(, 뼈 목록, 가중치)] ..] — 너비는 가운데 w, 양 끝으로 가늘게(붓을 대고 뗀 자국).
## 한 겹 앞면뿐(게임 먹선 껍질 ink_line 은 뒷면만 그려 이 띠에 테를 두르지 않는다). 감기: 바깥에서 보아 시계 방향(Godot 앞면 — _tube 와 같다)
func _ink_strip(pts: Array, w: float, bones_def: Array, wts_def: Array, col := INK_COL) -> void:
	var n := pts.size()
	if n < 2:
		return
	var rows: Array = []
	for i in n:
		var p: Vector3 = pts[i][0]
		var nr: Vector3 = (pts[i][1] as Vector3).normalized()
		var t: Vector3 = (pts[mini(i + 1, n - 1)][0] - pts[maxi(i - 1, 0)][0]).normalized()
		var b := nr.cross(t).normalized()
		var u := float(i) / (n - 1)
		var ww := w * (0.3 + 0.7 * sin(PI * u))
		var bo: Array = pts[i][2] if pts[i].size() > 2 else bones_def
		var wo: Array = pts[i][3] if pts[i].size() > 3 else wts_def
		var c := p + nr * INK_LIFT
		rows.append([c + b * ww * 0.5, c - b * ww * 0.5, bo, wo])
	for i in n - 1:
		var a: Array = rows[i]
		var d: Array = rows[i + 1]
		for v in [[a[0], a], [d[0], d], [d[1], d], [a[0], a], [d[1], d], [a[1], a]]:
			_vert(v[0], col, v[1][2], v[1][3])


## 세운 관(쉬는 자세의 팔 · 다리 — 축이 위아래) 둘레의 호: 각도는 앞(-z) 0 · 바깥(+x) 90도. y 를 따라 기울일 수 있다(dy — 호 끝에서 이만큼 아래)
func _ink_arc(c: Vector3, r: float, a0: float, a1: float, bones: Array, wts: Array, w := INK_W, dy := 0.0) -> void:
	var pts: Array = []
	var n := maxi(4, int(absf(a1 - a0) / 15.0) + 2)
	for i in n:
		var u := float(i) / (n - 1)
		var a := deg_to_rad(lerpf(a0, a1, u))
		var dir := Vector3(sin(a), 0, -cos(a))
		pts.append([c + dir * r + Vector3(0, -dy * u, 0), dir])
	_ink_strip(pts, w, bones, wts)


## 겉옷 몸통 관의 단면 반지름(옆 a, 앞뒤 b) — _torso_loft 와 같은 식(grow · 밑단 벌림 min_a · min_b · 밑단 높이 y0)
func _coat_ab(prof: Array, y: float, grow: float, min_a: float, min_b: float, y0: float) -> Vector2:
	var s := _prof_at(prof, y) + Vector2(grow, grow)
	if min_a > 0.0:
		var k := clampf((y - y0) / 0.16, 0.0, 1.0)
		s.x = maxf(s.x, lerpf(min_a, s.x, k))
		s.y = maxf(s.y, lerpf(min_b, s.y, k))
	return s


## 몸통 겉면 점(골반 뼈 기준 높이 y · 옆 x · 앞 / 뒤) + 바깥 법선 — 몸통 관(_loft sq 2.5)의 초타원 |x/a|^2.5 + |z/b|^2.5 = 1
func _torso_pt(ab: Vector2, y: float, x: float, front: bool) -> Array:
	var xr := clampf(absf(x) / ab.x, 0.0, 0.97)
	var zr := pow(1.0 - pow(xr, 2.5), 0.4)
	var z := (-1.0 if front else 1.0) * zr * ab.y
	var nrm := Vector3(signf(x) * pow(xr, 1.5) / ab.x, 0.0, signf(z) * pow(zr, 1.5) / ab.y).normalized()
	var bw := _torso_bw(y)
	return [gpos["hips"] + Vector3(x, y, z), nrm, bw[0], bw[1]]


## 몸통 높이 y 의 뼈 · 가중치(_torso_loft 와 같은 나눔)
func _torso_bw(y: float) -> Array:
	if y <= 0.0:
		return [["hips"], [1.0]]
	if y < 0.12:
		return [["hips", "spine"], [1.0 - y / 0.12, y / 0.12]]
	if y < 0.22:
		return [["spine"], [1.0]]
	if y < 0.34:
		var t: float = (y - 0.22) / 0.12
		return [["spine", "chest"], [1.0 - t, t]]
	return [["chest"], [1.0]]


## 옷 안쪽 먹선 — 겉옷 차림마다: 정장 · 코트(앞섶 · 밑단 갈라짐 · 주머니 · 가슴 주머니 · 등 솔기 · 바지 주름선), 셔츠(단추 줄 · 가슴 주머니),
## 캐주얼 겉옷(비스듬한 주머니), 조끼(앞섶). 소매 끝 · 팔꿈치 안 · 무릎 뒤 · 사타구니 주름은 차림과 상관없이(맨살은 빼고)
func _clothes_ink(lk: Dictionary, prof: Array, hem: float, bz: float, thigh_out: float, limb: float, wide: float) -> void:
	var outfit := str(lk.get("outfit", "suit"))
	var shirt_only := outfit == "shirt"
	var vest := outfit == "vest"
	var jacket := outfit == "jacket"
	var robe := outfit == "robe"
	var tailored := not (shirt_only or vest or jacket or robe)
	var g := gpos
	var fa := thigh_out + 0.012
	var fb := 0.122
	var at := func(y: float, x: float, front := true) -> Array:
		return _torso_pt(_coat_ab(prof, y, 0.008, fa, fb, hem), y, x, front)
	var ab0 := _coat_ab(prof, hem + 0.06, 0.008, fa, fb, hem)
	if tailored or vest:
		# 앞섶: 넥타이 밑(V 바닥)에서 단추 자리까지 곧게 → 밑단 쪽으로 두 자락이 벌어진다
		var y_btn := 0.07
		var line: Array = []
		for y in [0.27, 0.2, 0.13, y_btn]:
			line.append(at.call(y, 0.008))
		if vest:                                                      # 조끼 · 블라우스: 밑단이 짧아 곧게(갈라지면 W 자로 꺾여 보였다)
			_ink_strip(line + [at.call(hem + 0.012, 0.008)], INK_W * 0.85, [], [])
		else:
			_ink_strip(line + [at.call(0.03, 0.022), at.call(-0.02, 0.046), at.call(hem + 0.014, 0.07)], INK_W, [], [])
			_ink_strip([at.call(y_btn, 0.008), at.call(0.03, -0.008), at.call(-0.02, -0.034), at.call(hem + 0.014, -0.06)], INK_W * 0.9, [], [])
	if tailored:
		for sx in [-1.0, 1.0]:                                        # 허리 주머니(뚜껑 윗선)
			var x0: float = 0.07 * sx
			var x1: float = minf(0.15 * wide, ab0.x * 0.78) * sx
			_ink_strip([at.call(0.005, x0), at.call(0.0, (x0 + x1) * 0.5), at.call(-0.006, x1)], INK_W * 0.85, [], [])
		_ink_strip([at.call(0.37, -0.07), at.call(0.366, -0.1), at.call(0.362, -0.13 * wide)], INK_W * 0.75, [], [])   # 가슴 주머니
		var back: Array = []                                          # 등 가운데 솔기 + 밑단 트임
		for y in [0.49, 0.4, 0.3, 0.2, 0.1, 0.0, hem + 0.012]:
			back.append(at.call(y, 0.0, false))
		_ink_strip(back, INK_W * 0.85, [], [])
	elif shirt_only:
		var placket: Array = []                                       # 단추 줄
		for y in [0.4, 0.3, 0.2, 0.12, 0.05]:
			placket.append(at.call(y, 0.004))
		_ink_strip(placket, INK_W * 0.8, [], [])
		_ink_strip([at.call(0.37, -0.06), at.call(0.367, -0.09), at.call(0.364, -0.12 * wide)], INK_W * 0.7, [], [])
	elif jacket:
		for sx in [-1.0, 1.0]:                                        # 비스듬한 옆 주머니
			_ink_strip([at.call(0.14, 0.085 * sx), at.call(0.09, 0.11 * sx), at.call(0.04, 0.13 * sx * wide)], INK_W * 0.85, [], [])
	# 팔 · 다리
	var sleeveless: bool = lk.get("sleeveless", false)
	var bare := bool(lk.get("skirt", false)) or bool(lk.get("shorts", false))
	var long_coat := outfit == "coat" or robe
	for side in ["r", "l"]:
		var sx: float = 1.0 if side == "r" else -1.0
		var el: Vector3 = g["el_" + side]
		var ha: Vector3 = g["hand_" + side]
		var sb: String = "sh_" + side
		var eb: String = "el_" + side
		if not sleeveless:
			var cuffed := tailored and not Color(lk["shirt"]).is_equal_approx(Color(lk["suit"]))
			if cuffed:                                                 # 겉옷 소맷부리(흰 셔츠 소맷부리 위 끝)
				_ink_arc(ha + Vector3.UP * 0.04, 0.05 * limb, -180.0, 180.0, [eb], [1.0], INK_W * 0.8)
			elif not (shirt_only and not lk.get("long_sleeve", false)):
				_ink_arc(ha + Vector3.UP * 0.012, 0.044 * limb, -180.0, 180.0, [eb, "hand_" + side], [0.6, 0.4], INK_W * 0.8)
			# 팔꿈치 안 주름 두 줄(앞 — 굽히면 접히는 쪽)
			_ink_arc(el + Vector3.UP * 0.006, 0.056 * limb, -52.0, 52.0, [sb, eb], [0.5, 0.5], INK_W * 0.85)
			_ink_arc(el - Vector3.UP * 0.03, 0.056 * limb, -34.0, 30.0, [eb, sb], [0.8, 0.2], INK_W * 0.7)
		var th: Vector3 = g["th_" + side]
		var kn: Vector3 = g["kn_" + side]
		var ft: Vector3 = g["ft_" + side]
		var tb: String = "th_" + side
		var kb: String = "kn_" + side
		if long_coat or lk.get("skirt", false):
			continue
		var lr := 0.095 * limb * wide * (FEM_THIGH if lk.get("female", false) else 1.0)
		# 사타구니에서 허벅지 앞으로 비스듬히 내려가는 주름(안쪽 → 앞)
		_ink_arc(th + Vector3(0, -0.02, 0), lr * 0.95, -62.0 * sx, -14.0 * sx, [tb], [1.0], INK_W * 0.85, 0.1)
		if not bare:
			_ink_arc(kn + Vector3.UP * 0.005, 0.07 * limb, 135.0, 225.0, [tb, kb], [0.5, 0.5], INK_W * 0.85)    # 무릎 뒤 주름
			_ink_arc(kn - Vector3.UP * 0.045, 0.07 * limb, 150.0, 210.0, [kb, tb], [0.8, 0.2], INK_W * 0.7)
			if tailored:                                               # 정장 바지 앞 주름선(정강이 — 가늘게)
				var cr: Array = []
				for k in 5:
					var u := float(k) / 4.0
					var p := kn.lerp(ft, lerpf(0.12, 0.8, u))
					var r := lerpf(0.069, 0.062, u) * limb
					cr.append([p + Vector3(0, 0, -r), Vector3(0, 0, -1)])
				_ink_strip(cr, INK_W * 0.55, [kb], [1.0])


# ---- 그림 입히기(③ — UV 칸 배치 · 칠)
## 칸 크기(m): 둘레(가장 긴 행) × 길이(열마다 평균)
func _cell_dims(c: Dictionary) -> Vector2:
	var pos: Array = c["pos"]
	var w := 0.0
	for row in pos:
		var per := 0.0
		for j in row.size() - 1:
			per += (row[j + 1] as Vector3).distance_to(row[j])
		if c["wrap"] and row.size() > 1:
			per += (row[row.size() - 1] as Vector3).distance_to(row[0])
		w = maxf(w, per)
	var h := 0.0
	var cols: int = (pos[0] as Array).size()
	for j in cols:
		for i in pos.size() - 1:
			h += (pos[i + 1][j] as Vector3).distance_to(pos[i][j])
	return Vector2(w, h / maxf(cols, 1))


## 칸을 PAINT_TEX² 에 선반 쌓기로 — 밀도(텍셀/m)를 줄여 가며 다 들어갈 때까지. 돌려줌: 칸 번호 → Rect2i(0 은 민 칸)
func _pack_cells() -> Array:
	var dims: Array = [Vector2.ZERO]
	for k in range(1, cells.size()):
		dims.append(_cell_dims(cells[k]))
		cells[k]["dims"] = dims[k]
	var dens := 420.0
	while dens > 20.0:
		var rects := _shelf(dims, dens)
		if not rects.is_empty():
			return rects
		dens *= 0.92
	push_error("UV 칸이 들어가지 않는다")
	return []


func _shelf(dims: Array, dens: float) -> Array:
	var sizes: Array = [Vector2i(FACE_BOX, FACE_BOX)]
	for k in range(1, dims.size()):
		var d: Vector2 = dims[k]
		sizes.append(Vector2i(mini(PAINT_TEX, maxi(4, ceili(d.x * dens)) + 2 * CELL_PAD), mini(PAINT_TEX - FACE_BOX, maxi(4, ceili(d.y * dens)) + 2 * CELL_PAD)))
	var order := range(1, sizes.size())
	order.sort_custom(func(a, b): return sizes[a].y > sizes[b].y)
	var rects: Array = []
	rects.resize(sizes.size())
	rects[0] = Rect2i(0, 0, FACE_BOX, FACE_BOX)
	# (0..256, 0..256) = 얼굴 4표정 아틀라스 · (256..512, 0..16) = 단색 스와치 64칸
	# 선반은 (256, 16) 부터 시작, y < 256 동안은 x ∈ [256..512], y >= 256 부터는 x ∈ [0..512]
	var x := FACE_BOX
	var y := SWATCH_H
	var shelf_h := 0
	for k in order:
		var sz: Vector2i = sizes[k]
		if y < FACE_BOX and x + sz.x > PAINT_TEX:
			y += shelf_h
			shelf_h = 0
			x = FACE_BOX if y < FACE_BOX else 0
		if y < FACE_BOX and y + sz.y > FACE_BOX:
			y = FACE_BOX
			x = 0
			shelf_h = 0
		if y >= FACE_BOX and x + sz.x > PAINT_TEX:
			y += shelf_h
			x = 0
			shelf_h = 0
		if x + sz.x > PAINT_TEX or y + sz.y > PAINT_TEX:
			return []
		rects[k] = Rect2i(Vector2i(x, y), sz)
		x += sz.x
		shelf_h = maxi(shelf_h, sz.y)
	return rects


func _atlas_uv(rects: Array, cell: int, uv: Vector2) -> Vector2:
	if cell == 0:
		return Vector2(float(FACE_BOX + 2) / float(PAINT_TEX), 8.0 / float(PAINT_TEX))
	var r: Rect2i = rects[cell]
	var inner := Vector2(r.size - Vector2i(2 * CELL_PAD, 2 * CELL_PAD))
	return (Vector2(r.position) + Vector2(CELL_PAD, CELL_PAD) + uv * inner) / float(PAINT_TEX)


## 칸 종류: 머리털 · 금속 · 살 · 가죽 · 천
func _kind_of(hint: String, col: Color) -> String:
	if hint != "":
		return hint
	var lk := paint_look
	if _near(col, lk["skin"]):
		return "skin"
	if _near(col, lk.get("shoe", Color(0.05, 0.05, 0.06))) or (lk.get("belt") != null and _near(col, lk["belt"])):
		return "leather"
	if lk.get("leather", false) and _near(col, lk["suit"]):
		return "leather"
	if lk.get("gloves") != null and _near(col, lk["gloves"]):
		return "leather"
	if (lk.get("chain") != null and _near(col, lk["chain"])) or (lk.get("buckle") != null and _near(col, lk["buckle"])) \
			or (lk.get("badge") != null and _near(col, lk["badge"])) or (lk.get("rings") != null and _near(col, lk["rings"])):
		return "metal"
	return "cloth"


func _near(a: Color, b) -> bool:
	if not (b is Color):
		return false
	return absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b) < 0.03


## 정수 격자 값 잡음(0 ~ 1) — px > 0 이면 x 를 그 주기로 감는다(둘레 이음매가 안 보이게)
func _h2(ix: int, iy: int) -> float:
	var h := (ix * 374761393 + iy * 668265263) & 0x7fffffff
	h = ((h ^ (h >> 13)) * 1274126177) & 0x7fffffff
	return float((h ^ (h >> 16)) & 0xffff) / 65535.0


func _vn(x: float, y: float, px := 0) -> float:
	var ix := floori(x)
	var iy := floori(y)
	var fx := x - ix
	var fy := y - iy
	fx = fx * fx * (3.0 - 2.0 * fx)
	fy = fy * fy * (3.0 - 2.0 * fy)
	var ix1 := ix + 1
	if px > 0:
		ix = posmod(ix, px)
		ix1 = posmod(ix1, px)
	return lerpf(lerpf(_h2(ix, iy), _h2(ix1, iy), fx), lerpf(_h2(ix, iy + 1), _h2(ix1, iy + 1), fx), fy)


func _crev_ao(p: Vector3) -> float:
	var k := 1.0
	for c in crev:
		var d: float = p.distance_to(c[0])
		if d < c[1]:
			var u: float = 1.0 - d / c[1]
			k *= 1.0 - float(c[2]) * u * u
	return 1.0 - k


## 512x512 RGB8 풀컬러 아틀라스(v2):
##  1) (0,0)-(256,256): FacePainter 2D 웹툰 4표정 얼굴
##  2) (256,0)-(512,16): 단색 스와치 팔레트(먹선 · 원뿔 · 귀걸이 · 뚜껑)
##  3) 나머지: 몸통 · 옷 · 머리털 풀컬러 붓칠(동적 펜 해칭은 ink_cel + 공용 ink_lut.a 가 담당해 깔끔하고 이음매가 없다)
func _paint(rects: Array) -> Image:
	var data := PackedByteArray()
	data.resize(PAINT_TEX * PAINT_TEX * 3)
	var bg_col: Color = paint_look["skin"]
	var br := clampi(roundi(bg_col.r * 255.0), 0, 255)
	var bg := clampi(roundi(bg_col.g * 255.0), 0, 255)
	var bb := clampi(roundi(bg_col.b * 255.0), 0, 255)
	for t in PAINT_TEX * PAINT_TEX:
		data[t * 3] = br
		data[t * 3 + 1] = bg
		data[t * 3 + 2] = bb
	# 1) 좌상단 256x256 2D 웹툰 4표정 얼굴
	FacePainter.paint(data, PAINT_TEX, paint_look)
	# 2) (256, 0) 4x4 × 최대 256 단색 스와치 채우기
	for si in swatch_cols.size():
		var sc: Color = swatch_cols[si]
		var sr := clampi(roundi(sc.r * 255.0), 0, 255)
		var sg := clampi(roundi(sc.g * 255.0), 0, 255)
		var sb := clampi(roundi(sc.b * 255.0), 0, 255)
		var sx0 := FACE_BOX + (si % 64) * 4
		var sy0 := (si / 64) * 4
		for py in 4:
			for px in 4:
				var at := ((sy0 + py) * PAINT_TEX + sx0 + px) * 3
				data[at] = sr
				data[at + 1] = sg
				data[at + 2] = sb
	# 3) 몸통 · 옷 · 머리털 UV 셀 풀컬러 붓칠
	for k in range(1, cells.size()):
		var c: Dictionary = cells[k]
		var r: Rect2i = rects[k]
		var pos: Array = c["pos"]
		var cg: Array = c["col"]
		var nr := pos.size()
		var nc: int = (pos[0] as Array).size()
		var wrap: bool = c["wrap"]
		var dims: Vector2 = c["dims"]
		var kinds := {}
		var iw := maxi(1, r.size.x - 2 * CELL_PAD)
		var ih := maxi(1, r.size.y - 2 * CELL_PAD)
		var pu1 := maxi(3, roundi(dims.x * 22.0))
		var pu2 := maxi(2, roundi(dims.x * 3.0))
		var pu3 := maxi(3, roundi(dims.x * 10.0))
		var ph := maxi(8, roundi(dims.x * 76.0))
		for ty in r.size.y:
			var v := clampf((ty - CELL_PAD + 0.5) / ih, 0.0, 1.0)
			var fv := v * (nr - 1)
			var i0 := mini(int(fv), nr - 2) if nr > 1 else 0
			var i1 := mini(i0 + 1, nr - 1)
			var tv := fv - i0
			for tx in r.size.x:
				var u := clampf((tx - CELL_PAD + 0.5) / iw, 0.0, 1.0)
				var fu := u * (nc if wrap else nc - 1)
				var j0 := mini(int(fu), nc - 1)
				var j1 := (j0 + 1) % nc if wrap else mini(j0 + 1, nc - 1)
				var tu := fu - j0
				var a0: Vector3 = (pos[i0][j0] as Vector3).lerp(pos[i0][j1], tu)
				var a1: Vector3 = (pos[i1][j0] as Vector3).lerp(pos[i1][j1], tu)
				var p: Vector3 = a0.lerp(a1, tv)
				var col: Color = cg[roundi(fv)][roundi(fu) % nc]
				var kind: String = kinds.get(col, "")
				if kind == "":
					kind = _kind_of(str(c["hint"]), col)
					kinds[col] = kind
				var y := v * dims.y
				var m := 1.0
				var ao := _crev_ao(p)
				match kind:
					"hair":
						# 세련된 웹툰 머리카락 결(멜론 먹선 없이 자연스러운 가닥 명암 + 끝단 짙어짐)
						var nn := _vn(u * ph, y * 2.6 + _vn(u * ph * 0.25, y * 1.1, maxi(1, ph / 4)) * 1.8, ph)
						m = 0.86 + 0.28 * nn
						if nn < 0.24:
							m *= 0.80
						if v > 0.65:
							m *= lerpf(1.0, 0.82, (v - 0.65) / 0.35)
					"skin":
						# 피부는 매끈하고 화사하게(노이즈/빗금 제거)
						m = 1.0 + (_vn(u * pu2 * 2.0, y * 8.0, pu2 * 2) - 0.5) * 0.025
						m *= 1.0 - 0.16 * ao
					"metal":
						m = 0.94 + 0.16 * _vn(u * pu1, y * 3.0, pu1)
					_:
						m += (_vn(u * pu1, y * 3.6, pu1) - 0.5) * 0.12
						m += (_vn(u * pu2, y * 2.2 + 5.3, pu2) - 0.5) * 0.10
						if kind == "leather":
							m += 0.18 * smoothstep(0.68, 0.90, _vn(u * pu3, y * 1.6 + 2.0, pu3))
						m *= 1.0 - 0.34 * ao
				var out_c := Color(clampf(col.r * m, 0.0, 0.96), clampf(col.g * m, 0.0, 0.96), clampf(col.b * m, 0.0, 0.96))
				var at := ((r.position.y + ty) * PAINT_TEX + r.position.x + tx) * 3
				data[at] = clampi(roundi(out_c.r * 255.0), 0, 255)
				data[at + 1] = clampi(roundi(out_c.g * 255.0), 0, 255)
				data[at + 2] = clampi(roundi(out_c.b * 255.0), 0, 255)
	return Image.create_from_data(PAINT_TEX, PAINT_TEX, false, Image.FORMAT_RGB8, data)
