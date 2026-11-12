extends RefCounted
## 1장 범죄도시 회암 장 표 — 회암시(1부 p1:003-020). 방 표 · 인물 역할(3층) · 장 시점. 표의 칸은 hotel.gd 와 같다
## (src/combat/stage.gd 가 장 id ch1 로 읽는다 — src/data/campaign.gd). 범위: 김신이 싸우는 주요 전투 + 대사(사용자 추천안 '주요 전투 +
## 대사만' — history 2026-11-06 S5 묶음 1). 보스 둘 = 김대건 · 윤덕수(기획서 02 3절 · M2 '보스 2').
## 스테이지(2026-11-10 사용자 — 부제 '회암시 새 주인', "공사장 골목(김혁주). 차수민 폐차장 1(김성준). 2(김대건). 회암시 거리(강만재 + 윤덕수)"):
##   1 공사장 골목(fight:kimhyeokju p1:003) — 서진태가 DS 정장들을 먼저 눕혀 두었고, 김혁주(DS 부장 서열 4위 · 잭나이프 두 자루)가
##     부하와 막아선다. 끝 = 두 번째(진짜) 베기 전에 파고든 얼굴 주먹 한 방(003/049-050). 서진태는 아군(봇)
##   2 차수민 폐차장 1 · 밤(fight:pyechajang p1:008-010 — 부진폐차장은 차수민의 폐차장) — DS 습격조(방망이 · 쇠파이프 · 복면)와 약에 취한
##     김성준(칼). 끝 = 칼 쥔 손목 꺾기
##   3 차수민 폐차장 2 · 노을(fight:kimdaegeon_pyechajang p1:014-016) — 김대건 일대일(부하를 물림). 하이킥 · 뒷발 돌려차기 · 베어허그 태클,
##     '피떡이 돼야 시동'(015/042-048)으로 2차. 쓰러뜨리면 김신이 회유하고(원작 대사 016/016-020 · 017/029) 김대건이 합류(017/081-082 —
##     triggers down → say · recruit)
##   4 회암시 거리 낮(fight:jintae_ds · fight:yundeoksu p1:018-020) — 김신(조작) · 서진태 · 김대건(합류 — 아군) 대 DS 정장 무리와 강만재가
##     먼저. 강만재가 쓰러지면 윤덕수가 나서서 마지막 보스(triggers down:gangmanjae → spawn). 윤덕수를 쓰러뜨리면 끝
##     (끝 = 넘어뜨려 아스팔트에 처박기 020/024-030 → '알아서 찌그러져라' 020/045-046)
##   5 거리(끝) — DS 가 무너졌다(beat:yundeoksu) · 1장 끝
## 편(castle_common canon 2026-11-10 다시 봄): 김신 · 서진태(이스크라 출신 — 김신의 오른팔) 대 DS씨큐리티(윤덕수 · 김혁주 · 강만재 · 김성준).
## 김대건은 1 ~ 3 방까지 DS(이사) — 3 방에서 진 뒤 부진파로 넘어와(characters 김대건 faction bujinpa 018) 4 방에선 김신 편.
## 조작: 방마다 김신 한 사람(방 표 cast · 교대 없음). 서진태는 1 · 4 방 아군(봇).
## 원작과 다른 점(게임으로 옮기며): 김성준은 원작에서 김신과 잠깐이지만 방의 강적으로 둔다. 원작에서 강만재는 서진태가 베었다(019/031-036) —
## 사용자 지시대로 한 방(김신 조작)에 강만재 → 윤덕수로 잇는다. 강창석 · 김대건(fight:gangchangseok_kimdaegeon2) · 피우진 대 DS 무리는 대사로만.
## 난이도(사용자 2026-11-10 "보스가 김신보다 약한대도 강하게 표현될 때가 있음"): 1장 적은 모두 김신(내성 중위)보다 아래(김혁주 · 김성준 ·
##   강만재 네임드, 김대건 경호대급, 윤덕수 전국구) — 보스 dmg_k ≤ 1(2차 배율을 더해도 1 안팎) · 봇 8판 8/8 · 1분 안쪽. 무리(건달급)는 등급 차
##   한 방. 3층 값은 이 판 소유 — 방별 봇 판(tests/sim_rooms.gd ch1). 능력치 배율은 addendum.derive.

const EVENT := "beat:yundeoksu"      # 시점: 윤덕수를 이기기 전(김신 내성 중위 · 처음 기술)
const PERIOD := "p1"

## 원작 근거(castle_common canon — 장 데이터 검사 tests/unit/test_campaign.gd 가 id 가 canon 에 있는지 본다): 방 id →
## fight(canon fights.json 대결 id, 싸움 없는 방은 "") · place(canon locations.json 장소 id)
const CANON := {
	"site_alley": {"fight": "fight:kimhyeokju", "place": "hoeamsi"},
	"junkyard": {"fight": "fight:pyechajang", "place": "bujinpyechajang"},
	"junkyard_dusk": {"fight": "fight:kimdaegeon_pyechajang", "place": "bujinpyechajang"},
	"street": {"fight": "fight:yundeoksu", "place": "hoeamsi"},
	"street_end": {"fight": "", "place": "hoeamsi"},
}

