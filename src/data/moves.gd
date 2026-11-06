extends RefCounted
## 기술 표 — 프레임(60프레임 = 1초) · 피해 · 체간 · 예고 · 거리는 3층(이 판 소유). 처음 값은 castle_M `castle_m/action/moves.py`
## (2026-10-26, castle_M 커밋 5ea02c3)에서 옮겼고 그 뒤 폰 리뷰로 바꿔 왔다. 거리(reach · radius · lunge · side)는 픽셀 단위
## 원본을 PX 로 미터로 바꾼다. 초안이라 김신 쌍칼 · 김신 기술 · 백도찬 사시미만 있다.
## 2층 효과(엇박 계열 피해 종류 lethal · 내 체력 self_cost · 각법 · 옆차기 기절 초)는 skill_id 로 공통 데이터
## (src/data/common.gd — castle_common skills.json effects)에서 읽는다 — 여기 다시 적지 않는다(S1 공통 받기).

const Common = preload("res://src/data/common.gd")
const Addendum = preload("res://src/data/addendum.gd")     # castle_common 에 없는 기술(3D 덧붙임)도 같은 길로

const PX := 0.045                 # castle_M 1px → m (키 46px ≈ 1.8m 에서 몸 너비가 맞게 조금 크게)

const DEFAULTS := {
	"label": "", "startup": 4, "active": 3, "recovery": 10, "damage": 0.0,
	"reach": 14.0, "radius": 9.0, "arc": 0.0, "parryable": true, "knockback": 1.6,
	"hitstun": 16, "hitstop": 4, "knockdown": false, "posture": 10.0, "lunge": 0.0,
	"next": "", "cancel": -1, "telegraph": "", "shape": "slash", "sfx": "swing", "hit_sfx": "hit",
	"shake": 0, "hits": 1, "side": 0.0, "skill": false, "feints": [], "any_state": false, "hand": "R",      # hand: 치는 손 · 발 (R · L)
	"guard_break": false, "skill_id": "", "stun_3d": [], "fx": "", "whiff": 0, "brake": 0,
	# guard_break: 막기 · 쳐내기를 뚫는다 / skill_id: castle_common skills.json 의 기술 id — get_move 가 effects 에서
	# lethal(엇박 계열 피해 종류, common lethal_fraction) · self_cost(맞혔을 때 쓴 사람이 잃는 체력 비율)를 채우고, 기절 초는
	# skills.gd stun_frames 가 common stun_sec 로 본다 / stun_3d: **3D 덧붙임** 기절 프레임 [아랫급에게, 같은 급 · 윗급에게] —
	# common 에 기절이 없는 기술에만(엇박 계열 · 삼연타 셋째 대, 폰 리뷰 2 · 3차에 3D 에서 먼저 시험 — castle_common_요청 1 ~ 4행)
	# whiff: 아무도 못 맞히면 회수에 더하는 프레임(헛친 큰 동작) / brake: 엇엇박 브레이크가 걸리는 프레임(그때부터 판정 직전까지 버틴다)
	# fx "triple": 리천식 삼연타 — 맞은 순서를 세어 셋째에 크게, 기절은 셋째 대만 (world.gd)
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
	# 김신 · 백도찬 기술 (src/data/skills.gd — 김신은 게이지를 쓴다). 엇박 계열은 막기 · 쳐내기를 뚫고, 맞으면 기절,
	# 헛치면(whiff) 큰 동작 그대로 잠시 멈춰 역공을 받는다 — 폰 리뷰 3차(2026-10-27), 3D 초안에서 먼저 시험
	# 엇박 찌르기: 한 박자 멈칫(잔상)한 뒤 찌르는 팔 · 다리가 같은 쪽으로 깊고 길게 쭉 뻗는다
	"s_offbeat": {"label": "엇박 찌르기", "startup": 16, "active": 4, "recovery": 18, "damage": 16, "reach": 19,
		"radius": 9, "lunge": 26, "knockback": 4.2, "hitstop": 10, "posture": 45, "guard_break": true,
		"shape": "offbeat", "sfx": "knife", "hit_sfx": "hit_heavy", "shake": 4, "skill": true, "skill_id": "offbeat",
		"feints": [6], "telegraph": "unblock", "stun_3d": [90, 60], "whiff": 30},
	# 엇엇박 찌르기: 엇박처럼 나가다 브레이크(brake 프레임) — 온몸에 부하가 걸린 채 반 박자 버티다 쭉 찌른다.
	# 게이지 전부, 피해는 쓴 칸에 비례, 맞히면 내 체력 1/5. 엇박 · 반대발 엇박과 부딪히면 무조건 이긴다(world.gd)
	"s_offbeat2": {"label": "엇엇박 찌르기", "startup": 26, "active": 5, "recovery": 18, "damage": 26, "reach": 21,
		"radius": 10, "lunge": 30, "knockback": 5.0, "hitstop": 14, "posture": 80, "guard_break": true,
		"shape": "offbeat", "sfx": "knife", "hit_sfx": "hit_heavy", "shake": 6, "skill": true, "skill_id": "offbeat2",
		"brake": 10, "telegraph": "unblock", "stun_3d": [120, 90], "whiff": 36},
	# 반대발 엇박: 디딤발을 바꿔(왼발 앞) 작게 찌른다 — 피해 · 기절이 적은 대신 회수가 짧고 헛쳐도 멈추지 않는다
	"s_offbeat_rev": {"label": "반대발 엇박 찌르기", "startup": 13, "active": 4, "recovery": 9, "damage": 14,
		"reach": 18, "radius": 9, "lunge": 16, "side": 6, "knockback": 3.0, "hitstop": 8, "posture": 30,
		"guard_break": true, "shape": "offbeat_rev", "sfx": "knife", "hit_sfx": "hit_heavy", "shake": 2, "skill": true,
		"skill_id": "offbeat_rev", "feints": [5], "telegraph": "unblock", "stun_3d": [40, 24]},
	# 각법: 다리를 머리 위까지 곧게 들어 올렸다가 바닥까지 내려찍는다 — 기절은 common kickarts stun_rel_sec(아랫급 3초 · 같은 급 · 윗급 1초)
	"s_kick": {"label": "각법 — 내려찍기", "startup": 14, "active": 3, "recovery": 16, "damage": 12, "reach": 13,
		"radius": 10, "lunge": 6, "knockback": 0.8, "hitstop": 12, "posture": 22, "shape": "axe", "sfx": "kick",
		"hit_sfx": "hit_heavy", "shake": 7, "skill": true, "skill_id": "kickarts"},
	# 리천식 삼연타: 주먹 세 번(빠르게 — 판정 12프레임에 세 대) — 앞 두 대는 붙잡아 두고(넉백 작게) 셋째에 크게,
	# 셋째 대에 각법의 절반만큼 기절 (기절은 3D 초안에서 먼저 — 폰 리뷰 2026-10-26, castle_M 반영은 그쪽 세션)
	"s_triple": {"label": "리천식 삼연타", "startup": 3, "active": 12, "recovery": 14, "damage": 7, "reach": 14,
		"radius": 9, "arc": 60, "lunge": 8, "knockback": 0.5, "hitstop": 6, "posture": 12, "hits": 3, "shape": "punch",
		"sfx": "swing", "hit_sfx": "hit", "skill": true, "skill_id": "triple", "fx": "triple", "stun_3d": [90, 30]},
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
		"shape": "sidekick", "sfx": "kick", "hit_sfx": "hit_heavy", "shake": 3, "skill": true, "skill_id": "baek_sidekick"},
	"b_vital": {"label": "백도찬식 찌르기", "startup": 10, "active": 3, "recovery": 18, "damage": 22, "reach": 18,
		"radius": 7, "lunge": 14, "parryable": false, "knockback": 4.2, "hitstop": 12, "posture": 30,
		"telegraph": "unblock", "shape": "thrust_low", "sfx": "slash", "hit_sfx": "hit_heavy", "shake": 5,
		"skill": true, "skill_id": "baek_vital", "any_state": true},
	"b_wide": {"label": "살아있는 건 전부 죽여라", "startup": 30, "active": 10, "recovery": 26, "damage": 14, "reach": 0,
		"radius": 34, "parryable": false, "hits": 3, "knockback": 4.0, "hitstop": 6, "posture": 0,
		"telegraph": "unblock", "shape": "spin", "sfx": "wind", "hit_sfx": "hit_heavy", "shake": 4, "skill": true,
		"skill_id": "baek_wide"},
	# ---- 11장 호텔 캐슬 (S2, 2026-11-06) — 처음 값은 이 판이 정했다(봇 판 · 판 길이로 조정 — 무정지 규칙 6).
	# 기술 id · 원작 위치는 src/data/addendum.gd(3D 덧붙임 1층). 거리 단위는 위와 같다(PX). shape 는 인형 자세(src/view/poses.gd)
	# 피우진 — 맨주먹(원작 '남궁혁을 끝낸 주먹'). 잽 → 스트레이트 → 훅. 칼날 쳐내기는 못 한다(막기만)
	"w_jab": {"label": "잽", "startup": 4, "active": 3, "recovery": 9, "damage": 6, "reach": 12, "radius": 9,
		"lunge": 3, "next": "w_straight", "cancel": 7, "posture": 7, "shape": "punch", "sfx": "swing"},
	"w_straight": {"label": "스트레이트", "startup": 5, "active": 3, "recovery": 11, "damage": 8, "reach": 13, "radius": 9,
		"lunge": 5, "next": "w_hook", "cancel": 8, "posture": 10, "shape": "punch", "sfx": "swing", "hand": "L"},
	"w_hook": {"label": "훅", "startup": 7, "active": 4, "recovery": 15, "damage": 12, "reach": 12, "radius": 11,
		"arc": 90, "lunge": 4, "knockback": 3.4, "hitstop": 7, "posture": 18, "shape": "punch", "sfx": "kick",
		"hit_sfx": "hit_heavy", "shake": 2},
	"w_dash": {"label": "돌진 주먹", "startup": 6, "active": 5, "recovery": 14, "damage": 11, "reach": 14, "radius": 9,
		"lunge": 26, "knockback": 3.8, "hitstop": 6, "posture": 16, "shape": "punch", "sfx": "swing", "hit_sfx": "hit_heavy"},
	"w_finisher": {"label": "마무리 주먹", "startup": 4, "active": 4, "recovery": 18, "damage": 34, "reach": 14, "radius": 10,
		"lunge": 8, "knockback": 4.6, "hitstop": 16, "posture": 0, "shape": "punch", "sfx": "kick", "hit_sfx": "hit_heavy",
		"shake": 6},
	# 구일화 — 주먹 · 팔꿈치(057 중앙홀 난전). 아군 AI 로만 나온다
	"gu_jab": {"label": "주먹", "startup": 5, "active": 3, "recovery": 11, "damage": 7, "reach": 12, "radius": 9,
		"lunge": 4, "next": "gu_elbow", "cancel": 8, "posture": 9, "shape": "punch", "sfx": "swing"},
	"gu_elbow": {"label": "팔꿈치", "startup": 6, "active": 3, "recovery": 14, "damage": 10, "reach": 11, "radius": 10,
		"arc": 80, "lunge": 4, "knockback": 2.8, "posture": 14, "shape": "punch", "sfx": "kick", "hand": "L",
		"hit_sfx": "hit_heavy"},
	"gu_dash": {"label": "돌진", "startup": 6, "active": 5, "recovery": 14, "damage": 10, "reach": 13, "radius": 10,
		"lunge": 24, "knockback": 3.6, "posture": 16, "shape": "punch", "sfx": "swing", "hit_sfx": "hit_heavy"},
	"gu_finisher": {"label": "내리꽂기", "startup": 4, "active": 4, "recovery": 18, "damage": 30, "reach": 14, "radius": 10,
		"lunge": 6, "knockback": 4.4, "hitstop": 14, "posture": 0, "shape": "punch", "sfx": "kick", "hit_sfx": "hit_heavy",
		"shake": 5},
	"s_gu_headbutt": {"label": "들이받기", "startup": 12, "active": 4, "recovery": 16, "damage": 14, "reach": 13,
		"radius": 10, "lunge": 26, "knockback": 5.0, "hitstop": 10, "posture": 26, "shape": "thrust", "sfx": "kick",
		"hit_sfx": "hit_heavy", "shake": 4, "skill": true, "skill_id": "guilhwa_headbutt", "stun_3d": [60, 30]},
	"s_gu_forearm": {"label": "팔뚝 연타", "startup": 4, "active": 12, "recovery": 14, "damage": 6, "reach": 13,
		"radius": 10, "arc": 70, "lunge": 8, "knockback": 0.6, "hitstop": 5, "posture": 12, "hits": 3, "shape": "punch",
		"sfx": "swing", "skill": true, "skill_id": "guilhwa_forearm"},
	# 캐슬 경호원(엑스트라) — 곤봉 · 주먹
	"c_baton": {"label": "곤봉", "startup": 15, "active": 3, "recovery": 12, "damage": 8, "reach": 14, "radius": 10,
		"arc": 70, "lunge": 5, "posture": 10, "telegraph": "parry", "shape": "slash", "sfx": "swing"},
	"c_punch": {"label": "주먹", "startup": 13, "active": 3, "recovery": 12, "damage": 7, "reach": 12, "radius": 9,
		"lunge": 6, "posture": 9, "telegraph": "parry", "shape": "punch", "sfx": "swing"},
	# 경호대 최후의 4인 — 칼(오른손) · 권총(왼손). 기술은 마준영 기술의 전국구 하향(addendum.gd)
	"g4_slash": {"label": "칼 베기", "startup": 14, "active": 3, "recovery": 11, "damage": 9, "reach": 14, "radius": 10,
		"arc": 70, "lunge": 5, "posture": 10, "telegraph": "parry", "shape": "slash", "sfx": "knife"},
	"g4_thrust": {"label": "칼 찌르기", "startup": 15, "active": 4, "recovery": 14, "damage": 10, "reach": 17, "radius": 8,
		"lunge": 10, "knockback": 3.0, "posture": 14, "telegraph": "parry", "shape": "thrust", "sfx": "slash"},
	"s_g4_chop": {"label": "칼 내리찍기", "startup": 19, "active": 3, "recovery": 16, "damage": 13, "reach": 14,
		"radius": 10, "arc": 40, "lunge": 6, "knockback": 2.4, "hitstop": 8, "posture": 20, "telegraph": "parry",
		"shape": "slash", "sfx": "slash", "hit_sfx": "hit_heavy", "shake": 2, "skill": true, "skill_id": "g4_chop"},
	"s_g4_heel": {"label": "내려찍기 하이킥", "startup": 20, "active": 3, "recovery": 18, "damage": 12, "reach": 13,
		"radius": 10, "lunge": 6, "knockback": 1.0, "hitstop": 10, "posture": 18, "telegraph": "parry", "shape": "axe",
		"sfx": "kick", "hit_sfx": "hit_heavy", "shake": 4, "skill": true, "skill_id": "g4_heelkick", "stun_3d": [40, 20]},
	# 총: 겨누는 동안(startup) 빨간 ! — 보고 구른다. 선 판정(world.gd shape shot), 사거리 7m
	"t_shot": {"label": "근거리 사격", "startup": 28, "active": 2, "recovery": 18, "damage": 12, "reach": 155, "radius": 4,
		"parryable": false, "knockback": 2.0, "hitstop": 6, "posture": 12, "telegraph": "unblock", "shape": "shot",
		"sfx": "shot", "hit_sfx": "hit_heavy", "shake": 3, "skill": true, "skill_id": "g4_shot", "hand": "L"},
	# 하야부사 — 긴칼(카타나). 신겐보다 짧고 느리다(하향)
	"hy_slash1": {"label": "긴칼 베기", "startup": 13, "active": 3, "recovery": 11, "damage": 10, "reach": 20, "radius": 11,
		"arc": 80, "lunge": 6, "posture": 12, "telegraph": "parry", "shape": "slash", "sfx": "knife"},
	"hy_slash2": {"label": "되베기", "startup": 10, "active": 3, "recovery": 11, "damage": 10, "reach": 20, "radius": 11,
		"arc": 80, "lunge": 5, "posture": 12, "telegraph": "parry", "shape": "slash_back", "sfx": "knife"},
	"hy_thrust": {"label": "긴칼 찌르기", "startup": 15, "active": 4, "recovery": 15, "damage": 12, "reach": 24, "radius": 8,
		"lunge": 14, "knockback": 3.2, "hitstop": 7, "posture": 16, "telegraph": "parry", "shape": "thrust", "sfx": "slash",
		"hit_sfx": "hit_heavy", "shake": 2},
	"s_hy_arc": {"label": "하야부사식 큰 호 베기", "startup": 22, "active": 4, "recovery": 18, "damage": 17, "reach": 21,
		"radius": 13, "arc": 140, "lunge": 8, "knockback": 3.6, "hitstop": 9, "posture": 24, "telegraph": "parry",
		"shape": "slash", "sfx": "slash", "hit_sfx": "hit_heavy", "shake": 3, "skill": true, "skill_id": "hayabusa_arc"},
	"s_hy_low": {"label": "낮은 다리 베기", "startup": 15, "active": 3, "recovery": 18, "damage": 13, "reach": 18,
		"radius": 8, "lunge": 20, "parryable": false, "knockback": 2.4, "hitstop": 9, "posture": 20, "telegraph": "unblock",
		"shape": "thrust_low", "sfx": "slash", "hit_sfx": "hit_heavy", "shake": 3, "skill": true, "skill_id": "hayabusa_low"},
	# 사사키 신겐 — 대도(긴 칼 '대극') · 단도 · 발. 패턴은 boss 프로필(src/combat/enemy_ai.gd PROFILES shingen)
	"sg_slash1": {"label": "대도 베기", "startup": 15, "active": 4, "recovery": 12, "damage": 13, "reach": 23, "radius": 12,
		"arc": 90, "lunge": 7, "posture": 14, "telegraph": "parry", "shape": "slash", "sfx": "knife"},
	"sg_slash2": {"label": "대도 되베기", "startup": 10, "active": 4, "recovery": 12, "damage": 12, "reach": 23, "radius": 12,
		"arc": 90, "lunge": 6, "posture": 14, "telegraph": "parry", "shape": "slash_back", "sfx": "knife"},
	"sg_stab": {"label": "단도 찌르기", "startup": 12, "active": 3, "recovery": 13, "damage": 11, "reach": 15, "radius": 8,
		"lunge": 12, "knockback": 2.8, "posture": 14, "telegraph": "parry", "shape": "thrust", "sfx": "slash", "hand": "L"},
	"s_sg_daegeuk": {"label": "대극 큰 호 베기", "startup": 24, "active": 5, "recovery": 18, "damage": 24, "reach": 24,
		"radius": 14, "arc": 160, "lunge": 10, "knockback": 4.6, "hitstop": 11, "posture": 32, "telegraph": "parry",
		"shape": "slash", "sfx": "slash", "hit_sfx": "hit_heavy", "shake": 5, "skill": true, "skill_id": "shingen_daegeuk"},
	"s_sg_dive": {"label": "낮은 파고들기", "startup": 14, "active": 3, "recovery": 18, "damage": 18, "reach": 17,
		"radius": 8, "lunge": 30, "parryable": false, "knockback": 3.4, "hitstop": 10, "posture": 26, "telegraph": "unblock",
		"shape": "thrust_low", "sfx": "slash", "hit_sfx": "hit_heavy", "shake": 4, "skill": true, "skill_id": "shingen_dive",
		"hand": "L"},
	"s_sg_kick": {"label": "앞차기", "startup": 16, "active": 3, "recovery": 16, "damage": 11, "reach": 14, "radius": 10,
		"lunge": 18, "knockback": 6.5, "hitstop": 9, "posture": 22, "telegraph": "parry", "shape": "sidekick", "sfx": "kick",
		"hit_sfx": "hit_heavy", "shake": 4, "skill": true, "skill_id": "shingen_frontkick"},
	"s_sg_leap": {"label": "날아차기", "startup": 26, "active": 4, "recovery": 20, "damage": 20, "reach": 14, "radius": 11,
		"lunge": 44, "parryable": false, "knockback": 6.0, "hitstop": 12, "posture": 30, "telegraph": "unblock",
		"shape": "axe", "sfx": "kick", "hit_sfx": "hit_heavy", "shake": 6, "skill": true, "skill_id": "shingen_leap"},
	# ---- 0 · 1장(S5 묶음 2 · 3) — 1부 처음 김신은 맨손(p1:014/025-027 '너 정도엔 필요 없다'), 서진태는 아군 봇(1장 1 · 4 방).
	# 처음 값은 이 판이 정했다(봇 판 · 판 길이로 조정 — tests/sim_stage.gd ch0 · ch1). 원작 위치는 castle_common canon fights(화/컷).
	# 1부 처음 김신(내성 중위)은 이 장의 누구보다 여러 등급 위 — 보통 공격의 피해 · 체간이 몇 배로 들어가고(common rank_damage_k)
	# 아랫급의 보통 공격엔 움찔하지 않는다(shrugs_off). 그래서 보스는 넘어뜨리는(knockdown) · 숨 막히는(stun_3d) 큰 동작을 빨간 ! 로 낸다
	# 김신 맨손: 잽 → 주먹 → 턱 쳐 올리기 · 날아 차기 돌진 · 받아넘기며 치기 · 처박기
	"kf_jab": {"label": "잽", "startup": 4, "active": 3, "recovery": 9, "damage": 6, "reach": 12, "radius": 9,
		"lunge": 3, "next": "kf_jab2", "cancel": 7, "posture": 7, "shape": "punch", "sfx": "swing"},          # 014/027-030 파고들기
	"kf_jab2": {"label": "주먹", "startup": 4, "active": 3, "recovery": 10, "damage": 7, "reach": 13, "radius": 9,
		"lunge": 4, "next": "kf_upper", "cancel": 8, "posture": 9, "shape": "punch", "sfx": "swing", "hand": "L"},
	"kf_upper": {"label": "턱 쳐 올리기", "startup": 6, "active": 4, "recovery": 15, "damage": 12, "reach": 12, "radius": 10,
		"arc": 60, "lunge": 6, "knockback": 3.4, "hitstop": 7, "posture": 18, "shape": "punch", "sfx": "kick",
		"hit_sfx": "hit_heavy", "shake": 2},                                                                   # 002/016-017 · 014/027-030 어퍼컷
	"kf_dash": {"label": "날아 차기", "startup": 6, "active": 5, "recovery": 14, "damage": 11, "reach": 14, "radius": 9,
		"lunge": 28, "knockback": 3.8, "hitstop": 6, "posture": 16, "shape": "sidekick", "sfx": "kick", "hit_sfx": "hit_heavy"},   # 003/026-030 · 006/004-005
	"kf_counter": {"label": "받아넘기며 치기", "startup": 2, "active": 3, "recovery": 10, "damage": 15, "reach": 13, "radius": 11,
		"arc": 80, "lunge": 6, "posture": 24, "hitstop": 7, "shape": "punch", "sfx": "kick", "hit_sfx": "hit_heavy", "shake": 2},   # 014/027-030 ⑤ · 016/005-007 어깨로 흘리고 휘두르기
	"kf_finisher": {"label": "처박기", "startup": 3, "active": 4, "recovery": 18, "damage": 40, "reach": 14, "radius": 10,
		"lunge": 8, "knockback": 4.0, "hitstop": 16, "posture": 0, "shape": "punch", "sfx": "kick", "hit_sfx": "hit_heavy",
		"shake": 6},                                                                                           # 016/007 턱 밀어 메다꽂기 · 020/024-030 아스팔트에 처박기
	# 서진태(1장 아군) — 빠른 주먹 둘 → 하이킥(006/005-009 3연타 · 오른발 하이킥). 아군 AI 로만 나온다
	"j_jab": {"label": "주먹", "startup": 4, "active": 3, "recovery": 8, "damage": 6, "reach": 12, "radius": 9,
		"lunge": 4, "next": "j_jab2", "cancel": 6, "posture": 7, "shape": "punch", "sfx": "swing"},
	"j_jab2": {"label": "주먹", "startup": 4, "active": 3, "recovery": 9, "damage": 6, "reach": 12, "radius": 9,
		"lunge": 4, "next": "j_kick", "cancel": 7, "posture": 8, "shape": "punch", "sfx": "swing", "hand": "L"},
	"j_kick": {"label": "하이킥", "startup": 7, "active": 4, "recovery": 15, "damage": 11, "reach": 14, "radius": 10,
		"arc": 70, "lunge": 4, "knockback": 3.4, "hitstop": 7, "posture": 16, "shape": "sidekick", "sfx": "kick",
		"hit_sfx": "hit_heavy", "shake": 2},
	"j_dash": {"label": "뛰어들어 치기", "startup": 6, "active": 5, "recovery": 14, "damage": 10, "reach": 14, "radius": 9,
		"lunge": 26, "knockback": 3.8, "hitstop": 6, "posture": 16, "shape": "punch", "sfx": "kick", "hit_sfx": "hit_heavy"},   # 006/005-007 대각선으로 뛰어들어
	"j_finisher": {"label": "내려찍기", "startup": 4, "active": 4, "recovery": 18, "damage": 30, "reach": 14, "radius": 10,
		"lunge": 8, "knockback": 4.6, "hitstop": 14, "posture": 0, "shape": "axe", "sfx": "kick", "hit_sfx": "hit_heavy",
		"shake": 5},
	# 엑스트라(m_) — 군터 경호원 · DS 조직원 · DS 습격조(건달급). 느리고 예고가 길다(0장 첫 방은 '싸움 익히기')
	"m_punch": {"label": "주먹", "startup": 14, "active": 3, "recovery": 12, "damage": 7, "reach": 12, "radius": 9,
		"lunge": 6, "posture": 9, "telegraph": "parry", "shape": "punch", "sfx": "swing"},
	"m_swing": {"label": "휘두르기", "startup": 17, "active": 3, "recovery": 14, "damage": 9, "reach": 13, "radius": 10,
		"arc": 90, "lunge": 5, "knockback": 2.4, "posture": 12, "telegraph": "parry", "shape": "punch", "sfx": "swing"},        # 005/016-017 크게 휘두르자(후웅)
	"m_knife": {"label": "칼 찌르기", "startup": 16, "active": 3, "recovery": 13, "damage": 9, "reach": 15, "radius": 8,
		"lunge": 10, "posture": 10, "telegraph": "parry", "shape": "thrust", "sfx": "knife"},                                  # 003/016-018 · 003/026-030 칼을 들고 덮침
	"m_pipe": {"label": "쇠파이프 내려치기", "startup": 17, "active": 3, "recovery": 14, "damage": 10, "reach": 16, "radius": 10,
		"arc": 60, "lunge": 5, "posture": 12, "telegraph": "parry", "shape": "slash", "sfx": "swing", "hit_sfx": "hit_heavy"},  # 003/042-045 배트 · 008/001-004 쇠파이프 · 방망이
	"m_pipe_back": {"label": "되휘두르기", "startup": 12, "active": 3, "recovery": 14, "damage": 8, "reach": 16, "radius": 10,
		"arc": 100, "lunge": 4, "posture": 10, "telegraph": "parry", "shape": "slash_back", "sfx": "swing"},                     # 008/001-004 머리 위로 지나가는 휘두르기
	"m_charge": {"label": "함성 돌진", "startup": 18, "active": 4, "recovery": 16, "damage": 10, "reach": 14, "radius": 10,
		"arc": 60, "lunge": 24, "knockback": 3.0, "posture": 12, "telegraph": "parry", "shape": "slash", "sfx": "swing"},       # 008/001-004 함성과 함께 정면 돌진
	"m_brute_hook": {"label": "거구 훅", "startup": 18, "active": 4, "recovery": 16, "damage": 12, "reach": 13, "radius": 11,
		"arc": 90, "lunge": 6, "knockback": 3.6, "hitstop": 7, "posture": 16, "telegraph": "parry", "shape": "punch", "sfx": "kick",
		"hit_sfx": "hit_heavy", "shake": 2},                                                                   # 002/013-015 포니테일 거구
	"m_brute_slam": {"label": "두 손 내려찍기", "startup": 26, "active": 4, "recovery": 22, "damage": 14, "reach": 13, "radius": 11,
		"arc": 40, "lunge": 8, "parryable": false, "knockdown": true, "knockback": 3.0, "hitstop": 10, "posture": 20,
		"telegraph": "unblock", "shape": "slash", "sfx": "swing", "hit_sfx": "hit_heavy", "shake": 4, "whiff": 20},
	# 총(선 판정 world.gd shape shot) — 겨누는 동안 빨간 ! (보고 구른다). 리볼버는 한 발, 우지는 네 발을 흩뿌린다
	"m_revolver": {"label": "리볼버", "startup": 30, "active": 2, "recovery": 20, "damage": 12, "reach": 150, "radius": 4,
		"parryable": false, "knockback": 2.0, "hitstop": 6, "posture": 12, "telegraph": "unblock", "shape": "shot",
		"sfx": "shot", "hit_sfx": "hit_heavy", "shake": 3},                                                    # 002/013-015 리볼버를 겨눈 대머리
	"m_uzi": {"label": "우지 난사", "startup": 26, "active": 16, "recovery": 18, "damage": 4, "reach": 140, "radius": 6,
		"parryable": false, "hits": 4, "knockback": 0.8, "hitstop": 3, "posture": 5, "telegraph": "unblock", "shape": "shot",
		"sfx": "shot", "hit_sfx": "hit", "shake": 2},                                                          # 002/013-017 권총과 우지를 난사(타타타타)
	# 군터(gt_, 0장 보스 · 조장급) — 거래를 거절당하자 탁자 밑 리볼버(002/021-028). 쏘는 게 거의 전부, 붙으면 발악
	"gt_revolver": {"label": "탁자 밑 리볼버", "startup": 34, "active": 2, "recovery": 22, "damage": 18, "reach": 150, "radius": 4,
		"parryable": false, "knockback": 3.0, "hitstop": 8, "posture": 18, "telegraph": "unblock", "shape": "shot",
		"sfx": "shot", "hit_sfx": "hit_heavy", "shake": 4, "skill": true},
	"gt_fan": {"label": "리볼버 연사", "startup": 28, "active": 12, "recovery": 22, "damage": 7, "reach": 150, "radius": 6,
		"parryable": false, "hits": 3, "knockback": 1.2, "hitstop": 4, "posture": 8, "telegraph": "unblock", "shape": "shot",
		"sfx": "shot", "hit_sfx": "hit_heavy", "shake": 3},
	"gt_swing": {"label": "발악 주먹", "startup": 15, "active": 3, "recovery": 14, "damage": 8, "reach": 12, "radius": 10,
		"arc": 80, "lunge": 5, "posture": 10, "telegraph": "parry", "shape": "punch", "sfx": "swing"},
	"gt_glass": {"label": "위스키 잔 휘두르기", "startup": 16, "active": 3, "recovery": 14, "damage": 9, "reach": 13, "radius": 10,
		"arc": 90, "lunge": 4, "posture": 10, "telegraph": "parry", "shape": "slash_back", "sfx": "knife", "hand": "L"},        # 002/021-028 팔이 움직이며 위스키 잔이 깨지고(까앙)
	"gt_point": {"label": "코앞 사격", "startup": 20, "active": 2, "recovery": 20, "damage": 14, "reach": 60, "radius": 5,
		"parryable": false, "knockback": 3.0, "hitstop": 8, "posture": 16, "telegraph": "unblock", "shape": "shot",
		"sfx": "shot", "hit_sfx": "hit_heavy", "shake": 4},
	# 김혁주(hj_, DS 부장 서열 4위 · 잭나이프 두 자루, 003/045-051) — '잭나이프는 큰 베기 무기가 아니다 → 첫 베기는 잽, 두 번째가 진짜'.
	# 첫 베기는 빠르고 가볍게(넓은 호), 두 번째는 칼을 치켜든 채 반 박자 멈칫(feints)한 뒤 무겁게 내려온다 — 일찍 누르면 빗나간다
	"hj_jab": {"label": "잭나이프 잽", "startup": 9, "active": 3, "recovery": 7, "damage": 5, "reach": 13, "radius": 10,
		"arc": 100, "lunge": 4, "posture": 6, "telegraph": "parry", "shape": "slash", "sfx": "knife"},
	"hj_real": {"label": "진짜 베기", "startup": 20, "active": 3, "recovery": 14, "damage": 14, "reach": 14, "radius": 10,
		"arc": 70, "lunge": 6, "posture": 16, "telegraph": "parry", "shape": "slash_back", "sfx": "slash", "hit_sfx": "hit_heavy",
		"shake": 2, "hand": "L", "feints": [8]},
	"hj_thrust": {"label": "잭나이프 찌르기", "startup": 14, "active": 3, "recovery": 14, "damage": 10, "reach": 16, "radius": 8,
		"lunge": 10, "knockback": 2.6, "posture": 12, "telegraph": "parry", "shape": "thrust", "sfx": "slash"},
	"hj_rush": {"label": "양손 잭나이프 돌진", "startup": 18, "active": 8, "recovery": 16, "damage": 7, "reach": 14, "radius": 10,
		"arc": 70, "lunge": 26, "hits": 2, "knockback": 1.6, "posture": 10, "telegraph": "parry", "shape": "slash", "sfx": "knife"},   # 003/045 '작업 들어온 거냐' 외치며 돌진
	# 김성준(sj_, 약에 취함 · 칼, 008-010) — 몰아치는 주먹 · 코트 휘두르기 · 멀리 날려 보내는 부츠 발차기 · 칼
	"sj_flurry": {"label": "주먹 연타", "startup": 10, "active": 12, "recovery": 14, "damage": 5, "reach": 13, "radius": 10,
		"arc": 60, "lunge": 10, "hits": 3, "knockback": 0.6, "hitstop": 4, "posture": 7, "telegraph": "parry", "shape": "punch",
		"sfx": "swing"},                                                                                       # 009/014-015 '재밌게 좀 해보라' 연타(퍽 퍽)
	"sj_coat": {"label": "코트 휘두르기", "startup": 16, "active": 4, "recovery": 14, "damage": 9, "reach": 14, "radius": 12,
		"arc": 140, "lunge": 4, "knockback": 2.0, "posture": 12, "telegraph": "parry", "shape": "slash", "sfx": "swing"},        # 008/004-007 '지루해 죽겠다' 코트 팔을 수평으로 크게
	"sj_kick": {"label": "부츠 발차기", "startup": 20, "active": 3, "recovery": 18, "damage": 15, "reach": 14, "radius": 10,
		"lunge": 14, "parryable": false, "knockdown": true, "knockback": 16.0, "hitstop": 12, "posture": 26, "telegraph": "unblock",
		"shape": "sidekick", "sfx": "kick", "hit_sfx": "hit_heavy", "shake": 6, "skill": true},                 # 008/004-007 머리 쪽 발차기 → 김신이 승합차에 처박힘
	"sj_upslash": {"label": "칼 베어 올리기", "startup": 15, "active": 3, "recovery": 14, "damage": 12, "reach": 15, "radius": 10,
		"arc": 80, "lunge": 6, "posture": 14, "telegraph": "parry", "shape": "slash_back", "sfx": "knife", "hand": "L"},        # 009/017-019 아래에서 위로 크게 베어 올림
	"sj_knife": {"label": "칼 크게 휘두르기", "startup": 19, "active": 3, "recovery": 16, "damage": 14, "reach": 15, "radius": 11,
		"arc": 120, "lunge": 8, "posture": 16, "telegraph": "parry", "shape": "slash", "sfx": "slash", "hit_sfx": "hit_heavy",
		"feints": [9]},                                                                                        # 010/001-002 정수로 쥔 칼을 치켜들었다가 크게 호
	# 김대건(dg_, 1장 보스 · 경호대급, 014-016) — 1차: 큰 직선 · 훅 · 크로스 카운터(치기 시작하면 맞받는다 — enemy_ai counter) ·
	# 뒷발 돌려차기 · 페인트 하이킥 · 낮은 미끄러지기 · 베어허그 태클. 2차('피떡이 돼야 시동' 015/042-048): 프로다운 연타 · 정권 · 날아 무릎
	"dg_straight": {"label": "큰 직선 주먹", "startup": 14, "active": 3, "recovery": 13, "damage": 12, "reach": 14, "radius": 9,
		"lunge": 10, "knockback": 3.0, "hitstop": 6, "posture": 14, "telegraph": "parry", "shape": "punch", "sfx": "swing",
		"hit_sfx": "hit_heavy"},                                                                               # 014/027-030 '팡'
	"dg_hook": {"label": "오른 훅", "startup": 17, "active": 4, "recovery": 16, "damage": 14, "reach": 13, "radius": 11,
		"arc": 100, "lunge": 6, "knockback": 3.6, "hitstop": 7, "posture": 18, "telegraph": "parry", "shape": "punch", "sfx": "kick",
		"hit_sfx": "hit_heavy", "shake": 2},                                                                   # 015/000 크게 휘두른 오른 훅(부웅)
	"dg_cross": {"label": "크로스 카운터", "startup": 7, "active": 3, "recovery": 14, "damage": 13, "reach": 14, "radius": 9,
		"lunge": 8, "knockback": 3.2, "hitstop": 8, "posture": 16, "telegraph": "parry", "shape": "punch", "sfx": "kick",
		"hit_sfx": "hit_heavy", "shake": 3, "hand": "L"},                                                      # 014/030-032 엇갈려 동시에 꽂힘
	"dg_spin": {"label": "뒷발 돌려차기", "startup": 20, "active": 4, "recovery": 18, "damage": 17, "reach": 15, "radius": 11,
		"arc": 120, "lunge": 8, "parryable": false, "knockdown": true, "knockback": 5.0, "hitstop": 11, "posture": 26,
		"telegraph": "unblock", "shape": "sidekick", "sfx": "kick", "hit_sfx": "hit_heavy", "shake": 5, "skill": true},  # 015/006-009 헛친 몸이 돈 그대로 뒷발
	"dg_highkick": {"label": "페인트 하이킥", "startup": 22, "active": 3, "recovery": 18, "damage": 16, "reach": 15, "radius": 10,
		"arc": 70, "lunge": 8, "knockdown": true, "knockback": 4.0, "hitstop": 10, "posture": 24, "telegraph": "parry",
		"shape": "sidekick", "sfx": "kick", "hit_sfx": "hit_heavy", "shake": 4, "feints": [8], "skill": true},  # 015/012-016 '걸렸다' 큰 주먹(속임) 뒤 디딤 하이킥
	"dg_slide": {"label": "낮게 미끄러져 들기", "startup": 16, "active": 4, "recovery": 20, "damage": 11, "reach": 16, "radius": 8,
		"lunge": 34, "parryable": false, "knockdown": true, "knockback": 3.0, "hitstop": 9, "posture": 20, "telegraph": "unblock",
		"shape": "thrust_low", "sfx": "kick", "hit_sfx": "hit_heavy", "shake": 3, "whiff": 16},              # 015/023-028 낮게 미끄러져 다리를 뻗어
	"dg_tackle": {"label": "베어허그 태클", "startup": 24, "active": 6, "recovery": 22, "damage": 18, "reach": 13, "radius": 11,
		"lunge": 44, "parryable": false, "guard_break": true, "knockdown": true, "knockback": 5.0, "hitstop": 14, "posture": 34,
		"telegraph": "unblock", "shape": "thrust", "sfx": "wind", "hit_sfx": "hit_heavy", "shake": 6, "skill": true, "whiff": 30},   # 015/029-036 허리를 껴안아 밀어붙임 — 빠져나오면 크게 빈다
	"dg_jab": {"label": "잽", "startup": 8, "active": 3, "recovery": 9, "damage": 7, "reach": 13, "radius": 9,
		"lunge": 5, "posture": 8, "telegraph": "parry", "shape": "punch", "sfx": "swing", "hand": "L"},        # 016/001-002 주먹 연타(프로다워짐)
	"dg_jeongkwon": {"label": "정권", "startup": 12, "active": 3, "recovery": 14, "damage": 16, "reach": 15, "radius": 9,
		"lunge": 12, "knockback": 5.0, "hitstop": 9, "posture": 22, "telegraph": "parry", "shape": "punch", "sfx": "kick",
		"hit_sfx": "hit_heavy", "shake": 4},                                                                   # 015/042-048 일어나 정권 — 김신이 밀려남
	"dg_knee": {"label": "날아 무릎", "startup": 22, "active": 4, "recovery": 20, "damage": 20, "reach": 14, "radius": 11,
		"lunge": 38, "parryable": false, "knockdown": true, "knockback": 5.0, "hitstop": 13, "posture": 30, "telegraph": "unblock",
		"shape": "axe", "sfx": "kick", "hit_sfx": "hit_heavy", "shake": 6, "skill": true, "whiff": 20},       # 016/004-005 몸을 날려 내리꽂는 무릎
	# 강만재(mj_, 흉터 거구 · 네임드, 005-006) — 느리고 맷집이 대단하다 · 하이가드 · 큰 오른손 · 긴 스트레이트 · 보디블로
	"mj_swing": {"label": "큰 오른손 휘두르기", "startup": 19, "active": 4, "recovery": 16, "damage": 12, "reach": 14, "radius": 12,
		"arc": 110, "lunge": 6, "knockback": 3.4, "hitstop": 7, "posture": 16, "telegraph": "parry", "shape": "punch", "sfx": "swing",
		"hit_sfx": "hit_heavy"},                                                                               # 006/005-007
	"mj_hook": {"label": "훅", "startup": 16, "active": 4, "recovery": 15, "damage": 11, "reach": 13, "radius": 11,
		"arc": 90, "lunge": 5, "knockback": 3.0, "posture": 14, "telegraph": "parry", "shape": "punch", "sfx": "kick", "hand": "L"},   # 006/008-009 크게 훅(후웅)
	"mj_straight": {"label": "긴 스트레이트", "startup": 14, "active": 3, "recovery": 14, "damage": 11, "reach": 17, "radius": 9,
		"lunge": 8, "knockback": 3.0, "posture": 14, "telegraph": "parry", "shape": "punch", "sfx": "swing"},  # 006/009-011
	"mj_rush": {"label": "낮은 돌진 주먹", "startup": 18, "active": 4, "recovery": 16, "damage": 12, "reach": 14, "radius": 10,
		"lunge": 26, "knockback": 3.4, "posture": 16, "telegraph": "parry", "shape": "punch", "sfx": "kick", "hit_sfx": "hit_heavy"},  # 006/009-011 낮게 돌진(착)
	"mj_body": {"label": "보디블로", "startup": 22, "active": 3, "recovery": 18, "damage": 16, "reach": 12, "radius": 10,
		"lunge": 10, "parryable": false, "knockback": 1.6, "hitstop": 14, "posture": 30, "telegraph": "unblock", "shape": "punch",
		"sfx": "kick", "hit_sfx": "hit_heavy", "shake": 5, "skill": true, "stun_3d": [60, 45]},              # 005/019-020 시계 찬 주먹을 복부 깊이 — 털썩 주저앉는다
	# 윤덕수(yd_, 1장 끝 보스 · 전국구, 018-020) — 큰 오른 훅 · 오른 스트레이트 · 얼굴 잡아 들어 메치기 · 짓밟기.
	# 옆구리를 맞은 뒤(020/014-018 '이런... 낭패가') 2차 — 메치기를 더 자주
	"yd_jab": {"label": "왼손 견제", "startup": 9, "active": 3, "recovery": 10, "damage": 7, "reach": 13, "radius": 9,
		"lunge": 5, "posture": 8, "telegraph": "parry", "shape": "punch", "sfx": "swing", "hand": "L"},
	"yd_hook": {"label": "큰 오른 훅", "startup": 18, "active": 4, "recovery": 16, "damage": 16, "reach": 14, "radius": 12,
		"arc": 110, "lunge": 8, "knockback": 4.4, "hitstop": 9, "posture": 20, "telegraph": "parry", "shape": "punch", "sfx": "kick",
		"hit_sfx": "hit_heavy", "shake": 3},                                                                   # 020/000-005 붉은 눈빛 궤적과 함께 오른쪽 큰 훅
	"yd_straight": {"label": "오른 스트레이트", "startup": 13, "active": 3, "recovery": 14, "damage": 13, "reach": 16, "radius": 9,
		"lunge": 10, "knockback": 3.6, "hitstop": 7, "posture": 16, "telegraph": "parry", "shape": "punch", "sfx": "swing",
		"hit_sfx": "hit_heavy"},                                                                               # 020/014-018
	"yd_grab": {"label": "얼굴 잡아 메치기", "startup": 24, "active": 5, "recovery": 22, "damage": 22, "reach": 13, "radius": 10,
		"lunge": 16, "parryable": false, "guard_break": true, "knockdown": true, "knockback": 2.0, "hitstop": 16, "posture": 40,
		"telegraph": "unblock", "shape": "thrust", "sfx": "wind", "hit_sfx": "hit_heavy", "shake": 7, "skill": true, "whiff": 24},   # 019/124-138 얼굴을 움켜쥐어 들어 올려 등부터 꽂음
	"yd_stomp": {"label": "짓밟기", "startup": 16, "active": 4, "recovery": 18, "damage": 12, "reach": 10, "radius": 11,
		"lunge": 8, "parryable": false, "knockback": 0.6, "hitstop": 10, "posture": 18, "telegraph": "unblock", "shape": "axe",
		"sfx": "kick", "hit_sfx": "hit_heavy", "shake": 5},                                                    # 019/138 쓰러진 남자를 밟음(콰득)
}

