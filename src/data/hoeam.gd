extends RefCounted
## 1장 범죄도시 회암 장 표 — 회암시(1부 p1:003-020). 방 표 · 인물 역할(3층) · 장 시점. 표의 칸은 hotel.gd 와 같다
## (src/combat/stage.gd 가 장 id ch1 로 읽는다 — src/data/campaign.gd). 범위: 김신이 싸우는 주요 전투 + 대사(사용자 추천안 '주요 전투 +
## 대사만' — history 2026-11-06 S5 묶음 1). 보스 둘 = 김대건 · 윤덕수(기획서 02 3절 · M2 '보스 2').
## 흐름(castle_common canon fights — 화/컷):
##   1 공사장 골목(fight:kimhyeokju p1:003) — 서진태가 DS 정장들을 먼저 눕혀 두었고, 김혁주(DS 부장 서열 4위 · 잭나이프 두 자루)가
##     부하와 막아선다. 끝 = 두 번째(진짜) 베기 전에 파고든 얼굴 주먹 한 방(003/049-050)
##   2 부진폐차장 밤(fight:pyechajang p1:008-010) — DS 습격조(방망이 · 쇠파이프 · 복면)와 약에 취한 김성준(칼). 끝 = 칼 쥔 손목 꺾기
##   3 부진폐차장 노을(fight:kimdaegeon_pyechajang p1:014-016) — 김대건 일대일(부하를 물림). 하이킥 · 뒷발 돌려차기 · 베어허그 태클,
##     한 번 쓰러진 뒤 '피떡이 돼야 시동'(015/042-048)으로 2차. 끝 = 마지막 돌진에 맞춘 한 방(016/009-011)
##   4 회암시 거리 낮(fight:jintae_ds · fight:yundeoksu p1:018-019) — DS 정장 무리 난전 · 강만재(흉터 거구)
##   5 회암시 거리 중앙선(fight:yundeoksu p1:019-020) — 윤덕수. 큰 훅 · 얼굴 잡아 메치기 · 스트레이트, 옆구리를 맞은 뒤 2차.
##     끝 = 넘어뜨려 아스팔트에 처박기(020/024-030) → '알아서 찌그러져라'(020/045-046)
##   6 거리(끝) — DS 가 무너졌다(beat:yundeoksu)
## 원작과 다른 점(게임으로 옮기며): 김성준 · 강만재는 원작에서 김신과 맞붙지 않거나(강만재 — 서진태 · 윤덕수와) 잠깐(김성준)이지만 방의
## 강적으로 둔다. 서진태는 1 · 4 방의 아군(봇). 강창석 · 김혁주의 거리 싸움(피우진 · 김대건 몫)은 대사로만.
## 3층 값은 이 판 소유 — 봇 판 · 판 길이로 맞춘다(tests/sim_stage.gd). 능력치 배율은 addendum.derive.

const EVENT := "beat:yundeoksu"      # 시점: 윤덕수를 이기기 전(김신 내성 중위 · 처음 기술)
const PERIOD := "p1"

## 원작 근거(castle_common canon — 장 데이터 검사 tests/unit/test_campaign.gd 가 id 가 canon 에 있는지 본다): 방 id →
## fight(canon fights.json 대결 id, 싸움 없는 방은 "") · place(canon locations.json 장소 id)
const CANON := {
	"site_alley": {"fight": "fight:kimhyeokju", "place": "hoeamsi"},
	"junkyard": {"fight": "fight:pyechajang", "place": "bujinpyechajang"},
	"junkyard_dusk": {"fight": "fight:kimdaegeon_pyechajang", "place": "bujinpyechajang"},
	"street": {"fight": "fight:jintae_ds", "place": "hoeamsi"},
	"street_center": {"fight": "fight:yundeoksu", "place": "hoeamsi"},
	"street_end": {"fight": "", "place": "hoeamsi"},
}

const HEROES := ["kimshin"]          # 김신 혼자 — 교대 없음(서진태는 아군 봇)
const LINES := "ch1"
const CROWD_ID := "ds_member"

