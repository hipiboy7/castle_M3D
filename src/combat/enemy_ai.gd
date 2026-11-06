extends RefCounted
## 적 AI (11장 호텔 캐슬) — 프로필 표(PROFILES) 하나로 경호원 · 경호대 최후의 4인 · 하야부사 · 신겐을 움직인다.
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
	# ---- 0 · 1장(S5 묶음 2 · 3) — 뼈대: 자리만(패턴은 다음 커밋에서 canon fights 국면으로)
	"thug": {"patterns": {"baton": [["c_baton", 0]], "punch2": [["c_punch", 10], ["c_baton", 0]]}, "weights": [[["baton", 2], ["punch2", 1]]], "cd": [80, 60], "near": 1.0, "far": 1.7, "engage": 1.9},
	"thug_brute": {"patterns": {"baton": [["c_baton", 0]], "punch2": [["c_punch", 10], ["c_baton", 0]]}, "weights": [[["baton", 2], ["punch2", 1]]], "cd": [80, 60], "near": 1.0, "far": 1.7, "engage": 1.9},
	"thug_pipe": {"patterns": {"baton": [["c_baton", 0]], "punch2": [["c_punch", 10], ["c_baton", 0]]}, "weights": [[["baton", 2], ["punch2", 1]]], "cd": [80, 60], "near": 1.0, "far": 1.7, "engage": 1.9},
	"hyeokju": {"patterns": {"baton": [["c_baton", 0]], "punch2": [["c_punch", 10], ["c_baton", 0]]}, "weights": [[["baton", 2], ["punch2", 1]]], "cd": [80, 60], "near": 1.0, "far": 1.7, "engage": 1.9},
	"seongjun": {"patterns": {"baton": [["c_baton", 0]], "punch2": [["c_punch", 10], ["c_baton", 0]]}, "weights": [[["baton", 2], ["punch2", 1]]], "cd": [80, 60], "near": 1.0, "far": 1.7, "engage": 1.9},
	"daegeon": {"patterns": {"baton": [["c_baton", 0]], "punch2": [["c_punch", 10], ["c_baton", 0]]}, "weights": [[["baton", 2], ["punch2", 1]]], "cd": [80, 60], "near": 1.0, "far": 1.7, "engage": 1.9},
	"manjae": {"patterns": {"baton": [["c_baton", 0]], "punch2": [["c_punch", 10], ["c_baton", 0]]}, "weights": [[["baton", 2], ["punch2", 1]]], "cd": [80, 60], "near": 1.0, "far": 1.7, "engage": 1.9},
	"deoksu": {"patterns": {"baton": [["c_baton", 0]], "punch2": [["c_punch", 10], ["c_baton", 0]]}, "weights": [[["baton", 2], ["punch2", 1]]], "cd": [80, 60], "near": 1.0, "far": 1.7, "engage": 1.9},
	"thug_revolver": {"patterns": {"baton": [["c_baton", 0]], "punch2": [["c_punch", 10], ["c_baton", 0]]}, "weights": [[["baton", 2], ["punch2", 1]]], "cd": [80, 60], "near": 1.0, "far": 1.7, "engage": 1.9, "ranged": ["t_shot", 2.6, 6.5, 260]},
	"thug_uzi": {"patterns": {"baton": [["c_baton", 0]], "punch2": [["c_punch", 10], ["c_baton", 0]]}, "weights": [[["baton", 2], ["punch2", 1]]], "cd": [80, 60], "near": 1.0, "far": 1.7, "engage": 1.9, "ranged": ["t_shot", 2.6, 6.5, 260]},
	"gunter": {"patterns": {"baton": [["c_baton", 0]], "punch2": [["c_punch", 10], ["c_baton", 0]]}, "weights": [[["baton", 2], ["punch2", 1]]], "cd": [80, 60], "near": 1.0, "far": 1.7, "engage": 1.9, "ranged": ["t_shot", 2.6, 6.5, 260]},
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


func _init(enemy, profile_id: String, r: RandomNumberGenerator, guard := 0.3) -> void:
	me = enemy
	prof = PROFILES.get(profile_id, PROFILES["guard"])     # 표에 없는 프로필은 경호원(시험 test_campaign 이 장 표의 ai 가 다 있는지 본다)
	rng = r
	guard_rate = guard
	cooldown = 40 + rng.randi_range(0, 60)                  # 여럿이 같은 박자로 시작하지 않게
	ranged_cd = 90 + rng.randi_range(0, 120)


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
	if d > far or (cooldown <= 0 and may_attack and d >= float(prof["engage"])):
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
