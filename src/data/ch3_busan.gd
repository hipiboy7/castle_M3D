extends RefCounted
## 3장 청주 교도소 · 블라디보스토크 케이지 · 부산(1부 p1:037-060) 장 표 — 칸 뜻은 hotel.gd · haseong.gd 와 같다(stage.gd 가 장 id ch3 으로 읽는다).
## 조작: 방마다 한 사람(cast) — 원작이 김신 쪽 사람들을 따로따로 보여 준다(이슬 · 피우진 · 서진태 · 김신 · 표영 — 백의 결성은 5장 088).
## 밤 시장 골목만 김신 · 서진태 교대.
## 편(castle_common canon 2026-11-10 다시 봄): 김신 · 서진태 · 피우진(이스크라 출신) · 이슬(청주 교도소 수감 — 남구청년회) 쪽.
## 구일화는 감방에서 이슬에게 진 뒤(038 회상) 샤워장 습격에서는 이슬과 같은 편(fight:cheongju_shower). 표영은 오락실에서 서진태에게
## '시험'받은 뒤(043 김신이 말림) 김신 쪽 — 모승규 사무실은 표영 조작. 오도화 · 마사는 적, 샤이어(승표 · 민머리 복면)는 김신을 돕는다.
## 흐름(castle_common canon fights — 화/컷, conf ai 판독):
##   1 청주 교도소 감방(fight:cheongju_cell p1:038 회상) — 이슬 대 구일화 일대일 — 주먹 한 방 · 힘으로 내리눌러 꿇린다
##   2 청주 교도소 샤워장(fight:cheongju_shower p1:038) — 이슬 · 구일화(아군) 대 칫솔 칼 습격 무리 — 끝 = 칼 맞은 구일화의 주먹(144-145)
##   3 블라디보스토크 클럽 발레리노(fight:woojin_vasily p1:039-041) — 피우진 대 바실리(190cm 거구) — 머리를 잡고 넘어가며 매트에 내리꽂기
##   4 부산 오락실(fight:jintae_pyoyoung p1:042-043) — 서진태 대 표영(시험) — 명치 주먹 → 후드째 머리를 슬롯머신 화면에
##   5 부산 밤 시장 골목(fight:bulhwi p1:043-044) — 김신 · 서진태 대 붉은 점 가면 무리 · 남일호(결착 없음 → 물러남 yield)
##   6 ROLLING BALL 로비(fight:kimshin_bulgom p1:048-049) — 김신 대 불곰 · 모승규 부하들 — 팔 꺾기, 사지만 부숴 전투 불능
##   7 모승규 사무실(fight:pyoyoung_moseunggyu p1:049-052) — 표영 대 모승규 — 뛰어 무릎 → 책상 너머 올라탄 주먹 연타
##   8 부산 거리(fight:kimshin_odohwa p1:049-051) — 김신 대 오도화(손도끼) · 마사(단도) · 오도화 수하(정장 거구). 샤이어가 승표로 끼어들어
##     마사를 막고(050/133-138) 서진태(파란 후드)가 뛰어내려 마사를 벤다(051/067-070) — 결착 없이 '목적 달성'으로 철수 → 따돌리기(escape)
##   9 끝
## 원작과 다른 점: 불곰은 원작에서 표영 · 정승영 쪽과도 얽힌다(fight:pyoyoung_bulgom) — 김신 한 판으로. 오도화 대 모승규(손도끼 한 방)는 대사로만.
## 샤워장 무대는 감방 무대(prison_cell)를 함께 쓴다. 부산 거리의 샤이어 · 서진태는 원작에서 중간에 끼어들지만 방 처음부터 아군으로 세운다.
## 이름 있는 적은 원형 AI(enemy_ai x_*) + 아래 ROLES 로 손맛을 가른다(2026-11-08 — 3 ~ 13장을 한 번에). 수치는 봇 판(tests/sim_stage.gd ch3)으로.

