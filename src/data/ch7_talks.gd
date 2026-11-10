extends RefCounted
## 7장 임무열 처단 · 최민욱 담판(1부 p1:117-121 — 122 후기는 장 밖) — **싸움 없는 장**(기획서 02 3절 '(대화)'). 방은 대화 방(talk).
## 칸 뜻은 ch3_busan.gd 와 같다. 아군은 그 장면에 원작에서 김신 곁에 있던 사람만 세운다.
## 흐름(2026-11-10 원작 장면 차례로 다시 맞춤 — castle_common canon episodes p1_117 ~ 121, conf ai 판독):
##   1 미술관(p1:117 → 118) — 임무열은 김황의 시신을 싣고 최민욱을 찾아가 자백한 뒤 처형된다(fight:immuyeol_castleguards ·
##     fight:immuyeol_sainjin — 김신은 없다, 대사로). 붕대투성이 김신이 홀로 은신처를 나서 휴관한 미술관에서 최민욱과 **단독** 담판 —
##     로댕 〈지옥의 문〉 앞, 마학영 · 사인진(캐슬)이 곁에 선다(p1:118/000-081)
##   2 회암시 합동 장례(p1:119/094-115 · funeral:hoeamsi) — 백의 · 하성 식구가 풀려나고, 수원 박철규는 떠나고(leave:bakcheolgyu)
##     포항 도학수 · 대구 어광득은 남는다. 병원의 이슬 · 구일화(p1:119/116-179)는 대사로
##   3 오월동주 회의실(p1:119/195-228 · meeting:owoldongju) — 최민욱 · 천일도 · 리사 · 유우성 · 김태훈의 탁자에 '백의 김신'이 앉는다
##   4 에필로그(p1:121) — 블라디보스토크 클럽 발레리노 옥상: 피우진이 리사의 이스크라 입단 제안을 거절하고 김신을 따르겠다 한다.
##     구스타프가 코모도를 쓰러뜨리고(fight:gustav_komodo) · 히데가 모리를 쥐고 · 마준영이 북미 형무소에서 이긴다 — 대사로
##   5 끝 — 1부 끝 · 2부(8장)로
## 원작과 다른 점: 최민욱 · 마학영 · 김태훈 · 리사 등은 대화 방에 세우지 않는다(김신 편도 적도 아닌 자리 — 대사로만).

const EVENT := "beat:baekdochan"
const PERIOD := "p1"

const CANON := {
	"museum_talk": {"fight": "", "place": "misulgwan"},
	"hoeam_funeral": {"fight": "", "event": "funeral:hoeamsi", "place": "hoeamsi_pyechajang"},
	"owoldongju": {"fight": "", "event": "meeting:owoldongju", "place": "hoeamsi"},
	"epilogue_roof": {"fight": "", "place": "club_ballerino"},
	"part1_end": {"fight": "", "place": "club_ballerino"},
}

const HEROES := ["kimshin", "woojin"]
const LINES := "ch7"
const CROWD_ID := "street_thug"

const ROLES := {
	"kimshin": {"hp": 200.0, "posture": 60.0, "walk": 2.1, "run": 4.6, "stagger": 50, "look": "kim_p1_blade",
		"moveset": {"combo": "k_slash1", "dash": "k_dash", "counter": "k_counter", "finisher": "k_finisher"}},
	"woojin": {"hp": 220.0, "posture": 70.0, "walk": 2.1, "run": 4.6, "stagger": 50, "look": "woojin",
		"moveset": {"combo": "w_jab", "dash": "w_dash", "finisher": "w_finisher"}},
	# 남은 지방 보스(합동 장례 — 대화 방이라 싸우지 않는다. 동작 칸은 비슷한 손의 것을 빌린다)
	"dohaksu": {"hp": 240.0, "posture": 80.0, "walk": 2.0, "run": 4.3, "stagger": 55, "look": "dohaksu",
		"moveset": {"combo": "gu_jab", "dash": "gu_dash", "finisher": "gu_finisher"}},
	"eogwangdeuk": {"hp": 240.0, "posture": 80.0, "walk": 2.0, "run": 4.3, "stagger": 55, "look": "eogwangdeuk",
		"moveset": {"combo": "gu_jab", "dash": "gu_dash", "finisher": "gu_finisher"}},
	"street_thug": {"hp": 220.0, "posture": 45.0, "walk": 1.8, "run": 3.8, "stagger": 70, "ai": "thug", "look": "ds_raider"},
}

const ROOMS := [
	{"id": "museum_talk", "theme": "museum_plaza", "bounds": Rect2(-5.0, -2.0, 10.0, 4.0), "cast": ["kimshin"], "talk": 0.0,
		"heroes": [Vector2(-1.0, 0.4)], "allies": [], "enemies": []},
	{"id": "hoeam_funeral", "theme": "junkyard_dusk", "bounds": Rect2(-5.0, -2.2, 10.0, 4.4), "cast": ["kimshin"], "talk": 0.0,
		"heroes": [Vector2(0.0, -0.4)], "allies": [["dohaksu", Vector2(-1.6, 0.8)], ["eogwangdeuk", Vector2(1.6, 0.8)]], "enemies": []},
	{"id": "owoldongju", "theme": "meeting_room", "bounds": Rect2(-5.0, -2.0, 10.0, 4.0), "cast": ["kimshin"], "talk": 0.0,
		"heroes": [Vector2(-2.0, 0.0)], "allies": [], "enemies": []},
	{"id": "epilogue_roof", "theme": "rooftop_dusk", "bounds": Rect2(-5.0, -2.2, 10.0, 4.4), "cast": ["woojin"], "talk": 0.0,
		"heroes": [Vector2(-1.0, 0.2)], "allies": [], "enemies": []},
	{"id": "part1_end", "theme": "rooftop_dusk", "bounds": Rect2(-5.0, -2.2, 10.0, 4.4), "cast": ["woojin"],
		"heroes": [Vector2(-1.0, 0.2)], "allies": [], "enemies": [], "boss": "", "end": true},
]

const INTRO_T := 75
const CLEAR_T := 90
const END_T := 360
const HEAL_ON_CLEAR := 0.0
const MAX_ATTACKERS := 2
