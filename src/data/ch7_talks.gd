extends RefCounted
## 7장 임무열의 최후 · 1부 끝(1부 p1:117-121 — 122 후기는 장 밖) — **관전 장**(사용자 2026-11-10 폰 리뷰 rc.8 "7장은 정말 쓸데 없는
## 것 같음. 컴퓨터끼리 싸우는 모습이나 장면이라도 연출할 것"). 원작에서 김신이 없는 싸움은 관전 방(auto — 조작 인물도 봇, 화면 아래
## '관전'), 김신 · 피우진의 장면은 사람을 세운 대화 방(talk + standing). 칸 뜻은 ch3_busan.gd 와 같다.
## 흐름(castle_common canon fights — 화/컷, conf ai 판독):
##   1 캐슬 식당 앞(관전 — fight:immuyeol_castleguards p1:117/010-023) — 임무열이 최민욱을 찾아오자 이희성이 '잡아' — 사인진 · 캐슬 경호원과
##     맞붙는다 → 최민욱의 목소리 '귀한 손이다. 안으로 모셔라'로 멈춘다(triggers time → calm)
##   2 돌아가는 길(관전 — fight:immuyeol_sainjin p1:117/063-071) — 사인진이 임무열을 처형한다(임무열 = 적, 사인진 = 봇)
##   3 미술관(대화 — p1:118/013-081) — 붕대투성이 김신이 홀로 최민욱과 담판. 마학영 · 사인진이 곁에 선다(standing)
##   4 모리 회의(관전 — fight:hide_moriganbu p1:121/020-029 회상) — 히데가 실력을 숨긴 채 간부를 베고 모리의 새 오야붕이 된다
##   5 배 타는 곳(관전 — fight:gustav_komodo p1:121/047-070) — 블랙맘바가 달아난 코모도를 붙잡고 구스타프가 쓰러뜨린다
##   6 북미 형무소(관전 — fight:majunyeong_prison p1:121/073-083) — 마준영의 배틀 로열, 수감자 무리가 두 패로 들어온다
##   7 클럽 발레리노 옥상(대화 — p1:121/001-016) — 피우진이 메드베디에게 리사의 입단 제안을 거절했다고 — '김신 보스를 따를 거다'
##   8 끝 — 1부 끝(합동 장례 p1:119/094-115 · 오월동주 회의 p1:119/195-228 은 끝 글로)
## 원작과 다른 점: 합동 장례 · 오월동주 회의 방은 뺐다(대화만 있던 방 — 사용자 "줄이거나", 끝 글에 한 줄). 1 방의 사인진은 원작에서
## 임무열을 붙드는 쪽 — 싸움이 끝나지 않게 쓰러지지 않는다(hp_floor). 6 방 수감자 무리는 이름 없는 엑스트라(street_thug · gang_brute).
## 관전 방의 조작 인물(봇)은 지지 않게 상대를 약하게 둔다(봇 판 tests/sim_rooms.gd ch7 — 관전 방은 늘 이긴다).

const EVENT := "beat:baekdochan"
const PERIOD := "p1"

const CANON := {
	"castle_dining": {"fight": "fight:immuyeol_castleguards", "place": "castle_hotel"},
	"immuyeol_end": {"fight": "fight:immuyeol_sainjin", "place": "castle_hotel"},
	"museum_talk": {"fight": "", "place": "misulgwan"},
	"mori_council": {"fight": "fight:hide_moriganbu", "place": "tokyo"},
	"gustav_komodo": {"fight": "fight:gustav_komodo", "place": "vladivostok"},
	"majun_prison": {"fight": "fight:majunyeong_prison", "place": "prison"},
	"epilogue_roof": {"fight": "", "place": "club_ballerino"},
	"part1_end": {"fight": "", "place": "club_ballerino"},
}

## 조작 인물 — 김신 · 피우진(대화 방), 나머지는 관전 방의 봇(그 방에서만 나온다)
const HEROES := ["kimshin", "woojin", "immuyeol", "sainjin", "hide", "gustav", "majunyeong"]
const LINES := "ch7"
const CROWD_ID := "street_thug"