const EVENT := "beat:yundeoksu"      # 시점: 구스타프 앞 — 김신 내성 중위 · 서진태 외성 하위 · 피우진 경호대급
const PERIOD := "p1"

const CANON := {
	"cheongju_cell": {"fight": "fight:cheongju_cell", "place": "cheongju_prison"},
	"cheongju_shower": {"fight": "fight:cheongju_shower", "place": "cheongju_prison"},
	"ballerino_cage": {"fight": "fight:woojin_vasily", "place": "club_ballerino"},
	"busan_arcade": {"fight": "fight:jintae_pyoyoung", "place": "busan"},
	"busan_night": {"fight": "fight:bulhwi", "place": "busan"},
	"rolling_ball": {"fight": "fight:kimshin_bulgom", "place": "rollingball"},
	"moseunggyu_office": {"fight": "fight:pyoyoung_moseunggyu", "place": "busan"},
	"busan_street": {"fight": "fight:kimshin_odohwa", "place": "busan"},
	"busan_end": {"fight": "", "place": "busan"},
}

const HEROES := ["kimshin", "jintae", "woojin", "iseul", "pyoyoung"]
const LINES := "ch3"
const CROWD_ID := "street_thug"

## 그 장 시점의 등급(강함표의 조건 줄 — 1층 기본값이 다른 시기일 때)
const NPCS := {
	"odohwa": {"rank": "내성 하위"},       # (현 시점) 오도화 — (전성기) 내성 상위는 회상
	"pyoyoung": {"rank": "전국구"},        # (1부) 표영
	"guilhwa": {"rank": "전국구"},         # (화진 전) 구일화
}

