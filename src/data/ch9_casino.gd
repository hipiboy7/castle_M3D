extends RefCounted
## 9장 백의 사무실 · 클럽 부다페스트 · 선박 카지노(2부 15-32) 장 표 — 칸 뜻은 ch3_busan.gd 와 같다. 조작: 똘배 / 김신 / 서진태(방마다 한 사람).
## 편(2026-11-10 다시 맞춤 — castle_common canon fights · characters status): 백의(김신 · 서진태 · 똘배 · 표영) + **이스크라(라텔 · 크리사 ·
## 크로트 — 서진태(사로카)를 빼내러 온 우리 편)** 대 화진(유우성 = 롱터우 · 앤디청 · 습격조) · 왕하오밍의 사천왕(민머리 거한 · 은보) · 리천(톱).
## 클럽 부다페스트의 바이슨 · 판테라(뜨거운피 · 그롤라 쪽)는 서진태와 맞붙지만 이스크라의 아킬라가 룰로 멈춘다.
## 흐름(castle_common canon fights — 화/컷, conf ai 판독):
##   1 백의 사무실 복도(fight:hwajin_baekui_corridor 016/003-007) — 화진이 하룻밤 만에 사무실 층을 장악 — 똘배가 꽁지머리 베이지 코트 사내
##     (초승달 쌍날)에게 돌진한다. 롱터우(유우성)의 철수 명령으로 화진이 물러난다(yield)
##   2 보스실(016/005-008) — 대화: 김신이 유우성의 손을 거절('이 방에는 너하고 나 둘 뿐이다') → 유우성이 잔을 으스러뜨리고 철수
##   3 CLUB BUDAPEST(fight:jintae_clubbudapest 019-022) — 서진태 대 녹색 셔츠 칼잡이 → 판테라 · 바이슨 — 결착 없음: 아킬라가 룰을 내세워 멈춘다(yield)
##   4 왕하오밍 선박 카지노(fight:jintae_sacheonwang 025-027 · fight:pyoyoung_sacheonwang 027) — 서진태 대 사천왕 민머리 거한 · 은보 →
##     화진 앤디청(쌍 갈고리) 일대일, 표영(아군)은 바가지 머리 사천왕을 맡는다
##   5 붉은 기둥 회랑(fight:jintae_jokki 031-032 · fight:pyoyoung_jokki 028-031) — 리천(톱 · 조끼 남자)이 표영 · 라텔 · 크리사를 차례로 눕힌 뒤
##     서진태가 맞선다 — 지는 싸움: 라텔이 서진태를 끌어안아 빼낸다 → 따돌리기(escape, 진행 retreat:richeon)
##   6 끝 — 유우성이 크리사를 처형하고 판을 정리한다(fight:sikkal_talchul — 대사로)
## 원작과 다른 점: 1 방은 원작에서 똘배가 꽁지머리에게 제압당한 채 화진이 철수한다 — 이 판은 버티면(yield) 화진이 물러난다.
## 3 방 그롤라 · 아킬라, 4 방 왕하오밍, 5 방 크리사 · 크로트 · 유우성 추격(028-030)은 대사로만. 구로다 저택(신겐 017)은 신겐 혼자의 싸움이라 대사로만.

const EVENT := "beat:mark"            # 시점: 8장 뒤 — 피우진 준10강
const PERIOD := "hwajin"

const CANON := {
	"baekui_office": {"fight": "fight:hwajin_baekui_corridor", "place": "baekui_office"},
	"boss_room": {"fight": "", "place": "baekui_office"},
	"club_budapest": {"fight": "fight:jintae_clubbudapest", "place": "clubbudapest"},
	"casino_floor": {"fight": "fight:jintae_sacheonwang", "place": "hongkong"},
	"red_corridor": {"fight": "fight:jintae_jokki", "place": "hongkong"},
	"retreat_end": {"fight": "", "place": "hongkong"},
}

