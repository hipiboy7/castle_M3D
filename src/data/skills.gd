extends RefCounted
## 이 판(3D 초안) 소유 기술 값 + 공통 데이터(src/data/common.gd)를 이 결투에 맞게 부르는 얇은 층.
## 2층(등급 · 게이지 · 비용 · 엇박 피해 · 기절 초 · 습득)은 전부 common 에서 읽는다 — 여기 숫자를 다시 적지 않는다
## (S1 공통 받기, 2026-11-04 — 전에는 castle_M `skills.py` 에서 손으로 옮긴 값이었다).
## 여기 남는 것은 3층(이 판 소유): 기술 id → 동작 표 · 처음 게이지 · 백도찬 엇박 패턴, 그리고 3D 덧붙임 기절(moves.gd stun_3d).

const Common = preload("res://src/data/common.gd")
const Addendum = preload("res://src/data/addendum.gd")

const HERO_ID := "kimshin"
const BOSS_ID := "baekdochan"
## 이 결투 = 6장 인천항 김신 대 백도찬 (progression.json). 김신의 등급 · 기술은 이 사건 앞까지의 진행으로 정한다
## (castle_M `DUELS["baekdochan"].hero_events` 와 같은 시점 — 구스타프를 이겨 내성 상위)
const DUEL_EVENT := "duel_offbeat:baekdochan"

## 기술 id(castle_common skills.json) → 이 판 동작(moves.gd). 여기 없는 기술은 이 판에 동작이 없어 고를 수 없다
## (김신 처음 기술 중 vanish_step 좌우로 사라지는 스텝 · inch 촌경 — 받은 데이터에는 있다)
const MOVE_OF := {"kickarts": "s_kick", "triple": "s_triple", "offbeat": "s_offbeat", "offbeat2": "s_offbeat2",
	"offbeat_rev": "s_offbeat_rev"}

## 처음 게이지: 초안은 4칸으로 시작해 기술을 바로 써 볼 수 있게 한다 — 본편은 1칸 (3층 · 잠정)
const KIM_START_BARS := 4.0

## 백도찬 엇박 (castle_M `castle_m/data/bosses.py` · `duels.py`, 3층 보스 패턴): 체력 90% 이하에서 처음(그때까지 체력은
## 80% 아래로 안 내려간다), 그 뒤 쿨다운마다. 첫 엇박에 맞은 김신은 체력 25% 아래로 안 내려간다(보여 주는 한 방)
const BAEK_OFFBEAT := {"first_hp": 0.9, "hold_hp": 0.8, "cd": [1200, 720], "demo_floor": 0.25, "slowmo": 40}


## 고를 수 있는 기술 한 칸 — 이름은 skills.json, 비용은 skill_cost(쓰는 사람 등급). cost -1 = 전부(all_min_bars 칸 이상일 때)
static func entry(id: String, rank: String) -> Dictionary:
	var c = Common.skill_cost(id, rank)
	return {"id": id, "name": str(Common.skill(id)["name"]), "move": MOVE_OF[id], "cost": -1.0 if c == null else float(c)}


## 아는 기술 id 목록 → 고를 수 있는 목록 (이 판에 동작이 있는 것만, 순서 그대로)
static func entries(ids: Array, rank: String) -> Array:
	var out: Array = []
	for id in ids:
		if MOVE_OF.has(id):
			out.append(entry(id, rank))
	return out


## 진행 사건 하나로 새로 얻는 기술 id — 사건 앞 · 뒤 progress 의 차이를 can_learn 으로 거르고 rank_order 순
## (duel_offbeat:baekdochan → 엇엇박 · 엇박 · 반대발 엇박)
static func learned_at(char_id: String, event: String) -> Array:
	var st := Common.stage_of(event)
	var before: Array = Common.progress(char_id, Common.events_until(st))[1]
	var after: Array = Common.progress(char_id, Common.events_until(st + 1))
	var out: Array = []
	for id in after[1]:
		if not before.has(id) and Common.can_learn(id, after[0], char_id):
			out.append(id)
	out.sort_custom(func(a, b): return int(Common.skill(a).get("rank_order", 99)) < int(Common.skill(b).get("rank_order", 99)))
	return out


## 기절 프레임 (60 = 1초): common stun_sec(각법 stun_rel_sec · 옆차기 stun_rank) 이 먼저, 없으면 3D 덧붙임 stun_3d
## [아랫급에게, 같은 급 · 윗급에게] — 엇박 계열 · 삼연타 셋째 대 기절은 3D 초안에서 먼저 시험하는 규칙(common 에 없다)
static func stun_frames(mv: Dictionary, att_rank: String, def_rank: String) -> int:
	if mv.get("stun_off", false):
		return 0
	var sid := str(mv["skill_id"])
	if sid != "" and not Addendum.SKILLS.has(sid):          # 3D 덧붙임 기술은 castle_common 에 없다 — stun_3d 만
		var sec := Common.stun_sec(sid, att_rank, def_rank)
		if sec > 0.0:
			return roundi(sec * 60.0)
	var rel: Array = mv["stun_3d"]
	if rel.is_empty():
		return 0
	return int(rel[0]) if Common.rank_gap(att_rank, def_rank) > 0 else int(rel[1])
