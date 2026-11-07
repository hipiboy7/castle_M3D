extends RefCounted
## 8장 동남아 항구 · 교류회(2부 2-14) 장 표 — 칸 뜻은 ch3_busan.gd 와 같다. 조작: 피우진 / 김신(방마다 한 사람).
## 흐름(castle_common canon fights — 화/컷, conf ai 판독):
##   1 동남아 항구도시(fight:woojin_bandits 002) — 피우진 대 괴한들 — 마체테를 휘두르기 전에 정면 발차기
##   2 웨스턴 펍(fight:woojin_scaledanjang 003-004) — 피우진 대 스케일단장(준10강) — 이스크라 훈련(train:iskra_woojin)
##   3 호텔 캐슬 물류창고(fight:mark 009-010) — 피우진 대 마크(준10강) — 혁대를 감은 주먹, 홀딩스 중단권(진행 beat:mark)
##   4 호텔 캐슬 교류회장(fight:kimshin_ryujihak 012-014) — 김신 대 류지학(쌍단도) — 결착 없음 → 물러남(yield)
##   5 끝
## 원작과 다른 점: 스케일단장전은 원작에서 결과가 없다(003-004) — 이 판은 이긴다(훈련의 끝으로).

const EVENT := "beat:baekdochan"     # 시점: 6장 뒤 — 김신 톱 · 피우진 전국구(남궁혁 이김)
const PERIOD := "hwajin"

const CANON := {
	"port_market": {"fight": "fight:woojin_bandits", "place": "port_city"},
	"western_pub": {"fight": "fight:woojin_scaledanjang", "place": "westernpub"},
	"hotel_warehouse": {"fight": "fight:mark", "place": "castle_hotel_mulryuchanggo"},
	"gala_hall": {"fight": "fight:kimshin_ryujihak", "place": "castle_hotel"},
	"gala_end": {"fight": "", "place": "castle_hotel"},
}

const HEROES := ["kimshin", "woojin"]
const LINES := "ch8"
const CROWD_ID := "street_thug"

const NPCS := {
	"ryujihak": {"rank": "내성 중위"},      # (교류회 이후) 류지학
}

const ROLES := {
	"kimshin": {"hp": 200.0, "posture": 60.0, "walk": 2.1, "run": 4.6, "stagger": 50, "look": "kim",
		"moveset": {"combo": "k_slash1", "dash": "k_dash", "counter": "k_counter", "finisher": "k_finisher"}},
	"woojin": {"hp": 220.0, "posture": 70.0, "walk": 2.1, "run": 4.6, "stagger": 50, "look": "woojin",
		"moveset": {"combo": "w_jab", "dash": "w_dash", "finisher": "w_finisher"}},
	"street_thug": {"hp": 220.0, "posture": 45.0, "walk": 1.8, "run": 3.8, "stagger": 70, "ai": "thug", "look": "ds_raider"},
	"gang_blade": {"hp": 260.0, "posture": 50.0, "walk": 1.9, "run": 4.0, "stagger": 70, "ai": "haseong_guard", "look": "haseong_guard"},
	"elite_guard": {"hp": 300.0, "posture": 70.0, "walk": 1.9, "run": 4.1, "stagger": 70, "poise": 4.0, "ai": "haseong_guard", "look": "guard"},
	"scaledanjang": {"hp": 220.0, "posture": 240.0, "walk": 2.0, "run": 4.4, "stagger": 75, "poise": 28.0, "finisher_cap": 0.08, "ai": "x_blade",
		"look": "scaledanjang", "phase2_at": 0.5, "dmg_k": 0.6},
	"mark": {"hp": 300.0, "posture": 280.0, "walk": 1.9, "run": 4.1, "stagger": 80, "poise": 32.0, "finisher_cap": 0.06, "ai": "x_brawler",
		"look": "mark", "phase2_at": 0.5, "dmg_k": 0.6},
	"ryujihak": {"hp": 1600.0, "posture": 520.0, "walk": 2.2, "run": 4.8, "stagger": 80, "poise": 36.0, "finisher_cap": 0.04, "ai": "x_twin",
		"look": "ryujihak", "yield_at": 0.3, "dmg_k": 1.6},
}

const ROOMS := [
	{"id": "port_market", "theme": "port_market", "bounds": Rect2(-7.0, -2.6, 14.0, 5.2), "cast": ["woojin"],
		"heroes": [Vector2(-5.0, 0.2)], "allies": [],
		"enemies": [["street_thug", Vector2(-0.6, -1.8), {"name": "괴한"}], ["street_thug", Vector2(0.2, 1.8), {"name": "괴한"}],
			["gang_blade", Vector2(1.4, -0.4), {"name": "마체테 괴한"}], ["street_thug", Vector2(2.6, 1.6), {"name": "괴한"}],
			["gang_blade", Vector2(3.6, -1.4), {"name": "마체테 괴한"}]]},
	{"id": "western_pub", "theme": "western_pub", "bounds": Rect2(-6.0, -2.4, 12.0, 4.8), "cast": ["woojin"],
		"heroes": [Vector2(-3.8, 0.2)], "allies": [],
		"enemies": [["scaledanjang", Vector2(2.4, 0.0)]], "boss": "scaledanjang"},
	{"id": "hotel_warehouse", "theme": "warehouse", "bounds": Rect2(-6.0, -2.4, 12.0, 4.8), "cast": ["woojin"],
		"heroes": [Vector2(-3.8, 0.2)], "allies": [],
		"enemies": [["mark", Vector2(2.4, 0.0)]], "boss": "mark"},
	{"id": "gala_hall", "theme": "gala_hall", "bounds": Rect2(-6.4, -2.4, 12.8, 4.8), "cast": ["kimshin"],
		"heroes": [Vector2(-4.0, 0.2)], "allies": [],
		"enemies": [["elite_guard", Vector2(0.4, -1.6), {"name": "교류회 경호"}], ["elite_guard", Vector2(0.8, 1.6), {"name": "교류회 경호"}],
			["ryujihak", Vector2(3.0, 0.0)]], "boss": "ryujihak"},
	{"id": "gala_end", "theme": "gala_hall", "bounds": Rect2(-5.0, -2.4, 10.0, 4.8), "cast": ["kimshin"],
		"heroes": [Vector2(-1.6, 0.4)], "allies": [], "enemies": [], "boss": "", "end": true},
]

const INTRO_T := 75
const CLEAR_T := 150
const END_T := 360
const HEAL_ON_CLEAR := 0.25
const MAX_ATTACKERS := 2
