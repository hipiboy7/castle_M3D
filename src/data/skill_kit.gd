extends RefCounted
## 인물 기술 묶음 — 사용자 2026-11-10 "castle_common 에 있는 캐릭터별 기술을 캐릭터에 적용: 재앙 모든 기술 · 톱 7 · 내성 5 · 외성 4 ·
## 외성 미만 3". 기술 수는 그 장 시점 등급(조작 인물은 진행, 적은 장 표 NPCS · 1층)으로 정한다(castle_common 요청 30행 — 공통 규칙 후보).
## 원천 차례: ① 아는 기술(known — 이 판 동작이 있는 1층 기술: 조작 인물은 castle_common 진행, 아군 · 적은 characters.json skills)
##   ② 원작 기술 표(data/story/techniques.json — tools/bake_techniques.py 가 castle_common canon 에서 구움. conf ai 는 이름 띄우기에만).
##      castle_common skills.json 에 있는 기술은 ②로 넣지 않는다(진행 · 습득 규칙이 정한다 — 얻기 전의 엇박을 미리 쓰지 않게)
##   ③ 그래도 모자라면(적만) 원형 동작 이름으로 채운다(FILL — 원작 기술이 없는 인물)
## ②의 동작은 갈래(kind)로 고른다(3층 — KIND_MOVES, 같은 갈래가 여럿이면 차례로 다른 동작). 순수 함수(노드 없음).

const Common = preload("res://src/data/common.gd")
const Moves = preload("res://src/data/moves.gd")

const ALL := -1
const PATH := "res://data/story/techniques.json"

## 갈래 → 동작(3층). 맨손 원형이 칼 기술을 받으면 칼 동작(원작에서 칼을 든 장면이 있다는 뜻)
const KIND_MOVES := {
	"kick": ["x_roundkick", "x_spinkick", "x_flykick", "x_frontkick"],
	"grab": ["x_grab"],
	"counter": ["x_straight", "x_hook"],
	"blade": ["x_lunge", "x_cross", "x_stab", "x_cut2"],
	"gun": ["t_shot"],
	"head": ["x_shoulder"],
	"flurry": ["sj_flurry", "x_twin"],
	"evade": ["x_rush", "x_lunge"],
	"strike": ["x_hook", "x_hammer", "x_rush", "x_body"],
}
## 원작 기술이 모자란 적을 채우는 원형 동작(③ — 이름은 동작 이름). 표에 없는 원형은 맨손 큰 동작
const FILL := {
	"x_brawler": ["x_hook", "x_rush", "x_body"], "x_boxer": ["x_hook", "x_body", "x_straight"],
	"x_kicker": ["x_spinkick", "x_flykick", "x_roundkick"], "x_grappler": ["x_grab", "x_shoulder", "x_hammer"],
	"x_blade": ["x_lunge", "x_stab", "x_cut2"], "x_twin": ["x_twin", "x_cross", "x_lunge"],
	"x_axe": ["x_overhead", "x_chop", "x_swing"], "x_karambit": ["x_kara_spin", "x_kara", "x_lunge"],
	"x_master": ["x_spinkick", "x_grab", "x_rush", "x_hook", "x_roundkick", "x_body", "x_flykick"],
	"x_swordmaster": ["x_overhead", "x_cross", "x_lunge", "x_twin", "x_stab", "x_cut2", "x_swing"],
	"x_gun": ["t_shot", "x_grab", "x_rush", "x_stab"],
}
const FILL_ANY := ["x_hook", "x_rush", "x_roundkick", "x_grab", "x_spinkick", "x_body", "x_hammer"]
const CANON_COST := 1.0           # 원작 표 기술(②)의 게이지 칸 — 조작 인물이 쓸 때(3층 · 잠정)

static var _data := {}


static func count_for(rank: String) -> int:
	if rank == "재앙":
		return ALL
	if rank == "톱":
		return 7
	if rank.begins_with("내성"):
		return 5
	if rank.begins_with("외성"):
		return 4
	return 3


## 원작 기술 표 한 사람 — [{id, name, kind, conf, count}] (차례는 굽는 도구가 정했다)
static func canon(id: String) -> Array:
	if _data.is_empty():
		_data = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	return _data.get("chars", {}).get(id, [])


static func _is_common_skill(sid: String) -> bool:
	for s in Common._j("skills")["skills"]:
		if s["id"] == sid:
			return true
	return false


## 조작 인물: 아는 기술(진행 — skills.gd entries) + 원작 표, 등급 수까지
static func hero_kit(id: String, rank: String, known: Array) -> Array:
	return _kit(id, rank, known, "", true)


## 아군 · 적: 아는 기술 + 원작 표 + (모자라면) 원형 동작, 등급 수까지. ai = 적 원형(FILL).
## allowed: 그 적이 원래 쓰는 동작(enemy_ai.moves_of — 비어 있으면 거르지 않음). 원작 기술의 동작을 이 안에서 고른다 —
## 이름만 원작 기술로 띄우고 손맛(피해 · 예고)은 그 적의 원래 패턴과 같게(새 묶음이 보스를 세게 만들었다 — 방별 봇 판 2026-11-10)
static func npc_kit(id: String, rank: String, ai: String, known: Array, allowed: Array = []) -> Array:
	return _kit(id, rank, known, ai, false, allowed)


## 갈래에 맞는 동작 후보 — allowed 가 있으면 그 안에서(없으면 strike 후보 → allowed 전부)
static func _moves_for(kind: String, allowed: Array) -> Array:
	var mvs: Array = KIND_MOVES.get(kind, KIND_MOVES["strike"])
	if allowed.is_empty():
		return mvs
	for cand in [mvs, KIND_MOVES["strike"], allowed]:
		var ok: Array = cand.filter(func(m): return allowed.has(m))
		if not ok.is_empty():
			return ok
	return mvs


static func _kit(id: String, rank: String, known: Array, ai: String, hero: bool, allowed: Array = []) -> Array:
	var n := count_for(rank)
	var out: Array = []
	var names := {}
	for e in known:
		if n != ALL and out.size() >= n:
			return out
		if not allowed.is_empty() and not allowed.has(str(e["move"])):
			e = e.duplicate()                            # 원형 패턴에 없는 1층 기술 동작(11장용 구일화 박치기 등)은 이름만 두고 원형 동작으로
			e["move"] = _moves_for("strike", allowed)[0]
		out.append(e)
		names[str(e["name"])] = true
	var used := {}                                   # 갈래마다 몇 번째 동작까지 썼나
	for t in canon(id):
		if n != ALL and out.size() >= n:
			return out
		var sid := str(t["id"])
		if _is_common_skill(sid) or names.has(str(t["name"])):
			continue
		var kind := str(t["kind"])
		var mvs: Array = _moves_for(kind, allowed)
		var k := int(used.get(kind, 0))
		used[kind] = k + 1
		out.append({"id": sid, "name": str(t["name"]), "move": str(mvs[k % mvs.size()]), "cost": CANON_COST, "src": "canon"})
		names[str(t["name"])] = true
	if hero or n == ALL:
		return out
	var fill: Array = FILL.get(ai, FILL_ANY) + FILL_ANY
	if not allowed.is_empty():
		fill = fill.filter(func(m): return allowed.has(m)) + allowed
	for mv in fill:
		if out.size() >= n:
			break
		var label := str(Moves.get_move(mv)["label"])
		if names.has(label):
			continue
		out.append({"id": mv, "name": label, "move": mv, "cost": CANON_COST, "src": "fill"})
		names[label] = true
	return out
