extends RefCounted
## 10장 회암시 · 임대 아파트 · 화진 호텔(2부 36-51) 장 표 — 칸 뜻은 ch3_busan.gd 와 같다. 조작: 김신 / 피우진 / 서진태.
## 대결 구도(castle_common canon — 2026-11-10 다시 맞춤): 백의(김신 · 서진태 · 피우진 + 성남제일파 한태철(037 백의 원군) · 백의 부산지부
## 표영 · 정선오 · 정승영 · 넙치(factions busanseryeok) · 이스크라 킬러 라텔) 대 화진(유우성 · 링링 · 도우첸 · 화교 용병) + 유우성이 부른 살수 리천.
## 흐름(castle_common canon fights — 화/컷):
##   1 회암시 시장 끝 철공소 아케이드(fight:kimshin_richeon 036-041) — 김신 대 리천(톱) — 진행 beat:richeon(김신 → 재앙)
##   2 임대 아파트 단지(fight:woojin_douchen 038-042 · fight:douchen_apateu 036-042) — 한태철이 골프채로 먼저 도우첸에게 붙고(038/094-133)
##     피우진이 '저것만 상대하고'로 이어받아 오른 주먹 내리꽂기(042/049) — 한태철은 아군(진행 beat:douchen)
##   3 화진 부티크 호텔 1층 홀(fight:hwajinhotel 037-046) — 김신 · 서진태 교대 + 표영 · 라텔(아군) 대 화교 용병대 · 홍콩 본부 세력
##   4 화진 호텔 서재(fight:jintae_seojae 040 · 047-051) — 서진태 대 유우성(내성 하위) — 진행 beat:yuwoosung
##   5 1층 홀 · 부서진 피아노(fight:hwajinhotel 050/114-051/029) — 피우진이 백의 무리를 이끌고 홀로 들어오고(050/118-051/009) 김신이
##     링링의 사슬 식칼 밑으로 파고들어 목을 벤다(051/023-029) — 김신 · 피우진 교대
##   6 끝
## 원작과 다른 점: 리천전 끝(권총 두 발 097-099 — 쏜 쪽 불확정)은 김신 승으로만. 장이보(서재)는 대사로만. 링링은 원작에서 37화부터 홀에
## 있지만(라텔 · 표영과 싸움) 결착(김신 051)만 5 의 보스로. 백의 부산지부 사람은 표영 하나로 줄였다.

const EVENT := "retreat:richeon"     # 시점: 9장 뒤 — 서진태 외성 상위 · 피우진 준10강
const PERIOD := "hwajin"

const CANON := {
	"iron_arcade": {"fight": "fight:kimshin_richeon", "place": "hoeamsi"},
	"apartment_lot": {"fight": "fight:woojin_douchen", "place": "imdaeapateudanji"},
	"hwajin_hall": {"fight": "fight:hwajinhotel", "place": "hwajinboutiquehotel"},
	"library": {"fight": "fight:jintae_seojae", "place": "hwajinboutiquehotel"},
	"hwajin_piano": {"fight": "fight:hwajinhotel", "place": "hwajinboutiquehotel"},
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
	"douchen": {"hp": 260.0, "posture": 240.0, "walk": 2.0, "run": 4.4, "stagger": 75, "poise": 28.0, "finisher_cap": 0.06, "ai": "x_boxer",
		"look": "douchen", "phase2_at": 0.5, "dmg_k": 0.6},
	# 아군: 한태철(성남제일파 — 백의 원군, 골프채) · 표영(백의 부산지부장, 카람빗) · 라텔(이스크라 킬러, 카람빗)
	"hantaecheol": {"hp": 200.0, "posture": 70.0, "walk": 1.9, "run": 4.1, "stagger": 55, "look": "hantaecheol",
		"moveset": {"combo": "ny_jab", "dash": "ny_dash", "finisher": "ny_finisher"}},
	"pyoyoung": {"hp": 210.0, "posture": 60.0, "walk": 2.3, "run": 5.0, "stagger": 55, "look": "pyoyoung",
		"moveset": {"combo": "py_slash1", "dash": "py_dash", "finisher": "py_finisher"}},
	"ratel": {"hp": 200.0, "posture": 60.0, "walk": 2.2, "run": 4.8, "stagger": 55, "look": "ratel",
		"moveset": {"combo": "py_slash1", "dash": "py_dash", "finisher": "py_finisher"}},
	"lingling": {"hp": 1300.0, "posture": 340.0, "walk": 2.2, "run": 4.8, "stagger": 75, "poise": 24.0, "finisher_cap": 0.08, "ai": "x_kicker",
		"look": "lingling", "phase2_at": 0.5, "dmg_k": 1.9},
	"yuwoosung": {"hp": 180.0, "posture": 300.0, "walk": 2.1, "run": 4.6, "stagger": 80, "poise": 32.0, "finisher_cap": 0.04, "ai": "x_swordmaster",
		"look": "yuwoosung", "phase2_at": 0.5, "dmg_k": 0.45},
}

