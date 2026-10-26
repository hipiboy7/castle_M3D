extends RefCounted
## 자동 플레이 봇 (김신 쪽) — 예고 표시만 보고 받는다: 흰 ! 는 표시된 쪽(왼 · 오른)으로 쳐내기, 빨간 ! 는 구르기.
## castle_M BotController 처럼 '표시만 보고 이길 수 있는지'로 예고의 공정성을 확인하고, 데모 · 자동 점검에 쓴다.
## skill 은 제때 누를 확률(사람처럼 가끔 놓친다). 같은 시드면 같은 결과.

const Fighter = preload("res://src/combat/fighter.gd")

var me
var foe
var rng: RandomNumberGenerator
var skill := 0.85
var answered := -1
var hold := 0
var poke_t := 0


func _init(hero, boss, r: RandomNumberGenerator) -> void:
	me = hero
	foe = boss
	rng = r


func decide() -> Dictionary:
	var to: Vector2 = me.dir_to(foe)
	var it := {"move": Vector2.ZERO, "face": to}
	if not me.alive() or not foe.alive():
		return it
	var d: float = me.dist_to(foe)
	if hold > 0:
		hold -= 1
		it["parry_held"] = true
		return it
	var tel: Array = foe.telegraph()
	if not tel.is_empty() and d < 3.2 and foe.attack_id != answered:
		var kind: String = tel[0]
		var left: int = tel[1]
		if kind == "parry" and left <= 4 and left >= 1:
			answered = foe.attack_id
			if rng.randf() < skill:
				it["parry"] = true
				it["parry_side"] = tel[2]
				it["parry_held"] = true
				hold = Fighter.PARRY_MIN
			return it
		if kind == "unblock" and left <= 7:
			answered = foe.attack_id
			if rng.randf() < skill:
				var side := Vector2(-to.y, to.x) * (1.0 if rng.randf() < 0.5 else -1.0)
				it["roll"] = true
				it["move"] = (side - to * 0.6).normalized()
			return it
	var open: bool = foe.state in ["stagger", "recoil", "hitstun", "down"] or foe.in_recovery()
	if me.counter_ready > 0 or open:
		if d > 1.15:
			it["move"] = to
		elif me.can_act() or me.state == "attack":
			it["attack"] = true
		return it
	# 기다리며 거리 조절, 가끔 먼저 찔러 본다 (맞수를 부르는 공격)
	if d > 1.9:
		it["move"] = to * 0.8
	elif d < 1.1:
		it["move"] = -to * 0.6
	else:
		it["move"] = Vector2(-to.y, to.x) * 0.35
	poke_t -= 1
	if poke_t <= 0 and d < 1.5 and me.can_act():
		poke_t = 50 + rng.randi_range(0, 60)
		it["attack"] = true
	return it
