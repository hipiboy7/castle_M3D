extends RefCounted
## 11장 '만인지상' 호텔 캐슬 장 표 — 층(방) 표 · 인물 역할(3층: 체력 · 체간 · 속도 · 동작 묶음 · AI · 외형) · 장 시점. 방 규칙 칸은 src/combat/stage.gd 머리.
## 스테이지(사용자 rc.8 폰 리뷰 2026-11-10 '장별 스테이지' — 원작 판독보다 위, 여섯 차례):
##   1 지하주차장(fight:gyeonghodae_juchajang 043-048) — 류지학(조작) + 히데(아군) + 야쿠자 10 대 마학영 · 마준영 · 정단 · 최달천 · 이정화 + 경호대 50.
##     3분 버티기(survive 180) 뒤 히데 '해산!!'(048/050)으로 10초 안에 왼쪽 비상구로(escape). 류지학 · 히데가 쓰러지면 진다(protect).
##     경호대 50은 여덟 무리(tag p1 ~ p8)로 — 앞 무리가 다 쓰러지면 다음 무리와 이름 있는 적이 하나씩(폰 성능 — 한 번에 적 8명 안팎).
##     마학영(톱)은 마지막 무리와 함께 — 쓰러뜨릴 수 없다(hp_floor, 버티는 방). 류지학은 이 무렵 내성 중위(강함표 '교류회 이후'), 히데는 강함표
##     외성 중위지만 이 방에서 외성 상위로 덮는다 — 아군(조작 인물이 아님)이라 톱 마학영의 등급 차 한 방(5등급)에 쓰러지면 지키는 방이 안 된다
##   2 호텔캐슬 28층 중앙홀(fight:baekui_tower 057/042-067) — 김신 · 피우진(교대) + 구일화 · 한태철 · 어광득 · 도학수 · 최혁진 대 경호대 20(세 무리)
##   3 69층 비상구 계단(058/000-024) — 피우진 혼자 대 경호대 20. 김신 '뚫어.'(057/074 · 058/001), 긴 맵(계단을 뚫고 오른쪽 위층으로 — 다섯 무리)
##   4 71층(058/027-045) — 김신 혼자 대 경호대 최후의 방패 4인(이 방에서 이스크라 평 킬러급 — 방 표 ranks)
##   5 71층 회장실 앞(fight:kimshin_shingen 058/046-062/106) — 김신 대 신겐 1:1, 신겐 체력 2/3 에서 '지나가라'(yield)
##   6 71층 회장실(fight:kimshin_cheonildo 063/035-054) — 김신 대 천일도: 천일도는 맞서지 않고 맞기만(passive) · 체력 낮게
##   7 끝 — '만인지상의 자리에 오르다'(fade — 062/110-112 신겐 '그곳이.. 만인지상의 자리다')
## 원작과 다른 점: 지하주차장(43-48화)은 원작에서 10장 화진전과 같은 때 — 사용자 차례대로 11장 첫 방. 하야부사는 이 싸움에서 경호원들을
## '대기하라'로 멈춰 세울 뿐 김신과 싸우지 않는다(059/015-017) — 적에서 뺐다. 천일도 장면은 원작에서 빗속 옥상(063) — 회장실로 묶었다.
## 난이도(사용자 "보스가 김신보다 약한대도 강하게 표현될 때가 있음"): 김신(재앙)보다 아랫급인 최후의 4인 · 신겐은 dmg_k ≤ 1 · 빨리 끝나게.
## 3층 값은 이 판 소유 — 봇 판(tests/sim_rooms.gd)으로 맞춘다. 능력치 배율은 addendum.derive.

## 이 판의 시점 = 11장 호텔 캐슬 기습(castle_common progression 'raid:castle_hotel' 앞까지의 진행 — 김신 재앙 · 피우진 외성 하위)
const EVENT := "raid:castle_hotel"
const PERIOD := "hwajin"

