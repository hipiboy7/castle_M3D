extends RefCounted
## 12장 '대 교회 전'(2부 070-126 — 교회 앞마당 · 본동 · 비전센터 · 공사장 · 지하) 장 표 — 칸 뜻은 ch3_busan.gd 와 같다. 방 규칙 칸은 stage.gd 머리.
## 스테이지 아홉은 사용자 목록 그대로(2026-11-10 폰 리뷰 rc.8 — 원작 판독 · 기획서보다 위):
##   0 개전(교회 앞마당 계단 앞) — 김신 + 백의 주요 인력 대 캐슬 경호대 100인. 10명씩 열 무리(앞 무리가 다 쓰러지면 다음 — 폰 성능)
##   1 구스타프 전 — 녹색 조명 사무실에서 싸우다 구스타프 체력 60% 에서 옆 비전센터 안까지 맵이 넓어진다(trigger bounds · theme)
##   2 마준영 1차전(비전센터 앞) — 김신 + 백의 셋 대 마준영 + 경호대 10. 마준영은 체력 1/2 에서 빠진다(yield_at)
##   3 그롤라 전(녹색 조명 공사장) — 1:1 → 그롤라 50% 에서 마준영 투입 → (그 뒤에만 — requires) 김신 50% 에서 피우진 투입, 2대 2
##   4 신겐 1차전(교회 본동 3층 복도) — 히데 · 현석 · 표영 · 쿄지(교대) + 히데 쪽 야쿠자 10 대 신겐 · 하야부사 · 토이시 · 이와시로 + 야쿠자 10
##     (야쿠자는 5 + 5 — 12초에 양쪽 다섯씩 더). 신겐은 60% 에서 위층으로 빠진다(095/050-051 하야부사 '뒤는 맡기고 통과하시죠')
##   5 신겐 2차전(본동 4층) — 피우진 대 신겐. 신겐 70% 에서 피우진이 물러나고 김신이 들어선다(trigger cast)
##   6 신겐 3차전(본동 4층) — 김신 대 신겐
##   7 최민욱 잡기(본동 로비 — 103/044-048 히데의 계획: 김신이 지하로 가는 동안 로비를 틀어막는다) — 김신은 조작하지 않는다(서 있는 사람
##     standing — 싸우지도 맞지도 않음). 피우진 · 표영 · 히데 · 최달천 · 쿄지 · 여민수 · 한태철 · 최혁진을 교대로 마학영 + 경호대 50 을 60초
##     버틴다(survive). 경호대는 10명으로 시작해 10초마다 10명씩 더(time). 마학영은 이 방에서 쓰러지지 않는다(hp_floor)
##   8 마학영 전(지하 주차장) — 김신 + 서진태 대 마학영 + 경호대 10. 서진태 30% 로 시작(hp_start) → 김신이 안쪽으로 들어가 셔터를 닫는다
##     (cast — 서진태 혼자, 120/011-015) → 서진태가 쓰러지면 셔터가 열리고 김신이 돌아온다(down:jintae → cast — 120/049-055)
##   9 끝
## 편(사용자 말이 먼저 — canon fights sides 는 conf ai): 김신 · 백의(피우진 · 서진태 · 구일화 · 최혁진 · 한태철 · 여민수 · 최달천) · 반 야마구치
## 연합(히데 · 쿄지 · 현석 · 표영) 대 캐슬 홀딩스(마학영 · 마준영 · 경호대) · 이스크라(구스타프 · 그롤라) · 신겐 쪽(하야부사 · 토이시 · 이와시로).
## 난이도(사용자 2026-11-10 '보스가 김신보다 약한대도 강하게'): 이 장의 김신은 재앙 — 구스타프 · 마준영 · 그롤라 · 신겐 · 마학영(톱)은 모두
## 김신보다 아랫급이라 dmg_k ≤ 1 · 빨리 끝나게. 피우진(외성 중위) · 히데 쪽이 맡는 신겐 방만 윗급(봇 5/8 기준). 경호대 · 야쿠자는 1 ~ 2대.
## 원작과 다른 점: 개전 · 로비 버티기의 사람 수는 사용자 숫자(원작 판독 아님). 원작의 김신은 로비에서 몸을 드러내 경호대를 끌었다(103/053-055) —
## 게임에서는 김신을 서 있는 사람으로 두고 나머지가 막는다(사용자 '김신은 컨트롤 못하고'). 토이시는 외형 표에 없어 정장(ds_suit) + 이름 덮기.

const EVENT := "raid:castle_hotel"   # 시점: 11장 뒤 — 김신 재앙 · 피우진 외성 중위 · 서진태 내성 하위
const PERIOD := "church"

const CANON := {
	"church_steps": {"fight": "fight:hide_mahakyoung2", "place": "gyohoe"},
	"green_office": {"fight": "fight:kimshin_gustav", "place": "gyohoe"},
	"vision_front": {"fight": "fight:kimshin_majunyeong", "place": "gyohoebijeonsenteo"},
	"build_site": {"fight": "fight:kimshin_majunyeong2", "place": "gyohoebijeonsenteo"},
	"corridor_3f": {"fight": "fight:hide_shingen", "place": "gyohoe"},
	"hall_4f_woojin": {"fight": "fight:shingen", "place": "gyohoe"},
	"hall_4f_kim": {"fight": "fight:kimshin_shingen_gyohoe", "place": "gyohoe"},
	"lobby_hold": {"fight": "fight:hide_mahakyoung2", "place": "gyohoe"},
	"parking": {"fight": "fight:kimshin_mahakyoung", "place": "gyohoe"},
	"church_end": {"fight": "", "place": "gyohoe"},
}

