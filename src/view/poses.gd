extends RefCounted
## 관절 각도 표 (도) — src/view/puppet3d.gd 가 읽는다. 새 자세는 표에 한 줄을 더하면 된다.
##
## 몸통(pelvis · spine · chest · head): Vector3(앞으로 숙임, 비틀기(+ 오른 어깨가 앞), 옆 기울기(+ 오른쪽))
## 팔 · 다리(sh_ · th_): Vector3(앞으로 듦, 가로 휘두름(+ 몸 앞쪽으로), 옆으로 벌림(+ 바깥)) — 왼쪽도 같은 뜻(인형이 뒤집는다)
## 팔꿈치(el_) · 무릎(kn_) · 발목(ft_): 굽힘 각도 하나, 손목(wr_): Vector3(굽힘, 비틀기, 꺾기)
## root_y · root_fwd: 골반 높이(+ 면 발이 그만큼 땅에서 뜬다 — 날아차기) · 앞 보정(m), spin: 몸 전체 돌기(+ 왼쪽으로), roll: 앞구르기, fall: 뒤로 넘어짐
## 공격 동작은 모양(Move.shape)마다 W(준비 끝) · S(타격) · F(회수) 세 자세 — 인형이 A(예비 동작) · O(지나침)를 더해
## 가드 → A → W → S → O → F → 가드 다섯 자세로 부드럽게 잇는다(아래 AMP_TORSO 묶음 — src/view/puppet3d.gd _shape_set).

const NEUTRAL := {
	"pelvis": Vector3.ZERO, "spine": Vector3.ZERO, "chest": Vector3.ZERO, "head": Vector3.ZERO,
	"sh_r": Vector3(0, 0, 8), "sh_l": Vector3(0, 0, 8), "el_r": 10.0, "el_l": 10.0,
	"wr_r": Vector3.ZERO, "wr_l": Vector3.ZERO,
	"th_r": Vector3(0, 0, 3), "th_l": Vector3(0, 0, 3), "kn_r": 4.0, "kn_l": 4.0, "ft_r": 0.0, "ft_l": 0.0,
	"root_y": 0.0, "root_fwd": 0.0, "spin": 0.0, "roll": 0.0, "fall": 0.0,
}

# 김신 칼 자세: 오른손 칼(바로 쥠)을 앞으로, 왼손 칼(거꾸로 쥠)은 아래팔에 붙여 목 · 얼굴을 막는다. 오른발이 앞
const GUARD_KIM := {
	"pelvis": Vector3(6, 14, 0), "spine": Vector3(4, 4, 0), "chest": Vector3(4, 6, 0), "head": Vector3(-6, -22, 0),
	"sh_r": Vector3(48, 22, 14), "el_r": 78.0, "sh_l": Vector3(52, 38, 12), "el_l": 118.0,
	"th_r": Vector3(24, -4, 6), "kn_r": 30.0, "ft_r": -6.0, "th_l": Vector3(-16, 4, 10), "kn_l": 26.0, "ft_l": 12.0,
}
# 백도찬: 오른손 사시미를 허리 앞에 낮게, 왼손은 빈손으로 가슴 앞(손등 받기 손)
const GUARD_BAEK := {
	"pelvis": Vector3(4, 16, 0), "spine": Vector3(2, 4, 0), "chest": Vector3(2, 6, 0), "head": Vector3(-4, -24, 0),
	"sh_r": Vector3(30, 14, 16), "el_r": 64.0, "sh_l": Vector3(46, 40, 10), "el_l": 104.0,
	"th_r": Vector3(22, -4, 6), "kn_r": 24.0, "ft_r": -6.0, "th_l": Vector3(-14, 4, 10), "kn_l": 22.0, "ft_l": 10.0,
}

# 맨주먹(피우진 · 구일화 · 경호원): 두 주먹을 턱 앞에, 왼발이 앞
const GUARD_BOX := {
	"pelvis": Vector3(6, 18, 0), "spine": Vector3(4, 4, 0), "chest": Vector3(6, 8, 0), "head": Vector3(-2, -24, 0),
	"sh_r": Vector3(36, 26, 22), "el_r": 128.0, "sh_l": Vector3(52, 34, 16), "el_l": 120.0,
	"th_r": Vector3(-14, -4, 8), "kn_r": 26.0, "ft_r": 10.0, "th_l": Vector3(22, 4, 6), "kn_l": 28.0, "ft_l": -6.0,
}
# 긴 칼(신겐 · 하야부사): 오른손 칼을 비스듬히 앞으로 낮게, 왼손은 비우거나 단도
const GUARD_LONG := {
	"pelvis": Vector3(6, 20, 0), "spine": Vector3(4, 4, 0), "chest": Vector3(4, 10, 0), "head": Vector3(-4, -28, 0),
	"sh_r": Vector3(40, 30, 12), "el_r": 50.0, "wr_r": Vector3(-30, 0, 0), "sh_l": Vector3(36, 30, 14), "el_l": 96.0,
	"th_r": Vector3(24, -4, 6), "kn_r": 28.0, "ft_r": -6.0, "th_l": Vector3(-18, 4, 10), "kn_l": 24.0, "ft_l": 12.0,
}

# 여유 자세(2026-11-12 사용자 "본인보다 레벨이 낮은 캐릭터들만 있으면 굉장히 여유있는 포즈 — 느긋하게 팔을 내리고 있다가 싸울때만"):
# 반쯤 비스듬히 서서 팔을 늘어뜨리고 턱을 조금 든다. 동급 · 윗급 적이 있으면 가드(GUARD_*) — 인형이 둘 사이를 섞는다(puppet_pose calm)
const RELAX := {
	"pelvis": Vector3(0, 12, 0), "spine": Vector3(-2, 2, 0), "chest": Vector3(-4, 4, 0), "head": Vector3(-8, -14, 0),
	"sh_r": Vector3(6, 4, 9), "el_r": 16.0, "sh_l": Vector3(2, -2, 8), "el_l": 12.0,
	"wr_r": Vector3(8, 0, 0), "wr_l": Vector3(6, 0, 0),
	"th_r": Vector3(6, -4, 6), "kn_r": 8.0, "ft_r": -2.0, "th_l": Vector3(-6, 6, 8), "kn_l": 4.0, "ft_l": 2.0,
}

## 공격 자세를 크고 길게 읽히게(2026-11-10 폰 리뷰 "공격 모션이 다 비슷하다") — 인형(src/view/puppet3d.gd _shape_set)이 모양마다
## W · S · F 에 더해 A(예비 동작: 준비 앞에 타격 반대쪽으로 더 감고 가라앉음) · O(지나침: 타격 뒤 같은 쪽으로 더) 를 만든다.
## AMP_TORSO: 가드에서 벗어난 몸통 각도 배율 · AMP_STEP: 내딛기(root_fwd) 배율 · ANTICIPATE · OVERSHOOT: W↔S 차이의 몇 배를 더 감고 · 지나가나 ·
## KEY_MAX: 그 더함의 한도(도) · SINK: 예비 동작에서 두 무릎을 더 굽히는 각도. 모양 표에 "A" · "O" 가 있으면 그 위에 덮는다
const AMP_TORSO := 1.3
const AMP_STEP := 1.3
const ANTICIPATE := 0.35
const OVERSHOOT := 0.25
const KEY_MAX := 24.0
const SINK := 12.0
const TORSO_KEYS := ["pelvis", "spine", "chest", "head"]

const LUNGE_LEGS := {"th_r": Vector3(40, -4, 6), "kn_r": 48.0, "ft_r": -10.0, "th_l": Vector3(-28, 4, 9), "kn_l": 14.0,
	"ft_l": 16.0}

