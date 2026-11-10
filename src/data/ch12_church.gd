extends RefCounted
## 12장 교회 비전센터 · 공사장 · 지하(2부 70-126 — 기획서 02 3절 12-1 ~ 12-3, act:3 교회 대전) 장 표 — 칸 뜻은 ch3_busan.gd 와 같다.
## 조작: 김신 / 피우진 / 서진태(방마다 cast — 둘이 나오는 방은 교대).
## 대결 구도(castle_common canon — 2026-11-10 다시 맞춤): 김신(백의) · 반 야마구치 연합 대 최민욱의 카르텔 · 캐슬 홀딩스 경호대(마학영 · 마준영 ·
## 방패조). 구일화 · 최혁진은 백의(아군), 호텔 캐슬 암살조 '오른손'(엄지 · 검지)은 교회 안에서 따로 움직이다(111 summary) 125 하역장에서
## 백의에 등을 돌린다(factions castle_hotel — 김태훈의 실패 뒤).
## 흐름(castle_common canon fights — 화/컷):
##   1 녹색 조명 사무실층(fight:kimshin_gustav 071-074) — 김신 대 구스타프 — 공중 뒤집기 내리찍기 → 스테인드글라스 밖으로
##   2 교회 비전센터 빗속 마당(fight:kimshin_majunyeong 078-087) — 김신 대 마준영 · 경호대 방패조 — 결착 없음 → 물러남(yield)
##   3 녹색 조명 공사장(fight:kimshin_grolla 088-093 · fight:kimshin_majunyeong2 090-093) — 김신 · 피우진 대 그롤라 · 마준영(2차) — 김신 승
##   4 교회 건물 안 복도(fight:shingen 097-100 → fight:kimshin_shingen_gyohoe 100-102) — 피우진이 먼저(신겐 승), 김신이 이어받아 장도리 못뽑이
##   5 교회 지하 1층 복도(fight:jiha1cheung_bokdo 109-113) — 김신 · 구일화 · 최혁진(백의) 대 경호대 방패조
##   6 교회 쪽 하역장(fight:hotelcastle_baekui 125) — 피우진 대 호텔 캐슬 '오른손'(검지) — 주로가 '이 건은 여기서 끝낸다'(물러남 yield)
##   7 교회 지하 주차장(fight:kimshin_mahakyoung 104-126 — arc:jihajuchajang_mahakyoung) — 김신 · 서진태 대 마학영(톱 — 최종 보스)
##   8 끝
## 원작과 다른 점: 하역장(125)은 주차장 결착(124) 뒤의 일이지만 최종 보스 방을 마지막에 두려고 앞으로 당겼다. 서진태는 원작에서 주차장에서
## 마학영을 막다 숨진다(death:jintae 120) — 게임에서는 끝까지 교대 인물로 둔다. 리사(woojin_risa 118)는 기획서 02 대로 아직 뺐고,
## 엄지는 김신 쪽과 맞붙은 원작 싸움이 없어(juro_mahakyoung 은 엄지 대 마학영) 뺐다. 스카이 브리지(seukaibeuriji)는 대사로만.

const EVENT := "raid:castle_hotel"   # 시점: 11장 뒤 — 김신 재앙 · 피우진 외성 중위 · 서진태 내성 하위
const PERIOD := "church"

const CANON := {
	"green_office": {"fight": "fight:kimshin_gustav", "place": "gyohoe"},
	"church_yard": {"fight": "fight:kimshin_majunyeong", "place": "gyohoebijeonsenteo"},
	"build_site": {"fight": "fight:kimshin_grolla", "place": "gyohoebijeonsenteo"},
	"church_hall": {"fight": "fight:kimshin_shingen_gyohoe", "place": "gyohoe"},
	"basement": {"fight": "fight:jiha1cheung_bokdo", "place": "gyohoe_jiha1cheung_bokdo"},
	"loading_dock": {"fight": "fight:hotelcastle_baekui", "place": "gyohoe"},
	"parking": {"fight": "fight:kimshin_mahakyoung", "place": "gyohoe"},
	"church_end": {"fight": "", "place": "gyohoe"},
}

const HEROES := ["kimshin", "woojin", "jintae"]
const LINES := "ch12"
const CROWD_ID := "elite_guard"

const NPCS := {
	"geomji": {"rank": "내성 하위"},       # 강함표에 엄지만 — 짝 검지도 같은 급으로(3D 덧붙임)
}