const HEROES := ["ttolbae", "kimshin", "jintae"]
const LINES := "ch9"
const CROWD_ID := "street_thug"

const ROLES := {
	"kimshin": {"hp": 200.0, "posture": 60.0, "walk": 2.1, "run": 4.6, "stagger": 50, "look": "kim",
		"moveset": {"combo": "k_slash1", "dash": "k_dash", "counter": "k_counter", "finisher": "k_finisher"}},
	"jintae": {"hp": 230.0, "posture": 70.0, "walk": 2.2, "run": 4.8, "stagger": 50, "look": "jintae",
		"moveset": {"combo": "jk_slash1", "dash": "jk_dash", "finisher": "jk_finisher"}},
	"ttolbae": {"hp": 320.0, "posture": 80.0, "walk": 2.0, "run": 4.2, "stagger": 55, "look": "ttolbae",
		"moveset": {"combo": "ny_jab", "dash": "ny_dash", "finisher": "ny_finisher"}},
	# 아군: 표영(카지노 — 바가지 머리 사천왕을 이긴다 027) · 라텔(이스크라 — 서진태를 빼낸다 032)
	"pyoyoung": {"hp": 240.0, "posture": 70.0, "walk": 2.3, "run": 5.0, "stagger": 50, "look": "pyoyoung",
		"moveset": {"combo": "py_slash1", "dash": "py_dash", "finisher": "py_finisher"}},
	"ratel": {"hp": 240.0, "posture": 80.0, "walk": 2.2, "run": 4.8, "stagger": 50, "look": "ratel",
		"moveset": {"combo": "py_slash1", "dash": "py_dash", "finisher": "py_finisher"}},
	"street_thug": {"hp": 220.0, "posture": 45.0, "walk": 1.8, "run": 3.8, "stagger": 70, "ai": "thug", "look": "ds_raider"},
	"gang_blade": {"hp": 260.0, "posture": 50.0, "walk": 1.9, "run": 4.0, "stagger": 70, "ai": "haseong_guard", "look": "haseong_guard"},
	"pro_fighter": {"hp": 420.0, "posture": 120.0, "walk": 2.0, "run": 4.3, "stagger": 75, "poise": 10.0, "ai": "x_kicker", "look": "gunter_bald"},
	"gang_brute": {"hp": 340.0, "posture": 70.0, "walk": 1.7, "run": 3.6, "stagger": 75, "ai": "thug_brute", "look": "gunter_brute"},
	# 꽁지머리 베이지 코트 사내(화진 — 초승달 쌍날 016/004): 1층은 격투가(pro_fighter), 방 표 덧붙임 role 로 이 칸. 롱터우 명령으로 철수(yield)
	"hwajin_twin": {"hp": 300.0, "posture": 180.0, "walk": 2.1, "run": 4.6, "stagger": 75, "poise": 18.0, "finisher_cap": 0.08, "ai": "x_twin",
		"look": "gunter_bald", "yield_at": 0.35, "dmg_k": 0.5},
	"bison": {"hp": 420.0, "posture": 240.0, "walk": 1.9, "run": 4.1, "stagger": 80, "poise": 30.0, "finisher_cap": 0.08, "ai": "x_grappler",
		"look": "bison", "phase2_at": 0.6, "yield_at": 0.3, "dmg_k": 0.9},     # 아킬라가 룰로 멈춘다(022) — yield
	"pantera": {"hp": 260.0, "posture": 120.0, "walk": 2.2, "run": 4.8, "stagger": 70, "poise": 12.0, "ai": "x_kicker", "look": "pantera", "dmg_k": 0.8},
	"andycheong": {"hp": 380.0, "posture": 240.0, "walk": 2.1, "run": 4.6, "stagger": 75, "poise": 28.0, "finisher_cap": 0.06, "ai": "x_twin",
		"look": "andycheong", "phase2_at": 0.5, "dmg_k": 0.8},
	"eunbo": {"hp": 280.0, "posture": 140.0, "walk": 1.8, "run": 3.9, "stagger": 75, "poise": 16.0, "ai": "x_grappler", "look": "eunbo", "dmg_k": 0.7},
	# 리천(톱): 쓰러뜨릴 수 없다(hp_floor) — 퇴각 방
	"richeon": {"hp": 3000.0, "posture": 900.0, "walk": 2.1, "run": 4.6, "stagger": 80, "poise": 40.0, "finisher_cap": 0.02, "ai": "x_master",
		"look": "richeon", "hp_floor": 0.6, "dmg_k": 0.9},
}

