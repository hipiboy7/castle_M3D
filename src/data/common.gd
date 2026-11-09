extends RefCounted
## 공통 데이터(1 · 2층) 읽기 + 규칙 함수 — castle_common 이 원본, 여기는 받은 사본 `res://data/common/*.json` 을 읽기만 한다.
## 받기: `py -3.12 ../castle_common/tools/sync.py castle_M3D` (받은 파일은 손으로 고치지 않는다 — verify '공통 데이터' 줄이 본다).
## 함수 이름 · 인자 · 결과는 castle_common `ref/rules.py` 와 같다(등급은 이름 문자열 — "내성 상위" 등).
## 같은지는 `tests/test_common_cases.gd` 가 castle_common `cases/rules_cases.json` 전부로 본다(실수는 1e-9).
## JSON 의 수는 전부 float 으로 읽힌다 — 칸 수 · 등급 번호는 int() 로 바꿔 쓴다.
## 뜻: castle_common `rules/등급과_게이지.md` · `rules/기술.md`. 3층(프레임 · 피해 · 체력 · 패턴)은 이 판 소유라 여기 없다.

const DIR := "res://data/common/"

static var _cache := {}


static func _j(name: String) -> Dictionary:
	if _cache.has(name):
		return _cache[name]
	var path := DIR + name + ".json"
	var text := FileAccess.get_file_as_string(path)
	var data = JSON.parse_string(text) if text != "" else null
	if not data is Dictionary:
		push_error("common: %s 을 읽지 못했다 (%s) — castle_common tools/sync.py castle_M3D 로 받는다" % [path, error_string(FileAccess.get_open_error())])
		data = {}
	_cache[name] = data
	return data


# ---- 받은 데이터 그대로 (읽기만)
static func ranks() -> Array:
	return _j("ranks")["ladder"]          # 아래 → 위 15개. 같은 파일의 strength · strength_ref 는 읽지 않는다


static func rules() -> Dictionary:
	return _j("rules")


static func gauge() -> Dictionary:
	return _j("rules")["gauge"]


static func skill(id: String) -> Dictionary:
	for s in _j("skills")["skills"]:
		if s["id"] == id:
			return s
	push_error("common: 모르는 기술 %s" % id)
	return {}


static func character(id: String) -> Dictionary:
	for c in _j("characters")["characters"]:
		if c["id"] == id:
			return c
	push_error("common: 모르는 인물 %s" % id)
	return {}


static func progression() -> Dictionary:
	return _j("progression")


# ---- 게이지 상수 (rules.json gauge · cost)
static func bar_points() -> float:
	return float(gauge()["bar_points"])


static func all_min_bars() -> int:
	return int(_j("rules")["cost"]["all_min_bars"])


static func gain_points(kind: String) -> float:
	return float(gauge()["gain"].get(kind, 0.0))


static func passive_per_frame() -> float:
	return float(gauge()["passive_per_frame"])


static func skill_hit_k() -> float:
	return float(gauge()["skill_hit_k"])


## 인물의 기술 능력치 (characters.json stats.기술, 없으면 null → gauge_rate 가 default_tech 를 쓴다)
static func tech_of(char_id: String):
	return character(char_id).get("stats", {}).get("기술", null)


## 진행 사건의 자리 (events_until 의 단계 = 이 사건 앞까지)
static func stage_of(event: String) -> int:
	var evs: Array = progression()["events"]
	for i in evs.size():
		if evs[i][0] == event:
			return i
	push_error("common: 모르는 사건 %s" % event)
	return evs.size()


# ---- 규칙 함수 13개 + events_until (ref/rules.py 와 같은 이름 · 인자)
static func rank_index(rank: String) -> int:
	var i := ranks().find(rank)
	if i < 0:
		push_error("common: 모르는 등급 %s" % rank)
	return i


## 등급 → 게이지 칸 수: 가장 아래 1칸, 한 등급마다 +1, max_bars 에서 멈춘다
static func bars_for(rank: String) -> int:
	return mini(int(gauge()["max_bars"]), rank_index(rank) + 1)


## 차는 배율 = (1 + rank_rate_step × 등급 번호) × (0.5 + 기술 / 100) × (칸이 다 찬 등급보다 위면 fast_rank_k)
static func gauge_rate(rank: String, tech = null) -> float:
	var g := gauge()
	var t: float = float(g["default_tech"]) if tech == null else float(tech)
	var i := rank_index(rank)
	var fast: float = float(g["fast_rank_k"]) if i + 1 > int(g["max_bars"]) else 1.0
	return (1.0 + float(g["rank_rate_step"]) * i) * (0.5 + t / 100.0) * fast


## 엇박 비용(칸) = offbeat_base + (가장 위 등급 번호 - 쓰는 사람 등급 번호)
static func offbeat_cost(rank: String) -> float:
	return float(_j("rules")["cost"]["offbeat_base"]) + float(ranks().size() - 1 - rank_index(rank))


## 칸 수. cost_all 이면 null(all_min_bars 칸 이상일 때 게이지 전부)
static func skill_cost(id: String, rank: String):
	var s := skill(id)
	if s.get("cost_all", false):
		return null
	if float(s.get("cost_k", 0.0)) > 0.0:
		return offbeat_cost(rank) * float(s["cost_k"])
	return float(s.get("cost", 1.0))


