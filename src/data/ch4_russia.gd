extends RefCounted
## 4장 창고 · 러시아 · 저수지 · 공단 폐공장(1부 p1:061-085) 장 표 — 칸 뜻은 hotel.gd · haseong.gd · ch3_busan.gd 와 같다.
## 조작: 방마다 한 사람(cast) — 이슬 · 김신 · 피우진 · 김대건. 4장 끝은 김대건의 마지막 싸움(조작 — 기획서 02 3절 '김대건(4장 끝)').
## 편(castle_common canon 2026-11-10 다시 봄): 김신 · 피우진(이스크라 — 리사 · 메드베디 밑 훈련) · 이슬 · 김대건(부진파 — 김신 편) 쪽.
## 적 = 똘배(이슬에게 진 뒤 이슬 밑으로), 케이지 상대, 드미트리 갱단, 구스타프(이스크라 킬러 — 결착 없음), 바리스타(준 — 백도찬 밑) 쪽 칼잡이 ·
## 조슈아. 장호는 김대건의 동생(직속 식구) — 바리스타 매복(fight:jangho_ambush 079-080)에 잡혀 폐공장에 끌려온 포로다(적이 아니다).
## 흐름(castle_common canon fights — 화/컷, conf ai 판독 — 원작 화 차례):
##   1 회암시 당구장(fight:iseul_ttolbae p1:066-067) — 이슬 대 똘배 — 이름을 외치며 내지른 '김대건' 펀치 한 방
##   2 클럽 발레리노(fight:woojin_ballerino p1:069 — 훈련) — 피우진 대 클럽의 칼잡이들 — 민머리 칼잡이를 잡아 메다꽂기
##   3 불법 무투장 케이지(fight:kimshin_cage p1:072 회상) — 김신(맨손) 대 철망 속 상대(민머리 근육질) — 구스타프가 이 경기를 보고 김신을 점찍는다
##   4 저수지 물가 목조 집(fight:p1_kimshin_gustav p1:071-074) — 김신 대 구스타프 — 결착 없음: 이스크라 새 대가리들(아킬라 · 프리깃 · 샤모)이
##     끼어들어 구스타프가 '치욕을 새기겠다'며 물러난다 → 구스타프는 체력 yield_at 에서 물러난다(쓰러뜨리지 않는다)
##   5 시베리아 드미트리 갱단 작업장(fight:woojin_deumiteuri p1:074-075) — 피우진 대 드미트리 갱단 — 달아나는 뒤통수를 잡아 바닥에
##   6 공단 폐공장(fight:kimdaegeon_barista p1:081-084) — 김대건(조작) 혼자 들어가 바리스타 쪽 칼잡이(갈색 재킷 · 검은 상의 · 민머리 · 녹색 셔츠)를
##     먼저 치고 바리스타와 — 곡도를 빼앗아 몸통을 찌른다(084/112). 조슈아는 곡도를 던져 주고 총을 겨누다 김대건의 동생에게 막힌다(fight:joshua)
##   7 끝 — 백도찬이 나타나 김대건이 쓰러진다(fight:baekdochan_kimdaegeon p1:084-085 — 지는 전투는 대사로만)
## 원작과 다른 점: 류지학 대 김대건(창고 061-062) · 신태진 대 바리스타(063-065) · 피우진 대 블랙맘바(fight:woojin_josimopeu 070-071 — 짐)는
## 진 싸움이라 대사로만. 케이지 상대는 이름 없는 격투가. 조슈아는 손을 섞지 않아 방에 세우지 않는다.
## 진행 사건 beat:gustav(progression '4장 구스타프 이김')는 원작 결과(winner 없음)와 달라 이 장 표 시점에 넣지 않는다 — castle_common 확인 거리.
## 수치는 봇 판(방별 8판 — 3 ~ 13장 공통 방법)으로.

const EVENT := "beat:yundeoksu"      # 시점: 구스타프전 앞 — 김신 내성 중위(이 장 안의 beat:gustav 뒤로는 5장부터)
const PERIOD := "p1"

