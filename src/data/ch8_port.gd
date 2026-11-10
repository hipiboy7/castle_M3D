extends RefCounted
## 8장 동남아 항구 · 교류회(2부 2-14) 장 표 — 칸 뜻은 ch3_busan.gd 와 같다. 조작: 피우진 / 김신(방마다 한 사람).
## 스테이지(사용자 2026-11-10 폰 리뷰 rc.8 — 그대로): 동남아 항구도시 · 웨스턴 펍 · 교류회 피우진 · 교류회 김신.
## 등급(사용자): 피우진은 이 장에서 **이스크라 평 킬러급**(HERO_RANKS — 괴한들은 1 ~ 2방에 끝: 등급 차 한 방 · 피해 규칙),
## 교류회 김신은 김신 **톱** 대 류지학 **내성 중위** 1:1(방 표 ranks).
## 편(castle_common canon fights): 피우진(백의 · 이스크라에서 훈련 중 train:iskra_woojin) 대 무장 괴한 · 스케일(단장) ·
## 캐슬 홀딩스(마크 — 교류회 홀딩스 대결자). 김신(백의) 대 류지학(하성 — 교류회 대결, 최민욱이 거둠).
## 흐름(castle_common canon fights — 화/컷, conf ai 판독):
##   1 동남아 항구도시(fight:woojin_bandits 002/015-032) — 피우진 대 무장 괴한 다섯(AK 둘 · 붉은 셔츠 · 민소매 · 마체테) — 맨손 제압
##   2 웨스턴 펍(fight:woojin_scaledanjang 003/149-004/052) — 피우진 대 스케일단장(준10강) — 결착 없음: 단장이 총을 겨눈 채
##     '1순위는 김신'이라며 걸어 나간다 → 물러남(yield)
##   3 교류회 피우진(fight:mark 009-010 — 호텔 캐슬 물류창고) — 피우진 대 마크(준10강 · 홀딩스) — '홀딩스 중단권 사용 — 백의 승리'
##   4 교류회 김신(fight:kimshin_ryujihak 012-014 — 교류회장) — 김신(톱) 대 류지학(내성 중위 · 쌍단도) 1:1 — 승자 없음: 최민욱이
##     '둘 다 수고 많았다'며 거둔다 → 물러남(yield)
##   5 끝
## 원작과 다른 점: 무장 괴한의 총은 이 판에 없어 맨손 · 몽둥이 · 칼로.
## 난이도(사용자 "보스가 김신보다 약한대도 강하게 표현될 때가 있음"): 조작 인물보다 아랫급 보스(류지학)는 dmg_k ≤ 1 · 1분 안쪽,
## 같거나 윗급(스케일단장 · 마크 — 준10강)은 봇 8판 5판 이상(tests/sim_rooms.gd ch8).

const EVENT := "beat:baekdochan"     # 시점: 6장 뒤 — 김신 톱(교류회 방 ranks 로 확실히) · 피우진은 HERO_RANKS
const PERIOD := "hwajin"

const CANON := {
	"port_market": {"fight": "fight:woojin_bandits", "place": "port_city"},
	"western_pub": {"fight": "fight:woojin_scaledanjang", "place": "westernpub"},
	"gala_woojin": {"fight": "fight:mark", "place": "castle_hotel_mulryuchanggo"},
	"gala_kimshin": {"fight": "fight:kimshin_ryujihak", "place": "castle_hotel"},
	"gala_end": {"fight": "", "place": "castle_hotel"},
}

const HEROES := ["kimshin", "woojin"]
const LINES := "ch8"
const CROWD_ID := "street_thug"

## 피우진 = 이스크라 평 킬러급(사용자 2026-11-10 "피우진 레벨이 여기서 이스크라 킬러급") — 기술 수도 그 등급으로
const HERO_RANKS := {"woojin": "이스크라 평 킬러급"}

const NPCS := {
	"ryujihak": {"rank": "내성 중위"},      # (교류회 이후) 류지학 — 사용자 "류지학은 내성 중위"
}