## 원작 근거(castle_common canon — 장 데이터 검사 tests/unit/test_campaign.gd 가 id 가 canon 에 있는지 본다): 방 id →
## fight(canon fights.json 대결 id, 싸움 없는 방은 "") · place(canon locations.json 장소 id)
const CANON := {
	"parking": {"fight": "fight:gyeonghodae_juchajang", "place": "castle_hotel"},
	"hall28": {"fight": "fight:baekui_tower", "place": "castle_hotel"},
	"floor69": {"fight": "fight:baekui_tower", "place": "castle_hotel"},
	"hall71": {"fight": "fight:baekui_tower", "place": "castle_hotel"},
	"office_door": {"fight": "fight:kimshin_shingen", "place": "castle_hotel"},
	"office": {"fight": "fight:kimshin_cheonildo", "place": "castle_hotel"},
	"office_end": {"fight": "", "place": "castle_hotel"},
}

## 장 표 칸(src/data/campaign.gd 가 장 id ch11 로 이 표를 고르고, src/combat/stage.gd 가 읽는다)
const HEROES := ["kimshin", "woojin", "ryujihak"]   # 조작하는 사람 — 방마다 cast(지하주차장은 류지학 — 히데는 castle_common 인물 표에 없어 아군 봇)
const LINES := "ch11"                    # data/story/lines.json 의 이 장 글 — <LINES>.start · .rooms.<방 id>.<때> · .down
const CROWD_ID := "castle_guard"          # 성능 점검(--crowd N)에서 첫 방에 더 세우는 엑스트라

## 그 장 시점 등급(3D 덧붙임 — 강함표 조건 줄 · 강함표에 없는 인물)
const NPCS := {
	"choedalcheon": {"rank": "외성 하위"},   # 강함표 '(2부) 최달천'
	"jeonghwa": {"rank": "전국구"},          # 강함표에 없음 — 지하주차장 초록 선글라스 경호대원(043/022-029, canon look 122/056-058) · 경호대 지휘급 후보
}

