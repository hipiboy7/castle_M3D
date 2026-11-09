extends RefCounted
## 7장 임무열 처단 · 최민욱 담판(1부 p1:117-121 — 122 후기는 장 밖) — **싸움 없는 장**(기획서 02 3절 '(대화)'). 방은 대화 방(talk).
##   1 고층 회의실 앞(fight:immuyeol_castleguards 의 무대 p1:117) — 최민욱과 만나는 자리
##   2 항구 뒷골목 밤(p1:121) — 러시아행 밀항로, 구스타프와 코모도(대사로만)
##   3 끝 — 1부 끝 · 2부(8장)로

const EVENT := "beat:baekdochan"
const PERIOD := "p1"

const CANON := {
	"meeting_room": {"fight": "", "place": "hoeamsi"},
	"port_alley": {"fight": "", "place": "incheonhang"},
	"part1_end": {"fight": "", "place": "incheonhang"},
}

const HEROES := ["kimshin"]
const LINES := "ch7"
const CROWD_ID := "street_thug"

const ROLES := {
	"kimshin": {"hp": 200.0, "posture": 60.0, "walk": 2.1, "run": 4.6, "stagger": 50, "look": "kim_p1_blade",
		"moveset": {"combo": "k_slash1", "dash": "k_dash", "counter": "k_counter", "finisher": "k_finisher"}},
	"jintae": {"hp": 230.0, "posture": 70.0, "walk": 2.2, "run": 4.8, "stagger": 50, "look": "jintae",
		"moveset": {"combo": "jk_slash1", "dash": "jk_dash", "finisher": "jk_finisher"}},
	"woojin": {"hp": 220.0, "posture": 70.0, "walk": 2.1, "run": 4.6, "stagger": 50, "look": "woojin",
		"moveset": {"combo": "w_jab", "dash": "w_dash", "finisher": "w_finisher"}},
	"street_thug": {"hp": 220.0, "posture": 45.0, "walk": 1.8, "run": 3.8, "stagger": 70, "ai": "thug", "look": "ds_raider"},
}

const ROOMS := [
	{"id": "meeting_room", "theme": "meeting_room", "bounds": Rect2(-5.0, -2.0, 10.0, 4.0), "cast": ["kimshin"], "talk": 0.0,
		"heroes": [Vector2(-2.0, 0.0)], "allies": [["jintae", Vector2(-3.2, 0.8)], ["woojin", Vector2(-3.4, -0.6)]], "enemies": []},
	{"id": "port_alley", "theme": "port_alley", "bounds": Rect2(-5.6, -2.2, 11.2, 4.4), "cast": ["kimshin"], "talk": 0.0,
		"heroes": [Vector2(-1.0, 0.2)], "allies": [], "enemies": []},
	{"id": "part1_end", "theme": "port_alley", "bounds": Rect2(-5.0, -2.2, 10.0, 4.4), "cast": ["kimshin"],
		"heroes": [Vector2(-1.0, 0.2)], "allies": [], "enemies": [], "boss": "", "end": true},
]

const INTRO_T := 75
const CLEAR_T := 90
const END_T := 360
const HEAL_ON_CLEAR := 0.0
const MAX_ATTACKERS := 2