const ROLES := {
	"kimshin": {"hp": 200.0, "posture": 60.0, "walk": 2.1, "run": 4.6, "stagger": 50, "look": "kim",
		"moveset": {"combo": "k_slash1", "dash": "k_dash", "counter": "k_counter", "finisher": "k_finisher"}},
	"woojin": {"hp": 220.0, "posture": 70.0, "walk": 2.1, "run": 4.6, "stagger": 50, "look": "woojin",
		"moveset": {"combo": "w_jab", "dash": "w_dash", "finisher": "w_finisher"}},
	# 괴한(건달급 — 피우진의 등급 차 한 방) · 마체테 괴한(조장급 — 등급 차 피해 1.75배로 두 대)
	"street_thug": {"hp": 90.0, "posture": 30.0, "walk": 1.8, "run": 3.8, "stagger": 70, "ai": "thug", "look": "ds_raider", "dmg_k": 0.5},
	"gang_blade": {"hp": 40.0, "posture": 20.0, "walk": 1.9, "run": 4.0, "stagger": 70, "ai": "haseong_guard", "look": "haseong_guard", "dmg_k": 0.5},
	# 스케일단장(준10강 — 피우진보다 한 단 위): 결착 없이 걸어 나간다(004/038-052) — yield
	"scaledanjang": {"hp": 190.0, "posture": 240.0, "walk": 2.0, "run": 4.4, "stagger": 75, "poise": 28.0, "finisher_cap": 0.08, "ai": "x_blade",
		"look": "scaledanjang", "phase2_at": 0.6, "yield_at": 0.3, "dmg_k": 0.5},
	# 마크(준10강 · 홀딩스): 혁대를 감은 주먹
	"mark": {"hp": 300.0, "posture": 280.0, "walk": 1.9, "run": 4.1, "stagger": 80, "poise": 32.0, "finisher_cap": 0.06, "ai": "x_brawler",
		"look": "mark", "phase2_at": 0.5, "dmg_k": 0.6},
	# 류지학(내성 중위 — 톱 김신보다 두 단 아래): 쌍단도. 최민욱이 거둔다(yield)
	"ryujihak": {"hp": 900.0, "posture": 420.0, "walk": 2.2, "run": 4.8, "stagger": 80, "poise": 30.0, "finisher_cap": 0.05, "ai": "x_twin",
		"look": "ryujihak", "phase2_at": 0.6, "yield_at": 0.3, "dmg_k": 0.8},
}

const ROOMS := [
	{"id": "port_market", "theme": "port_market", "bounds": Rect2(-7.0, -2.6, 14.0, 5.2), "cast": ["woojin"],
		"heroes": [Vector2(-5.0, 0.2)], "allies": [],
		"enemies": [["street_thug", Vector2(-0.6, -1.8), {"name": "AK 괴한"}], ["street_thug", Vector2(0.2, 1.8), {"name": "AK 괴한"}],
			["street_thug", Vector2(1.4, -0.4), {"name": "붉은 셔츠 괴한"}], ["street_thug", Vector2(2.6, 1.6), {"name": "민소매 괴한"}],
			["gang_blade", Vector2(3.6, -1.4), {"name": "마체테 괴한"}]]},
	{"id": "western_pub", "theme": "western_pub", "bounds": Rect2(-6.0, -2.4, 12.0, 4.8), "cast": ["woojin"],
		"heroes": [Vector2(-3.8, 0.2)], "allies": [],
		"enemies": [["scaledanjang", Vector2(2.4, 0.0)]], "boss": "scaledanjang"},
	{"id": "gala_woojin", "theme": "warehouse", "bounds": Rect2(-6.0, -2.4, 12.0, 4.8), "cast": ["woojin"],
		"heroes": [Vector2(-3.8, 0.2)], "allies": [],
		"enemies": [["mark", Vector2(2.4, 0.0)]], "boss": "mark"},
	{"id": "gala_kimshin", "theme": "gala_hall", "bounds": Rect2(-6.4, -2.4, 12.8, 4.8), "cast": ["kimshin"],
		"heroes": [Vector2(-4.0, 0.2)], "allies": [], "ranks": {"kimshin": "톱", "ryujihak": "내성 중위"},
		"enemies": [["ryujihak", Vector2(2.4, 0.0)]], "boss": "ryujihak"},
	{"id": "gala_end", "theme": "gala_hall", "bounds": Rect2(-5.0, -2.4, 10.0, 4.8), "cast": ["kimshin"],
		"heroes": [Vector2(-1.6, 0.4)], "allies": [], "enemies": [], "boss": "", "end": true},
]

const INTRO_T := 75
const CLEAR_T := 150
const END_T := 360
const HEAL_ON_CLEAR := 0.25
const MAX_ATTACKERS := 2