const SHAPES := {
	# 오른손 바로 베기: 오른쪽 뒤 → 왼쪽 앞
	"slash": {
		"W": {"pelvis": Vector3(5, -18, 0), "chest": Vector3(6, -24, 0), "head": Vector3(-4, 30, 0),
			"sh_r": Vector3(34, -48, 80), "el_r": 72.0, "sh_l": Vector3(46, 44, 12), "el_l": 112.0},
		"S": {"pelvis": Vector3(10, 22, 0), "chest": Vector3(10, 28, 0), "head": Vector3(-6, -38, 0),
			"sh_r": Vector3(28, 76, 84), "el_r": 16.0, "root_fwd": 0.08},
		"F": {"pelvis": Vector3(12, 30, 0), "chest": Vector3(12, 42, 0), "head": Vector3(-6, -52, 0),
			"sh_r": Vector3(20, 116, 62), "el_r": 40.0, "root_fwd": 0.08},
	},
	# 왼손 거꾸로 쥔 칼로 되베기 (김신 쌍칼): 왼쪽 뒤 → 오른쪽 앞
	"slash_back_L": {
		"W": {"pelvis": Vector3(5, 20, 0), "chest": Vector3(6, 28, 0), "head": Vector3(-4, -36, 0),
			"sh_l": Vector3(34, -42, 78), "el_l": 82.0, "sh_r": Vector3(42, 30, 16), "el_r": 92.0},
		"S": {"pelvis": Vector3(10, -20, 0), "chest": Vector3(10, -30, 0), "head": Vector3(-6, 36, 0),
			"sh_l": Vector3(28, 76, 86), "el_l": 22.0, "root_fwd": 0.08},
		"F": {"pelvis": Vector3(12, -28, 0), "chest": Vector3(12, -40, 0), "head": Vector3(-6, 48, 0),
			"sh_l": Vector3(20, 112, 60), "el_l": 44.0, "root_fwd": 0.08},
	},
	# 오른손 손등 쪽으로 되베기 (백도찬): 왼쪽 → 오른쪽
	"slash_back_R": {
		"W": {"pelvis": Vector3(5, 24, 0), "chest": Vector3(6, 32, 0), "head": Vector3(-4, -42, 0),
			"sh_r": Vector3(40, 104, 56), "el_r": 88.0},
		"S": {"pelvis": Vector3(10, -14, 0), "chest": Vector3(10, -22, 0), "head": Vector3(-6, 26, 0),
			"sh_r": Vector3(32, 18, 86), "el_r": 14.0, "root_fwd": 0.08},
		"F": {"pelvis": Vector3(10, -24, 0), "chest": Vector3(10, -34, 0), "head": Vector3(-6, 40, 0),
			"sh_r": Vector3(28, -36, 76), "el_r": 26.0, "root_fwd": 0.08},
	},
	"thrust": {
		"W": {"pelvis": Vector3(2, -22, 0), "chest": Vector3(2, -26, 0), "head": Vector3(-4, 34, 0),
			"sh_r": Vector3(-6, -10, 26), "el_r": 116.0, "wr_r": Vector3(-20, 0, 0), "sh_l": Vector3(56, 44, 10),
			"el_l": 106.0, "th_r": Vector3(18, -4, 6), "kn_r": 36.0, "th_l": Vector3(-12, 4, 10), "kn_l": 32.0},
		"S": {"pelvis": Vector3(14, 18, 0), "chest": Vector3(12, 24, 0), "head": Vector3(-10, -30, 0),
			"sh_r": Vector3(84, 12, 6), "el_r": 4.0, "wr_r": Vector3(-30, 0, 0), "sh_l": Vector3(28, 10, 26),
			"el_l": 62.0, "th_r": Vector3(50, -4, 6), "kn_r": 60.0, "th_l": Vector3(-34, 4, 8), "kn_l": 8.0,
			"root_fwd": 0.16},
		"F": {"pelvis": Vector3(12, 14, 0), "chest": Vector3(10, 18, 0), "head": Vector3(-8, -24, 0),
			"sh_r": Vector3(70, 10, 8), "el_r": 22.0, "th_r": Vector3(44, -4, 6), "kn_r": 52.0,
			"th_l": Vector3(-30, 4, 8), "kn_l": 10.0, "root_fwd": 0.12},
	},
	# 엇박 찌르기 (엇엇박도) — 찌르는 오른팔과 오른다리가 같은 쪽으로 깊고 길게 쭉 뻗는다(펜싱 런지처럼). 뒷다리는 곧게,
	# 왼팔은 뒤로 균형. 준비(W)는 뒷다리에 무게를 싣고 칼을 허리 옆으로 당겨 몸을 감는다 (폰 리뷰 3차 2026-10-27)
	"offbeat": {
		"W": {"pelvis": Vector3(4, -30, 0), "chest": Vector3(4, -30, 0), "head": Vector3(-4, 50, 0),
			"sh_r": Vector3(-14, -14, 24), "el_r": 124.0, "wr_r": Vector3(-20, 0, 0), "sh_l": Vector3(50, 40, 12),
			"el_l": 100.0, "th_r": Vector3(12, -4, 6), "kn_r": 44.0, "th_l": Vector3(-8, 4, 10), "kn_l": 46.0},
		"S": {"pelvis": Vector3(22, 34, 0), "spine": Vector3(6, 0, 0), "chest": Vector3(12, 22, 0), "head": Vector3(-20, -52, 0),
			"sh_r": Vector3(88, 4, 2), "el_r": 0.0, "wr_r": Vector3(-24, 0, 0), "sh_l": Vector3(-36, -10, 46), "el_l": 18.0,
			"th_r": Vector3(74, -4, 6), "kn_r": 84.0, "ft_r": -16.0, "th_l": Vector3(-52, 4, 8), "kn_l": 2.0, "ft_l": 28.0,
			"root_fwd": 0.42},
		"F": {"pelvis": Vector3(20, 30, 0), "chest": Vector3(10, 20, 0), "head": Vector3(-18, -46, 0),
			"sh_r": Vector3(80, 4, 4), "el_r": 12.0, "th_r": Vector3(68, -4, 6), "kn_r": 78.0,
			"th_l": Vector3(-48, 4, 8), "kn_l": 6.0, "root_fwd": 0.38},
	},
	# 반대발 엇박 — 디딤발을 바꿔 왼발이 앞, 오른팔로 몸을 가로질러 짧게 찌른다. 엇박보다 작고 빨리 돌아온다
	"offbeat_rev": {
		"W": {"pelvis": Vector3(2, -12, 0), "chest": Vector3(2, -16, 0), "head": Vector3(-4, 24, 0),
			"sh_r": Vector3(0, -8, 24), "el_r": 110.0, "th_r": Vector3(14, -4, 6), "kn_r": 36.0,
			"th_l": Vector3(-10, 4, 10), "kn_l": 34.0},
		"S": {"pelvis": Vector3(10, -14, 0), "chest": Vector3(8, 30, 0), "head": Vector3(-8, -14, 0),
			"sh_r": Vector3(84, 14, 6), "el_r": 6.0, "wr_r": Vector3(-20, 0, 0), "sh_l": Vector3(20, 10, 30), "el_l": 70.0,
			"th_l": Vector3(46, 4, 8), "kn_l": 52.0, "ft_l": -10.0, "th_r": Vector3(-30, -4, 6), "kn_r": 10.0, "ft_r": 16.0,
			"root_fwd": 0.2},
		"F": {"pelvis": Vector3(8, -12, 0), "chest": Vector3(8, 22, 0), "head": Vector3(-6, -10, 0),
			"sh_r": Vector3(66, 10, 8), "el_r": 24.0, "th_l": Vector3(40, 4, 8), "kn_l": 46.0,
			"th_r": Vector3(-26, -4, 6), "kn_r": 12.0, "root_fwd": 0.16},
	},
	# 백도찬식 찌르기 — 낮게 깊이 파고들어 급소
	"thrust_low": {
		"W": {"pelvis": Vector3(16, -26, 0), "chest": Vector3(10, -20, 0), "head": Vector3(-10, 30, 0),
			"sh_r": Vector3(-10, -16, 26), "el_r": 120.0, "kn_r": 56.0, "kn_l": 54.0, "th_r": Vector3(34, -4, 6),
			"th_l": Vector3(-8, 4, 10)},
		"S": {"pelvis": Vector3(30, 16, 0), "chest": Vector3(20, 20, 0), "head": Vector3(-26, -26, 0),
			"sh_r": Vector3(56, 10, 6), "el_r": 4.0, "wr_r": Vector3(-48, 0, 0), "th_r": Vector3(64, -4, 6),
			"kn_r": 88.0, "th_l": Vector3(-38, 4, 8), "kn_l": 24.0, "root_fwd": 0.28},
		"F": {"pelvis": Vector3(26, 12, 0), "chest": Vector3(16, 16, 0), "head": Vector3(-20, -20, 0),
			"sh_r": Vector3(48, 8, 10), "el_r": 20.0, "th_r": Vector3(58, -4, 6), "kn_r": 80.0,
			"th_l": Vector3(-34, 4, 8), "kn_l": 22.0, "root_fwd": 0.24},
	},
	# 백도찬식 옆차기: (발구르며 달려나감은 인형이 따로) → 무릎 접기(W) → 옆으로 곧게(S). 몸은 90도 돌아 오른 허리가 상대 쪽
	"sidekick": {
		"W": {"spin": 86.0, "pelvis": Vector3(-8, 0, -6), "chest": Vector3(-4, 0, -4), "head": Vector3(0, -80, 0),
			"th_r": Vector3(84, 0, 22), "kn_r": 118.0, "ft_r": 30.0, "th_l": Vector3(-4, 0, 6), "kn_l": 24.0,
			"sh_r": Vector3(22, 20, 40), "el_r": 64.0, "sh_l": Vector3(42, 50, 20), "el_l": 120.0},
		"S": {"spin": 92.0, "pelvis": Vector3(0, 0, -30), "chest": Vector3(0, 0, -12), "head": Vector3(0, -84, 6),
			"th_r": Vector3(6, 0, 90), "kn_r": 2.0, "ft_r": 0.0, "th_l": Vector3(0, 0, 10), "kn_l": 18.0,
			"sh_r": Vector3(8, 0, 72), "el_r": 18.0, "sh_l": Vector3(40, 44, 20), "el_l": 118.0},
		"F": {"spin": 80.0, "pelvis": Vector3(-6, 0, -12), "chest": Vector3(-2, 0, -6), "head": Vector3(0, -70, 0),
			"th_r": Vector3(70, 0, 30), "kn_r": 100.0, "th_l": Vector3(-2, 0, 6), "kn_l": 22.0,
			"sh_r": Vector3(22, 20, 40), "el_r": 64.0, "sh_l": Vector3(42, 50, 20), "el_l": 120.0},
	},
	# 살아있는 건 전부 죽여라 — 낮게 웅크렸다(W) 칼을 뻗고 세 바퀴(S) 도는 원형 난도질
	"spin": {
		"W": {"pelvis": Vector3(22, -50, 0), "chest": Vector3(12, -30, 0), "head": Vector3(-12, 60, 0),
			"sh_r": Vector3(12, -64, 70), "el_r": 30.0, "sh_l": Vector3(40, 50, 20), "el_l": 100.0,
			"kn_r": 58.0, "kn_l": 56.0, "th_r": Vector3(36, -4, 10), "th_l": Vector3(-6, 4, 14)},
		"S": {"pelvis": Vector3(10, 0, 0), "chest": Vector3(6, 0, 0), "head": Vector3(-4, 0, 0),
			"sh_r": Vector3(6, 0, 92), "el_r": 6.0, "sh_l": Vector3(6, 0, 86), "el_l": 12.0,
			"kn_r": 34.0, "kn_l": 30.0, "th_r": Vector3(20, -4, 12), "th_l": Vector3(-10, 4, 14)},
		"F": {"pelvis": Vector3(6, 10, 0), "chest": Vector3(4, 10, 0), "sh_r": Vector3(14, 30, 70), "el_r": 30.0,
			"sh_l": Vector3(30, 40, 30), "el_l": 80.0},
	},
	# 각법 — 오른 다리를 머리 위까지 곧게 들어 올렸다가(W) 바닥까지 내려찍는다(S). 몸은 크게 젖혔다가 앞으로 접히고,
	# 디딤 무릎이 깊이 굽는다. 두 팔은 옆으로 넓게 균형 (폰 리뷰 3차: 동작을 더 크게)
	"axe": {
		"W": {"pelvis": Vector3(-22, 8, 0), "spine": Vector3(-10, 0, 0), "chest": Vector3(-12, 4, 0), "head": Vector3(18, -10, 0),
			"th_r": Vector3(176, -6, 4), "kn_r": 0.0, "ft_r": -30.0, "th_l": Vector3(-8, 4, 6), "kn_l": 22.0, "ft_l": 10.0,
			"sh_r": Vector3(30, -30, 80), "el_r": 30.0, "sh_l": Vector3(40, 20, 76), "el_l": 40.0},
		"S": {"pelvis": Vector3(30, 8, 0), "spine": Vector3(10, 0, 0), "chest": Vector3(20, 4, 0), "head": Vector3(-24, -10, 0),
			"th_r": Vector3(24, -4, 6), "kn_r": 4.0, "ft_r": -8.0, "th_l": Vector3(-24, 4, 6), "kn_l": 70.0, "ft_l": 20.0,
			"sh_r": Vector3(-10, -10, 56), "el_r": 30.0, "sh_l": Vector3(0, 20, 54), "el_l": 40.0, "root_fwd": 0.2},
		"F": {"pelvis": Vector3(24, 8, 0), "chest": Vector3(16, 4, 0), "head": Vector3(-18, -10, 0),
			"th_r": Vector3(26, -4, 6), "kn_r": 40.0, "th_l": Vector3(-22, 4, 8), "kn_l": 50.0, "root_fwd": 0.16},
	},
	# 주먹 (리천식 삼연타 — 인형이 한 대마다 오른손 · 왼손을 번갈아 내지른다). 몸통을 크게 비틀고 한 발씩 내딛는다
	"punch": {
		"W": {"pelvis": Vector3(6, -30, 0), "chest": Vector3(6, -34, 0), "head": Vector3(-6, 44, 0),
			"sh_r": Vector3(24, -14, 18), "el_r": 130.0, "sh_l": Vector3(54, 30, 12), "el_l": 108.0,
			"th_r": Vector3(16, -4, 6), "kn_r": 40.0},
		"S": {"pelvis": Vector3(12, 32, 0), "chest": Vector3(10, 36, 0), "head": Vector3(-10, -50, 0),
			"sh_r": Vector3(90, 8, 2), "el_r": 0.0, "th_r": Vector3(46, -4, 6), "kn_r": 56.0, "th_l": Vector3(-30, 4, 8),
			"kn_l": 12.0, "root_fwd": 0.2},
		"F": {"sh_r": Vector3(64, 10, 10), "el_r": 40.0},
	},
	# 총(경호대 최후의 4인): 오른팔을 곧게 뻗어 겨눈다 — 왼손 총은 인형이 좌우로 뒤집는다(shot_L)
	"shot": {
		"W": {"pelvis": Vector3(2, -24, 0), "chest": Vector3(2, -28, 0), "head": Vector3(-4, 30, 0),
			"sh_r": Vector3(86, 6, 4), "el_r": 4.0, "wr_r": Vector3(-40, 0, 0)},
		"S": {"pelvis": Vector3(-2, -24, 0), "chest": Vector3(-6, -28, 0), "head": Vector3(-2, 30, 0),
			"sh_r": Vector3(98, 6, 4), "el_r": 10.0, "wr_r": Vector3(-60, 0, 0)},
		"F": {"sh_r": Vector3(80, 6, 6), "el_r": 20.0, "wr_r": Vector3(-30, 0, 0)},
	},
	# 제압 — 두 칼을 높이 엇갈려 들었다가 X 자로 내리벤다
	"cross": {
		"W": {"pelvis": Vector3(-6, 0, 0), "chest": Vector3(-8, 0, 0), "head": Vector3(-6, 0, 0),
			"sh_r": Vector3(150, 34, 22), "el_r": 52.0, "sh_l": Vector3(150, 34, 22), "el_l": 52.0,
			"kn_r": 30.0, "kn_l": 30.0},
		"S": {"pelvis": Vector3(26, 0, 0), "chest": Vector3(16, 0, 0), "head": Vector3(-14, 0, 0),
			"sh_r": Vector3(42, -56, 70), "el_r": 10.0, "sh_l": Vector3(42, -56, 70), "el_l": 10.0,
			"th_r": Vector3(46, -4, 6), "kn_r": 62.0, "th_l": Vector3(-30, 4, 8), "kn_l": 10.0, "root_fwd": 0.22},
		"F": {"pelvis": Vector3(22, 0, 0), "chest": Vector3(14, 0, 0), "head": Vector3(-12, 0, 0),
			"sh_r": Vector3(30, -60, 64), "el_r": 20.0, "sh_l": Vector3(30, -60, 64), "el_l": 20.0,
			"th_r": Vector3(44, -4, 6), "kn_r": 58.0, "th_l": Vector3(-28, 4, 8), "kn_l": 12.0, "root_fwd": 0.2},
	},
	# ---- 맨손 · 발 · 잡기 · 피하기 · 무기 모양 (2026-11-10 — 기술마다 동작이 달라 보이게. 모두 오른손 · 오른발 기준,
	#      왼손 · 왼발 판은 인형이 좌우로 뒤집는다(MIRROR — 이름 + "_L"). 다리는 가드(칼 · 주먹 · 긴 칼)마다 달라 거의 다 적는다)
	# 잽: 몸을 거의 안 돌리고 짧고 빠르게 곧게 뻗었다 바로 거둔다
	"jab": {
		"W": {"pelvis": Vector3(4, -8, 0), "chest": Vector3(4, -10, 0), "head": Vector3(-2, 14, 0),
			"sh_r": Vector3(34, 18, 22), "el_r": 132.0, "sh_l": Vector3(54, 34, 16), "el_l": 120.0,
			"th_r": Vector3(14, -4, 6), "kn_r": 30.0, "ft_r": -4.0, "th_l": Vector3(-10, 4, 8), "kn_l": 26.0, "ft_l": 8.0},
		"S": {"pelvis": Vector3(6, 12, 0), "chest": Vector3(6, 16, 0), "head": Vector3(-4, -24, 0),
			"sh_r": Vector3(86, 8, 4), "el_r": 4.0, "th_r": Vector3(28, -4, 6), "kn_r": 34.0,
			"th_l": Vector3(-18, 4, 8), "kn_l": 14.0, "root_fwd": 0.1},
		"F": {"sh_r": Vector3(56, 16, 14), "el_r": 80.0, "root_fwd": 0.06},
	},
	# 스트레이트: 뒷발로 바닥을 밀고 허리 · 어깨를 크게 돌려 뒷손을 끝까지 꽂는다 (왼발 앞)
	"straight": {
		"W": {"pelvis": Vector3(6, -28, 0), "chest": Vector3(6, -32, 0), "head": Vector3(-6, 40, 0),
			"sh_r": Vector3(26, -12, 18), "el_r": 132.0, "sh_l": Vector3(56, 34, 14), "el_l": 116.0,
			"th_r": Vector3(-14, -4, 8), "kn_r": 30.0, "ft_r": 10.0, "th_l": Vector3(24, 4, 6), "kn_l": 34.0, "ft_l": -6.0},
		"S": {"pelvis": Vector3(14, 36, 0), "chest": Vector3(12, 40, 0), "head": Vector3(-12, -56, 0),
			"sh_r": Vector3(92, 6, 0), "el_r": 0.0, "sh_l": Vector3(40, 40, 20), "el_l": 124.0,
			"th_r": Vector3(-30, -4, 6), "kn_r": 10.0, "ft_r": 26.0, "th_l": Vector3(46, 4, 6), "kn_l": 50.0, "ft_l": -10.0,
			"root_fwd": 0.22},
		"F": {"sh_r": Vector3(70, 10, 8), "el_r": 36.0, "root_fwd": 0.18},
	},
	# 훅: 위팔을 옆으로 들고 팔꿈치를 직각으로 굽힌 채 허리를 돌려 옆에서 휘감아 친다
	"hook": {
		"W": {"pelvis": Vector3(6, -22, 0), "chest": Vector3(4, -28, 0), "head": Vector3(-4, 32, 0),
			"sh_r": Vector3(10, -24, 72), "el_r": 96.0, "sh_l": Vector3(54, 34, 14), "el_l": 118.0,
			"th_r": Vector3(10, -4, 8), "kn_r": 36.0, "th_l": Vector3(14, 4, 6), "kn_l": 34.0},
		"S": {"pelvis": Vector3(10, 40, 0), "chest": Vector3(8, 48, -6), "head": Vector3(-6, -66, 0),
			"sh_r": Vector3(12, 66, 84), "el_r": 92.0, "sh_l": Vector3(50, 30, 18), "el_l": 124.0,
			"th_r": Vector3(8, -4, 8), "kn_r": 40.0, "ft_r": 10.0, "th_l": Vector3(18, 4, 6), "kn_l": 32.0, "root_fwd": 0.08},
		"F": {"pelvis": Vector3(10, 46, 0), "chest": Vector3(8, 56, -4), "head": Vector3(-6, -72, 0),
			"sh_r": Vector3(16, 90, 70), "el_r": 100.0},
	},
	# 어퍼컷: 오른 어깨를 떨구고 무릎을 굽혀 가라앉았다가 다리를 펴며 턱 밑에서 위로 쳐올린다
	"uppercut": {
		"W": {"pelvis": Vector3(14, -20, 0), "chest": Vector3(10, -24, 10), "head": Vector3(-8, 30, -4),
			"sh_r": Vector3(-6, -6, 16), "el_r": 104.0, "sh_l": Vector3(56, 34, 14), "el_l": 120.0,
			"th_r": Vector3(30, -4, 8), "kn_r": 54.0, "th_l": Vector3(14, 4, 8), "kn_l": 50.0},
		"S": {"pelvis": Vector3(-4, 30, 0), "chest": Vector3(-8, 34, -4), "head": Vector3(-12, -44, 0),
			"sh_r": Vector3(52, 18, 8), "el_r": 112.0, "wr_r": Vector3(10, 0, 0),
			"th_r": Vector3(8, -4, 6), "kn_r": 12.0, "ft_r": 10.0, "th_l": Vector3(-4, 4, 8), "kn_l": 18.0, "ft_l": 18.0,
			"root_fwd": 0.08},
		"F": {"sh_r": Vector3(70, 14, 10), "el_r": 120.0, "chest": Vector3(-10, 30, 0)},
	},
	# 바디 블로: 무릎을 깊이 굽혀 몸을 낮추고 옆구리 · 명치에 짧게 꽂는다
	"body_blow": {
		"W": {"pelvis": Vector3(12, -24, 0), "chest": Vector3(8, -28, 0), "head": Vector3(-10, 34, 0),
			"sh_r": Vector3(16, -14, 22), "el_r": 116.0, "sh_l": Vector3(56, 34, 14), "el_l": 120.0,
			"th_r": Vector3(30, -4, 8), "kn_r": 50.0, "th_l": Vector3(4, 4, 8), "kn_l": 44.0},
		"S": {"pelvis": Vector3(18, 30, 0), "chest": Vector3(10, 34, 0), "head": Vector3(-16, -44, 0),
			"sh_r": Vector3(70, 22, 8), "el_r": 34.0, "sh_l": Vector3(50, 36, 16), "el_l": 126.0,
			"th_r": Vector3(54, -4, 6), "kn_r": 70.0, "th_l": Vector3(-16, 4, 8), "kn_l": 30.0, "root_fwd": 0.2},
		"F": {"sh_r": Vector3(50, 20, 14), "el_r": 70.0},
	},
	# 팔꿈치: 주먹을 귀 옆으로 접어 든 팔꿈치를 허리를 돌려 수평으로 휘두른다
	"elbow": {
		"W": {"pelvis": Vector3(4, -22, 0), "chest": Vector3(4, -28, 0), "head": Vector3(-4, 34, 0),
			"sh_r": Vector3(16, -30, 74), "el_r": 146.0, "sh_l": Vector3(54, 34, 14), "el_l": 120.0,
			"th_r": Vector3(12, -4, 8), "kn_r": 34.0, "th_l": Vector3(14, 4, 6), "kn_l": 32.0},
		"S": {"pelvis": Vector3(8, 36, 0), "chest": Vector3(8, 46, 0), "head": Vector3(-6, -62, 0),
			"sh_r": Vector3(12, 70, 86), "el_r": 150.0, "sh_l": Vector3(44, 30, 20), "el_l": 124.0,
			"th_r": Vector3(24, -4, 8), "kn_r": 42.0, "th_l": Vector3(-6, 4, 6), "kn_l": 24.0, "root_fwd": 0.14},
		"F": {"sh_r": Vector3(14, 84, 76), "el_r": 140.0},
	},
	# 무릎: 두 손으로 상대 목을 잡아 끌어내리며 무릎을 높이 올려 찍는다 (디딤발은 발끝)
	"knee": {
		"W": {"pelvis": Vector3(-2, 0, 0), "chest": Vector3(4, 0, 0), "head": Vector3(-6, 0, 0),
			"sh_r": Vector3(82, 26, 10), "el_r": 64.0, "sh_l": Vector3(82, 26, 10), "el_l": 64.0,
			"th_r": Vector3(-20, -4, 6), "kn_r": 44.0, "ft_r": 20.0, "th_l": Vector3(10, 4, 6), "kn_l": 26.0, "ft_l": 0.0},
		"S": {"pelvis": Vector3(-10, 0, 0), "chest": Vector3(14, 0, 0), "head": Vector3(-8, 0, 0),
			"sh_r": Vector3(56, 22, 14), "el_r": 104.0, "sh_l": Vector3(56, 22, 14), "el_l": 104.0,
			"th_r": Vector3(96, -4, 6), "kn_r": 120.0, "ft_r": 30.0, "th_l": Vector3(-8, 4, 6), "kn_l": 8.0, "ft_l": 24.0,
			"root_fwd": 0.12},
		"F": {"th_r": Vector3(50, -4, 6), "kn_r": 80.0, "root_fwd": 0.1},
	},
	# 날아 무릎: 웅크렸다 뛰어올라(root_y) 오른 무릎을 앞으로 내지르고, 두 팔은 위로 끌어올린다
	"flying_knee": {
		"W": {"pelvis": Vector3(16, 0, 0), "chest": Vector3(10, 0, 0), "head": Vector3(-14, 0, 0),
			"sh_r": Vector3(-30, 0, 18), "el_r": 30.0, "sh_l": Vector3(-30, 0, 18), "el_l": 30.0,
			"th_r": Vector3(52, -4, 6), "kn_r": 72.0, "th_l": Vector3(36, 4, 6), "kn_l": 70.0},
		"S": {"pelvis": Vector3(-12, 0, 0), "chest": Vector3(8, 0, 0), "head": Vector3(-6, 0, 0),
			"sh_r": Vector3(104, 26, 18), "el_r": 82.0, "sh_l": Vector3(104, 26, 18), "el_l": 82.0,
			"th_r": Vector3(104, -4, 6), "kn_r": 130.0, "ft_r": 30.0, "th_l": Vector3(-22, 4, 6), "kn_l": 76.0, "ft_l": 30.0,
			"root_y": 0.45, "root_fwd": 0.25},
		"F": {"th_r": Vector3(40, -4, 6), "kn_r": 60.0, "th_l": Vector3(10, 4, 6), "kn_l": 40.0, "root_y": 0.08,
			"sh_r": Vector3(50, 20, 20), "el_r": 90.0, "sh_l": Vector3(50, 20, 20), "el_l": 90.0},
	},
	# 박치기: 두 손으로 상대를 잡고 몸을 젖혔다가 이마로 내리박는다
	"headbutt": {
		"W": {"pelvis": Vector3(-6, 0, 0), "chest": Vector3(-14, 0, 0), "head": Vector3(-12, 0, 0),
			"sh_r": Vector3(58, 24, 12), "el_r": 50.0, "sh_l": Vector3(58, 24, 12), "el_l": 50.0,
			"th_r": Vector3(16, -4, 6), "kn_r": 26.0, "th_l": Vector3(-10, 4, 8), "kn_l": 22.0},
		"S": {"pelvis": Vector3(14, 0, 0), "chest": Vector3(22, 0, 0), "head": Vector3(30, 0, 0),
			"sh_r": Vector3(52, 22, 16), "el_r": 112.0, "sh_l": Vector3(52, 22, 16), "el_l": 112.0,
			"th_r": Vector3(36, -4, 6), "kn_r": 40.0, "th_l": Vector3(-18, 4, 8), "kn_l": 12.0, "root_fwd": 0.16},
		"F": {"head": Vector3(14, 0, 0), "chest": Vector3(12, 0, 0)},
	},
	# 장타: 손목을 젖혀 손바닥 아래쪽(손꿈치)으로 곧게 밀어 친다
	"palm": {
		"W": {"pelvis": Vector3(4, -22, 0), "chest": Vector3(4, -26, 0), "head": Vector3(-4, 32, 0),
			"sh_r": Vector3(20, -10, 20), "el_r": 124.0, "wr_r": Vector3(60, 0, 0), "sh_l": Vector3(54, 34, 14), "el_l": 116.0,
			"th_r": Vector3(-8, -4, 8), "kn_r": 34.0, "th_l": Vector3(20, 4, 6), "kn_l": 36.0},
		"S": {"pelvis": Vector3(10, 28, 0), "chest": Vector3(8, 32, 0), "head": Vector3(-8, -44, 0),
			"sh_r": Vector3(84, 6, 4), "el_r": 6.0, "wr_r": Vector3(76, 0, 0), "sh_l": Vector3(30, 20, 30), "el_l": 70.0,
			"th_r": Vector3(-24, -4, 6), "kn_r": 14.0, "ft_r": 20.0, "th_l": Vector3(42, 4, 6), "kn_l": 50.0, "root_fwd": 0.2},
		"F": {"sh_r": Vector3(74, 6, 6), "el_r": 20.0, "wr_r": Vector3(50, 0, 0)},
	},
	# 메주먹: 주먹을 머리 위로 들었다가 망치처럼 내리친다
	"hammer_fist": {
		"W": {"pelvis": Vector3(-4, -10, 0), "chest": Vector3(-8, -12, 0), "head": Vector3(-4, 16, 0),
			"sh_r": Vector3(164, 12, 16), "el_r": 76.0, "sh_l": Vector3(50, 30, 16), "el_l": 110.0,
			"th_r": Vector3(10, -4, 6), "kn_r": 22.0, "th_l": Vector3(-6, 4, 8), "kn_l": 22.0},
		"S": {"pelvis": Vector3(16, 10, 0), "chest": Vector3(18, 14, 0), "head": Vector3(-14, -16, 0),
			"sh_r": Vector3(48, 10, 10), "el_r": 18.0, "sh_l": Vector3(20, 10, 30), "el_l": 70.0,
			"th_r": Vector3(40, -4, 6), "kn_r": 52.0, "th_l": Vector3(-10, 4, 8), "kn_l": 34.0, "root_fwd": 0.12},
		"F": {"sh_r": Vector3(36, 10, 14), "el_r": 30.0},
	},
	# 앞차기: 무릎을 가슴까지 접어 올렸다가(W) 몸을 조금 젖히며 발바닥으로 곧게 밀어 찬다
	"front_kick": {
		"W": {"pelvis": Vector3(-6, 0, 0), "chest": Vector3(-2, 0, 0), "head": Vector3(-4, 0, 0),
			"th_r": Vector3(92, -4, 6), "kn_r": 112.0, "ft_r": 20.0, "th_l": Vector3(-6, 4, 6), "kn_l": 22.0, "ft_l": 0.0},
		"S": {"pelvis": Vector3(-16, 0, 0), "chest": Vector3(-8, 0, 0), "head": Vector3(14, 0, 0),
			"th_r": Vector3(80, -4, 6), "kn_r": 4.0, "ft_r": -24.0, "th_l": Vector3(-14, 4, 6), "kn_l": 14.0,
			"sh_r": Vector3(20, 10, 40), "el_r": 70.0, "root_fwd": 0.1},
		"F": {"th_r": Vector3(70, -4, 6), "kn_r": 90.0, "pelvis": Vector3(-8, 0, 0), "chest": Vector3(-4, 0, 0)},
	},
	# 돌려차기: 디딤발로 돌며(spin) 몸을 옆으로 눕히고, 접은 무릎을 옆에서 펴며 정강이 · 발등으로 수평으로 휘감아 찬다
	"round_kick": {
		"W": {"spin": 34.0, "pelvis": Vector3(0, 0, -8), "chest": Vector3(0, 0, -4), "head": Vector3(-4, -34, 0),
			"th_r": Vector3(40, -30, 56), "kn_r": 112.0, "ft_r": 20.0, "th_l": Vector3(-4, 4, 6), "kn_l": 24.0,
			"sh_r": Vector3(20, 10, 40), "el_r": 80.0},
		"S": {"spin": 70.0, "pelvis": Vector3(-4, 0, -26), "chest": Vector3(-2, 0, -14), "head": Vector3(0, -62, 8),
			"th_r": Vector3(10, 40, 84), "kn_r": 8.0, "ft_r": -20.0, "th_l": Vector3(0, 4, 8), "kn_l": 16.0, "ft_l": 0.0,
			"sh_r": Vector3(-20, -10, 50), "el_r": 30.0, "sh_l": Vector3(52, 46, 20), "el_l": 118.0, "root_fwd": 0.08},
		"F": {"spin": 86.0, "th_r": Vector3(20, 60, 60), "kn_r": 80.0, "pelvis": Vector3(-2, 0, -14)},
	},
	# 로킥: 몸을 조금 돌리며 정강이로 상대 허벅지를 낮게 깎아 찬다
	"low_kick": {
		"W": {"spin": 12.0, "pelvis": Vector3(4, -12, 0), "chest": Vector3(4, -14, 0), "head": Vector3(-4, 4, 0),
			"th_r": Vector3(6, -24, 30), "kn_r": 70.0, "ft_r": 20.0, "th_l": Vector3(10, 4, 6), "kn_l": 32.0},
		"S": {"spin": 44.0, "pelvis": Vector3(6, 0, -16), "chest": Vector3(4, 0, -8), "head": Vector3(-4, -40, 0),
			"th_r": Vector3(36, 46, 36), "kn_r": 10.0, "ft_r": -14.0, "th_l": Vector3(4, 4, 6), "kn_l": 26.0,
			"sh_r": Vector3(-14, -20, 36), "el_r": 50.0, "root_fwd": 0.06},
		"F": {"spin": 50.0, "th_r": Vector3(20, 60, 24), "kn_r": 50.0},
	},
	# 뒤돌려차기: 등을 보이며 한 바퀴 돌아(spin — 회수 동안 마저 돈다, SPIN_THROUGH) 상체를 숙이고 뒤로 곧게 뻗어 찬다
	"spin_back_kick": {
		"W": {"spin": -110.0, "pelvis": Vector3(12, 0, 0), "chest": Vector3(8, 0, 0), "head": Vector3(-4, 70, 0),
			"th_r": Vector3(40, -4, 6), "kn_r": 100.0, "ft_r": 10.0, "th_l": Vector3(10, 4, 6), "kn_l": 30.0,
			"sh_r": Vector3(40, 30, 30), "el_r": 100.0, "sh_l": Vector3(40, 30, 30), "el_l": 100.0},
		"S": {"spin": -180.0, "pelvis": Vector3(36, 0, 0), "chest": Vector3(14, 0, 0), "head": Vector3(-26, 70, 0),
			"th_r": Vector3(-52, 0, 6), "kn_r": 4.0, "ft_r": 30.0, "th_l": Vector3(36, 4, 6), "kn_l": 26.0,
			"sh_r": Vector3(30, 30, 40), "el_r": 90.0, "sh_l": Vector3(40, 30, 30), "el_l": 110.0, "root_fwd": 0.14},
		"F": {"spin": -240.0, "pelvis": Vector3(20, 0, 0), "chest": Vector3(8, 0, 0), "head": Vector3(-14, 50, 0),
			"th_r": Vector3(-10, 0, 6), "kn_r": 60.0},
	},
	# 내려찍기(발): 다리를 머리 높이까지 곧게 올렸다가 뒤꿈치로 내리찍는다 — 각법(axe)보다 작고 빠르다(바닥 충격 없음)
	"axe_kick": {
		"W": {"pelvis": Vector3(-16, 6, 0), "chest": Vector3(-8, 4, 0), "head": Vector3(12, -8, 0),
			"th_r": Vector3(146, -8, 14), "kn_r": 8.0, "ft_r": -20.0, "th_l": Vector3(-6, 4, 6), "kn_l": 18.0, "ft_l": 10.0,
			"sh_r": Vector3(24, -20, 64), "el_r": 30.0, "sh_l": Vector3(36, 20, 60), "el_l": 40.0},
		"S": {"pelvis": Vector3(18, 6, 0), "chest": Vector3(14, 4, 0), "head": Vector3(-14, -8, 0),
			"th_r": Vector3(40, -4, 6), "kn_r": 8.0, "ft_r": -10.0, "th_l": Vector3(-6, 4, 6), "kn_l": 46.0, "ft_l": 16.0,
			"sh_r": Vector3(0, -10, 44), "el_r": 30.0, "sh_l": Vector3(10, 20, 44), "el_l": 40.0, "root_fwd": 0.14},
		"F": {"th_r": Vector3(30, -4, 6), "kn_r": 40.0, "kn_l": 36.0},
	},
	# 날아차기: 웅크렸다 뛰어올라(root_y) 왼 무릎은 접고 오른발을 곧게 앞으로 내지른다
	"flying_kick": {
		"W": {"pelvis": Vector3(16, 0, 0), "chest": Vector3(10, 0, 0), "head": Vector3(-14, 0, 0),
			"sh_r": Vector3(-30, 0, 18), "el_r": 30.0, "sh_l": Vector3(-30, 0, 18), "el_l": 30.0,
			"th_r": Vector3(52, -4, 6), "kn_r": 72.0, "th_l": Vector3(36, 4, 6), "kn_l": 70.0},
		"S": {"pelvis": Vector3(-22, 0, 0), "chest": Vector3(-6, 0, 0), "head": Vector3(18, 0, 0),
			"th_r": Vector3(84, -4, 6), "kn_r": 0.0, "ft_r": -24.0, "th_l": Vector3(70, 4, 6), "kn_l": 124.0, "ft_l": 20.0,
			"sh_r": Vector3(20, -10, 56), "el_r": 40.0, "sh_l": Vector3(70, 30, 20), "el_l": 90.0,
			"root_y": 0.55, "root_fwd": 0.35},
		"F": {"th_r": Vector3(40, -4, 6), "kn_r": 50.0, "th_l": Vector3(10, 4, 6), "kn_l": 40.0, "root_y": 0.1,
			"pelvis": Vector3(6, 0, 0), "chest": Vector3(4, 0, 0), "head": Vector3(-4, 0, 0)},
	},
	# 다리 쓸기: 왼 다리로 깊이 주저앉아 몸을 돌리며(spin) 곧게 편 오른 다리로 바닥을 쓴다 — 손 하나는 바닥 짚기
	"sweep": {
		"W": {"pelvis": Vector3(26, 0, 0), "chest": Vector3(14, 0, 0), "head": Vector3(-30, 0, 0),
			"th_l": Vector3(110, 4, 14), "kn_l": 130.0, "ft_l": -20.0, "th_r": Vector3(18, -10, 68), "kn_r": 6.0,
			"sh_r": Vector3(40, 0, 30), "el_r": 20.0, "sh_l": Vector3(54, 34, 14), "el_l": 110.0},
		"S": {"spin": 70.0, "pelvis": Vector3(30, 0, -10), "chest": Vector3(14, 0, -6), "head": Vector3(-34, -50, 0),
			"th_l": Vector3(112, 4, 16), "kn_l": 134.0, "ft_l": -20.0, "th_r": Vector3(40, 30, 80), "kn_r": 0.0, "ft_r": 0.0,
			"sh_r": Vector3(50, -10, 40), "el_r": 10.0, "sh_l": Vector3(60, 30, 20), "el_l": 90.0},
		"F": {"spin": 100.0, "th_r": Vector3(50, 50, 60), "kn_r": 30.0},
	},
	# 태클: 몸을 낮춰 고개를 들고 상대 허리로 어깨부터 파고들며 두 팔로 감싼다
	"tackle": {
		"W": {"pelvis": Vector3(30, 0, 0), "chest": Vector3(16, 0, 0), "head": Vector3(-34, 0, 0),
			"sh_r": Vector3(40, 10, 30), "el_r": 50.0, "sh_l": Vector3(40, 10, 30), "el_l": 50.0,
			"th_r": Vector3(80, -4, 6), "kn_r": 84.0, "th_l": Vector3(30, 4, 6), "kn_l": 60.0},
		"S": {"pelvis": Vector3(40, 0, 0), "chest": Vector3(20, 0, 0), "head": Vector3(-44, 0, 0),
			"sh_r": Vector3(70, 40, 24), "el_r": 96.0, "sh_l": Vector3(70, 40, 24), "el_l": 96.0,
			"th_r": Vector3(96, -4, 6), "kn_r": 100.0, "ft_r": -10.0, "th_l": Vector3(4, 4, 6), "kn_l": 12.0, "ft_l": 30.0,
			"root_fwd": 0.42},
		"F": {"root_fwd": 0.36},
	},
	# 잡기: 두 손을 뻗어 멱살 · 머리를 움켜쥐고(W) 몸을 젖히며 끌어당긴다(S)
	"grab": {
		"W": {"pelvis": Vector3(10, 0, 0), "chest": Vector3(8, 0, 0), "head": Vector3(-8, 0, 0),
			"sh_r": Vector3(80, 18, 12), "el_r": 24.0, "sh_l": Vector3(80, 18, 12), "el_l": 24.0,
			"wr_r": Vector3(30, 0, 0), "wr_l": Vector3(30, 0, 0),
			"th_r": Vector3(34, -4, 6), "kn_r": 36.0, "th_l": Vector3(-14, 4, 8), "kn_l": 14.0, "root_fwd": 0.12},
		"S": {"pelvis": Vector3(-6, 0, 0), "chest": Vector3(-10, 0, 0), "head": Vector3(4, 0, 0),
			"sh_r": Vector3(40, 24, 16), "el_r": 100.0, "sh_l": Vector3(40, 24, 16), "el_l": 100.0,
			"th_r": Vector3(10, -4, 6), "kn_r": 22.0, "th_l": Vector3(-26, 4, 8), "kn_l": 34.0, "root_fwd": 0.0},
		"F": {"sh_r": Vector3(36, 24, 16), "el_r": 104.0, "sh_l": Vector3(36, 24, 16), "el_l": 104.0},
	},
	# 메치기: 상대를 머리 위로 들어 올려(W — 몸을 젖히고 두 팔을 높이) 상체를 크게 숙이며 바닥에 내리꽂는다(S)
	"throw_slam": {
		"W": {"pelvis": Vector3(-8, 0, 0), "chest": Vector3(-20, 0, 0), "head": Vector3(-10, 0, 0),
			"sh_r": Vector3(156, 20, 18), "el_r": 50.0, "sh_l": Vector3(156, 20, 18), "el_l": 50.0,
			"th_r": Vector3(12, -4, 8), "kn_r": 34.0, "th_l": Vector3(-4, 4, 8), "kn_l": 30.0},
		"S": {"pelvis": Vector3(36, 0, 0), "spine": Vector3(10, 0, 0), "chest": Vector3(26, 0, 0), "head": Vector3(-30, 0, 0),
			"sh_r": Vector3(34, 20, 18), "el_r": 20.0, "sh_l": Vector3(34, 20, 18), "el_l": 20.0,
			"th_r": Vector3(86, -4, 6), "kn_r": 96.0, "th_l": Vector3(20, 4, 8), "kn_l": 84.0, "ft_l": 20.0, "root_fwd": 0.24},
		"F": {"pelvis": Vector3(30, 0, 0), "chest": Vector3(20, 0, 0)},
	},
	# 목 조르기(뒤에서): 두 팔로 목을 감아(W) 팔을 조이며 몸을 뒤로 젖혀 끌어당긴다(S)
	"choke": {
		"W": {"pelvis": Vector3(6, 0, 0), "chest": Vector3(6, 0, 0), "head": Vector3(-4, 0, 0),
			"sh_r": Vector3(62, 44, 24), "el_r": 104.0, "sh_l": Vector3(62, 44, 24), "el_l": 104.0,
			"th_r": Vector3(24, -4, 6), "kn_r": 30.0, "th_l": Vector3(-14, 4, 8), "kn_l": 20.0, "root_fwd": 0.1},
		"S": {"pelvis": Vector3(-6, 0, 0), "chest": Vector3(-12, 0, 0), "head": Vector3(4, 16, 0),
			"sh_r": Vector3(54, 60, 20), "el_r": 124.0, "sh_l": Vector3(58, 54, 22), "el_l": 120.0,
			"th_r": Vector3(16, -4, 6), "kn_r": 34.0, "th_l": Vector3(-24, 4, 8), "kn_l": 30.0, "root_fwd": 0.06},
		"F": {"chest": Vector3(-14, 0, 0)},
	},
	# 숙이기: 무릎과 허리를 깊이 굽혀 머리 · 상체를 숙여 흘린다(W) — 숙인 채 올라오며 반격 준비(S)
	"duck": {
		"W": {"pelvis": Vector3(30, 0, 0), "chest": Vector3(22, 0, 0), "head": Vector3(-30, 0, 0),
			"sh_r": Vector3(46, 30, 16), "el_r": 132.0, "sh_l": Vector3(46, 30, 16), "el_l": 132.0,
			"th_r": Vector3(74, -4, 8), "kn_r": 84.0, "th_l": Vector3(44, 4, 8), "kn_l": 80.0},
		"S": {"pelvis": Vector3(20, 16, 0), "chest": Vector3(14, 20, 0), "head": Vector3(-20, -24, 0),
			"sh_r": Vector3(40, 22, 18), "el_r": 128.0, "sh_l": Vector3(54, 34, 14), "el_l": 120.0,
			"th_r": Vector3(54, -4, 8), "kn_r": 64.0, "th_l": Vector3(20, 4, 8), "kn_l": 50.0},
		"F": {"pelvis": Vector3(12, 14, 0), "chest": Vector3(8, 16, 0), "kn_r": 44.0, "kn_l": 36.0},
	},
	# 흔들기(위빙): 무릎을 굽힌 채 상체를 왼쪽으로(W) → 오른쪽으로(S) U 자로 흔들어 흘린다
	"weave": {
		"W": {"pelvis": Vector3(16, 0, -12), "chest": Vector3(14, -12, -24), "head": Vector3(-14, 12, 12),
			"sh_r": Vector3(46, 30, 16), "el_r": 128.0, "sh_l": Vector3(50, 34, 14), "el_l": 124.0,
			"th_r": Vector3(36, -4, 10), "kn_r": 56.0, "th_l": Vector3(26, 4, 14), "kn_l": 54.0},
		"S": {"pelvis": Vector3(16, 0, 12), "chest": Vector3(14, 12, 24), "head": Vector3(-14, -12, -12),
			"th_r": Vector3(26, -4, 14), "kn_r": 54.0, "th_l": Vector3(36, 4, 10), "kn_l": 56.0},
		"F": {"pelvis": Vector3(10, 0, 4), "chest": Vector3(8, 4, 8), "head": Vector3(-8, -4, -4)},
	},
	# 비켜서기: 오른발을 옆으로 내디뎌(W) 몸을 돌려 상대 선 밖으로 빠진다(S) — 눈은 상대에게
	"sidestep": {
		"W": {"pelvis": Vector3(6, 0, 10), "chest": Vector3(4, 0, -8), "head": Vector3(-4, 0, -4),
			"th_r": Vector3(6, -4, 34), "kn_r": 18.0, "th_l": Vector3(-4, 4, 4), "kn_l": 38.0},
		"S": {"spin": 40.0, "pelvis": Vector3(8, 0, -8), "chest": Vector3(6, -10, -4), "head": Vector3(-6, -32, 0),
			"th_r": Vector3(8, -4, 18), "kn_r": 44.0, "th_l": Vector3(-6, 4, 24), "kn_l": 22.0, "ft_l": 10.0},
		"F": {"spin": 24.0, "kn_r": 34.0},
	},
	# 어깨 들이받기: 몸을 돌려 오른 어깨를 앞세우고(spin) 낮게 웅크렸다가 앞으로 몸통째 부딪는다
	"shoulder_ram": {
		"W": {"spin": 40.0, "pelvis": Vector3(14, 0, 0), "chest": Vector3(12, 0, -6), "head": Vector3(-14, -40, 0),
			"sh_r": Vector3(20, 30, 10), "el_r": 110.0, "sh_l": Vector3(44, 40, 10), "el_l": 120.0,
			"th_r": Vector3(36, -4, 8), "kn_r": 56.0, "th_l": Vector3(20, 4, 8), "kn_l": 54.0},
		"S": {"spin": 64.0, "pelvis": Vector3(18, 0, -6), "chest": Vector3(16, 6, -14), "head": Vector3(-18, -60, 0),
			"sh_r": Vector3(14, 34, 10), "el_r": 104.0, "sh_l": Vector3(40, 44, 10), "el_l": 124.0,
			"th_r": Vector3(58, -4, 8), "kn_r": 70.0, "th_l": Vector3(-24, 4, 8), "kn_l": 10.0, "ft_l": 20.0,
			"root_fwd": 0.4},
		"F": {"root_fwd": 0.34, "spin": 50.0},
	},
	# 짓밟기: 무릎을 높이 들고 고개를 숙여 내려다보다 발바닥으로 바닥(쓰러진 상대)을 내리밟는다
	"stomp": {
		"W": {"pelvis": Vector3(-4, 0, 0), "chest": Vector3(8, 0, 0), "head": Vector3(22, 0, 0),
			"th_r": Vector3(92, -4, 6), "kn_r": 100.0, "ft_r": 0.0, "th_l": Vector3(-2, 4, 6), "kn_l": 14.0,
			"sh_r": Vector3(16, 0, 36), "el_r": 30.0, "sh_l": Vector3(16, 0, 36), "el_l": 30.0},
		"S": {"pelvis": Vector3(12, 0, 0), "chest": Vector3(16, 0, 0), "head": Vector3(30, 0, 0),
			"th_r": Vector3(46, -4, 6), "kn_r": 34.0, "ft_r": -10.0, "th_l": Vector3(-6, 4, 6), "kn_l": 44.0,
			"sh_r": Vector3(0, 0, 30), "el_r": 30.0, "sh_l": Vector3(10, 0, 30), "el_l": 30.0, "root_fwd": 0.14},
		"F": {"th_r": Vector3(40, -4, 6), "kn_r": 40.0},
	},
	# 내리찍기(무기): 무기를 머리 뒤까지 들어 올렸다가 몸을 실어 위에서 곧게 내리찍는다
	"overhead_chop": {
		"W": {"pelvis": Vector3(-4, -10, 0), "chest": Vector3(-10, -10, 0), "head": Vector3(-4, 14, 0),
			"sh_r": Vector3(172, 8, 12), "el_r": 70.0, "wr_r": Vector3(-30, 0, 0), "sh_l": Vector3(60, 30, 16), "el_l": 100.0,
			"th_r": Vector3(12, -4, 6), "kn_r": 24.0, "th_l": Vector3(-8, 4, 8), "kn_l": 22.0},
		"S": {"pelvis": Vector3(18, 12, 0), "chest": Vector3(16, 10, 0), "head": Vector3(-14, -12, 0),
			"sh_r": Vector3(58, 8, 6), "el_r": 8.0, "wr_r": Vector3(-20, 0, 0), "sh_l": Vector3(10, 10, 30), "el_l": 60.0,
			"th_r": Vector3(46, -4, 6), "kn_r": 56.0, "th_l": Vector3(-24, 4, 8), "kn_l": 10.0, "root_fwd": 0.2},
		"F": {"sh_r": Vector3(40, 8, 10), "el_r": 20.0, "root_fwd": 0.18},
	},
	# 역수 찌르기: 거꾸로 쥔 칼을 머리 옆으로 높이 들었다가 몸을 덮치며 위에서 내리 찌른다
	"reverse_stab": {
		"W": {"pelvis": Vector3(-2, -16, 0), "chest": Vector3(-6, -20, 0), "head": Vector3(-4, 24, 0),
			"sh_r": Vector3(150, 0, 34), "el_r": 96.0, "sh_l": Vector3(54, 34, 14), "el_l": 110.0,
			"th_r": Vector3(10, -4, 6), "kn_r": 26.0, "th_l": Vector3(-6, 4, 8), "kn_l": 24.0},
		"S": {"pelvis": Vector3(18, 22, 0), "chest": Vector3(16, 24, 0), "head": Vector3(-16, -32, 0),
			"sh_r": Vector3(80, 20, 10), "el_r": 40.0, "sh_l": Vector3(30, 20, 30), "el_l": 80.0,
			"th_r": Vector3(46, -4, 6), "kn_r": 58.0, "th_l": Vector3(-26, 4, 8), "kn_l": 10.0, "root_fwd": 0.22},
		"F": {"sh_r": Vector3(64, 20, 12), "el_r": 50.0, "root_fwd": 0.18},
	},
	# 뽑아 쏘기: 품(왼쪽 가슴)에 손을 넣었다가(W) 뽑으며 오른팔을 곧게 뻗어 쏜다(S — shot 과 같은 겨눔)
	"draw_shot": {
		"W": {"pelvis": Vector3(2, -10, 0), "chest": Vector3(4, -12, 0), "head": Vector3(-4, 18, 0),
			"sh_r": Vector3(24, 54, 14), "el_r": 128.0, "wr_r": Vector3(0, 0, 0)},
		"S": {"pelvis": Vector3(-2, -24, 0), "chest": Vector3(-6, -28, 0), "head": Vector3(-2, 30, 0),
			"sh_r": Vector3(94, 40, 4), "el_r": 6.0, "wr_r": Vector3(-56, 0, 0)},
		"F": {"sh_r": Vector3(80, 36, 6), "el_r": 20.0, "wr_r": Vector3(-30, 0, 0)},
	},
	# 두 손 내려치기: 깍지 낀 두 손을 머리 위로 들었다가 허리를 접으며 내려친다
	"two_hand_slam": {
		"W": {"pelvis": Vector3(-6, 0, 0), "chest": Vector3(-14, 0, 0), "head": Vector3(-6, 0, 0),
			"sh_r": Vector3(168, 26, 6), "el_r": 40.0, "sh_l": Vector3(168, 26, 6), "el_l": 40.0,
			"th_r": Vector3(14, -4, 6), "kn_r": 22.0, "th_l": Vector3(-6, 4, 8), "kn_l": 20.0},
		"S": {"pelvis": Vector3(22, 0, 0), "chest": Vector3(22, 0, 0), "head": Vector3(-20, 0, 0),
			"sh_r": Vector3(54, 30, 6), "el_r": 12.0, "sh_l": Vector3(54, 30, 6), "el_l": 12.0,
			"th_r": Vector3(46, -4, 6), "kn_r": 54.0, "th_l": Vector3(4, 4, 8), "kn_l": 40.0, "root_fwd": 0.14},
		"F": {"sh_r": Vector3(40, 30, 8), "el_r": 20.0, "sh_l": Vector3(40, 30, 8), "el_l": 20.0},
	},
	# 백피스트: 주먹을 반대 어깨 앞으로 접었다가(W) 손등으로 바깥 · 앞으로 채찍처럼 휘둘러 친다
	"backfist": {
		"W": {"pelvis": Vector3(4, 10, 0), "chest": Vector3(4, 20, 0), "head": Vector3(-4, -26, 0),
			"sh_r": Vector3(60, 70, 24), "el_r": 128.0, "sh_l": Vector3(54, 34, 14), "el_l": 120.0,
			"th_r": Vector3(16, -4, 6), "kn_r": 30.0, "th_l": Vector3(-6, 4, 8), "kn_l": 26.0},
		"S": {"pelvis": Vector3(4, -12, 0), "chest": Vector3(4, -18, 0), "head": Vector3(-4, 10, 0),
			"sh_r": Vector3(82, -4, 26), "el_r": 12.0, "wr_r": Vector3(-20, 0, 0),
			"th_r": Vector3(30, -4, 6), "kn_r": 36.0, "th_l": Vector3(-16, 4, 8), "kn_l": 14.0, "root_fwd": 0.1},
		"F": {"sh_r": Vector3(70, -10, 26), "el_r": 40.0},
	},
	# 막고 받아치기: 왼 아래팔을 세워 막고(W) 그대로 막은 채 오른손을 곧게 받아친다(S)
	"guard_counter": {
		"W": {"pelvis": Vector3(6, -6, 0), "chest": Vector3(6, -8, 0), "head": Vector3(-8, 12, 0),
			"sh_r": Vector3(40, 20, 20), "el_r": 128.0, "sh_l": Vector3(78, 46, 12), "el_l": 104.0,
			"th_r": Vector3(-6, -4, 8), "kn_r": 34.0, "th_l": Vector3(20, 4, 6), "kn_l": 34.0},
		"S": {"pelvis": Vector3(10, 30, 0), "chest": Vector3(10, 34, 0), "head": Vector3(-10, -44, 0),
			"sh_r": Vector3(90, 8, 2), "el_r": 2.0, "sh_l": Vector3(78, 46, 12), "el_l": 104.0,
			"th_r": Vector3(-24, -4, 6), "kn_r": 12.0, "ft_r": 20.0, "th_l": Vector3(40, 4, 6), "kn_l": 46.0, "root_fwd": 0.16},
		"F": {"sh_r": Vector3(66, 12, 10), "el_r": 40.0},
	},
	# 올려 베기: 칼을 오른 허리 뒤 아래로 낮게 내렸다가(W — 무릎을 굽혀 가라앉음) 다리를 펴며 앞 위로 크게 베어 올린다(S)
	"rising_slash": {
		"W": {"pelvis": Vector3(14, -24, 0), "chest": Vector3(10, -28, 6), "head": Vector3(-10, 34, -4),
			"sh_r": Vector3(-24, -10, 28), "el_r": 20.0, "wr_r": Vector3(-20, 0, 0), "sh_l": Vector3(50, 36, 14), "el_l": 110.0,
			"th_r": Vector3(36, -4, 8), "kn_r": 56.0, "th_l": Vector3(4, 4, 8), "kn_l": 46.0},
		"S": {"pelvis": Vector3(-4, 24, 0), "chest": Vector3(-10, 30, -6), "head": Vector3(-10, -36, 0),
			"sh_r": Vector3(132, 30, 24), "el_r": 16.0, "wr_r": Vector3(20, 0, 0), "sh_l": Vector3(20, 10, 40), "el_l": 60.0,
			"th_r": Vector3(30, -4, 6), "kn_r": 24.0, "th_l": Vector3(-20, 4, 8), "kn_l": 8.0, "ft_l": 20.0, "root_fwd": 0.14},
		"F": {"sh_r": Vector3(146, 36, 30), "el_r": 30.0, "chest": Vector3(-12, 34, -6)},
	},
	# 던지기(오버핸드): 오른팔을 머리 뒤로 젖혀 감고 왼팔로 겨눴다가(W) 몸을 돌리며 머리 위로 앞으로 뿌린다(S — 사슬 추 · 당구공)
	"toss": {
		"W": {"pelvis": Vector3(-4, -30, 0), "chest": Vector3(-10, -34, 0), "head": Vector3(-4, 44, 0),
			"sh_r": Vector3(130, -40, 50), "el_r": 110.0, "sh_l": Vector3(80, 10, 10), "el_l": 16.0,
			"th_r": Vector3(-10, -4, 8), "kn_r": 30.0, "ft_r": 10.0, "th_l": Vector3(24, 4, 6), "kn_l": 22.0},
		"S": {"pelvis": Vector3(14, 34, 0), "chest": Vector3(16, 38, 0), "head": Vector3(-14, -52, 0),
			"sh_r": Vector3(100, 20, 10), "el_r": 8.0, "wr_r": Vector3(-30, 0, 0), "sh_l": Vector3(10, -10, 40), "el_l": 50.0,
			"th_r": Vector3(-30, -4, 6), "kn_r": 12.0, "ft_r": 28.0, "th_l": Vector3(44, 4, 6), "kn_l": 46.0, "root_fwd": 0.18},
		"F": {"sh_r": Vector3(60, 30, 14), "el_r": 20.0, "wr_r": Vector3(-40, 0, 0)},
	},
}