## 조작 인물 — 방마다 cast. 신겐 1차전 · 최민욱 잡기의 사람들도 조작(교대)한다. 쓰러진 조작 인물은 뒤 방에서도 쓰러진 채라
## (stage.gd — 방을 넘어도 되살리지 않음) 개전 · 마준영 · 그롤라 방의 백의 사람들은 아군(NPC)으로 따로 세운다
const HEROES := ["kimshin", "woojin", "jintae", "hide", "hyeonseok", "pyoyoung", "yamamotokyoji", "choedalcheon", "yeominsu", "hantaecheol", "choehyeokjin"]
const LINES := "ch12"
const CROWD_ID := "elite_guard"

## 조작 인물 등급(진행이 없는 사람 — ranks.json 강함표의 교회전 무렵 줄)
const HERO_RANKS := {
	"woojin": "외성 중위", "hide": "외성 중위", "hyeonseok": "외성 상위", "pyoyoung": "준10강", "yamamotokyoji": "준10강", "choedalcheon": "외성 하위",
	"yeominsu": "이스크라 평 킬러급", "hantaecheol": "이스크라 평 킬러급", "choehyeokjin": "전국구",
}

## 아군 · 적으로 나올 때의 등급 · 이름(같은 사람이 조작 인물일 때는 위 HERO_RANKS · 진행)
const NPCS := {
	"woojin": {"rank": "외성 중위"},       # 캐슬 호텔 기습 이후
	"jintae": {"rank": "내성 하위"},       # 유우성 이긴 뒤(10장)
	"pyoyoung": {"rank": "준10강"},
	"hide": {"rank": "외성 중위"},
	"yeominsu": {"rank": "이스크라 평 킬러급"},
	"toishi": {"name": "토이시"},          # 외형 표에 없다 — 이름만(강함표 준10강)
	"iwashiro": {"rank": "조장급"},        # 이와시로 신스케(야마구치구미 전 회장 — 늙은 두목)
}

