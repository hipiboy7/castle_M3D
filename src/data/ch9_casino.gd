extends RefCounted
## 9장 화진의 유우성(2부 15-32) 장 표 — 칸 뜻은 ch3_busan.gd 와 같다. 스테이지는 사용자 목록 그대로(2026-11-10 폰 리뷰 rc.8).
## 편(사용자 답 2): CLUB BUDAPEST 의 바이슨 · 판테라(이스크라 뜨거운피)는 서진태의 적, 왕하오밍 선박의 이스크라(크리사 · 크로트 · 샤이어 ·
## 라텔)는 우리 편. 화진(유우성 = 롱터우 · 앤디청 · 링링 · 사천왕 · 리천(톱))이 적.
## 흐름(화/컷 — castle_common canon fights · work/text 원작 대사):
##   1 백의 사무실(대화 — 015/060-080) — 여민수 + 백의 5명 대 유우성 + 앤디청 + 화진 10명. 싸우지 않는다: 화진이 백의를 에워싸고,
##     김신은 문 안에서 목소리로만 '들여보내라'(서 있는 사람 standing — 김신은 화면에 없다, 조작 칸은 여민수)
##   2 CLUB BUDAPEST(fight:jintae_clubbudapest 019-022) — 서진태 대 바이슨 + 판테라. 바이슨 피 반 → 그롤라가 나타나 말하고(020/058-071),
##     싸우려 들면 아킬라가 총을 겨누며 들어와(020/076-092) 그롤라와 말을 주고받는다 → 그롤라 '순 병X 집합소 아닌가'(020/097) ·
##     '혹시라도 탈퇴하면 연락 주고'(022/101)로 끝(triggers hp → spawn · calm · say · clear)
##   3 메드베디 장례식(대화 — 023/054-102) — 김신 · 피우진 · 서진태 · 여민수 · 크리사 · 라텔 대 리사 · 그롤라 · 블랙맘바 · 잭슨 · 바이슨 ·
##     판테라 · 블루 인력 5명. 서로 말하다 김신 '언제 내 기분이 바뀌어서.. 이스크라를 폐기처분해 버릴지 몰라'(023/098-102)로 끝
##   4 왕하오밍 선박 카지노 1(fight:jintae_sacheonwang 025-027) — 서진태 대 주천명(1차전) → 쓰러뜨리면 앤디청이 나와 이어서(027/032-033),
##     앤디청 피 반 → 멘트 후 싸움이 파함(027/123-149)
##   5 선박 카지노 2(031/059-122) — 서진태 대 유우성, 2분 버티면 크리사가 와서 연막탄(029/015-038)을 던지고 끝
##   6 선박 카지노 3(fight:pyoyoung_jokki 028-030) — 라텔 + 표영 대 리천, 3분 버티기
##   7 선박 카지노 4(fight:krot_shire 028-030) — 크로트 + 샤이어 대 링링 + 화진 일당 10명, 3분 버티기(화진은 두 무리 — 앞 무리가 쓰러지면 다음)
##   8 선박 카지노 5(fight:jintae_jokki 031/180-189) — 서진태 대 리천: 90초 버틴 뒤 10초 안에 빠져나가기(사용자 '1분 버티고 30초 후
##     10초 안에' — 나의 해석 = survive 90 → escape 10, 오케스트레이터 메모)
##   9 배 선상 위(fight:jintae_jokki 032) — 라텔 + 서진태 대 리천 · 유우성 · 링링 · 사천왕 · 화진 일당 10명. 1분 안에 죽지 않고 빠져나가기,
##     크고 긴 맵(뒤에서 리천 · 유우성 · 링링이 쫓고, 앞에서 사천왕 · 화진이 두 무리로 막는다)
##   10 끝 — 유우성이 크리사를 처형하고 판을 정리한다(fight:sikkal_talchul 032 — 끝 글)
## 원작과 다른 점: 1 방 '들여보내라'는 사용자 연출(원작 015/078 은 문이 열리는 소리만). 주천명은 원작 외형이 없어 격투가 외형에 이름만.
## '블루 인력'은 이름 없는 엑스트라(정장 외형). 사천왕 넷은 민머리 · 은보 · 바가지 머리 · 회색 정장(canon factions sacheonwang).
## 난이도(사용자): 서진태(외성 중위)보다 아랫급 보스(바이슨 · 주천명 · 앤디청)는 dmg_k ≤ 1 · 빨리, 윗급(유우성 · 리천)은 버티기 ·
## 빠져나가기로 — 쓰러뜨릴 수 없다(hp_floor). 화진 조직원(건달급)은 1 ~ 2대. 수치는 봇 판(tests/sim_rooms.gd ch9 seeds=1..8).