const ROLES := {
	"kimshin": {"hp": 200.0, "posture": 60.0, "walk": 2.1, "run": 4.6, "stagger": 50, "look": "kim_p1_blade",
		"moveset": {"combo": "k_slash1", "dash": "k_dash", "counter": "k_counter", "finisher": "k_finisher"}},
	"woojin": {"hp": 220.0, "posture": 70.0, "walk": 2.1, "run": 4.6, "stagger": 50, "look": "woojin",
		"moveset": {"combo": "w_jab", "dash": "w_dash", "finisher": "w_finisher"}},
	# 관전 방의 봇(조작 인물 칸) — 1 방 임무열(칼) · 2 방 사인진 · 4 방 히데(칼) · 5 방 구스타프(주먹) · 6 방 마준영(발)
	"immuyeol": {"hp": 520.0, "posture": 140.0, "walk": 2.0, "run": 4.4, "stagger": 50, "look": "immuyeol", "ai": "x_blade",
		"moveset": {"combo": "k_slash1", "dash": "k_dash", "finisher": "k_finisher"}},
	"sainjin": {"hp": 520.0, "posture": 160.0, "walk": 2.1, "run": 4.6, "stagger": 50, "look": "sainjin", "ai": "x_boxer",
		"moveset": {"combo": "w_jab", "dash": "w_dash", "finisher": "w_finisher"}},
	"hide": {"hp": 420.0, "posture": 120.0, "walk": 2.1, "run": 4.6, "stagger": 50, "look": "hide",
		"moveset": {"combo": "k_slash1", "dash": "k_dash", "finisher": "k_finisher"}},
	"gustav": {"hp": 600.0, "posture": 180.0, "walk": 2.0, "run": 4.4, "stagger": 55, "look": "gustav",
		"moveset": {"combo": "gu_jab", "dash": "gu_dash", "finisher": "gu_finisher"}},
	"majunyeong": {"hp": 600.0, "posture": 180.0, "walk": 2.1, "run": 4.6, "stagger": 50, "look": "majunyeong",
		"moveset": {"combo": "ny_jab", "dash": "ny_dash", "finisher": "ny_finisher"}},
	# 적 · 서 있는 사람
	# 1 방 사인진(적 — 임무열을 붙드는 쪽): 쓰러지지 않는다 · 세게 치지 않는다(최민욱의 목소리가 싸움을 멈출 때까지)
	"sainjin_guard": {"hp": 520.0, "posture": 200.0, "walk": 2.1, "run": 4.6, "stagger": 70, "ai": "x_boxer", "look": "sainjin", "hp_floor": 0.5, "dmg_k": 0.3},
	"castle_guard": {"hp": 160.0, "posture": 45.0, "walk": 1.9, "run": 4.0, "stagger": 70, "ai": "guard", "look": "guard", "dmg_k": 0.4},
	"immuyeol_last": {"hp": 140.0, "posture": 60.0, "walk": 1.8, "run": 3.8, "stagger": 75, "ai": "x_blade", "look": "immuyeol", "dmg_k": 0.3},
	"pro_fighter": {"hp": 260.0, "posture": 90.0, "walk": 2.0, "run": 4.3, "stagger": 75, "ai": "x_blade", "look": "gunter_suit", "dmg_k": 0.4},
	"komodo": {"hp": 240.0, "posture": 120.0, "walk": 2.1, "run": 4.6, "stagger": 75, "poise": 12.0, "ai": "x_blade", "look": "komodo", "dmg_k": 0.4},
	"street_thug": {"hp": 120.0, "posture": 40.0, "walk": 1.8, "run": 3.8, "stagger": 70, "ai": "thug", "look": "ds_raider", "dmg_k": 0.4},
	"gang_brute": {"hp": 200.0, "posture": 60.0, "walk": 1.7, "run": 3.6, "stagger": 75, "ai": "thug_brute", "look": "gunter_brute", "dmg_k": 0.4},
	"ihuiseong": {"hp": 200.0, "posture": 60.0, "walk": 1.9, "run": 4.0, "stagger": 60, "look": "ihuiseong"},
	"choeminuk": {"hp": 200.0, "posture": 60.0, "walk": 1.9, "run": 4.0, "stagger": 60, "look": "choeminuk"},
	"mahakyoung": {"hp": 200.0, "posture": 60.0, "walk": 1.9, "run": 4.0, "stagger": 60, "look": "mahakyoung"},
	"blackmamba": {"hp": 200.0, "posture": 60.0, "walk": 1.9, "run": 4.0, "stagger": 60, "look": "blackmamba"},
	"medvedi": {"hp": 200.0, "posture": 60.0, "walk": 1.9, "run": 4.0, "stagger": 60, "look": "medvedi"},
}