const ROLES := {
	"kimshin": {"hp": 200.0, "posture": 60.0, "walk": 2.1, "run": 4.6, "stagger": 50, "look": "kim",
		"moveset": {"combo": "k_slash1", "dash": "k_dash", "counter": "k_counter", "finisher": "k_finisher"}},
	"woojin": {"hp": 220.0, "posture": 70.0, "walk": 2.1, "run": 4.6, "stagger": 50, "look": "woojin",
		"moveset": {"combo": "w_jab", "dash": "w_dash", "finisher": "w_finisher"}},
	"jintae": {"hp": 230.0, "posture": 70.0, "walk": 2.2, "run": 4.8, "stagger": 50, "look": "jintae",
		"moveset": {"combo": "jk_slash1", "dash": "jk_dash", "finisher": "jk_finisher"}},
	# 반 야마구치 연합 — 히데(카타나 · 소음기 권총) · 현석(톱날 단검) · 표영(카람빗) · 쿄지(맨손 거구)
	"hide": {"hp": 230.0, "posture": 70.0, "walk": 2.2, "run": 4.8, "stagger": 50, "look": "hide",
		"moveset": {"combo": "k_slash1", "dash": "k_dash", "finisher": "k_finisher"}},
	"hyeonseok": {"hp": 220.0, "posture": 70.0, "walk": 2.2, "run": 4.8, "stagger": 50, "look": "hyeonseok",
		"moveset": {"combo": "py_slash1", "dash": "py_dash", "finisher": "py_finisher"}},
	"pyoyoung": {"hp": 220.0, "posture": 60.0, "walk": 2.3, "run": 5.0, "stagger": 55, "look": "pyoyoung",
		"moveset": {"combo": "py_slash1", "dash": "py_dash", "finisher": "py_finisher"}},
	"yamamotokyoji": {"hp": 250.0, "posture": 80.0, "walk": 2.0, "run": 4.4, "stagger": 55, "look": "yamamotokyoji",
		"moveset": {"combo": "dk_jab", "dash": "dk_dash", "finisher": "dk_finisher"}},
	# 백의 — 최달천(거구 맨손) · 여민수 · 한태철 · 최혁진 · 구일화
	"choedalcheon": {"hp": 280.0, "posture": 90.0, "walk": 1.9, "run": 4.1, "stagger": 55, "look": "choedalcheon",
		"moveset": {"combo": "ia_hook", "dash": "ia_dash", "finisher": "ia_finisher"}},
	"yeominsu": {"hp": 240.0, "posture": 80.0, "walk": 2.0, "run": 4.3, "stagger": 55, "look": "yeominsu",
		"moveset": {"combo": "gu_jab", "dash": "gu_dash", "finisher": "gu_finisher"}},
	"hantaecheol": {"hp": 220.0, "posture": 70.0, "walk": 1.9, "run": 4.1, "stagger": 55, "look": "hantaecheol",
		"moveset": {"combo": "ny_jab", "dash": "ny_dash", "finisher": "ny_finisher"}},
	"choehyeokjin": {"hp": 200.0, "posture": 70.0, "walk": 2.0, "run": 4.3, "stagger": 55, "look": "choehyeokjin",
		"moveset": {"combo": "ny_jab", "dash": "ny_dash", "finisher": "ny_finisher"}},
	"guilhwa": {"hp": 220.0, "posture": 80.0, "walk": 2.0, "run": 4.4, "stagger": 55, "look": "guilhwa",
		"moveset": {"combo": "gu_jab", "dash": "gu_dash", "finisher": "gu_finisher"}},
	# 이름 없는 무리 — 캐슬 경호대 · 야쿠자(신겐 쪽 적 / 히데 쪽 아군 — 같은 엑스트라 id, 아군은 role yakuza_ally)
	"elite_guard": {"hp": 110.0, "posture": 40.0, "walk": 1.9, "run": 4.1, "stagger": 70, "poise": 2.0, "ai": "haseong_guard", "look": "guard", "dmg_k": 0.6},
	"gang_blade": {"hp": 100.0, "posture": 40.0, "walk": 1.9, "run": 4.1, "stagger": 70, "ai": "haseong_guard", "look": "ds_suit"},
	"yakuza_ally": {"hp": 140.0, "posture": 50.0, "walk": 1.9, "run": 4.1, "stagger": 60, "look": "haseong_suit",
		"moveset": {"combo": "ny_jab", "dash": "ny_dash", "finisher": "ny_finisher"}},
	# 보스 — 모두 김신(재앙)보다 아랫급: dmg_k ≤ 1
	"gustav": {"hp": 1000.0, "posture": 460.0, "walk": 2.1, "run": 4.6, "stagger": 80, "poise": 30.0, "finisher_cap": 0.05, "ai": "x_master",
		"look": "gustav", "phase2_at": 0.5, "dmg_k": 0.9},
	"majunyeong": {"hp": 900.0, "posture": 460.0, "walk": 2.1, "run": 4.6, "stagger": 80, "poise": 30.0, "finisher_cap": 0.05, "ai": "x_grappler",
		"look": "majunyeong", "yield_at": 0.5, "dmg_k": 0.9},
	# 마준영 2차(공사장 — 그롤라 50% 에서 뛰어든다)
	"majunyeong2": {"hp": 600.0, "posture": 360.0, "walk": 2.1, "run": 4.6, "stagger": 80, "poise": 26.0, "finisher_cap": 0.06, "ai": "x_grappler",
		"look": "majunyeong", "dmg_k": 0.8},
	"grolla": {"hp": 1000.0, "posture": 460.0, "walk": 2.1, "run": 4.6, "stagger": 80, "poise": 30.0, "finisher_cap": 0.05, "ai": "x_master",
		"look": "grolla", "phase2_at": 0.5, "dmg_k": 0.95},
	# 신겐 — 1차(3층 복도 — 60% 에서 위층으로) · 2차(피우진 — 70% 에서 김신 교대, 그 밑으로는 안 내려간다) · 3차(김신)
	"shingen1": {"hp": 650.0, "posture": 380.0, "walk": 1.95, "run": 4.2, "stagger": 80, "poise": 18.0, "finisher_cap": 0.06, "ai": "shingen",
		"look": "shingen", "yield_at": 0.6, "dmg_k": 0.7},
	"shingen2": {"hp": 220.0, "posture": 340.0, "walk": 1.95, "run": 4.2, "stagger": 80, "poise": 16.0, "finisher_cap": 0.06, "ai": "shingen",
		"look": "shingen", "hp_floor": 0.65, "dmg_k": 0.35},
	"shingen": {"hp": 1000.0, "posture": 420.0, "walk": 1.95, "run": 4.2, "stagger": 80, "poise": 18.0, "finisher_cap": 0.05, "ai": "shingen",
		"look": "shingen", "phase2_at": 0.5, "dmg_k": 0.95},
	"hayabusa": {"hp": 300.0, "posture": 200.0, "walk": 2.1, "run": 4.6, "stagger": 75, "poise": 10.0, "ai": "hayabusa", "look": "hayabusa", "dmg_k": 0.5},
	"toishi": {"hp": 260.0, "posture": 180.0, "walk": 2.0, "run": 4.4, "stagger": 75, "poise": 8.0, "ai": "x_blade", "look": "ds_suit", "dmg_k": 0.5},
	"iwashiro": {"hp": 140.0, "posture": 80.0, "walk": 1.7, "run": 3.6, "stagger": 70, "ai": "x_brawler", "look": "iwashiro", "dmg_k": 0.5},
	# 마학영(톱) — 주차장 보스(김신 재앙보다 한 급 아래) · 로비에서는 쓰러지지 않는 버티기 상대(hp_floor)
	"mahakyoung": {"hp": 900.0, "posture": 480.0, "walk": 2.1, "run": 4.6, "stagger": 80, "poise": 34.0, "finisher_cap": 0.04, "ai": "x_gun",
		"look": "mahakyoung", "phase2_at": 0.5, "dmg_k": 0.5},
	"mahakyoung_hold": {"hp": 1300.0, "posture": 600.0, "walk": 2.0, "run": 4.4, "stagger": 80, "poise": 34.0, "finisher_cap": 0.04, "ai": "x_gun",
		"look": "mahakyoung", "hp_floor": 0.4, "dmg_k": 0.55},
}

