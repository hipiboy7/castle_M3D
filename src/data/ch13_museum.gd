extends RefCounted
## 13장 미술관 앞(2부 127-134 — arc:misulgwan_gyeolmal) — 마지막 장. 칸 뜻은 ch3_busan.gd 와 같다. 조작: 김신 혼자(1 ~ 3 맨손 — 방 표 kit, 127/026 소매를 걷고 주먹).
## 대결 구도(castle_common canon — 2026-11-10 사용자 폰 리뷰로 바로잡음): 백의(김신 · 도학수 · 어광득 — fight:misulgwan_seupgyeok
## factions ['baekui'])가 미술관(최민욱의 마지막 보루)을 들이받고, 피우진은 최민욱 쪽 계단에서 자기 무리(경호대 · 옛 선진)를 이끌고
## 내려와 김신 앞을 막는다(127/032 — arc turning point). 그래서 도학수 · 어광득은 아군, 피우진은 적이다(조작 인물에서 뺐다).
## 흐름(castle_common canon fights — 화/컷):
##   1 미술관 정문(fight:misulgwan_seupgyeok 127/022-028) — 덤프트럭이 정문을 부수고, 김신이 소매를 걷고(맨주먹 — kit) 도학수 · 어광득 · 백의와 경비 무리에 뛰어든다
##   2 미술관 계단(fight:misulgwan_seupgyeok 127/029-036 · 128/064-070) — 계단에서 경호대 증원 → 피우진이 정장 무리를 이끌고 내려와 '나와라 김신, 일대일'
##   3 돌바닥 광장(fight:jumeok_seungbu 129-134) — 김신(맨손) 대 피우진 — 맨손 주먹 승부(기획서 00 결정 3 · 프롤로그 001 의 예고). 김신 승 —
##     피우진이 '가져가라'며 스스로 판을 넘긴다(134/055-057, 답27-184 — 피우진은 크게 다쳤으나 죽지 않음)
##   4 맺음(대화 방 — fight:kimshin_sainjin 134/065-073: 묶여 끌려온 사인진을 김신이 찌르고 최민욱 거래를 건다 · 싸움이 아니라 대사로) · 5 끝
## 원작과 다른 점: 정문 · 계단 난투에서 경비 · 경호대를 쓰러뜨리는 것은 게임 진행(원작은 피우진의 등장으로 난투가 멈춘다 — 127/031).
## 백의 조직원 무리는 도학수 · 어광득 둘로 줄였다. 사인진(134)은 묶인 채 찔리는 장면이라 싸우는 방이 아니라 맺음 대사로.

const EVENT := "fight:shingen"       # 시점: 12장 뒤 — 피우진 외성 상위(fight:shingen 100)
const PERIOD := "church"

const CANON := {
	"museum_gate": {"fight": "fight:misulgwan_seupgyeok", "place": "misulgwan"},
	"museum_stairs": {"fight": "fight:misulgwan_seupgyeok", "place": "misulgwan"},
	"fist_duel": {"fight": "fight:jumeok_seungbu", "place": "misulgwan"},
	"epilogue": {"fight": "fight:kimshin_sainjin", "place": "misulgwan"},
	"finale": {"fight": "", "place": "misulgwan"},
}

const HEROES := ["kimshin"]
const LINES := "ch13"
const CROWD_ID := "elite_guard"

const NPCS := {
	"woojin": {"rank": "외성 상위"},       # 주먹 승부의 피우진(적 — 교회전 신겐과 싸운 뒤, fight:shingen)
}

