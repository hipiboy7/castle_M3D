extends "res://tests/helpers.gd"
## 등급 능력(A 등급 — src/data/rank_power.gd · 3D 덧붙임): 사용자 2026-11-10 "레벨이 높을수록 동작은 더 빠르고 공격력은 더 높고,
## 체력은 더 많고, 회피율도 높아야 하며, 방어력도 더 높아야함. 재앙급은 거의 외성 미만급에는 타격을 받지 않고, 타격을 맞아도
## 데미지가 방어력이 높아서 덜 들어가야함"

const RP = preload("res://src/data/rank_power.gd")


func test_higher_rank_is_faster_and_tougher() -> void:
	var ladder: Array = Common.ranks()
	for i in range(1, ladder.size()):
		var lo: String = ladder[i - 1]
		var hi: String = ladder[i]
		check(RP.tempo(hi) > RP.tempo(lo), "빠르기 %s > %s" % [hi, lo])
		check(RP.hp_k(hi) > RP.hp_k(lo), "체력 %s > %s" % [hi, lo])
	check(is_equal_approx(RP.tempo(RP.MID), 1.0) and is_equal_approx(RP.hp_k(RP.MID), 1.0), "기준 등급은 1배")
	check(is_equal_approx(RP.tempo(""), 1.0) and is_equal_approx(RP.hp_k(""), 1.0), "등급 없음은 1배")


func test_defense_and_evasion_grow_with_gap() -> void:
	check(is_equal_approx(RP.defense_k("톱", "톱"), 1.0) and RP.evade_p("톱", "톱") == 0.0, "같은 등급은 그대로")
	check(is_equal_approx(RP.defense_k("전국구", "톱"), 1.0) and RP.evade_p("전국구", "톱") == 0.0, "아랫급이 맞을 때는 그대로(공격 배율은 common)")
	var prev_d := 1.0
	var prev_e := 0.0
	for att in ["내성 상위", "내성 하위", "외성 중위", "준10강", "건달급"]:
		var dk := RP.defense_k("톱", att)
		var ep := RP.evade_p("톱", att)
		check(dk <= prev_d and ep >= prev_e, "등급 차가 클수록 덜 들어가고 더 피한다 — 톱 ← %s (%.2f · %.2f)" % [att, dk, ep])
		prev_d = dk
		prev_e = ep
	check(RP.defense_k("톱", "건달급") < 1.0 and RP.evade_p("톱", "건달급") > 0.0, "한참 아랫급")


func test_calamity_vs_below_outer() -> void:
	for att in ["준10강", "이스크라 평 킬러급", "전국구", "건달급"]:
		check(RP.evade_p("재앙", att) >= 0.85, "재앙은 외성 미만의 공격을 거의 다 피한다 — %s %.2f" % [att, RP.evade_p("재앙", att)])
		var total := Common.rank_damage_k(att, "재앙") * RP.defense_k("재앙", att)
		check(total <= 0.2, "맞아도 거의 안 들어간다 — %s %.2f" % [att, total])
	check(RP.evade_p("재앙", "외성 하위") < 0.85, "외성부터는 맞힐 수 있다")


func test_world_applies_evasion_and_defense() -> void:
	# 재앙 김신 ← 건달급: 열 번 쳐서 거의 다 피하고, 맞은 것도 조금만 들어간다
	var w = World.new()
	var k = Fighter.new("김신", 0)
	k.rank = "재앙"
	k.hp_max = 1000.0
	k.hp = 1000.0
	var e = Fighter.new("건달", 1)
	e.rank = "건달급"
	k.can_parry = false
	k.pos = Vector2.ZERO
	e.pos = Vector2(0.8, 0)
	k.facing = Vector2(-1, 0)
	w.fighters = [k, e]
	var mv := Moves.get_move("x_hook")
	var dodged := 0
	for i in 10:
		k.set_state("idle")
		e.start_move("x_hook")
		e.attack_id += i
		var before: float = k.hp
		w.events.clear()
		w._resolve(e, k)
		if w.events.any(func(ev): return ev[0] == "dodge"):
			dodged += 1
		else:
			check(before - k.hp <= float(mv["damage"]) * 0.2 + 0.01, "맞은 피해 %.1f" % (before - k.hp))
		k.hp = 1000.0
		w.pending.clear()
	check(dodged >= 7, "10번 중 피함 %d" % dodged)


