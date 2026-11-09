extends RefCounted
## 13장 미술관 앞(2부 127-134) — 마지막 장. 칸 뜻은 ch3_busan.gd 와 같다. 조작: 김신(3 은 맨손 — 방 표 kit) · 피우진(1 교대).
## 흐름(castle_common canon fights — 화/컷, conf ai 판독):
##   1 미술관 앞 돌바닥 공터(fight:misulgwan_seupgyeok 127-128) — 김신 · 피우진 대 도학수 · 어광득
##   2 미술관(fight:kimshin_sainjin 134) — 김신 대 사인진 — 어깨 · 쇄골께 칼 찌르기
##   3 붉은 하늘 · 비 오는 공터(fight:jumeok_seungbu 129-134) — 김신(맨손) 대 피우진 — 맨손 주먹 승부(기획서 00 결정 3 · 프롤로그 001 의 예고)
##   4 맺음(대화 방) · 5 끝
## 원작과 다른 점: 주먹 승부의 끝(134/059 — 누가 누구를 쳤는지 컷만으로 불확정)은 김신 승으로. 도지웅은 대사로만.

const EVENT := "fight:shingen"       # 시점: 12장 뒤 — 피우진 외성 상위
const PERIOD := "church"

const CANON := {
	"museum_plaza": {"fight": "fight:misulgwan_seupgyeok", "place": "misulgwan"},
	"museum_front": {"fight": "fight:kimshin_sainjin", "place": "misulgwan"},
	"fist_duel": {"fight": "fight:jumeok_seungbu", "place": "misulgwan"},
	"epilogue": {"fight": "", "place": "misulgwan"},
	"finale": {"fight": "", "place": "misulgwan"},
}

const HEROES := ["kimshin", "woojin"]
const LINES := "ch13"
const CROWD_ID := "elite_guard"

const NPCS := {
	"woojin": {"rank": "외성 상위"},       # 주먹 승부의 피우진(적 — 교회전 신겐과 싸운 뒤)
}

const ROLES := {
	"kimshin": {"hp": 200.0, "posture": 60.0, "walk": 2.1, "run": 4.6, "stagger": 50, "look": "kim",
		"moveset": {"combo": "k_slash1", "dash": "k_dash", "counter": "k_counter", "finisher": "k_finisher"}},
	"kimshin_bare": {"look": "kim_bare",
		"moveset": {"combo": "kf_jab", "dash": "kf_dash", "counter": "kf_counter", "finisher": "kf_finisher"}},
	# 피우진: 1 에서는 조작 인물(교대 — woojin), 3 에서는 적(주먹 승부 — woojin_rival: 주먹 · 발 · 메다꽂기를 섞는 x_master, 방 표 role)
	"woojin": {"hp": 230.0, "posture": 70.0, "walk": 2.1, "run": 4.6, "stagger": 50, "look": "woojin",
		"moveset": {"combo": "w_jab", "dash": "w_dash", "finisher": "w_finisher"}},
	"woojin_rival": {"hp": 1500.0, "posture": 560.0, "walk": 2.1, "run": 4.6, "stagger": 50, "look": "woojin", "ai": "x_master",
		"poise": 36.0, "finisher_cap": 0.04, "phase2_at": 0.5, "dmg_k": 1.8},
	"elite_guard": {"hp": 300.0, "posture": 70.0, "walk": 1.9, "run": 4.1, "stagger": 70, "poise": 4.0, "ai": "haseong_guard", "look": "guard"},
	"dohaksu": {"hp": 1200.0, "posture": 300.0, "walk": 1.9, "run": 4.1, "stagger": 75, "poise": 28.0, "finisher_cap": 0.06, "ai": "x_brawler",
		"look": "dohaksu", "phase2_at": 0.5, "dmg_k": 2.2},
	"eogwangdeuk": {"hp": 600.0, "posture": 220.0, "walk": 1.9, "run": 4.1, "stagger": 75, "poise": 22.0, "ai": "x_grappler", "look": "eogwangdeuk", "dmg_k": 1.4},
	"sainjin": {"hp": 1600.0, "posture": 420.0, "walk": 2.2, "run": 4.8, "stagger": 80, "poise": 32.0, "finisher_cap": 0.05, "ai": "x_gun",
		"look": "sainjin", "phase2_at": 0.5, "dmg_k": 2.6},
}

const ROOMS := [
	{"id": "museum_plaza", "theme": "museum_plaza", "bounds": Rect2(-7.0, -2.4, 14.0, 4.8), "cast": ["kimshin", "woojin"],
		"heroes": [Vector2(-5.0, -0.6), Vector2(-5.2, 0.8)], "allies": [],
		"enemies": [["elite_guard", Vector2(0.0, -1.6), {"name": "도학수 쪽"}], ["elite_guard", Vector2(0.6, 1.6), {"name": "도학수 쪽"}],
			["eogwangdeuk", Vector2(2.2, -0.6)], ["dohaksu", Vector2(3.8, 0.6)]], "boss": "dohaksu"},
	{"id": "museum_front", "theme": "museum_plaza", "bounds": Rect2(-6.0, -2.4, 12.0, 4.8), "cast": ["kimshin"],
		"heroes": [Vector2(-3.8, 0.2)], "allies": [],
		"enemies": [["sainjin", Vector2(2.6, 0.0)]], "boss": "sainjin"},
	{"id": "fist_duel", "theme": "red_plaza", "bounds": Rect2(-5.6, -2.4, 11.2, 4.8), "cast": ["kimshin"], "kit": {"kimshin": "kimshin_bare"},
		"heroes": [Vector2(-3.0, 0.2)], "allies": [],
		"enemies": [["woojin", Vector2(2.6, 0.0), {"role": "woojin_rival"}]], "boss": "woojin"},
	{"id": "epilogue", "theme": "red_plaza", "bounds": Rect2(-5.0, -2.4, 10.0, 4.8), "cast": ["kimshin"], "talk": 0.0,
		"heroes": [Vector2(-0.6, 0.4)], "allies": [], "enemies": []},
	{"id": "finale", "theme": "museum_plaza", "bounds": Rect2(-5.0, -2.4, 10.0, 4.8), "cast": ["kimshin"],
		"heroes": [Vector2(-0.6, 0.4)], "allies": [], "enemies": [], "boss": "", "end": true},
]

const INTRO_T := 75
const CLEAR_T := 150
const END_T := 600
const HEAL_ON_CLEAR := 0.4
const MAX_ATTACKERS := 2
