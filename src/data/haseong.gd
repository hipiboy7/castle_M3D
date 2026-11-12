extends RefCounted
## 2장 하성 본사 장 표 — 하성그룹 본사 습격(1부 p1:022-033). 방 표 · 인물 역할(3층) · 장 시점. 칸은 hotel.gd · hoeam.gd 와 같다
## (src/combat/stage.gd 가 장 id ch2 로 읽는다 — src/data/campaign.gd). 범위: 주요 전투 + 대사(사용자 "추천대로" 2026-11-06).
## 조작: 김신 / 서진태 — 방마다 한 사람(방 표 cast — 교대 없음). 원작이 로비(서진태 · 이슬 · 청년회)와 위층(김신)을 번갈아 보여 준다.
## 스테이지(2026-11-10 사용자 — 부제 '김신과 하성'):
##   1 공사장 밤(fight:iseul p1:022/055-066) — 남구청년회 이슬과 한 합. 끝 = 김신의 한 방 → 청년회 19명 합류
##   2 하성 본사 1층(fight:haseong_lobby · fight:jintae_hwangbomincheol p1:024-028) — 서진태(조작) · 이슬 · 청년회 3명(인수 + 둘) · 부진파 2명 대
##     하성 인력 30명(세 무리 12 · 10 · 8 — 2026-11-12 사용자 '하성 캐릭터 숫자 2배로' · triggers down) + 황보민철(셋째 무리와 함께, 단검 둘)
##   3 위층 복도(fight:namgunghyuk p1:024/105-156) — 김신 · 피우진 · 김대건 대 남궁혁 + 하성 특별 경호대 10명(5 + 앞쪽 5). 피우진 · 김대건이
##     쓰러지기 전에(protect) 남궁혁을 지나 긴 복도 끝 계단으로(escape — '김신, 먼저 올라가라' 024/126)
##   4 대표실 앞 복도(fight:gyeonghotim p1:025-026 · 029) — 김신 대 오지인 + 특별 경호대 20명(10 + 10). 오지인은 yield_at 에서 비켜선다
##   5 대표실 · 불 꺼짐(fight:kimjaehoon_daepyosil p1:029) — 강창석 · 김재훈을 한 방씩(등급 차 한 방 — 방 보스 없음) → 김신 '입 닫고, 달게 받아라'
##   6 위층 복도(fight:kimshin_namgunghyuk p1:029-030) — 남궁혁. 정면 승부 없이 피해서 10초 안에 긴 복도 끝으로(escape — 030/013-024)
##   7 부진폐차장 밤(fight:kimshin_sintaejin p1:031-033) — 신태진(쌍칼)을 때려눕히고 멘트 → 2장 끝(끝 방)
## 편(castle_common canon 2026-11-10 다시 봄): 김신 · 서진태 · 이슬(남구청년회 — 1 방 한 합 뒤 합류) · 피우진 · 김대건(부진파) 대 하성(김재훈 ·
## 오지인 · 황보민철 · 강창석 — characters faction haseong 022-024) · 남궁혁(선진 — 백도찬의 오른팔) · 신태진(하성의 칼 — 김재훈 지시로 김신을 쫓음).
## 원작과 다른 점: 강창석은 원작에서 중간에 달아난다(029/039-043) — 사용자 지시대로 방의 적(한 방). 황보민철전은 원작에서 우측 빌딩 중앙계단 —
## 사용자 지시대로 1층 싸움에 묶었다. 부진파 둘은 이름 없는 엑스트라(외형 ds_suit · 이름 '부진파' — 원작 김대건의 식구들 017/073-075).
## 신태진 고속도로 추격(fight:sintaejin_gosokdoro) · 피우진 대련(fight:woojin_daeryeon)은 대사로만.
## 난이도(사용자 2026-11-10 "보스가 김신보다 약한대도 강하게"): 2장 적은 모두 조작 인물보다 아래(신태진 준10강 · 남궁혁 외성 하위 <
##   김신 내성 중위, 황보민철 전국구 < 서진태 외성 하위) — 보스 dmg_k ≤ 1(2차 배율을 더해도 1 안팎) · 봇 8판 8/8 · 1분 안쪽, 무리는 1 ~ 2대.
## 3층 값은 이 판 소유 — 방별 봇 판(tests/sim_rooms.gd ch2). 능력치 배율은 addendum.derive.