func test_tempo_shortens_frames() -> void:
	var f = Fighter.new("a", 0)
	f.rank = "재앙"
	f.start_move("x_hook")
	var base := Moves.get_move("x_hook")
	check(Moves.total(f.move) < Moves.total(base), "재앙은 같은 동작이 짧다 %d < %d" % [Moves.total(f.move), Moves.total(base)])
	check(int(f.move["active"]) >= 1 and int(f.move["startup"]) >= 1, "판정 · 준비는 1프레임 이상")
	var g = Fighter.new("b", 1)
	g.rank = "건달급"
	g.start_move("x_hook")
	check(Moves.total(g.move) > Moves.total(base), "건달급은 길다")


func test_attack_and_crit_by_rank() -> void:
	var ladder: Array = Common.ranks()
	for i in range(1, ladder.size()):
		check(RP.atk_k(ladder[i]) > RP.atk_k(ladder[i - 1]), "공격 %s > %s" % [ladder[i], ladder[i - 1]])
		check(RP.crit_p(ladder[i]) >= RP.crit_p(ladder[i - 1]), "부동심 %s ≥ %s" % [ladder[i], ladder[i - 1]])
	check(is_equal_approx(RP.tempo("재앙"), 1.3) and is_equal_approx(RP.hp_k("재앙"), 1.5), "재앙 빠르기 1.3 · 체력 1.5")
	check(RP.atk_k("재앙") > RP.atk_k("톱") + 0.1, "재앙 공격이 더 많이")
	check(RP.defense_k("톱", "건달급") >= 0.5 - 0.001, "방어 바닥 50%")
	check(RP.evade_p("톱", "건달급") <= 0.45 + 0.001, "회피 위 45%")
	check(RP.crit_p("재앙") == RP.CRIT_MAX and RP.crit_p("내성 상위", "akila") == RP.CRIT_MAX, "부동심은 재앙 · 아킬라가 가장 높다")
	check(RP.crit_p("톱") < RP.CRIT_MAX, "톱은 재앙보다 낮다")


func test_world_crit_doubles() -> void:
	# 아킬라(부동심 최고)가 같은 등급을 스무 번 치면 몇 번은 2배('crit' 신호) — 피해는 보통의 2배
	var w = World.new()
	var a = Fighter.new("아킬라", 0)
	a.char_id = "akila"
	a.rank = "내성 상위"
	var d = Fighter.new("상대", 1)
	d.rank = "내성 상위"
	d.can_parry = false
	a.pos = Vector2.ZERO
	d.pos = Vector2(0.8, 0)
	d.facing = Vector2(1, 0)
	w.fighters = [a, d]
	var crits := 0
	var normal := -1.0
	var big := -1.0
	for i in 20:
		d.hp_max = 1000.0
		d.hp = 1000.0
		d.set_state("idle")
		d.posture = 0.0
		a.start_move("x_hook")
		w.events.clear()
		w.pending.clear()
		w._resolve(a, d)
		var lost: float = 1000.0 - d.hp
		if w.events.any(func(ev): return ev[0] == "crit"):
			crits += 1
			big = lost
		elif lost > 0.0:
			normal = lost
	check(crits >= 1 and crits <= 12, "20번 중 부동심 %d" % crits)
	check(normal > 0.0 and absf(big - normal * 2.0) < 0.01, "부동심은 2배 (%.1f · %.1f)" % [normal, big])