const ROLES := {
	"kimshin": {"hp": 200.0, "posture": 60.0, "walk": 2.1, "run": 4.6, "stagger": 50, "look": "kim",
		"moveset": {"combo": "k_slash1", "dash": "k_dash", "counter": "k_counter", "finisher": "k_finisher"}},
	"woojin": {"hp": 220.0, "posture": 70.0, "walk": 2.1, "run": 4.6, "stagger": 50, "look": "woojin",
		"moveset": {"combo": "w_jab", "dash": "w_dash", "finisher": "w_finisher"}},
	"jintae": {"hp": 230.0, "posture": 70.0, "walk": 2.2, "run": 4.8, "stagger": 50, "look": "jintae",
		"moveset": {"combo": "jk_slash1", "dash": "jk_dash", "finisher": "jk_finisher"}},
	"elite_guard": {"hp": 300.0, "posture": 70.0, "walk": 1.9, "run": 4.1, "stagger": 70, "poise": 4.0, "ai": "haseong_guard", "look": "guard"},
	# 아군(백의): 구일화 · 최혁진 — 지하 1층 복도에서 방패조를 몸으로 밀어붙인다(109-112)
	"guilhwa": {"hp": 200.0, "posture": 80.0, "walk": 2.0, "run": 4.4, "stagger": 55, "look": "guilhwa",
		"moveset": {"combo": "gu_jab", "dash": "gu_dash", "finisher": "gu_finisher"}},
	"choehyeokjin": {"hp": 190.0, "posture": 70.0, "walk": 2.0, "run": 4.3, "stagger": 55, "look": "choehyeokjin",
		"moveset": {"combo": "ny_jab", "dash": "ny_dash", "finisher": "ny_finisher"}},
	"majunyeong": {"hp": 2200.0, "posture": 700.0, "walk": 2.1, "run": 4.6, "stagger": 80, "poise": 38.0, "finisher_cap": 0.04, "ai": "x_grappler",
		"look": "majunyeong", "yield_at": 0.4, "dmg_k": 2.4},
	# 마준영 2차(공사장 — 그롤라와 함께, 김신이 끝낸다 093/060): 방 표 덧붙임 role
	"majunyeong2": {"hp": 1100.0, "posture": 500.0, "walk": 2.1, "run": 4.6, "stagger": 80, "poise": 34.0, "finisher_cap": 0.05, "ai": "x_grappler",
		"look": "majunyeong", "dmg_k": 1.6},
	"gustav": {"hp": 1500.0, "posture": 560.0, "walk": 2.1, "run": 4.6, "stagger": 80, "poise": 38.0, "finisher_cap": 0.04, "ai": "x_master",
		"look": "gustav", "phase2_at": 0.5, "dmg_k": 1.35},
	"shingen": {"hp": 1600.0, "posture": 520.0, "walk": 1.95, "run": 4.2, "stagger": 80, "poise": 20.0, "finisher_cap": 0.06, "ai": "shingen",
		"look": "shingen", "phase2_at": 0.5, "dmg_k": 1.9},
	"grolla": {"hp": 1500.0, "posture": 560.0, "walk": 2.1, "run": 4.6, "stagger": 80, "poise": 36.0, "finisher_cap": 0.04, "ai": "x_master",
		"look": "grolla", "phase2_at": 0.5, "dmg_k": 1.8},
	# 검지(호텔 캐슬 '오른손' 멜빵 칼잡이 — 125 하역장에서 피우진을 칼로 누른다). 주로가 철수를 선언 → 물러남
	# (피우진 외성 중위가 아랫급 — 등급 차 피해 규칙 때문에 체력 · 피해를 낮게, 10장 도우첸처럼)
	"geomji": {"hp": 170.0, "posture": 220.0, "walk": 2.1, "run": 4.6, "stagger": 75, "poise": 24.0, "finisher_cap": 0.06, "ai": "x_blade", "look": "geomji",
		"yield_at": 0.35, "dmg_k": 0.45},
	# 마학영(톱 — 최종 보스): 주먹 · 붙잡기 · 역수 단검 · 근거리 권총(x_gun — 거리를 두면 쏜다). 2차에 더 몰아친다
	"mahakyoung": {"hp": 2600.0, "posture": 900.0, "walk": 2.1, "run": 4.6, "stagger": 80, "poise": 40.0, "finisher_cap": 0.03, "ai": "x_gun",
		"look": "mahakyoung", "phase2_at": 0.5, "dmg_k": 1.8},
}

