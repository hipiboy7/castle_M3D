extends RefCounted
## 2장 하성 본사 장 표 — 하성그룹 본사 습격(1부 p1:022-033). 방 표 · 인물 역할(3층) · 장 시점. 칸은 hotel.gd · hoeam.gd 와 같다
## (src/combat/stage.gd 가 장 id ch2 로 읽는다 — src/data/campaign.gd). 범위: 주요 전투 + 대사(사용자 "추천대로" 2026-11-06).
## 조작: 김신 / 서진태 — 방마다 한 사람(방 표 cast — 교대 없음). 원작이 로비(서진태 · 이슬 · 청년회)와 위층(김신)을 번갈아 보여 준다.
## 흐름(castle_common canon fights — 화/컷):
##   1 공사장 밤(fight:iseul p1:022/055-066) — 남구청년회 이슬과 한 합. 끝 = 김신의 한 방 → 청년회 19명 합류
##   2 하성 본사 1층 로비(fight:haseong_lobby p1:024-028) — 서진태 조작 · 이슬 · 청년회가 아군, 하성 조직원 무리
##   3 대표실 앞 복도(fight:gyeonghotim p1:025-026 · 029) — 김신이 특별 경호팀을 칼로 제압(불살) · 오지인
##   4 우측 빌딩 로비 · 중앙계단(fight:jintae_hwangbomincheol p1:026-027) — 서진태 대 황보민철(단검 둘)
##   5 대표실 · 불 꺼짐(fight:kimjaehoon_daepyosil p1:029) — 김재훈 · 강창석. 끝 = 깨진 창밖으로 걷어차기(093-095)
##   6 위층 복도(fight:kimshin_namgunghyuk p1:029-030) — 남궁혁. 정면 승부 없이 따돌리고 빠져나간다(030/013-024) → 따돌리기 방(escape)
##   7 부진폐차장 밤(fight:kimshin_sintaejin p1:031-033) — 2장 끝 보스 신태진(쌍칼)
##   8 끝
## 원작과 다른 점: 강창석은 원작에서 중간에 달아난다 — 방의 적으로 둔다. 피우진 · 김대건의 남궁혁전(fight:namgunghyuk)과
## 신태진 고속도로 추격(fight:sintaejin_gosokdoro) · 피우진 대련(fight:woojin_daeryeon)은 대사로만.
## 3층 값은 이 판 소유 — 봇 판 · 판 길이로 맞춘다(tests/sim_stage.gd ch2). 능력치 배율은 addendum.derive.

const EVENT := "beat:yundeoksu"      # 시점: 1장 뒤 · 구스타프 앞 — 김신 내성 중위(진행 사건이 2장 안에 없다)
const PERIOD := "p1"

## 원작 근거(장 데이터 검사 tests/unit/test_campaign.gd 가 id 가 canon 에 있는지 본다): 방 id → fight · place
const CANON := {
	"site_night": {"fight": "fight:iseul", "place": "hoeamsi"},
	"lobby": {"fight": "fight:haseong_lobby", "place": "haseong_hq"},
	"guard_corridor": {"fight": "fight:gyeonghotim", "place": "haseong_hq"},
	"lobby_stairs": {"fight": "fight:jintae_hwangbomincheol", "place": "haseong_hq"},
	"ceo_office": {"fight": "fight:kimjaehoon_daepyosil", "place": "haseong_hq"},
	"upper_corridor": {"fight": "fight:kimshin_namgunghyuk", "place": "haseong_hq"},
	"junkyard_night": {"fight": "fight:kimshin_sintaejin", "place": "bujinpyechajang"},
	"junkyard_end": {"fight": "", "place": "bujinpyechajang"},
}

const HEROES := ["kimshin", "jintae"]   # 방마다 cast 로 한 사람만 나온다
const LINES := "ch2"
const CROWD_ID := "haseong_suit"