# 왼손 · 왼발 판(이름 + "_L")을 인형이 좌우로 뒤집어 만드는 모양 — 기술의 hand 가 "L" 이면 그 판(src/view/puppet_pose.gd shape_key)
const MIRROR := ["punch", "shot", "jab", "straight", "hook", "uppercut", "body_blow", "elbow", "knee", "flying_knee",
	"headbutt", "palm", "hammer_fist", "front_kick", "round_kick", "low_kick", "spin_back_kick", "axe_kick",
	"flying_kick", "sweep", "tackle", "grab", "throw_slam", "choke", "duck", "weave", "sidestep", "shoulder_ram",
	"stomp", "overhead_chop", "reverse_stab", "draw_shot", "two_hand_slam", "backfist", "guard_counter",
	"rising_slash", "toss"]
# 회수 동안 같은 쪽으로 마저 돌아 한 바퀴(360)를 채우는 모양 — 거꾸로 풀려 돌아오지 않게
const SPIN_THROUGH := ["spin_back_kick"]

# 막기(쳐내기 자세): 두 아래팔을 얼굴 앞에 세운다 / 쳐내기 성공: 칼을 바깥으로 튕겨 낸다
const PARRY := {"pelvis": Vector3(6, 6, 0), "chest": Vector3(6, 8, 0), "head": Vector3(-8, -12, 0),
	"sh_r": Vector3(76, 44, 12), "el_r": 102.0, "sh_l": Vector3(74, 46, 12), "el_l": 104.0, "kn_r": 32.0, "kn_l": 30.0}