const ROOMS := [
	{"id": "green_office", "theme": "green_office", "bounds": Rect2(-6.0, -2.2, 12.0, 4.4), "cast": ["kimshin"],
		"heroes": [Vector2(-3.8, 0.2)], "allies": [],
		"enemies": [["gustav", Vector2(2.4, 0.0)]], "boss": "gustav"},
	{"id": "church_yard", "theme": "church_yard", "bounds": Rect2(-6.6, -2.4, 13.2, 4.8), "cast": ["kimshin"],
		"heroes": [Vector2(-4.6, 0.2)], "allies": [],
		"enemies": [["elite_guard", Vector2(0.0, -1.6), {"name": "경호대 방패조"}], ["elite_guard", Vector2(0.6, 1.6), {"name": "경호대 방패조"}],
			["elite_guard", Vector2(1.8, -0.4), {"name": "경호대 방패조"}], ["majunyeong", Vector2(3.6, 0.2)]], "boss": "majunyeong"},
	{"id": "build_site", "theme": "build_site", "bounds": Rect2(-6.4, -2.4, 12.8, 4.8), "cast": ["kimshin", "woojin"],
		"heroes": [Vector2(-4.0, -0.6), Vector2(-4.4, 0.8)], "allies": [],
		"enemies": [["grolla", Vector2(2.6, -0.6)], ["majunyeong", Vector2(3.4, 1.0), {"role": "majunyeong2"}]], "boss": "grolla"},
	{"id": "church_hall", "theme": "church_hall", "bounds": Rect2(-6.0, -2.4, 12.0, 4.8), "cast": ["woojin", "kimshin"],
		"heroes": [Vector2(-3.8, -0.6), Vector2(-4.2, 0.8)], "allies": [],
		"enemies": [["shingen", Vector2(2.4, 0.0)]], "boss": "shingen"},
	{"id": "basement", "theme": "basement", "bounds": Rect2(-7.0, -2.0, 14.0, 4.0), "cast": ["kimshin"],
		"heroes": [Vector2(-5.2, 0.0)], "allies": [["guilhwa", Vector2(-4.4, -1.0)], ["choehyeokjin", Vector2(-4.6, 1.0)]],
		"enemies": [["elite_guard", Vector2(0.0, -1.2), {"name": "경호대 방패조"}], ["elite_guard", Vector2(0.6, 1.2), {"name": "경호대 방패조"}],
			["elite_guard", Vector2(1.8, 0.0), {"name": "경호대 방패조"}], ["elite_guard", Vector2(3.0, -1.2), {"name": "경호대 방패조"}],
			["elite_guard", Vector2(3.4, 1.2), {"name": "경호대 방패조"}], ["elite_guard", Vector2(4.6, 0.0), {"name": "경호대 방패조장", "hp_k": 2.5}]], "boss": ""},
	{"id": "loading_dock", "theme": "warehouse", "bounds": Rect2(-6.0, -2.4, 12.0, 4.8), "cast": ["woojin"],
		"heroes": [Vector2(-4.0, 0.2)], "allies": [],
		"enemies": [["elite_guard", Vector2(0.6, -1.4), {"name": "호텔 캐슬 조원", "hp_k": 0.6}], ["elite_guard", Vector2(1.0, 1.4), {"name": "호텔 캐슬 조원", "hp_k": 0.6}],
			["geomji", Vector2(2.8, 0.0)]], "boss": "geomji"},
	{"id": "parking", "theme": "parking", "bounds": Rect2(-6.4, -2.4, 12.8, 4.8), "cast": ["kimshin", "jintae"],
		"heroes": [Vector2(-4.0, -0.6), Vector2(-4.4, 0.8)], "allies": [],
		"enemies": [["mahakyoung", Vector2(2.6, 0.0)]], "boss": "mahakyoung"},
	{"id": "church_end", "theme": "church_yard", "bounds": Rect2(-5.0, -2.4, 10.0, 4.8), "cast": ["kimshin"],
		"heroes": [Vector2(-1.6, 0.4)], "allies": [], "enemies": [], "boss": "", "end": true},
]

const INTRO_T := 75
const CLEAR_T := 150
const END_T := 420
const HEAL_ON_CLEAR := 0.3
const MAX_ATTACKERS := 2