## 인물 역할(3층). hp · posture 는 능력치 맷집 배율을 곱하기 전 값, dmg_k 는 능력치 힘 배율에 더 곱한다(보스 손맛). moveset 은 사람과 아군만
const ROLES := {
	"kimshin": {"hp": 200.0, "posture": 60.0, "walk": 2.1, "run": 4.6, "stagger": 50, "look": "kim",
		"moveset": {"combo": "k_slash1", "dash": "k_dash", "counter": "k_counter", "finisher": "k_finisher"}},
	"woojin": {"hp": 200.0, "posture": 70.0, "walk": 2.1, "run": 4.6, "stagger": 50, "look": "woojin",
		"moveset": {"combo": "w_jab", "dash": "w_dash", "finisher": "w_finisher"}},
	# 류지학(하성 — 쌍칼, 지하주차장에서만 조작) · 히데(야나가와구미 — 카타나 · 권총, 아군 봇 — 지켜야 할 사람)
	"ryujihak": {"hp": 230.0, "posture": 80.0, "walk": 2.2, "run": 4.8, "stagger": 50, "look": "ryujihak",
		"moveset": {"combo": "jk_slash1", "dash": "jk_dash", "finisher": "jk_finisher"}},
	"hide": {"hp": 420.0, "posture": 90.0, "walk": 2.2, "run": 4.8, "stagger": 50, "look": "hide",
		"moveset": {"combo": "jk_slash1", "dash": "jk_dash", "finisher": "jk_finisher"}},
	"guilhwa": {"hp": 170.0, "posture": 70.0, "walk": 2.0, "run": 4.4, "stagger": 55, "look": "guilhwa",
		"moveset": {"combo": "gu_jab", "dash": "gu_dash", "finisher": "gu_finisher"}},
	# 28층 아군(백의 · 연합 — 사용자 rc.8): 한태철(골프채) · 어광득 · 도학수(맨주먹) · 최혁진 — 봇이 모는 묶음은 맨손 ny_
	"hantaecheol": {"hp": 190.0, "posture": 70.0, "walk": 1.9, "run": 4.1, "stagger": 55, "look": "hantaecheol",
		"moveset": {"combo": "ny_jab", "dash": "ny_dash", "finisher": "ny_finisher"}},
	"eogwangdeuk": {"hp": 190.0, "posture": 80.0, "walk": 1.9, "run": 4.1, "stagger": 55, "look": "eogwangdeuk",
		"moveset": {"combo": "ny_jab", "dash": "ny_dash", "finisher": "ny_finisher"}},
	"dohaksu": {"hp": 190.0, "posture": 80.0, "walk": 1.9, "run": 4.1, "stagger": 55, "look": "dohaksu",
		"moveset": {"combo": "ny_jab", "dash": "ny_dash", "finisher": "ny_finisher"}},
	"choehyeokjin": {"hp": 180.0, "posture": 70.0, "walk": 2.0, "run": 4.3, "stagger": 55, "look": "choehyeokjin",
		"moveset": {"combo": "ny_jab", "dash": "ny_dash", "finisher": "ny_finisher"}},
	# 야쿠자(히데 쪽 복면 무리 043/006-021 — 아군 봇, 1층은 엑스트라 street_thug · 방 표 덧붙임 role)
	"yakuza": {"hp": 150.0, "posture": 50.0, "walk": 1.9, "run": 4.1, "stagger": 60, "look": "ds_raider",
		"moveset": {"combo": "ny_jab", "dash": "ny_dash", "finisher": "ny_finisher"}},
	"street_thug": {"hp": 150.0, "posture": 50.0, "walk": 1.9, "run": 4.1, "stagger": 60, "ai": "thug", "look": "ds_raider"},   # 외형 = 복면 습격조(원작 043 '복면 무리' — 경호대 검은 정장과 가른다)
	"castle_guard": {"hp": 110.0, "posture": 60.0, "walk": 1.8, "run": 3.8, "stagger": 70, "poise": 0.0, "ai": "guard",
		"look": "guard", "dmg_k": 0.55},
	"castle_guard_lt": {"hp": 40.0, "posture": 30.0, "walk": 1.8, "run": 3.8, "stagger": 70, "poise": 0.0, "ai": "guard",
		"look": "guard"},
	# 지하주차장 경호대 지휘부(버티는 방 — 손맛은 가볍게, 무리와 함께 들어온다)
	"jeongdan": {"hp": 320.0, "posture": 200.0, "walk": 2.0, "run": 4.3, "stagger": 75, "poise": 20.0, "finisher_cap": 0.08, "ai": "x_gun",
		"look": "jeongdan", "dmg_k": 0.3},
	"majunyeong": {"hp": 460.0, "posture": 300.0, "walk": 2.1, "run": 4.6, "stagger": 75, "poise": 26.0, "finisher_cap": 0.06, "ai": "x_grappler",
		"look": "majunyeong", "dmg_k": 0.3},
	"choedalcheon": {"hp": 420.0, "posture": 300.0, "walk": 1.9, "run": 4.1, "stagger": 75, "poise": 26.0, "finisher_cap": 0.06, "ai": "x_brawler",
		"look": "choedalcheon", "dmg_k": 0.3},
	"jeonghwa": {"hp": 220.0, "posture": 150.0, "walk": 2.0, "run": 4.3, "stagger": 75, "poise": 10.0, "finisher_cap": 0.1, "ai": "x_gun",
		"look": "jeonghwa", "dmg_k": 0.3},
	"mahakyoung": {"hp": 1400.0, "posture": 700.0, "walk": 2.0, "run": 4.4, "stagger": 80, "poise": 36.0, "finisher_cap": 0.03, "ai": "x_gun",
		"look": "mahakyoung", "hp_floor": 0.5, "dmg_k": 0.3},
	"gyeonghodaechoehuui4in": {"hp": 240.0, "posture": 130.0, "walk": 1.8, "run": 3.9, "stagger": 80, "poise": 6.0, "ai": "g4",
		"look": "g4", "dmg_k": 0.8},
	"shingen": {"hp": 900.0, "posture": 420.0, "walk": 1.95, "run": 4.2, "stagger": 80, "poise": 18.0, "ai": "shingen",
		"look": "shingen", "phase2_at": 0.85, "yield_at": 0.667, "finisher_cap": 0.08, "dmg_k": 0.8},
	"cheonildo": {"hp": 320.0, "posture": 80.0, "walk": 1.4, "run": 2.4, "stagger": 90, "ai": "x_brawler", "look": "cheonildo"},
}

