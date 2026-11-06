extends RefCounted
## 적 AI (여러 사람 판 — 0장 군터 호텔 · 1장 회암시 · 11장 호텔 캐슬) — 프로필 표(PROFILES) 하나로 엑스트라 · 군터 · DS 간부 ·
## 김대건 · 윤덕수 · 경호원 · 경호대 최후의 4인 · 하야부사 · 신겐을 움직인다.
## 백도찬 AI(boss_ai.gd)처럼 Fighter.intent 만 채운다. 판(stage.gd)이 매 프레임 상대(가장 가까운 사람)와 may_attack 을 준다 —
## 여럿이 한꺼번에 몰아치지 않게 동시에 패턴을 내는 적 수를 판이 제한한다(협공은 하되 예고를 읽을 틈은 남긴다).
## 칼날 쳐내기는 못 한다(김신 · 백도찬만) — 상대가 치면 기술(능력치) 확률로 막는다(fighter can_parry false → 막기).
## 3층(이 판 소유): 패턴 · 박자 · 거리 · 확률. 처음 값은 봇 판으로 맞춘다(무정지 규칙 6).

const Fighter = preload("res://src/combat/fighter.gd")

const HELPLESS := ["down", "stagger", "hitstun", "recoil", "stun", "dead"]

## patterns: 이름 → [[동작, 다음까지 쉬는 프레임], ...] · weights[phase-1]: [[이름, 무게], ...] · cd: 패턴 사이 쉬는 프레임 [최소, 더함]
## near · far: 거리 조절 · engage: 이 안이면 패턴을 시작 · ranged: [동작, 최소 거리, 최대 거리, 쿨다운] (총)
const PROFILES := {
	"guard": {"patterns": {"baton": [["c_baton", 0]], "punch2": [["c_punch", 10], ["c_baton", 0]]},
		"weights": [[["baton", 2], ["punch2", 1]]], "cd": [80, 60], "near": 1.0, "far": 1.7, "engage": 1.9},
	"g4": {"patterns": {"slash2": [["g4_slash", 8], ["g4_thrust", 0]], "chop": [["s_g4_chop", 0]],
			"heel": [["s_g4_heel", 0]], "slash_heel": [["g4_slash", 10], ["s_g4_heel", 0]]},
		"weights": [[["slash2", 3], ["chop", 1], ["heel", 1], ["slash_heel", 1]]], "cd": [70, 60],
		"near": 1.1, "far": 1.9, "engage": 2.1, "ranged": ["t_shot", 2.6, 6.5, 260]},
	"hayabusa": {"patterns": {"slash3": [["hy_slash1", 6], ["hy_slash2", 8], ["hy_thrust", 0]], "arc": [["s_hy_arc", 0]],
			"low": [["s_hy_low", 0]], "slash_low": [["hy_slash1", 8], ["s_hy_low", 0]]},
		"weights": [[["slash3", 3], ["arc", 2], ["low", 1], ["slash_low", 1]]], "cd": [50, 40],
		"near": 1.3, "far": 2.3, "engage": 2.5},
	"shingen": {"patterns": {"slash3": [["sg_slash1", 6], ["sg_slash2", 8], ["sg_stab", 0]], "daegeuk": [["s_sg_daegeuk", 0]],
			"dive": [["s_sg_dive", 0]], "kick": [["s_sg_kick", 0]], "leap": [["s_sg_leap", 0]],
			"slash_kick": [["sg_slash1", 8], ["s_sg_kick", 0]], "stab_daegeuk": [["sg_stab", 10], ["s_sg_daegeuk", 0]]},
		"weights": [[["slash3", 4], ["daegeuk", 2], ["dive", 1], ["kick", 1], ["slash_kick", 1]],
			[["slash3", 2], ["daegeuk", 2], ["dive", 2], ["kick", 1], ["leap", 2], ["slash_kick", 1], ["stab_daegeuk", 2]]],
		"cd": [34, 30], "near": 1.4, "far": 2.4, "engage": 2.6, "phase2": {"dmg_k": 1.15, "cd_k": 0.7, "guard_add": 0.1}},
	# ---- 0 · 1장(S5 묶음 2 · 3) — canon fights 국면(화/컷)에서. 동작은 src/data/moves.gd(m_ · gt_ · hj_ · sj_ · dg_ · mj_ · yd_).
	# 덧붙인 칸(이 장들만 쓴다): guard_add — 막는 확률에 더함(강만재 하이가드) · counter: [동작, 확률] — 상대가 치기 시작할 때 막지 않으면
	# 이 확률로 맞받아 친다(김대건 크로스 카운터 014/030-032) · phase2.counter_add — 2차에 맞받는 확률을 더함 ·
	# kite — 총잡이: 주먹 차례에도 다가가지 않고 거리를 두며 쏜다(붙으면 그때 주먹)
	# 엑스트라: 정장(군터 경호원 · DS 조직원 — 주먹 · 휘두르기 · 칼, 002/013-020 · 003/016-045) · 포니테일 거구(훅 · 두 손 내려찍기) ·
	# 대머리(리볼버) · 장발(우지 난사) · DS 습격조(쇠파이프 · 방망이 · 함성 돌진, 008/001-004)
	"thug": {"patterns": {"punch": [["m_punch", 0]], "punch2": [["m_punch", 8], ["m_swing", 0]], "swing": [["m_swing", 0]],
			"knife": [["m_knife", 0]]},
		"weights": [[["punch", 2], ["punch2", 2], ["swing", 1], ["knife", 1]]], "cd": [80, 60], "near": 1.0, "far": 1.7, "engage": 1.9},
	"thug_brute": {"patterns": {"hook": [["m_brute_hook", 0]], "slam": [["m_brute_slam", 0]], "hook_slam": [["m_brute_hook", 8], ["m_brute_slam", 0]]},
		"weights": [[["hook", 3], ["slam", 1], ["hook_slam", 1]]], "cd": [90, 60], "near": 1.0, "far": 1.8, "engage": 2.0},
	"thug_revolver": {"patterns": {"punch": [["m_punch", 0]], "punch_swing": [["m_punch", 10], ["m_swing", 0]]},
		"weights": [[["punch", 2], ["punch_swing", 1]]], "cd": [90, 60], "near": 1.9, "far": 4.0, "engage": 2.0,
		"ranged": ["m_revolver", 2.1, 6.8, 200], "kite": true},
	"thug_uzi": {"patterns": {"swing": [["m_swing", 0]], "punch2": [["m_punch", 8], ["m_punch", 0]]},
		"weights": [[["swing", 1], ["punch2", 1]]], "cd": [90, 60], "near": 2.0, "far": 4.2, "engage": 2.0,
		"ranged": ["m_uzi", 2.1, 6.2, 220], "kite": true},
	"thug_pipe": {"patterns": {"pipe": [["m_pipe", 0]], "pipe2": [["m_pipe", 6], ["m_pipe_back", 0]], "charge": [["m_charge", 0]]},
		"weights": [[["pipe", 3], ["pipe2", 2], ["charge", 1]]], "cd": [70, 60], "near": 1.1, "far": 1.9, "engage": 2.2},
	# 군터(0장 보스 · 조장급, 002/021-028): 탁자 밑 리볼버 — 떨어지면 쏘고, 붙으면 발악(주먹 · 위스키 잔 · 코앞 사격)
	"gunter": {"patterns": {"swing2": [["gt_swing", 8], ["gt_glass", 0]], "point": [["gt_swing", 6], ["gt_point", 0]],
			"glass": [["gt_glass", 0]], "fan": [["gt_fan", 0]]},
		"weights": [[["swing2", 2], ["point", 2], ["glass", 1], ["fan", 1]]], "cd": [60, 50], "near": 1.6, "far": 3.8, "engage": 2.0,
		"ranged": ["gt_revolver", 2.1, 7.0, 150], "kite": true},
	# 김혁주(003/045-051): 잭나이프 두 자루 — 첫 베기는 잽, 두 번째가 진짜(멈칫 뒤). 돌진 · 찌르기
	"hyeokju": {"patterns": {"two": [["hj_jab", 2], ["hj_real", 0]], "two_thrust": [["hj_jab", 2], ["hj_real", 8], ["hj_thrust", 0]],
			"rush": [["hj_rush", 0]], "thrust": [["hj_thrust", 0]]},
		"weights": [[["two", 4], ["two_thrust", 2], ["rush", 1], ["thrust", 1]]], "cd": [55, 45], "near": 1.1, "far": 1.9, "engage": 2.1},
	# 김성준(008-010): 약에 취해 몰아친다(쉬는 틈이 짧다) — 연타 · 코트 휘두르기 · 부츠 발차기(멀리 날림) · 칼
	"seongjun": {"patterns": {"flurry": [["sj_flurry", 0]], "coat": [["sj_coat", 0]], "coat_kick": [["sj_coat", 6], ["sj_kick", 0]],
			"knife": [["sj_upslash", 8], ["sj_knife", 0]], "flurry_kick": [["sj_flurry", 6], ["sj_kick", 0]]},
		"weights": [[["flurry", 3], ["coat", 2], ["coat_kick", 2], ["knife", 2], ["flurry_kick", 1]]], "cd": [36, 40],
		"near": 1.0, "far": 1.8, "engage": 2.0},
	# 김대건(014-016): 1차 큰 주먹 · 훅 → 뒷발 · 페인트 하이킥 · 미끄러지기 · 태클, 크로스 카운터. 2차(015/042-048 '피떡이 돼야 시동')
	# 프로다운 연타(잽 잽 정권 · 잽 직선 훅 → 날아 무릎) — 더 몰아치고 더 맞받는다
	"daegeon": {"patterns": {"straight": [["dg_straight", 0]], "one_two": [["dg_straight", 4], ["dg_hook", 0]],
			"hook_spin": [["dg_hook", 2], ["dg_spin", 0]], "feint_kick": [["dg_highkick", 0]], "slide": [["dg_slide", 0]],
			"tackle": [["dg_tackle", 0]], "pro3": [["dg_jab", 3], ["dg_jab", 3], ["dg_jeongkwon", 0]],
			"pro4": [["dg_jab", 3], ["dg_straight", 4], ["dg_hook", 6], ["dg_knee", 0]], "knee": [["dg_knee", 0]]},
		"weights": [[["straight", 3], ["one_two", 3], ["hook_spin", 2], ["feint_kick", 2], ["slide", 1], ["tackle", 1]],
			[["pro3", 3], ["pro4", 2], ["one_two", 2], ["hook_spin", 1], ["feint_kick", 1], ["knee", 2], ["tackle", 2]]],
		"cd": [40, 30], "near": 1.1, "far": 2.0, "engage": 2.2, "counter": ["dg_cross", 0.25],
		"phase2": {"dmg_k": 1.2, "cd_k": 0.65, "guard_add": 0.1, "counter_add": 0.15}},
	# 강만재(005-006): 느린 흉터 거구 · 하이가드(잘 막는다) — 큰 오른손 · 훅 · 긴 스트레이트 · 낮은 돌진 · 보디블로(숨이 막힌다)
	"manjae": {"patterns": {"swing": [["mj_swing", 0]], "hook_straight": [["mj_hook", 6], ["mj_straight", 0]], "rush": [["mj_rush", 0]],
			"body": [["mj_body", 0]], "swing_body": [["mj_swing", 6], ["mj_body", 0]]},
		"weights": [[["swing", 3], ["hook_straight", 2], ["rush", 2], ["body", 1], ["swing_body", 1]]], "cd": [70, 50],
		"near": 1.0, "far": 1.8, "engage": 2.0, "guard_add": 0.25},
	# 윤덕수(018-020): 큰 오른 훅 · 오른 스트레이트 · 얼굴 잡아 메치기 → 짓밟기. 2차(옆구리를 맞은 뒤)는 메치기를 더 자주 · 더 몰아친다
	"deoksu": {"patterns": {"hook": [["yd_hook", 0]], "jab_hook": [["yd_jab", 4], ["yd_hook", 0]], "straight": [["yd_straight", 0]],
			"one_two": [["yd_straight", 6], ["yd_hook", 0]], "stomp": [["yd_stomp", 0]], "grab": [["yd_grab", 6], ["yd_stomp", 0]],
			"hook_grab": [["yd_hook", 6], ["yd_grab", 6], ["yd_stomp", 0]]},
		"weights": [[["hook", 3], ["jab_hook", 2], ["straight", 2], ["one_two", 2], ["stomp", 1], ["grab", 1]],
			[["hook", 2], ["jab_hook", 2], ["one_two", 3], ["grab", 3], ["hook_grab", 2]]],
		"cd": [44, 34], "near": 1.1, "far": 2.0, "engage": 2.2, "phase2": {"dmg_k": 1.15, "cd_k": 0.7, "guard_add": 0.1}},
}

