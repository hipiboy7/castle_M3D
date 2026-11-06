extends Node3D
## 3D 관절 인형 — 뼈 길이가 고정된 노드 계층(골반 → 허리 → 가슴 → 목 → 머리, 어깨 → 팔꿈치 → 손, 엉덩이 → 무릎 → 발목)에
## 캡슐 · 원기둥 몸을 붙이고 관절 각도(src/view/poses.gd)로 자세를 잡는다. 길이는 노드 위치라 자세가 바뀌어도 그대로다
## (castle_M 2D 인형의 '팔다리 길이가 자세마다 늘었다 줄었다' 하던 문제 — castle_M history 2026-10-26).
## 상태가 바뀌면 자세를 지수 감쇠로 섞고(크로스페이드), 걷기 · 달리기는 주기 함수, 발은 땅에 붙인다(가장 낮은 발목 = 땅).
## 나중에 ArtCraft · Mixamo GLB 캐릭터로 바꿀 때는 같은 update_from(f, dt, frozen) 을 가진 그림으로 바꿔 끼운다.

const P = preload("res://src/view/poses.gd")
const Fighter = preload("res://src/combat/fighter.gd")
const FONT = preload("res://assets/fonts/Galmuri11-Bold.ttf")

const PELVIS_H := 0.97
const HIP_W := 0.095
const THIGH := 0.45
const SHIN := 0.44
const ANKLE_H := 0.055
const BRAKE_AT := 0.45            # 엇엇박: 준비 → 타격 자세의 이만큼 뻗은 데서 브레이크가 걸린다
const CHEST_UP := 0.27
const NECK_UP := 0.215
const HEAD_UP := 0.135
const SHOULDER_W := 0.2
const SHOULDER_UP := 0.165
const UPPER_ARM := 0.29
const FOREARM := 0.26
const ROLL_PIVOT := 0.45
const GRIP_FWD := Vector3(0, -0.82, -0.57)    # 바로 쥔 칼날 방향 (손 좌표: 아래팔 연장선에서 엄지 쪽으로)
const GRIP_REV := Vector3(0, 0.55, 0.83)      # 거꾸로 쥔 칼날 (새끼손가락 쪽 → 아래팔을 따라 뒤로)

var look: Dictionary
var J := {}
var mats: Array = []
var cur := {}
var guard_pose := {}
var shape_keys := {}
var phase := 0.0
var yaw := 0.0
var time := 0.0
var glasses: Node3D = null
var tele: Label3D
var weapon_r: Node3D = null
var weapon_l: Node3D = null
var victory := false
var tele_y := 2.22
var _last_state := ""


func setup(lk: Dictionary) -> void:
	look = lk
	guard_pose = _merge(P.NEUTRAL, P.GUARD_KIM if lk.get("guard", "kim") == "kim" else P.GUARD_BAEK)
	for sh in P.SHAPES:
		var keys: Dictionary = P.SHAPES[sh]
		var w := _merge(guard_pose, keys["W"])
		var s := _merge(w, keys["S"])
		if sh.begins_with("slash"):
			s = _merge(_merge(w, P.LUNGE_LEGS), keys["S"])
		var f := _merge(s, keys["F"])
		shape_keys[sh] = [w, s, f]
		if sh == "punch":
			# 왼손 주먹: 오른손 주먹을 좌우로 뒤집는다 (삼연타 둘째 대)
			var wl := _merge(guard_pose, _mirror(keys["W"]))
			var sl := _merge(wl, _mirror(keys["S"]))
			shape_keys["punch_L"] = [wl, sl, _merge(sl, _mirror(keys["F"]))]
	cur = guard_pose.duplicate()
	_build()
	_apply(cur)