const FLICK := {"chest": Vector3(6, -16, 0), "sh_r": Vector3(62, -12, 58), "el_r": 32.0, "sh_l": Vector3(60, 30, 20),
	"el_l": 100.0}
# 쳐내기 당함(휘청): 칼 든 팔이 위 뒤로 튕기고 몸이 젖혀진다
const RECOIL := {"pelvis": Vector3(-14, -14, 0), "chest": Vector3(-12, -20, 0), "head": Vector3(16, 20, 0),
	"sh_r": Vector3(122, -40, 60), "el_r": 32.0, "sh_l": Vector3(20, 0, 40), "el_l": 40.0,
	"th_r": Vector3(-8, 0, 6), "kn_r": 22.0, "th_l": Vector3(10, 0, 8), "kn_l": 26.0}
const HURT := {"pelvis": Vector3(-12, 0, 0), "chest": Vector3(-16, 10, 0), "head": Vector3(22, 0, 0),
	"sh_r": Vector3(-14, 0, 34), "el_r": 30.0, "sh_l": Vector3(-14, 0, 34), "el_l": 30.0, "kn_r": 18.0, "kn_l": 18.0}
# 기절: 무릎이 풀려 몸이 늘어진다 (인형이 흔든다)
const STUN := {"pelvis": Vector3(10, 0, 0), "chest": Vector3(14, 0, 0), "head": Vector3(26, 0, 14),
	"sh_r": Vector3(0, 0, 14), "el_r": 10.0, "sh_l": Vector3(0, 0, 14), "el_l": 10.0,
	"th_r": Vector3(18, 0, 6), "kn_r": 46.0, "th_l": Vector3(14, 0, 6), "kn_l": 44.0}