var me
var foe
var rng: RandomNumberGenerator
var prof: Dictionary
var guard_rate := 0.3
var queue: Array = []
var wait := 0
var cooldown := 60
var guard_hold := 0
var seen_attack := ""
var ranged_cd := 0
var strafe := 1.0
var strafe_t := 0
var phase := 1
var counter_rate := 0.0          # 맞받아 치는 확률(프로필 counter — 0 · 1장 김대건)
var kite := false                # 총잡이(프로필 kite): 주먹 차례가 와도 다가가지 않고 거리를 둔다 — 붙으면 그때 친다


func _init(enemy, profile_id: String, r: RandomNumberGenerator, guard := 0.3) -> void:
	me = enemy
	prof = PROFILES.get(profile_id, PROFILES["guard"])     # 표에 없는 프로필은 경호원(시험 test_campaign 이 장 표의 ai 가 다 있는지 본다)
	rng = r
	guard_rate = minf(0.85, guard + float(prof.get("guard_add", 0.0)))     # guard_add: 하이가드(강만재) — 없으면 능력치 그대로
	if prof.has("counter"):
		counter_rate = float(prof["counter"][1])
	cooldown = 40 + rng.randi_range(0, 60)                  # 여럿이 같은 박자로 시작하지 않게
	ranged_cd = 90 + rng.randi_range(0, 120)
	kite = bool(prof.get("kite", false))
	if kite:
		ranged_cd = int(ranged_cd / 3.0)                   # 총잡이는 첫 발이 빠르다(들어서자 겨눈다 — 002/013-015)


