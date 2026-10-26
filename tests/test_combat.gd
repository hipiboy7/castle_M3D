extends RefCounted
## 전투 규칙 테스트 — 맞기 · 구르기 무적 · 칼날 쳐내기 · 가드 불가 · 빈틈 → 제압 상한 · 연타 · 2차 바닥 ·
## 기술(엇박 계열 관통 · 엇엇박 · 반대발 · 각법 기절 · 빈틈 우선 · 삼연타 기절 · 게이지) · 백도찬 첫 엇박 → 습득 ·
## 엇박 구르기 · 결정성.

const Duel = preload("res://src/combat/duel.gd")
const Fighter = preload("res://src/combat/fighter.gd")
const Moves = preload("res://src/data/moves.gd")
const World = preload("res://src/combat/world.gd")
const Skills = preload("res://src/data/skills.gd")

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


func _events(d: Dictionary, kind: String) -> Array:
	var out := []
	for e in d["world"].events:
		if e[0] == kind:
			out.append(e)
	return out


## 백도찬이 엇박을 쓴 것처럼 — 김신이 엇박 계열을 얻는다 (엇엇박 · 엇박 · 반대발 엇박 · 각법 · 삼연타)
func _learn(d: Dictionary) -> void:
	Duel._boss_offbeat(d)
	d["world"].slowmo = 0


func test_offbeat_pierces_parry_lethal() -> void:
	var d := _close(1.4)
	var h = d["hero"]
	var b = d["boss"]
	_learn(d)
	h.skill_idx = h.skill_index("offbeat")                  # 엇박 찌르기: 4칸, 준비 16 (6에서 멈칫)
	var g0: float = h.gauge
	_tick(d, {"skill": true})
	check(h.state == "attack" and h.move["name"] == "s_offbeat", "기술 버튼 → 엇박 찌르기 (%s)" % h.move.get("name", ""))
	check(is_equal_approx(g0 - h.gauge, 4.0 * Skills.BAR - Skills.PASSIVE * h.gauge_rate), "4칸을 쓴다 (%s)" % (g0 - h.gauge))
	for i in 8:
		_tick(d)
	_tick(d, {}, {"parry": true, "parry_held": true})       # 보스가 판정 전에 쳐내기를 들어도
	for i in 20:
		_tick(d, {}, {"parry_held": true})
	check(not _events(d, "pierce").is_empty(), "엇박은 막기 · 쳐내기를 뚫는다")
	check(_events(d, "parry").is_empty(), "엇박은 쳐내지지 않는다")
	var want: float = b.hp_max * (1.0 - Skills.lethal_fraction("offbeat", b.rank, h.rank))
	check(is_equal_approx(b.hp, want), "아랫급(내성 상위)이 톱에게: 체력 1/3 × 2/3 (boss hp %s, 기대 %s)" % [b.hp, want])


func test_offbeat2_spends_all_and_self_cost() -> void:
	var d := _close(1.4)
	var h = d["hero"]
	var b = d["boss"]
	d["world"].phase = 2                                    # 1차 바닥(55%)에 막히지 않게
	_learn(d)
	h.skill_idx = h.skill_index("offbeat2")
	h.gauge = 4.0 * Skills.BAR
	_tick(d, {"skill": true})
	check(h.state != "attack" and not _events(d, "no_gauge").is_empty(), "엇엇박은 5칸이 안 되면 못 쓴다")
	h.gauge = 6.0 * Skills.BAR
	_tick(d, {"skill": true})
	check(h.state == "attack" and h.move["name"] == "s_offbeat2", "엇엇박 찌르기 (%s)" % h.move.get("name", ""))
	check(h.gauge < 1.0, "게이지를 전부 쓴다 (%s)" % h.gauge)
	_run(d, 45)
	check(_events(d, "feint").size() == 2, "두 번 멈칫한다 (%d)" % _events(d, "feint").size())
	check(is_equal_approx(b.hp, b.hp_max * (1.0 - 0.6)), "6칸 = 최대 체력 60%% (boss hp %s)" % b.hp)
	check(is_equal_approx(h.hp, h.hp_max * 0.8), "맞히면 내 체력 1/5 를 잃는다 (hero hp %s)" % h.hp)


func test_offbeat_rev_half() -> void:
	var d := _close(1.3)
	var h = d["hero"]
	var b = d["boss"]
	_learn(d)
	h.skill_idx = h.skill_index("offbeat_rev")
	_tick(d, {"skill": true})
	_run(d, 35)
	var want: float = b.hp_max * (1.0 - 1.0 / 3.0 * 0.5 * 2.0 / 3.0)
	check(is_equal_approx(b.hp, want), "반대발 엇박 = 엇박의 절반 (boss hp %s, 기대 %s)" % [b.hp, want])


func test_kick_stuns_boss_one_second() -> void:
	var d := _close(0.8)
	var h = d["hero"]
	var b = d["boss"]
	h.skill_idx = h.skill_index("kickarts")                 # 각법 내려찍기: 준비 12 → 판정 13
	_tick(d, {"skill": true})
	_run(d, 14)
	check(b.state == "stun", "각법에 맞으면 기절 (state %s)" % b.state)
	check(b.hold_t == 60, "같은 급 · 윗급에게는 1초 (%d)" % b.hold_t)
	_run(d, 75)                                             # 역경직 10 + 기절 60
	check(b.state != "stun", "1초 뒤 풀린다 (state %s)" % b.state)