const CANON := {
	"billiard_hall": {"fight": "fight:iseul_ttolbae", "place": "hoeamsi"},
	"cage_pit": {"fight": "fight:kimshin_cage", "place": "bulbeopmutujang"},
	"ballerino_club": {"fight": "fight:woojin_ballerino", "place": "club_ballerino"},
	"siberia_ward": {"fight": "fight:woojin_deumiteuri", "place": "siberia"},
	"lakehouse": {"fight": "fight:p1_kimshin_gustav", "place": "pyejeosuji"},
	"factory": {"fight": "fight:kimdaegeon_barista", "place": "gongdan_pyegongjang"},
	"factory_end": {"fight": "", "place": "gongdan_pyegongjang"},
}

const HEROES := ["kimshin", "woojin", "iseul", "kimdaegeon"]
const LINES := "ch4"
const CROWD_ID := "street_thug"

const NPCS := {
	"deumiteuri": {"rank": "전국구"},      # 강함표에 없음 — 시베리아 갱단 두목(3D 덧붙임)
}

const ROLES := {
	"kimshin": {"hp": 200.0, "posture": 60.0, "walk": 2.1, "run": 4.6, "stagger": 50, "look": "kim_p1_blade",
		"moveset": {"combo": "k_slash1", "dash": "k_dash", "counter": "k_counter", "finisher": "k_finisher"}},
	"kimshin_bare": {"look": "kim_bare",
		"moveset": {"combo": "kf_jab", "dash": "kf_dash", "counter": "kf_counter", "finisher": "kf_finisher"}},
	"woojin": {"hp": 220.0, "posture": 70.0, "walk": 2.1, "run": 4.6, "stagger": 50, "look": "woojin",
		"moveset": {"combo": "w_jab", "dash": "w_dash", "finisher": "w_finisher"}},
	"iseul": {"hp": 260.0, "posture": 90.0, "walk": 1.9, "run": 4.2, "stagger": 55, "look": "iseul",
		"moveset": {"combo": "ia_hook", "dash": "ia_dash", "finisher": "ia_finisher"}},
	"kimdaegeon": {"hp": 380.0, "posture": 90.0, "walk": 2.1, "run": 4.6, "stagger": 50, "look": "kimdaegeon",
		"moveset": {"combo": "dk_jab", "dash": "dk_dash", "finisher": "dk_finisher"}},
	"street_thug": {"hp": 220.0, "posture": 45.0, "walk": 1.8, "run": 3.8, "stagger": 70, "ai": "thug", "look": "ds_raider"},
	"gang_blade": {"hp": 260.0, "posture": 50.0, "walk": 1.9, "run": 4.0, "stagger": 70, "ai": "haseong_guard", "look": "haseong_guard"},
	"gang_brute": {"hp": 340.0, "posture": 70.0, "walk": 1.7, "run": 3.6, "stagger": 75, "ai": "thug_brute", "look": "gunter_brute"},
	"pro_fighter": {"hp": 2200.0, "posture": 260.0, "walk": 2.0, "run": 4.3, "stagger": 75, "poise": 26.0, "finisher_cap": 0.1, "ai": "x_boxer",
		"look": "gunter_bald", "phase2_at": 0.5, "dmg_k": 1.6},
	"ttolbae": {"hp": 220.0, "posture": 200.0, "walk": 2.0, "run": 4.2, "stagger": 75, "poise": 24.0, "finisher_cap": 0.1, "ai": "x_brawler",
		"look": "ttolbae", "dmg_k": 1.0},
	"deumiteuri": {"hp": 220.0, "posture": 200.0, "walk": 2.0, "run": 4.4, "stagger": 75, "poise": 26.0, "finisher_cap": 0.08, "ai": "x_blade",
		"look": "deumiteuri", "phase2_at": 0.5, "dmg_k": 0.7},
	# 구스타프: 결착 없음(074 — 이스크라 새 대가리들이 끼어들어 물러난다) — yield_at 에서 물러선다
	"gustav": {"hp": 480.0, "posture": 520.0, "walk": 2.1, "run": 4.6, "stagger": 80, "poise": 36.0, "finisher_cap": 0.04, "ai": "x_master",
		"look": "gustav", "phase2_at": 0.6, "yield_at": 0.3, "dmg_k": 0.85},
	"barista": {"hp": 140.0, "posture": 180.0, "walk": 2.1, "run": 4.6, "stagger": 75, "poise": 28.0, "finisher_cap": 0.06, "ai": "x_blade",
		"look": "barista", "phase2_at": 0.5, "dmg_k": 0.35},
}