static var _cache := {}


## 이름 → 기술 (기본값을 채우고 거리를 미터로 바꾸고 2층 효과를 공통 데이터에서 채운 사본, 한 번 만들어 둔다)
static func get_move(name: String) -> Dictionary:
	if _cache.has(name):
		return _cache[name]
	var d: Dictionary = DEFAULTS.duplicate(true)
	d.merge(M[name], true)
	d["name"] = name
	var fx: Dictionary = Addendum.skill(d["skill_id"]).get("effects", {}) if d["skill_id"] != "" else {}
	d["lethal"] = str(fx.get("lethal", ""))
	d["self_cost"] = float(fx.get("self_cost", 0.0))
	for k in ["reach", "radius", "lunge", "side"]:
		d[k] = float(d[k]) * PX
	d["damage"] = float(d["damage"])
	d["posture"] = float(d["posture"])
	d["knockback"] = float(d["knockback"]) * PX * 6.0     # px/프레임 넉백 → m/초 첫 속도
	_cache[name] = d
	return d


## 쳐내는 동작 방향 (받는 사람 기준 L 왼팔 · R 오른팔, 그림용) — 판정은 쪽과 관계없다(castle_common rules/전투_쳐내기.md 2절).
## 들어오는 쪽(치는 사람 기준): 바로 베기(slash)는 오른쪽, 되베기(slash_back)는 왼쪽(fx3d.swing 궤적이 시작하는 쪽),
## 찌르기 · 주먹 · 발차기는 그 손 · 발("hand"). 마주 보고 있으니 치는 사람의 오른쪽은 막는 사람의 왼쪽이다.
static func parry_side(mv: Dictionary) -> String:
	var from := "L" if str(mv["shape"]) == "slash_back" else str(mv["hand"])
	return "R" if from == "L" else "L"


static func total(mv: Dictionary) -> int:
	return int(mv["startup"]) + int(mv["active"]) + int(mv["recovery"])


static func cancel_at(mv: Dictionary) -> int:
	var c := int(mv["cancel"])
	return c if c >= 0 else int(mv["startup"]) + int(mv["active"])
