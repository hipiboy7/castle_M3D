extends RefCounted
## 전투 규칙 테스트 — 맞기 · 구르기 무적 · 칼날 쳐내기 · 가드 불가 · 빈틈 → 제압 상한 · 연타 · 2차 바닥 · 결정성.

const Duel = preload("res://src/combat/duel.gd")
const Fighter = preload("res://src/combat/fighter.gd")
const Moves = preload("res://src/data/moves.gd")
const World = preload("res://src/combat/world.gd")

var failures: Array = []


func check(cond: bool, msg: String) -> void:
	if not cond:
		failures.append(msg)


## 두 사람을 가까이 마주 세운 판 (AI · 봇은 쓰지 않고 손으로 입력을 준다)
func _close(dist := 0.8) -> Dictionary:
	var d := Duel.make(1)
	d["hero"].pos = Vector2(0, 0)
	d["hero"].facing = Vector2(1, 0)
	d["boss"].pos = Vector2(dist, 0)
	d["boss"].facing = Vector2(-1, 0)
	return d


## 손 입력으로 한 프레임 (보스 입력도 직접)
func _tick(d: Dictionary, hero_it := {}, boss_it := {}) -> void:
	var w = d["world"]
	d["hero"].intent = hero_it
	d["boss"].intent = boss_it
	w.tick()


func _run(d: Dictionary, n: int) -> void:
	for i in n:
		_tick(d)


func test_slash_hits() -> void:
	var d := _close()
	_tick(d, {"attack": true})
	_run(d, 30)
	check(is_equal_approx(d["boss"].hp, Duel.BOSS["hp"] - 7.0), "베기 한 번 = 7 (boss hp %s)" % d["boss"].hp)


func test_roll_iframes_dodge_thrust() -> void:
	var d := _close(1.0)
	_tick(d, {}, {"use": "b_thrust"})                       # 준비 16 → 판정 17 ~ 20
	for i in 7:
		_tick(d)
	_tick(d, {"roll": true, "move": Vector2(0, 1)})         # 보스 9프레임째 구르기 → 판정 때 구르기 8 ~ 11프레임
	_run(d, 30)
	check(is_equal_approx(d["hero"].hp, Duel.HERO["hp"]), "구르기 무적이면 안 맞는다 (hero hp %s)" % d["hero"].hp)


func test_parry_recoils_attacker() -> void:
	var d := _close(0.9)
	_tick(d, {}, {"use": "b_slash1"})                       # 준비 14 → 판정 15
	for i in 10:
		_tick(d)
	_tick(d, {"parry": true, "parry_held": true})           # 판정 4프레임 전
	var seen := false
	for i in 12:
		_tick(d, {"parry_held": true})
		for e in d["world"].events:
			seen = seen or e[0] == "parry"
	check(seen, "칼날 쳐내기 신호")
	check(is_equal_approx(d["hero"].hp, Duel.HERO["hp"]), "쳐내면 안 맞는다")
	check(d["boss"].posture > 0.0, "쳐내기 당한 쪽 체간이 찬다")
	check(d["hero"].counter_ready > 0, "쳐낸 쪽은 반격 베기를 낼 수 있다")


func test_late_parry_after_contact() -> void:
	var d := _close(0.9)
	_tick(d, {}, {"use": "b_slash1"})                       # 준비 14 → 판정 15
	for i in 16:
		_tick(d)                                            # 판정이 지나도록 아무것도 안 함 → 맞음이 미뤄진다
	_tick(d, {"parry": true, "parry_held": true})           # 닿은 뒤 늦게 누름
	var seen := false
	for i in 10:
		_tick(d, {"parry_held": true})
		for e in d["world"].events:
			seen = seen or e[0] == "parry"
	check(seen, "닿은 뒤 %d프레임 안에 누르면 쳐내기" % World.LATE_PARRY)
	check(is_equal_approx(d["hero"].hp, Duel.HERO["hp"]), "늦은 쳐내기는 피해가 없다 (hero hp %s)" % d["hero"].hp)
	check(d["hero"].parry_side == "L", "바로 베기는 왼팔로 튕긴다 (%s)" % d["hero"].parry_side)


