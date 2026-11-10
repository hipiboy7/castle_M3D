extends RefCounted
## 10장 '화진 전'(2부 36-61) 장 표 — 칸 뜻은 ch3_busan.gd · 방 규칙 칸은 src/combat/stage.gd 머리. 조작: 김신 / 피우진 / 서진태 / 아킬라.
## 스테이지(사용자 rc.8 폰 리뷰 2026-11-10 '장별 스테이지' — 원작 판독보다 위):
##   1 회암시 시장골목 — 김신 대 리천 1:1, 2분 안에(limit 120). 리천을 쓰러뜨리면 진행 beat:richeon(learn — 김신 재앙 · 촌경 · 리천식 삼연타,
##     사용자 "10장 리천과 싸운다음 김신은 리천식 촌경과 3연타를 쓸 수 있어야함" — 다음 방부터 기술 목록에 보인다)
##   2 임대 아파트 단지 — 피우진 대 도우첸 1:1. 한태철(백의 원군 — 사용자 "10장 한태철 아군")은 먼저 붙었다가 물러나 지켜본다(standing 038/094-133)
##   3 화진 호텔 서재 — 서진태 대 유우성 1:1 → 진행 beat:yuwoosung(서진태 내성 하위)
##   4 산 기슭(산길 · 숲 — fight:akila_suv 046 · 052-061) — 아킬라(총 · 타격) 대 구스타프(방패 · 총 · 타격)
##   5 화진 호텔 1층 홀 — 김신 · 피우진 + 표영 + 백의 5 대 링링 + 화진 20(세 무리로 나눠 들어온다 — 폰 성능 · 한 번에 적 8명 이하)
##   6 끝
## 대결 구도(castle_common canon fights — 화/컷): fight:kimshin_richeon 036-041 · fight:woojin_douchen 038-042 · fight:jintae_seojae 047-051 ·
## fight:akila_suv 046-069 · fight:hwajinhotel 037-051.
## 원작과 다른 점: 리천전 끝(권총 두 발 041 — 쏜 쪽 불확정)은 김신 승으로만. 아킬라 대 구스타프는 원작에서 결착이 없다(069 — 아킬라 쓰러짐) —
## 게임에서는 아킬라가 이긴다. 구스타프의 방패는 이 판에 방패 동작이 없어 단단함(poise)으로만 낸다. 링링은 원작에서 37화부터 홀에 있지만
## 결착(김신 051/023-029)을 마지막 방의 보스로. 산 기슭은 canon locations 에 맞는 장소가 없어(요청 33행) place 를 회암시로 둔다.
## 난이도(사용자 "보스가 김신보다 약한대도 강하게 표현될 때가 있음"): 조작 인물보다 아랫급 보스(링링 — 김신 재앙)는 dmg_k ≤ 1 · 빨리.

const EVENT := "retreat:richeon"     # 시점: 9장 뒤 — 김신 톱 · 서진태 외성 상위 앞 · 피우진 준10강
const PERIOD := "hwajin"

const CANON := {
	"iron_arcade": {"fight": "fight:kimshin_richeon", "place": "hoeamsi"},
	"apartment_lot": {"fight": "fight:woojin_douchen", "place": "imdaeapateudanji"},
	"library": {"fight": "fight:jintae_seojae", "place": "hwajinboutiquehotel"},
	"mountain_road": {"fight": "fight:akila_suv", "place": "hoeamsi"},
	"hwajin_hall": {"fight": "fight:hwajinhotel", "place": "hwajinboutiquehotel"},
	"hwajin_end": {"fight": "", "place": "hwajinboutiquehotel"},
}