const EVENT := "beat:mark"            # 시점: 8장 뒤 — 김신 톱 · 서진태 외성 중위 · 피우진 준10강
const PERIOD := "hwajin"

const CANON := {
	"baekui_office": {"fight": "", "place": "baekui_office"},      # 대화 방(fight:hwajin_baekui_office 015-016 — 싸우지 않는 장면으로)
	"club_budapest": {"fight": "fight:jintae_clubbudapest", "place": "clubbudapest"},
	"medvedi_funeral": {"fight": "", "place": "vladivostok"},
	"casino_1": {"fight": "fight:jintae_sacheonwang", "place": "hongkong"},
	"casino_2": {"fight": "fight:jintae_sacheonwang", "place": "hongkong"},
	"casino_3": {"fight": "fight:pyoyoung_jokki", "place": "hongkong"},
	"casino_4": {"fight": "fight:krot_shire", "place": "hongkong"},
	"casino_5": {"fight": "fight:jintae_jokki", "place": "hongkong"},
	"ship_deck": {"fight": "fight:jintae_jokki", "place": "hongkong"},
	"retreat_end": {"fight": "", "place": "hongkong"},
}

## 조작 인물(방마다 cast) — 여민수(1 방 — 서 있기만) · 서진태 · 김신(장례식) · 라텔 · 표영 · 크로트 · 샤이어
const HEROES := ["jintae", "kimshin", "yeominsu", "ratel", "pyoyoung", "krot", "shire"]
const LINES := "ch9"
const CROWD_ID := "street_thug"

const NPCS := {
	"pyoyoung": {"rank": "전국구"},        # (2부 화진 전) 표영
}

