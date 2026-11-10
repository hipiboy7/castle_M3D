extends RefCounted
## 13장 '세대 교체'(2부 127-134 — 미술관 앞) — 마지막 장. 칸 뜻은 ch3_busan.gd 와 같다. 방 규칙 칸은 stage.gd 머리.
## 스테이지 셋은 사용자 목록 그대로(2026-11-10 폰 리뷰 rc.8 — '도학수, 어광득은 모두 우리편. 모든 싸움은 미술관 앞에서 일어남'):
##   0 미술관 앞 공터 — 김신(맨손 — 127/026 소매를 걷고) + 백의 주요 인력(김신 · 피우진 빼고 — 서진태는 12장에서 숨졌다) 대 경호대 50인
##     (10명씩 다섯 무리 — down:m1 → m2 …). 다 쓰러뜨리면(trigger clear) 백의 사람들은 물러서고, 피우진이 캐슬홀딩스 쪽에서 나와
##     김신과 맨주먹 1:1(128/068-070 '나와라, 김신' → fight:jumeok_seungbu 129-134). 피우진이 쓰러지면 '가져가라, 확실하게'(134/055)
##   1 미술관 — 라텔 · 샤이어(교대) + 백의 10 대 사인진(134/065 '치사하게 대가리 쪽수로 밀어붙여?!')
##   2 최민욱 — 그림 앞. 김신 대 최민욱. 쓰러뜨리면 게임 끝(fade → 끝 방)
## 편: 김신 · 도학수 · 어광득 · 백의 대 최민욱 · 캐슬홀딩스 경호대(피우진은 경호대 · 선진을 이끌고 최민욱 쪽에서 — 127/032).
## 난이도: 김신은 재앙 — 피우진(외성 상위) · 최민욱(내성 중위)은 아랫급이라 dmg_k ≤ 1. 사인진(이스크라 평 킬러급)은 라텔(외성 하위)보다 아랫급.
## 원작과 다른 점: 원작에서 김신이 최민욱과 맞붙는 싸움은 없다(134 김신은 사인진을 찌르고 최민욱에게 거래를 건다 — 134/065-073) — 사용자 지시로
## 최민욱을 마지막 보스로. 미술관 안 사인진 싸움도 사용자 지시(원작은 묶여 끌려온 사인진 — fight:kimshin_sainjin).

const EVENT := "fight:shingen"       # 시점: 12장 뒤 — 피우진 외성 상위(fight:shingen 100)
const PERIOD := "church"

const CANON := {
	"museum_front": {"fight": "fight:misulgwan_seupgyeok", "place": "misulgwan"},
	"museum_hall": {"fight": "fight:kimshin_sainjin", "place": "misulgwan"},
	"choeminuk": {"fight": "fight:gangminseong_choeminuk", "place": "misulgwan"},
	"finale": {"fight": "", "place": "misulgwan"},
}

const HEROES := ["kimshin", "ratel", "shire"]
const LINES := "ch13"
const CROWD_ID := "elite_guard"

const NPCS := {
	"woojin": {"rank": "외성 상위"},       # 주먹 승부의 피우진(적 — 교회전 신겐과 싸운 뒤, fight:shingen)
	"pyoyoung": {"rank": "외성 중위"},     # 교회전 이후
	"hide": {"rank": "외성 중위"},
	"yeominsu": {"rank": "이스크라 평 킬러급"},
}

