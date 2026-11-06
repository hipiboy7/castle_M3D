extends "res://tests/helpers.gd"
## 전투 규칙 테스트 — 맞기 · 구르기 무적 · 칼날 쳐내기 · 가드 불가 · 빈틈 → 제압 상한 · 연타 · 2차 바닥 ·
## 기술(엇박 계열 관통 · 엇엇박 · 반대발 · 각법 기절 · 빈틈 우선 · 삼연타 기절 · 게이지) · 백도찬 첫 엇박 → 습득 ·
## 엇박 구르기 · 결정성.
## (A 등급 — 판정 · 피해 · 기절 · 게이지 · 등급: 손 입력으로 world.tick 을 돌린다)


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


func test_offbeat_pierces_parry_lethal() -> void:
	var d := _close(1.4)
	var h = d["hero"]
	var b = d["boss"]
	_learn(d)
	h.skill_idx = h.skill_index("offbeat")                  # 엇박 찌르기: 4칸, 준비 16 (6에서 멈칫)
	var g0: float = h.gauge
	_tick(d, {"skill": true})
	check(h.state == "attack" and h.move["name"] == "s_offbeat", "기술 버튼 → 엇박 찌르기 (%s)" % h.move.get("name", ""))
	check(is_equal_approx(g0 - h.gauge, 4.0 * Common.bar_points() - Common.passive_per_frame() * h.gauge_rate), "4칸을 쓴다 (%s)" % (g0 - h.gauge))
	for i in 8:
		_tick(d)
	_tick(d, {}, {"parry": true, "parry_held": true})       # 보스가 판정 전에 쳐내기를 들어도
	for i in 20:
		_tick(d, {}, {"parry_held": true})
	check(not _events(d, "pierce").is_empty(), "엇박은 막기 · 쳐내기를 뚫는다")
	check(_events(d, "parry").is_empty(), "엇박은 쳐내지지 않는다")
	var want: float = b.hp_max * (1.0 - Common.lethal_fraction("offbeat", b.rank, h.rank))
	check(is_equal_approx(b.hp, want), "아랫급(내성 상위)이 톱에게: 체력 1/3 × 2/3 (boss hp %s, 기대 %s)" % [b.hp, want])


func test_offbeat2_spends_all_and_self_cost() -> void:
	var d := _close(1.4)
	var h = d["hero"]
	var b = d["boss"]
	d["world"].phase = 2                                    # 1차 바닥(55%)에 막히지 않게
	d["boss"].phase = 2
	_learn(d)
	h.skill_idx = h.skill_index("offbeat2")
	h.gauge = 4.0 * Common.bar_points()
	_tick(d, {"skill": true})
	check(h.state != "attack" and not _events(d, "no_gauge").is_empty(), "엇엇박은 5칸이 안 되면 못 쓴다")
	h.gauge = 6.0 * Common.bar_points()
	_tick(d, {"skill": true})
	check(h.state == "attack" and h.move["name"] == "s_offbeat2", "엇엇박 찌르기 (%s)" % h.move.get("name", ""))
	check(h.gauge < 1.0, "게이지를 전부 쓴다 (%s)" % h.gauge)
	_run(d, 45)
	check(_events(d, "brake").size() == 1, "엇박처럼 나가다 브레이크 한 번 (%d)" % _events(d, "brake").size())
	check(is_equal_approx(b.hp, b.hp_max * (1.0 - 0.6)), "6칸 = 최대 체력 60%% (boss hp %s)" % b.hp)
	check(is_equal_approx(h.hp, h.hp_max * 0.8), "맞히면 내 체력 1/5 를 잃는다 (hero hp %s)" % h.hp)


func test_offbeat_hit_stuns() -> void:
	var d := _close(1.4)
	var h = d["hero"]
	var b = d["boss"]
	_learn(d)
	h.skill_idx = h.skill_index("offbeat")
	_tick(d, {"skill": true})
	_run(d, 22)
	var stuns := _events(d, "stun")
	check(stuns.size() == 1 and int(stuns[0][3]) == 60, "엇박에 맞으면 기절 — 백도찬(윗급) 1초 (%s)" % [stuns])
	check(b.state == "stun", "기절 상태 (%s)" % b.state)


func test_offbeat_whiff_leaves_opening() -> void:
	var d := _close(4.0)                                    # 닿지 않는 거리 — 헛친다
	var h = d["hero"]
	_learn(d)
	h.skill_idx = h.skill_index("offbeat")
	_tick(d, {"skill": true})
	var mv: Dictionary = h.move
	_run(d, Moves.total(mv) + 2)
	check(not _events(d, "whiff").is_empty(), "헛침 신호")
	check(h.state == "attack" and h.in_recovery(), "헛치면 회수 뒤에도 뻗은 채 멈춰 있다 (state %s)" % h.state)
	_tick(d, {"roll": true})
	check(h.state == "attack", "헛친 동안은 구르기로도 못 끊는다 (state %s)" % h.state)
	_run(d, int(mv["whiff"]))
	check(h.state != "attack", "헛침 %d프레임 뒤 풀린다 (state %s)" % [int(mv["whiff"]), h.state])


