extends RefCounted
## 11장 호텔 캐슬 장 표 — 층(방) 표 · 인물 역할(3층: 체력 · 체간 · 속도 · 동작 묶음 · AI · 외형) · 장 시점.
## 흐름(원작 arc:hotelcastle_raid · fight:baekui_tower · fight:kimshin_shingen — castle_common canon):
##   28층 중앙홀(057 — 백의 일행 대 경호대 정장, 구일화가 '올라가라') → 71층 회장층 홀(058 — 검은 정장 거구 넷 = 경호대 최후의 4인)
##   → 71층 복도(059 — 하야부사가 길을 막음) → 회장실 앞(058 ~ 062 — 신겐, 고집에 밀려 길을 내줌) → 빈 회장실(062/099-106)
## 원작과 다른 점(게임으로 옮기며): 원작은 김신이 홀로 71층에 먼저 가고 하야부사는 경호대를 막는다 — 여기서는 김신 · 피우진이
## 함께 오르고(교대, 기획서 03 3절) 하야부사는 신겐 앞을 지키는 적으로 둔다.
## 3층 값은 이 판 소유 — 처음 값은 이 판이 정했고 봇 판 · 판 길이로 맞춘다(무정지 규칙 6). 능력치 배율은 addendum.derive.

## 이 판의 시점 = 11장 호텔 캐슬 기습(castle_common progression 'raid:castle_hotel' 앞까지의 진행 — 김신 재앙 · 피우진 외성 하위)
const EVENT := "raid:castle_hotel"
const PERIOD := "hwajin"

## 원작 근거(castle_common canon — 장 데이터 검사 tests/unit/test_campaign.gd 가 id 가 canon 에 있는지 본다): 방 id →
## fight(canon fights.json 대결 id, 싸움 없는 방은 "") · place(canon locations.json 장소 id)
const CANON := {
	"hall28": {"fight": "fight:baekui_tower", "place": "castle_hotel"},
	"hall71": {"fight": "fight:baekui_tower", "place": "castle_hotel"},
	"corridor71": {"fight": "fight:baekui_tower", "place": "castle_hotel"},
	"office_door": {"fight": "fight:kimshin_shingen", "place": "castle_hotel"},
	"office": {"fight": "", "place": "castle_hotel"},
}

## 장 표 칸(src/data/campaign.gd 가 장 id ch11 로 이 표를 고르고, src/combat/stage.gd 가 읽는다)
const HEROES := ["kimshin", "woojin"]   # 조작하는 사람(교대 차례) — 둘 다 ROLES 에 moveset
const LINES := "ch11"                    # data/story/lines.json 의 이 장 글 — <LINES>.start · .rooms.<방 id>.<때> · .down
const CROWD_ID := "castle_guard"          # 성능 점검(--crowd N)에서 첫 방에 더 세우는 엑스트라

## 인물 역할(3층). hp · posture 는 능력치 맷집 배율을 곱하기 전 값, dmg_k 는 능력치 힘 배율에 더 곱한다(보스 손맛). moveset 은 사람(김신 · 피우진)과 아군(구일화)만 — 적은 AI 가 동작을 고른다
const ROLES := {
	"kimshin": {"hp": 200.0, "posture": 60.0, "walk": 2.1, "run": 4.6, "stagger": 50, "look": "kim",
		"moveset": {"combo": "k_slash1", "dash": "k_dash", "counter": "k_counter", "finisher": "k_finisher"}},
	"woojin": {"hp": 200.0, "posture": 70.0, "walk": 2.1, "run": 4.6, "stagger": 50, "look": "woojin",
		"moveset": {"combo": "w_jab", "dash": "w_dash", "finisher": "w_finisher"}},
	"guilhwa": {"hp": 170.0, "posture": 70.0, "walk": 2.0, "run": 4.4, "stagger": 55, "look": "guilhwa",
		"moveset": {"combo": "gu_jab", "dash": "gu_dash", "finisher": "gu_finisher"}},
	"castle_guard": {"hp": 110.0, "posture": 60.0, "walk": 1.8, "run": 3.8, "stagger": 70, "poise": 0.0, "ai": "guard",
		"look": "guard"},
	"gyeonghodaechoehuui4in": {"hp": 240.0, "posture": 130.0, "walk": 1.8, "run": 3.9, "stagger": 80, "poise": 6.0, "ai": "g4",
		"look": "g4"},
	"hayabusa": {"hp": 760.0, "posture": 260.0, "walk": 2.0, "run": 4.4, "stagger": 80, "poise": 14.0, "ai": "hayabusa",
		"look": "hayabusa"},
	"shingen": {"hp": 1500.0, "posture": 420.0, "walk": 1.95, "run": 4.2, "stagger": 80, "poise": 18.0, "ai": "shingen",
		"look": "shingen", "phase2_at": 0.6, "yield_at": 0.3, "finisher_cap": 0.08, "dmg_k": 3.0},
}

