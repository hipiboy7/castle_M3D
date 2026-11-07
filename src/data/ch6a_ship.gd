extends RefCounted
## 6장 앞 · 인천항 — 백도찬의 배(1부 p1:089-111). 6장 결투(김신 대 백도찬 — duel.gd, 장 id ch6) 앞에 배 위 싸움을 셋으로 둔다
## (기획서 02 3절 6장 '코모도(서진태) · 남궁혁(피우진) · 백도찬(김신) — 셋 교대'). 칸 뜻은 ch3_busan.gd 와 같다.
## 흐름(castle_common canon fights — 화/컷, conf ai 판독):
##   1 배 갑판 → 선내(fight:kimshin_seonsil p1:090-091) — 김신 · 피우진 · 서진태 셋 교대, 이스크라 · 선원 무리
##   2 선교(fight:jintae_komodo p1:090-107) — 서진태 대 코모도 — 칼 쥔 손가락을 베어 전의를 꺾음(진행 beat:komodo — 외성 중위 · 오리지널)
##   3 선창(fight:woojin_namgunghyuk p1:097-111) — 피우진 대 남궁혁 — 들어 올려 머리부터 내리꽂기(진행 beat:namgunghyuk — 전국구)
##   4 끝 — 부두의 백도찬에게(다음 장 ch6 결투)

const EVENT := "beat:gustav"
const PERIOD := "p1"

const CANON := {
	"ship_deck": {"fight": "fight:kimshin_seonsil", "place": "incheonhang_je3budu"},
	"ship_bridge": {"fight": "fight:jintae_komodo", "place": "incheonhang_je3budu"},
	"ship_hold": {"fight": "fight:woojin_namgunghyuk", "place": "incheonhang_je3budu"},
	"ship_end": {"fight": "", "place": "incheonhang"},
}

const HEROES := ["kimshin", "woojin", "jintae"]
const LINES := "ch6a"
const CROWD_ID := "elite_guard"

const ROLES := {
	"kimshin": {"hp": 200.0, "posture": 60.0, "walk": 2.1, "run": 4.6, "stagger": 50, "look": "kim_p1_blade",
		"moveset": {"combo": "k_slash1", "dash": "k_dash", "counter": "k_counter", "finisher": "k_finisher"}},
	"woojin": {"hp": 220.0, "posture": 70.0, "walk": 2.1, "run": 4.6, "stagger": 50, "look": "woojin",
		"moveset": {"combo": "w_jab", "dash": "w_dash", "finisher": "w_finisher"}},
	"jintae": {"hp": 230.0, "posture": 70.0, "walk": 2.2, "run": 4.8, "stagger": 50, "look": "jintae",
		"moveset": {"combo": "jk_slash1", "dash": "jk_dash", "finisher": "jk_finisher"}},
	"elite_guard": {"hp": 300.0, "posture": 70.0, "walk": 1.9, "run": 4.1, "stagger": 70, "poise": 4.0, "ai": "haseong_guard", "look": "guard"},
	"pro_fighter": {"hp": 420.0, "posture": 120.0, "walk": 2.0, "run": 4.3, "stagger": 75, "poise": 10.0, "ai": "x_kicker", "look": "gunter_bald"},
	"komodo": {"hp": 200.0, "posture": 220.0, "walk": 2.1, "run": 4.6, "stagger": 75, "poise": 28.0, "finisher_cap": 0.06, "ai": "x_blade",
		"look": "komodo", "phase2_at": 0.5, "dmg_k": 0.6},
	# 남궁혁: 2장 따돌리기 방과 같은 너클(namgung 프로필 — 너클 카운터 기절). 여기서는 쓰러뜨린다(피우진 승 — p1:111)
	"namgunghyuk": {"hp": 230.0, "posture": 200.0, "walk": 2.0, "run": 4.4, "stagger": 80, "poise": 30.0, "finisher_cap": 0.06, "ai": "namgung",
		"look": "namgunghyuk", "dmg_k": 0.4},
}

const ROOMS := [
	{"id": "ship_deck", "theme": "ship_deck", "bounds": Rect2(-7.0, -2.6, 14.0, 5.2),
		"heroes": [Vector2(-5.0, -0.8), Vector2(-5.4, 0.6), Vector2(-4.6, 1.8)], "allies": [],
		"enemies": [["elite_guard", Vector2(-0.6, -1.8), {"name": "선원"}], ["elite_guard", Vector2(0.2, 1.8), {"name": "선원"}],
			["pro_fighter", Vector2(1.4, -0.4), {"name": "이스크라"}], ["elite_guard", Vector2(2.6, 1.6), {"name": "선원"}],
			["pro_fighter", Vector2(3.6, -1.4), {"name": "이스크라"}], ["elite_guard", Vector2(4.6, 0.6), {"name": "선원"}]]},
	{"id": "ship_bridge", "theme": "ship_bridge", "bounds": Rect2(-5.4, -2.2, 10.8, 4.4), "cast": ["jintae"],
		"heroes": [Vector2(-3.6, 0.2)], "allies": [],
		"enemies": [["komodo", Vector2(2.4, 0.0)]], "boss": "komodo"},
	{"id": "ship_hold", "theme": "ship_hold", "bounds": Rect2(-6.0, -2.4, 12.0, 4.8), "cast": ["woojin"],
		"heroes": [Vector2(-3.8, 0.2)], "allies": [],
		"enemies": [["namgunghyuk", Vector2(2.4, 0.0)]], "boss": "namgunghyuk"},
	{"id": "ship_end", "theme": "ship_deck", "bounds": Rect2(-5.0, -2.4, 10.0, 4.8), "cast": ["kimshin"],
		"heroes": [Vector2(-1.6, 0.4)], "allies": [], "enemies": [], "boss": "", "end": true},
]

const INTRO_T := 75
const CLEAR_T := 150
const END_T := 300
const HEAL_ON_CLEAR := 0.25
const MAX_ATTACKERS := 2
