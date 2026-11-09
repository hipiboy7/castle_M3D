extends RefCounted
## 12장 교회 비전센터 · 공사장 · 지하(2부 70-126 — 기획서 02 3절 12-1 ~ 12-3) 장 표 — 칸 뜻은 ch3_busan.gd 와 같다.
## 조작: 김신 / 피우진 / 서진태(방마다 cast — 둘이 나오는 방은 교대).
## 흐름(castle_common canon fights — 화/컷, conf ai 판독):
##   1 교회 비전센터 빗속 마당(fight:kimshin_majunyeong 078-087) — 김신 대 마준영 · 교회 경호대 — 결착 없음 → 물러남(yield)
##   2 녹색 조명 사무실층(fight:kimshin_gustav 071-074) — 김신 대 구스타프 — 공중 뒤집기 내리찍기 → 스테인드글라스 밖으로
##   3 교회 건물 안 복도(fight:kimshin_shingen_gyohoe 100-102) — 김신 · 피우진 대 신겐 — 장도리 못뽑이(김신 승)
##   4 녹색 조명 공사장(fight:kimshin_grolla 088-093) — 김신 · 피우진 대 그롤라 — 시멘트 통에 얼굴을
##   5 교회 지하 1층 복도(fight:jiha1cheung_bokdo 109-115) — 김신 · 서진태 대 엄지 · 검지 · 최혁진
##   6 교회 지하 주차장(fight:kimshin_mahakyoung 104-126) — 김신 대 마학영(톱 — 최종 보스, 권총 · 방패 · 단검)
##   7 끝
## 원작과 다른 점: 피우진 대 신겐(fight:shingen 097-100 — 신겐 승, 진행 fight:shingen)은 3 의 교대로 합쳤다. 리사(woojin_risa)는
## story 12장에 아직 없어(기획서 02) 뺐다. 스카이 브리지(seukaibeuriji)는 대사로만.

const EVENT := "raid:castle_hotel"   # 시점: 11장 뒤 — 김신 재앙 · 피우진 외성 중위 · 서진태 내성 하위
const PERIOD := "church"

const CANON := {
	"church_yard": {"fight": "fight:kimshin_majunyeong", "place": "gyohoebijeonsenteo"},
	"green_office": {"fight": "fight:kimshin_gustav", "place": "gyohoe"},
	"church_hall": {"fight": "fight:kimshin_shingen_gyohoe", "place": "gyohoe"},
	"build_site": {"fight": "fight:kimshin_grolla", "place": "gyohoebijeonsenteo"},
	"basement": {"fight": "fight:jiha1cheung_bokdo", "place": "gyohoe_jiha1cheung_bokdo"},
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
	"majunyeong": {"hp": 2200.0, "posture": 700.0, "walk": 2.1, "run": 4.6, "stagger": 80, "poise": 38.0, "finisher_cap": 0.04, "ai": "x_grappler",
		"look": "majunyeong", "yield_at": 0.4, "dmg_k": 2.4},
	"gustav": {"hp": 1500.0, "posture": 560.0, "walk": 2.1, "run": 4.6, "stagger": 80, "poise": 38.0, "finisher_cap": 0.04, "ai": "x_master",
		"look": "gustav", "phase2_at": 0.5, "dmg_k": 1.8},
	"shingen": {"hp": 1600.0, "posture": 520.0, "walk": 1.95, "run": 4.2, "stagger": 80, "poise": 20.0, "finisher_cap": 0.06, "ai": "shingen",
		"look": "shingen", "phase2_at": 0.5, "dmg_k": 1.9},
	"grolla": {"hp": 1500.0, "posture": 560.0, "walk": 2.1, "run": 4.6, "stagger": 80, "poise": 36.0, "finisher_cap": 0.04, "ai": "x_master",
		"look": "grolla", "phase2_at": 0.5, "dmg_k": 1.8},
	"eomji": {"hp": 900.0, "posture": 320.0, "walk": 2.1, "run": 4.6, "stagger": 75, "poise": 28.0, "finisher_cap": 0.06, "ai": "x_karambit",
		"look": "eomji", "phase2_at": 0.5, "dmg_k": 1.8},
	"geomji": {"hp": 700.0, "posture": 260.0, "walk": 2.1, "run": 4.6, "stagger": 75, "poise": 24.0, "ai": "x_blade", "look": "geomji", "dmg_k": 1.6},
	"choehyeokjin": {"hp": 500.0, "posture": 200.0, "walk": 1.9, "run": 4.1, "stagger": 75, "poise": 20.0, "ai": "x_brawler", "look": "choehyeokjin", "dmg_k": 1.4},
	# 마학영(톱 — 최종 보스): 주먹 · 붙잡기 · 역수 단검 · 근거리 권총(x_gun — 거리를 두면 쏜다). 2차에 더 몰아친다
	"mahakyoung": {"hp": 2600.0, "posture": 900.0, "walk": 2.1, "run": 4.6, "stagger": 80, "poise": 40.0, "finisher_cap": 0.03, "ai": "x_gun",
		"look": "mahakyoung", "phase2_at": 0.5, "dmg_k": 2.3},
}