const ROOMS := [
	{"id": "castle_dining", "theme": "gala_hall", "bounds": Rect2(-6.0, -2.4, 12.0, 4.8), "cast": ["immuyeol"], "auto": true,
		"heroes": [Vector2(-3.6, 0.2)], "allies": [],
		"enemies": [["sainjin", Vector2(1.2, 0.0), {"role": "sainjin_guard"}], ["castle_guard", Vector2(0.4, -1.6), {"name": "캐슬 경호원"}],
			["castle_guard", Vector2(0.6, 1.6), {"name": "캐슬 경호원"}], ["castle_guard", Vector2(2.6, -1.0), {"name": "캐슬 경호원"}],
			["castle_guard", Vector2(2.8, 1.2), {"name": "캐슬 경호원"}]], "boss": "sainjin",
		"standing": [["ihuiseong", Vector2(4.6, -0.6), 1]],
		"triggers": [{"when": "time:0.1", "say": "seize"},
			{"when": "time:14", "calm": true, "say": "voice", "clear": true}]},
	{"id": "immuyeol_end", "theme": "parking", "bounds": Rect2(-5.0, -2.2, 10.0, 4.4), "cast": ["sainjin"], "auto": true,
		"heroes": [Vector2(-2.4, 0.2)], "allies": [],
		"enemies": [["immuyeol", Vector2(1.6, 0.0), {"role": "immuyeol_last"}]], "boss": "immuyeol",
		"triggers": [{"when": "time:0.1", "say": "start"}, {"when": "down:immuyeol", "say": "after"}]},
	{"id": "museum_talk", "theme": "museum_plaza", "bounds": Rect2(-5.0, -2.0, 10.0, 4.0), "cast": ["kimshin"], "talk": 0.0,
		"heroes": [Vector2(-1.4, 0.4)], "allies": [], "enemies": [],
		"standing": [["choeminuk", Vector2(1.4, 0.0), 1], ["mahakyoung", Vector2(2.6, -1.0), 1], ["sainjin", Vector2(2.8, 1.0), 1]]},
	{"id": "mori_council", "theme": "meeting_room", "bounds": Rect2(-5.0, -2.0, 10.0, 4.0), "cast": ["hide"], "auto": true,
		"heroes": [Vector2(-2.0, 0.2)], "allies": [], "ranks": {"pro_fighter": "외성 하위"},
		"enemies": [["pro_fighter", Vector2(1.8, 0.0), {"name": "회색 정장 간부"}]], "boss": "pro_fighter",
		"triggers": [{"when": "time:0.1", "say": "start"}, {"when": "down:pro_fighter", "say": "after"}]},
	{"id": "gustav_komodo", "theme": "port_alley", "bounds": Rect2(-6.0, -2.4, 12.0, 4.8), "cast": ["gustav"], "auto": true,
		"heroes": [Vector2(-3.4, 0.2)], "allies": [], "ranks": {"komodo": "외성 상위"},
		"enemies": [["komodo", Vector2(1.6, 0.0)]], "boss": "komodo",
		"standing": [["blackmamba", Vector2(3.8, -1.2), 0]],
		"triggers": [{"when": "time:0.1", "say": "start"}, {"when": "down:komodo", "say": "after"}]},
	{"id": "majun_prison", "theme": "cage_pit", "bounds": Rect2(-6.0, -2.4, 12.0, 4.8), "cast": ["majunyeong"], "auto": true,
		"heroes": [Vector2(0.0, 0.2)], "allies": [],
		"enemies": [["street_thug", Vector2(-3.4, -1.4), {"name": "수감자", "tag": "w1"}], ["street_thug", Vector2(-3.0, 1.6), {"name": "수감자", "tag": "w1"}],
			["street_thug", Vector2(3.2, -1.2), {"name": "수감자", "tag": "w1"}], ["gang_brute", Vector2(3.4, 1.4), {"name": "갱단 거구", "tag": "w1"}]],
		"triggers": [{"when": "down:w1", "say": "wave",
			"spawn": [["street_thug", Vector2(-5.8, -1.0), {"name": "수감자"}], ["street_thug", Vector2(-5.8, 1.2), {"name": "수감자"}],
				["street_thug", Vector2(5.8, -1.4), {"name": "수감자"}], ["gang_brute", Vector2(5.8, 1.0), {"name": "흑인 갱단 두목"}]]}]},
	{"id": "epilogue_roof", "theme": "rooftop_dusk", "bounds": Rect2(-5.0, -2.2, 10.0, 4.4), "cast": ["woojin"], "talk": 0.0,
		"heroes": [Vector2(-1.2, 0.2)], "allies": [], "enemies": [],
		"standing": [["medvedi", Vector2(1.4, -0.2), 0]]},
	{"id": "part1_end", "theme": "rooftop_dusk", "bounds": Rect2(-5.0, -2.2, 10.0, 4.4), "cast": ["woojin"],
		"heroes": [Vector2(-1.0, 0.2)], "allies": [], "enemies": [], "boss": "", "end": true},
]

const INTRO_T := 75
const CLEAR_T := 90
const END_T := 360
const HEAL_ON_CLEAR := 0.0
const MAX_ATTACKERS := 2