const ROLES := {
	"kimshin": {"hp": 200.0, "posture": 60.0, "walk": 2.1, "run": 4.6, "stagger": 50, "look": "kim",
		"moveset": {"combo": "k_slash1", "dash": "k_dash", "counter": "k_counter", "finisher": "k_finisher"}},
	"jintae": {"hp": 230.0, "posture": 70.0, "walk": 2.2, "run": 4.8, "stagger": 50, "look": "jintae",
		"moveset": {"combo": "jk_slash1", "dash": "jk_dash", "finisher": "jk_finisher"}},
	"yeominsu": {"hp": 260.0, "posture": 80.0, "walk": 2.0, "run": 4.3, "stagger": 55, "look": "yeominsu",
		"moveset": {"combo": "ym_1", "dash": "ym_dash", "finisher": "gu_finisher"}},
	# 이스크라(우리 편 — 선박): 라텔(단검) · 표영(카람빗) · 크로트(스틸레토 · 총) · 샤이어(승표 · 쇠사슬) · 크리사(발 — 5 방 아군)
	"ratel": {"hp": 260.0, "posture": 80.0, "walk": 2.2, "run": 4.8, "stagger": 50, "look": "ratel",
		"moveset": {"combo": "rt_1", "dash": "rt_dash", "finisher": "py_finisher"}},
	"pyoyoung": {"hp": 260.0, "posture": 70.0, "walk": 2.3, "run": 5.0, "stagger": 50, "look": "pyoyoung",
		"moveset": {"combo": "py_slash1", "dash": "py_dash", "finisher": "py_finisher"}},
	"krot": {"hp": 280.0, "posture": 80.0, "walk": 2.0, "run": 4.4, "stagger": 50, "look": "krot",
		"moveset": {"combo": "kt_1", "dash": "kt_dash", "finisher": "jk_finisher"}},
	"shire": {"hp": 320.0, "posture": 100.0, "walk": 1.9, "run": 4.2, "stagger": 55, "look": "shire",
		"moveset": {"combo": "srg_1", "dash": "srg_dash", "finisher": "gu_finisher"}},
	"keurisa": {"hp": 260.0, "posture": 80.0, "walk": 2.2, "run": 4.8, "stagger": 50, "look": "keurisa", "ai": "x_kicker",
		"moveset": {"combo": "kr_1", "dash": "kr_dash", "finisher": "w_finisher"}},
	"akila": {"hp": 300.0, "posture": 120.0, "walk": 2.0, "run": 4.4, "stagger": 55, "look": "akila", "ai": "x_gun",
		"moveset": {"combo": "ak_1", "dash": "ak_dash", "finisher": "w_finisher"}},
	"woojin": {"hp": 220.0, "posture": 70.0, "walk": 2.1, "run": 4.6, "stagger": 50, "look": "woojin", "ai": "x_kicker",
		"moveset": {"combo": "w_jab", "dash": "w_dash", "finisher": "w_finisher"}},
	# 이름 없는 무리 — 화진 조직원(건달급 — 1 ~ 2대) · 백의 조직원 · 블루 인력(서 있기만)
	"street_thug": {"hp": 40.0, "posture": 20.0, "walk": 1.8, "run": 3.8, "stagger": 70, "ai": "thug", "look": "ds_raider", "dmg_k": 0.5},
	"gang_blade": {"hp": 55.0, "posture": 25.0, "walk": 1.9, "run": 4.0, "stagger": 70, "ai": "haseong_guard", "look": "haseong_guard", "dmg_k": 0.5},
	"ds_member": {"hp": 120.0, "posture": 40.0, "walk": 1.8, "run": 3.8, "stagger": 70, "ai": "thug", "look": "ds_suit"},
	"haseong_suit": {"hp": 120.0, "posture": 40.0, "walk": 1.8, "run": 3.8, "stagger": 70, "ai": "thug", "look": "gunter_suit"},
	"gang_brute": {"hp": 200.0, "posture": 60.0, "walk": 1.7, "run": 3.6, "stagger": 75, "ai": "thug_brute", "look": "gunter_brute", "dmg_k": 0.5},
	"pro_fighter": {"hp": 220.0, "posture": 80.0, "walk": 2.0, "run": 4.3, "stagger": 75, "ai": "x_kicker", "look": "gunter_bald", "dmg_k": 0.5},
	# CLUB BUDAPEST — 바이슨(피 반에서 멈춤 hp_floor 0.5) · 판테라 · 그롤라 · 아킬라(말만)
	"bison": {"hp": 360.0, "posture": 200.0, "walk": 1.9, "run": 4.1, "stagger": 80, "poise": 24.0, "finisher_cap": 0.08, "ai": "x_grappler",
		"look": "bison", "hp_floor": 0.5, "dmg_k": 0.6},
	"pantera": {"hp": 200.0, "posture": 100.0, "walk": 2.2, "run": 4.8, "stagger": 70, "poise": 10.0, "ai": "x_kicker", "look": "pantera", "dmg_k": 0.5},
	"grolla": {"hp": 1500.0, "posture": 560.0, "walk": 2.1, "run": 4.6, "stagger": 80, "poise": 36.0, "ai": "x_master", "look": "grolla"},
	# 장례식(서 있기만)
	"risa": {"hp": 200.0, "posture": 60.0, "walk": 1.9, "run": 4.0, "stagger": 60, "look": "risa"},
	"blackmamba": {"hp": 200.0, "posture": 60.0, "walk": 1.9, "run": 4.0, "stagger": 60, "look": "blackmamba"},
	"jackson": {"hp": 200.0, "posture": 60.0, "walk": 1.9, "run": 4.0, "stagger": 60, "look": "jackson"},
	# 선박 — 주천명(1차전) → 앤디청(피 반에서 파함 hp_floor 0.5)
	"jucheonmyeong": {"hp": 200.0, "posture": 140.0, "walk": 2.0, "run": 4.3, "stagger": 75, "poise": 14.0, "ai": "x_brawler",
		"look": "gunter_bald", "dmg_k": 0.4},
	"andycheong": {"hp": 300.0, "posture": 220.0, "walk": 2.1, "run": 4.6, "stagger": 75, "poise": 24.0, "finisher_cap": 0.06, "ai": "x_twin",
		"look": "andycheong", "hp_floor": 0.5, "dmg_k": 0.5},
	# 유우성(내성 하위 — 서진태보다 위): 2분 버티기 · 배 위 추격. 쓰러뜨릴 수 없다
	"yuwoosung": {"hp": 900.0, "posture": 400.0, "walk": 2.1, "run": 4.6, "stagger": 80, "poise": 32.0, "finisher_cap": 0.04, "ai": "x_swordmaster",
		"look": "yuwoosung", "hp_floor": 0.3, "dmg_k": 0.25},
	# 리천(톱): 쓰러뜨릴 수 없다 — 버티기 · 퇴각 방
	"richeon": {"hp": 3000.0, "posture": 900.0, "walk": 2.1, "run": 4.6, "stagger": 80, "poise": 40.0, "finisher_cap": 0.02, "ai": "x_master",
		"look": "richeon", "hp_floor": 0.6, "dmg_k": 0.15},
	"lingling": {"hp": 900.0, "posture": 300.0, "walk": 2.2, "run": 4.8, "stagger": 75, "poise": 20.0, "finisher_cap": 0.08, "ai": "x_kicker",
		"look": "lingling", "hp_floor": 0.3, "dmg_k": 0.5},
	"eunbo": {"hp": 240.0, "posture": 120.0, "walk": 1.8, "run": 3.9, "stagger": 75, "poise": 14.0, "ai": "x_grappler", "look": "eunbo", "dmg_k": 0.5},
}

