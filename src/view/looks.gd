extends RefCounted
## 외형 표(3층 · 이 판 소유) — 관절 인형(src/view/puppet3d.gd setup)이 읽는다. 새 인물은 한 칸을 더한다(OCP).
## GLB · 도트로 바꿀 때도 인물 id → 외형 이름은 여기서(hotel.gd ROLES look · main.gd).

# 외형(3층 · 이 판 소유): castle_common `canon/characters.json` 의 look 글(conf ai — 원작 화별 판독을 합친 것, 연출에만)을
# 관절 인형으로 옮겼다(2026-11-05 사용자 "김신과 백도찬도 캐릭터에 맞게 외형 바꿔졌으면"). 색은 3D 밤 조명에 맞게 조금 밝힘.
#  김신: 키 크고 어깨 넓은 근육질 · 검은 올백 + 앞머리 몇 가닥 · 가는 눈 · 왼뺨 흉터 · 귀 검은 스터드 · 턱 수염 그늘 ·
#        검은 정장 · 흰 셔츠 · 검은 넥타이 · 옷깃 금 배지 · 은 버클 검은 벨트 · 톱니 등날 군용 단검(역수 · 정수)
#  (rc.2 폰 리뷰 2026-11-05: 김신 '머리 · 얼굴 · 몸 비율이 이상함' → 옆머리 짧게 · 눈썹 · 입 · 머리 0.9 · 팔다리 굵게 · 몸통 두껍게,
#   백도찬 '몸이 더 크고 두꺼워야 함. 특히 김신보다는 더' → 키 1.2 · 너비 1.3 · 두께 1.4 · 팔다리 1.45)
#  백도찬(6장 부두 — 대표 차림, 사용자 2026-11-05): 뒤로 넘긴 밝은 갈색 머리(2차에 가닥이 흘러내림) · 빛 반사로 하얀 테 없는
#        직사각 안경 · 각진 턱 · 근육질 거구 · 소매 걷은 흰 셔츠 · 등에서 X 자 갈색 가죽 어깨 홀스터(왼 겨드랑이 권총) ·
#        검은 벨트 · 바지 · 구두 · 갈색 손잡이 가는 단도 · 귀 검은 피어싱
const LOOKS := {
	"kim": {"suit": Color(0.16, 0.16, 0.2), "pants": Color(0.13, 0.13, 0.17), "shirt": Color(0.93, 0.93, 0.94),
		"tie": Color(0.09, 0.09, 0.12), "skin": Color(0.91, 0.77, 0.65), "hair": Color(0.11, 0.11, 0.15),
		"hair_style": "slick_fringe", "glasses": false, "big": false, "scale": 1.04, "shoulder": 1.12, "eye_h": 0.007,
		"depth": 1.1, "limb": 1.15, "head": 0.9, "brow_tilt": 12.0, "jaw": true,
		"scar": true, "piercing": true, "badge": Color(0.95, 0.75, 0.25), "buckle": Color(0.82, 0.84, 0.88),
		"weapon_r": "combat", "weapon_l": "combat", "guard": "kim"},
	"baek": {"outfit": "shirt", "suit": Color(0.9, 0.9, 0.92), "pants": Color(0.11, 0.11, 0.13), "shirt": Color(0.92, 0.92, 0.94),
		"skin": Color(0.89, 0.75, 0.63), "hair": Color(0.62, 0.44, 0.27), "hair_style": "slick", "glasses": true,
		"big": true, "scale": 1.2, "wide": 1.28, "depth": 1.35, "limb": 1.2, "head": 0.95, "jaw": true, "piercing": true, "holster": Color(0.45, 0.27, 0.14),
		"buckle": Color(0.2, 0.2, 0.22), "weapon_r": "sashimi", "weapon_l": "", "guard": "baek"},
	# ---- 11장 호텔 캐슬 (S2) — 근거는 같은 canon look 글(conf ai)
	#  피우진: 큰 키 · 근육질 · 어깨 길이 검은 장발(싸울 땐 정수리 상투) · 왼뺨~콧등 흉터 · 귀 피어싱 · 검은 정장 · 흰 셔츠 ·
	#          검은 사각 선글라스 · 맨주먹
	"woojin": {"suit": Color(0.14, 0.14, 0.17), "pants": Color(0.12, 0.12, 0.15), "shirt": Color(0.92, 0.92, 0.93),
		"skin": Color(0.88, 0.74, 0.62), "hair": Color(0.08, 0.08, 0.1), "hair_style": "topknot", "glasses": "sun",
		"big": false, "scale": 1.06, "shoulder": 1.1, "depth": 1.15, "limb": 1.2, "head": 0.92, "jaw": true,
		"scar": true, "piercing": true, "buckle": Color(0.2, 0.2, 0.22), "weapon_r": "", "weapon_l": "", "guard": "box"},
	#  구일화: 근육질 거구 · 곱슬 웨이브 흑발(뒤로 묶음) · 턱수염 · 색안경(보라 렌즈 에비에이터) · 검은 정장 · 단추 푼 흰 셔츠 · 금 체인
	"guilhwa": {"suit": Color(0.12, 0.12, 0.14), "pants": Color(0.11, 0.11, 0.13), "shirt": Color(0.9, 0.9, 0.9),
		"skin": Color(0.85, 0.7, 0.56), "hair": Color(0.07, 0.07, 0.08), "hair_style": "wavy_back", "glasses": "aviator",
		"lens": Color(0.45, 0.25, 0.6), "beard": true, "big": true, "scale": 1.12, "wide": 1.25, "depth": 1.3, "limb": 1.3,
		"head": 0.95, "jaw": true, "chain": Color(0.95, 0.75, 0.25), "weapon_r": "", "weapon_l": "", "guard": "box"},
	#  캐슬 경호원(엑스트라 — 057 경호대 정장): 검은 정장 · 흰 셔츠 · 넥타이 · 짧은 머리 · 곤봉
	"guard": {"suit": Color(0.1, 0.1, 0.12), "pants": Color(0.1, 0.1, 0.12), "shirt": Color(0.88, 0.88, 0.9),
		"tie": Color(0.06, 0.06, 0.08), "skin": Color(0.86, 0.72, 0.6), "hair": Color(0.09, 0.09, 0.1), "hair_style": "short",
		"big": false, "scale": 1.02, "limb": 1.1, "weapon_r": "baton", "weapon_l": "", "guard": "box"},
	#  경호대 최후의 4인: 넷 다 거구 · 검은 정장 · 흰 셔츠 · 넥타이, 중심 인물은 희끗한 짧은 크루컷(058/039-045). 칼 · 권총
	"g4": {"suit": Color(0.07, 0.07, 0.09), "pants": Color(0.07, 0.07, 0.09), "shirt": Color(0.9, 0.9, 0.92),
		"tie": Color(0.05, 0.05, 0.06), "skin": Color(0.86, 0.72, 0.6), "hair": Color(0.08, 0.08, 0.09), "hair_style": "short",
		"big": true, "scale": 1.14, "wide": 1.25, "depth": 1.3, "limb": 1.3, "head": 0.95, "jaw": true,
		"weapon_r": "tanto", "weapon_l": "pistol", "grip_l": "fwd", "guard": "baek"},
	"g4_leader": {"suit": Color(0.07, 0.07, 0.09), "pants": Color(0.07, 0.07, 0.09), "shirt": Color(0.9, 0.9, 0.92),
		"tie": Color(0.05, 0.05, 0.06), "skin": Color(0.84, 0.7, 0.58), "hair": Color(0.62, 0.62, 0.64), "hair_style": "crew",
		"big": true, "scale": 1.2, "wide": 1.3, "depth": 1.35, "limb": 1.35, "head": 0.95, "jaw": true,
		"weapon_r": "tanto", "weapon_l": "pistol", "grip_l": "fwd", "guard": "baek"},
	#  하야부사: 웨이브 진 검은 곱슬머리를 뒤로 넘김(목덜미까지) · 흰 피부 · 흰(밝은 회색) 정장 · 검은 셔츠 · 검은 넥타이 · 카타나
	"hayabusa": {"suit": Color(0.74, 0.74, 0.76), "pants": Color(0.72, 0.72, 0.74), "shirt": Color(0.08, 0.08, 0.09),
		"tie": Color(0.04, 0.04, 0.05), "skin": Color(0.95, 0.85, 0.76), "hair": Color(0.06, 0.06, 0.07),
		"hair_style": "wavy_back", "big": false, "scale": 1.04, "limb": 1.05, "head": 0.92,
		"weapon_r": "katana", "weapon_l": "", "guard": "long"},
	#  사사키 신겐: 하얗게 곤두선 스파이크 백발 · 구릿빛 피부 · 짧은 턱수염 · 콧수염 · 가는 눈 · 거구 · 흰 세로줄 정장 · 흰 셔츠 ·
	#              적갈색 넥타이 · 흰 바지 · 긴 칼(대극) · 츠바 달린 단도
	"shingen": {"suit": Color(0.76, 0.76, 0.78), "pants": Color(0.74, 0.74, 0.76), "shirt": Color(0.86, 0.86, 0.88),
		"tie": Color(0.5, 0.14, 0.1), "skin": Color(0.72, 0.52, 0.36), "hair": Color(0.95, 0.95, 0.96), "hair_style": "spiky",
		"beard": true, "eye_h": 0.007, "big": true, "scale": 1.18, "wide": 1.25, "depth": 1.3, "limb": 1.3, "head": 0.95,
		"jaw": true, "weapon_r": "tachi", "weapon_l": "tanto", "grip_l": "fwd", "guard": "long"},
	# ---- 0 · 1장(S5 묶음 2 · 3) — 뼈대: 자리만(외형은 다음 커밋에서 canon look 글로)
	"gunter_suit": {"suit": Color(0.1, 0.1, 0.12), "pants": Color(0.1, 0.1, 0.12), "shirt": Color(0.88, 0.88, 0.9), "tie": Color(0.06, 0.06, 0.08), "skin": Color(0.86, 0.72, 0.6), "hair": Color(0.09, 0.09, 0.1), "hair_style": "short", "big": false, "scale": 1.02, "limb": 1.1, "weapon_r": "", "weapon_l": "", "guard": "box"},
	"gunter_bald": {"suit": Color(0.1, 0.1, 0.12), "pants": Color(0.1, 0.1, 0.12), "shirt": Color(0.88, 0.88, 0.9), "tie": Color(0.06, 0.06, 0.08), "skin": Color(0.86, 0.72, 0.6), "hair": Color(0.09, 0.09, 0.1), "hair_style": "short", "big": false, "scale": 1.04, "limb": 1.1, "weapon_r": "pistol", "weapon_l": "", "guard": "box"},
	"gunter_uzi": {"suit": Color(0.1, 0.1, 0.12), "pants": Color(0.1, 0.1, 0.12), "shirt": Color(0.88, 0.88, 0.9), "tie": Color(0.06, 0.06, 0.08), "skin": Color(0.86, 0.72, 0.6), "hair": Color(0.09, 0.09, 0.1), "hair_style": "short", "big": false, "scale": 1.02, "limb": 1.1, "weapon_r": "pistol", "weapon_l": "", "guard": "box"},
	"gunter_brute": {"suit": Color(0.1, 0.1, 0.12), "pants": Color(0.1, 0.1, 0.12), "shirt": Color(0.88, 0.88, 0.9), "tie": Color(0.06, 0.06, 0.08), "skin": Color(0.86, 0.72, 0.6), "hair": Color(0.09, 0.09, 0.1), "hair_style": "short", "big": true, "scale": 1.14, "limb": 1.1, "weapon_r": "", "weapon_l": "", "guard": "box"},
	"gunter": {"suit": Color(0.1, 0.1, 0.12), "pants": Color(0.1, 0.1, 0.12), "shirt": Color(0.88, 0.88, 0.9), "tie": Color(0.06, 0.06, 0.08), "skin": Color(0.86, 0.72, 0.6), "hair": Color(0.09, 0.09, 0.1), "hair_style": "short", "big": false, "scale": 1.0, "limb": 1.1, "weapon_r": "pistol", "weapon_l": "", "guard": "box"},
	"ds_suit": {"suit": Color(0.1, 0.1, 0.12), "pants": Color(0.1, 0.1, 0.12), "shirt": Color(0.88, 0.88, 0.9), "tie": Color(0.06, 0.06, 0.08), "skin": Color(0.86, 0.72, 0.6), "hair": Color(0.09, 0.09, 0.1), "hair_style": "short", "big": false, "scale": 1.02, "limb": 1.1, "weapon_r": "", "weapon_l": "", "guard": "box"},
	"ds_raider": {"suit": Color(0.1, 0.1, 0.12), "pants": Color(0.1, 0.1, 0.12), "shirt": Color(0.88, 0.88, 0.9), "tie": Color(0.06, 0.06, 0.08), "skin": Color(0.86, 0.72, 0.6), "hair": Color(0.09, 0.09, 0.1), "hair_style": "short", "big": false, "scale": 1.02, "limb": 1.1, "weapon_r": "baton", "weapon_l": "", "guard": "box"},
	"jintae": {"suit": Color(0.1, 0.1, 0.12), "pants": Color(0.1, 0.1, 0.12), "shirt": Color(0.88, 0.88, 0.9), "tie": Color(0.06, 0.06, 0.08), "skin": Color(0.86, 0.72, 0.6), "hair": Color(0.09, 0.09, 0.1), "hair_style": "short", "big": false, "scale": 1.02, "limb": 1.1, "weapon_r": "", "weapon_l": "", "guard": "box"},
	"kimhyeokju": {"suit": Color(0.1, 0.1, 0.12), "pants": Color(0.1, 0.1, 0.12), "shirt": Color(0.88, 0.88, 0.9), "tie": Color(0.06, 0.06, 0.08), "skin": Color(0.86, 0.72, 0.6), "hair": Color(0.09, 0.09, 0.1), "hair_style": "short", "big": false, "scale": 1.0, "limb": 1.1, "weapon_r": "tanto", "weapon_l": "", "guard": "box"},
	"kimseongjun": {"suit": Color(0.1, 0.1, 0.12), "pants": Color(0.1, 0.1, 0.12), "shirt": Color(0.88, 0.88, 0.9), "tie": Color(0.06, 0.06, 0.08), "skin": Color(0.86, 0.72, 0.6), "hair": Color(0.09, 0.09, 0.1), "hair_style": "short", "big": false, "scale": 1.04, "limb": 1.1, "weapon_r": "tanto", "weapon_l": "", "guard": "box"},
	"kimdaegeon": {"suit": Color(0.1, 0.1, 0.12), "pants": Color(0.1, 0.1, 0.12), "shirt": Color(0.88, 0.88, 0.9), "tie": Color(0.06, 0.06, 0.08), "skin": Color(0.86, 0.72, 0.6), "hair": Color(0.09, 0.09, 0.1), "hair_style": "short", "big": true, "scale": 1.12, "limb": 1.1, "weapon_r": "", "weapon_l": "", "guard": "box"},
	"gangmanjae": {"suit": Color(0.1, 0.1, 0.12), "pants": Color(0.1, 0.1, 0.12), "shirt": Color(0.88, 0.88, 0.9), "tie": Color(0.06, 0.06, 0.08), "skin": Color(0.86, 0.72, 0.6), "hair": Color(0.09, 0.09, 0.1), "hair_style": "short", "big": true, "scale": 1.16, "limb": 1.1, "weapon_r": "", "weapon_l": "", "guard": "box"},
	"yundeoksu": {"suit": Color(0.1, 0.1, 0.12), "pants": Color(0.1, 0.1, 0.12), "shirt": Color(0.88, 0.88, 0.9), "tie": Color(0.06, 0.06, 0.08), "skin": Color(0.86, 0.72, 0.6), "hair": Color(0.09, 0.09, 0.1), "hair_style": "short", "big": true, "scale": 1.2, "limb": 1.1, "weapon_r": "", "weapon_l": "", "guard": "box"},
	"kim_bare": {"suit": Color(0.16, 0.16, 0.2), "pants": Color(0.13, 0.13, 0.17), "shirt": Color(0.93, 0.93, 0.94), "tie": Color(0.09, 0.09, 0.12), "skin": Color(0.91, 0.77, 0.65), "hair": Color(0.11, 0.11, 0.15), "hair_style": "slick_fringe", "glasses": false, "big": false, "scale": 1.04, "shoulder": 1.12, "eye_h": 0.007, "depth": 1.1, "limb": 1.15, "head": 0.9, "brow_tilt": 12.0, "jaw": true, "scar": true, "piercing": true, "badge": Color(0.95, 0.75, 0.25), "buckle": Color(0.82, 0.84, 0.88), "weapon_r": "", "weapon_l": "", "guard": "box"},
}

## 그림 A · B 가 있는 인물(S3 — 김신 · 신겐, 기획서 03 5절 '시험 범위 2명')
const ART := {
	"kim": {"glb": "res://assets/models/kimshin_a.glb", "dots": "res://assets/sprites/kimshin_b"},
	"shingen": {"glb": "res://assets/models/shingen_a.glb", "dots": "res://assets/sprites/shingen_b"},
	"kim_bare": {"glb": "res://assets/models/kimshin_a.glb", "dots": "res://assets/sprites/kimshin_b"},   # 0 · 1장 맨손 김신 — 몸은 같은 GLB, 무기만 없음
}


## 외형 이름 → 표. "<이름>_a" · "<이름>_b" 는 그 인물 외형 + 그림 A(GLB) · B(도트) 자리
static func look(name: String) -> Dictionary:
	var base := name.trim_suffix("_a").trim_suffix("_b")
	var lk: Dictionary = LOOKS.get(base, LOOKS["guard"]).duplicate()     # 표에 없는 외형은 경호원(시험 test_campaign 이 본다)
	if base == name:
		return lk
	if ART.has(base):
		lk.merge(ART[base], true)
	return lk


static func has_art(name: String) -> bool:
	return ART.has(name)