# 빈틈: 체간이 무너져 고개를 떨구고 휘청인다
const STAGGER := {"pelvis": Vector3(20, 0, 0), "chest": Vector3(18, 0, 0), "head": Vector3(30, 0, 0),
	"sh_r": Vector3(8, 10, 12), "el_r": 16.0, "sh_l": Vector3(8, 10, 12), "el_l": 16.0,
	"th_r": Vector3(12, 0, 6), "kn_r": 36.0, "th_l": Vector3(-6, 0, 6), "kn_l": 30.0}
# 앞구르기: 무릎을 가슴에 붙여 웅크린다 (돌기는 인형이)
const TUCK := {"pelvis": Vector3(40, 0, 0), "chest": Vector3(30, 0, 0), "head": Vector3(30, 0, 0),
	"sh_r": Vector3(64, 30, 10), "el_r": 112.0, "sh_l": Vector3(64, 30, 10), "el_l": 112.0,
	"th_r": Vector3(104, 0, 8), "kn_r": 124.0, "th_l": Vector3(104, 0, 8), "kn_l": 124.0}
# 넘어짐 · 쓰러짐: 등을 대고 눕는다 (넘어지는 각도는 인형이)
const LYING := {"head": Vector3(-14, 0, 0), "sh_r": Vector3(10, 0, 64), "el_r": 24.0, "sh_l": Vector3(10, 0, 58),
	"el_l": 30.0, "th_r": Vector3(8, 0, 10), "kn_r": 16.0, "th_l": Vector3(4, 0, 8), "kn_l": 22.0, "fall": 88.0}
# 이긴 자세 (결과 화면)
const VICTORY := {"pelvis": Vector3(2, 8, 0), "head": Vector3(-10, -10, 0), "sh_r": Vector3(10, 0, 18), "el_r": 20.0,
	"sh_l": Vector3(10, 0, 14), "el_l": 20.0, "kn_r": 6.0, "kn_l": 6.0}
