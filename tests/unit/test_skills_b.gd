extends "res://tests/helpers.gd"
## rc.2 폰 피드백 묶음 B(사용자 2026-11-07) — 대시 버튼 · 아무르 티그로 3연타 · 위빙 · 좌우로 사라지는 스텝 · 서진태 오리지널 ·
## 근거리 급소 베기 · 난무 · 피우진 미친 코어 카운터 · 등급 차 한 방(3D 덧붙임). A 등급 — 손 입력으로 world.tick 을 돌린다.
## 판은 6장 결투(김신 내성 중위 대 백도찬 톱)를 빌려 쓰고, 등급 · 무적 플래그는 시험마다 바꿔 끼운다.



func _use(d: Dictionary, sid: String) -> void:
	var h = d["hero"]
	if h.skill_index(sid) < 0:
		h.skills.append({"id": sid, "name": sid, "move": str(Skills.MOVE_OF[sid]), "cost": 0.0})
	h.skill_idx = h.skill_index(sid)
	_tick(d, {"skill": true})


## 백도찬을 '무리'처럼 — 한 방을 받을 수 있게(보스 표시 · 버팀 · 2차 · 바닥을 끈다)
func _as_mob(b, rank: String) -> void:
	b.rank = rank
	b.oneshot_immune = false
	b.is_boss = false
	b.poise = 0.0
	b.phase2_at = 0.0
	b.hp_floor = 0.0


func test_dash_button_runs_and_dash_attack() -> void:
	var d := _close(4.0)
	var h = d["hero"]
	var x0: float = h.pos.x
	_tick(d, {"dash": true, "move": Vector2(1, 0)})
	for i in 5:
		_tick(d, {"move": Vector2(1, 0)})
	var per_frame: float = (h.pos.x - x0) / 6.0
	check(per_frame > h.run_speed / 60.0 * 1.4, "대시는 달리기보다 빠르다 (%.3f m/프레임)" % per_frame)
	_tick(d, {"attack": true})
	check(h.state == "attack" and str(h.move["name"]) == "k_dash" and str(h.move["label"]) == "아무르 티그로 대시",
		"대시 중 공격 = 아무르 티그로 대시 (%s %s)" % [h.state, h.move.get("name", "")])


func test_dash_grace_then_attack() -> void:
	var d := _close(6.0)
	var h = d["hero"]
	_tick(d, {"dash": true})
	for i in Fighter.DASH_T + 2:
		_tick(d)
	_tick(d, {"attack": true})
	check(str(h.move.get("name", "")) == "k_dash", "대시가 끝난 직후 공격도 대시기 (%s)" % h.move.get("name", ""))
	var d2 := _close(6.0)
	_tick(d2, {"attack": true})
	check(str(d2["hero"].move.get("name", "")) == "k_slash1", "서서 공격하면 보통 베기")


func test_amur_triple_three_booms_stun_and_high_rank() -> void:
	var d := _close(0.8)
	var b = d["boss"]
	_use(d, "amur_triple")
	_run(d, 40)
	var nos := []
	for e in _events(d, "hit"):
		nos.append(int(e[3].get("hit_no", 0)))
	check(nos == [1, 2, 3], "하복부 세 대 (%s)" % [nos])
	var stuns := _events(d, "stun")
	check(stuns.size() == 1 and int(stuns[0][3]) == 30, "셋째 대에 0.5초 기절 (%s)" % [stuns])
	var k := maxf(1.0, Common.rank_damage_k(d["hero"].rank, b.rank)) * 1.6
	check(is_equal_approx(b.hp, b.hp_max - 9.0 * 3.0 * k), "외성 이상(톱)에게 × 1.6 — %s (hp %s)" % [k, b.hp])


func test_weaving_dodges_and_kills_low_rank() -> void:
	var d := _close(0.8)
	var h = d["hero"]
	var b = d["boss"]
	var hp0: float = h.hp
	_tick(d, {}, {"use": "b_thrust"})                       # 준비 16 → 판정 17 ~ 20
	_run(d, 12)
	_use(d, "amur_weaving")                                 # 위빙 준비 중에 찌르기가 닿는다
	_run(d, 30)
	check(is_equal_approx(h.hp, hp0) and not _events(d, "dodge").is_empty(), "위빙 중에는 맞지 않는다 (hp %s)" % h.hp)
	var d2 := _close(0.8)
	_as_mob(d2["boss"], "외성 상위")
	_use(d2, "amur_weaving")
	_run(d2, 30)
	check(not d2["boss"].alive() and not _events(d2, "oneshot").is_empty(), "외성 이하는 한 방 (hp %s)" % d2["boss"].hp)
	var d3 := _close(0.8)
	d3["boss"].rank = "외성 상위"
	_use(d3, "amur_weaving")
	_run(d3, 30)
	check(d3["boss"].alive(), "방의 보스(oneshot_immune)는 한 방이 아니다 (hp %s)" % d3["boss"].hp)