func test_no_parry_hit_lands_after_grace() -> void:
	var d := _close(0.9)
	_tick(d, {}, {"use": "b_slash1"})
	_run(d, 15 + World.LATE_PARRY + 4)
	check(d["hero"].hp < Duel.HERO["hp"], "안 누르면 미룬 맞음이 들어온다 (hero hp %s)" % d["hero"].hp)


func test_parry_side_by_limb() -> void:
	check(Moves.parry_side(Moves.get_move("b_slash1")) == "L", "바로 베기 → 왼쪽")
	check(Moves.parry_side(Moves.get_move("b_slash2")) == "R", "되베기 → 오른쪽")
	check(Moves.parry_side(Moves.get_move("b_thrust")) == "L", "오른손 찌르기 → 왼쪽")
	check(Moves.parry_side(Moves.get_move("b_sidekick")) == "L", "오른발 옆차기 → 왼쪽")
	check(Moves.parry_side({"shape": "thrust", "hand": "L"}) == "R", "왼손 · 왼발(주먹 · 발차기 포함) → 오른팔")


func test_unblockable_ignores_parry() -> void:
	var d := _close(1.0)
	_tick(d, {}, {"use": "b_vital"})                        # 준비 10, 가드 불가
	for i in 7:
		_tick(d)
	_tick(d, {"parry": true, "parry_held": true})
	for i in 12:
		_tick(d, {"parry_held": true})
	check(d["hero"].hp < Duel.HERO["hp"], "빨간 ! 는 쳐낼 수 없다 (hero hp %s)" % d["hero"].hp)


func test_stagger_then_finisher_capped() -> void:
	var d := _close()
	var b = d["boss"]
	b.posture = b.posture_max - 1.0
	_tick(d, {"attack": true})
	_run(d, 20)
	check(b.state == "stagger", "체간이 차면 빈틈 (state %s)" % b.state)
	var hp_before: float = b.hp
	_tick(d, {"attack": true})
	_run(d, 25)
	check(b.state == "down", "빈틈에 공격 = 제압 → 넘어짐 (state %s)" % b.state)
	check(hp_before - b.hp <= b.hp_max * 0.08 + 0.001, "보스 제압 피해는 최대 체력 8%% 까지 (%s)" % (hp_before - b.hp))


func test_combo_chains_to_second_slash() -> void:
	var d := _close(3.0)
	_tick(d, {"attack": true})
	_run(d, 4)
	_tick(d, {"attack": true})                              # 연타 버퍼 8프레임
	_run(d, 6)
	check(d["hero"].move.get("name", "") == "k_slash2", "베기 → 되베기 (%s)" % d["hero"].move.get("name", ""))


func test_phase2_floor() -> void:
	var d := _close()
	var b = d["boss"]
	b.hp = b.hp_max * 0.56
	_tick(d, {"attack": true})
	var seen := false
	for i in 30:
		_tick(d)
		for e in d["world"].events:
			seen = seen or e[0] == "phase2"
	check(d["world"].phase == 2, "1차 바닥에서 2차로")
	check(is_equal_approx(b.hp, b.hp_max * 0.55), "1차는 55%% 아래로 안 내려간다 (%s)" % b.hp)
	check(seen, "phase2 신호")


func test_deterministic_same_seed() -> void:
	var a := Duel.simulate(7, 2400)
	var b := Duel.simulate(7, 2400)
	check(a == b, "같은 시드면 같은 결과\n%s\n%s" % [a, b])


func test_bot_fights_boss() -> void:
	var r := Duel.simulate(3, 3600)
	check(r["boss_hp"] < Duel.BOSS["hp"], "봇이 1분 안에 보스에게 피해를 준다 %s" % r)
	check(r["stats"]["parries"] > 0, "봇이 흰 ! 를 보고 쳐낸다 %s" % r)