## 1 방: 화진 열둘이 백의 여섯을 둥글게 에워싼다(가운데 (0.4, 0)) — 서 있는 사람
const _OFFICE_STAND := [
	["ds_member", Vector2(-0.6, -0.9), 0, {"name": "백의 조직원"}], ["ds_member", Vector2(-0.6, 0.9), 0, {"name": "백의 조직원"}],
	["ds_member", Vector2(0.6, -1.1), 0, {"name": "백의 조직원"}], ["ds_member", Vector2(0.6, 1.1), 0, {"name": "백의 조직원"}],
	["ds_member", Vector2(1.4, 0.0), 0, {"name": "백의 조직원"}],
	["yuwoosung", Vector2(3.6, 0.0), 1], ["andycheong", Vector2(3.0, -1.4), 1],
	["street_thug", Vector2(-2.6, -1.4), 1, {"name": "화진 조직원"}], ["street_thug", Vector2(-2.8, 0.2), 1, {"name": "화진 조직원"}],
	["street_thug", Vector2(-2.4, 1.6), 1, {"name": "화진 조직원"}], ["street_thug", Vector2(-1.2, -2.0), 1, {"name": "화진 조직원"}],
	["street_thug", Vector2(-1.0, 2.0), 1, {"name": "화진 조직원"}], ["street_thug", Vector2(0.6, -2.1), 1, {"name": "화진 조직원"}],
	["street_thug", Vector2(0.8, 2.1), 1, {"name": "화진 조직원"}], ["street_thug", Vector2(2.2, -2.0), 1, {"name": "화진 조직원"}],
	["street_thug", Vector2(2.4, 2.0), 1, {"name": "화진 조직원"}], ["street_thug", Vector2(3.2, 1.4), 1, {"name": "화진 조직원"}],
]

## 3 방 메드베디 장례식: 왼쪽 백의 · 이스크라(김신 편), 오른쪽 리사 쪽(뜨거운피 · 블루)
const _FUNERAL_STAND := [
	["woojin", Vector2(-2.6, -1.0), 0], ["jintae", Vector2(-2.6, 1.0), 0], ["yeominsu", Vector2(-3.6, 0.0), 0],
	["keurisa", Vector2(-1.4, -1.6), 0], ["ratel", Vector2(-1.4, 1.6), 0],
	["risa", Vector2(1.6, 0.0), 1], ["grolla", Vector2(2.4, -1.2), 1], ["blackmamba", Vector2(2.6, 1.2), 1], ["jackson", Vector2(3.4, -0.2), 1],
	["bison", Vector2(3.6, -1.8), 1], ["pantera", Vector2(3.8, 1.8), 1],
	["haseong_suit", Vector2(4.6, -1.2), 1, {"name": "블루 인력"}], ["haseong_suit", Vector2(4.6, 0.0), 1, {"name": "블루 인력"}],
	["haseong_suit", Vector2(4.6, 1.2), 1, {"name": "블루 인력"}], ["haseong_suit", Vector2(5.4, -0.6), 1, {"name": "블루 인력"}],
	["haseong_suit", Vector2(5.4, 0.6), 1, {"name": "블루 인력"}],
]