const ROLES := {
	"kimshin": {"hp": 200.0, "posture": 60.0, "walk": 2.1, "run": 4.6, "stagger": 50, "look": "kim_p1_blade",
		"moveset": {"combo": "k_slash1", "dash": "k_dash", "counter": "k_counter", "finisher": "k_finisher"}},
	"jintae": {"hp": 230.0, "posture": 70.0, "walk": 2.2, "run": 4.8, "stagger": 50, "look": "jintae",
		"moveset": {"combo": "jk_slash1", "dash": "jk_dash", "finisher": "jk_finisher"}},
	"woojin": {"hp": 220.0, "posture": 70.0, "walk": 2.1, "run": 4.6, "stagger": 50, "look": "woojin",
		"moveset": {"combo": "w_jab", "dash": "w_dash", "finisher": "w_finisher"}},
	"iseul": {"hp": 260.0, "posture": 90.0, "walk": 1.9, "run": 4.2, "stagger": 55, "look": "iseul",
		"moveset": {"combo": "ia_hook", "dash": "ia_dash", "finisher": "ia_finisher"}},
	# 표영: 6 모승규 사무실에서는 조작 인물(카람빗), 3 오락실에서는 적(ai) — 한 줄에 둘 다(stage._npc 가 편에 따라 고른다)
	"pyoyoung": {"hp": 270.0, "posture": 60.0, "walk": 2.3, "run": 5.0, "stagger": 50, "look": "pyoyoung", "ai": "x_karambit",
		"moveset": {"combo": "py_slash1", "dash": "py_dash", "finisher": "py_finisher"}, "dmg_k": 1.3},
	"street_thug": {"hp": 220.0, "posture": 45.0, "walk": 1.8, "run": 3.8, "stagger": 70, "ai": "thug", "look": "ds_raider"},
	"gang_blade": {"hp": 260.0, "posture": 50.0, "walk": 1.9, "run": 4.0, "stagger": 70, "ai": "haseong_guard", "look": "haseong_guard"},
	"gang_brute": {"hp": 340.0, "posture": 70.0, "walk": 1.7, "run": 3.6, "stagger": 75, "ai": "thug_brute", "look": "gunter_brute"},
	# 구일화: 감방에서는 적(ai), 샤워장에서는 아군(moveset — 11장 호텔과 같은 주먹 묶음) — 한 줄에 둘 다(stage._npc 가 편에 따라 고른다)
	"guilhwa": {"hp": 300.0, "posture": 180.0, "walk": 2.0, "run": 4.3, "stagger": 75, "poise": 28.0, "finisher_cap": 0.1, "ai": "x_boxer",
		"look": "guilhwa", "phase2_at": 0.5, "dmg_k": 1.0, "moveset": {"combo": "gu_jab", "dash": "gu_dash", "finisher": "gu_finisher"}},
	"vasily": {"hp": 430.0, "posture": 260.0, "walk": 1.9, "run": 4.1, "stagger": 80, "poise": 32.0, "finisher_cap": 0.06, "ai": "x_grappler",
		"look": "vasily", "phase2_at": 0.5, "dmg_k": 1.0},
	"namilho": {"hp": 1100.0, "posture": 300.0, "walk": 2.1, "run": 4.6, "stagger": 75, "poise": 28.0, "finisher_cap": 0.08, "ai": "x_blade",
		"look": "namilho", "yield_at": 0.35, "dmg_k": 1.8},
	"bulgom": {"hp": 1500.0, "posture": 460.0, "walk": 1.8, "run": 3.9, "stagger": 80, "poise": 34.0, "finisher_cap": 0.06, "ai": "x_grappler",
		"look": "bulgom", "phase2_at": 0.5, "dmg_k": 2.2},
	"moseunggyu": {"hp": 360.0, "posture": 300.0, "walk": 1.8, "run": 3.9, "stagger": 80, "poise": 32.0, "finisher_cap": 0.06, "ai": "x_brawler",
		"look": "moseunggyu", "phase2_at": 0.5, "dmg_k": 0.7},
	"odohwa": {"hp": 2600.0, "posture": 800.0, "walk": 2.0, "run": 4.4, "stagger": 80, "poise": 38.0, "finisher_cap": 0.04, "ai": "x_axe",
		"look": "odohwa", "hp_floor": 0.4, "dmg_k": 1.8},
	"masa": {"hp": 600.0, "posture": 160.0, "walk": 2.0, "run": 4.3, "stagger": 75, "poise": 18.0, "ai": "x_blade", "look": "masa", "dmg_k": 1.2},
	# 아군(봇) — 샤이어(승표 · 민머리 복면 — 050/133-138 마사를 막는다) · 구일화(샤워장 — 천안 구일화, 주먹)
	"shire": {"hp": 320.0, "posture": 120.0, "walk": 1.9, "run": 4.1, "stagger": 60, "look": "shire",
		"moveset": {"combo": "ny_jab", "dash": "ny_dash", "finisher": "ny_finisher"}},
}