## 경호대 무리: 덧붙임 tag 로 가른다(when "down:<tag>"). 28층 · 69층은 아랫급이라 가벼운 역할 role castle_guard_lt(1 ~ 2대)
## 방 — theme: 무대 그림(src/view/hotel3d.gd) · bounds: 걸을 수 있는 바닥(m) · heroes/allies/enemies: [인물 id, 자리, (덧붙임)]
## boss: 화면 위 큰 체력 막대에 보일 적(없으면 가장 가까운 적) · lines: data/story/lines.json ch11.rooms.<id>
const ROOMS := [
	{"id": "parking", "theme": "parking", "bounds": Rect2(-7.0, -2.6, 14.0, 5.2), "cast": ["ryujihak"],
		"heroes": [Vector2(-3.4, -0.4)], "ranks": {"ryujihak": "내성 중위", "hide": "외성 상위"},
		"allies": [["hide", Vector2(-3.8, 0.9)], ["street_thug", Vector2(-2.2, -1.9), {"role": "yakuza", "name": "야쿠자"}], ["street_thug", Vector2(-2.0, 2.0), {"role": "yakuza", "name": "야쿠자"}],
			["street_thug", Vector2(-2.6, -0.9), {"role": "yakuza", "name": "야쿠자"}], ["street_thug", Vector2(-2.4, 1.2), {"role": "yakuza", "name": "야쿠자"}],
			["street_thug", Vector2(-4.6, -2.0), {"role": "yakuza", "name": "야쿠자"}], ["street_thug", Vector2(-4.8, 2.0), {"role": "yakuza", "name": "야쿠자"}],
			["street_thug", Vector2(-5.2, -0.8), {"role": "yakuza", "name": "야쿠자"}], ["street_thug", Vector2(-5.2, 0.6), {"role": "yakuza", "name": "야쿠자"}],
			["street_thug", Vector2(-3.0, 0.2), {"role": "yakuza", "name": "야쿠자"}], ["street_thug", Vector2(-4.4, -0.1), {"role": "yakuza", "name": "야쿠자"}]],
		"enemies": [["castle_guard", Vector2(1.4, -1.8), {"tag": "p1"}], ["castle_guard", Vector2(1.8, 0.0), {"tag": "p1"}], ["castle_guard", Vector2(1.4, 1.8), {"tag": "p1"}], ["castle_guard", Vector2(3.0, -1.0), {"tag": "p1"}], ["castle_guard", Vector2(3.0, 1.0), {"tag": "p1"}], ["castle_guard", Vector2(4.2, 0.0), {"tag": "p1"}],
			["jeongdan", Vector2(5.4, -0.6)]],
		"boss": "", "survive": 180, "protect": ["ryujihak", "hide"],
		"triggers": [
			{"when": "time:0", "say": "order"},
			{"when": "down:p1", "say": "majun", "spawn": [["castle_guard", Vector2(6.4, -2.0), {"tag": "p2"}], ["castle_guard", Vector2(6.4, -0.6), {"tag": "p2"}], ["castle_guard", Vector2(6.4, 0.8), {"tag": "p2"}], ["castle_guard", Vector2(6.4, 2.0), {"tag": "p2"}], ["castle_guard", Vector2(5.6, -1.4), {"tag": "p2"}],
				["castle_guard", Vector2(5.6, 1.4), {"tag": "p2"}], ["majunyeong", Vector2(6.6, 0.0)]]},
			{"when": "down:p2", "spawn": [["castle_guard", Vector2(6.4, -2.0), {"tag": "p3"}], ["castle_guard", Vector2(6.4, -0.6), {"tag": "p3"}], ["castle_guard", Vector2(6.4, 0.8), {"tag": "p3"}], ["castle_guard", Vector2(6.4, 2.0), {"tag": "p3"}], ["castle_guard", Vector2(5.6, -1.4), {"tag": "p3"}], ["castle_guard", Vector2(5.6, 1.4), {"tag": "p3"}]]},
			{"when": "down:p3", "say": "dalcheon", "spawn": [["castle_guard", Vector2(6.4, -2.0), {"tag": "p4"}], ["castle_guard", Vector2(6.4, -0.6), {"tag": "p4"}], ["castle_guard", Vector2(6.4, 0.8), {"tag": "p4"}], ["castle_guard", Vector2(6.4, 2.0), {"tag": "p4"}], ["castle_guard", Vector2(5.6, -1.4), {"tag": "p4"}],
				["castle_guard", Vector2(5.6, 1.4), {"tag": "p4"}], ["choedalcheon", Vector2(6.6, 0.0)]]},
			{"when": "down:p4", "spawn": [["castle_guard", Vector2(6.4, -2.0), {"tag": "p5"}], ["castle_guard", Vector2(6.4, -0.6), {"tag": "p5"}], ["castle_guard", Vector2(6.4, 0.8), {"tag": "p5"}], ["castle_guard", Vector2(6.4, 2.0), {"tag": "p5"}], ["castle_guard", Vector2(5.6, -1.4), {"tag": "p5"}], ["castle_guard", Vector2(5.6, 1.4), {"tag": "p5"}]]},
			{"when": "down:p5", "say": "jeonghwa", "spawn": [["castle_guard", Vector2(6.4, -2.0), {"tag": "p6"}], ["castle_guard", Vector2(6.4, -0.6), {"tag": "p6"}], ["castle_guard", Vector2(6.4, 0.8), {"tag": "p6"}], ["castle_guard", Vector2(6.4, 2.0), {"tag": "p6"}], ["castle_guard", Vector2(5.6, -1.4), {"tag": "p6"}],
				["castle_guard", Vector2(5.6, 1.4), {"tag": "p6"}], ["jeonghwa", Vector2(6.6, 0.0)]]},
			{"when": "down:p6", "spawn": [["castle_guard", Vector2(6.4, -2.0), {"tag": "p7"}], ["castle_guard", Vector2(6.4, -0.6), {"tag": "p7"}], ["castle_guard", Vector2(6.4, 0.8), {"tag": "p7"}], ["castle_guard", Vector2(6.4, 2.0), {"tag": "p7"}], ["castle_guard", Vector2(5.6, -1.4), {"tag": "p7"}], ["castle_guard", Vector2(5.6, 1.4), {"tag": "p7"}]]},
			{"when": "down:p7", "say": "boss", "boss": "mahakyoung",
				"spawn": [["castle_guard", Vector2(6.4, -2.0), {"tag": "p8"}], ["castle_guard", Vector2(6.4, -0.6), {"tag": "p8"}], ["castle_guard", Vector2(6.4, 0.8), {"tag": "p8"}], ["castle_guard", Vector2(6.4, 2.0), {"tag": "p8"}], ["castle_guard", Vector2(5.6, -1.8), {"tag": "p8"}], ["castle_guard", Vector2(5.6, -0.6), {"tag": "p8"}],
					["castle_guard", Vector2(5.6, 0.6), {"tag": "p8"}], ["castle_guard", Vector2(5.6, 1.8), {"tag": "p8"}], ["mahakyoung", Vector2(6.6, 0.0)]]},
			{"when": "survive", "say": "disperse", "escape": {"exit": Rect2(-7.0, -2.6, 1.2, 5.2), "secs": 10}}]},
	{"id": "hall28", "theme": "hall", "bounds": Rect2(-6.6, -3.4, 13.2, 7.0), "cast": ["kimshin", "woojin"],
		"heroes": [Vector2(-4.4, 0.4), Vector2(-4.8, -0.8)],
		"allies": [["guilhwa", Vector2(-3.4, 1.4)], ["hantaecheol", Vector2(-3.6, -2.0)], ["eogwangdeuk", Vector2(-5.4, 2.2)],
			["dohaksu", Vector2(-5.6, -2.4)], ["choehyeokjin", Vector2(-5.8, 0.0)]],
		"enemies": [["castle_guard", Vector2(1.6, -2.2), {"tag": "g1", "role": "castle_guard_lt"}], ["castle_guard", Vector2(2.6, -0.8), {"tag": "g1", "role": "castle_guard_lt"}],
			["castle_guard", Vector2(3.4, 0.4), {"tag": "g1", "role": "castle_guard_lt", "name": "톤파 경호원", "hp_k": 1.6}],
			["castle_guard", Vector2(2.6, 1.8), {"tag": "g1", "role": "castle_guard_lt"}], ["castle_guard", Vector2(4.4, -1.8), {"tag": "g1", "role": "castle_guard_lt"}], ["castle_guard", Vector2(4.6, 1.2), {"tag": "g1", "role": "castle_guard_lt"}],
			["castle_guard", Vector2(5.4, -0.4), {"tag": "g1", "role": "castle_guard_lt"}], ["castle_guard", Vector2(5.4, 2.6), {"tag": "g1", "role": "castle_guard_lt"}]], "boss": "",
		"triggers": [
			{"when": "down:g1", "say": "wave", "spawn": [["castle_guard", Vector2(6.2, -2.8), {"tag": "g2", "role": "castle_guard_lt"}], ["castle_guard", Vector2(6.2, -1.4), {"tag": "g2", "role": "castle_guard_lt"}], ["castle_guard", Vector2(6.2, 0.0), {"tag": "g2", "role": "castle_guard_lt"}],
				["castle_guard", Vector2(6.2, 1.4), {"tag": "g2", "role": "castle_guard_lt"}], ["castle_guard", Vector2(6.2, 2.8), {"tag": "g2", "role": "castle_guard_lt"}], ["castle_guard", Vector2(5.4, 0.7), {"tag": "g2", "role": "castle_guard_lt"}]]},
			{"when": "down:g2", "spawn": [["castle_guard", Vector2(6.2, -2.8), {"tag": "g3", "role": "castle_guard_lt"}], ["castle_guard", Vector2(6.2, -1.4), {"tag": "g3", "role": "castle_guard_lt"}], ["castle_guard", Vector2(6.2, 0.0), {"tag": "g3", "role": "castle_guard_lt"}],
				["castle_guard", Vector2(6.2, 1.4), {"tag": "g3", "role": "castle_guard_lt"}], ["castle_guard", Vector2(6.2, 2.8), {"tag": "g3", "role": "castle_guard_lt"}], ["castle_guard", Vector2(5.4, -0.7), {"tag": "g3", "role": "castle_guard_lt"}]]}]},
	{"id": "floor69", "theme": "stairs", "bounds": Rect2(-7.0, -1.7, 34.0, 3.4), "cast": ["woojin"],
		"heroes": [Vector2(-5.2, 0.0)], "allies": [],
		"enemies": [["castle_guard", Vector2(-0.4, -0.8), {"tag": "s1", "role": "castle_guard_lt"}], ["castle_guard", Vector2(0.6, 0.8), {"tag": "s1", "role": "castle_guard_lt"}], ["castle_guard", Vector2(1.8, -0.4), {"tag": "s1", "role": "castle_guard_lt"}],
			["castle_guard", Vector2(2.6, 0.6), {"tag": "s1", "role": "castle_guard_lt"}]], "boss": "",
		"triggers": [
			{"when": "time:0", "say": "go"},
			{"when": "down:s1", "say": "wave", "spawn": [["castle_guard", Vector2(6.2, -0.8), {"tag": "s2", "role": "castle_guard_lt"}], ["castle_guard", Vector2(7.0, 0.8), {"tag": "s2", "role": "castle_guard_lt"}],
				["castle_guard", Vector2(8.0, -0.4), {"tag": "s2", "role": "castle_guard_lt"}], ["castle_guard", Vector2(8.8, 0.6), {"tag": "s2", "role": "castle_guard_lt"}]]},
			{"when": "down:s2", "spawn": [["castle_guard", Vector2(12.2, -0.8), {"tag": "s3", "role": "castle_guard_lt"}], ["castle_guard", Vector2(13.0, 0.8), {"tag": "s3", "role": "castle_guard_lt"}],
				["castle_guard", Vector2(14.0, -0.4), {"tag": "s3", "role": "castle_guard_lt"}], ["castle_guard", Vector2(14.8, 0.6), {"tag": "s3", "role": "castle_guard_lt"}]]},
			{"when": "down:s3", "spawn": [["castle_guard", Vector2(18.2, -0.8), {"tag": "s4", "role": "castle_guard_lt"}], ["castle_guard", Vector2(19.0, 0.8), {"tag": "s4", "role": "castle_guard_lt"}],
				["castle_guard", Vector2(20.0, -0.4), {"tag": "s4", "role": "castle_guard_lt"}], ["castle_guard", Vector2(20.8, 0.6), {"tag": "s4", "role": "castle_guard_lt"}]]},
			{"when": "down:s4", "spawn": [["castle_guard", Vector2(23.2, -0.8), {"tag": "s5", "role": "castle_guard_lt"}], ["castle_guard", Vector2(24.0, 0.8), {"tag": "s5", "role": "castle_guard_lt"}],
				["castle_guard", Vector2(25.0, -0.4), {"tag": "s5", "role": "castle_guard_lt"}], ["castle_guard", Vector2(25.8, 0.6), {"tag": "s5", "role": "castle_guard_lt"}]]}]},
	{"id": "hall71", "theme": "vip_hall", "bounds": Rect2(-6.2, -3.2, 12.4, 6.6), "cast": ["kimshin"],
		"heroes": [Vector2(-4.2, 0.3)], "allies": [], "ranks": {"gyeonghodaechoehuui4in": "이스크라 평 킬러급"},
		"enemies": [["gyeonghodaechoehuui4in", Vector2(2.4, -1.4), {"leader": true}],
			["gyeonghodaechoehuui4in", Vector2(3.4, 0.6)], ["gyeonghodaechoehuui4in", Vector2(2.2, 1.8)],
			["gyeonghodaechoehuui4in", Vector2(4.2, -0.4)]], "boss": "gyeonghodaechoehuui4in"},
	{"id": "office_door", "theme": "blue_corridor", "bounds": Rect2(-6.0, -2.4, 12.0, 4.8), "cast": ["kimshin"],
		"heroes": [Vector2(-4.0, 0.3)], "allies": [],
		"enemies": [["shingen", Vector2(2.4, 0.0)]], "boss": "shingen"},
	{"id": "office", "theme": "office", "bounds": Rect2(-5.0, -2.8, 10.0, 5.6), "cast": ["kimshin"],
		"heroes": [Vector2(-2.6, 0.6)], "allies": [],
		"enemies": [["cheonildo", Vector2(1.6, -0.2), {"passive": true}]], "boss": "cheonildo"},
	{"id": "office_end", "theme": "office", "bounds": Rect2(-5.0, -2.8, 10.0, 5.6), "cast": ["kimshin"],
		"heroes": [Vector2(-1.0, 0.4)], "allies": [], "enemies": [], "boss": "", "end": true, "fade": "fade"},
]

const INTRO_T := 75              # 방에 들어서서 싸움이 시작되기까지(층 이름 · 대사)
const CLEAR_T := 150             # 방을 넘고 다음 층으로 가기까지
const END_T := 360               # 끝 방 — 끝 글이 보이는 시간
const HEAL_ON_CLEAR := 0.25      # 방을 넘으면 살아 있는 사람이 최대 체력의 이만큼 회복(3층 · 잠정)
const MAX_ATTACKERS := 2         # 동시에 패턴을 내는 적 수(협공 상한)
