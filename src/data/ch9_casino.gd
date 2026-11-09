extends RefCounted
## 9장 백의 사무실 · 클럽 부다페스트 · 선박 카지노(2부 15-32) 장 표 — 칸 뜻은 ch3_busan.gd 와 같다. 조작: 김신 / 서진태.
## 흐름(castle_common canon fights — 화/컷, conf ai 판독):
##   1 백의 사무실 복도(fight:hwajin_baekui_corridor 016) — 화진 습격조가 사무실을 친다 — 김신 · 똘배(아군)
##   2 CLUB BUDAPEST(fight:jintae_clubbudapest 019-022) — 서진태 대 바이슨 · 판테라
##   3 왕하오밍 선박 카지노 2층(fight:jintae_sacheonwang 025-028) — 서진태 대 사천왕 앤디청 · 은보
##   4 붉은 기둥 회랑(fight:jintae_jokki 031-032) — 서진태 대 리천(톱) · 라텔 — 지는 싸움 → 퇴각(따돌리기 escape, 진행 retreat:richeon)
##   5 끝
## 원작과 다른 점: 아킬라 · 그롤라(부다페스트)는 대사로만. 구로다 저택(신겐 017)은 신겐이 혼자 하는 싸움이라 대사로만.

const EVENT := "beat:mark"            # 시점: 8장 뒤 — 피우진 준10강
const PERIOD := "hwajin"

const CANON := {
	"baekui_office": {"fight": "fight:hwajin_baekui_corridor", "place": "baekui_office"},
	"club_budapest": {"fight": "fight:jintae_clubbudapest", "place": "clubbudapest"},
	"casino_floor": {"fight": "fight:jintae_sacheonwang", "place": "hongkong"},
	"red_corridor": {"fight": "fight:jintae_jokki", "place": "hongkong"},
	"retreat_end": {"fight": "", "place": "hongkong"},
}

const HEROES := ["kimshin", "jintae"]
const LINES := "ch9"
const CROWD_ID := "street_thug"

const ROLES := {
	"kimshin": {"hp": 200.0, "posture": 60.0, "walk": 2.1, "run": 4.6, "stagger": 50, "look": "kim",
		"moveset": {"combo": "k_slash1", "dash": "k_dash", "counter": "k_counter", "finisher": "k_finisher"}},
	"jintae": {"hp": 230.0, "posture": 70.0, "walk": 2.2, "run": 4.8, "stagger": 50, "look": "jintae",
		"moveset": {"combo": "jk_slash1", "dash": "jk_dash", "finisher": "jk_finisher"}},
	"ttolbae": {"hp": 200.0, "posture": 60.0, "walk": 2.0, "run": 4.2, "stagger": 60, "look": "ttolbae",
		"moveset": {"combo": "ny_jab", "dash": "ny_dash", "finisher": "ny_finisher"}},
	"street_thug": {"hp": 220.0, "posture": 45.0, "walk": 1.8, "run": 3.8, "stagger": 70, "ai": "thug", "look": "ds_raider"},
	"gang_blade": {"hp": 260.0, "posture": 50.0, "walk": 1.9, "run": 4.0, "stagger": 70, "ai": "haseong_guard", "look": "haseong_guard"},
	"pro_fighter": {"hp": 420.0, "posture": 120.0, "walk": 2.0, "run": 4.3, "stagger": 75, "poise": 10.0, "ai": "x_kicker", "look": "gunter_bald"},
	"bison": {"hp": 420.0, "posture": 240.0, "walk": 1.9, "run": 4.1, "stagger": 80, "poise": 30.0, "finisher_cap": 0.08, "ai": "x_grappler",
		"look": "bison", "phase2_at": 0.5, "dmg_k": 0.9},
	"pantera": {"hp": 260.0, "posture": 120.0, "walk": 2.2, "run": 4.8, "stagger": 70, "poise": 12.0, "ai": "x_kicker", "look": "pantera", "dmg_k": 0.8},
	"andycheong": {"hp": 380.0, "posture": 240.0, "walk": 2.1, "run": 4.6, "stagger": 75, "poise": 28.0, "finisher_cap": 0.06, "ai": "x_kicker",
		"look": "andycheong", "phase2_at": 0.5, "dmg_k": 0.8},
	"eunbo": {"hp": 280.0, "posture": 140.0, "walk": 1.8, "run": 3.9, "stagger": 75, "poise": 16.0, "ai": "x_grappler", "look": "eunbo", "dmg_k": 0.7},
	# 리천(톱): 쓰러뜨릴 수 없다(hp_floor) — 퇴각 방
	"richeon": {"hp": 3000.0, "posture": 900.0, "walk": 2.1, "run": 4.6, "stagger": 80, "poise": 40.0, "finisher_cap": 0.02, "ai": "x_master",
		"look": "richeon", "hp_floor": 0.6, "dmg_k": 0.9},
	"ratel": {"hp": 300.0, "posture": 140.0, "walk": 2.1, "run": 4.6, "stagger": 75, "poise": 14.0, "ai": "x_karambit", "look": "ratel", "dmg_k": 0.6},
}

const ROOMS := [
	{"id": "baekui_office", "theme": "office_corridor", "bounds": Rect2(-7.0, -2.0, 14.0, 4.0), "cast": ["kimshin"],
		"heroes": [Vector2(-5.2, 0.0)], "allies": [["ttolbae", Vector2(-4.4, 1.2)]],
		"enemies": [["street_thug", Vector2(-0.4, -1.2), {"name": "화진 습격조"}], ["gang_blade", Vector2(0.6, 1.2), {"name": "화진 습격조"}],
			["street_thug", Vector2(1.8, -0.4), {"name": "화진 습격조"}], ["gang_blade", Vector2(3.0, 1.0), {"name": "화진 습격조"}],
			["pro_fighter", Vector2(4.4, -0.6), {"name": "꽁지머리 사내", "hp_k": 3.0}]], "boss": "pro_fighter"},
	{"id": "club_budapest", "theme": "club_budapest", "bounds": Rect2(-6.0, -2.4, 12.0, 4.8), "cast": ["jintae"],
		"heroes": [Vector2(-4.0, 0.2)], "allies": [],
		"enemies": [["pantera", Vector2(1.2, -1.2)], ["bison", Vector2(2.8, 0.6)]], "boss": "bison"},
	{"id": "casino_floor", "theme": "casino_deck", "bounds": Rect2(-6.4, -2.4, 12.8, 4.8), "cast": ["jintae"],
		"heroes": [Vector2(-4.2, 0.2)], "allies": [],
		"enemies": [["eunbo", Vector2(1.0, 1.4)], ["andycheong", Vector2(2.8, -0.6)]], "boss": "andycheong"},
	{"id": "red_corridor", "theme": "casino_deck", "bounds": Rect2(-7.0, -2.0, 14.0, 4.0), "cast": ["jintae"],
		"heroes": [Vector2(-5.4, 0.0)], "allies": [],
		"enemies": [["richeon", Vector2(-0.6, 0.2)], ["ratel", Vector2(1.8, -1.2)]], "boss": "richeon",
		"escape": {"secs": 12.0, "exit": Rect2(5.6, -2.0, 1.4, 4.0)}},
	{"id": "retreat_end", "theme": "casino_deck", "bounds": Rect2(-5.0, -2.0, 10.0, 4.0), "cast": ["jintae"],
		"heroes": [Vector2(-1.6, 0.4)], "allies": [], "enemies": [], "boss": "", "end": true},
]

const INTRO_T := 75
const CLEAR_T := 150
const END_T := 360
const HEAL_ON_CLEAR := 0.25
const MAX_ATTACKERS := 2