## 인물 역할(3층) — 칸 뜻은 hotel.gd ROLES
const ROLES := {
	"kimshin": {"hp": 200.0, "posture": 60.0, "walk": 2.1, "run": 4.6, "stagger": 50, "look": "kim_bare",
		"moveset": {"combo": "kf_jab", "dash": "kf_dash", "counter": "kf_counter", "finisher": "kf_finisher"}},
	"jintae": {"hp": 180.0, "posture": 60.0, "walk": 2.2, "run": 4.8, "stagger": 50, "look": "jintae",
		"moveset": {"combo": "j_jab", "dash": "j_dash", "finisher": "j_finisher"}},
	"ds_member": {"hp": 240.0, "posture": 45.0, "walk": 1.8, "run": 3.8, "stagger": 70, "poise": 0.0, "ai": "thug",
		"look": "ds_suit"},
	"ds_raider": {"hp": 160.0, "posture": 45.0, "walk": 1.8, "run": 3.9, "stagger": 70, "poise": 0.0, "ai": "thug_pipe",
		"look": "ds_raider"},
	"kimhyeokju": {"hp": 1200.0, "posture": 200.0, "walk": 2.0, "run": 4.3, "stagger": 70, "poise": 28.0, "finisher_cap": 0.12, "ai": "hyeokju",
		"look": "kimhyeokju"},
	"kimseongjun": {"hp": 640.0, "posture": 220.0, "walk": 1.9, "run": 4.2, "stagger": 70, "poise": 28.0, "finisher_cap": 0.12, "ai": "seongjun",
		"look": "kimseongjun"},
	"kimdaegeon": {"hp": 1800.0, "posture": 480.0, "walk": 1.95, "run": 4.2, "stagger": 75, "poise": 30.0, "finisher_cap": 0.06, "ai": "daegeon",
		"look": "kimdaegeon", "phase2_at": 0.5, "dmg_k": 2.6},
	"gangmanjae": {"hp": 800.0, "posture": 260.0, "walk": 1.7, "run": 3.7, "stagger": 75, "poise": 30.0, "finisher_cap": 0.12, "ai": "manjae",
		"look": "gangmanjae"},
	"yundeoksu": {"hp": 2000.0, "posture": 600.0, "walk": 1.85, "run": 4.0, "stagger": 80, "poise": 34.0, "finisher_cap": 0.06, "ai": "deoksu",
		"look": "yundeoksu", "phase2_at": 0.5, "dmg_k": 3.2},
}

## 방 — 칸 뜻은 hotel.gd ROOMS. enemies 셋째 칸(덧붙임): look · ai · name · hp_k (stage.gd _npc)
const ROOMS := [
	{"id": "site_alley", "theme": "site_alley", "bounds": Rect2(-6.6, -2.2, 13.2, 4.4),
		"heroes": [Vector2(-4.6, 0.3)], "allies": [["jintae", Vector2(-3.6, -1.0)]],
		"enemies": [["ds_member", Vector2(1.4, -1.2)], ["ds_member", Vector2(2.2, 1.2)], ["ds_member", Vector2(3.4, -0.2)],
			["ds_member", Vector2(4.6, 1.4)], ["kimhyeokju", Vector2(4.6, -1.0)]], "boss": "kimhyeokju"},
	{"id": "junkyard", "theme": "junkyard_night", "bounds": Rect2(-6.8, -3.0, 13.6, 6.0),
		"heroes": [Vector2(-4.8, 0.3)], "allies": [],
		"enemies": [["ds_raider", Vector2(1.2, -1.8)], ["ds_raider", Vector2(1.8, 1.6)], ["ds_raider", Vector2(3.0, -0.4)],
			["ds_raider", Vector2(4.4, 2.0)], ["ds_raider", Vector2(4.6, -2.0)], ["kimseongjun", Vector2(4.2, 0.4)]],
		"boss": "kimseongjun"},
	{"id": "junkyard_dusk", "theme": "junkyard_dusk", "bounds": Rect2(-6.0, -2.6, 12.0, 5.2),
		"heroes": [Vector2(-3.6, 0.2)], "allies": [],
		"enemies": [["kimdaegeon", Vector2(2.4, 0.0)]], "boss": "kimdaegeon"},
	{"id": "street", "theme": "hoeam_street", "bounds": Rect2(-7.0, -3.0, 14.0, 6.0),
		"heroes": [Vector2(-5.0, 0.3)], "allies": [["jintae", Vector2(-4.2, -1.2)]],
		"enemies": [["ds_member", Vector2(0.8, -1.8)], ["ds_member", Vector2(1.6, 1.4)], ["ds_member", Vector2(2.8, -0.2)],
			["ds_member", Vector2(3.6, 2.0)], ["ds_member", Vector2(4.6, -1.6)], ["gangmanjae", Vector2(4.4, 0.6)]],
		"boss": "gangmanjae"},
	{"id": "street_center", "theme": "hoeam_street", "bounds": Rect2(-6.0, -2.8, 12.0, 5.6),
		"heroes": [Vector2(-3.6, 0.2)], "allies": [],
		"enemies": [["yundeoksu", Vector2(2.6, 0.0)]], "boss": "yundeoksu"},
	{"id": "street_end", "theme": "hoeam_street", "bounds": Rect2(-5.0, -2.4, 10.0, 4.8),
		"heroes": [Vector2(-1.6, 0.4)], "allies": [], "enemies": [], "boss": "", "end": true},
]

const INTRO_T := 75
const CLEAR_T := 150
const END_T := 360
const HEAL_ON_CLEAR := 0.2
const MAX_ATTACKERS := 2
