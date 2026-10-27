extends RefCounted
## 백도찬 AI — 다른 컨트롤러처럼 Fighter.intent 만 채운다.
## 패턴 · 박자 · 맞수(칼날 쳐내기) · 백도찬식 찌르기는 castle_M `docs/P2_설계서_M1전투핵심.md` 8.1 · 8.2절.
## 엇박 찌르기(원조)와 엇박 계열 피하기는 castle_M `castle_m/action/boss_ai.py` · `data/bosses.py` (2026-10-26):
## 체력 90% 이하에서 처음 쓰고(그때까지 80% 아래로 안 내려간다 · 김신은 25% 아래로 안 내려간다), 그 뒤 쿨다운마다.
## 김신이 엇박 계열을 내기 시작하면(4프레임 안) dodge_rate 확률로 구른다 — 그래서 엇박 계열은 백도찬이 못 구르는
## '열린 순간'(쳐내기 당한 휘청 · 기절 · 움찔)에 넣는 기술이 된다.
## 초안에서 뺀 것: 쓸어 베기(점프가 없다) · 손등 받기 · 동요 · 전력 컷인 연출.

const Fighter = preload("res://src/combat/fighter.gd")
const Skills = preload("res://src/data/skills.gd")
const HELPLESS := ["down", "stagger", "hitstun", "recoil", "stun", "dead"]
const OFFBEAT_RANGE := 2.0       # 엇박 찌르기가 닿는 거리 (찌르기 19px + 내딛기 22px ≈ 1.85m + 몸)

const PATTERNS := {
	"sashimi3": [["b_slash1", 6], ["b_slash2", 8], ["b_thrust", 0]],
	"offbeat3": [["b_slash1", 6], ["b_slash2_off", 8], ["b_thrust", 0]],
	"step_l": [["b_step_l", 0]],
	"step_r": [["b_step_r", 0]],
	"sidekick": [["b_sidekick", 0]],
	"slash_kick": [["b_slash1", 6], ["b_sidekick", 0]],
	"wide": [["b_wide", 0]],
}
const WEIGHTS_1 := [["sashimi3", 4], ["step_l", 1], ["step_r", 1], ["sidekick", 1], ["slash_kick", 1]]
const WEIGHTS_2 := [["sashimi3", 2], ["offbeat3", 3], ["step_l", 1], ["step_r", 1], ["sidekick", 1],
	["slash_kick", 2]]
const KEEP_NEAR := 1.15
const KEEP_FAR := 1.85

var me
var foe
var rng: RandomNumberGenerator
var phase := 1
var parry_rate := 0.45
var vital_rate := 0.2
var queue: Array = []
var wait := 0
var cooldown := 70
var parry_hold := 0
var seen_attack := -1
var vital_seen := -1
var used_wide := false
var strafe := 1.0
var strafe_t := 0
var dodge_rate := 0.7
var seen_dodge := -1
var offbeat_cd := 0
var offbeat_shown := false       # 첫 엇박을 썼다 (그 뒤 쿨다운마다)
var demo := ""                   # 첫 엇박 장면: "" → wait(쓸 때를 기다림) → active(쓰는 중) → done


func _init(boss, hero, r: RandomNumberGenerator) -> void:
	me = boss
	foe = hero
	rng = r


## 2차: 안경을 벗는다 — 피해 ×1.2 · 쳐내기 창 +2 · 맞수 확률 0.6. 김신 상대라 전력(피해 ×1.1 · 창 +1 더)
func enter_phase2() -> void:
	phase = 2
	parry_rate = 0.6
	vital_rate = 0.4
	dodge_rate = 0.85
	me.dmg_k = 1.2 * 1.1
	me.parry_extra = 3
	queue.clear()
	cooldown = 40