const EVENT := "beat:yundeoksu"      # 시점: 1장 뒤 · 구스타프 앞 — 김신 내성 중위(진행 사건이 2장 안에 없다)
const PERIOD := "p1"

## 원작 근거(장 데이터 검사 tests/unit/test_campaign.gd 가 id 가 canon 에 있는지 본다): 방 id → fight · place
const CANON := {
	"site_night": {"fight": "fight:iseul", "place": "hoeamsi"},
	"lobby": {"fight": "fight:haseong_lobby", "place": "haseong_hq"},
	"upper_hall": {"fight": "fight:namgunghyuk", "place": "haseong_hq"},
	"guard_corridor": {"fight": "fight:gyeonghotim", "place": "haseong_hq"},
	"upper_corridor": {"fight": "fight:kimshin_namgunghyuk", "place": "haseong_hq"},
	"junkyard_night": {"fight": "fight:kimshin_sintaejin", "place": "bujinpyechajang"},
	"junkyard_end": {"fight": "", "place": "bujinpyechajang"},
}

const HEROES := ["kimshin", "jintae"]   # 방마다 cast 로 한 사람만 나온다

## 그 장 시점의 등급(1층 대체가 강함표의 묶음 이름 '그 아래급'을 줄 때 — 등급 사다리 값으로)
const NPCS := {
	"insu": {"rank": "조장급"},            # 강함표 '그 아래급'(강창석 · 인수 · 장호) — 경호대급 밑
}
const LINES := "ch2"
const CROWD_ID := "haseong_suit"

