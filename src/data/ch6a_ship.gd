extends RefCounted
## 6장 앞 · 인천항 — 백도찬의 배(1부 p1:089-111). 6장 결투(김신 대 백도찬 — duel.gd, 장 id ch6) 앞에 배 위 싸움을 넷으로 둔다
## (기획서 02 3절 6장 '코모도(서진태) · 남궁혁(피우진) · 백도찬(김신) — 셋 교대'). 칸 뜻은 ch3_busan.gd 와 같다.
## 편(2026-11-10 다시 맞춤 — castle_common canon fights): 백의(김신 · 피우진 · 서진태) + **이스크라(메드베디 · 라텔 · 크리사 — 우리 편,
## 리사가 내놓은 '조커' p1:087-088)** 대 백도찬 · 선진(남궁혁) · 스케일 킬러단(조끼 경비 · 복면 무리) · 코모도. 부두에서는 이슬 · 구일화 ·
## 도학수 · 어광득 등 백의 무리가 선진 항구 무리(약 200)와 따로 싸운다(fight:baekui_sunjin — 대사로만).
## 흐름(화/컷, conf ai 판독):
##   1 갑판 → 선내 복도(fight:iskra_scale p1:089-092 · fight:kimshin_seonsil p1:090-091) — 셋 교대, 이스크라 메드베디 · 라텔이 곁에서
##     스케일 조끼 경비 · 복면 무리를 친다
##   2 선창 창고(fight:kimshin_seonsil p1:091/004-005) — 김신 혼자 들어선다: 백도찬을 닮은 안경 남자(대역)의 곡선 단검 → 얼굴을 베고 함정을 깨닫는다
##   3 선교(fight:jintae_komodo p1:090-091 · 106-107) — 서진태 대 코모도와 매복 부하 둘(기둥 뒤 조끼 · 콘솔 뒤 총잡이) — 칼 쥔 손가락을 베어
##     패주시킨다(진행 beat:komodo — 외성 중위 · 오리지널)
##   4 선내 복도(fight:woojin_namgunghyuk p1:097-111) — 크리사가 먼저 남궁혁에게 쓰러지고(fight:keurisa_namgunghyuk) 피우진이 받아 낸다 —
##     들어 올려 머리부터 내리꽂기(진행 beat:namgunghyuk — 전국구)
##   5 끝 — 메드베디가 백도찬을 붙잡아 두다 쓰러진다(fight:medvedi_baekdochan p1:095) → 김신이 교대(다음 장 ch6 결투 — fight:kimshin_baekdochan)
## 원작과 다른 점: 이스크라 셋은 원작에서 각자 따로 움직인다 — 1 방에 메드베디 · 라텔만 아군으로 세운다(크리사는 4 방 대사로).
## 코모도는 원작에서 끝내 배 밖으로 달아난다 — 이 판은 쓰러뜨리면 방을 넘는다(달아난 것은 대사로).

const EVENT := "beat:gustav"
const PERIOD := "p1"

const CANON := {
	"ship_deck": {"fight": "fight:iskra_scale", "place": "incheonhang_je3budu"},
	"ship_cargo": {"fight": "fight:kimshin_seonsil", "place": "incheonhang_je3budu"},
	"ship_bridge": {"fight": "fight:jintae_komodo", "place": "incheonhang_je3budu"},
	"ship_hold": {"fight": "fight:woojin_namgunghyuk", "place": "incheonhang_je3budu"},
	"ship_end": {"fight": "", "place": "incheonhang_je3budu"},     # 대사 — fight:medvedi_baekdochan(p1:092-095)
}

const HEROES := ["kimshin", "woojin", "jintae"]
const LINES := "ch6a"
const CROWD_ID := "elite_guard"