const ROOMS := [
	{"id": "baekui_office", "theme": "office_corridor", "bounds": Rect2(-6.0, -2.4, 12.0, 4.8), "cast": ["yeominsu"], "talk": 0.0,
		"heroes": [Vector2(0.2, 0.0)], "allies": [], "enemies": [], "standing": _OFFICE_STAND},
	{"id": "club_budapest", "theme": "club_budapest", "bounds": Rect2(-6.0, -2.4, 12.0, 4.8), "cast": ["jintae"],
		"heroes": [Vector2(-4.0, 0.2)], "allies": [],
		"enemies": [["pantera", Vector2(1.6, -1.2)], ["bison", Vector2(2.4, 0.6)]], "boss": "bison",
		"triggers": [
			{"when": "hp:bison:0.5", "calm": true, "spawn": [["grolla", Vector2(5.4, -0.8)]], "say": "grolla", "clear": true},
			{"when": "after:0:10.1", "spawn_allies": [["akila", Vector2(-6.4, 1.2)]], "calm": true}]},
	{"id": "medvedi_funeral", "theme": "funeral", "bounds": Rect2(-6.0, -2.4, 12.0, 4.8), "cast": ["kimshin"], "talk": 0.0,
		"heroes": [Vector2(-0.4, 0.0)], "allies": [], "enemies": [], "standing": _FUNERAL_STAND},
	{"id": "casino_1", "theme": "casino_deck", "bounds": Rect2(-6.4, -2.4, 12.8, 4.8), "cast": ["jintae"],
		"heroes": [Vector2(-4.2, 0.2)], "allies": [],
		"enemies": [["jucheonmyeong", Vector2(2.0, 0.0), {"name": "주천명"}]], "boss": "jucheonmyeong",
		"triggers": [
			{"when": "down:jucheonmyeong", "spawn": [["andycheong", Vector2(5.6, -0.6)]], "boss": "andycheong", "say": "andy_in"},
			{"when": "hp:andycheong:0.5", "calm": true, "say": "andy_out", "clear": true}]},
	{"id": "casino_2", "theme": "casino_deck", "bounds": Rect2(-6.4, -2.4, 12.8, 4.8), "cast": ["jintae"], "survive": 120.0,
		"heroes": [Vector2(-4.2, 0.2)], "allies": [],
		"enemies": [["yuwoosung", Vector2(2.4, 0.0)]], "boss": "yuwoosung",
		"triggers": [{"when": "time:40", "say": "sister"},
			{"when": "time:113", "spawn_allies": [["keurisa", Vector2(-7.0, -1.6)]], "calm": true, "say": "smoke"}]},
	{"id": "casino_3", "theme": "casino_deck", "bounds": Rect2(-7.0, -2.4, 14.0, 4.8), "cast": ["ratel", "pyoyoung"], "survive": 180.0,
		"heroes": [Vector2(-4.4, -0.8), Vector2(-4.4, 1.0)], "allies": [],
		"enemies": [["richeon", Vector2(2.6, 0.0)]], "boss": "richeon",
		"triggers": [{"when": "time:50", "say": "mid"}, {"when": "time:120", "say": "late"}]},
	{"id": "casino_4", "theme": "casino_deck", "bounds": Rect2(-7.0, -2.4, 14.0, 4.8), "cast": ["krot", "shire"], "survive": 180.0,
		"heroes": [Vector2(-4.4, -0.8), Vector2(-4.4, 1.0)], "allies": [],
		"enemies": [["lingling", Vector2(3.4, 0.0)],
			["street_thug", Vector2(1.0, -1.6), {"name": "화진 조직원", "tag": "h1"}], ["street_thug", Vector2(1.4, 1.6), {"name": "화진 조직원", "tag": "h1"}],
			["gang_blade", Vector2(2.2, -0.8), {"name": "화진 칼잡이", "tag": "h1"}], ["street_thug", Vector2(2.4, 1.0), {"name": "화진 조직원", "tag": "h1"}],
			["gang_blade", Vector2(4.6, -1.6), {"name": "화진 칼잡이", "tag": "h1"}]], "boss": "lingling",
		"triggers": [{"when": "down:h1", "say": "wave",
			"spawn": [["street_thug", Vector2(7.0, -1.8), {"name": "화진 조직원"}], ["street_thug", Vector2(7.0, -0.6), {"name": "화진 조직원"}],
				["gang_blade", Vector2(7.0, 0.6), {"name": "화진 칼잡이"}], ["street_thug", Vector2(7.0, 1.8), {"name": "화진 조직원"}],
				["gang_blade", Vector2(-7.0, 1.8), {"name": "화진 칼잡이"}]]}]},
	{"id": "casino_5", "theme": "casino_deck", "bounds": Rect2(-8.0, -2.0, 16.0, 4.0), "cast": ["jintae"], "survive": 90.0,
		"heroes": [Vector2(-5.4, 0.0)], "allies": [],
		"enemies": [["richeon", Vector2(0.4, 0.0)]], "boss": "richeon",
		"triggers": [{"when": "survive", "escape": {"exit": Rect2(6.6, -2.0, 1.4, 4.0), "secs": 10.0}, "say": "run"}]},
	{"id": "ship_deck", "theme": "ship_deck", "bounds": Rect2(-16.0, -3.0, 32.0, 6.0), "cast": ["ratel", "jintae"],
		"heroes": [Vector2(-12.6, -0.8), Vector2(-12.6, 0.8)], "allies": [],
		"escape": {"secs": 60.0, "exit": Rect2(14.2, -3.0, 1.8, 6.0)},
		"enemies": [["richeon", Vector2(-15.6, 0.0)], ["yuwoosung", Vector2(-15.6, -1.8)], ["lingling", Vector2(-15.6, 1.8)],
			["gang_brute", Vector2(-7.0, -1.2), {"name": "사천왕 민머리"}], ["eunbo", Vector2(-6.6, 1.2)],
			["street_thug", Vector2(-3.0, -2.0), {"name": "화진 조직원"}], ["street_thug", Vector2(-2.6, 0.4), {"name": "화진 조직원"}],
			["gang_blade", Vector2(-2.2, 2.2), {"name": "화진 칼잡이"}],
			["pro_fighter", Vector2(2.4, -1.0), {"name": "사천왕 바가지 머리"}], ["gang_brute", Vector2(2.8, 1.4), {"name": "사천왕 회색 정장"}],
			["street_thug", Vector2(6.0, -2.2), {"name": "화진 조직원"}], ["street_thug", Vector2(6.4, 0.0), {"name": "화진 조직원"}],
			["gang_blade", Vector2(6.8, 2.0), {"name": "화진 칼잡이"}]], "boss": "richeon",
		"triggers": [{"when": "time:3", "say": "front",
			"spawn": [["street_thug", Vector2(11.0, -2.0), {"name": "화진 조직원"}], ["street_thug", Vector2(11.4, -0.4), {"name": "화진 조직원"}],
				["street_thug", Vector2(11.0, 1.4), {"name": "화진 조직원"}], ["gang_blade", Vector2(11.6, 2.4), {"name": "화진 칼잡이"}]]}]},
	{"id": "retreat_end", "theme": "ship_deck", "bounds": Rect2(-5.0, -2.0, 10.0, 4.0), "cast": ["jintae"],
		"heroes": [Vector2(-1.6, 0.4)], "allies": [], "enemies": [], "boss": "", "end": true},
]

const INTRO_T := 75
const CLEAR_T := 150
const END_T := 360
const HEAL_ON_CLEAR := 0.25
const MAX_ATTACKERS := 2
