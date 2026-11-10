extends RefCounted
## 5장 장례 · 백의 결성(1부 p1:086-088) — **싸움 없는 장**(기획서 02 3절 '전투 없음 — 대화 · 장면'). 방은 모두 대화 방(talk — stage.gd:
## rooms.<방>.say 줄을 차례로 보이고 다음 방으로). 칸 뜻은 ch3_busan.gd 와 같다. 아군은 그 장면에 원작에서 김신 곁에 있던 사람만 세운다.
## 흐름(2026-11-10 원작 장면 차례로 다시 맞춤 — castle_common canon episodes p1_086 ~ 088 beats, conf ai 판독):
##   1 부진폐차장 빈소(p1:086 · funeral:kimdaegeon) — 대사 없는 장례: 상주 완장의 김신 · 피우진, 조문객을 맞는 이슬, 서진태, 조문 온 천안 구일화.
##     빗속 처마 밑에서 피우진 · 김신이 복수를 다짐(p1:086/022-026)
##   2 놀이공원 회담(p1:087/005-008 · 088/000-004) — 하성 김태훈 회장 · 오비서 앞에서 김신이 '내일 밤 인천항'을 선언하고 이스크라의 마담
##     리사(조커)를 내놓는다. 곁에 서진태 · 장발의 피우진(p1:088/004 — 셋이 함께 걸어 나감)
##   3 빈소 마당 · 노을(p1:088/005-008 · found:baekui) — 남은 각지 보스들 앞 연설 → 포항 도학수가 따지고 → 천안 구일화가 먼저 무릎 →
##     순천 여민수 · 대구 어광득 · 수원 박철규 · 도학수가 따른다 → '지금부터 우리는 백의'
##   4 끝 — 흰 줄 완장의 백의 무리가 밤의 인천항으로 행진(p1:088/008)
## 원작과 다른 점: 여민수 · 박철규는 이 판에 그림이 없어 대사로만. 김태훈 · 리사도 대사로만(이 장에서 김신 편도 적도 아닌 거래 상대).
## 도지웅 고깃집(이름 '백의'를 받는 자리 p1:088/002-003)은 3 방 대사로.

const EVENT := "beat:gustav"
const PERIOD := "p1"

const CANON := {
	"funeral_hall": {"fight": "", "event": "funeral:kimdaegeon", "place": "bujinpyechajang"},
	"park_meeting": {"fight": "", "place": "hoeamsi"},
	"baekui_oath": {"fight": "", "event": "found:baekui", "place": "bujinpyechajang"},
	"march_end": {"fight": "", "place": "incheonhang"},
}

const HEROES := ["kimshin"]
const LINES := "ch5"
const CROWD_ID := "street_thug"

const ROLES := {
	"kimshin": {"hp": 200.0, "posture": 60.0, "walk": 2.1, "run": 4.6, "stagger": 50, "look": "kim_p1_blade",
		"moveset": {"combo": "k_slash1", "dash": "k_dash", "counter": "k_counter", "finisher": "k_finisher"}},
	"woojin": {"hp": 220.0, "posture": 70.0, "walk": 2.1, "run": 4.6, "stagger": 50, "look": "woojin",
		"moveset": {"combo": "w_jab", "dash": "w_dash", "finisher": "w_finisher"}},
	"jintae": {"hp": 230.0, "posture": 70.0, "walk": 2.2, "run": 4.8, "stagger": 50, "look": "jintae",
		"moveset": {"combo": "jk_slash1", "dash": "jk_dash", "finisher": "jk_finisher"}},
	"iseul": {"hp": 260.0, "posture": 90.0, "walk": 1.9, "run": 4.2, "stagger": 55, "look": "iseul",
		"moveset": {"combo": "ia_hook", "dash": "ia_dash", "finisher": "ia_finisher"}},
	# 각지 보스(백의 결성 — 대화 방이라 싸우지 않는다. 동작 칸은 비슷한 손의 것을 빌린다)
	"guilhwa": {"hp": 260.0, "posture": 90.0, "walk": 2.0, "run": 4.4, "stagger": 55, "look": "guilhwa",
		"moveset": {"combo": "gu_jab", "dash": "gu_dash", "finisher": "gu_finisher"}},
	"dohaksu": {"hp": 240.0, "posture": 80.0, "walk": 2.0, "run": 4.3, "stagger": 55, "look": "dohaksu",
		"moveset": {"combo": "dhg_1", "dash": "dhg_dash", "finisher": "gu_finisher"}},
	"eogwangdeuk": {"hp": 240.0, "posture": 80.0, "walk": 2.0, "run": 4.3, "stagger": 55, "look": "eogwangdeuk",
		"moveset": {"combo": "egg_1", "dash": "egg_dash", "finisher": "gu_finisher"}},
	"street_thug": {"hp": 220.0, "posture": 45.0, "walk": 1.8, "run": 3.8, "stagger": 70, "ai": "thug", "look": "ds_raider"},
}

const ROOMS := [
	{"id": "funeral_hall", "theme": "funeral", "bounds": Rect2(-5.0, -2.2, 10.0, 4.4), "cast": ["kimshin"], "talk": 0.0,
		"heroes": [Vector2(0.0, 0.6)], "allies": [["woojin", Vector2(-1.6, 0.8)], ["iseul", Vector2(1.6, 0.8)], ["jintae", Vector2(2.6, 1.4)],
			["guilhwa", Vector2(-2.8, 1.6)]],
		"enemies": []},
	{"id": "park_meeting", "theme": "park_plaza", "bounds": Rect2(-5.0, -2.2, 10.0, 4.4), "cast": ["kimshin"], "talk": 0.0,
		"heroes": [Vector2(0.0, 0.2)], "allies": [["jintae", Vector2(-1.6, 0.8)], ["woojin", Vector2(1.6, 0.8)]],
		"enemies": []},
	{"id": "baekui_oath", "theme": "junkyard_dusk", "bounds": Rect2(-5.6, -2.2, 11.2, 4.4), "cast": ["kimshin"], "talk": 0.0,
		"heroes": [Vector2(0.0, -0.6)], "allies": [["guilhwa", Vector2(-1.4, 0.8)], ["dohaksu", Vector2(1.4, 0.8)], ["eogwangdeuk", Vector2(2.8, 1.2)],
			["iseul", Vector2(-2.8, 1.2)], ["jintae", Vector2(-3.8, -0.2)], ["woojin", Vector2(3.8, -0.2)]],
		"enemies": []},
	{"id": "march_end", "theme": "port_alley", "bounds": Rect2(-5.0, -2.2, 10.0, 4.4), "cast": ["kimshin"],
		"heroes": [Vector2(0.0, -0.6)], "allies": [], "enemies": [], "boss": "", "end": true},
]

const INTRO_T := 75
const CLEAR_T := 90
const END_T := 360
const HEAL_ON_CLEAR := 0.0
const MAX_ATTACKERS := 2
