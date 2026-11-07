extends RefCounted
## 공통 규칙 같은 결과 시험 — castle_common `cases/rules_cases.json`(받은 사본 `res://data/common/cases/`)의 줄 전부를
## `src/data/common.gd` 로 돌려 기대 값과 같은지 본다. 실수는 차이 1e-9 까지 같으면 통과(cases 머리 _about).
## 시험 값은 castle_common `tools/gen_cases.py` 가 `ref/rules.py` 로 만든다 — 여기서 고치지 않는다.

const Common = preload("res://src/data/common.gd")
const CASES := "res://data/common/cases/rules_cases.json"
const EPS := 1e-9
const N_FN := 15                 # 시험 함수 수 (bars_for … progress_at — c3ed030 에 one_shot · skill_ko)

var failures: Array = []


func check(cond: bool, msg: String) -> void:
	if not cond:
		failures.append(msg)


func _cases() -> Array:
	var data = JSON.parse_string(FileAccess.get_file_as_string(CASES))
	return data["cases"] if data is Dictionary else []


func _call(fn: String, a: Array):
	match fn:
		"bars_for": return Common.bars_for(a[0])
		"gauge_rate": return Common.gauge_rate(a[0], a[1])
		"offbeat_cost": return Common.offbeat_cost(a[0])
		"skill_cost": return Common.skill_cost(a[0], a[1])
		"can_learn": return Common.can_learn(a[0], a[1], a[2])
		"rank_gap": return Common.rank_gap(a[0], a[1])
		"rank_damage_k": return Common.rank_damage_k(a[0], a[1])
		"shrugs_off": return Common.shrugs_off(a[0], a[1])
		"immune_lower": return Common.immune_lower(a[0], a[1])
		"one_shot": return Common.one_shot(a[0], a[1])
		"skill_ko": return Common.skill_ko(a[0], a[1])
		"stun_sec": return Common.stun_sec(a[0], a[1], a[2])
		"lethal_fraction": return Common.lethal_fraction(a[0], a[1], a[2], a[3])
		"roulette_reflects": return Common.roulette_reflects(a[0], a[1])
		"progress_at": return Common.progress(a[0], Common.events_until(int(a[1])), a[2])
	return "모르는 함수 " + fn


## 같은가 — 수(int · float)끼리는 1e-9, 배열은 자리마다, 그 밖(bool · 문자열 · null)은 종류와 값이 같아야
func _same(got, want) -> bool:
	var num := [TYPE_INT, TYPE_FLOAT]
	if typeof(want) in num and typeof(got) in num:
		return absf(float(got) - float(want)) <= EPS
	if typeof(want) == TYPE_ARRAY and typeof(got) == TYPE_ARRAY:
		if want.size() != got.size():
			return false
		for i in want.size():
			if not _same(got[i], want[i]):
				return false
		return true
	return typeof(got) == typeof(want) and got == want


func test_rules_cases_all() -> void:
	var cases := _cases()
	check(cases.size() >= 1000, "cases 를 읽었다 (%d줄)" % cases.size())
	var fns := {}
	var bad := 0
	for c in cases:
		var fn: String = c["fn"]
		fns[fn] = int(fns.get(fn, 0)) + 1
		var got = _call(fn, c["args"])
		if not _same(got, c["want"]):
			bad += 1
			if bad <= 10:
				failures.append("%s%s = %s, 기대 %s" % [fn, c["args"], got, c["want"]])
	check(bad == 0, "cases %d줄 중 %d줄 다름" % [cases.size(), bad])
	check(fns.size() == N_FN, "시험 함수 %d개 (%s)" % [fns.size(), fns.keys()])
	print("common cases: %d줄 · 함수 %d개 · 다름 %d" % [cases.size(), fns.size(), bad])


## ranks.json 최상위에 모르는 칸(strength · strength_ref)이 있어도 ladder 만 읽는다 (castle_common 세션인계 '미확인' 한 줄)
func test_ranks_ignores_unknown_fields() -> void:
	var raw = JSON.parse_string(FileAccess.get_file_as_string("res://data/common/ranks.json"))
	check(raw is Dictionary and raw.has("strength_ref"), "받은 ranks.json 에 strength_ref 가 있다")
	check(Common.ranks().size() == 15 and Common.ranks()[0] == "건달급" and Common.ranks()[14] == "재앙",
		"ladder 15개만 등급으로 (%s)" % [Common.ranks()])
