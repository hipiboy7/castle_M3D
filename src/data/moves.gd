extends RefCounted
## 기술 표 — 프레임(60프레임 = 1초) · 피해 · 체간 · 예고는 castle_M `castle_m/action/moves.py` 에서 그대로 옮겼다
## (2026-10-26, castle_M 커밋 5ea02c3). 거리(reach · radius · lunge · side)는 픽셀 단위 원본을 PX 로 미터로 바꾼다.
## 초안이라 김신 쌍칼 · 백도찬 사시미만 옮긴다. 값을 바꿀 때는 castle_M 쪽이 원본이다(상류 → 하류).

const PX := 0.045                 # castle_M 1px → m (키 46px ≈ 1.8m 에서 몸 너비가 맞게 조금 크게)

const DEFAULTS := {
	"label": "", "startup": 4, "active": 3, "recovery": 10, "damage": 0.0,
	"reach": 14.0, "radius": 9.0, "arc": 0.0, "parryable": true, "knockback": 1.6,
	"hitstun": 16, "hitstop": 4, "knockdown": false, "posture": 10.0, "lunge": 0.0,
	"next": "", "cancel": -1, "telegraph": "", "shape": "slash", "sfx": "swing", "hit_sfx": "hit",
	"shake": 0, "hits": 1, "side": 0.0, "skill": false, "feints": [], "any_state": false, "hand": "R",
}