# ----------------------------------------------------------------------
# 몸 만들기
func _build() -> void:
	var lk := look
	var big: bool = lk.get("big", false)
	var shirt_only: bool = lk.get("outfit", "suit") == "shirt"   # 정장 없이 셔츠(소매 걷음) — 백도찬 부두 차림
	var suit := _mat(lk["suit"], 0.74, 0.45)
	var pants := _mat(lk["pants"], 0.78, 0.4)
	var shirt := _mat(lk["shirt"], 0.85, 0.2)
	var skin := _mat(lk["skin"], 0.62, 0.25)
	var hair := _mat(lk["hair"], 0.42, 0.35)
	var shoe := _mat(Color(0.05, 0.05, 0.06), 0.35, 0.3)
	var eye := _mat(Color(0.07, 0.05, 0.05), 0.5, 0.0)
	var dark := _mat(Color(0.04, 0.04, 0.05), 0.4, 0.1)
	var top := shirt if shirt_only else suit                    # 몸통 · 위팔 겉감
	var wide: float = lk.get("wide", 1.08 if big else 1.0)      # 몸 너비(거구 · 어깨 넓음)
	var sh_wide: float = lk.get("shoulder", wide)               # 어깨 너비만 따로(김신 — 어깨 넓은 근육질)
	var depth: float = lk.get("depth", 1.0)                     # 몸통 두께(앞뒤) — 거구 · 근육질
	var limb: float = lk.get("limb", 1.0)                       # 팔다리 굵기 — 막대처럼 보이지 않게(rc.2 폰 리뷰 6)
	var head_k: float = lk.get("head", 1.0)                     # 머리 크기
	var body_k: float = lk.get("scale", 1.06 if big else 1.0)

	J["fall"] = _node(self, Vector3.ZERO)
	J["roll"] = _node(J["fall"], Vector3(0, ROLL_PIVOT, 0))
	J["body"] = _node(J["roll"], Vector3(0, -ROLL_PIVOT, 0))
	J["body"].scale = Vector3.ONE * body_k
	J["hips"] = _node(J["body"], Vector3(0, PELVIS_H, 0))
	# 몸통 겉모양은 관절 노드 밑의 '껍데기' 노드에 붙여 앞뒤 두께(depth)만 늘린다 — 관절 노드를 늘이면 팔다리가 찌그러진다
	var hs := _shell(J["hips"], depth)
	_mesh(hs, _capsule(0.125, 0.36), pants, Vector3(0, -0.03, 0), Vector3(0, 0, 90), Vector3(1, wide, 0.8))
	# 검은 벨트 + 버클 (김신 은 버클 · 백도찬 검은 벨트)
	_mesh(hs, _cyl(0.142, 0.142, 0.036), dark, Vector3(0, 0.055, 0), Vector3.ZERO, Vector3(1.02 * wide, 1, 0.76))
	if lk.get("buckle") != null:
		_mesh(hs, _box(Vector3(0.05, 0.034, 0.012)), _mat(lk["buckle"], 0.22, 0.1, 0.9), Vector3(0, 0.055, -0.11))
	J["spine"] = _node(J["hips"], Vector3(0, 0.02, 0))
	_mesh(_shell(J["spine"], depth), _capsule(0.13, 0.32), top, Vector3(0, 0.12, 0), Vector3.ZERO, Vector3(1.12 * wide, 1, 0.74))
	J["chest"] = _node(J["spine"], Vector3(0, CHEST_UP, 0))
	var cs := _shell(J["chest"], depth)
	_mesh(cs, _cyl(0.2 * sh_wide, 0.15 * wide, 0.34), top, Vector3(0, 0.05, 0), Vector3.ZERO, Vector3(1, 1, 0.6))
	_mesh(cs, _capsule(0.082, 0.48 * sh_wide), top, Vector3(0, 0.15, 0), Vector3(0, 0, 90), Vector3(1, 1, 0.78))
	# 앞은 -Z
	if shirt_only:
		# 셔츠: 단추 줄 · 열린 깃(목 V) · 깃
		_mesh(cs, _box(Vector3(0.008, 0.24, 0.01)), _mat(lk["shirt"].darkened(0.18), 0.8, 0.0), Vector3(0, 0.06, -0.122))
		_mesh(cs, _box(Vector3(0.05, 0.06, 0.012)), skin, Vector3(0, 0.18, -0.112))
		_mesh(cs, _cyl(0.064, 0.07, 0.045), shirt, Vector3(0, 0.205, -0.004))
	else:
		# 정장: 셔츠 V · 넥타이 · 깃
		_mesh(cs, _box(Vector3(0.1, 0.2, 0.012)), shirt, Vector3(0, 0.12, -0.118))
		_mesh(cs, _cyl(0.062, 0.066, 0.04), shirt, Vector3(0, 0.205, -0.004))
		if lk.get("tie") != null:
			_mesh(cs, _box(Vector3(0.036, 0.24, 0.014)), _mat(lk["tie"], 0.5, 0.2), Vector3(0, 0.085, -0.127))
	if lk.get("badge") != null:                                  # 옷깃 금 배지 (왼쪽 가슴)
		_mesh(cs, _cyl(0.014, 0.014, 0.008), _mat(lk["badge"], 0.2, 0.2, 0.9), Vector3(-0.085, 0.16, -0.122), Vector3(90, 0, 0))
	if lk.get("holster") != null:
		_holster(cs, _mat(lk["holster"], 0.7, 0.15), dark, wide)
	J["neck"] = _node(J["chest"], Vector3(0, NECK_UP, 0))
	_mesh(J["neck"], _cyl(0.047 * wide, 0.05 * wide, 0.12), skin, Vector3(0, 0.03, 0))
	J["head"] = _node(J["neck"], Vector3(0, HEAD_UP, 0))
	J["head"].scale = Vector3.ONE * head_k
	_mesh(J["head"], _sphere(0.105, 0.232), skin, Vector3(0, 0, 0))
	_mesh(J["head"], _box(Vector3(0.022, 0.036, 0.022)), skin, Vector3(0, -0.012, -0.104))     # 코
	if lk.get("jaw", false):                                     # 각진 턱
		_mesh(J["head"], _box(Vector3(0.13, 0.05, 0.1)), skin, Vector3(0, -0.07, -0.035))
	# 턱 수염 그늘 (둘 다) — 턱 앞쪽만 조금 어둡게
	_mesh(J["head"], _sphere(0.092, 0.1), _mat(lk["skin"].darkened(0.2), 0.8, 0.0), Vector3(0, -0.068, -0.03), Vector3.ZERO, Vector3(1, 1, 0.9))
	var eye_h: float = lk.get("eye_h", 0.011)                   # 김신 가는 눈
	# 눈썹 · 입 — 얼굴이 밋밋하지 않게(rc.2 폰 리뷰 6). brow_tilt: 눈썹 끝을 올린 각(김신 날카로운 눈매)
	var brow_tilt: float = lk.get("brow_tilt", 6.0)
	for sx in [-1.0, 1.0]:
		_mesh(J["head"], _box(Vector3(0.034, 0.009, 0.012)), _mat(lk["hair"], 0.6, 0.0), Vector3(0.038 * sx, 0.03, -0.098),
			Vector3(0, 0, brow_tilt * sx))
	_mesh(J["head"], _box(Vector3(0.032, 0.005, 0.008)), _mat(lk["skin"].darkened(0.4), 0.7, 0.0), Vector3(0, -0.046, -0.097))
	for sx in [-1.0, 1.0]:
		_mesh(J["head"], _sphere(0.022, 0.044), skin, Vector3(0.103 * sx, -0.004, 0.006))     # 귀
		_mesh(J["head"], _box(Vector3(0.024, eye_h, 0.012)), eye, Vector3(0.037 * sx, 0.008, -0.096))
		if lk.get("piercing", false):                            # 귀 검은 스터드
			_mesh(J["head"], _sphere(0.007, 0.014), dark, Vector3(0.112 * sx, -0.024, 0.0))
	if lk.get("scar", false):                                    # 왼뺨 흉터
		_mesh(J["head"], _box(Vector3(0.006, 0.046, 0.006)), _mat(lk["skin"].darkened(0.35).lerp(Color(0.6, 0.2, 0.2), 0.3), 0.7, 0.0),
			Vector3(-0.06, -0.03, -0.088), Vector3(0, -30, 18))
	_hair(J["head"], hair, str(lk.get("hair_style", "short")))
	if lk.get("glasses", false):
		glasses = _glasses(J["head"])
	# 팔 · 다리
	for side in ["r", "l"]:
		var sx := 1.0 if side == "r" else -1.0
		var sh := _node(J["chest"], Vector3(sx * SHOULDER_W * sh_wide, SHOULDER_UP, 0))
		J["sh_" + side] = sh
		_mesh(sh, _sphere(0.072 * sh_wide * limb, 0.144 * sh_wide * limb), top, Vector3.ZERO)          # 어깨(삼각근)
		_mesh(sh, _capsule(0.058 * wide * limb, 0.34), top, Vector3(0, -UPPER_ARM * 0.5, 0))
		_mesh(sh, _sphere(0.064 * wide * limb, 0.17), top, Vector3(0, -UPPER_ARM * 0.4, -0.01))       # 위팔 근육(이두)
		var el := _node(sh, Vector3(0, -UPPER_ARM, 0))
		J["el_" + side] = el
		if shirt_only:
			# 소매 걷음: 아래팔은 맨살, 팔꿈치 아래에 걷어 올린 소매 뭉치
			_mesh(el, _capsule(0.046 * wide * limb, 0.29), skin, Vector3(0, -FOREARM * 0.5, 0))
			_mesh(el, _sphere(0.054 * wide * limb, 0.15), skin, Vector3(0, -FOREARM * 0.32, 0))          # 아래팔 근육(팔꿈치 쪽 굵게)
			_mesh(el, _cyl(0.06 * wide * limb, 0.058 * wide * limb, 0.06), shirt, Vector3(0, -0.035, 0))
		else:
			_mesh(el, _capsule(0.048 * wide * limb, 0.29), suit, Vector3(0, -FOREARM * 0.5, 0))
			_mesh(el, _sphere(0.054 * wide * limb, 0.15), suit, Vector3(0, -FOREARM * 0.32, 0))
			_mesh(el, _cyl(0.05, 0.05, 0.028), shirt, Vector3(0, -FOREARM + 0.028, 0))            # 소맷부리
		var hand := _node(el, Vector3(0, -FOREARM, 0))
		J["hand_" + side] = hand
		_mesh(hand, _sphere(0.046 * sqrt(limb), 0.1 * sqrt(limb)), skin, Vector3(0, -0.044, -0.004), Vector3.ZERO, Vector3(0.82, 1, 1))
		var th := _node(J["hips"], Vector3(sx * HIP_W * wide, -0.03, 0))
		J["th_" + side] = th
		_mesh(th, _capsule(0.083 * wide * limb, 0.5), pants, Vector3(0, -THIGH * 0.5, 0))
		_mesh(th, _sphere(0.092 * wide * limb, 0.26), pants, Vector3(0, -THIGH * 0.3, 0))             # 허벅지 위쪽 굵게
		var kn := _node(th, Vector3(0, -THIGH, 0))
		J["kn_" + side] = kn
		_mesh(kn, _capsule(0.062 * wide * limb, 0.48), pants, Vector3(0, -SHIN * 0.5, 0))
		_mesh(kn, _sphere(0.068 * wide * limb, 0.2), pants, Vector3(0, -SHIN * 0.28, 0.012))          # 종아리
		var ft := _node(kn, Vector3(0, -SHIN, 0))
		J["ft_" + side] = ft
		_mesh(ft, _capsule(0.045, 0.26), shoe, Vector3(0, -0.012, -0.055), Vector3(90, 0, 0), Vector3(1.05, 1, 0.9))
	weapon_r = _attach(J["hand_r"], str(lk.get("weapon_r", "")), GRIP_FWD)
	weapon_l = _attach(J["hand_l"], str(lk.get("weapon_l", "")), GRIP_REV)
	# 예고 표시 (흰 ! 쳐내기 · 빨간 ! 가드 불가 · 빈틈)
	tele = Label3D.new()
	tele.font = FONT
	tele.font_size = 96
	tele.outline_size = 22
	tele.outline_modulate = Color(0, 0, 0, 0.9)
	tele.pixel_size = 0.0045
	tele.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tele.no_depth_test = true
	tele.position = Vector3(0, 2.22, 0)
	tele.visible = false
	tele_y = 2.22 + (body_k - 1.0) * 1.9                         # 큰 몸은 머리가 높다 — 예고 · 빈틈 글자를 그만큼 위로
	add_child(tele)


