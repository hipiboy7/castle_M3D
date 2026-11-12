extends RefCounted
## 0장 프롤로그 장 표 — 블라디보스토크 호텔(군터 거처). 방(층) 표 · 인물 역할(3층) · 장 시점. 표의 칸은 hotel.gd 와 같다
## (src/combat/stage.gd 가 장 id ch0 으로 읽는다 — src/data/campaign.gd).
## 흐름(원작 fight:gunter · p1:002 — castle_common canon): 호텔 복도에서 군터 경호원들이 권총 · 우지를 난사(002/013-015) →
##   김신이 대머리 경호원 턱을 쳐 올리고 방패로 삼음(016-017) → 우지 남자 뒤통수를 권총 손잡이로(018-020) →
##   군터 방 — 거래를 거절당한 군터가 탁자 밑 리볼버를 뽑는다(021-028) → 목 쪽 손 공격 한 번에 끝 → 다음 장면 경찰차.
##   p1:001(플래시포워드)은 쓰지 않는다(기획서 02 3절).
## 원작과 다른 점(게임으로 옮기며): 경호원 셋(대머리 · 우지 장발 · 포니테일 거구)에 정장 둘을 더해 복도를 '싸움 익히기'로 둔다.
## 스테이지 하나(2026-11-10 사용자 "호텔 복도 방 - 군터 방은 같은 스테이지로 묶고, 복도 방에서 군터 방으로 연결되어 이어지도록 …
##   거기서 끝나면 프롤로그는 끝내. 3개 스테이지로 만들 필요 없어"): 한 맵(무대 vlad_hotel — 왼쪽 복도 14m · 문틀 · 오른쪽 군터의 방)에서
##   경호원이 다 쓰러지면 문틀 너머로 걸어 들어가고(x trigger), 들어서면 군터가 일어선다. 군터를 쓰러뜨리면 끝 방(글만 — 판 끝 win 자리).
## 난이도(사용자 "보스가 김신보다 약한대도 강하게"): 군터(조장급) · 경호원(건달급)은 김신(내성 중위)보다 한참 아래 — 경호원은 한 방(등급 차),
##   군터는 dmg_k ≤ 1 로 짧게. 3층 값은 이 판 소유 — 방별 봇 판(tests/sim_rooms.gd ch0). 능력치 배율은 addendum.derive.

## 시점: 1부 처음(진행 사건 beat:yundeoksu 앞 — 김신 내성 중위 · 처음 기술)
const EVENT := "beat:yundeoksu"
const PERIOD := "p1"

## 원작 근거(castle_common canon — 장 데이터 검사 tests/unit/test_campaign.gd 가 id 가 canon 에 있는지 본다): 방 id →
## fight(canon fights.json 대결 id, 싸움 없는 방은 "") · place(canon locations.json 장소 id)
const CANON := {
	"vlad_bar": {"fight": "", "place": "vladivostok"},          # 주점 — 의뢰(p1:002/002-011, 2026-11-12 사용자 5번)
	"vlad_hotel": {"fight": "fight:gunter", "place": "vladivostok"},
	"vlad_night": {"fight": "", "place": "vladivostok"},
}

const HEROES := ["kimshin"]          # 김신 혼자 — 교대 없음
const LINES := "ch0"                 # data/story/lines.json ch0
const CROWD_ID := "gunter_guard"

## 인물 역할(3층) — 칸 뜻은 hotel.gd ROLES. 김신은 1부 처음이라 맨손(칼은 들지 않는다 — p1:014/025-027 '너 정도엔 필요 없다')
const ROLES := {
	"kimshin": {"hp": 200.0, "posture": 60.0, "walk": 2.1, "run": 4.6, "stagger": 50, "look": "kim_bare",
		"moveset": {"combo": "kf_jab", "dash": "kf_dash", "counter": "kf_counter", "finisher": "kf_finisher"}},
	# 주점 장면(싸움 없음): 롱코트 김신(방 표 kit) · 리사 · 의뢰인
	"kimshin_coat": {"look": "kim_coat",
		"moveset": {"combo": "kf_jab", "dash": "kf_dash", "counter": "kf_counter", "finisher": "kf_finisher"}},
	"risa": {"hp": 200.0, "posture": 60.0, "walk": 1.9, "run": 4.0, "stagger": 60, "look": "risa"},
	"client_woman": {"hp": 100.0, "posture": 40.0, "walk": 1.5, "run": 3.0, "stagger": 60, "look": "client_woman"},
	"gunter_guard": {"hp": 420.0, "posture": 100.0, "walk": 1.8, "run": 3.8, "stagger": 70, "poise": 0.0, "ai": "thug",
		"look": "gunter_suit"},
	"gunter": {"hp": 520.0, "posture": 260.0, "walk": 1.6, "run": 3.4, "stagger": 70, "poise": 24.0, "ai": "gunter",
		"look": "gunter", "dmg_k": 0.8},
}