const HEROES := ["kimshin", "woojin", "jintae", "akila"]
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
	# 아킬라(이스크라 — 총 · 타격기): 맨주먹 묶음 + 원작 기술(총격 — skill_kit 이 등급 수만큼)
	"akila": {"hp": 230.0, "posture": 80.0, "walk": 2.1, "run": 4.6, "stagger": 50, "look": "akila",
		"moveset": {"combo": "akk_1", "dash": "akk_dash", "counter": "kf_counter", "finisher": "kf_finisher"}},
	"street_thug": {"hp": 120.0, "posture": 40.0, "walk": 1.8, "run": 3.8, "stagger": 70, "ai": "thug", "look": "ds_raider"},
	"gang_blade": {"hp": 150.0, "posture": 45.0, "walk": 1.9, "run": 4.0, "stagger": 70, "ai": "haseong_guard", "look": "haseong_guard"},
	# 백의 조직원(아군 봇 — 방 표 덧붙임 role, 1층은 엑스트라 street_thug)
	"baekui_man": {"hp": 150.0, "posture": 50.0, "walk": 1.9, "run": 4.1, "stagger": 60, "look": "ds_suit",
		"moveset": {"combo": "ny_jab", "dash": "ny_dash", "finisher": "ny_finisher"}},
	"richeon": {"hp": 1300.0, "posture": 640.0, "walk": 2.1, "run": 4.6, "stagger": 80, "poise": 38.0, "finisher_cap": 0.04, "ai": "x_master",
		"look": "richeon", "phase2_at": 0.5, "dmg_k": 0.85},
	"douchen": {"hp": 260.0, "posture": 240.0, "walk": 2.0, "run": 4.4, "stagger": 75, "poise": 28.0, "finisher_cap": 0.06, "ai": "x_boxer",
		"look": "douchen", "phase2_at": 0.5, "dmg_k": 0.6},
	# 아군: 한태철(성남제일파 — 백의 원군, 골프채) · 표영(백의 부산지부장, 카람빗)
	"hantaecheol": {"hp": 200.0, "posture": 70.0, "walk": 1.9, "run": 4.1, "stagger": 55, "look": "hantaecheol",
		"moveset": {"combo": "ht_1", "dash": "ht_dash", "finisher": "ny_finisher"}},
	"pyoyoung": {"hp": 210.0, "posture": 60.0, "walk": 2.3, "run": 5.0, "stagger": 55, "look": "pyoyoung",
		"moveset": {"combo": "py_slash1", "dash": "py_dash", "finisher": "py_finisher"}},
	"lingling": {"hp": 520.0, "posture": 300.0, "walk": 2.2, "run": 4.8, "stagger": 75, "poise": 20.0, "finisher_cap": 0.1, "ai": "x_kicker",
		"look": "lingling", "phase2_at": 0.5, "dmg_k": 0.8},
	"yuwoosung": {"hp": 140.0, "posture": 300.0, "walk": 2.1, "run": 4.6, "stagger": 80, "poise": 32.0, "finisher_cap": 0.04, "ai": "x_swordmaster",
		"look": "yuwoosung", "phase2_at": 0.5, "dmg_k": 0.38},
	# 구스타프(이스크라 — 방패 · 총 · 타격): 거리를 두면 쏘는 x_gun, 방패는 단단함(poise)으로
	"gustav": {"hp": 230.0, "posture": 400.0, "walk": 2.0, "run": 4.4, "stagger": 80, "poise": 40.0, "finisher_cap": 0.04, "ai": "x_gun",
		"look": "gustav", "phase2_at": 0.5, "dmg_k": 0.4},
}