const ROLES := {
	"kimshin": {"hp": 200.0, "posture": 60.0, "walk": 2.1, "run": 4.6, "stagger": 50, "look": "kim",
		"moveset": {"combo": "k_slash1", "dash": "k_dash", "counter": "k_counter", "finisher": "k_finisher"}},
	"kimshin_bare": {"look": "kim_bare",
		"moveset": {"combo": "kf_jab", "dash": "kf_dash", "counter": "kf_counter", "finisher": "kf_finisher"}},
	# 미술관 안 — 라텔(쌍칼) · 샤이어(맨손 · 총) — 조작(교대)
	"ratel": {"hp": 230.0, "posture": 70.0, "walk": 2.2, "run": 4.8, "stagger": 50, "look": "ratel",
		"moveset": {"combo": "rtj_1", "dash": "rtj_dash", "finisher": "jk_finisher"}},
	"shire": {"hp": 240.0, "posture": 70.0, "walk": 2.1, "run": 4.6, "stagger": 50, "look": "shire",
		"moveset": {"combo": "srw_1", "dash": "srw_dash", "finisher": "w_finisher"}},
	# 아군(백의): 도학수(포항) · 어광득(대구 동성로) — 맨주먹 · 박치기(127/024-025) · 구일화 · 최혁진 · 한태철 · 표영 · 히데 · 여민수
	"dohaksu": {"hp": 220.0, "posture": 90.0, "walk": 1.9, "run": 4.1, "stagger": 55, "look": "dohaksu",
		"moveset": {"combo": "dh_1", "dash": "dh_dash", "finisher": "ny_finisher"}},
	"eogwangdeuk": {"hp": 220.0, "posture": 90.0, "walk": 1.9, "run": 4.1, "stagger": 55, "look": "eogwangdeuk",
		"moveset": {"combo": "eg_1", "dash": "eg_dash", "finisher": "ny_finisher"}},
	"guilhwa": {"hp": 220.0, "posture": 80.0, "walk": 2.0, "run": 4.4, "stagger": 55, "look": "guilhwa",
		"moveset": {"combo": "gu_jab", "dash": "gu_dash", "finisher": "gu_finisher"}},
	"choehyeokjin": {"hp": 200.0, "posture": 70.0, "walk": 2.0, "run": 4.3, "stagger": 55, "look": "choehyeokjin",
		"moveset": {"combo": "cj_1", "dash": "cj_dash", "finisher": "ny_finisher"}},
	"hantaecheol": {"hp": 220.0, "posture": 70.0, "walk": 1.9, "run": 4.1, "stagger": 55, "look": "hantaecheol",
		"moveset": {"combo": "ht_1", "dash": "ht_dash", "finisher": "ny_finisher"}},
	"pyoyoung": {"hp": 220.0, "posture": 60.0, "walk": 2.3, "run": 5.0, "stagger": 55, "look": "pyoyoung",
		"moveset": {"combo": "py_slash1", "dash": "py_dash", "finisher": "py_finisher"}},
	"hide": {"hp": 230.0, "posture": 70.0, "walk": 2.2, "run": 4.8, "stagger": 50, "look": "hide",
		"moveset": {"combo": "hd_1", "dash": "hd_dash", "finisher": "k_finisher"}},
	"yeominsu": {"hp": 240.0, "posture": 80.0, "walk": 2.0, "run": 4.3, "stagger": 55, "look": "yeominsu",
		"moveset": {"combo": "ym_1", "dash": "ym_dash", "finisher": "gu_finisher"}},
	# 백의 조직원(이름 없는 무리 — 엑스트라 gang_brute, 이 장에서는 아군만)
	"gang_brute": {"hp": 150.0, "posture": 50.0, "walk": 1.9, "run": 4.1, "stagger": 60, "look": "haseong_suit",
		"moveset": {"combo": "ny_jab", "dash": "ny_dash", "finisher": "ny_finisher"}},
	# 적: 캐슬홀딩스 경호대(1 ~ 2대)
	"elite_guard": {"hp": 110.0, "posture": 40.0, "walk": 1.9, "run": 4.1, "stagger": 70, "poise": 2.0, "ai": "haseong_guard", "look": "guard"},
	# 피우진(적 — 주먹 승부): 주먹 · 발 · 메다꽂기를 섞는 x_master(129/032-035 메침 · 134/042-046 앞차기)
	"woojin": {"hp": 760.0, "posture": 420.0, "walk": 2.1, "run": 4.6, "stagger": 50, "look": "woojin", "ai": "x_master",
		"poise": 30.0, "finisher_cap": 0.05, "phase2_at": 0.5, "dmg_k": 0.9},
	# 사인진(칼 · 총 — 이스크라 평 킬러급)
	"sainjin": {"hp": 700.0, "posture": 320.0, "walk": 2.1, "run": 4.6, "stagger": 75, "poise": 20.0, "finisher_cap": 0.06, "ai": "x_blade",
		"look": "sainjin", "phase2_at": 0.5, "dmg_k": 0.8},
	# 최민욱(내성 중위 — 마지막 보스)
	"choeminuk": {"hp": 1100.0, "posture": 480.0, "walk": 2.1, "run": 4.6, "stagger": 80, "poise": 30.0, "finisher_cap": 0.05, "ai": "x_master",
		"look": "choeminuk", "phase2_at": 0.5, "dmg_k": 0.95},
}

## 공터의 백의 사람들(피우진이 나오면 물러선다 — trigger inert)
const BAEKUI := ["dohaksu", "eogwangdeuk", "guilhwa", "choehyeokjin", "hantaecheol", "pyoyoung", "hide", "yeominsu"]

