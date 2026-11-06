extends "res://tests/helpers.gd"
## 통합 시험(B 등급) — duel.gd 흐름 · 백도찬 AI · 봇 · 같은 시드 같은 결과 · 공통 데이터로 만든 결투 값.


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


## S1 공통 받기: 결투의 2층 값이 공통 데이터에서 온다 — 김신 등급은 진행(6장 백도찬전 앞 = 내성 상위), 게이지 10칸 ·
## 배율 4.988(fast_rank_k 2배 포함, 어긋남 ④), 비용 = skill_cost, 이름 = skills.json · characters.json
func test_duel_values_from_common() -> void:
	var d := Duel.make(1)
	var h = d["hero"]
	var b = d["boss"]
	check(h.char_id == "kimshin" and h.name == "김신" and b.char_id == "baekdochan" and b.name == "백도찬", "인물 id · 이름")
	check(h.rank == "내성 상위" and b.rank == "톱", "등급 (%s · %s)" % [h.rank, b.rank])
	check(is_equal_approx(h.gauge_max, 10.0 * Common.bar_points()), "게이지 10칸 (%s)" % h.gauge_max)
	check(absf(h.gauge_rate - 4.988) < 1e-9, "차는 배율 4.988 (%s)" % h.gauge_rate)
	var got := []
	for sk in h.skills:
		got.append([sk["id"], sk["name"], sk["cost"]])
	check(got == [["kickarts", "각법", 1.0], ["triple", "리천식 삼연타", 1.0]],
		"처음 기술 — 동작이 있는 것만(스텝 · 촌경 빠짐) %s" % [got])
	_learn(d)
	got = []
	for sk in h.skills:
		got.append([sk["id"], sk["name"], sk["cost"]])
	check(got.slice(0, 3) == [["offbeat2", "엇엇박 찌르기", -1.0], ["offbeat", "엇박 찌르기", 4.0], ["offbeat_rev", "반대발 엇박 찌르기", 2.0]],
		"엇박 습득 — rank_order 순 · 비용 공식 %s" % [got])
	check(Moves.get_move("s_offbeat2")["lethal"] == "offbeat2" and is_equal_approx(Moves.get_move("s_offbeat2")["self_cost"], 0.2),
		"엇엇박 효과는 skills.json effects 에서")
