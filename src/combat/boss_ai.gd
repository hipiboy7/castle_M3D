extends RefCounted
## 백도찬 AI — 다른 컨트롤러처럼 Fighter.intent 만 채운다.
## 패턴 · 박자 · 맞수(칼날 쳐내기) · 백도찬식 찌르기는 castle_M `docs/P2_설계서_M1전투핵심.md` 8.1 · 8.2절.
## 초안에서 뺀 것: 쓸어 베기(점프가 없다) · 손등 받기 · 엇박 찌르기(원조) · 동요 · 전력 컷인 연출.

const Fighter = preload("res://src/combat/fighter.gd")
const Moves = preload("res://src/data/moves.gd")

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


func _init(boss, hero, r: RandomNumberGenerator) -> void:
	me = boss
	foe = hero
	rng = r


## 2차: 안경을 벗는다 — 피해 ×1.2 · 쳐내기 창 +2 · 맞수 확률 0.6. 김신 상대라 전력(피해 ×1.1 · 창 +1 더)
func enter_phase2() -> void:
	phase = 2
	parry_rate = 0.6
	vital_rate = 0.4
	me.dmg_k = 1.2 * 1.1
	me.parry_extra = 3
	queue.clear()
	cooldown = 40


func decide() -> Dictionary:
	var it := {"move": Vector2.ZERO, "face": me.dir_to(foe)}
	if not me.alive() or not foe.alive():
		return it
	var d: float = me.dist_to(foe)
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
	# 3. 김신이 공격을 시작하면(정면 · 사거리 안 · 시작 2프레임 안) 확률로 칼날 쳐내기
	if foe.state == "attack" and foe.t <= 2 and foe.attack_id != seen_attack and d < 2.4 \
			and foe.facing.dot(foe.dir_to(me)) > 0.5:
		seen_attack = foe.attack_id
		if rng.randf() < parry_rate:
			it["parry"] = true
			it["parry_side"] = Moves.parry_side(foe.move)
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
