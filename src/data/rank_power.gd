extends RefCounted
## 등급 능력 — **3D 덧붙임**(사용자 2026-11-10 "레벨이 높을수록 당연히 동작은 더 빠르고 공격력은 더 높고, 체력은 더 많고,
## 회피율도 높아야 하며, 방어력도 더 높아야함. 재앙급은 거의 외성 미만급에는 타격을 받지 않고, 타격을 맞아도 데미지가
## 방어력이 높아서 덜 들어가야함"). 공통 후보 — docs/castle_common_요청.md 34행.
## castle_common rank_gap(공격 배율 rank_damage_k · 움찔 안 함 shrugs_off · 한 방 one_shot)은 그대로 두고 그 위에 더한다:
##   빠르기 tempo — 동작 프레임 ÷ tempo · 걷기 · 달리기 × tempo (등급 하나마다, 기준 MID = 1)
##   체력 hp_k — 장 표 hp × hp_k (등급 하나마다)
##   방어 defense_k — 아랫급의 보통 공격 피해 · 체간 × (DEF_FROM 등급 차부터 줄어든다, 바닥 DEF_MIN)
##   회피 evade_p — 아랫급의 보통 공격을 저절로 피할 확률(EVADE_FROM 등급 차부터, 위 EVADE_MAX)
##   재앙 ← 외성 미만: 회피 CALAMITY_EVADE · 방어 × CALAMITY_DEF 더
## 엇박 계열(lethal)은 등급과 상관없는 박자 기술이라 피하기 · 방어를 받지 않는다(윗급을 잡는 수단 — 기획서 02). 순수 함수.

const Common = preload("res://src/data/common.gd")

const MID := "외성 하위"
const TEMPO_STEP := 0.015
const HP_STEP := 0.05
const TOP_OVERRIDE := {"재앙": {"tempo": 1.15, "hp": 1.4}}
const DEF_FROM := 2
const DEF_STEP := 0.06
const DEF_MIN := 0.35
const EVADE_FROM := 2
const EVADE_STEP := 0.05
const EVADE_MAX := 0.45
const CALAMITY := "재앙"
const CALAMITY_BELOW := "외성 하위"     # 이 등급 밑(외성 미만)의 공격
const CALAMITY_EVADE := 0.9
const CALAMITY_DEF := 0.4

static var _idx := {}


static func _i(rank: String) -> int:
	if _idx.is_empty():
		var lad: Array = Common.ranks()
		for i in lad.size():
			_idx[lad[i]] = i
	return int(_idx.get(rank, -1))


static func _steps(rank: String) -> int:
	var i := _i(rank)
	return 0 if i < 0 else i - _i(MID)


static func tempo(rank: String) -> float:
	if TOP_OVERRIDE.has(rank):
		return float(TOP_OVERRIDE[rank]["tempo"])
	return 1.0 + TEMPO_STEP * _steps(rank)


static func hp_k(rank: String) -> float:
	if TOP_OVERRIDE.has(rank):
		return float(TOP_OVERRIDE[rank]["hp"])
	return 1.0 + HP_STEP * _steps(rank)


static func _gap(def_rank: String, att_rank: String) -> int:
	if _i(def_rank) < 0 or _i(att_rank) < 0:
		return 0
	return _i(def_rank) - _i(att_rank)


static func _calamity(def_rank: String, att_rank: String) -> bool:
	return def_rank == CALAMITY and _i(att_rank) >= 0 and _i(att_rank) < _i(CALAMITY_BELOW)


## 맞는 쪽이 윗급일 때 보통 공격 피해 · 체간에 곱한다(1 = 그대로)
static func defense_k(def_rank: String, att_rank: String) -> float:
	var g := _gap(def_rank, att_rank)
	var k := 1.0
	if g >= DEF_FROM:
		k = maxf(DEF_MIN, 1.0 - DEF_STEP * (g - 1))
	if _calamity(def_rank, att_rank):
		k *= CALAMITY_DEF
	return k


## 아랫급의 보통 공격을 저절로 피할 확률
static func evade_p(def_rank: String, att_rank: String) -> float:
	if _calamity(def_rank, att_rank):
		return CALAMITY_EVADE
	var g := _gap(def_rank, att_rank)
	if g < EVADE_FROM:
		return 0.0
	return minf(EVADE_MAX, EVADE_STEP * (g - 1))


## 등급 빠르기로 동작 프레임을 줄이거나 늘린 사본(tempo 1 이면 그대로). 준비 · 판정은 1프레임 이상
static func scaled(mv: Dictionary, rank: String) -> Dictionary:
	var tp := tempo(rank)
	if is_equal_approx(tp, 1.0):
		return mv
	var m := mv.duplicate()
	var f := func(v) -> int: return int(round(float(v) / tp))
	m["startup"] = maxi(1, f.call(mv["startup"]))
	m["active"] = maxi(1, f.call(mv["active"]))
	m["recovery"] = maxi(0, f.call(mv["recovery"]))
	if int(mv.get("cancel", -1)) >= 0:
		m["cancel"] = f.call(mv["cancel"])
	if int(mv.get("stance", 0)) > 0:
		m["stance"] = maxi(1, f.call(mv["stance"]))
	if int(mv.get("brake", 0)) > 0:
		m["brake"] = maxi(1, f.call(mv["brake"]))
	m["feints"] = mv.get("feints", []).map(func(x): return maxi(1, f.call(x)))
	return m