const ROOMS := [
	{"id": "baekui_office", "theme": "office_corridor", "bounds": Rect2(-7.0, -2.0, 14.0, 4.0), "cast": ["ttolbae"],
		"heroes": [Vector2(-5.2, 0.0)], "allies": [],
		"enemies": [["street_thug", Vector2(-0.4, -1.2), {"name": "화진 조직원"}], ["street_thug", Vector2(1.0, 1.2), {"name": "화진 조직원"}],
			["street_thug", Vector2(2.4, -0.2), {"name": "화진 칼잡이"}],
			["pro_fighter", Vector2(4.4, -0.6), {"role": "hwajin_twin", "name": "꽁지머리 사내"}]], "boss": "pro_fighter"},
	{"id": "boss_room", "theme": "busan_office", "bounds": Rect2(-5.0, -2.0, 10.0, 4.0), "cast": ["kimshin"], "talk": 0.0,
		"heroes": [Vector2(-1.0, 0.4)], "allies": [], "enemies": []},
	{"id": "club_budapest", "theme": "club_budapest", "bounds": Rect2(-6.0, -2.4, 12.0, 4.8), "cast": ["jintae"],
		"heroes": [Vector2(-4.0, 0.2)], "allies": [],
		"enemies": [["gang_blade", Vector2(0.2, 1.4), {"name": "녹색 셔츠 칼잡이"}], ["pantera", Vector2(1.6, -1.2)], ["bison", Vector2(3.0, 0.6)]],
		"boss": "bison"},
	{"id": "casino_floor", "theme": "casino_deck", "bounds": Rect2(-6.4, -2.4, 12.8, 4.8), "cast": ["jintae"],
		"heroes": [Vector2(-4.2, 0.2)], "allies": [["pyoyoung", Vector2(-4.6, 1.6)]],
		"enemies": [["gang_brute", Vector2(0.4, -1.2), {"name": "사천왕 민머리 거한"}], ["eunbo", Vector2(1.0, 1.4)],
			["pro_fighter", Vector2(1.8, 1.8), {"name": "바가지 머리 사천왕"}], ["andycheong", Vector2(3.2, -0.6)]], "boss": "andycheong"},
	{"id": "red_corridor", "theme": "casino_deck", "bounds": Rect2(-7.0, -2.0, 14.0, 4.0), "cast": ["jintae"],
		"heroes": [Vector2(-5.4, 0.0)], "allies": [["ratel", Vector2(-5.8, 1.2)]],
		"enemies": [["richeon", Vector2(-0.6, 0.2)], ["street_thug", Vector2(1.8, -1.2), {"name": "흰 셔츠 사내"}],
			["street_thug", Vector2(2.4, 1.2), {"name": "흰 셔츠 사내"}]], "boss": "richeon",
		"escape": {"secs": 12.0, "exit": Rect2(5.6, -2.0, 1.4, 4.0)}},
	{"id": "retreat_end", "theme": "casino_deck", "bounds": Rect2(-5.0, -2.0, 10.0, 4.0), "cast": ["jintae"],
		"heroes": [Vector2(-1.6, 0.4)], "allies": [], "enemies": [], "boss": "", "end": true},
]

const INTRO_T := 75
const CLEAR_T := 150
const END_T := 360
const HEAL_ON_CLEAR := 0.25
const MAX_ATTACKERS := 2