const HEROES := ["kimshin"]             # 방마다 김신 한 사람(교대 없음) — 서진태 · 김대건(합류)은 아군 봇
const LINES := "ch1"
const CROWD_ID := "ds_member"

## 인물 역할(3층) — 칸 뜻은 hotel.gd ROLES. 적 줄에 moveset 이 있으면 recruit 때 아군 봇이 된다(김대건 — stage._recruit)
const ROLES := {
	"kimshin": {"hp": 200.0, "posture": 60.0, "walk": 2.1, "run": 4.6, "stagger": 50, "look": "kim_bare",
		"moveset": {"combo": "kf_jab", "dash": "kf_dash", "counter": "kf_counter", "finisher": "kf_finisher"}},
	"jintae": {"hp": 180.0, "posture": 60.0, "walk": 2.2, "run": 4.8, "stagger": 50, "look": "jintae",
		"moveset": {"combo": "j_jab", "dash": "j_dash", "finisher": "j_finisher"}},
	"ds_member": {"hp": 60.0, "posture": 30.0, "walk": 1.8, "run": 3.8, "stagger": 70, "poise": 0.0, "ai": "thug",
		"look": "ds_suit"},
	"ds_raider": {"hp": 50.0, "posture": 30.0, "walk": 1.8, "run": 3.9, "stagger": 70, "poise": 0.0, "ai": "thug_pipe",
		"look": "ds_raider"},
	"kimhyeokju": {"hp": 380.0, "posture": 160.0, "walk": 2.0, "run": 4.3, "stagger": 70, "poise": 22.0, "finisher_cap": 0.2, "ai": "hyeokju",
		"look": "kimhyeokju", "dmg_k": 0.8},
	"kimseongjun": {"hp": 360.0, "posture": 160.0, "walk": 1.9, "run": 4.2, "stagger": 70, "poise": 22.0, "finisher_cap": 0.2, "ai": "seongjun",
		"look": "kimseongjun", "dmg_k": 0.8},
	"kimdaegeon": {"hp": 700.0, "posture": 300.0, "walk": 1.95, "run": 4.2, "stagger": 75, "poise": 26.0, "finisher_cap": 0.12, "ai": "daegeon",
		"look": "kimdaegeon", "phase2_at": 0.5, "dmg_k": 0.8,
		"moveset": {"combo": "dk_jab", "dash": "dk_dash", "finisher": "dk_finisher"}},     # 합류하면 아군 봇(4장 김대건 동작)
	# 4 방 아군 김대건(합류한 뒤 — 방 표 role): 체력은 아군 몫
	"kimdaegeon_ally": {"hp": 320.0, "posture": 90.0, "walk": 2.1, "run": 4.6, "stagger": 50, "look": "kimdaegeon",
		"moveset": {"combo": "dk_jab", "dash": "dk_dash", "finisher": "dk_finisher"}},
	"gangmanjae": {"hp": 420.0, "posture": 200.0, "walk": 1.7, "run": 3.7, "stagger": 75, "poise": 24.0, "finisher_cap": 0.2, "ai": "manjae",
		"look": "gangmanjae", "dmg_k": 0.8},
	# 윤덕수가 나설 때 함께(2026-11-12 사용자 8번 — '강창석(악귀)와 DS 시큐리티 5명' · 다른 캐릭터들 근처에): 서진태 · 김대건이 맡는다
	"gangchangseok": {"hp": 420.0, "posture": 160.0, "walk": 1.9, "run": 4.1, "stagger": 75, "poise": 18.0, "finisher_cap": 0.2, "ai": "changseok",
		"look": "gangchangseok", "dmg_k": 0.8},
	"yundeoksu": {"hp": 900.0, "posture": 380.0, "walk": 1.85, "run": 4.0, "stagger": 80, "poise": 28.0, "finisher_cap": 0.1, "ai": "deoksu",
		"look": "yundeoksu", "phase2_at": 0.5, "dmg_k": 0.85},
}