func busy() -> bool:
	if not me.alive() or me.inert:
		return false                                   # 쓰러진 사람의 남은 패턴은 차례를 붙잡지 않는다
	return not queue.is_empty() or me.state == "attack"


func decide(target, may_attack: bool) -> Dictionary:
	foe = target
	var it := {"move": Vector2.ZERO}
	if foe == null or not me.alive() or not foe.alive() or me.inert:
		return it
	it["face"] = me.dir_to(foe)
	if me.phase == 2 and phase == 1:
		_enter_phase2()
	var d: float = me.dist_to(foe)
	if ranged_cd > 0:
		ranged_cd -= 1
	if guard_hold > 0:
		guard_hold -= 1
		it["parry_held"] = true
		return it
	if not me.can_act():
		return it
	# 1. 상대가 나를 향해 치기 시작하면(2프레임 안) 기술 확률로 막는다
	var key := "%d:%d" % [foe.get_instance_id(), foe.attack_id]
	if foe.state == "attack" and foe.t <= 2 and key != seen_attack and d < 2.6 and foe.facing.dot(foe.dir_to(me)) > 0.5:
		seen_attack = key
		if rng.randf() < guard_rate:
			it["parry"] = true
			it["parry_held"] = true
			guard_hold = Fighter.PARRY_MIN + 4
			queue.clear()
			return it
		# 막지 않으면 맞받아 친다(크로스 카운터 — 프로필 counter 가 있는 사람만, 판이 준 차례 안에서)
		if counter_rate > 0.0 and may_attack and d < float(prof["engage"]) and rng.randf() < counter_rate:
			queue.clear()
			it["use"] = str(prof["counter"][0])
			return it
	# 2. 패턴 이어 가기
	if not queue.is_empty():
		if wait > 0:
			wait -= 1
			it["move"] = it["face"] * 0.35 if d > float(prof["near"]) + 0.2 else Vector2.ZERO
			return it
		var step: Array = queue.pop_front()
		it["use"] = step[0]
		wait = int(step[1])
		return it
	# 3. 총: 떨어져 있으면 겨눠 쏜다(빨간 ! — 보고 구른다)
	if prof.has("ranged") and may_attack and ranged_cd == 0 and not foe.state in HELPLESS:
		var rg: Array = prof["ranged"]
		if d >= float(rg[1]) and d <= float(rg[2]):
			it["use"] = rg[0]
			ranged_cd = int(rg[3]) + rng.randi_range(0, 90)
			return it
	# 4. 쿨다운이 끝나고 차례(may_attack)면 패턴을 고른다
	cooldown -= 1
	if cooldown <= 0 and may_attack and d < float(prof["engage"]):
		_pick()
		return it
	# 5. 거리 조절 — 차례가 아니면 한 발 물러나 둘레를 돈다(포위)
	var to: Vector2 = it["face"]
	strafe_t -= 1
	if strafe_t <= 0:
		strafe = -strafe if rng.randf() < 0.5 else strafe
		strafe_t = 40 + rng.randi_range(0, 50)
	var far: float = float(prof["far"]) + (0.0 if may_attack else 1.0)
	var near: float = float(prof["near"]) + (0.0 if may_attack else 0.8)
	if d > far or (not kite and cooldown <= 0 and may_attack and d >= float(prof["engage"])):
		it["move"] = to * 0.6
	elif d < near:
		it["move"] = -to * 0.5
	else:
		it["move"] = Vector2(-to.y, to.x) * strafe * 0.4
	return it


func _enter_phase2() -> void:
	phase = 2
	var p2: Dictionary = prof.get("phase2", {})
	me.dmg_k *= float(p2.get("dmg_k", 1.0))
	guard_rate = minf(0.85, guard_rate + float(p2.get("guard_add", 0.0)))
	counter_rate = minf(0.85, counter_rate + float(p2.get("counter_add", 0.0)))
	queue.clear()
	cooldown = 30


func _pick() -> void:
	var tables: Array = prof["weights"]
	var table: Array = tables[mini(phase, tables.size()) - 1]
	var total := 0
	for row in table:
		total += int(row[1])
	var r := rng.randi_range(1, total)
	var name: String = table[0][0]
	for row in table:
		r -= int(row[1])
		if r <= 0:
			name = row[0]
			break
	queue = prof["patterns"][name].duplicate(true)
	wait = 0
	var cd: Array = prof["cd"]
	var k: float = float(prof.get("phase2", {}).get("cd_k", 1.0)) if phase == 2 else 1.0
	cooldown = int((int(cd[0]) + rng.randi_range(0, int(cd[1]))) * k)