const ROOMS := [
	# 0 개전 — 교회 앞마당 계단 앞. 경호대 100인 = 10명 × 10 무리(down:g1 → g2 …)
	{"id": "church_steps", "theme": "church_yard", "bounds": Rect2(-8.0, -2.4, 16.0, 4.8), "cast": ["kimshin"],
		"heroes": [Vector2(-6.0, 0.0)],
		"allies": [["woojin", Vector2(-6.4, -1.4)], ["jintae", Vector2(-6.4, 1.4)], ["guilhwa", Vector2(-5.4, -2.0)], ["choehyeokjin", Vector2(-5.4, 2.0)],
			["hantaecheol", Vector2(-7.0, -0.6)], ["pyoyoung", Vector2(-7.0, 0.6)], ["hide", Vector2(-5.0, -0.8)], ["yeominsu", Vector2(-5.0, 0.8)]],
		"enemies": [
			["elite_guard", Vector2(0.4, -2.0), {"tag": "g1", "name": "캐슬 경호대"}], ["elite_guard", Vector2(1.0, -1.2), {"tag": "g1", "name": "캐슬 경호대"}],
			["elite_guard", Vector2(1.6, -0.4), {"tag": "g1", "name": "캐슬 경호대"}], ["elite_guard", Vector2(2.1, 0.4), {"tag": "g1", "name": "캐슬 경호대"}],
			["elite_guard", Vector2(2.7, 1.2), {"tag": "g1", "name": "캐슬 경호대"}], ["elite_guard", Vector2(3.3, 2.0), {"tag": "g1", "name": "캐슬 경호대"}],
			["elite_guard", Vector2(3.9, -2.0), {"tag": "g1", "name": "캐슬 경호대"}], ["elite_guard", Vector2(4.4, -1.2), {"tag": "g1", "name": "캐슬 경호대"}],
			["elite_guard", Vector2(5.0, -0.4), {"tag": "g1", "name": "캐슬 경호대"}], ["elite_guard", Vector2(5.6, 0.4), {"tag": "g1", "name": "캐슬 경호대"}]],
		"boss": "",
		"triggers": [
			{"when": "down:g1", "spawn": [
				["elite_guard", Vector2(6.2, -2.0), {"tag": "g2", "name": "캐슬 경호대"}], ["elite_guard", Vector2(6.4, -1.2), {"tag": "g2", "name": "캐슬 경호대"}],
				["elite_guard", Vector2(6.6, -0.4), {"tag": "g2", "name": "캐슬 경호대"}], ["elite_guard", Vector2(6.7, 0.4), {"tag": "g2", "name": "캐슬 경호대"}],
				["elite_guard", Vector2(6.9, 1.2), {"tag": "g2", "name": "캐슬 경호대"}], ["elite_guard", Vector2(7.1, 2.0), {"tag": "g2", "name": "캐슬 경호대"}],
				["elite_guard", Vector2(7.3, -2.0), {"tag": "g2", "name": "캐슬 경호대"}], ["elite_guard", Vector2(7.4, -1.2), {"tag": "g2", "name": "캐슬 경호대"}],
				["elite_guard", Vector2(7.6, -0.4), {"tag": "g2", "name": "캐슬 경호대"}], ["elite_guard", Vector2(7.8, 0.4), {"tag": "g2", "name": "캐슬 경호대"}]]},
			{"when": "down:g2", "spawn": [
				["elite_guard", Vector2(6.2, -2.0), {"tag": "g3", "name": "캐슬 경호대"}], ["elite_guard", Vector2(6.4, -1.2), {"tag": "g3", "name": "캐슬 경호대"}],
				["elite_guard", Vector2(6.6, -0.4), {"tag": "g3", "name": "캐슬 경호대"}], ["elite_guard", Vector2(6.7, 0.4), {"tag": "g3", "name": "캐슬 경호대"}],
				["elite_guard", Vector2(6.9, 1.2), {"tag": "g3", "name": "캐슬 경호대"}], ["elite_guard", Vector2(7.1, 2.0), {"tag": "g3", "name": "캐슬 경호대"}],
				["elite_guard", Vector2(7.3, -2.0), {"tag": "g3", "name": "캐슬 경호대"}], ["elite_guard", Vector2(7.4, -1.2), {"tag": "g3", "name": "캐슬 경호대"}],
				["elite_guard", Vector2(7.6, -0.4), {"tag": "g3", "name": "캐슬 경호대"}], ["elite_guard", Vector2(7.8, 0.4), {"tag": "g3", "name": "캐슬 경호대"}]]},
			{"when": "down:g3", "spawn": [
				["elite_guard", Vector2(6.2, -2.0), {"tag": "g4", "name": "캐슬 경호대"}], ["elite_guard", Vector2(6.4, -1.2), {"tag": "g4", "name": "캐슬 경호대"}],
				["elite_guard", Vector2(6.6, -0.4), {"tag": "g4", "name": "캐슬 경호대"}], ["elite_guard", Vector2(6.7, 0.4), {"tag": "g4", "name": "캐슬 경호대"}],
				["elite_guard", Vector2(6.9, 1.2), {"tag": "g4", "name": "캐슬 경호대"}], ["elite_guard", Vector2(7.1, 2.0), {"tag": "g4", "name": "캐슬 경호대"}],
				["elite_guard", Vector2(7.3, -2.0), {"tag": "g4", "name": "캐슬 경호대"}], ["elite_guard", Vector2(7.4, -1.2), {"tag": "g4", "name": "캐슬 경호대"}],
				["elite_guard", Vector2(7.6, -0.4), {"tag": "g4", "name": "캐슬 경호대"}], ["elite_guard", Vector2(7.8, 0.4), {"tag": "g4", "name": "캐슬 경호대"}]]},
			{"when": "down:g4", "spawn": [
				["elite_guard", Vector2(6.2, -2.0), {"tag": "g5", "name": "캐슬 경호대"}], ["elite_guard", Vector2(6.4, -1.2), {"tag": "g5", "name": "캐슬 경호대"}],
				["elite_guard", Vector2(6.6, -0.4), {"tag": "g5", "name": "캐슬 경호대"}], ["elite_guard", Vector2(6.7, 0.4), {"tag": "g5", "name": "캐슬 경호대"}],
				["elite_guard", Vector2(6.9, 1.2), {"tag": "g5", "name": "캐슬 경호대"}], ["elite_guard", Vector2(7.1, 2.0), {"tag": "g5", "name": "캐슬 경호대"}],
				["elite_guard", Vector2(7.3, -2.0), {"tag": "g5", "name": "캐슬 경호대"}], ["elite_guard", Vector2(7.4, -1.2), {"tag": "g5", "name": "캐슬 경호대"}],
				["elite_guard", Vector2(7.6, -0.4), {"tag": "g5", "name": "캐슬 경호대"}], ["elite_guard", Vector2(7.8, 0.4), {"tag": "g5", "name": "캐슬 경호대"}]]},
			{"when": "down:g5", "spawn": [
				["elite_guard", Vector2(6.2, -2.0), {"tag": "g6", "name": "캐슬 경호대"}], ["elite_guard", Vector2(6.4, -1.2), {"tag": "g6", "name": "캐슬 경호대"}],
				["elite_guard", Vector2(6.6, -0.4), {"tag": "g6", "name": "캐슬 경호대"}], ["elite_guard", Vector2(6.7, 0.4), {"tag": "g6", "name": "캐슬 경호대"}],
				["elite_guard", Vector2(6.9, 1.2), {"tag": "g6", "name": "캐슬 경호대"}], ["elite_guard", Vector2(7.1, 2.0), {"tag": "g6", "name": "캐슬 경호대"}],
				["elite_guard", Vector2(7.3, -2.0), {"tag": "g6", "name": "캐슬 경호대"}], ["elite_guard", Vector2(7.4, -1.2), {"tag": "g6", "name": "캐슬 경호대"}],
				["elite_guard", Vector2(7.6, -0.4), {"tag": "g6", "name": "캐슬 경호대"}], ["elite_guard", Vector2(7.8, 0.4), {"tag": "g6", "name": "캐슬 경호대"}]], "say": "wave_half"},
			{"when": "down:g6", "spawn": [
				["elite_guard", Vector2(6.2, -2.0), {"tag": "g7", "name": "캐슬 경호대"}], ["elite_guard", Vector2(6.4, -1.2), {"tag": "g7", "name": "캐슬 경호대"}],
				["elite_guard", Vector2(6.6, -0.4), {"tag": "g7", "name": "캐슬 경호대"}], ["elite_guard", Vector2(6.7, 0.4), {"tag": "g7", "name": "캐슬 경호대"}],
				["elite_guard", Vector2(6.9, 1.2), {"tag": "g7", "name": "캐슬 경호대"}], ["elite_guard", Vector2(7.1, 2.0), {"tag": "g7", "name": "캐슬 경호대"}],
				["elite_guard", Vector2(7.3, -2.0), {"tag": "g7", "name": "캐슬 경호대"}], ["elite_guard", Vector2(7.4, -1.2), {"tag": "g7", "name": "캐슬 경호대"}],
				["elite_guard", Vector2(7.6, -0.4), {"tag": "g7", "name": "캐슬 경호대"}], ["elite_guard", Vector2(7.8, 0.4), {"tag": "g7", "name": "캐슬 경호대"}]]},
			{"when": "down:g7", "spawn": [
				["elite_guard", Vector2(6.2, -2.0), {"tag": "g8", "name": "캐슬 경호대"}], ["elite_guard", Vector2(6.4, -1.2), {"tag": "g8", "name": "캐슬 경호대"}],
				["elite_guard", Vector2(6.6, -0.4), {"tag": "g8", "name": "캐슬 경호대"}], ["elite_guard", Vector2(6.7, 0.4), {"tag": "g8", "name": "캐슬 경호대"}],
				["elite_guard", Vector2(6.9, 1.2), {"tag": "g8", "name": "캐슬 경호대"}], ["elite_guard", Vector2(7.1, 2.0), {"tag": "g8", "name": "캐슬 경호대"}],
				["elite_guard", Vector2(7.3, -2.0), {"tag": "g8", "name": "캐슬 경호대"}], ["elite_guard", Vector2(7.4, -1.2), {"tag": "g8", "name": "캐슬 경호대"}],
				["elite_guard", Vector2(7.6, -0.4), {"tag": "g8", "name": "캐슬 경호대"}], ["elite_guard", Vector2(7.8, 0.4), {"tag": "g8", "name": "캐슬 경호대"}]]},
			{"when": "down:g8", "spawn": [
				["elite_guard", Vector2(6.2, -2.0), {"tag": "g9", "name": "캐슬 경호대"}], ["elite_guard", Vector2(6.4, -1.2), {"tag": "g9", "name": "캐슬 경호대"}],
				["elite_guard", Vector2(6.6, -0.4), {"tag": "g9", "name": "캐슬 경호대"}], ["elite_guard", Vector2(6.7, 0.4), {"tag": "g9", "name": "캐슬 경호대"}],
				["elite_guard", Vector2(6.9, 1.2), {"tag": "g9", "name": "캐슬 경호대"}], ["elite_guard", Vector2(7.1, 2.0), {"tag": "g9", "name": "캐슬 경호대"}],
				["elite_guard", Vector2(7.3, -2.0), {"tag": "g9", "name": "캐슬 경호대"}], ["elite_guard", Vector2(7.4, -1.2), {"tag": "g9", "name": "캐슬 경호대"}],
				["elite_guard", Vector2(7.6, -0.4), {"tag": "g9", "name": "캐슬 경호대"}], ["elite_guard", Vector2(7.8, 0.4), {"tag": "g9", "name": "캐슬 경호대"}]]},
			{"when": "down:g9", "spawn": [
				["elite_guard", Vector2(6.2, -2.0), {"tag": "g10", "name": "캐슬 경호대"}], ["elite_guard", Vector2(6.4, -1.2), {"tag": "g10", "name": "캐슬 경호대"}],
				["elite_guard", Vector2(6.6, -0.4), {"tag": "g10", "name": "캐슬 경호대"}], ["elite_guard", Vector2(6.7, 0.4), {"tag": "g10", "name": "캐슬 경호대"}],
				["elite_guard", Vector2(6.9, 1.2), {"tag": "g10", "name": "캐슬 경호대"}], ["elite_guard", Vector2(7.1, 2.0), {"tag": "g10", "name": "캐슬 경호대"}],
				["elite_guard", Vector2(7.3, -2.0), {"tag": "g10", "name": "캐슬 경호대"}], ["elite_guard", Vector2(7.4, -1.2), {"tag": "g10", "name": "캐슬 경호대"}],
				["elite_guard", Vector2(7.6, -0.4), {"tag": "g10", "name": "캐슬 경호대"}], ["elite_guard", Vector2(7.8, 0.4), {"tag": "g10", "name": "캐슬 경호대"}]], "say": "wave_last"},
		]},
	# 1 구스타프 전 — 녹색 조명 사무실 → 60% 에서 옆 비전센터 안까지(맵 넓힘)
	{"id": "green_office", "theme": "green_office", "bounds": Rect2(-6.0, -2.2, 12.0, 4.4), "cast": ["kimshin"],
		"heroes": [Vector2(-3.8, 0.2)], "allies": [],
		"enemies": [["gustav", Vector2(2.4, 0.0)]], "boss": "gustav",
		"triggers": [{"when": "hp:gustav:0.6", "bounds": Rect2(-6.0, -2.4, 20.0, 4.8), "theme": "vision_center", "say": "widen"}]},
	# 2 마준영 1차전 — 비전센터 앞. 김신 + 백의 셋 대 마준영 + 경호대 10(마준영 1/2 에서 빠진다)
	{"id": "vision_front", "theme": "church_yard", "bounds": Rect2(-7.0, -2.4, 14.0, 4.8), "cast": ["kimshin"],
		"heroes": [Vector2(-5.0, 0.0)], "allies": [["guilhwa", Vector2(-5.6, -1.4)], ["choehyeokjin", Vector2(-5.6, 1.4)], ["hantaecheol", Vector2(-6.2, 0.0)]],
		"enemies": [["elite_guard", Vector2(0.0, -2.0), {"name": "경호대 방패조"}], ["elite_guard", Vector2(0.4, 2.0), {"name": "경호대 방패조"}],
			["elite_guard", Vector2(1.0, -1.0), {"name": "경호대 방패조"}], ["elite_guard", Vector2(1.4, 1.0), {"name": "경호대 방패조"}],
			["elite_guard", Vector2(2.0, 0.0), {"name": "경호대 방패조"}], ["elite_guard", Vector2(3.4, -2.0), {"name": "경호대 방패조"}],
			["elite_guard", Vector2(3.6, 2.0), {"name": "경호대 방패조"}], ["elite_guard", Vector2(4.6, -1.0), {"name": "경호대 방패조"}],
			["elite_guard", Vector2(4.8, 1.0), {"name": "경호대 방패조"}], ["elite_guard", Vector2(5.6, 0.0), {"name": "경호대 방패조"}],
			["majunyeong", Vector2(3.0, 0.0)]], "boss": "majunyeong"},
	# 3 그롤라 전 — 1:1 → 그롤라 50% 마준영 → (그 뒤에만) 김신 50% 피우진(아군) — 2대 2
	{"id": "build_site", "theme": "build_site", "bounds": Rect2(-6.4, -2.4, 12.8, 4.8), "cast": ["kimshin"],
		"heroes": [Vector2(-3.6, 0.0)], "allies": [],
		"enemies": [["grolla", Vector2(2.4, 0.0)]], "boss": "grolla",
		"triggers": [
			{"when": "hp:grolla:0.5", "spawn": [["majunyeong", Vector2(6.4, 1.2), {"role": "majunyeong2"}]], "say": "majun_in"},
			{"when": "hp:kimshin:0.5", "requires": [0], "spawn_allies": [["woojin", Vector2(-6.4, -1.0)]], "say": "woojin_in"},
		]},
	# 4 신겐 1차전 — 교회 본동 3층 복도. 반 야마구치 연합(교대) + 히데 쪽 야쿠자 대 신겐 · 하야부사 · 토이시 · 이와시로 + 야쿠자
	{"id": "corridor_3f", "theme": "church_corridor", "bounds": Rect2(-8.0, -2.0, 16.0, 4.0), "cast": ["hide", "hyeonseok", "pyoyoung", "yamamotokyoji"],
		"heroes": [Vector2(-5.6, -0.4), Vector2(-6.2, 1.0), Vector2(-6.2, -1.6), Vector2(-6.8, 0.2)],
		"allies": [["gang_blade", Vector2(-7.2, -1.2), {"role": "yakuza_ally", "name": "히데 쪽 야쿠자", "look": "haseong_suit"}], ["gang_blade", Vector2(-7.2, 1.2), {"role": "yakuza_ally", "name": "히데 쪽 야쿠자", "look": "haseong_suit"}],
			["gang_blade", Vector2(-7.6, 0.0), {"role": "yakuza_ally", "name": "히데 쪽 야쿠자", "look": "haseong_suit"}], ["gang_blade", Vector2(-5.0, 1.6), {"role": "yakuza_ally", "name": "히데 쪽 야쿠자", "look": "haseong_suit"}],
			["gang_blade", Vector2(-5.0, -1.8), {"role": "yakuza_ally", "name": "히데 쪽 야쿠자", "look": "haseong_suit"}]],
		"enemies": [["shingen", Vector2(5.0, 0.0), {"role": "shingen1"}], ["hayabusa", Vector2(3.2, -1.0)], ["toishi", Vector2(3.2, 1.0)], ["iwashiro", Vector2(6.6, 0.4)],
			["gang_blade", Vector2(0.6, -1.6), {"tag": "y1", "name": "신겐 쪽 야쿠자"}], ["gang_blade", Vector2(0.8, 1.6), {"tag": "y1", "name": "신겐 쪽 야쿠자"}],
			["gang_blade", Vector2(1.4, 0.0), {"tag": "y1", "name": "신겐 쪽 야쿠자"}], ["gang_blade", Vector2(2.0, -1.8), {"tag": "y1", "name": "신겐 쪽 야쿠자"}],
			["gang_blade", Vector2(2.2, 1.8), {"tag": "y1", "name": "신겐 쪽 야쿠자"}]], "boss": "shingen",
		"triggers": [
			{"when": "time:12", "spawn": [["gang_blade", Vector2(8.0, -1.6), {"name": "신겐 쪽 야쿠자"}], ["gang_blade", Vector2(8.0, -0.8), {"name": "신겐 쪽 야쿠자"}],
				["gang_blade", Vector2(8.0, 0.0), {"name": "신겐 쪽 야쿠자"}], ["gang_blade", Vector2(8.0, 0.8), {"name": "신겐 쪽 야쿠자"}], ["gang_blade", Vector2(8.0, 1.6), {"name": "신겐 쪽 야쿠자"}]],
			"spawn_allies": [["gang_blade", Vector2(-8.0, -1.6), {"role": "yakuza_ally", "name": "히데 쪽 야쿠자", "look": "haseong_suit"}], ["gang_blade", Vector2(-8.0, -0.8), {"role": "yakuza_ally", "name": "히데 쪽 야쿠자", "look": "haseong_suit"}],
				["gang_blade", Vector2(-8.0, 0.0), {"role": "yakuza_ally", "name": "히데 쪽 야쿠자", "look": "haseong_suit"}], ["gang_blade", Vector2(-8.0, 0.8), {"role": "yakuza_ally", "name": "히데 쪽 야쿠자", "look": "haseong_suit"}],
				["gang_blade", Vector2(-8.0, 1.6), {"role": "yakuza_ally", "name": "히데 쪽 야쿠자", "look": "haseong_suit"}]], "say": "more"},
		]},
	# 5 신겐 2차전 — 본동 4층. 피우진 대 신겐 → 70% 에서 피우진이 물러나고 김신이 들어선다
	{"id": "hall_4f_woojin", "theme": "church_hall", "bounds": Rect2(-6.0, -2.4, 12.0, 4.8), "cast": ["woojin"],
		"heroes": [Vector2(-3.6, 0.0)], "allies": [],
		"enemies": [["shingen", Vector2(2.4, 0.0), {"role": "shingen2"}]], "boss": "shingen",
		"triggers": [{"when": "hp:shingen:0.7", "calm": true, "cast": ["kimshin"], "cast_at": [Vector2(-5.4, 0.6)], "say": "kim_in", "clear": true}]},
	# 6 신겐 3차전 — 본동 4층. 김신 대 신겐
	{"id": "hall_4f_kim", "theme": "church_hall", "bounds": Rect2(-6.0, -2.4, 12.0, 4.8), "cast": ["kimshin"],
		"heroes": [Vector2(-3.6, 0.0)], "allies": [],
		"enemies": [["shingen", Vector2(2.4, 0.0)]], "boss": "shingen"},
	# 7 최민욱 잡기 — 본동 로비. 김신은 서 있고(조작 안 함) 여덟이 교대로 마학영 + 경호대 50 을 60초 버틴다
	{"id": "lobby_hold", "theme": "church_lobby", "bounds": Rect2(-7.0, -2.4, 14.0, 4.8),
		"cast": ["woojin", "pyoyoung", "hide", "choedalcheon", "yamamotokyoji", "yeominsu", "hantaecheol", "choehyeokjin"],
		"heroes": [Vector2(-4.0, 0.0), Vector2(-4.4, -1.4), Vector2(-4.4, 1.4), Vector2(-5.0, -0.6), Vector2(-5.0, 0.6), Vector2(-5.4, -1.8),
			Vector2(-5.4, 1.8), Vector2(-5.8, 0.0)],
		"allies": [], "standing": [["kimshin", Vector2(-6.6, 0.0), 0]], "survive": 60,
		"enemies": [["mahakyoung", Vector2(4.4, 0.0), {"role": "mahakyoung_hold"}],
			["elite_guard", Vector2(0.6, -2.0), {"tag": "h1", "name": "캐슬 경호대"}], ["elite_guard", Vector2(1.2, -1.2), {"tag": "h1", "name": "캐슬 경호대"}],
			["elite_guard", Vector2(1.7, -0.4), {"tag": "h1", "name": "캐슬 경호대"}], ["elite_guard", Vector2(2.3, 0.4), {"tag": "h1", "name": "캐슬 경호대"}],
			["elite_guard", Vector2(2.8, 1.2), {"tag": "h1", "name": "캐슬 경호대"}], ["elite_guard", Vector2(3.4, 2.0), {"tag": "h1", "name": "캐슬 경호대"}],
			["elite_guard", Vector2(3.9, -2.0), {"tag": "h1", "name": "캐슬 경호대"}], ["elite_guard", Vector2(4.5, -1.2), {"tag": "h1", "name": "캐슬 경호대"}],
			["elite_guard", Vector2(5.0, -0.4), {"tag": "h1", "name": "캐슬 경호대"}], ["elite_guard", Vector2(5.6, 0.4), {"tag": "h1", "name": "캐슬 경호대"}]],
		"boss": "mahakyoung",
		"triggers": [
			{"when": "time:10", "spawn": [
				["elite_guard", Vector2(5.4, -2.0), {"tag": "h2", "name": "캐슬 경호대"}], ["elite_guard", Vector2(5.6, -1.2), {"tag": "h2", "name": "캐슬 경호대"}],
				["elite_guard", Vector2(5.7, -0.4), {"tag": "h2", "name": "캐슬 경호대"}], ["elite_guard", Vector2(5.9, 0.4), {"tag": "h2", "name": "캐슬 경호대"}],
				["elite_guard", Vector2(6.0, 1.2), {"tag": "h2", "name": "캐슬 경호대"}], ["elite_guard", Vector2(6.2, 2.0), {"tag": "h2", "name": "캐슬 경호대"}],
				["elite_guard", Vector2(6.3, -2.0), {"tag": "h2", "name": "캐슬 경호대"}], ["elite_guard", Vector2(6.5, -1.2), {"tag": "h2", "name": "캐슬 경호대"}],
				["elite_guard", Vector2(6.6, -0.4), {"tag": "h2", "name": "캐슬 경호대"}], ["elite_guard", Vector2(6.8, 0.4), {"tag": "h2", "name": "캐슬 경호대"}]]},
			{"when": "time:20", "spawn": [
				["elite_guard", Vector2(5.4, -2.0), {"tag": "h3", "name": "캐슬 경호대"}], ["elite_guard", Vector2(5.6, -1.2), {"tag": "h3", "name": "캐슬 경호대"}],
				["elite_guard", Vector2(5.7, -0.4), {"tag": "h3", "name": "캐슬 경호대"}], ["elite_guard", Vector2(5.9, 0.4), {"tag": "h3", "name": "캐슬 경호대"}],
				["elite_guard", Vector2(6.0, 1.2), {"tag": "h3", "name": "캐슬 경호대"}], ["elite_guard", Vector2(6.2, 2.0), {"tag": "h3", "name": "캐슬 경호대"}],
				["elite_guard", Vector2(6.3, -2.0), {"tag": "h3", "name": "캐슬 경호대"}], ["elite_guard", Vector2(6.5, -1.2), {"tag": "h3", "name": "캐슬 경호대"}],
				["elite_guard", Vector2(6.6, -0.4), {"tag": "h3", "name": "캐슬 경호대"}], ["elite_guard", Vector2(6.8, 0.4), {"tag": "h3", "name": "캐슬 경호대"}]]},
			{"when": "time:30", "spawn": [
				["elite_guard", Vector2(5.4, -2.0), {"tag": "h4", "name": "캐슬 경호대"}], ["elite_guard", Vector2(5.6, -1.2), {"tag": "h4", "name": "캐슬 경호대"}],
				["elite_guard", Vector2(5.7, -0.4), {"tag": "h4", "name": "캐슬 경호대"}], ["elite_guard", Vector2(5.9, 0.4), {"tag": "h4", "name": "캐슬 경호대"}],
				["elite_guard", Vector2(6.0, 1.2), {"tag": "h4", "name": "캐슬 경호대"}], ["elite_guard", Vector2(6.2, 2.0), {"tag": "h4", "name": "캐슬 경호대"}],
				["elite_guard", Vector2(6.3, -2.0), {"tag": "h4", "name": "캐슬 경호대"}], ["elite_guard", Vector2(6.5, -1.2), {"tag": "h4", "name": "캐슬 경호대"}],
				["elite_guard", Vector2(6.6, -0.4), {"tag": "h4", "name": "캐슬 경호대"}], ["elite_guard", Vector2(6.8, 0.4), {"tag": "h4", "name": "캐슬 경호대"}]]},
			{"when": "time:40", "spawn": [
				["elite_guard", Vector2(5.4, -2.0), {"tag": "h5", "name": "캐슬 경호대"}], ["elite_guard", Vector2(5.6, -1.2), {"tag": "h5", "name": "캐슬 경호대"}],
				["elite_guard", Vector2(5.7, -0.4), {"tag": "h5", "name": "캐슬 경호대"}], ["elite_guard", Vector2(5.9, 0.4), {"tag": "h5", "name": "캐슬 경호대"}],
				["elite_guard", Vector2(6.0, 1.2), {"tag": "h5", "name": "캐슬 경호대"}], ["elite_guard", Vector2(6.2, 2.0), {"tag": "h5", "name": "캐슬 경호대"}],
				["elite_guard", Vector2(6.3, -2.0), {"tag": "h5", "name": "캐슬 경호대"}], ["elite_guard", Vector2(6.5, -1.2), {"tag": "h5", "name": "캐슬 경호대"}],
				["elite_guard", Vector2(6.6, -0.4), {"tag": "h5", "name": "캐슬 경호대"}], ["elite_guard", Vector2(6.8, 0.4), {"tag": "h5", "name": "캐슬 경호대"}]]},
			{"when": "time:25", "say": "rally"},
		]},
	# 8 마학영 전 — 지하 주차장. 서진태 30% · 김신은 셔터 안으로 → 서진태가 쓰러지면 김신이 돌아온다
	{"id": "parking", "theme": "parking", "bounds": Rect2(-6.4, -2.4, 12.8, 4.8), "cast": ["kimshin", "jintae"], "hp_start": {"jintae": 0.3},
		"heroes": [Vector2(-4.0, -0.6), Vector2(-3.6, 0.8)], "allies": [],
		"enemies": [["mahakyoung", Vector2(2.6, 0.0)],
			["elite_guard", Vector2(1.0, -2.0), {"name": "경호대"}], ["elite_guard", Vector2(1.2, 2.0), {"name": "경호대"}],
			["elite_guard", Vector2(1.8, -1.0), {"name": "경호대"}], ["elite_guard", Vector2(2.0, 1.2), {"name": "경호대"}],
			["elite_guard", Vector2(3.6, -2.0), {"name": "경호대"}], ["elite_guard", Vector2(3.8, 2.0), {"name": "경호대"}],
			["elite_guard", Vector2(4.4, -1.0), {"name": "경호대"}], ["elite_guard", Vector2(4.6, 1.0), {"name": "경호대"}],
			["elite_guard", Vector2(5.2, -0.2), {"name": "경호대"}], ["elite_guard", Vector2(5.6, 1.6), {"name": "경호대"}]], "boss": "mahakyoung",
		"triggers": [
			{"when": "time:1", "cast": ["jintae"], "say": "door_close"},
			{"when": "down:jintae", "requires": [0], "cast": ["kimshin"], "cast_at": [Vector2(-5.8, 0.0)], "say": "kim_back"},
		]},
	{"id": "church_end", "theme": "church_yard", "bounds": Rect2(-5.0, -2.4, 10.0, 4.8), "cast": ["kimshin"],
		"heroes": [Vector2(-1.6, 0.4)], "allies": [], "enemies": [], "boss": "", "end": true},
]

const INTRO_T := 75
const CLEAR_T := 150
const END_T := 420
const HEAL_ON_CLEAR := 0.35
const MAX_ATTACKERS := 2