## 인물 역할(3층) — 칸 뜻은 hotel.gd ROLES. 김신 2장 = 역수 단검(kim_p1_blade — 경호팀을 칼로 제압 025-026),
## 공사장 이슬 한 합은 맨손(방 표 kit → kimshin_bare)
const ROLES := {
	"kimshin": {"hp": 200.0, "posture": 60.0, "walk": 2.1, "run": 4.6, "stagger": 50, "look": "kim_p1_blade",
		"moveset": {"combo": "k_slash1", "dash": "k_dash", "counter": "k_counter", "finisher": "k_finisher"}},
	"kimshin_bare": {"look": "kim_bare",
		"moveset": {"combo": "kf_jab", "dash": "kf_dash", "counter": "kf_counter", "finisher": "kf_finisher"}},
	# 서진태(2장 조작 인물 · 칼 — 028 로비 난전 · 026-027 황보민철): 칼 베기 → 되베기 → 회전 베기 · 낮은 대시 · 역수 내리꽂기.
	# 칼날 쳐내기가 없어(막기만) 반격 동작은 없다. 기술은 castle_common 진행(stage._hero — 이 시점엔 없음)
	"jintae": {"hp": 230.0, "posture": 70.0, "walk": 2.2, "run": 4.8, "stagger": 50, "look": "jintae",
		"moveset": {"combo": "jk_slash1", "dash": "jk_dash", "finisher": "jk_finisher"}},
	# 이슬: 공사장에서는 적(ai), 로비에서는 아군(moveset · 1층 skills) — 한 줄에 둘 다(stage._npc 가 편에 따라 고른다).
	# 공사장은 '한 합'(022/055-066) — 방 표 hp_k 로 짧게
	"iseul": {"hp": 900.0, "posture": 260.0, "walk": 1.8, "run": 3.9, "stagger": 75, "poise": 30.0, "finisher_cap": 0.12, "ai": "iseul",
		"look": "iseul", "moveset": {"combo": "ia_hook", "dash": "ia_dash", "finisher": "ia_finisher"}},
	# 아군(봇)
	"namgu_youth": {"hp": 220.0, "posture": 45.0, "walk": 1.9, "run": 4.0, "stagger": 70, "look": "namgu_youth",
		"moveset": {"combo": "ny_jab", "dash": "ny_dash", "finisher": "ny_finisher"}},
	# 적
	"haseong_suit": {"hp": 240.0, "posture": 45.0, "walk": 1.8, "run": 3.8, "stagger": 70, "poise": 0.0, "ai": "haseong_suit",
		"look": "haseong_suit"},
	"haseong_guard": {"hp": 280.0, "posture": 60.0, "walk": 1.9, "run": 4.0, "stagger": 70, "poise": 0.0, "ai": "haseong_guard",
		"look": "haseong_guard"},
	# 오지인: 원작은 맞붙지 않고 '열에 아홉은 진다'며 칼을 내려놓고 비켜선다(026/049-052) — yield_at 에서 길을 내준다(stage.gd)
	"ojiin": {"hp": 900.0, "posture": 220.0, "walk": 2.0, "run": 4.3, "stagger": 70, "poise": 26.0, "finisher_cap": 0.12, "ai": "ojiin",
		"look": "ojiin", "yield_at": 0.4},
	"hwangbomincheol": {"hp": 720.0, "posture": 260.0, "walk": 2.0, "run": 4.4, "stagger": 75, "poise": 30.0, "finisher_cap": 0.06, "ai": "mincheol",
		"look": "hwangbomincheol", "phase2_at": 0.5},
	"kimjaehoon": {"hp": 300.0, "posture": 60.0, "walk": 1.8, "run": 3.8, "stagger": 70, "poise": 0.0, "ai": "jaehoon",
		"look": "kimjaehoon"},
	"gangchangseok": {"hp": 800.0, "posture": 240.0, "walk": 1.9, "run": 4.1, "stagger": 75, "poise": 28.0, "finisher_cap": 0.12, "ai": "changseok",
		"look": "gangchangseok"},
	"namgunghyuk": {"hp": 2400.0, "posture": 700.0, "walk": 2.0, "run": 4.4, "stagger": 80, "poise": 36.0, "finisher_cap": 0.04, "ai": "namgung",
		"look": "namgunghyuk", "hp_floor": 0.4, "dmg_k": 1.6},
	"sintaejin": {"hp": 1750.0, "posture": 600.0, "walk": 2.1, "run": 4.6, "stagger": 80, "poise": 34.0, "finisher_cap": 0.06, "ai": "sintaejin",
		"look": "sintaejin", "phase2_at": 0.5, "dmg_k": 2.3},
}