func test_kick_breaking_posture_is_stagger_not_stun() -> void:
	var d := _close(0.8)
	var h = d["hero"]
	var b = d["boss"]
	b.posture = b.posture_max - 5.0
	h.skill_idx = h.skill_index("kickarts")
	_tick(d, {"skill": true})
	_run(d, 14)
	check(b.state == "stagger", "같은 대에 체간이 다 차면 빈틈 (state %s)" % b.state)
	check(_events(d, "stun").is_empty(), "빈틈이면 '기절!' 이 뜨지 않는다")


func test_triple_three_hits() -> void:
	var d := _close(0.8)
	var h = d["hero"]
	var b = d["boss"]
	h.skill_idx = h.skill_index("triple")                   # 리천식 삼연타: 판정 15프레임에 세 번
	_tick(d, {"skill": true})
	_run(d, 60)
	var nos := []
	for e in _events(d, "hit"):
		nos.append(int(e[3].get("hit_no", 0)))
	check(nos == [1, 2, 3], "주먹 세 번, 순서 번호 (%s)" % [nos])
	check(is_equal_approx(b.hp, b.hp_max - 21.0), "7 × 3 (boss hp %s)" % b.hp)
	var stuns := _events(d, "stun")
	check(stuns.size() == 1 and int(stuns[0][3]) == 30, "셋째 대에 각법의 절반(0.5초) 기절 (%s)" % [stuns])


func test_skill_needs_gauge() -> void:
	var d := _close(0.8)
	var h = d["hero"]
	h.gauge = 50.0
	h.skill_idx = 0
	_tick(d, {"skill": true})
	check(h.state != "attack", "게이지가 모자라면 기술이 안 나간다 (state %s)" % h.state)
	check(not _events(d, "no_gauge").is_empty(), "게이지 부족 신호")
	_tick(d, {"skill_next": true})
	check(h.skill_idx == 1, "기술 바꾸기 (%d)" % h.skill_idx)
	check(h.skill_index("offbeat") < 0, "엇박 계열은 백도찬이 쓰기 전에는 없다")


func test_boss_first_offbeat_teaches() -> void:
	var d := Duel.make(1)
	var h = d["hero"]
	var b = d["boss"]
	d["ai"].parry_rate = 0.0
	b.hp = b.hp_max * 0.9
	var learned := false
	var lethal_on_hero := false
	var slow := false
	var low: float = h.hp
	for i in 400:
		Duel.step(d, {"move": Vector2.ZERO, "face": h.dir_to(b)})       # 김신은 가만히 (구르지 않는다)
		slow = slow or d["world"].slowmo > 0
		low = minf(low, h.hp)
		for e in d["world"].events:
			learned = learned or e[0] == "learn"
			lethal_on_hero = lethal_on_hero or (e[0] == "lethal" and e[1] == h)
		d["world"].events.clear()
		if d["ai"].demo == "done":
			break
	check(learned, "백도찬이 엇박을 쓰면 김신이 엇박 계열을 얻는다")
	check(h.skill_index("offbeat2") >= 0 and h.skill_index("offbeat_rev") >= 0, "엇엇박 · 반대발 엇박도 (%s)" % [h.skills])
	check(lethal_on_hero, "첫 엇박이 김신에게 들어간다(안 구르면)")
	check(slow, "첫 엇박은 슬로모션")
	check(low >= h.hp_max * Skills.BAEK_OFFBEAT["demo_floor"] - 0.001, "첫 엇박 장면에서 김신은 25%% 아래로 안 내려간다 (%s)" % low)
	check(d["ai"].demo == "done" and h.hp_floor == 0.0 and b.hp_floor == 0.0, "장면이 끝나면 체력 바닥을 푼다")


func test_baek_rolls_from_offbeat() -> void:
	var d := _close(1.4)
	var h = d["hero"]
	var b = d["boss"]
	var ai = d["ai"]
	_learn(d)
	ai.dodge_rate = 1.0
	ai.parry_rate = 0.0
	ai.cooldown = 9999
	h.skill_idx = h.skill_index("offbeat")
	var face: Vector2 = h.dir_to(b)
	Duel.step(d, {"skill": true, "face": face})
	for i in 40:
		Duel.step(d, {"face": face})
	check(is_equal_approx(b.hp, b.hp_max), "백도찬은 자유로우면 엇박 계열을 보고 구른다 (boss hp %s)" % b.hp)


func test_deterministic_same_seed() -> void:
	var a := Duel.simulate(7, 2400)
	var b := Duel.simulate(7, 2400)
	check(a == b, "같은 시드면 같은 결과\n%s\n%s" % [a, b])


func test_bot_fights_boss() -> void:
	var r := Duel.simulate(3, 3600)
	check(r["boss_hp"] < Duel.BOSS["hp"], "봇이 1분 안에 보스에게 피해를 준다 %s" % r)
	check(r["stats"]["parries"] > 0, "봇이 흰 ! 를 보고 쳐낸다 %s" % r)