const ROOMS := [
	{"id": "church_yard", "theme": "church_yard", "bounds": Rect2(-6.6, -2.4, 13.2, 4.8), "cast": ["kimshin"],
		"heroes": [Vector2(-4.6, 0.2)], "allies": [],
		"enemies": [["elite_guard", Vector2(0.0, -1.6), {"name": "교회 경호대"}], ["elite_guard", Vector2(0.6, 1.6), {"name": "교회 경호대"}],
			["elite_guard", Vector2(1.8, -0.4), {"name": "교회 경호대"}], ["majunyeong", Vector2(3.6, 0.2)]], "boss": "majunyeong"},
	{"id": "green_office", "theme": "green_office", "bounds": Rect2(-6.0, -2.2, 12.0, 4.4), "cast": ["kimshin"],
		"heroes": [Vector2(-3.8, 0.2)], "allies": [],
		"enemies": [["gustav", Vector2(2.4, 0.0)]], "boss": "gustav"},
	{"id": "church_hall", "theme": "church_hall", "bounds": Rect2(-6.0, -2.4, 12.0, 4.8), "cast": ["woojin", "kimshin"],
		"heroes": [Vector2(-3.8, -0.6), Vector2(-4.2, 0.8)], "allies": [],
		"enemies": [["shingen", Vector2(2.4, 0.0)]], "boss": "shingen"},
	{"id": "build_site", "theme": "build_site", "bounds": Rect2(-6.4, -2.4, 12.8, 4.8), "cast": ["kimshin", "woojin"],
		"heroes": [Vector2(-4.0, -0.6), Vector2(-4.4, 0.8)], "allies": [],
		"enemies": [["grolla", Vector2(2.6, 0.0)]], "boss": "grolla"},
	{"id": "basement", "theme": "basement", "bounds": Rect2(-7.0, -2.0, 14.0, 4.0), "cast": ["kimshin", "jintae"],
		"heroes": [Vector2(-5.2, -0.6), Vector2(-5.4, 0.8)], "allies": [],
		"enemies": [["choehyeokjin", Vector2(0.6, 1.0)], ["geomji", Vector2(2.2, -1.0)], ["eomji", Vector2(3.8, 0.4)]], "boss": "eomji"},
	{"id": "parking", "theme": "parking", "bounds": Rect2(-6.4, -2.4, 12.8, 4.8), "cast": ["kimshin"],
		"heroes": [Vector2(-4.0, 0.2)], "allies": [],
		"enemies": [["mahakyoung", Vector2(2.6, 0.0)]], "boss": "mahakyoung"},
	{"id": "church_end", "theme": "church_yard", "bounds": Rect2(-5.0, -2.4, 10.0, 4.8), "cast": ["kimshin"],
		"heroes": [Vector2(-1.6, 0.4)], "allies": [], "enemies": [], "boss": "", "end": true},
]

const INTRO_T := 75
const CLEAR_T := 150
const END_T := 420
const HEAL_ON_CLEAR := 0.3
const MAX_ATTACKERS := 2