## 방 — 칸 뜻은 hotel.gd ROOMS. 덧붙임: cast(이 방에 나오는 조작 인물 id — heroes 자리도 이 차례) · kit(조작 인물 id → ROLES 의
## 다른 줄 — 동작 · 외형만 바꿔 낀다) · escape(따돌리기: secs 버티거나 exit 안에 들어서면 방을 넘는다 — 적은 쓰러뜨리지 않아도 된다)
const ROOMS := [
	{"id": "site_night", "theme": "site_alley", "bounds": Rect2(-5.6, -2.4, 11.2, 4.8), "cast": ["kimshin"], "kit": {"kimshin": "kimshin_bare"},
		"heroes": [Vector2(-3.0, 0.2)], "allies": [],
		"enemies": [["iseul", Vector2(2.0, 0.0), {"hp_k": 0.5}]], "boss": "iseul"},
	{"id": "lobby", "theme": "haseong_lobby", "bounds": Rect2(-7.2, -3.2, 14.4, 6.4), "cast": ["jintae"],
		"heroes": [Vector2(-5.0, 0.2)], "allies": [["iseul", Vector2(-4.4, -1.4)], ["namgu_youth", Vector2(-5.4, 1.6)], ["namgu_youth", Vector2(-4.0, 2.0)]],
		"enemies": [["haseong_suit", Vector2(0.6, -2.0)], ["haseong_suit", Vector2(1.4, 1.6)], ["haseong_suit", Vector2(2.6, -0.4)],
			["haseong_suit", Vector2(3.6, 2.2)], ["haseong_suit", Vector2(4.6, -1.8)], ["haseong_suit", Vector2(5.2, 0.6)]]},
	{"id": "guard_corridor", "theme": "haseong_corridor", "bounds": Rect2(-7.0, -2.0, 14.0, 4.0), "cast": ["kimshin"],
		"heroes": [Vector2(-5.2, 0.0)], "allies": [],
		"enemies": [["haseong_guard", Vector2(0.4, -1.2)], ["haseong_guard", Vector2(1.2, 1.0)], ["haseong_guard", Vector2(2.4, -0.4)],
			["haseong_guard", Vector2(3.4, 1.2)], ["haseong_guard", Vector2(4.2, -1.2)], ["ojiin", Vector2(5.2, 0.2)]], "boss": "ojiin"},
	{"id": "lobby_stairs", "theme": "haseong_stairs", "bounds": Rect2(-6.0, -2.6, 12.0, 5.2), "cast": ["jintae"],
		"heroes": [Vector2(-3.6, 0.2)], "allies": [],
		"enemies": [["hwangbomincheol", Vector2(2.4, 0.0)]], "boss": "hwangbomincheol"},
	{"id": "ceo_office", "theme": "haseong_office", "bounds": Rect2(-5.6, -2.6, 11.2, 5.2), "cast": ["kimshin"],
		"heroes": [Vector2(-3.8, 0.4)], "allies": [],
		"enemies": [["gangchangseok", Vector2(1.6, -1.2)], ["kimjaehoon", Vector2(3.0, 0.8)]], "boss": "kimjaehoon"},
	{"id": "upper_corridor", "theme": "haseong_upper", "bounds": Rect2(-7.0, -2.0, 14.0, 4.0), "cast": ["kimshin"],
		"heroes": [Vector2(-5.4, 0.0)], "allies": [],
		"enemies": [["namgunghyuk", Vector2(0.6, 0.0)]], "boss": "namgunghyuk",
		"escape": {"secs": 40.0, "exit": Rect2(5.6, -2.0, 1.4, 4.0)}},
	{"id": "junkyard_night", "theme": "junkyard_night", "bounds": Rect2(-6.4, -2.8, 12.8, 5.6), "cast": ["kimshin"],
		"heroes": [Vector2(-3.6, 0.2)], "allies": [],
		"enemies": [["sintaejin", Vector2(2.4, 0.0)]], "boss": "sintaejin"},
	{"id": "junkyard_end", "theme": "junkyard_night", "bounds": Rect2(-5.0, -2.4, 10.0, 4.8), "cast": ["kimshin"],
		"heroes": [Vector2(-1.6, 0.4)], "allies": [], "enemies": [], "boss": "", "end": true},
]

const INTRO_T := 75
const CLEAR_T := 150
const END_T := 360
const HEAL_ON_CLEAR := 0.25
const MAX_ATTACKERS := 2