## 머리 모양: slick_fringe(김신 — 짧게 뒤로 넘긴 올백 + 이마로 떨어진 앞머리 몇 가닥) · slick(백도찬 — 뒤로 넘긴 머리, 2차에
## 가닥이 흘러내린다 — loose_hair()) · parted · short. 외형 근거는 castle_common canon/characters.json look(conf ai — 연출용)
var loose: Node3D = null


func _hair(head: Node3D, m: Material, style: String) -> void:
	if style == "slick_fringe" or style == "slick":
		if style == "slick_fringe":
			# 김신: 옆은 짧게(관자놀이 · 귀 위 살이 보이게 — 옆까지 덮으면 헬멧 같다, rc.2 폰 리뷰 6), 위는 뒤로 넘기고 뒤통수는 목덜미까지
			_mesh(head, _sphere(0.108, 0.2), m, Vector3(0, 0.066, 0.026), Vector3.ZERO, Vector3(0.93, 0.6, 1.0))
			_mesh(head, _sphere(0.098, 0.15), m, Vector3(0, 0.004, 0.05), Vector3.ZERO, Vector3(0.93, 1.0, 0.85))
			_mesh(head, _sphere(0.09, 0.09), m, Vector3(0, 0.1, -0.03), Vector3(-8, 0, 0), Vector3(0.95, 0.55, 1.0))
		else:
			# 뒤로 넘긴 머리: 정수리 · 뒤통수를 덮고 앞이마 선은 높게, 앞쪽이 살짝 솟는다
			_mesh(head, _sphere(0.109, 0.2), m, Vector3(0, 0.052, 0.03), Vector3.ZERO, Vector3(1.0, 0.66, 1.0))
			# 앞쪽 살짝 솟은 부분 — 크게 두면 위에서 보는 카메라에 혹처럼 보인다(run #16), 빗은 결 줄도 뺐다
			_mesh(head, _sphere(0.096, 0.1), m, Vector3(0, 0.082, -0.022), Vector3(-8, 0, 0), Vector3(1.0, 0.5, 1.0))
		if style == "slick_fringe":
			for k in 3:                                          # 앞머리 몇 가닥 (이마로)
				_mesh(head, _box(Vector3(0.012, 0.075, 0.01)), m, Vector3(-0.03 + 0.024 * k, 0.05, -0.102),
					Vector3(-14, 0, -12 + 12 * k))
		else:
			loose = _node(head, Vector3.ZERO)                    # 백도찬: 싸우면 흘러내리는 가닥 (2차에 보인다)
			for k in 2:
				_mesh(loose, _box(Vector3(0.01, 0.075, 0.008)), m, Vector3(-0.022 + 0.04 * k, 0.045, -0.1),
					Vector3(-14, 0, 8 - 20 * k))
			loose.visible = false
	elif style == "parted":
		_mesh(head, _sphere(0.108, 0.2), m, Vector3(0, 0.05, 0.022), Vector3.ZERO, Vector3(1.0, 0.66, 1.02))
		_mesh(head, _box(Vector3(0.11, 0.03, 0.17)), m, Vector3(0.034, 0.088, -0.004), Vector3(0, 0, -12))
		_mesh(head, _box(Vector3(0.16, 0.03, 0.04)), m, Vector3(-0.01, 0.072, -0.086), Vector3(-24, 0, -8))
	else:
		_mesh(head, _sphere(0.107, 0.2), m, Vector3(0, 0.048, 0.024), Vector3.ZERO, Vector3(1.0, 0.64, 1.02))
		_mesh(head, _box(Vector3(0.15, 0.036, 0.05)), m, Vector3(0, 0.07, -0.084), Vector3(-22, 0, 0))