const ROLES := {
	"kimshin": {"hp": 200.0, "posture": 60.0, "walk": 2.1, "run": 4.6, "stagger": 50, "look": "kim_p1_blade",
		"moveset": {"combo": "k_slash1", "dash": "k_dash", "counter": "k_counter", "finisher": "k_finisher"}},
	"woojin": {"hp": 220.0, "posture": 70.0, "walk": 2.1, "run": 4.6, "stagger": 50, "look": "woojin",
		"moveset": {"combo": "w_jab", "dash": "w_dash", "finisher": "w_finisher"}},
	"jintae": {"hp": 230.0, "posture": 70.0, "walk": 2.2, "run": 4.8, "stagger": 50, "look": "jintae",
		"moveset": {"combo": "jk_slash1", "dash": "jk_dash", "finisher": "jk_finisher"}},
	# 이스크라(아군 — 리사의 조커): 메드베디(거구 · 몸통 들이받아 거꾸로 내리꽂기 p1:090/002 — 피우진의 둘째 스승이라 같은 잡기 손) ·
	# 라텔(양손 단검 · 카람빗 p1:092/003 — 표영과 같은 칼 손)
	"medvedi": {"hp": 300.0, "posture": 110.0, "walk": 1.9, "run": 4.2, "stagger": 55, "look": "medvedi",
		"moveset": {"combo": "md_1", "dash": "md_dash", "finisher": "w_finisher"}},
	"ratel": {"hp": 240.0, "posture": 80.0, "walk": 2.2, "run": 4.8, "stagger": 50, "look": "ratel",
		"moveset": {"combo": "rt_1", "dash": "rt_dash", "finisher": "py_finisher"}},
	# 스케일 킬러단 · 선진 선원(적)
	"elite_guard": {"hp": 300.0, "posture": 70.0, "walk": 1.9, "run": 4.1, "stagger": 70, "poise": 4.0, "ai": "haseong_guard", "look": "guard"},
	"pro_fighter": {"hp": 420.0, "posture": 120.0, "walk": 2.0, "run": 4.3, "stagger": 75, "poise": 10.0, "ai": "x_kicker", "look": "gunter_bald"},
	"gang_blade": {"hp": 260.0, "posture": 50.0, "walk": 1.9, "run": 4.0, "stagger": 70, "ai": "haseong_guard", "look": "haseong_guard"},
	# 백도찬의 대역(선창 창고 — 흰 셔츠 · 사각 안경 · 곡선 단검 p1:091/005): 1층은 격투가(pro_fighter), 방 표 덧붙임 role 로 이 칸,
	# 그림은 백도찬을 빌린다(닮은 사람)
	"decoy": {"hp": 900.0, "posture": 160.0, "walk": 2.0, "run": 4.4, "stagger": 75, "poise": 16.0, "finisher_cap": 0.08, "ai": "x_blade",
		"look": "baek", "dmg_k": 0.7},
	"komodo": {"hp": 200.0, "posture": 220.0, "walk": 2.1, "run": 4.6, "stagger": 75, "poise": 28.0, "finisher_cap": 0.06, "ai": "x_blade",
		"look": "komodo", "phase2_at": 0.5, "dmg_k": 0.6},
	# 남궁혁: 2장 따돌리기 방과 같은 너클(namgung 프로필 — 너클 카운터 기절). 여기서는 쓰러뜨린다(피우진 승 — p1:111)
	"namgunghyuk": {"hp": 230.0, "posture": 200.0, "walk": 2.0, "run": 4.4, "stagger": 80, "poise": 30.0, "finisher_cap": 0.06, "ai": "namgung",
		"look": "namgunghyuk", "dmg_k": 0.4},
}

const ROOMS := [
	{"id": "ship_deck", "theme": "ship_deck", "bounds": Rect2(-7.0, -2.6, 14.0, 5.2),
		"heroes": [Vector2(-5.0, -0.8), Vector2(-5.4, 0.6), Vector2(-4.6, 1.8)],
		"allies": [["medvedi", Vector2(-4.0, -1.8)], ["ratel", Vector2(-3.8, 1.0)]],
		"enemies": [["elite_guard", Vector2(-0.6, -1.8), {"name": "스케일 조끼 경비"}], ["elite_guard", Vector2(0.2, 1.8), {"name": "스케일 조끼 경비"}],
			["pro_fighter", Vector2(1.4, -0.4), {"name": "스케일 복면"}], ["gang_blade", Vector2(2.6, 1.6), {"name": "스케일 복면 칼잡이"}],
			["pro_fighter", Vector2(3.6, -1.4), {"name": "스케일 복면"}], ["elite_guard", Vector2(4.6, 0.6), {"name": "선실 경비 총잡이"}]]},
	{"id": "ship_cargo", "theme": "ship_hold", "bounds": Rect2(-5.4, -2.2, 10.8, 4.4), "cast": ["kimshin"],
		"heroes": [Vector2(-3.6, 0.2)], "allies": [],
		"enemies": [["pro_fighter", Vector2(2.4, 0.0), {"role": "decoy", "look": "baek", "name": "안경 남자(대역)"}]], "boss": "pro_fighter"},
	{"id": "ship_bridge", "theme": "ship_bridge", "bounds": Rect2(-5.4, -2.2, 10.8, 4.4), "cast": ["jintae"],
		"heroes": [Vector2(-3.6, 0.2)], "allies": [],
		"enemies": [["elite_guard", Vector2(0.4, -1.4), {"name": "기둥 뒤 조끼 부하"}], ["elite_guard", Vector2(1.0, 1.4), {"name": "콘솔 뒤 총잡이"}],
			["komodo", Vector2(2.6, 0.0)]], "boss": "komodo"},
	{"id": "ship_hold", "theme": "ship_hold", "bounds": Rect2(-6.0, -2.4, 12.0, 4.8), "cast": ["woojin"],
		"heroes": [Vector2(-3.8, 0.2)], "allies": [],
		"enemies": [["namgunghyuk", Vector2(2.4, 0.0)]], "boss": "namgunghyuk"},
	{"id": "ship_end", "theme": "ship_deck", "bounds": Rect2(-5.0, -2.4, 10.0, 4.8), "cast": ["kimshin"],
		"heroes": [Vector2(-1.6, 0.4)], "allies": [], "enemies": [], "boss": "", "end": true},
]

const INTRO_T := 75
const CLEAR_T := 150
const END_T := 300
const HEAL_ON_CLEAR := 0.25
const MAX_ATTACKERS := 2