const ROOMS := [
	{"id": "iron_arcade", "theme": "market_alley", "bounds": Rect2(-6.0, -2.4, 12.0, 4.8), "cast": ["kimshin"],
		"heroes": [Vector2(-3.8, 0.2)], "allies": [],
		"enemies": [["richeon", Vector2(2.4, 0.0)]], "boss": "richeon", "limit": 120,
		"triggers": [{"when": "down:richeon", "learn": "beat:richeon", "say": "beat"}]},
	{"id": "apartment_lot", "theme": "apartment_lot", "bounds": Rect2(-6.4, -2.4, 12.8, 4.8), "cast": ["woojin"],
		"heroes": [Vector2(-3.6, 0.2)], "allies": [],
		"standing": [["hantaecheol", Vector2(-5.2, -1.8), 0]],
		"enemies": [["douchen", Vector2(2.4, 0.2)]], "boss": "douchen"},
	{"id": "library", "theme": "library", "bounds": Rect2(-5.6, -2.4, 11.2, 4.8), "cast": ["jintae"],
		"heroes": [Vector2(-3.6, 0.2)], "allies": [],
		"enemies": [["yuwoosung", Vector2(2.4, 0.0)]], "boss": "yuwoosung",
		"triggers": [{"when": "down:yuwoosung", "learn": "beat:yuwoosung"}]},
	{"id": "mountain_road", "theme": "mountain_road", "bounds": Rect2(-7.0, -2.4, 14.0, 4.8), "cast": ["akila"],
		"heroes": [Vector2(-4.2, 0.2)], "allies": [],
		"enemies": [["gustav", Vector2(2.8, 0.0)]], "boss": "gustav"},
	{"id": "hwajin_hall", "theme": "hwajin_hall", "bounds": Rect2(-7.0, -2.6, 14.0, 5.2), "cast": ["kimshin", "woojin"],
		"heroes": [Vector2(-5.0, -0.6), Vector2(-5.2, 0.8)],
		"allies": [["pyoyoung", Vector2(-4.2, 1.8)], ["street_thug", Vector2(-5.8, -1.8), {"role": "baekui_man", "name": "백의 조직원", "look": "ds_suit"}],
			["street_thug", Vector2(-6.2, -0.2), {"role": "baekui_man", "name": "백의 조직원", "look": "ds_suit"}],
			["street_thug", Vector2(-6.2, 1.4), {"role": "baekui_man", "name": "백의 조직원", "look": "ds_suit"}],
			["street_thug", Vector2(-4.6, -2.0), {"role": "baekui_man", "name": "백의 조직원", "look": "ds_suit"}],
			["street_thug", Vector2(-5.6, 2.2), {"role": "baekui_man", "name": "백의 조직원", "look": "ds_suit"}]],
		"enemies": [["lingling", Vector2(4.6, -0.2)],
			["street_thug", Vector2(-0.4, -1.8), {"name": "화진 조직원", "tag": "h1"}], ["gang_blade", Vector2(0.4, 1.8), {"name": "화진 칼잡이", "tag": "h1"}],
			["street_thug", Vector2(1.2, -0.4), {"name": "화진 조직원", "tag": "h1"}], ["gang_blade", Vector2(2.2, 1.2), {"name": "화진 칼잡이", "tag": "h1"}],
			["street_thug", Vector2(2.8, -1.6), {"name": "화진 조직원", "tag": "h1"}], ["street_thug", Vector2(3.4, 0.8), {"name": "화진 조직원", "tag": "h1"}]],
		"boss": "lingling",
		"triggers": [
			{"when": "time:0", "learn": "beat:douchen"},
			{"when": "down:h1", "say": "wave",   # 화진 무리 세 갈래(tag h1 · h2 · h3) — 앞 무리가 다 쓰러지면 회전문(오른쪽)에서 다음 무리
				"spawn": [["street_thug", Vector2(6.6, -2.0), {"name": "화진 조직원", "tag": "h2"}], ["gang_blade", Vector2(6.6, -0.8), {"name": "화진 칼잡이", "tag": "h2"}],
					["street_thug", Vector2(6.6, 0.4), {"name": "화진 조직원", "tag": "h2"}], ["gang_blade", Vector2(6.6, 1.6), {"name": "화진 칼잡이", "tag": "h2"}],
					["street_thug", Vector2(6.6, -1.4), {"name": "화진 조직원", "tag": "h2"}], ["street_thug", Vector2(6.6, 1.0), {"name": "화진 조직원", "tag": "h2"}],
					["street_thug", Vector2(6.6, 2.2), {"name": "화진 조직원", "tag": "h2"}]]},
			{"when": "down:h2",
				"spawn": [["gang_blade", Vector2(6.6, -2.0), {"name": "화진 칼잡이", "tag": "h3"}], ["street_thug", Vector2(6.6, -0.8), {"name": "화진 조직원", "tag": "h3"}],
					["gang_blade", Vector2(6.6, 0.4), {"name": "화진 칼잡이", "tag": "h3"}], ["street_thug", Vector2(6.6, 1.6), {"name": "화진 조직원", "tag": "h3"}],
					["street_thug", Vector2(6.6, -1.4), {"name": "화진 조직원", "tag": "h3"}], ["gang_blade", Vector2(6.6, 1.0), {"name": "화진 칼잡이", "tag": "h3"}],
					["street_thug", Vector2(6.6, 2.2), {"name": "화진 조직원", "tag": "h3"}]]}]},
	{"id": "hwajin_end", "theme": "hwajin_hall", "bounds": Rect2(-5.0, -2.4, 10.0, 4.8), "cast": ["kimshin"],
		"heroes": [Vector2(-1.6, 0.4)], "allies": [], "enemies": [], "boss": "", "end": true},
]

const INTRO_T := 75
const CLEAR_T := 150
const END_T := 360
const HEAL_ON_CLEAR := 0.25
const MAX_ATTACKERS := 2