## 인물 역할(3층) — 칸 뜻은 hotel.gd ROLES. 김신 2장 = 역수 단검(kim_p1_blade — 경호팀을 칼로 제압 025-026),
## 공사장 이슬 한 합은 맨손(방 표 kit → kimshin_bare)
const ROLES := {
	"kimshin": {"hp": 200.0, "posture": 60.0, "walk": 2.1, "run": 4.6, "stagger": 50, "look": "kim_p1_blade",
		"moveset": {"combo": "k_slash1", "dash": "k_dash", "counter": "k_counter", "finisher": "k_finisher"}},
	"kimshin_bare": {"look": "kim_bare",
		"moveset": {"combo": "kf_jab", "dash": "kf_dash", "counter": "kf_counter", "finisher": "kf_finisher"}},
	# 서진태(2장 조작 인물 · 칼 — 028 로비 난전 · 026-027 황보민철): 칼 베기 → 되베기 → 회전 베기 · 낮은 대시 · 역수 내리꽂기.
	# 칼날 쳐내기가 없어(막기만) 반격 동작은 없다. 기술은 castle_common 진행(stage._hero — 이 시점엔 없음)
	"jintae": {"hp": 230.0, "posture": 70.0, "walk": 2.2, "run": 4.8, "stagger": 50, "look": "jintae",
		"moveset": {"combo": "jk_slash1", "dash": "jk_dash", "finisher": "jk_finisher"}},
	# 이슬: 공사장에서는 적(ai), 1층에서는 아군(moveset · 1층 skills) — 한 줄에 둘 다(stage._npc 가 편에 따라 고른다).
	# 공사장은 '한 합'(022/055-066) — 방 표 hp_k 로 짧게
	"iseul": {"hp": 600.0, "posture": 220.0, "walk": 1.8, "run": 3.9, "stagger": 75, "poise": 24.0, "finisher_cap": 0.2, "ai": "iseul",
		"look": "iseul", "dmg_k": 0.8, "moveset": {"combo": "ia_hook", "dash": "ia_dash", "finisher": "ia_finisher"}},
	# 아군(봇)
	"insu": {"hp": 240.0, "posture": 50.0, "walk": 1.9, "run": 4.0, "stagger": 70, "look": "insu",
		"moveset": {"combo": "in_1", "dash": "in_dash", "finisher": "ny_finisher"}},
	"namgu_youth": {"hp": 220.0, "posture": 45.0, "walk": 1.9, "run": 4.0, "stagger": 70, "look": "namgu_youth",
		"moveset": {"combo": "ny_jab", "dash": "ny_dash", "finisher": "ny_finisher"}},
	# 부진파(김대건의 식구들 — 이름 없는 엑스트라. 인물 id 는 ds_member(DS 조직원 외형)를 빌리고 이름은 방 표 덧붙임 name)
	"ds_member": {"hp": 220.0, "posture": 45.0, "walk": 1.9, "run": 4.0, "stagger": 70, "look": "ds_suit",
		"moveset": {"combo": "ny_jab", "dash": "ny_dash", "finisher": "ny_finisher"}},
	# 위층 복도(3 방) 아군 — 피우진 · 김대건이 남궁혁을 막는다(024/126-156). 동작은 4장과 같다
	"woojin": {"hp": 240.0, "posture": 70.0, "walk": 2.1, "run": 4.6, "stagger": 50, "look": "woojin",
		"moveset": {"combo": "w_jab", "dash": "w_dash", "finisher": "w_finisher"}},
	"kimdaegeon": {"hp": 340.0, "posture": 90.0, "walk": 2.1, "run": 4.6, "stagger": 50, "look": "kimdaegeon",
		"moveset": {"combo": "dk_jab", "dash": "dk_dash", "finisher": "dk_finisher"}},
	# 적 — 무리는 조작 인물에게 1 ~ 2대(김신에게는 등급 차 한 방)
	"haseong_suit": {"hp": 70.0, "posture": 30.0, "walk": 1.8, "run": 3.8, "stagger": 70, "poise": 0.0, "ai": "haseong_suit",
		"look": "haseong_suit"},
	"haseong_guard": {"hp": 90.0, "posture": 40.0, "walk": 1.9, "run": 4.0, "stagger": 70, "poise": 0.0, "ai": "haseong_guard",
		"look": "haseong_guard"},
	# 오지인: 원작은 맞붙지 않고 '열에 아홉은 진다'며 칼을 내려놓고 비켜선다(026/049-052) — yield_at 에서 길을 내준다(stage.gd)
	"ojiin": {"hp": 500.0, "posture": 180.0, "walk": 2.0, "run": 4.3, "stagger": 70, "poise": 22.0, "finisher_cap": 0.2, "ai": "ojiin",
		"look": "ojiin", "yield_at": 0.4, "dmg_k": 0.8},
	"hwangbomincheol": {"hp": 520.0, "posture": 220.0, "walk": 2.0, "run": 4.4, "stagger": 75, "poise": 26.0, "finisher_cap": 0.12, "ai": "mincheol",
		"look": "hwangbomincheol", "phase2_at": 0.5, "dmg_k": 0.8},
	# 대표실: 둘 다 김신의 한 방(방 보스가 없어 등급 차 한 방을 받는다 — 사용자 "김신이 둘 다 한 방에 쓰러트리고 멘트")
	"kimjaehoon": {"hp": 120.0, "posture": 40.0, "walk": 1.8, "run": 3.8, "stagger": 70, "poise": 0.0, "ai": "jaehoon",
		"look": "kimjaehoon", "dmg_k": 0.6},
	"gangchangseok": {"hp": 160.0, "posture": 60.0, "walk": 1.9, "run": 4.1, "stagger": 75, "poise": 0.0, "ai": "changseok",
		"look": "gangchangseok", "dmg_k": 0.6},
	# 남궁혁: 쓰러뜨릴 수 없다(hp_floor — 두 위층 복도 모두 따돌리기). 피우진 · 김대건(경호대급)에게는 등급 차로 세다
	"namgunghyuk": {"hp": 2400.0, "posture": 700.0, "walk": 2.0, "run": 4.4, "stagger": 80, "poise": 36.0, "finisher_cap": 0.04, "ai": "namgung",
		"look": "namgunghyuk", "hp_floor": 0.4, "dmg_k": 1.0},
	"chasumin": {"hp": 120.0, "posture": 40.0, "walk": 1.8, "run": 3.6, "stagger": 60, "look": "chasumin"},   # 2장 끝 사무실(부진폐차장 사장)
	"sintaejin": {"hp": 760.0, "posture": 360.0, "walk": 2.1, "run": 4.6, "stagger": 80, "poise": 28.0, "finisher_cap": 0.1, "ai": "sintaejin",
		"look": "sintaejin", "phase2_at": 0.5, "dmg_k": 0.8},
}