func test_vanish_step_unblockable_by_rank() -> void:
	var d := _close(0.9)
	var b = d["boss"]
	b.rank = "내성 중위"
	_use(d, "vanish_step")
	for i in 30:
		_tick(d, {}, {"parry": true, "parry_held": true})
	check(_events(d, "block").is_empty() and not _events(d, "hit").is_empty(), "내성 중위 이하는 못 막는다(맞음)")
	var d2 := _close(0.9)
	d2["boss"].rank = "내성 상위"
	_use(d2, "vanish_step")
	for i in 30:
		_tick(d2, {}, {"parry": true, "parry_held": true})
	check(not _events(d2, "block").is_empty() or not _events(d2, "parry").is_empty(), "내성 상위부터는 막는다")
	var d3 := _close(0.8)
	_use(d3, "vanish_step")
	var hp0: float = d3["hero"].hp
	_tick(d3, {}, {"use": "b_thrust"})
	_run(d3, 20)
	check(is_equal_approx(d3["hero"].hp, hp0), "스텝 중에는 무적 (hp %s)" % d3["hero"].hp)


func test_jintae_original_and_storm() -> void:
	var d := _close(0.8)
	_as_mob(d["boss"], "외성 하위")
	_use(d, "jin_original")
	_run(d, 40)
	check(not d["boss"].alive(), "서진태 오리지널 — 외성 하위 이하 한 방")
	var d2 := _close(0.8)
	_as_mob(d2["boss"], "외성 중위")
	_use(d2, "jin_original")
	_run(d2, 40)
	check(d2["boss"].alive() and _events(d2, "hit").size() == 3, "외성 중위는 세 대를 맞고 버틴다 (%d대)" % _events(d2, "hit").size())
	var mv: Dictionary = Moves.get_move("s_jt_storm")
	check(str(mv["shape"]) == "spin" and int(mv["hits"]) == 3 and float(mv["radius"]) > 1.0, "난무 — 둘레 전부 세 바퀴")
	var d3 := _close(0.8)
	var w = d3["world"]
	var other := Fighter.new("둘째", 1)
	other.rank = "건달급"
	other.pos = Vector2(-0.9, 0.3)
	other.hp = 1000.0
	other.hp_max = 1000.0
	w.add(other)
	_use(d3, "jintae_storm")
	_run(d3, 40)
	check(other.hp < 1000.0 and d3["boss"].hp < d3["boss"].hp_max, "난무는 앞뒤의 둘 다 벤다 (%s · %s)" % [other.hp, d3["boss"].hp])
	var vit: Dictionary = Moves.get_move("s_jt_vital")
	check(int(vit["startup"]) <= 2 and float(vit["reach"]) < float(Moves.get_move("jk_slash1")["reach"]), "근거리 급소 베기 — 빠르고 짧다")


func test_core_counter_catches_and_stuns() -> void:
	var d := _close(0.8)
	var h = d["hero"]
	var b = d["boss"]
	h.char_id = "woojin"
	_use(d, "woojin_core_counter")
	_tick(d, {}, {"use": "b_thrust"})
	_run(d, 40)
	check(not _events(d, "counter_catch").is_empty(), "받을 자세에서 들어온 공격을 흘린다")
	var stuns := _events(d, "stun")
	check(stuns.size() == 1 and stuns[0][1] == b and int(stuns[0][3]) == 60, "강하게 맞받아 1초 기절 (%s)" % [stuns])


func test_rank_gap_one_shot_rule() -> void:
	check(Skills.one_shot("내성 중위", "준10강", false), "김신(내성 중위) → 준10강 한 방(5등급 차)")
	check(not Skills.one_shot("내성 중위", "외성 하위", false), "외성 하위(4등급 차)는 한 방이 아니다")
	check(not Skills.one_shot("내성 중위", "건달급", true), "조작 인물 · 방의 보스는 빼고")
	var d := _close(0.8)
	_as_mob(d["boss"], "전국구")
	_tick(d, {"attack": true})
	_run(d, 20)
	check(not d["boss"].alive(), "보통 베기 한 대에 전국구 무리가 쓰러진다 (hp %s)" % d["boss"].hp)