## 방 — 칸 뜻은 hotel.gd ROOMS · 규칙 칸은 src/combat/stage.gd 머리. enemies 셋째 칸(덧붙임): look · ai · name · hp_k (stage.gd _npc)
## 호텔(한 맵): x -7 ~ 7 복도 · 7 ~ 8.2 문틀 · 8.2 ~ 19 군터의 방(무대 town3d HOTEL_CORRIDOR · HOTEL_GAP 과 같은 자리) —
## 문틀을 지나 x 8.6 에 들어서면 군터가 일어선다
const ROOMS := [
	# 주점(2026-11-12 사용자 5번 "주점에서 리사 캐릭터가 앉아있고(구석에는 김신이 롱코트를 입고 어두움 속에 앉아있음), 막 당한 여성이
	# 갑작스럽게 바로 들어와서 리사에게 청부를 하는 스테이지" — 원작 그대로 p1:002/002-011): 싸움 없는 장면 방(scene → clear)
	{"id": "vlad_bar", "fixed": true, "theme": "vlad_bar", "bounds": Rect2(-6.0, -2.2, 12.0, 4.4), "kit": {"kimshin": "kimshin_coat"},
		"heroes": [Vector2(-5.0, -1.7)], "allies": [], "enemies": [], "boss": "",
		"standing": [["risa", Vector2(0.9, -1.6), 0], ["client_woman", Vector2(-6.0, 1.6), 0]],
		"poses": {"kimshin": "sit", "risa": "lean"},
		"scene": "bar_request"},
	{"id": "vlad_hotel", "fixed": true, "theme": "vlad_hotel", "bounds": Rect2(-7.0, -1.9, 26.0, 3.8),
		"heroes": [Vector2(-5.4, 0.2)], "allies": [],
		"enemies": [
			["gunter_guard", Vector2(-1.2, -0.9), {"name": "정장 경호원"}],
			["gunter_guard", Vector2(0.4, 1.0), {"name": "정장 경호원"}],
			["gunter_guard", Vector2(2.2, -0.6), {"look": "gunter_brute", "ai": "thug_brute", "name": "포니테일 거구", "hp_k": 1.6}],
			["gunter_guard", Vector2(4.0, 0.8), {"look": "gunter_bald", "ai": "thug_revolver", "name": "대머리 경호원", "hp_k": 1.2}],
			["gunter_guard", Vector2(5.2, -0.8), {"look": "gunter_uzi", "ai": "thug_uzi", "name": "우지 든 장발 남자", "hp_k": 1.2}]],
		"boss": "gunter",                               # 군터는 방에 들어서면 일어선다(trigger spawn)
		"triggers": [
			{"when": "down:gunter_guard", "say": "corridor_clear"},                         # 0: 복도를 넘었다 — 안쪽 문틀로
			{"when": "x:8.6", "requires": [0], "boss": "gunter", "say": "suite",   # 1: 군터의 방 — 리볼버(002/021-028)
				"spawn": [["gunter", Vector2(16.2, -0.4)]]}]},
	{"id": "vlad_night", "theme": "vlad_night", "bounds": Rect2(-5.0, -2.4, 10.0, 4.8),
		"heroes": [Vector2(-2.4, 0.4)], "allies": [], "enemies": [], "boss": "", "end": true},
]

const INTRO_T := 75
const CLEAR_T := 150
const END_T := 360
const HEAL_ON_CLEAR := 0.3
const MAX_ATTACKERS := 2
