extends RefCounted
## 5장 장례 · 백의 결성(1부 p1:086-088) — **싸움 없는 장**(기획서 02 3절 '전투 없음 — 대화 · 장면'). 방은 모두 대화 방(talk — stage.gd:
## rooms.<방>.say 줄을 차례로 보이고 다음 방으로). 칸 뜻은 ch3_busan.gd 와 같다. 아군(이슬 · 피우진 · 서진태)은 김신 곁에 선다.
##   1 회암장례식장(p1:086) — 김대건의 장례
##   2 옥상 · 노을(p1:087-088) — 흩어졌던 사람들이 '백의'로 모인다
##   3 끝

const EVENT := "beat:gustav"
const PERIOD := "p1"

const CANON := {
	"funeral_hall": {"fight": "", "place": "hoeamjangnyesikjang"},
	"rooftop": {"fight": "", "place": "hoeamsi"},
	"rooftop_end": {"fight": "", "place": "hoeamsi"},
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
	"street_thug": {"hp": 220.0, "posture": 45.0, "walk": 1.8, "run": 3.8, "stagger": 70, "ai": "thug", "look": "ds_raider"},
}

const ROOMS := [
	{"id": "funeral_hall", "theme": "funeral", "bounds": Rect2(-5.0, -2.2, 10.0, 4.4), "cast": ["kimshin"], "talk": 0.0,
		"heroes": [Vector2(0.0, 0.6)], "allies": [["woojin", Vector2(-1.6, 0.8)], ["iseul", Vector2(1.6, 0.8)], ["jintae", Vector2(2.6, 1.4)]],
		"enemies": []},
	{"id": "rooftop", "theme": "rooftop_dusk", "bounds": Rect2(-5.0, -2.2, 10.0, 4.4), "cast": ["kimshin"], "talk": 0.0,
		"heroes": [Vector2(0.0, -0.6)], "allies": [["woojin", Vector2(-1.4, 0.4)], ["iseul", Vector2(1.6, 0.4)], ["jintae", Vector2(-2.6, 0.8)]],
		"enemies": []},
	{"id": "rooftop_end", "theme": "rooftop_dusk", "bounds": Rect2(-5.0, -2.2, 10.0, 4.4), "cast": ["kimshin"],
		"heroes": [Vector2(0.0, -0.6)], "allies": [], "enemies": [], "boss": "", "end": true},
]

const INTRO_T := 75
const CLEAR_T := 90
const END_T := 360
const HEAL_ON_CLEAR := 0.0
const MAX_ATTACKERS := 2