const ROOMS := [
	# 0 미술관 앞 공터 — 경호대 50인(10 × 5 무리) → 피우진 1:1
	{"id": "museum_front", "theme": "museum_plaza", "bounds": Rect2(-8.0, -2.4, 16.0, 4.8), "cast": ["kimshin"], "kit": {"kimshin": "kimshin_bare"},
		"heroes": [Vector2(-6.0, 0.0)],
		"allies": [["dohaksu", Vector2(-6.4, -1.4)], ["eogwangdeuk", Vector2(-6.4, 1.4)], ["guilhwa", Vector2(-5.4, -2.0)], ["choehyeokjin", Vector2(-5.4, 2.0)],
			["hantaecheol", Vector2(-7.0, -0.6)], ["pyoyoung", Vector2(-7.0, 0.6)], ["hide", Vector2(-5.0, -0.8)], ["yeominsu", Vector2(-5.0, 0.8)]],
		"enemies": [
			["elite_guard", Vector2(0.4, -2.0), {"tag": "m1", "name": "캐슬 경호대"}], ["elite_guard", Vector2(1.0, -1.2), {"tag": "m1", "name": "캐슬 경호대"}],
			["elite_guard", Vector2(1.6, -0.4), {"tag": "m1", "name": "캐슬 경호대"}], ["elite_guard", Vector2(2.1, 0.4), {"tag": "m1", "name": "캐슬 경호대"}],
			["elite_guard", Vector2(2.7, 1.2), {"tag": "m1", "name": "캐슬 경호대"}], ["elite_guard", Vector2(3.3, 2.0), {"tag": "m1", "name": "캐슬 경호대"}],
			["elite_guard", Vector2(3.9, -2.0), {"tag": "m1", "name": "캐슬 경호대"}], ["elite_guard", Vector2(4.4, -1.2), {"tag": "m1", "name": "캐슬 경호대"}],
			["elite_guard", Vector2(5.0, -0.4), {"tag": "m1", "name": "캐슬 경호대"}], ["elite_guard", Vector2(5.6, 0.4), {"tag": "m1", "name": "캐슬 경호대"}]],
		"boss": "",
		"triggers": [
			{"when": "down:m1", "spawn": [
				["elite_guard", Vector2(6.2, -2.0), {"tag": "m2", "name": "캐슬 경호대"}], ["elite_guard", Vector2(6.4, -1.2), {"tag": "m2", "name": "캐슬 경호대"}],
				["elite_guard", Vector2(6.6, -0.4), {"tag": "m2", "name": "캐슬 경호대"}], ["elite_guard", Vector2(6.7, 0.4), {"tag": "m2", "name": "캐슬 경호대"}],
				["elite_guard", Vector2(6.9, 1.2), {"tag": "m2", "name": "캐슬 경호대"}], ["elite_guard", Vector2(7.1, 2.0), {"tag": "m2", "name": "캐슬 경호대"}],
				["elite_guard", Vector2(7.3, -2.0), {"tag": "m2", "name": "캐슬 경호대"}], ["elite_guard", Vector2(7.4, -1.2), {"tag": "m2", "name": "캐슬 경호대"}],
				["elite_guard", Vector2(7.6, -0.4), {"tag": "m2", "name": "캐슬 경호대"}], ["elite_guard", Vector2(7.8, 0.4), {"tag": "m2", "name": "캐슬 경호대"}]]},
			{"when": "down:m2", "spawn": [
				["elite_guard", Vector2(6.2, -2.0), {"tag": "m3", "name": "캐슬 경호대"}], ["elite_guard", Vector2(6.4, -1.2), {"tag": "m3", "name": "캐슬 경호대"}],
				["elite_guard", Vector2(6.6, -0.4), {"tag": "m3", "name": "캐슬 경호대"}], ["elite_guard", Vector2(6.7, 0.4), {"tag": "m3", "name": "캐슬 경호대"}],
				["elite_guard", Vector2(6.9, 1.2), {"tag": "m3", "name": "캐슬 경호대"}], ["elite_guard", Vector2(7.1, 2.0), {"tag": "m3", "name": "캐슬 경호대"}],
				["elite_guard", Vector2(7.3, -2.0), {"tag": "m3", "name": "캐슬 경호대"}], ["elite_guard", Vector2(7.4, -1.2), {"tag": "m3", "name": "캐슬 경호대"}],
				["elite_guard", Vector2(7.6, -0.4), {"tag": "m3", "name": "캐슬 경호대"}], ["elite_guard", Vector2(7.8, 0.4), {"tag": "m3", "name": "캐슬 경호대"}]], "say": "wave_half"},
			{"when": "down:m3", "spawn": [
				["elite_guard", Vector2(6.2, -2.0), {"tag": "m4", "name": "캐슬 경호대"}], ["elite_guard", Vector2(6.4, -1.2), {"tag": "m4", "name": "캐슬 경호대"}],
				["elite_guard", Vector2(6.6, -0.4), {"tag": "m4", "name": "캐슬 경호대"}], ["elite_guard", Vector2(6.7, 0.4), {"tag": "m4", "name": "캐슬 경호대"}],
				["elite_guard", Vector2(6.9, 1.2), {"tag": "m4", "name": "캐슬 경호대"}], ["elite_guard", Vector2(7.1, 2.0), {"tag": "m4", "name": "캐슬 경호대"}],
				["elite_guard", Vector2(7.3, -2.0), {"tag": "m4", "name": "캐슬 경호대"}], ["elite_guard", Vector2(7.4, -1.2), {"tag": "m4", "name": "캐슬 경호대"}],
				["elite_guard", Vector2(7.6, -0.4), {"tag": "m4", "name": "캐슬 경호대"}], ["elite_guard", Vector2(7.8, 0.4), {"tag": "m4", "name": "캐슬 경호대"}]]},
			{"when": "down:m4", "spawn": [
				["elite_guard", Vector2(6.2, -2.0), {"tag": "m5", "name": "캐슬 경호대"}], ["elite_guard", Vector2(6.4, -1.2), {"tag": "m5", "name": "캐슬 경호대"}],
				["elite_guard", Vector2(6.6, -0.4), {"tag": "m5", "name": "캐슬 경호대"}], ["elite_guard", Vector2(6.7, 0.4), {"tag": "m5", "name": "캐슬 경호대"}],
				["elite_guard", Vector2(6.9, 1.2), {"tag": "m5", "name": "캐슬 경호대"}], ["elite_guard", Vector2(7.1, 2.0), {"tag": "m5", "name": "캐슬 경호대"}],
				["elite_guard", Vector2(7.3, -2.0), {"tag": "m5", "name": "캐슬 경호대"}], ["elite_guard", Vector2(7.4, -1.2), {"tag": "m5", "name": "캐슬 경호대"}],
				["elite_guard", Vector2(7.6, -0.4), {"tag": "m5", "name": "캐슬 경호대"}], ["elite_guard", Vector2(7.8, 0.4), {"tag": "m5", "name": "캐슬 경호대"}]]},
			{"when": "clear", "inert": BAEKUI, "spawn": [["woojin", Vector2(7.6, 0.0)]], "boss": "woojin", "say": "woojin_in"},
			{"when": "down:woojin", "say": "duel_end"},
		]},
	# 1 미술관 — 라텔 · 샤이어 + 백의 10 대 사인진
	{"id": "museum_hall", "theme": "museum_hall", "bounds": Rect2(-6.4, -2.4, 12.8, 4.8), "cast": ["ratel", "shire"],
		"heroes": [Vector2(-3.8, -0.6), Vector2(-4.2, 0.8)],
		"allies": [["gang_brute", Vector2(-5.0, -2.0), {"name": "백의 조직원"}], ["gang_brute", Vector2(-5.0, 2.0), {"name": "백의 조직원"}],
			["gang_brute", Vector2(-5.4, -1.2), {"name": "백의 조직원"}], ["gang_brute", Vector2(-5.4, 1.2), {"name": "백의 조직원"}],
			["gang_brute", Vector2(-5.8, -0.4), {"name": "백의 조직원"}], ["gang_brute", Vector2(-5.8, 0.4), {"name": "백의 조직원"}],
			["gang_brute", Vector2(-6.2, -1.6), {"name": "백의 조직원"}], ["gang_brute", Vector2(-6.2, 1.6), {"name": "백의 조직원"}],
			["gang_brute", Vector2(-4.6, -1.6), {"name": "백의 조직원"}], ["gang_brute", Vector2(-4.6, 1.6), {"name": "백의 조직원"}]],
		"enemies": [["sainjin", Vector2(2.6, 0.0)]], "boss": "sainjin"},
	# 2 최민욱 — 그림 앞. 쓰러뜨리면 게임 끝
	{"id": "choeminuk", "theme": "museum_hall", "bounds": Rect2(-5.6, -2.4, 11.2, 4.8), "cast": ["kimshin"],
		"heroes": [Vector2(-3.0, 0.2)], "allies": [],
		"enemies": [["choeminuk", Vector2(2.6, 0.0)]], "boss": "choeminuk", "fade": "fade"},
	{"id": "finale", "theme": "museum_plaza", "bounds": Rect2(-5.0, -2.4, 10.0, 4.8), "cast": ["kimshin"],
		"heroes": [Vector2(-0.6, 0.4)], "allies": [], "enemies": [], "boss": "", "end": true},
]

const INTRO_T := 75
const CLEAR_T := 150
const END_T := 600
const HEAL_ON_CLEAR := 0.4
const MAX_ATTACKERS := 2