## 방 — theme: 무대 그림(src/view/hotel3d.gd) · bounds: 걸을 수 있는 바닥(m) · heroes/allies/enemies: [인물 id, 자리, (외형 덧붙임)]
## boss: 화면 위 큰 체력 막대에 보일 적(없으면 가장 가까운 적) · lines: data/story/lines.json ch11.rooms.<id>
const ROOMS := [
	{"id": "hall28", "theme": "hall", "bounds": Rect2(-6.6, -3.4, 13.2, 7.0),
		"heroes": [Vector2(-4.4, 0.4), Vector2(-4.8, -0.8)], "allies": [["guilhwa", Vector2(-3.4, 1.4)]],
		"enemies": [["castle_guard", Vector2(2.6, -1.6)], ["castle_guard", Vector2(3.4, 0.2)], ["castle_guard", Vector2(2.8, 1.8)],
			["castle_guard", Vector2(4.6, -0.8)], ["castle_guard", Vector2(4.8, 1.2)]], "boss": ""},
	{"id": "hall71", "theme": "vip_hall", "bounds": Rect2(-6.2, -3.2, 12.4, 6.6),
		"heroes": [Vector2(-4.2, 0.3), Vector2(-4.6, -0.9)], "allies": [],
		"enemies": [["gyeonghodaechoehuui4in", Vector2(2.4, -1.4), {"leader": true}],
			["gyeonghodaechoehuui4in", Vector2(3.4, 0.6)], ["gyeonghodaechoehuui4in", Vector2(2.2, 1.8)],
			["gyeonghodaechoehuui4in", Vector2(4.2, -0.4)]], "boss": "gyeonghodaechoehuui4in"},
	{"id": "corridor71", "theme": "corridor", "bounds": Rect2(-7.2, -1.7, 14.4, 3.4),
		"heroes": [Vector2(-5.2, 0.3), Vector2(-5.8, -0.6)], "allies": [],
		"enemies": [["hayabusa", Vector2(2.6, 0.0)]], "boss": "hayabusa"},
	{"id": "office_door", "theme": "blue_corridor", "bounds": Rect2(-6.0, -2.4, 12.0, 4.8),
		"heroes": [Vector2(-4.0, 0.3), Vector2(-4.6, -0.8)], "allies": [],
		"enemies": [["shingen", Vector2(2.4, 0.0)]], "boss": "shingen"},
	{"id": "office", "theme": "office", "bounds": Rect2(-5.0, -2.8, 10.0, 5.6),
		"heroes": [Vector2(-2.6, 0.6), Vector2(-3.2, -0.6)], "allies": [], "enemies": [], "boss": "", "end": true},
]

const INTRO_T := 75              # 방에 들어서서 싸움이 시작되기까지(층 이름 · 대사)
const CLEAR_T := 150             # 방을 넘고 다음 층으로 가기까지
const END_T := 360               # 빈 회장실 — 끝 글이 보이는 시간
const HEAL_ON_CLEAR := 0.2       # 방을 넘으면 살아 있는 사람이 최대 체력의 이만큼 회복(3층 · 잠정)
const MAX_ATTACKERS := 2         # 동시에 패턴을 내는 적 수(협공 상한)