const ROOMS := [
	{"id": "cheongju_cell", "theme": "prison_cell", "bounds": Rect2(-5.6, -2.4, 11.2, 4.8), "cast": ["iseul"],
		"heroes": [Vector2(-3.0, 0.2)], "allies": [],
		"enemies": [["guilhwa", Vector2(2.2, 0.0)]], "boss": "guilhwa"},
	{"id": "cheongju_shower", "theme": "prison_cell", "bounds": Rect2(-6.0, -2.4, 12.0, 4.8), "cast": ["iseul"],
		"heroes": [Vector2(-4.0, 0.2)], "allies": [["guilhwa", Vector2(-1.6, -0.8)]],
		"enemies": [["street_thug", Vector2(0.6, -1.4), {"name": "습격 무리"}], ["gang_blade", Vector2(1.2, 1.4), {"name": "칫솔 칼잡이"}],
			["street_thug", Vector2(2.4, -0.2), {"name": "습격 무리"}], ["gang_blade", Vector2(3.4, 1.2), {"name": "칫솔 칼잡이"}],
			["gang_brute", Vector2(4.2, -1.0), {"name": "턱수염 재소자"}]]},
	{"id": "ballerino_cage", "theme": "club_cage", "bounds": Rect2(-5.0, -2.2, 10.0, 4.4), "cast": ["woojin"],
		"heroes": [Vector2(-3.0, 0.2)], "allies": [],
		"enemies": [["vasily", Vector2(2.2, 0.0)]], "boss": "vasily"},
	{"id": "busan_arcade", "theme": "busan_arcade", "bounds": Rect2(-6.0, -2.4, 12.0, 4.8), "cast": ["jintae"],
		"heroes": [Vector2(-4.0, 0.2)], "allies": [],
		"enemies": [["street_thug", Vector2(0.4, -1.4), {"name": "표영 패거리"}], ["street_thug", Vector2(1.0, 1.4), {"name": "표영 패거리"}],
			["pyoyoung", Vector2(2.8, 0.0), {"hp_k": 3.0}]], "boss": "pyoyoung"},
	{"id": "busan_night", "theme": "busan_rain", "bounds": Rect2(-7.0, -2.6, 14.0, 5.2), "cast": ["kimshin", "jintae"],
		"heroes": [Vector2(-5.0, -0.6), Vector2(-5.2, 0.8)], "allies": [],
		"enemies": [["street_thug", Vector2(-0.4, -1.8), {"name": "붉은 점 가면"}], ["street_thug", Vector2(0.4, 1.6), {"name": "붉은 점 가면"}],
			["gang_blade", Vector2(1.6, -0.6), {"name": "붉은 점 가면"}], ["street_thug", Vector2(2.8, 1.8), {"name": "붉은 점 가면"}],
			["gang_blade", Vector2(3.4, -1.6), {"name": "붉은 점 가면"}], ["namilho", Vector2(4.6, 0.2)]], "boss": "namilho"},
	{"id": "rolling_ball", "theme": "busan_lobby", "bounds": Rect2(-6.0, -2.4, 12.0, 4.8), "cast": ["kimshin"],
		"heroes": [Vector2(-4.0, 0.2)], "allies": [],
		"enemies": [["gang_brute", Vector2(0.8, -1.4)], ["gang_brute", Vector2(1.2, 1.4)], ["bulgom", Vector2(3.0, 0.0)]], "boss": "bulgom"},
	{"id": "moseunggyu_office", "theme": "busan_office", "bounds": Rect2(-5.4, -2.4, 10.8, 4.8), "cast": ["pyoyoung"],
		"heroes": [Vector2(-3.6, 0.2)], "allies": [],
		"enemies": [["gang_blade", Vector2(0.4, -1.4), {"name": "모승규 부하"}], ["gang_blade", Vector2(0.8, 1.4), {"name": "모승규 부하"}],
			["moseunggyu", Vector2(2.8, 0.0)]], "boss": "moseunggyu"},
	{"id": "busan_street", "theme": "busan_street", "bounds": Rect2(-7.0, -2.2, 14.0, 4.4), "cast": ["kimshin"],
		"heroes": [Vector2(-5.4, 0.0)], "allies": [["shire", Vector2(-4.4, 1.4)], ["jintae", Vector2(-4.6, -1.4)]],
		"enemies": [["odohwa", Vector2(0.4, 0.0)], ["masa", Vector2(2.2, -1.4)], ["gang_brute", Vector2(2.6, 1.4), {"name": "오도화 수하"}]], "boss": "odohwa",
		"escape": {"secs": 12.0, "exit": Rect2(5.6, -2.2, 1.4, 4.4)}},
	{"id": "busan_end", "theme": "busan_rain", "bounds": Rect2(-5.0, -2.4, 10.0, 4.8), "cast": ["kimshin"],
		"heroes": [Vector2(-1.6, 0.4)], "allies": [], "enemies": [], "boss": "", "end": true},
]

const INTRO_T := 75
const CLEAR_T := 150
const END_T := 360
const HEAL_ON_CLEAR := 0.25
const MAX_ATTACKERS := 2