## 백도찬 안경: 테 없는(은테) 직사각 — 알이 빛을 받아 하얗게 눈을 가린다(canon look)
func _glasses(head: Node3D) -> Node3D:
	var g := _node(head, Vector3.ZERO)
	var frame := _mat(Color(0.75, 0.77, 0.8), 0.25, 0.0, 0.85)
	var lens := _mat(Color(0.97, 0.98, 1.0), 0.08, 0.6)
	for sx in [-1.0, 1.0]:
		_mesh(g, _box(Vector3(0.036, 0.022, 0.004)), lens, Vector3(0.039 * sx, 0.009, -0.106))
		_mesh(g, _box(Vector3(0.004, 0.004, 0.09)), frame, Vector3(0.06 * sx, 0.014, -0.062))
	_mesh(g, _box(Vector3(0.02, 0.004, 0.005)), frame, Vector3(0, 0.014, -0.108))
	return g


## 2차(전력): 안경을 벗고, 뒤로 넘긴 머리 가닥이 흘러내린다
func remove_glasses() -> void:
	if glasses != null:
		glasses.visible = false
	if loose != null:
		loose.visible = true


## 백도찬 어깨 홀스터: 등에서 X 자로 걸친 갈색 가죽 끈 + 앞쪽 어깨끈 + 왼 겨드랑이 권총집 · 권총 손잡이
func _holster(chest: Node3D, leather: Material, dark: Material, wide: float) -> void:
	for sx in [-1.0, 1.0]:
		_mesh(chest, _box(Vector3(0.036, 0.34, 0.012)), leather, Vector3(0, 0.08, 0.121), Vector3(0, 0, 32 * sx))     # 등 X
		_mesh(chest, _box(Vector3(0.03, 0.17, 0.012)), leather, Vector3(0.118 * sx * wide, 0.12, -0.112), Vector3(0, 0, -14 * sx))
	_mesh(chest, _box(Vector3(0.05, 0.12, 0.07)), leather, Vector3(-0.19 * wide, 0.0, -0.01))       # 권총집 (왼 겨드랑이)
	_mesh(chest, _box(Vector3(0.032, 0.055, 0.04)), dark, Vector3(-0.19 * wide, 0.075, 0.018), Vector3(-20, 0, 0))


func _attach(hand: Node3D, kind: String, dir: Vector3) -> Node3D:
	if kind == "":
		return null
	var w := _knife(kind)
	w.position = Vector3(0, -0.05, -0.006)
	w.basis = Basis(Quaternion(Vector3.UP, dir.normalized()))
	hand.add_child(w)
	return w


