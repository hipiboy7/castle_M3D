extends RefCounted
## 10장 회암시 · 임대 아파트 · 화진 호텔(2부 36-51) 장 표 — 칸 뜻은 ch3_busan.gd 와 같다. 조작: 김신 / 피우진 / 서진태.
## 흐름(castle_common canon fights — 화/컷, conf ai 판독):
##   1 회암시 시장 끝 철공소 아케이드(fight:kimshin_richeon 036-041) — 김신 대 리천(톱) — 진행 beat:richeon(김신 → 재앙)
##   2 임대 아파트 단지(fight:woojin_douchen 038-042) — 피우진 대 도우첸 · 한태철 — 오른 주먹 내리꽂기(진행 beat:douchen)
##   3 화진 부티크 호텔 1층 홀(fight:hwajinhotel 037-051) — 김신 · 서진태 교대 대 화진 무리 · 링링
##   4 화진 호텔 서재(fight:jintae_seojae 047-051) — 서진태 대 유우성(내성 하위) — 진행 beat:yuwoosung
##   5 끝
## 원작과 다른 점: 리천전 끝(권총 두 발 097-099 — 쏜 쪽 불확정)은 김신 승으로만. 장이보(서재)는 대사로만.

const EVENT := "retreat:richeon"     # 시점: 9장 뒤 — 서진태 외성 상위 · 피우진 준10강
const PERIOD := "hwajin"

const CANON := {
	"iron_arcade": {"fight": "fight:kimshin_richeon", "place": "hoeamsi"},
	"apartment_lot": {"fight": "fight:woojin_douchen", "place": "imdaeapateudanji"},
	"hwajin_hall": {"fight": "fight:hwajinhotel", "place": "hwajinboutiquehotel"},
	"library": {"fight": "fight:jintae_seojae", "place": "hwajinboutiquehotel"},
	"hwajin_end": {"fight": "", "place": "hwajinboutiquehotel"},
}

const HEROES := ["kimshin", "woojin", "jintae"]
const LINES := "ch10"
const CROWD_ID := "street_thug"

const NPCS := {
	"douchen": {"rank": "외성 하위"},      # 강함표에 없음 — 피우진이 이기면 외성 하위가 된다(진행 beat:douchen)
}

const ROLES := {
	"kimshin": {"hp": 200.0, "posture": 60.0, "walk": 2.1, "run": 4.6, "stagger": 50, "look": "kim",
		"moveset": {"combo": "k_slash1", "dash": "k_dash", "counter": "k_counter", "finisher": "k_finisher"}},
	"woojin": {"hp": 220.0, "posture": 70.0, "walk": 2.1, "run": 4.6, "stagger": 50, "look": "woojin",
		"moveset": {"combo": "w_jab", "dash": "w_dash", "finisher": "w_finisher"}},
	"jintae": {"hp": 230.0, "posture": 70.0, "walk": 2.2, "run": 4.8, "stagger": 50, "look": "jintae",
		"moveset": {"combo": "jk_slash1", "dash": "jk_dash", "finisher": "jk_finisher"}},
	"street_thug": {"hp": 220.0, "posture": 45.0, "walk": 1.8, "run": 3.8, "stagger": 70, "ai": "thug", "look": "ds_raider"},
	"gang_blade": {"hp": 260.0, "posture": 50.0, "walk": 1.9, "run": 4.0, "stagger": 70, "ai": "haseong_guard", "look": "haseong_guard"},
	"richeon": {"hp": 1300.0, "posture": 640.0, "walk": 2.1, "run": 4.6, "stagger": 80, "poise": 38.0, "finisher_cap": 0.04, "ai": "x_master",
		"look": "richeon", "phase2_at": 0.5, "dmg_k": 1.0},
	"douchen": {"hp": 150.0, "posture": 240.0, "walk": 2.0, "run": 4.4, "stagger": 75, "poise": 28.0, "finisher_cap": 0.06, "ai": "x_boxer",
		"look": "douchen", "phase2_at": 0.5, "dmg_k": 0.45},
	"hantaecheol": {"hp": 100.0, "posture": 120.0, "walk": 1.9, "run": 4.1, "stagger": 70, "poise": 10.0, "ai": "x_brawler", "look": "hantaecheol", "dmg_k": 0.5},
	"lingling": {"hp": 700.0, "posture": 240.0, "walk": 2.2, "run": 4.8, "stagger": 75, "poise": 24.0, "finisher_cap": 0.08, "ai": "x_kicker",
		"look": "lingling", "dmg_k": 1.0},
	"yuwoosung": {"hp": 180.0, "posture": 300.0, "walk": 2.1, "run": 4.6, "stagger": 80, "poise": 32.0, "finisher_cap": 0.04, "ai": "x_swordmaster",
		"look": "yuwoosung", "phase2_at": 0.5, "dmg_k": 0.45},
}

const ROOMS := [
	{"id": "iron_arcade", "theme": "iron_arcade", "bounds": Rect2(-6.0, -2.4, 12.0, 4.8), "cast": ["kimshin"],
		"heroes": [Vector2(-3.8, 0.2)], "allies": [],
		"enemies": [["richeon", Vector2(2.4, 0.0)]], "boss": "richeon"},
	{"id": "apartment_lot", "theme": "apartment_lot", "bounds": Rect2(-6.4, -2.4, 12.8, 4.8), "cast": ["woojin"],
		"heroes": [Vector2(-4.2, 0.2)], "allies": [],
		"enemies": [["hantaecheol", Vector2(1.0, -1.4)], ["douchen", Vector2(2.8, 0.4)]], "boss": "douchen"},
	{"id": "hwajin_hall", "theme": "hwajin_hall", "bounds": Rect2(-7.0, -2.6, 14.0, 5.2), "cast": ["kimshin", "jintae"],
		"heroes": [Vector2(-5.0, -0.6), Vector2(-5.2, 0.8)], "allies": [],
		"enemies": [["street_thug", Vector2(-0.6, -1.8), {"name": "화진 조직원"}], ["gang_blade", Vector2(0.2, 1.8), {"name": "화진 칼잡이"}],
			["street_thug", Vector2(1.4, -0.4), {"name": "화진 조직원"}], ["gang_blade", Vector2(2.6, 1.6), {"name": "화진 칼잡이"}],
			["lingling", Vector2(4.2, -0.2)]], "boss": "lingling"},
	{"id": "library", "theme": "library", "bounds": Rect2(-5.6, -2.4, 11.2, 4.8), "cast": ["jintae"],
		"heroes": [Vector2(-3.6, 0.2)], "allies": [],
		"enemies": [["yuwoosung", Vector2(2.4, 0.0)]], "boss": "yuwoosung"},
	{"id": "hwajin_end", "theme": "hwajin_hall", "bounds": Rect2(-5.0, -2.4, 10.0, 4.8), "cast": ["kimshin"],
		"heroes": [Vector2(-1.6, 0.4)], "allies": [], "enemies": [], "boss": "", "end": true},
]

const INTRO_T := 75
const CLEAR_T := 150
const END_T := 360
const HEAL_ON_CLEAR := 0.25
const MAX_ATTACKERS := 2