## 방 — 칸 뜻은 hotel.gd ROOMS · 규칙 칸(triggers · protect · escape)은 src/combat/stage.gd 머리. 덧붙임: cast(이 방에 나오는 조작 인물 id —
## heroes 자리도 이 차례) · kit(조작 인물 id → ROLES 의 다른 줄 — 동작 · 외형만 바꿔 낀다) · escape(따돌리기: secs 안에 exit 안에 들어서면
## 방을 넘는다 — 적은 쓰러뜨리지 않아도 된다, 못 들어서면 진다)
const ROOMS := [
	# 이슬과 대가리 정하기(2026-11-12 사용자 9번): 싸움 앞 장면(김신 + 김대건 대 이슬 + 인수 — 둘은 지켜보기만: standing) →
	# 김신 대 이슬 한 합 → 이슬이 쓰러지면 김신 · 김대건 퇴장, 이슬 · 인수 대사(lines.json ch2.scenes)
	{"id": "site_night", "theme": "site_alley", "bounds": Rect2(-5.6, -2.4, 11.2, 4.8), "cast": ["kimshin"], "kit": {"kimshin": "kimshin_bare"},
		"heroes": [Vector2(-3.0, 0.2)], "allies": [],
		"standing": [["kimdaegeon", Vector2(-4.4, -1.4), 0], ["insu", Vector2(3.6, -1.5), 1]],
		"enemies": [["iseul", Vector2(2.0, 0.0), {"hp_k": 0.5}]], "boss": "iseul",
		"scene": "iseul_deal",
		"triggers": [
			{"when": "hp:iseul:0.75", "say": [["", "이슬: 크... 이게 얼마 만인지.", ["p1:022/059"]],
				["", "이슬: 아무리 윗대가리 꼰대가 되어가도... 너 같은 놈을 보면 피가 끓는 걸 참을 수가 없단 말이야.", ["p1:022/061"]]]},
			{"when": "hp:iseul:0.4", "say": [["", "이슬: 모든 걸 내려놓고 치고 받고 싶어서!", ["p1:022/062"]], ["", "이슬: 살아있음을 실감하고 싶어서!", ["p1:022/063"]]]},
			{"when": "down:iseul", "scene": "iseul_after", "scene_end": "clear"}]},
	# 1층: 하성 인력 30명 = 12(w1) → 10(w2) → 8(w3) + 황보민철(2026-11-12 사용자 '2배로') — 앞 무리가 다 쓰러지면 오른쪽에서 다음 무리
	{"id": "lobby", "theme": "haseong_lobby", "bounds": Rect2(-7.2, -3.2, 14.4, 6.4), "cast": ["jintae"],
		"heroes": [Vector2(-5.0, 0.2)],
		"allies": [["iseul", Vector2(-4.4, -1.4)], ["insu", Vector2(-5.6, -0.6)], ["namgu_youth", Vector2(-5.4, 1.6)], ["namgu_youth", Vector2(-4.0, 2.0)],
			["ds_member", Vector2(-6.2, -2.2), {"name": "부진파"}], ["ds_member", Vector2(-6.4, 2.4), {"name": "부진파"}]],
		"enemies": [
			["haseong_suit", Vector2(0.4, -2.6), {"tag": "w1"}], ["haseong_suit", Vector2(0.4, 0.0), {"tag": "w1"}], ["haseong_suit", Vector2(0.4, 2.6), {"tag": "w1"}],
			["haseong_suit", Vector2(2.2, -1.6), {"tag": "w1"}], ["haseong_suit", Vector2(2.2, 0.5), {"tag": "w1"}], ["haseong_suit", Vector2(2.2, 2.6), {"tag": "w1"}],
			["haseong_suit", Vector2(4.0, -2.6), {"tag": "w1"}], ["haseong_suit", Vector2(4.0, 0.0), {"tag": "w1"}], ["haseong_suit", Vector2(4.0, 2.6), {"tag": "w1"}],
			["haseong_suit", Vector2(5.6, -1.6), {"tag": "w1"}], ["haseong_suit", Vector2(5.6, 0.5), {"tag": "w1"}], ["haseong_suit", Vector2(5.6, 2.6), {"tag": "w1"}]],
		"boss": "hwangbomincheol",                      # 황보민철은 셋째 무리와 함께 들어온다(trigger spawn)
		"triggers": [
			{"when": "down:w1", "say": "wave2", "spawn": [
			["haseong_suit", Vector2(6.2, -2.8), {"tag": "w2"}], ["haseong_suit", Vector2(6.2, -1.4), {"tag": "w2"}], ["haseong_suit", Vector2(6.2, 0.0), {"tag": "w2"}],
			["haseong_suit", Vector2(6.2, 1.4), {"tag": "w2"}], ["haseong_suit", Vector2(6.2, 2.8), {"tag": "w2"}], ["haseong_suit", Vector2(7.0, -2.2), {"tag": "w2"}],
			["haseong_suit", Vector2(7.0, -0.9), {"tag": "w2"}], ["haseong_suit", Vector2(7.0, 0.3), {"tag": "w2"}], ["haseong_suit", Vector2(7.0, 1.6), {"tag": "w2"}],
			["haseong_suit", Vector2(7.0, 2.8), {"tag": "w2"}]]},
			{"when": "down:w2", "say": "mincheol", "boss": "hwangbomincheol",
				"spawn": [["hwangbomincheol", Vector2(6.4, 0.0)],
			["haseong_suit", Vector2(6.2, -2.8), {"tag": "w3"}], ["haseong_suit", Vector2(6.2, -0.9), {"tag": "w3"}], ["haseong_suit", Vector2(6.2, 0.9), {"tag": "w3"}],
			["haseong_suit", Vector2(6.2, 2.8), {"tag": "w3"}], ["haseong_suit", Vector2(7.0, -2.0), {"tag": "w3"}], ["haseong_suit", Vector2(7.0, -0.4), {"tag": "w3"}],
			["haseong_suit", Vector2(7.0, 1.2), {"tag": "w3"}], ["haseong_suit", Vector2(7.0, 2.8), {"tag": "w3"}]]}]},
	# 위층 복도(긴 맵 24m): 남궁혁이 복도를 막고, 피우진 · 김대건이 붙잡는 동안 김신은 오른쪽 끝 계단으로. 둘 중 하나가 쓰러지면 진다.
	# 제한 시간 10초(2026-11-12 사용자 "2장 \"위층 복도 남궁혁\"편에서는 제한 시간을 10초 바꿔" — 전에는 40초)
	# 특별 경호대 10명 = 앞 5(g1) + 김신이 복도 가운데를 넘으면 끝 쪽 5(g2)
	{"id": "upper_hall", "theme": "haseong_upper", "bounds": Rect2(-12.0, -2.0, 24.0, 4.0), "cast": ["kimshin"],
		"heroes": [Vector2(-10.6, 0.0)], "allies": [["woojin", Vector2(-9.8, -1.2)], ["kimdaegeon", Vector2(-9.8, 1.2)]],
		"enemies": [["namgunghyuk", Vector2(-5.0, 0.0)],
			["haseong_guard", Vector2(-3.0, -1.4), {"tag": "g1"}], ["haseong_guard", Vector2(-2.4, 1.2), {"tag": "g1"}],
			["haseong_guard", Vector2(-1.2, -0.2), {"tag": "g1"}], ["haseong_guard", Vector2(0.4, 1.4), {"tag": "g1"}], ["haseong_guard", Vector2(1.2, -1.2), {"tag": "g1"}]],
		"boss": "namgunghyuk", "protect": ["woojin", "kimdaegeon"],
		"escape": {"secs": 10.0, "exit": Rect2(10.6, -2.0, 1.4, 4.0)},
		"triggers": [
			{"when": "x:2", "spawn": [["haseong_guard", Vector2(6.0, -1.4), {"tag": "g2"}], ["haseong_guard", Vector2(6.6, 1.2), {"tag": "g2"}],
				["haseong_guard", Vector2(7.6, -0.2), {"tag": "g2"}], ["haseong_guard", Vector2(8.6, 1.4), {"tag": "g2"}], ["haseong_guard", Vector2(9.2, -1.2), {"tag": "g2"}]]}]},
	# 대표실 앞 복도: 특별 경호대 20명 = 10(w1) → 10(w2) + 오지인(비켜선다 — 2026-11-12 사용자 '하성 조직원 숫자 2배로')
	# 대표실 앞 복도 → 대표실(한 방 — 2026-11-12 사용자 "'대표실 앞 복도 불 꺼짐'와 '대표실 불꺼짐'은 하나로 합치고, 대표실 앞 복도에서
	# 문을 열고 방 안으로 들어가면 대표실 불꺼짐이 이어지도록해. 스테이지로 나누지말고"): 복도 경호팀 20 · 오지인을 넘기면 길이 열리고,
	# 복도 오른쪽 끝 문틀로 걸어 들어가면 대표실(한 맵 haseong_ceo — rc.16 6번 "프롤로그 군터처럼", 옛 무대 바꿈 · ceo_door 장면은 뺐다).
	# 대표실: 강창석 · 김재훈 — 김재훈이 쓰러지면 창 장면 → 방을 깬다. 복도 자리는 맵 넓히기(MAP_K 1.4 × 1.25)를 미리 곱한 값(fixed — 대표실 넓이가 그대로이게)
	{"id": "guard_corridor", "fixed": true, "theme": "haseong_ceo", "bounds": Rect2(-9.8, -2.6, 34.8, 5.2), "cast": ["kimshin"],
		"heroes": [Vector2(-7.28, 0.0)], "allies": [],
		"enemies": [
			["haseong_guard", Vector2(0.56, -2.0), {"tag": "w1"}], ["haseong_guard", Vector2(0.56, 0.0), {"tag": "w1"}], ["haseong_guard", Vector2(0.56, 2.0), {"tag": "w1"}],
			["haseong_guard", Vector2(2.52, -1.25), {"tag": "w1"}], ["haseong_guard", Vector2(2.52, 0.375), {"tag": "w1"}], ["haseong_guard", Vector2(2.52, 2.0), {"tag": "w1"}],
			["haseong_guard", Vector2(4.48, -2.0), {"tag": "w1"}], ["haseong_guard", Vector2(4.48, 0.0), {"tag": "w1"}], ["haseong_guard", Vector2(4.48, 2.0), {"tag": "w1"}],
			["haseong_guard", Vector2(6.16, 0.0), {"tag": "w1"}],
			["ojiin", Vector2(7.28, 0.25)]], "boss": "ojiin",
		"triggers": [
			{"when": "down:w1", "say": "wave2", "spawn": [
			["haseong_guard", Vector2(8.4, -2.125), {"tag": "w2"}], ["haseong_guard", Vector2(8.4, -1.0), {"tag": "w2"}], ["haseong_guard", Vector2(8.4, 0.0), {"tag": "w2"}],
			["haseong_guard", Vector2(8.4, 1.0), {"tag": "w2"}], ["haseong_guard", Vector2(8.4, 2.125), {"tag": "w2"}], ["haseong_guard", Vector2(9.52, -1.625), {"tag": "w2"}],
			["haseong_guard", Vector2(9.52, -0.75), {"tag": "w2"}], ["haseong_guard", Vector2(9.52, 0.25), {"tag": "w2"}], ["haseong_guard", Vector2(9.52, 1.125), {"tag": "w2"}],
			["haseong_guard", Vector2(9.52, 2.125), {"tag": "w2"}]]},
			# 복도 → 대표실 한 맵(2026-11-12 사용자 rc.16 6번 "프롤로그 군터처럼 방으로 자연스럽게" — haseong3d haseong_ceo · 대표실 자리 = 옛 대표실 + CEO_OX 19.4)
			# 1 · 2: 둘째 무리 · 오지인을 다 넘기면 길이 열린다 — 오른쪽 끝 문틀로
			{"when": "down:w2", "requires": [0]},
			{"when": "down:ojiin", "requires": [1], "say": "ceo_open"},
			# 3: 문틀을 넘어 대표실로 걸어 들어서면(스테이지 넘김 · 무대 바꿈 없음)
			{"when": "x:11.6", "requires": [2], "boss": "", "say": "office",
				"spawn": [["gangchangseok", Vector2(21.0, -1.2)], ["kimjaehoon", Vector2(22.4, 0.8)]], "scene": "ceo_enter"},
			# 4: 김재훈이 쓰러지면 장면(2026-11-12 사용자 12번 — 강창석은 원작처럼 달아나고 029/039-043, 창을 쏴 깨고 끌고 가 '달게 받아라' → 창 밖으로)
			{"when": "down:kimjaehoon", "scene": "jaehoon_window", "scene_end": "clear"}]},
	# 위층 복도(긴 맵 22m) — 남궁혁을 피해 10초 안에 오른쪽 끝 문으로
	{"id": "upper_corridor", "theme": "haseong_upper", "bounds": Rect2(-11.0, -2.0, 22.0, 4.0), "cast": ["kimshin"],
		"heroes": [Vector2(-10.2, 0.0)], "allies": [],
		"enemies": [["namgunghyuk", Vector2(-2.0, 0.0)]], "boss": "namgunghyuk",
		"escape": {"secs": 10.0, "exit": Rect2(9.6, -2.0, 1.4, 4.0)}},
	{"id": "junkyard_night", "theme": "junkyard_night", "bounds": Rect2(-6.4, -2.8, 12.8, 5.6), "cast": ["kimshin"],
		"heroes": [Vector2(-3.6, 0.2)], "allies": [],
		"enemies": [["sintaejin", Vector2(2.4, 0.0)]], "boss": "sintaejin"},
	# 2장 끝 — 차수민의 부진폐차장 사무실(2026-11-12 사용자 "'부진폐차장'은 필요 없고, 사무실로 가서 김신, 김대건, 서진태, 차수민, 이슬이
	# 차수민 폐차장 내부 쇼파에 다 같이 앉아서 멘트하는걸로 해"): ㄷ 자 소파에 다섯이 앉고, 신태진은 간이침대에 눕는다(원작 p1:034 — 대화 상대).
	# 싸움 없는 장면 방 — 장면이 끝나면 2장을 깬다(scene end win)
	{"id": "junkyard_end", "fixed": true, "theme": "junkyard_office", "bounds": Rect2(-4.0, -2.0, 8.0, 4.0), "cast": ["kimshin"],
		"heroes": [Vector2(-0.6, -1.3)], "allies": [], "enemies": [], "boss": "",
		"standing": [["jintae", Vector2(2.2, 0.15), 0], ["chasumin", Vector2(0.6, -1.3), 0], ["iseul", Vector2(-2.2, -0.3), 0], ["kimdaegeon", Vector2(-2.2, 0.6), 0],
			["sintaejin", Vector2(1.2, 1.35), 0]],
		# 신태진은 탁자 앞 간이침대에 눕는다(2026-11-12 사용자 "바닥에 말고, 침대에 좀 눕혀줘" — 침대는 haseong3d _hs_junk_office, 발은 오른쪽 · 장면 첫 단계 face)
		"poses": {"kimshin": "sit", "jintae": "sit", "chasumin": "sit", "iseul": "sit", "kimdaegeon": "sit", "sintaejin": "lie_bed"},
		"scene": "office_talk"},
]

const INTRO_T := 75
const CLEAR_T := 150
const END_T := 360
const HEAL_ON_CLEAR := 0.25
const MAX_ATTACKERS := 2