## 칼 (칼날이 +Y). combat: 김신 — 톱니 등날 군용 단검(canon look, 검은 손잡이 · 외날 · 등에 톱니) / gerber: 거버 Mark II —
## 양날 창끝 · 고무 손잡이(전 그림) / sashimi: 백도찬 — 길고 가는 외날 · 갈색 손잡이
func _knife(kind: String) -> Node3D:
	var root := Node3D.new()
	var steel := _mat(Color(0.86, 0.88, 0.92), 0.16, 0.0, 0.95)
	if kind == "combat":
		_mesh(root, _cyl(0.014, 0.013, 0.11), _mat(Color(0.08, 0.08, 0.09), 0.85, 0.0), Vector3(0, -0.01, 0))
		_mesh(root, _box(Vector3(0.06, 0.012, 0.02)), _mat(Color(0.3, 0.3, 0.33), 0.3, 0.0, 0.8), Vector3(0, 0.05, 0))
		_mesh(root, _box(Vector3(0.03, 0.15, 0.005)), steel, Vector3(0, 0.13, 0))
		var tip := PrismMesh.new()
		tip.size = Vector3(0.03, 0.05, 0.005)
		tip.left_to_right = 0.0
		_mesh(root, tip, steel, Vector3(0, 0.23, 0))
		for k in 4:                                              # 등날 톱니
			_mesh(root, _box(Vector3(0.008, 0.008, 0.005)), steel, Vector3(-0.017, 0.09 + 0.022 * k, 0), Vector3(0, 0, 45))
		return root
	if kind == "sashimi":
		_mesh(root, _cyl(0.012, 0.012, 0.12), _mat(Color(0.45, 0.3, 0.17), 0.8, 0.0), Vector3(0, -0.01, 0))
		_mesh(root, _box(Vector3(0.026, 0.25, 0.004)), steel, Vector3(0, 0.175, 0))
		var tip := PrismMesh.new()
		tip.size = Vector3(0.026, 0.055, 0.004)
		tip.left_to_right = 1.0
		_mesh(root, tip, steel, Vector3(0, 0.3275, 0))
	else:
		_mesh(root, _cyl(0.013, 0.013, 0.11), _mat(Color(0.09, 0.09, 0.1), 0.85, 0.0), Vector3(0, -0.01, 0))
		_mesh(root, _box(Vector3(0.056, 0.012, 0.02)), _mat(Color(0.3, 0.3, 0.33), 0.3, 0.0, 0.8), Vector3(0, 0.05, 0))
		var blade := CylinderMesh.new()
		blade.top_radius = 0.0
		blade.bottom_radius = 0.02
		blade.height = 0.17
		blade.radial_segments = 4
		blade.rings = 1
		_mesh(root, blade, steel, Vector3(0, 0.14, 0), Vector3(0, 45, 0), Vector3(1, 1, 0.3))
	return root


## 몸통 겉모양 노드 — 앞뒤(z)만 depth 배. 관절 노드(위치 · 회전)는 그대로라 팔다리 길이 · 각도가 바뀌지 않는다
func _shell(parent: Node3D, depth: float) -> Node3D:
	var n := _node(parent, Vector3.ZERO)
	n.scale = Vector3(1, 1, depth)
	return n


func _node(parent: Node3D, pos: Vector3) -> Node3D:
	var n := Node3D.new()
	n.position = pos
	parent.add_child(n)
	return n