func test_offbeat2_beats_offbeat() -> void:
	var d := _close(1.6)
	var h = d["hero"]
	var b = d["boss"]
	_learn(d)
	d["world"].phase = 2
	d["boss"].phase = 2
	h.gauge = 5.0 * Common.bar_points()
	h.skill_idx = h.skill_index("offbeat2")
	_tick(d, {}, {"use": "s_offbeat"})                     # 백도찬 엇박(판정 17)
	for i in 6:
		_tick(d)
	_tick(d, {"skill": true})                              # 김신 엇엇박으로 맞받음(판정 27 — 늦다)
	_run(d, 50)
	check(not _events(d, "clash").is_empty(), "엇박이 엇엇박에 부딪힘")
	check(is_equal_approx(h.hp, h.hp_max * 0.8), "엇박은 닿지 않고 김신은 엇엇박 반동만 (hero hp %s)" % h.hp)
	check(b.hp < b.hp_max * 0.6, "엇엇박이 들어간다 (boss hp %s)" % b.hp)


func test_offbeat_rev_light_recovery() -> void:
	var rev := Moves.get_move("s_offbeat_rev")
	var ob := Moves.get_move("s_offbeat")
	check(Moves.total(rev) < Moves.total(ob) and int(rev["whiff"]) == 0, "반대발은 회수가 짧고 헛쳐도 안 멈춘다")
	check(int(rev["stun_3d"][1]) < int(ob["stun_3d"][1]), "반대발은 기절도 짧다")


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
	h.skill_idx = h.skill_index("kickarts")                 # 각법 내려찍기: 준비 14 → 판정 15
	_tick(d, {"skill": true})
	_run(d, 16)
	check(b.state == "stun", "각법에 맞으면 기절 (state %s)" % b.state)
	check(b.hold_t == 60, "같은 급 · 윗급에게는 1초 (%d)" % b.hold_t)
	_run(d, 75)                                             # 역경직 12 + 기절 60
	check(b.state != "stun", "1초 뒤 풀린다 (state %s)" % b.state)


func test_kick_breaking_posture_is_stagger_not_stun() -> void:
	var d := _close(0.8)
	var h = d["hero"]
	var b = d["boss"]
	b.posture = b.posture_max - 5.0
	h.skill_idx = h.skill_index("kickarts")
	_tick(d, {"skill": true})
	_run(d, 16)
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


## 어긋남 ①: 등급 차 강함 — 보통 공격 피해 × rank_damage_k, 한참 아랫급의 공격에는 움찔하지 않는다(shrugs_off).
## 이 결투(1등급 차)에서는 1.0 이라, 등급을 바꿔 연결만 본다
func test_rank_gap_damage_and_armor() -> void:
	var d := _close()
	var h = d["hero"]
	var b = d["boss"]
	h.rank = "재앙"
	b.rank = "외성 하위"                                     # 7등급 차 → 2.5배 · 0.58배 · 김신은 움찔 안 함
	_tick(d, {"attack": true})
	_run(d, 30)
	var k_up := Common.rank_damage_k("재앙", "외성 하위")
	check(is_equal_approx(b.hp, b.hp_max - 7.0 * k_up), "윗급의 베기 = 7 × %s (boss hp %s)" % [k_up, b.hp])
	var d2 := _close(0.9)
	d2["hero"].rank = "재앙"
	d2["boss"].rank = "외성 하위"
	_tick(d2, {}, {"use": "b_slash1"})
	var flinch := false
	for i in 15 + World.LATE_PARRY + 4:
		_tick(d2)
		flinch = flinch or d2["hero"].state == "hitstun"
	var k_down := Common.rank_damage_k("외성 하위", "재앙")
	check(is_equal_approx(d2["hero"].hp, d2["hero"].hp_max - 9.0 * k_down), "아랫급의 베기 = 9 × %s (hero hp %s)" % [k_down, d2["hero"].hp])
	check(not flinch, "한참 아랫급에게 맞아도 움찔하지 않는다")


## 어긋남 ⑤: 구르기로 피하면 게이지가 찬다 (gauge.gain.dodge × 배율)
func test_dodge_gains_gauge() -> void:
	var d := _close(1.0)
	var h = d["hero"]
	_tick(d, {}, {"use": "b_thrust"})                       # 판정 17 ~ 20
	for i in 14:
		_tick(d)
	var g0: float = h.gauge
	_tick(d, {"roll": true, "move": Vector2(0, 1)})         # 판정 때 구르기 무적 초반(아직 사거리 안)
	var dodged := false
	for i in 30:
		_tick(d)
		dodged = dodged or not _events(d, "dodge").is_empty()
		if dodged:
			break
	check(dodged, "피함 신호")
	var want: float = Common.gain_points("dodge") * h.gauge_rate
	check(h.gauge - g0 >= want - 0.001, "피하면 %s 이상 찬다 (%s)" % [want, h.gauge - g0])


## 작은 길잡이 함수 — world.hero() · boss() · fighter.current_skill() · common.rules()
func test_accessors() -> void:
	var d := _close()
	var w = d["world"]
	check(w.hero() == d["hero"] and w.boss() == d["boss"], "world.hero() · boss() 가 두 사람을 돌려준다")
	var h = d["hero"]
	check(h.current_skill()["id"] == h.skills[h.skill_idx]["id"], "고른 기술")
	h.skills = []
	check(h.current_skill().is_empty(), "기술이 없으면 빈 것")
	check(Common.rules().has("gauge") and Common.rules()["gauge"] == Common.gauge(), "rules() 의 gauge = gauge()")
