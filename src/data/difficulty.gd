extends RefCounted
## 난이도 표(3층 · 이 판 소유 — 사용자 2026-11-09 "난이도를 쉬움, 보통, 어려움, 헬난이도 정도를 수정할 수 있으면").
## 적(team 1)에게만 배율을 건다 — 조작 인물 · 아군 · 등급 규칙(castle_common)은 그대로:
##   foe_hp 적 최대 체력 · foe_dmg 적이 주는 피해(dmg_k) · foe_cd 적이 공격 패턴 사이에 쉬는 시간(작을수록 몰아친다)
## 보통은 늘 배율 1 — 장 표 수치(방별 봇 판 시드 4)가 보통 기준이다. 판(stage · duel)을 만들 때 opts.difficulty 로 받고
## 리플레이 opts 에도 남는다(같은 기록이면 같은 판). 고른 값은 세이브 "difficulty"(src/data/save.gd).

const IDS := ["easy", "normal", "hard", "hell"]
const DEFAULT := "normal"
const LEVELS := {
	"easy": {"name": "쉬움", "foe_hp": 0.7, "foe_dmg": 0.6, "foe_cd": 1.35},
	"normal": {"name": "보통", "foe_hp": 1.0, "foe_dmg": 1.0, "foe_cd": 1.0},
	"hard": {"name": "어려움", "foe_hp": 1.3, "foe_dmg": 1.4, "foe_cd": 0.85},
	"hell": {"name": "헬", "foe_hp": 1.7, "foe_dmg": 2.0, "foe_cd": 0.7},
}


static func of(id) -> Dictionary:
	return LEVELS.get(str(id), LEVELS[DEFAULT])


static func valid(id) -> String:
	return str(id) if LEVELS.has(str(id)) else DEFAULT


## 버튼: 쉬움 → 보통 → 어려움 → 헬 → 쉬움 (모르는 값 다음은 보통)
static func next(id) -> String:
	var i := IDS.find(str(id))
	return IDS[(i + 1) % IDS.size()] if i >= 0 else DEFAULT


static func label(id) -> String:
	return str(of(id)["name"])


## 적 한 사람에 배율을 건다(체력은 꽉 찬 채로). ai 는 EnemyAI · BossAI(cd_k 칸) 또는 null
static func apply_foe(f, ai, id) -> void:
	var k := of(id)
	f.hp_max *= float(k["foe_hp"])
	f.hp = f.hp_max
	f.dmg_k *= float(k["foe_dmg"])
	if ai != null:
		ai.cd_k = float(k["foe_cd"])
