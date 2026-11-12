extends "res://tests/helpers.gd"
## 피하기 · 점프 · 벽 밟기 · 앉기(2026-11-12 사용자 "'쳐내기' 기능이 없는 캐릭터들은 해당 버튼을 '피하기'로 … '점프'와 '앉기' 버튼과
## 기능 … 점프해서 벽에 붙으면 벽을 밟는 기능") — 등급 A(fighter 상태 기계 · world 판정): 시험 먼저.



func _evader(d: Dictionary) -> void:
	var h = d["hero"]
	h.can_parry = false
	h.evade_btn = true


## 쳐내기가 없는 사람(evade_btn)의 쳐내기 버튼 = 피하기: 짧게 비켜서며 무적 — 찌르기를 안 맞는다
func test_evade_dodges_thrust() -> void:
	var d := _close(1.0)
	_evader(d)
	var x0: float = d["hero"].pos.x
	_tick(d, {}, {"use": "b_thrust"})                       # 준비 16 → 판정 17 ~ 20
	for i in 13:
		_tick(d)
	_tick(d, {"parry": true, "parry_held": true})           # 판정 직전에 피하기
	check(d["hero"].state == "evade", "쳐내기 버튼이 피하기가 된다 (%s)" % d["hero"].state)
	_run(d, 30)
	check(is_equal_approx(d["hero"].hp, Duel.HERO["hp"]), "피하기 무적이면 안 맞는다 (hero hp %s)" % d["hero"].hp)
	check(d["hero"].pos.x < x0 - 0.4, "상대 반대쪽으로 비켜선다 (%.2f → %.2f)" % [x0, d["hero"].pos.x])
	check(d["hero"].state == "idle", "끝나면 선다 (%s)" % d["hero"].state)


## 쳐내기가 있는 사람(김신)은 그대로 쳐내기
func test_parry_stays_for_parry_users() -> void:
	var d := _close(1.0)
	_tick(d, {"parry": true, "parry_held": true})
	check(d["hero"].state == "parry", "김신은 쳐내기 (%s)" % d["hero"].state)


## 점프: 떠올랐다(air > 0) 내려온다. 공중 가운데는 무적(바닥 기술을 넘는다)
func test_jump_up_and_land() -> void:
	var d := _close(3.0)
	var h = d["hero"]
	_tick(d, {"jump": true})
	check(h.state == "jump", "점프 (%s)" % h.state)
	var top := 0.0
	var safe := false
	for i in Fighter.JUMP_T / 2:
		_tick(d)
		top = maxf(top, h.air)
		safe = safe or h.iframes()
	check(top > 0.6 and safe, "떠오르고(%.2f m) 공중에서는 무적" % top)
	_run(d, Fighter.JUMP_T)
	check(h.state == "idle" and is_zero_approx(h.air), "내려와 선다 (%s · %.2f)" % [h.state, h.air])


## 점프로 찌르기를 넘는다
func test_jump_dodges_thrust() -> void:
	var d := _close(1.0)
	_tick(d, {}, {"use": "b_thrust"})
	for i in 7:
		_tick(d)
	_tick(d, {"jump": true})
	_run(d, 40)
	check(is_equal_approx(d["hero"].hp, Duel.HERO["hp"]), "공중이면 안 맞는다 (hero hp %s)" % d["hero"].hp)


## 벽 밟기: 점프 중 맵 끝(벽)에 닿아 그쪽으로 밀면 벽을 차고 반대로 한 번 더 뛴다(점프 한 번에 한 번)
func test_wall_step() -> void:
	var d := _close(4.0)
	var w = d["world"]
	var h = d["hero"]
	h.pos = Vector2(w.bounds.position.x + 0.3, 0.0)
	_tick(d, {"jump": true, "move": Vector2(-1, 0)})
	var stepped := false
	var vx := 0.0
	var st := ""
	for i in 30:
		_tick(d, {"move": Vector2(-1, 0)})
		if not stepped and not _events(d, "wall_step").is_empty():
			stepped = true
			vx = h.jump_vel.x
			st = h.state
		w.events.clear()
	check(stepped and h.wall_used, "벽을 밟는다")
	check(st == "jump" and vx > 0.5, "벽 반대쪽으로 다시 뛴다 (%s · %.2f)" % [st, vx])
	var again := false
	for i in 20:
		_tick(d, {"move": Vector2(-1, 0)})
		again = again or not _events(d, "wall_step").is_empty()
		w.events.clear()
	check(not again, "한 점프에 한 번만")


## 앉기: 높은 공격(베기)은 머리 위로 지나가고, 낮은 공격(로우킥)은 맞는다. 앉은 채 걸으면 느리다
func test_crouch_ducks_high_not_low() -> void:
	var d := _close(0.9)
	_tick(d, {"crouch": true}, {"use": "b_slash1"})
	check(d["hero"].crouching, "앉는다")
	for i in 30:
		_tick(d, {"crouch": true})
	check(is_equal_approx(d["hero"].hp, Duel.HERO["hp"]), "앉으면 베기가 지나간다 (hp %s)" % d["hero"].hp)
	var d2 := _close(0.9)
	_tick(d2, {"crouch": true}, {"use": "ku_front"})
	for i in 40:
		_tick(d2, {"crouch": true})
	check(d2["hero"].hp < Duel.HERO["hp"], "로우킥은 앉아도 맞는다 (hp %s)" % d2["hero"].hp)
	var d3 := _close(4.0)
	var x0: float = d3["hero"].pos.x
	for i in 30:
		_tick(d3, {"crouch": true, "move": Vector2(1, 0)})
	var crouch_x: float = d3["hero"].pos.x - x0
	var d4 := _close(4.0)
	for i in 30:
		_tick(d4, {"move": Vector2(1, 0)})
	check(crouch_x < (d4["hero"].pos.x - x0) * 0.6, "앉은 걸음은 느리다 (%.2f m)" % crouch_x)


## 앉아서 치면 낮은 발(쓸기), 공중에서 치면 날아차기
func test_crouch_and_air_attacks() -> void:
	var d := _close(3.0)
	_tick(d, {"crouch": true, "attack": true})
	check(d["hero"].state == "attack" and str(d["hero"].move["name"]) == Fighter.CROUCH_MOVE, "앉아 치기 (%s)" % d["hero"].move.get("name", ""))
	var d2 := _close(3.0)
	_tick(d2, {"jump": true})
	_run(d2, 6)
	_tick(d2, {"attack": true})
	_tick(d2)
	check(d2["hero"].state == "attack" and str(d2["hero"].move["name"]) == Fighter.AIR_MOVE, "공중 치기 (%s)" % d2["hero"].move.get("name", ""))


## 리플레이 비트: 점프 · 앉기도 기록된다
func test_replay_bits_jump_crouch() -> void:
	var Replay = preload("res://src/combat/replay.gd")
	var q: Dictionary = Replay.quantize({"jump": true, "crouch": true})
	check(q["jump"] and q["crouch"], "점프 · 앉기 비트")