const ROOMS := [
	{"id": "iron_arcade", "theme": "iron_arcade", "bounds": Rect2(-6.0, -2.4, 12.0, 4.8), "cast": ["kimshin"],
		"heroes": [Vector2(-3.8, 0.2)], "allies": [],
		"enemies": [["richeon", Vector2(2.4, 0.0)]], "boss": "richeon"},
	{"id": "apartment_lot", "theme": "apartment_lot", "bounds": Rect2(-6.4, -2.4, 12.8, 4.8), "cast": ["woojin"],
		"heroes": [Vector2(-4.2, 0.2)], "allies": [["hantaecheol", Vector2(-1.0, 1.0)]],
		"enemies": [["street_thug", Vector2(0.8, -1.6), {"name": "도우첸 쪽 무리"}], ["street_thug", Vector2(1.4, 1.6), {"name": "도우첸 쪽 무리"}],
			["douchen", Vector2(2.8, 0.4)]], "boss": "douchen"},
	{"id": "hwajin_hall", "theme": "hwajin_hall", "bounds": Rect2(-7.0, -2.6, 14.0, 5.2), "cast": ["kimshin", "jintae"],
		"heroes": [Vector2(-5.0, -0.6), Vector2(-5.2, 0.8)], "allies": [["pyoyoung", Vector2(-4.2, 1.8)], ["ratel", Vector2(-4.0, -1.8)]],
		"enemies": [["street_thug", Vector2(-0.6, -1.8), {"name": "화교 용병"}], ["gang_blade", Vector2(0.2, 1.8), {"name": "화교 용병"}],
			["street_thug", Vector2(1.4, -0.4), {"name": "화교 용병"}], ["gang_blade", Vector2(2.6, 1.6), {"name": "화진 칼잡이"}],
			["street_thug", Vector2(3.4, -1.6), {"name": "화교 용병"}], ["gang_blade", Vector2(4.2, -0.2), {"name": "베이지 트렌치코트 거구", "hp_k": 2.0}]], "boss": ""},
	{"id": "library", "theme": "library", "bounds": Rect2(-5.6, -2.4, 11.2, 4.8), "cast": ["jintae"],
		"heroes": [Vector2(-3.6, 0.2)], "allies": [],
		"enemies": [["yuwoosung", Vector2(2.4, 0.0)]], "boss": "yuwoosung"},
	{"id": "hwajin_piano", "theme": "hwajin_hall", "bounds": Rect2(-7.0, -2.6, 14.0, 5.2), "cast": ["kimshin", "woojin"],
		"heroes": [Vector2(-5.0, -0.6), Vector2(-5.2, 0.8)], "allies": [],
		"enemies": [["street_thug", Vector2(-0.4, -1.6), {"name": "화진 패거리"}], ["gang_blade", Vector2(0.6, 1.6), {"name": "화진 패거리"}],
			["street_thug", Vector2(1.8, 0.2), {"name": "화진 패거리"}], ["lingling", Vector2(4.0, -0.2)]], "boss": "lingling"},
	{"id": "hwajin_end", "theme": "hwajin_hall", "bounds": Rect2(-5.0, -2.4, 10.0, 4.8), "cast": ["kimshin"],
		"heroes": [Vector2(-1.6, 0.4)], "allies": [], "enemies": [], "boss": "", "end": true},
]

const INTRO_T := 75
const CLEAR_T := 150
const END_T := 360
const HEAL_ON_CLEAR := 0.25
const MAX_ATTACKERS := 2