const ROLES := {
	"kimshin": {"hp": 200.0, "posture": 60.0, "walk": 2.1, "run": 4.6, "stagger": 50, "look": "kim",
		"moveset": {"combo": "k_slash1", "dash": "k_dash", "counter": "k_counter", "finisher": "k_finisher"}},
	"kimshin_bare": {"look": "kim_bare",
		"moveset": {"combo": "kf_jab", "dash": "kf_dash", "counter": "kf_counter", "finisher": "kf_finisher"}},
	# 아군(백의): 도학수(포항 세력 대표) · 어광득(대구 동성로 세력) — 맨주먹 · 박치기(127/024-025) — 봇이 모는 동작 묶음은 맨손 ny_
	"dohaksu": {"hp": 220.0, "posture": 90.0, "walk": 1.9, "run": 4.1, "stagger": 55, "look": "dohaksu",
		"moveset": {"combo": "ny_jab", "dash": "ny_dash", "finisher": "ny_finisher"}},
	"eogwangdeuk": {"hp": 220.0, "posture": 90.0, "walk": 1.9, "run": 4.1, "stagger": 55, "look": "eogwangdeuk",
		"moveset": {"combo": "ny_jab", "dash": "ny_dash", "finisher": "ny_finisher"}},
	# 적: 미술관 쪽 정장 경비 무리 · 경호대(최민욱 쪽)
	"elite_guard": {"hp": 300.0, "posture": 70.0, "walk": 1.9, "run": 4.1, "stagger": 70, "poise": 4.0, "ai": "haseong_guard", "look": "guard"},
	# 피우진(적 — 주먹 승부): 주먹 · 발 · 메다꽂기를 섞는 x_master(129/032-035 메침 · 134/042-046 앞차기)
	"woojin": {"hp": 1300.0, "posture": 520.0, "walk": 2.1, "run": 4.6, "stagger": 50, "look": "woojin", "ai": "x_master",
		"poise": 36.0, "finisher_cap": 0.04, "phase2_at": 0.5, "dmg_k": 1.0},
}

const ROOMS := [
	{"id": "museum_gate", "theme": "museum_plaza", "bounds": Rect2(-7.0, -2.4, 14.0, 4.8), "cast": ["kimshin"], "kit": {"kimshin": "kimshin_bare"},
		"heroes": [Vector2(-5.0, 0.0)], "allies": [["dohaksu", Vector2(-5.2, -1.2)], ["eogwangdeuk", Vector2(-5.2, 1.2)]],
		"enemies": [["elite_guard", Vector2(0.0, -1.6), {"name": "미술관 경비"}], ["elite_guard", Vector2(0.6, 1.6), {"name": "미술관 경비"}],
			["elite_guard", Vector2(1.8, -0.4), {"name": "미술관 경비"}], ["elite_guard", Vector2(3.0, 1.0), {"name": "미술관 경비"}],
			["elite_guard", Vector2(3.6, -1.4), {"name": "미술관 경비"}], ["elite_guard", Vector2(4.4, 0.2), {"name": "미술관 경비"}]], "boss": ""},
	{"id": "museum_stairs", "theme": "museum_plaza", "bounds": Rect2(-6.4, -2.4, 12.8, 4.8), "cast": ["kimshin"], "kit": {"kimshin": "kimshin_bare"},
		"heroes": [Vector2(-4.4, 0.0)], "allies": [["dohaksu", Vector2(-4.6, -1.2)], ["eogwangdeuk", Vector2(-4.6, 1.2)]],
		"enemies": [["elite_guard", Vector2(0.4, -1.6), {"name": "경호대"}], ["elite_guard", Vector2(0.8, 1.6), {"name": "경호대"}],
			["elite_guard", Vector2(2.0, -0.6), {"name": "경호대"}], ["elite_guard", Vector2(2.6, 1.0), {"name": "경호대"}],
			["elite_guard", Vector2(3.4, -1.4), {"name": "경호대"}], ["elite_guard", Vector2(3.8, 1.4), {"name": "경호대"}],
			["elite_guard", Vector2(4.4, 0.0), {"name": "경호대 고참", "hp_k": 2.5}]], "boss": ""},
	{"id": "fist_duel", "theme": "red_plaza", "bounds": Rect2(-5.6, -2.4, 11.2, 4.8), "cast": ["kimshin"], "kit": {"kimshin": "kimshin_bare"},
		"heroes": [Vector2(-3.0, 0.2)], "allies": [],
		"enemies": [["woojin", Vector2(2.6, 0.0)]], "boss": "woojin"},
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