## 방 — 칸 뜻은 hotel.gd ROOMS · 규칙 칸(triggers)은 src/combat/stage.gd 머리. enemies 셋째 칸(덧붙임): look · ai · name · hp_k · role
const ROOMS := [
	{"id": "site_alley", "theme": "site_alley", "bounds": Rect2(-6.6, -2.2, 13.2, 4.4), "cast": ["kimshin"],
		"heroes": [Vector2(-4.6, 0.3)], "allies": [["jintae", Vector2(-3.6, -1.0)]],
		"enemies": [["ds_member", Vector2(1.4, -1.2)], ["ds_member", Vector2(2.2, 1.2)], ["ds_member", Vector2(3.4, -0.2)],
			["ds_member", Vector2(4.6, 1.4)], ["kimhyeokju", Vector2(4.6, -1.0)]], "boss": "kimhyeokju"},
	{"id": "junkyard", "theme": "junkyard_night", "bounds": Rect2(-6.8, -3.0, 13.6, 6.0), "cast": ["kimshin"],
		"heroes": [Vector2(-4.8, 0.3)], "allies": [],
		"enemies": [["ds_raider", Vector2(1.2, -1.8)], ["ds_raider", Vector2(1.8, 1.6)], ["ds_raider", Vector2(3.0, -0.4)],
			["ds_raider", Vector2(4.4, 2.0)], ["ds_raider", Vector2(4.6, -2.0)], ["kimseongjun", Vector2(4.2, 0.4)]],
		"boss": "kimseongjun"},
	# 김대건을 쓰러뜨리면: 아군으로 일어서고(recruit) 회유(원작 대사 — 모두 멈춤 hold) → 합류 대사 → 대사가 끝나면 방을 넘는다
	{"id": "junkyard_dusk", "theme": "junkyard_dusk", "bounds": Rect2(-6.0, -2.6, 12.0, 5.2), "cast": ["kimshin"],
		"heroes": [Vector2(-3.6, 0.2)], "allies": [],
		"enemies": [["kimdaegeon", Vector2(2.4, 0.0)]], "boss": "kimdaegeon",
		"triggers": [                                   # 원작도 일어선 김대건과 말을 나눈다(016/015-020) — 일어서며 회유, 이어 합류
			{"when": "down:kimdaegeon", "recruit": "kimdaegeon", "say": "persuade", "hold": true},
			{"when": "after:0:0", "say": "join", "clear": true}]},
	# 회암시 거리: 강만재가 먼저(무리와) → 강만재가 쓰러지면 윤덕수가 나선다(마지막 보스) → 윤덕수를 쓰러뜨리면 끝
	# 회암시 거리(2026-11-12 사용자 8번 — 맵을 키우고 18 × 7m, 윤덕수가 나설 때 강창석(악귀) · DS 시큐리티 5명을 더: 윤덕수는 김신 곁에,
	# 강창석 · DS 는 서진태 · 김대건 곁에 — 둘이 그쪽과 싸우고 김신은 윤덕수에게. spawn 덧붙임 near · off — stage._spawn_at)
	{"id": "street", "theme": "hoeam_street", "bounds": Rect2(-9.0, -3.5, 18.0, 7.0), "cast": ["kimshin"],
		"heroes": [Vector2(-6.6, 0.3)],
		"allies": [["jintae", Vector2(-7.2, -1.6)], ["kimdaegeon", Vector2(-7.2, 1.8), {"role": "kimdaegeon_ally"}]],
		"enemies": [["ds_member", Vector2(-0.4, -2.2)], ["ds_member", Vector2(0.6, 1.8)], ["ds_member", Vector2(2.0, -0.4)],
			["ds_member", Vector2(3.2, 2.4)], ["ds_member", Vector2(4.4, -2.6)], ["ds_member", Vector2(5.6, 1.0)],
			["ds_member", Vector2(6.6, -1.2)], ["gangmanjae", Vector2(4.8, 0.4)]],
		"boss": "gangmanjae",
		"triggers": [
			{"when": "down:gangmanjae", "boss": "yundeoksu", "say": "deoksu",
				"spawn": [["yundeoksu", Vector2(6.4, -0.6), {"near": "kimshin", "off": Vector2(2.2, 0.0)}],
					["gangchangseok", Vector2(5.0, -2.0), {"near": "jintae", "off": Vector2(1.8, 0.2), "name": "강창석(악귀)"}],
					["ds_member", Vector2(5.0, 2.0), {"near": "jintae", "off": Vector2(1.6, -1.2), "name": "DS 시큐리티"}],
					["ds_member", Vector2(5.0, 2.0), {"near": "jintae", "off": Vector2(-1.4, 1.2), "name": "DS 시큐리티"}],
					["ds_member", Vector2(5.0, 2.0), {"near": "kimdaegeon", "off": Vector2(1.6, 0.8), "name": "DS 시큐리티"}],
					["ds_member", Vector2(5.0, 2.0), {"near": "kimdaegeon", "off": Vector2(1.4, -1.0), "name": "DS 시큐리티"}],
					["ds_member", Vector2(5.0, 2.0), {"near": "kimdaegeon", "off": Vector2(-1.6, 0.6), "name": "DS 시큐리티"}]]}]},
	{"id": "street_end", "theme": "hoeam_street", "bounds": Rect2(-5.0, -2.4, 10.0, 4.8), "cast": ["kimshin"],
		"heroes": [Vector2(-1.6, 0.4)], "allies": [], "enemies": [], "boss": "", "end": true},
]

const INTRO_T := 75
const CLEAR_T := 150
const END_T := 360
const HEAL_ON_CLEAR := 0.2
const MAX_ATTACKERS := 2