func _mesh(parent: Node3D, mesh: Mesh, mat: Material, pos := Vector3.ZERO, rot := Vector3.ZERO, scl := Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot
	mi.scale = scl
	parent.add_child(mi)
	return mi


func _mat(c: Color, rough := 0.7, rim := 0.3, metal := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	if rim > 0.0:
		m.rim_enabled = true
		m.rim = rim
		m.rim_tint = 0.35
	# 번쩍임 때 셰이더를 새로 만들지 않게 발광은 늘 켜 두고 색만 바꾼다
	m.emission_enabled = true
	m.emission = Color(0, 0, 0)
	mats.append(m)
	return m


func _capsule(r: float, h: float) -> CapsuleMesh:
	var m := CapsuleMesh.new()
	m.radius = r
	m.height = maxf(h, r * 2.0)
	m.radial_segments = 12
	m.rings = 4
	return m


func _cyl(top: float, bottom: float, h: float) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius = top
	m.bottom_radius = bottom
	m.height = h
	m.radial_segments = 14
	m.rings = 1
	return m


func _sphere(r: float, h: float) -> SphereMesh:
	var m := SphereMesh.new()
	m.radius = r
	m.height = h
	m.radial_segments = 16
	m.rings = 8
	return m


func _box(size: Vector3) -> BoxMesh:
	var m := BoxMesh.new()
	m.size = size
	return m


# ----------------------------------------------------------------------
# 자세
static func _merge(a: Dictionary, b: Dictionary) -> Dictionary:
	var out := a.duplicate()
	for k in b:
		out[k] = b[k]
	return out


static func _lerp_pose(a: Dictionary, b: Dictionary, k: float) -> Dictionary:
	var out := {}
	for key in P.NEUTRAL:
		var va = a.get(key, P.NEUTRAL[key])
		var vb = b.get(key, P.NEUTRAL[key])
		if va is Vector3:
			out[key] = (va as Vector3).lerp(vb, k)
		else:
			out[key] = lerpf(float(va), float(vb), k)
	return out


static func _ease_out(u: float) -> float:
	u = clampf(u, 0.0, 1.0)
	return 1.0 - (1.0 - u) * (1.0 - u)


static func _ease_in_out(u: float) -> float:
	u = clampf(u, 0.0, 1.0)
	return u * u * (3.0 - 2.0 * u)


static func _torso(v: Vector3) -> Vector3:
	return Vector3(deg_to_rad(-v.x), deg_to_rad(v.y), deg_to_rad(-v.z))


static func _limb(v: Vector3, side: float) -> Vector3:
	return Vector3(deg_to_rad(v.x), deg_to_rad(v.y * side), deg_to_rad(v.z * side))


func _apply(p: Dictionary) -> void:
	J["hips"].position = Vector3(0, PELVIS_H + float(p["root_y"]), -float(p["root_fwd"]))
	J["hips"].rotation = _torso(p["pelvis"])
	J["spine"].rotation = _torso(p["spine"])
	J["chest"].rotation = _torso(p["chest"])
	J["neck"].rotation = _torso(p["head"])
	for side in ["r", "l"]:
		var sx := 1.0 if side == "r" else -1.0
		J["sh_" + side].rotation = _limb(p["sh_" + side], sx)
		J["el_" + side].rotation = Vector3(deg_to_rad(float(p["el_" + side])), 0, 0)
		J["hand_" + side].rotation = _limb(p["wr_" + side], sx)
		J["th_" + side].rotation = _limb(p["th_" + side], sx)
		J["kn_" + side].rotation = Vector3(-deg_to_rad(float(p["kn_" + side])), 0, 0)
		J["ft_" + side].rotation = Vector3(deg_to_rad(float(p["ft_" + side])), 0, 0)
	J["body"].rotation = Vector3(0, deg_to_rad(float(p["spin"])), 0)
	J["roll"].rotation = Vector3(deg_to_rad(float(p["roll"])), 0, 0)
	var fall := deg_to_rad(float(p["fall"]))
	J["fall"].rotation = Vector3(fall, 0, 0)
	J["fall"].position = Vector3(0, 0.11 * sin(fall), 0)


## 발 붙이기: 가장 낮은 발목이 땅 높이에 오도록 골반을 올리거나 내린다 (무릎을 굽히면 몸이 낮아진다)
func _ground() -> void:
	var lo := INF
	for side in ["r", "l"]:
		lo = minf(lo, to_local(J["ft_" + side].global_position).y)
	var k: float = J["body"].scale.y
	J["hips"].position.y += (ANKLE_H * k - lo) / k


func update_from(f, dt: float, frozen: bool) -> void:
	position = Vector3(f.pos.x, 0, f.pos.y)
	_update_flash(f)
	_update_telegraph(f)
	if frozen:
		return                                   # 역경직: 자세를 그대로 멈춘다
	time += dt
	if f.state != _last_state:
		# 돌기 · 구르기 각도를 짧은 쪽으로 감아 둔다 (세 바퀴 돈 뒤 거꾸로 풀리지 않게)
		cur["spin"] = wrapf(float(cur["spin"]), -180.0, 180.0)
		cur["roll"] = wrapf(float(cur["roll"]), -180.0, 180.0)
		_last_state = f.state
	var target := _target_pose(f, dt)
	var rate := 15.0
	match f.state:
		"attack":
			rate = 38.0
		"roll":
			rate = 40.0
		"recoil", "hitstun", "parry", "down", "dead", "stun":
			rate = 28.0
	cur = _lerp_pose(cur, target, 1.0 - exp(-rate * dt))
	if f.state == "attack":
		cur["spin"] = target["spin"]
	elif f.state == "roll":
		cur["roll"] = target["roll"]
	_apply(cur)
	if f.state != "roll" and f.state != "down" and f.state != "dead":
		_ground()
	var want: Vector2 = f.roll_dir if f.state == "roll" else f.facing
	var yaw_rate := 40.0 if f.state == "roll" or f.state == "attack" else 14.0
	yaw = lerp_angle(yaw, atan2(-want.x, -want.y), 1.0 - exp(-yaw_rate * dt))
	rotation.y = yaw


func _target_pose(f, dt: float) -> Dictionary:
	if victory:
		return _merge(guard_pose, P.VICTORY)
	match f.state:
		"idle", "move":
			return _locomotion(f, dt)
		"attack":
			return _attack_pose(f)
		"parry":
			# 쳐내는 쪽 팔만 세우고 반대 팔은 가드 그대로
			var pp := _merge(guard_pose, P.PARRY)
			var off := "l" if f.parry_side == "R" else "r"
			pp["sh_" + off] = guard_pose["sh_" + off]
			pp["el_" + off] = guard_pose["el_" + off]
			return pp
		"roll":
			var u := float(f.t) / Fighter.ROLL_T
			var p := _merge(guard_pose, P.TUCK)
			p["root_y"] = -0.4
			if u > 0.75:
				p = _lerp_pose(p, guard_pose, (u - 0.75) / 0.25)
			p["roll"] = -360.0 * _ease_in_out(u)
			return p
		"hitstun":
			return _merge(guard_pose, P.HURT)
		"recoil":
			return _merge(guard_pose, P.RECOIL)
		"stun":
			var st := _merge(guard_pose, P.STUN)
			st["chest"] = st["chest"] + Vector3(0, 6.0 * sin(time * 3.0), 10.0 * sin(time * 2.2))
			st["head"] = st["head"] + Vector3(0, 10.0 * sin(time * 3.0 - 0.5), 0)
			return st
		"stagger":
			var q := _merge(guard_pose, P.STAGGER)
			q["chest"] = q["chest"] + Vector3(0, 0, 9.0 * sin(time * 4.5))
			q["head"] = q["head"] + Vector3(0, 0, 12.0 * sin(time * 4.5 - 0.6))
			return q
		"down":
			return _down_pose(f, true)
		"dead":
			return _down_pose(f, false)
	return guard_pose


func _locomotion(f, dt: float) -> Dictionary:
	var p: Dictionary = guard_pose.duplicate()
	if f.flick_t > 0:
		p = _merge(p, P.FLICK if f.parry_side == "R" else _mirror(P.FLICK))   # 들어오는 쪽 팔로 바깥으로 튕긴다
	p["chest"] = p["chest"] + Vector3(1.4 * sin(time * 2.3), 0, 0)      # 숨
	var sp: float = f.speed_now
	if sp < 0.2:
		return p
	var mv: Vector2 = f.move_vec.normalized()
	var fwd: float = mv.dot(f.facing)
	var side: float = mv.dot(Vector2(-f.facing.y, f.facing.x))
	var run := sp > 3.2
	var cadence := 2.7 if run else 1.7 + 0.5 * clampf(sp / 2.1, 0.0, 1.0)
	phase = fmod(phase + TAU * cadence * dt, TAU)
	var s := sin(phase)
	var c := cos(phase)
	if run:
		return _merge(p, {
			"pelvis": Vector3(12, 8 * s, 0), "spine": Vector3(4, 0, 0), "chest": Vector3(6, -12 * s, 0),
			"head": Vector3(-14, 4 * s, 0),
			"th_r": Vector3(46 * s + 6, 0, 4), "th_l": Vector3(-46 * s + 6, 0, 4),
			"kn_r": 16.0 + 80.0 * maxf(0.0, c), "kn_l": 16.0 + 80.0 * maxf(0.0, -c),
			"ft_r": -12.0 * s, "ft_l": 12.0 * s,
			"sh_r": Vector3(-36 * s + 18, 10, 14), "el_r": 88.0, "sh_l": Vector3(36 * s + 18, 10, 14), "el_l": 88.0,
		})
	# 칼 자세 그대로 발만 옮긴다 (마주 본 채 앞뒤 · 옆걸음)
	var amp := 26.0 * clampf(sp / 2.1, 0.4, 1.0)
	p["th_r"] = p["th_r"] + Vector3(amp * s * fwd, 0, 14.0 * s * side)
	p["th_l"] = p["th_l"] + Vector3(-amp * s * fwd, 0, -14.0 * s * side)
	p["kn_r"] = float(p["kn_r"]) + 24.0 * maxf(0.0, c)
	p["kn_l"] = float(p["kn_l"]) + 24.0 * maxf(0.0, -c)
	p["sh_r"] = p["sh_r"] + Vector3(4.0 * s, 0, 0)
	p["sh_l"] = p["sh_l"] + Vector3(-4.0 * s, 0, 0)
	return p


func _attack_pose(f) -> Dictionary:
	var mv: Dictionary = f.move
	var shape := str(mv["shape"])
	if shape == "slash_back":
		shape = "slash_back_L" if str(mv["hand"]) == "L" and weapon_l != null else "slash_back_R"
	var keys: Array = shape_keys.get(shape, shape_keys["slash"])
	var w: Dictionary = keys[0]
	var s: Dictionary = keys[1]
	var fo: Dictionary = keys[2]
	var su := int(mv["startup"])
	var ac := int(mv["active"])
	var rc := int(mv["recovery"])
	var t: int = f.t
	var brake := int(mv["brake"])
	var from := w if brake <= 0 else _lerp_pose(w, s, BRAKE_AT)
	if t <= su and brake > 0:
		return _brake_pose(t, brake, w, s, from)
	if t <= su:
		var u := float(t) / maxf(1.0, su)
		if shape == "sidekick":
			return _sidekick_windup(f, u, w)
		var p := _lerp_pose(guard_pose, w, 1.0 - (1.0 - u) * (1.0 - u))   # 준비 자세가 일찍 보이게(처음이 빠르다)
		for fr in mv["feints"]:
			if t >= int(fr) and t < int(fr) + 4:
				p = _lerp_pose(w, s, 0.7)       # 멈칫: 치는 척만 하고 몸은 다시 준비로
		return p
	if t <= su + ac and str(mv["fx"]) == "triple":
		return _triple_pose(mv, t - su)
	if t <= su + ac:
		var u2 := float(t - su) / maxf(1.0, ac)
		var p2 := _lerp_pose(from, s, minf(1.0, _ease_out(u2) * 1.5))
		if shape == "spin":
			p2["spin"] = 1080.0 * u2
		return p2
	var rt := t - su - ac
	if f.whiff_t > 0:
		if rt <= f.whiff_t:
			# 헛침: 뻗은 채로 앞으로 쏠려 멈춰 있다 (역공을 받는 틈)
			var wp := _lerp_pose(s, fo, 0.2)
			wp["chest"] = wp["chest"] + Vector3(5.0 + 3.0 * sin(time * 8.0), 0, 0)
			wp["head"] = wp["head"] + Vector3(6.0, 0, 0)
			return wp
		rt -= f.whiff_t
	var hold := maxi(2, int(rc * 0.45))
	var p3: Dictionary
	if rt <= hold:
		p3 = _lerp_pose(s, fo, _ease_out(float(rt) / hold))
	else:
		p3 = _lerp_pose(fo, guard_pose, _ease_in_out(float(rt - hold) / maxf(1.0, rc - hold)))
	if shape == "spin":
		p3["spin"] = 1080.0
	return p3


## 엇엇박 준비: 엇박처럼 감았다가(앞 70%) 뻗기 시작한 순간(brake) 브레이크 — 반쯤 뻗은 채 온몸에 힘이 걸려 떨며
## 반 박자 버틴다. 판정이 시작되면 그 자리에서 쭉 찌른다
func _brake_pose(t: int, brake: int, w: Dictionary, s: Dictionary, held: Dictionary) -> Dictionary:
	var coil := maxf(1.0, brake * 0.7)
	if t < coil:
		return _lerp_pose(guard_pose, w, _ease_out(float(t) / coil))
	if t < brake:
		return _lerp_pose(w, held, (t - coil) / maxf(1.0, brake - coil))
	var q := sin(time * 70.0)
	var p := held.duplicate()
	p["chest"] = p["chest"] + Vector3(3.0 * q, 0, 2.5 * q)
	p["head"] = p["head"] + Vector3(2.0 * q, 0, 0)
	p["sh_r"] = p["sh_r"] + Vector3(4.0 * q, 0, 0)
	p["sh_l"] = p["sh_l"] + Vector3(-4.0 * q, 0, 0)
	p["kn_r"] = float(p["kn_r"]) + 5.0 * q
	p["kn_l"] = float(p["kn_l"]) - 4.0 * q
	return p


## 리천식 삼연타 판정 동안: 한 대마다 오른손 · 왼손 · 오른손을 번갈아 내지르고(앞 1/3) 반쯤 거둔다. 셋째 대는 더 깊이
func _triple_pose(mv: Dictionary, ta: int) -> Dictionary:
	var hits := int(mv["hits"])
	var seg := maxi(1, int(mv["active"]) / hits)
	var k := mini(hits - 1, (ta - 1) / seg)
	var u := float((ta - 1) % seg + 1) / seg
	var keys: Array = shape_keys["punch_L"] if k % 2 == 1 else shape_keys["punch"]
	var e := minf(1.0, u * 3.0) if u < 0.34 else 1.0 - 0.6 * (u - 0.34) / 0.66
	var p := _lerp_pose(keys[0], keys[1], e)
	if k == hits - 1:
		p["root_fwd"] = float(p["root_fwd"]) + 0.2 * e
		p["chest"] = p["chest"] + Vector3(12, 0, 0) * e
	return p


## 백도찬식 옆차기 준비: 빠르게 발을 구르며 달려나가다(앞 65%) 몸을 돌려 무릎을 접는다
func _sidekick_windup(f, u: float, w: Dictionary) -> Dictionary:
	var stomp := 0.65
	var turn := _merge(guard_pose, {"spin": 50.0, "head": Vector3(-6, -60, 0), "pelvis": Vector3(12, 10, 0)})
	if u < stomp:
		var q := u / stomp
		var p := _lerp_pose(guard_pose, turn, q)
		var s := sin(f.t * 0.95)
		var c := cos(f.t * 0.95)
		p["th_r"] = Vector3(30 * s + 12, 0, 6)
		p["th_l"] = Vector3(-30 * s + 12, 0, 8)
		p["kn_r"] = 30.0 + 44.0 * maxf(0.0, c)
		p["kn_l"] = 30.0 + 44.0 * maxf(0.0, -c)
		return p
	return _lerp_pose(turn, w, _ease_out((u - stomp) / (1.0 - stomp)))


func _down_pose(f, gets_up: bool) -> Dictionary:
	var lying := _merge(guard_pose, P.LYING)
	var t: int = f.t
	if t < 14:
		var p := _lerp_pose(_merge(guard_pose, P.HURT), lying, t / 14.0)
		p["fall"] = 88.0 * _ease_in_out(t / 14.0)
		return p
	if gets_up and t > Fighter.DOWN_T - 22:
		var u := (t - (Fighter.DOWN_T - 22)) / 22.0
		var kneel := _merge(guard_pose, {"kn_r": 70.0, "kn_l": 80.0, "th_r": Vector3(60, 0, 8), "fall": 0.0})
		return _lerp_pose(lying, kneel if u < 0.7 else guard_pose, _ease_in_out(u))
	return lying


## 좌우 뒤집기: 팔다리 r · l 을 맞바꾸고(팔다리 각도는 _limb 가 쪽마다 뒤집는다) 몸통 · 머리의 좌우 돌림(y · z)을 뒤집는다
func _mirror(p: Dictionary) -> Dictionary:
	var q := {}
	for k in p:
		var v = p[k]
		var nk: String = k
		if k.ends_with("_r"):
			nk = k.substr(0, k.length() - 2) + "_l"
		elif k.ends_with("_l"):
			nk = k.substr(0, k.length() - 2) + "_r"
		elif v is Vector3:
			v = Vector3(v.x, -v.y, -v.z)
		q[nk] = v
	return q


func _update_flash(f) -> void:
	var on: bool = f.flash > 0 and (f.flash / 2) % 2 == 0
	var col := Color(0.12, 0.1, 0.09) if on else Color(0, 0, 0)
	if f.state == "attack" and int(f.move["brake"]) > 0 and f.t >= int(f.move["brake"]) \
			and f.t <= int(f.move["startup"]):              # 찌르는 순간 풀린다 (run #11: 맞은 뒤 멈춤 내내 붉었다)
		var k := 0.6 + 0.4 * sin(time * 38.0)
		col = Color(0.34 * k, 0.07 * k, 0.03 * k)       # 엇엇박 브레이크: 온몸이 붉게 달아오른다(부하)
	for m in mats:
		m.emission = col


func _update_telegraph(f) -> void:
	if f.state == "stagger" or f.state == "stun":
		tele.visible = true
		tele.text = "빈틈" if f.state == "stagger" else "기절"
		tele.position = Vector3(0, tele_y, 0)
		tele.font_size = 64
		tele.modulate = Color(1.0, 0.82, 0.3, 1.0)
		tele.scale = Vector3.ONE
		return
	var tg: Array = f.telegraph()
	if tg.is_empty():
		tele.visible = false
		return
	var kind: String = tg[0]
	var left: int = tg[1]
	var big := left <= 6
	tele.visible = true
	tele.text = "!"
	tele.font_size = 96
	tele.position = Vector3(0, tele_y, 0)
	var col := Color(1, 1, 1) if kind == "parry" else Color(1.0, 0.22, 0.18)
	col.a = 0.5 if big and left % 2 == 1 else 1.0
	tele.modulate = col
	tele.scale = Vector3.ONE * (1.6 if big else 0.95)