const M := {
	# 김신 — 쌍단검(거버 Mark II). 빠른 베기 2번 → 찌르기. 둘째 베기는 왼손 역수 칼(그림만)
	"k_slash1": {"label": "베기", "startup": 4, "active": 3, "recovery": 10, "damage": 7, "reach": 13, "radius": 10,
		"arc": 70, "lunge": 3, "next": "k_slash2", "cancel": 8, "posture": 8, "shape": "slash", "sfx": "swing"},
	"k_slash2": {"label": "되베기", "startup": 4, "active": 3, "recovery": 11, "damage": 7, "reach": 13, "radius": 10,
		"arc": 70, "lunge": 3, "next": "k_thrust", "cancel": 8, "posture": 8, "shape": "slash_back", "sfx": "swing",
		"hand": "L"},
	"k_thrust": {"label": "찌르기", "startup": 6, "active": 4, "recovery": 16, "damage": 12, "reach": 18, "radius": 8,
		"lunge": 8, "knockback": 3.2, "hitstop": 7, "posture": 18, "shape": "thrust", "sfx": "slash",
		"hit_sfx": "hit_heavy", "shake": 3},
	"k_dash": {"label": "돌진 찌르기", "startup": 5, "active": 6, "recovery": 14, "damage": 10, "reach": 16, "radius": 9,
		"lunge": 28, "knockback": 3.6, "hitstop": 6, "posture": 16, "shape": "thrust", "sfx": "slash",
		"hit_sfx": "hit_heavy", "shake": 2},
	"k_counter": {"label": "반격 베기", "startup": 2, "active": 3, "recovery": 10, "damage": 15, "reach": 15, "radius": 11,
		"arc": 80, "lunge": 6, "posture": 24, "hitstop": 7, "shape": "slash", "sfx": "slash", "hit_sfx": "hit_heavy",
		"shake": 2},
	"k_finisher": {"label": "제압", "startup": 3, "active": 4, "recovery": 18, "damage": 40, "reach": 16, "radius": 10,
		"lunge": 8, "knockback": 4.0, "hitstop": 16, "posture": 0, "shape": "cross", "sfx": "slash",
		"hit_sfx": "hit_heavy", "shake": 6},
	# 보스 — 백도찬 (사시미 나이프 파이팅). 패턴 · 박자는 src/combat/boss_ai.gd (castle_M P2 설계서 8.2절)
	"b_slash1": {"label": "사시미 베기", "startup": 14, "active": 3, "recovery": 10, "damage": 9, "reach": 14, "radius": 10,
		"arc": 70, "lunge": 5, "posture": 10, "telegraph": "parry", "shape": "slash", "sfx": "knife"},
	"b_slash2": {"label": "되베기", "startup": 9, "active": 3, "recovery": 10, "damage": 9, "reach": 14, "radius": 10,
		"arc": 70, "lunge": 5, "posture": 10, "telegraph": "parry", "shape": "slash_back", "sfx": "knife"},
	"b_slash2_off": {"label": "엇박 되베기", "startup": 19, "active": 3, "recovery": 10, "damage": 10, "reach": 14,
		"radius": 10, "arc": 70, "lunge": 5, "posture": 12, "telegraph": "parry", "shape": "slash_back", "sfx": "knife",
		"feints": [9]},
	"b_thrust": {"label": "사시미 찌르기", "startup": 16, "active": 4, "recovery": 16, "damage": 12, "reach": 18, "radius": 8,
		"lunge": 12, "knockback": 3.2, "hitstop": 7, "posture": 16, "telegraph": "parry", "shape": "thrust",
		"sfx": "slash", "hit_sfx": "hit_heavy", "shake": 2},
	"b_step_l": {"label": "스텝 베기", "startup": 18, "active": 3, "recovery": 12, "damage": 10, "reach": 14, "radius": 10,
		"arc": 80, "lunge": 6, "side": 18, "posture": 12, "telegraph": "parry", "shape": "slash", "sfx": "knife"},
	"b_step_r": {"label": "스텝 베기", "startup": 18, "active": 3, "recovery": 12, "damage": 10, "reach": 14, "radius": 10,
		"arc": 80, "lunge": 6, "side": -18, "posture": 12, "telegraph": "parry", "shape": "slash", "sfx": "knife"},
	"b_counter": {"label": "맞받아 베기", "startup": 14, "active": 3, "recovery": 14, "damage": 11, "reach": 15,
		"radius": 10, "arc": 80, "lunge": 6, "posture": 14, "telegraph": "parry", "shape": "slash", "sfx": "slash",
		"hit_sfx": "hit_heavy"},
	"b_sidekick": {"label": "백도찬식 옆차기", "startup": 20, "active": 3, "recovery": 16, "damage": 10, "reach": 14,
		"radius": 9, "lunge": 30, "knockback": 5.5, "hitstop": 8, "posture": 20, "telegraph": "parry",
		"shape": "sidekick", "sfx": "kick", "hit_sfx": "hit_heavy", "shake": 3, "skill": true},
	"b_vital": {"label": "백도찬식 찌르기", "startup": 10, "active": 3, "recovery": 18, "damage": 22, "reach": 18,
		"radius": 7, "lunge": 14, "parryable": false, "knockback": 4.2, "hitstop": 12, "posture": 30,
		"telegraph": "unblock", "shape": "thrust_low", "sfx": "slash", "hit_sfx": "hit_heavy", "shake": 5,
		"skill": true, "any_state": true},
	"b_wide": {"label": "살아있는 건 전부 죽여라", "startup": 30, "active": 10, "recovery": 26, "damage": 14, "reach": 0,
		"radius": 34, "parryable": false, "hits": 3, "knockback": 4.0, "hitstop": 6, "posture": 0,
		"telegraph": "unblock", "shape": "spin", "sfx": "wind", "hit_sfx": "hit_heavy", "shake": 4, "skill": true},
}

static var _cache := {}


## 이름 → 기술 (기본값을 채우고 거리를 미터로 바꾼 사본, 한 번 만들어 둔다)
static func get_move(name: String) -> Dictionary:
	if _cache.has(name):
		return _cache[name]
	var d: Dictionary = DEFAULTS.duplicate(true)
	d.merge(M[name], true)
	d["name"] = name
	for k in ["reach", "radius", "lunge", "side"]:
		d[k] = float(d[k]) * PX
	d["damage"] = float(d["damage"])
	d["posture"] = float(d["posture"])
	d["knockback"] = float(d["knockback"]) * PX * 6.0     # px/프레임 넉백 → m/초 첫 속도
	_cache[name] = d
	return d


static func total(mv: Dictionary) -> int:
	return int(mv["startup"]) + int(mv["active"]) + int(mv["recovery"])


static func cancel_at(mv: Dictionary) -> int:
	var c := int(mv["cancel"])
	return c if c >= 0 else int(mv["startup"]) + int(mv["active"])