const ROOMS := [
	{"id": "billiard_hall", "theme": "billiard", "bounds": Rect2(-6.0, -2.4, 12.0, 4.8), "cast": ["iseul"],
		"heroes": [Vector2(-4.0, 0.2)], "allies": [],
		"enemies": [["street_thug", Vector2(0.2, -1.4), {"name": "똘배 패거리"}], ["street_thug", Vector2(0.8, 1.4), {"name": "똘배 패거리"}],
			["ttolbae", Vector2(2.8, 0.0)]], "boss": "ttolbae"},
	{"id": "ballerino_club", "theme": "club_cage", "bounds": Rect2(-6.0, -2.4, 12.0, 4.8), "cast": ["woojin"],
		"heroes": [Vector2(-4.0, 0.2)], "allies": [],
		"enemies": [["gang_blade", Vector2(0.4, -1.6), {"name": "클럽 칼잡이"}], ["gang_blade", Vector2(1.0, 1.4), {"name": "클럽 칼잡이"}],
			["street_thug", Vector2(2.4, -0.4), {"name": "클럽 경비"}], ["gang_brute", Vector2(3.6, 1.0), {"name": "민머리 칼잡이", "look": "gunter_bald"}]]},
	{"id": "cage_pit", "theme": "cage_pit", "bounds": Rect2(-5.0, -2.2, 10.0, 4.4), "cast": ["kimshin"], "kit": {"kimshin": "kimshin_bare"},
		"heroes": [Vector2(-3.0, 0.2)], "allies": [],
		"enemies": [["pro_fighter", Vector2(2.2, 0.0), {"name": "케이지 파이터"}]], "boss": "pro_fighter"},
	{"id": "lakehouse", "theme": "lakehouse", "bounds": Rect2(-6.0, -2.0, 12.0, 4.4), "cast": ["kimshin"],
		"heroes": [Vector2(-3.8, 0.2)], "allies": [],
		"enemies": [["gustav", Vector2(2.4, 0.0)]], "boss": "gustav"},
	{"id": "siberia_ward", "theme": "siberia_ward", "bounds": Rect2(-6.0, -2.2, 12.0, 4.4), "cast": ["woojin"],
		"heroes": [Vector2(-4.0, 0.2)], "allies": [],
		"enemies": [["street_thug", Vector2(0.6, -1.4), {"name": "드미트리 갱단"}], ["street_thug", Vector2(1.0, 1.4), {"name": "드미트리 갱단"}],
			["deumiteuri", Vector2(3.0, 0.0)]], "boss": "deumiteuri"},
	{"id": "factory", "theme": "factory", "bounds": Rect2(-6.4, -2.6, 12.8, 5.2), "cast": ["kimdaegeon"],
		"heroes": [Vector2(-4.2, 0.2)], "allies": [],
		"enemies": [["gang_blade", Vector2(0.6, -1.6), {"name": "갈색 재킷 칼잡이", "hp_k": 0.8}], ["gang_blade", Vector2(1.0, 1.4), {"name": "검은 상의 칼잡이", "hp_k": 0.8}],
			["gang_brute", Vector2(2.0, -0.2), {"name": "민머리(녹색 트레이닝복)", "look": "gunter_bald", "hp_k": 0.8}],
			["gang_blade", Vector2(2.8, 1.6), {"name": "녹색 셔츠 칼잡이", "hp_k": 0.8}], ["barista", Vector2(3.8, -0.6)]], "boss": "barista"},
	{"id": "factory_end", "theme": "factory", "bounds": Rect2(-5.0, -2.4, 10.0, 4.8), "cast": ["kimdaegeon"],
		"heroes": [Vector2(-1.6, 0.4)], "allies": [], "enemies": [], "boss": "", "end": true},
]

const INTRO_T := 75
const CLEAR_T := 150
const END_T := 420
const HEAL_ON_CLEAR := 0.25
const MAX_ATTACKERS := 2