func decide() -> Dictionary:
	var it := {"move": Vector2.ZERO, "face": me.dir_to(foe)}
	if not me.alive() or not foe.alive():
		return it
	var d: float = me.dist_to(foe)
	_offbeat_clock()
	# 1. 빈틈 · 움찔 중 상대가 치러 들어오면 가끔 빠져나오며 찌른다 (백도찬식 찌르기, 빨간 !)
	if (me.state == "stagger" or me.state == "hitstun") and foe.state == "attack" and foe.t <= 2 \
			and foe.attack_id != vital_seen:
		vital_seen = foe.attack_id
		if rng.randf() < vital_rate:
			it["use"] = "b_vital"
			return it
	if parry_hold > 0:
		parry_hold -= 1
		it["parry_held"] = true
		return it
	if not me.can_act():
		return it
	# 2. 쳐냈으면 곧바로 맞받아 베기
	if me.counter_ready > 0:
		it["use"] = "b_counter"
		return it
	# 2-1. 김신이 엇박 계열을 내기 시작하면 확률로 구른다 (막기 · 쳐내기를 뚫으니까)
	if foe.state == "attack" and str(foe.move["lethal"]) != "" and foe.t <= 4 and foe.attack_id != seen_dodge:
		seen_dodge = foe.attack_id
		if d < OFFBEAT_RANGE + 0.8 and rng.randf() < dodge_rate:
			var away: Vector2 = -it["face"]
			var side := Vector2(-away.y, away.x) * (0.6 if rng.randf() < 0.5 else -0.6)
			it["roll"] = true
			it["move"] = (away + side).normalized()
			queue.clear()
			return it
	# 2-2. 김신이 엇박 계열을 헛치고 뻗은 채 멈춰 있으면 곧바로 벤다 (헛침의 대가)
	if foe.state == "attack" and foe.whiff_t > 0:
		queue.clear()
		if d < 1.5:
			it["use"] = "b_slash1"
		elif d < 2.5:
			it["use"] = "b_thrust"
		else:
			it["move"] = it["face"]
		return it
	# 2-3. 엇박 찌르기 (첫 번은 체력 90% 이하에서 꼭, 그 뒤 쿨다운마다)
	if _offbeat(it, d):
		return it
	# 3. 김신이 공격을 시작하면(정면 · 사거리 안 · 시작 2프레임 안) 확률로 칼날 쳐내기
	if foe.state == "attack" and foe.t <= 2 and foe.attack_id != seen_attack and d < 2.4 \
			and foe.facing.dot(foe.dir_to(me)) > 0.5:
		seen_attack = foe.attack_id
		if rng.randf() < parry_rate:
			it["parry"] = true
			it["parry_held"] = true
			parry_hold = Fighter.PARRY_MIN + 2
			return it
	# 4. 패턴을 이어 가는 중 — 박자만큼 쉬고 다음 기술
	if not queue.is_empty():
		if wait > 0:
			wait -= 1
			it["move"] = it["face"] * 0.35 if d > 1.3 else Vector2.ZERO
			return it
		var step: Array = queue.pop_front()
		it["use"] = step[0]
		wait = int(step[1])
		return it
	# 5. 거리 조절 → 쿨다운이 끝나면 패턴 고르기
	cooldown -= 1
	if cooldown <= 0 and d < 2.3:
		_pick()
		return it
	var to: Vector2 = it["face"]
	strafe_t -= 1
	if strafe_t <= 0:
		strafe = -strafe if rng.randf() < 0.5 else strafe
		strafe_t = 40 + rng.randi_range(0, 50)
	if d > KEEP_FAR or (cooldown <= 0 and d >= 2.3):
		it["move"] = to * 0.6
	elif d < KEEP_NEAR:
		it["move"] = -to * 0.5
	else:
		it["move"] = Vector2(-to.y, to.x) * strafe * 0.4
	return it


## 첫 엇박 장면의 시작 · 끝과 쿨다운
func _offbeat_clock() -> void:
	if offbeat_cd > 0:
		offbeat_cd -= 1
	var ob: Dictionary = Skills.BAEK_OFFBEAT
	if demo == "" and me.hp <= me.hp_max * float(ob["first_hp"]) + 0.001:
		demo = "wait"
		me.hp_floor = float(ob["hold_hp"])           # 첫 엇박을 보이기 전에는 이 아래로 안 내려간다
		foe.hp_floor = float(ob["demo_floor"])       # 보여 주는 한 방 — 김신이 여기서 지지 않게
		me.events.append(["first_offbeat", me])
	elif demo == "active" and me.state != "attack":
		demo = "done"
		me.hp_floor = 0.0
		foe.hp_floor = 0.0


func _offbeat(it: Dictionary, d: float) -> bool:
	var forced := demo == "wait"
	if not forced and not (offbeat_shown and offbeat_cd == 0):
		return false
	if foe.state in HELPLESS:
		return false            # 피할 수 없는 상대에게는 쓰지 않는다 — 엇박은 '보고 구르는' 기술 (예고의 공정성)
	if d > OFFBEAT_RANGE:
		if forced:
			it["move"] = it["face"] * 0.8
			return true
		return false
	it["use"] = "s_offbeat"
	offbeat_cd = int(Skills.BAEK_OFFBEAT["cd"][phase - 1])
	cooldown = maxi(cooldown, 110)          # 맞혀서 김신이 기절해도 몰아치지 않고 내려다본다 ("재주를 좀 더 부려 보거라")
	offbeat_shown = true
	if forced:
		demo = "active"
	queue.clear()
	return true


func _pick() -> void:
	var name := ""
	if phase == 2 and not used_wide and me.hp <= me.hp_max * 0.45:
		used_wide = true
		name = "wide"
	elif phase == 2 and used_wide and rng.randf() < 0.12:
		name = "wide"
	else:
		name = _weighted(WEIGHTS_1 if phase == 1 else WEIGHTS_2)
	queue = PATTERNS[name].duplicate(true)
	wait = 0
	cooldown = (45 + rng.randi_range(0, 35)) if phase == 1 else (28 + rng.randi_range(0, 30))


func _weighted(table: Array) -> String:
	var total := 0
	for row in table:
		total += int(row[1])
	var r := rng.randi_range(1, total)
	for row in table:
		r -= int(row[1])
		if r <= 0:
			return row[0]
	return table[0][0]
