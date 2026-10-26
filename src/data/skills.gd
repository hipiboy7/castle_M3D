extends RefCounted
## 기술(스킬) · 기술 게이지 · 엇박 계열 피해 · 기절 — castle_M `castle_m/action/skills.py` 에서 3D 초안에 필요한 만큼 옮겼다
## (2026-10-26, castle_M 커밋 0a85410). 엇박 계열 · 습득 순서는 castle_common `data/skills.json` · `data/progression.json`.
## 등급은 이 결투의 두 사람만: 김신 내성 상위 · 백도찬 톱 (castle_M `castle_m/data/roster.py` RANKS 순서 번호).
## 값을 바꿀 때는 castle_common · castle_M 쪽이 원본이다(상류 → 하류).

const RANK := {"내성 하위": 10, "내성 중위": 11, "내성 상위": 12, "톱": 13, "재앙": 14}
const TOP_RANK := 14             # 재앙 — 엇박 비용 기준

const BAR := 100.0
const MAX_BARS := 10             # 엇엇박 피해 = 쓴 칸 / 이것
const ALL_MIN_BARS := 5          # 엇엇박: 이만큼 차 있어야 쓰고, 게이지를 전부 쓴다
const OFFBEAT_BASE := 2          # 엇박 비용 = 2 + (재앙 - 쓰는 사람 등급) — 재앙 2 · 톱 3 · 내성 상위 4
const GAIN := {"hit": 6.0, "parry": 18.0, "guard": 4.0, "taken": 5.0, "finisher": 14.0}
const PASSIVE := 0.03            # 싸우는 동안 프레임마다
const SKILL_HIT_K := 0.3         # 기술 동작으로 맞힌 것은 이만큼만 찬다(기술로 기술을 무한히 잇지 않게)
const LOWER_RANK_K := 2.0 / 3.0  # 아랫급이 윗급에 엇박 · 반대발 엇박을 쓰면
const OFFBEAT_FRACTION := {14: 1.0 / 6.0, 13: 1.0 / 3.0, 12: 1.0 / 2.0, 11: 2.0 / 3.0, 10: 5.0 / 6.0}
const LETHAL_SCALE := {"offbeat": 1.0, "offbeat_rev": 0.5}

## 김신 — 내성 상위: 10칸, 차는 배율 (1 + 0.06 × 12) × (0.5 + 기술 95 / 100) = 2.494 (roster.py gauge_rate)
const KIM := {"rank": 12, "bars": 10, "rate": 2.494}
## 처음 게이지: 초안은 4칸으로 시작해 기술을 바로 써 볼 수 있게 한다 — 본편은 1칸 (잠정)
const KIM_START_BARS := 4.0

## 고를 수 있는 기술 (화면 '기술 바꾸기'로 돈다). cost 칸, -1 = 엇엇박(ALL_MIN_BARS 칸 이상일 때 게이지 전부)
const KIM_SKILLS := [
	{"id": "kickarts", "name": "각법 내려찍기", "move": "s_kick", "cost": 1.0},
	{"id": "triple", "name": "리천식 삼연타", "move": "s_triple", "cost": 1.0},
]
## 백도찬이 엇박을 쓰는 것을 보고 얻는다 (progression.json 'duel_offbeat:baekdochan' — 엇박 · 엇엇박 · 반대발 엇박).
## 목록 맨 앞에 rank_order 순서로 붙는다
const KIM_LEARN := [
	{"id": "offbeat2", "name": "엇엇박 찌르기", "move": "s_offbeat2", "cost": -1.0},
	{"id": "offbeat", "name": "엇박 찌르기", "move": "s_offbeat", "cost": 4.0},
	{"id": "offbeat_rev", "name": "반대발 엇박", "move": "s_offbeat_rev", "cost": 2.0},
]

## 백도찬 엇박 (castle_M `castle_m/data/bosses.py` · `duels.py`): 체력 90% 이하에서 처음(그때까지 체력은 80% 아래로
## 안 내려간다), 그 뒤 쿨다운마다. 첫 엇박에 맞은 김신은 체력 25% 아래로 안 내려간다(보여 주는 한 방)
const BAEK_OFFBEAT := {"first_hp": 0.9, "hold_hp": 0.8, "cd": [1200, 720], "demo_floor": 0.25, "slowmo": 40}


static func offbeat_cost(rank: int) -> float:
	return float(OFFBEAT_BASE + TOP_RANK - rank)


## 엇박 계열 피해: 맞는 쪽 최대 체력의 몇 분의 몇 (외성 상위 이하는 즉사 — 이 결투에는 없다)
## offbeat2: 쓴 칸 / MAX_BARS (2/3 규칙 없음). offbeat · offbeat_rev: 등급 비율 × LETHAL_SCALE, 아랫급이 쓰면 × 2/3
static func lethal_fraction(kind: String, target_rank: int, user_rank: int, paid_bars := 0.0) -> float:
	if kind == "offbeat2":
		return clampf(paid_bars / MAX_BARS, 0.0, 1.0)
	var frac: float = OFFBEAT_FRACTION.get(target_rank, 1.0) * float(LETHAL_SCALE.get(kind, 1.0))
	if user_rank < target_rank:
		frac *= LOWER_RANK_K
	return minf(1.0, frac)


## 기절 프레임: stun_rel = [아랫급에게, 같은 급 · 윗급에게] (각법 3초 · 1초, 삼연타 셋째 대는 그 절반)
static func stun_frames(mv: Dictionary, att_rank: int, def_rank: int) -> int:
	var rel: Array = mv["stun_rel"]
	if rel.is_empty():
		return 0
	return int(rel[0]) if att_rank > def_rank else int(rel[1])