## only(이 사람들만) · min_rank(이 등급 이상) — 카피 · 전수 · 진행 모두 이것으로 거른다
static func can_learn(id: String, rank: String, char_id = null) -> bool:
	var s := skill(id)
	var only: Array = s.get("only", [])
	if not only.is_empty() and not only.has(char_id):
		return false
	var mr = s.get("min_rank", null)
	return mr == null or mr == "" or rank_index(rank) >= rank_index(mr)


static func rank_gap(att_rank: String, def_rank: String) -> int:
	return rank_index(att_rank) - rank_index(def_rank)


## 등급 차 강함: 보통 공격의 피해 · 체간 배율 (치는 쪽, 맞는 쪽)
static func rank_damage_k(att_rank: String, def_rank: String) -> float:
	var rg: Dictionary = _j("rules")["rank_gap"]
	var g := rank_gap(att_rank, def_rank)
	if g >= int(rg["from"]):
		return minf(float(rg["up_max"]), 1.0 + float(rg["up_k"]) * (g - 1))
	if g <= -int(rg["from"]):
		return maxf(float(rg["down_min"]), 1.0 - float(rg["down_k"]) * (-g - 1))
	return 1.0


## 한참 아랫급(armor_gap 등급 이상 차이)의 공격에는 움찔하지 않는다 (맞는 쪽, 치는 쪽)
static func shrugs_off(def_rank: String, att_rank: String) -> bool:
	return rank_gap(def_rank, att_rank) >= int(_j("rules")["rank_gap"]["armor_gap"])


## 등급 차 한 방: 치는 쪽이 rank_gap.one_shot_gap 등급 이상 위면 보통 공격도 한 대에(조작 인물 · 방의 보스를 뺄지는 판 — skills.gd)
static func one_shot(att_rank: String, def_rank: String) -> bool:
	return rank_gap(att_rank, def_rank) >= int(_j("rules")["rank_gap"]["one_shot_gap"])


## ko_rank 효과 — 맞는 쪽이 그 등급 이하면 한 방(아무르 티그로 위빙 · 서진태 오리지널)
static func skill_ko(id: String, def_rank: String) -> bool:
	return rank_at_most(def_rank, skill(id).get("effects", {}).get("ko_rank", null))


## immune_lower 효과가 있는 기술을 쓰는 중이면, 아랫급의 공격에 무적
static func immune_lower(owner_rank: String, att_rank: String) -> bool:
	return rank_gap(owner_rank, att_rank) > 0


static func rank_at_most(rank: String, top) -> bool:
	return top != null and top != "" and rank_index(rank) <= rank_index(top)


## 기절 초 (0 = 없음). stun_rel_sec 은 쓰는 사람과 견주고(윗급이 치면 앞 값), stun_rank 는 맞는 쪽 등급만 본다
static func stun_sec(id: String, att_rank: String, def_rank: String) -> float:
	var fx: Dictionary = skill(id).get("effects", {})
	var rel: Array = fx.get("stun_rel_sec", [])
	if not rel.is_empty():
		return float(rel[0]) if rank_gap(att_rank, def_rank) > 0 else float(rel[1])
	if rank_at_most(def_rank, fx.get("stun_rank", null)):
		return float(fx["stun_rank_sec"])
	return 0.0


static func in_kill_zone(rank: String) -> bool:
	return rank_index(rank) <= rank_index(_j("rules")["offbeat"]["kill_zone_top"])


static func jesus_fraction(target_rank: String) -> float:
	return float(_j("rules")["jesus"]["fraction"].get(target_rank, 1.0))


## lethal 효과의 피해 = 맞는 쪽 최대 체력의 비율(1.0 = 즉사)
static func lethal_fraction(kind: String, target_rank: String, user_rank = null, paid_bars = null) -> float:
	var ob: Dictionary = _j("rules")["offbeat"]
	if kind == "jesus":
		return jesus_fraction(target_rank)
	if kind == "offbeat2":
		if in_kill_zone(target_rank):
			return 1.0
		var paid: float = 0.0 if paid_bars == null else float(paid_bars)
		return minf(1.0, maxf(0.0, paid / float(gauge()["max_bars"])))
	if kind == "offbeat" and in_kill_zone(target_rank):
		return 1.0
	var frac: float = float(ob["fraction"].get(target_rank, 1.0)) * float(ob["scale"][kind])
	if user_rank != null and rank_index(user_rank) < rank_index(target_rank):
		frac *= float(ob["lower_rank_k"])
	return minf(1.0, frac)


static func roulette_reflects(owner_rank: String, attacker_rank: String) -> bool:
	return rank_index(attacker_rank) >= rank_index(owner_rank)


## 처음 값에 사건들을 적용한 [등급, 아는 기술 목록]. extra 면 시점 미정 기술도
static func progress(char_id: String, events: Array = [], extra := false) -> Array:
	var c := character(char_id)
	var rank: String = c["rank"]
	var known: Array = c.get("skills", []).duplicate()
	for st in progression()["steps"]:
		if st[1] != char_id or not events.has(st[0]):
			continue
		if st[2] == "rank":
			rank = st[3]
		elif not known.has(st[3]):
			known.append(st[3])
	if extra:
		var more: Array = []
		for s in progression()["unplaced"].get(char_id, []):
			if not known.has(s):
				more.append(s)
		known.append_array(more)
	return [rank, known]


static func events_until(stage: int) -> Array:
	var out: Array = []
	var evs: Array = progression()["events"]
	for i in mini(stage, evs.size()):
		out.append(evs[i][0])
	return out
