extends RefCounted
## 0장 프롤로그 장 표 — 블라디보스토크 호텔(군터 거처). 방(층) 표 · 인물 역할(3층) · 장 시점. 표의 칸은 hotel.gd 와 같다
## (src/combat/stage.gd 가 장 id ch0 으로 읽는다 — src/data/campaign.gd).
## 흐름(원작 fight:gunter · p1:002 — castle_common canon): 호텔 복도에서 군터 경호원들이 권총 · 우지를 난사(002/013-015) →
##   김신이 대머리 경호원 턱을 쳐 올리고 방패로 삼음(016-017) → 우지 남자 뒤통수를 권총 손잡이로(018-020) →
##   군터 방 — 거래를 거절당한 군터가 탁자 밑 리볼버를 뽑는다(021-028) → 목 쪽 손 공격 한 번에 끝 → 다음 장면 경찰차.
##   p1:001(플래시포워드)은 쓰지 않는다(기획서 02 3절).
## 원작과 다른 점(게임으로 옮기며): 경호원 셋(대머리 · 우지 장발 · 포니테일 거구)에 정장 둘을 더해 첫 방을 '싸움 익히기'로 둔다.
## 3층 값은 이 판 소유 — 봇 판 · 판 길이로 맞춘다(tests/sim_stage.gd). 능력치 배율은 addendum.derive.

## 시점: 1부 처음(진행 사건 beat:yundeoksu 앞 — 김신 내성 중위 · 처음 기술)
const EVENT := "beat:yundeoksu"
const PERIOD := "p1"

## 원작 근거(castle_common canon — 장 데이터 검사 tests/unit/test_campaign.gd 가 id 가 canon 에 있는지 본다): 방 id →
## fight(canon fights.json 대결 id, 싸움 없는 방은 "") · place(canon locations.json 장소 id)
const CANON := {
	"vlad_corridor": {"fight": "fight:gunter", "place": "vladivostok"},
	"gunter_suite": {"fight": "fight:gunter", "place": "vladivostok"},
	"vlad_night": {"fight": "", "place": "vladivostok"},
}

const HEROES := ["kimshin"]          # 김신 혼자 — 교대 없음
const LINES := "ch0"                 # data/story/lines.json ch0
const CROWD_ID := "gunter_guard"

## 인물 역할(3층) — 칸 뜻은 hotel.gd ROLES. 김신은 1부 처음이라 맨손(칼은 들지 않는다 — p1:014/025-027 '너 정도엔 필요 없다')
const ROLES := {
	"kimshin": {"hp": 200.0, "posture": 60.0, "walk": 2.1, "run": 4.6, "stagger": 50, "look": "kim_bare",
		"moveset": {"combo": "kf_jab", "dash": "kf_dash", "counter": "kf_counter", "finisher": "kf_finisher"}},
	"gunter_guard": {"hp": 420.0, "posture": 100.0, "walk": 1.8, "run": 3.8, "stagger": 70, "poise": 0.0, "ai": "thug",
		"look": "gunter_suit"},
	"gunter": {"hp": 1150.0, "posture": 400.0, "walk": 1.6, "run": 3.4, "stagger": 70, "poise": 30.0, "ai": "gunter",
		"look": "gunter"},
}

## 방 — 칸 뜻은 hotel.gd ROOMS. enemies 셋째 칸(덧붙임): look · ai · name · hp_k (stage.gd _npc)
const ROOMS := [
	{"id": "vlad_corridor", "theme": "vlad_corridor", "bounds": Rect2(-7.0, -1.9, 14.0, 3.8),
		"heroes": [Vector2(-5.4, 0.2)], "allies": [],
		"enemies": [
			["gunter_guard", Vector2(-1.2, -0.9), {"name": "정장 경호원"}],
			["gunter_guard", Vector2(0.4, 1.0), {"name": "정장 경호원"}],
			["gunter_guard", Vector2(2.2, -0.6), {"look": "gunter_brute", "ai": "thug_brute", "name": "포니테일 거구", "hp_k": 1.6}],
			["gunter_guard", Vector2(4.0, 0.8), {"look": "gunter_bald", "ai": "thug_revolver", "name": "대머리 경호원", "hp_k": 1.2}],
			["gunter_guard", Vector2(5.2, -0.8), {"look": "gunter_uzi", "ai": "thug_uzi", "name": "우지 든 장발 남자", "hp_k": 1.2}]],
		"boss": ""},
	{"id": "gunter_suite", "theme": "gunter_suite", "bounds": Rect2(-5.4, -2.6, 10.8, 5.2),
		"heroes": [Vector2(-3.8, 0.4)], "allies": [],
		"enemies": [["gunter", Vector2(2.6, -0.4)]], "boss": "gunter"},
	{"id": "vlad_night", "theme": "vlad_night", "bounds": Rect2(-5.0, -2.4, 10.0, 4.8),
		"heroes": [Vector2(-2.4, 0.4)], "allies": [], "enemies": [], "boss": "", "end": true},
]

const INTRO_T := 75
const CLEAR_T := 150
const END_T := 360
const HEAL_ON_CLEAR := 0.3
const MAX_ATTACKERS := 2
