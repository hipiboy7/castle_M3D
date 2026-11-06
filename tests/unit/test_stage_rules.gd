extends "res://tests/helpers.gd"
## 여러 사람 판(11장 호텔 캐슬)에 필요한 판정 규칙(A 등급) — 칼날 쳐내기를 못 하는 사람은 막기만 · 총(일직선 판정) ·
## 사람마다 2차 · 제압 상한 · 쓰러져도 판이 안 끝나는 world · 3D 덧붙임 1층(src/data/addendum.gd) · 능력치 → 3층 배율.

const Addendum = preload("res://src/data/addendum.gd")


## 칼날 쳐내기는 김신 · 백도찬만(castle_common 김신 book '타이밍 패리 — 김신 · 백도찬만') — 다른 사람은 눌러도 막기
func test_no_parry_fighter_only_blocks() -> void:
	var d := _close(0.9)
	var h = d["hero"]
	h.can_parry = false
	_tick(d, {}, {"use": "b_slash1"})                       # 판정 15 ~ 17
	for i in 10:
		_tick(d)
	_tick(d, {"parry": true, "parry_held": true})
	var parried := false
	var blocked := false
	for i in 12:
		_tick(d, {"parry_held": true})
		parried = parried or not _events(d, "parry").is_empty()
		blocked = blocked or not _events(d, "block").is_empty()
		d["world"].events.clear()
	check(not parried and blocked, "쳐내기 못 하는 사람은 막기만 (parry %s block %s)" % [parried, blocked])


## 총: shape "shot" 은 앞으로 뻗은 선분 위 어디든 맞는다(끝 원만이 아니라)
func test_shot_hits_along_line() -> void:
	var d := _close(3.0)
	var b = d["boss"]
	var h = d["hero"]
	b.start_move("t_shot")
	var w = d["world"]
	var hit_far: bool = w._in_hit(b, h)
	h.pos = Vector2(0.0, 1.4)                               # 선에서 옆으로 벗어남
	var off_line: bool = w._in_hit(b, h)
	h.pos = Vector2(-6.0, 0.0)                              # 사거리 밖
	var too_far: bool = w._in_hit(b, h)
	check(hit_far and not off_line and not too_far, "총은 선 위에서만 (선 %s · 옆 %s · 멀리 %s)" % [hit_far, off_line, too_far])


## 제압 상한은 사람마다(finisher_cap) — 백도찬은 8%, 상한이 없는 사람은 제압 피해를 다 받는다
func test_finisher_cap_per_fighter() -> void:
	var d := _close(0.9)
	var b = d["boss"]
	check(is_equal_approx(b.finisher_cap, World.FINISHER_CAP_BOSS), "결투의 백도찬은 상한 8%")
	b.finisher_cap = 0.0
	b.get_stagger()
	var hp0: float = b.hp
	_tick(d, {"attack": true})
	_run(d, 12)
	var mv := Moves.get_move("k_finisher")
	var want: float = mv["damage"] * Common.rank_damage_k(d["hero"].rank, b.rank)
	check(is_equal_approx(hp0 - b.hp, want), "상한 없으면 제압 피해 전부 (%s · %s)" % [hp0 - b.hp, want])


## 2차는 사람마다(phase2_at > 0 인 사람만) · 쓰러져도 판을 끝내지 않는 world(end_on_ko false — 여러 사람 판)
func test_phase2_per_fighter_and_no_end_on_ko() -> void:
	var d := _close(0.9)
	var w = d["world"]
	var b = d["boss"]
	w.end_on_ko = false
	b.phase2_at = 0.0                                       # 2차 없는 적
	b.hp = 1.0
	_tick(d, {"attack": true})
	_run(d, 12)
	check(not b.alive() and w.over == "", "쓰러져도 판이 안 끝난다 (alive %s over '%s')" % [b.alive(), w.over])
	var d2 := _close(0.9)
	var b2 = d2["boss"]
	b2.phase2_at = 0.5
	b2.hp = b2.hp_max * 0.51
	_tick(d2, {"attack": true})
	_run(d2, 12)
	check(b2.phase == 2 and is_equal_approx(b2.hp, b2.hp_max * 0.5), "그 사람 2차 (phase %s hp %s)" % [b2.phase, b2.hp])


## 3D 덧붙임 1층(사용자 답 2026-11-06): 하야부사 준10강 긴칼 · 경호대 최후의 4인 전국구 총/칼 · 구일화 화진 전 전국구 · 교회 전
## 이스크라 평 킬러급 · 주먹/칼. castle_common 에 있는 인물은 castle_common 이 먼저
func test_addendum_characters() -> void:
	var hy := Addendum.character("hayabusa")
	check(hy["rank"] == "준10강" and hy["weapons"] == ["칼"], "하야부사 %s(castle_common 70차 — 원문 '긴칼'은 칼)" % hy)
	var g4 := Addendum.character("gyeonghodaechoehuui4in")
	check(g4["rank"] == "전국구" and g4["weapons"] == ["칼/총"], "4인 %s(castle_common 70차)" % g4)
	check(Addendum.rank_at("guilhwa", "hwajin") == "전국구" and Addendum.rank_at("guilhwa", "church") == "이스크라 평 킬러급",
		"구일화 시기별 등급")
	check(Addendum.stats_at("guilhwa", "hwajin")["맷집"] < Addendum.stats_at("guilhwa", "church")["맷집"], "구일화 교회 전이 더 세다")
	check(Addendum.character("kimshin")["rank"] == "내성 중위", "castle_common 인물은 castle_common 값 그대로")
	for id in ["hayabusa", "gyeonghodaechoehuui4in", "guilhwa", "shingen"]:
		for sid in Addendum.character(id)["skills"]:
			check(not Addendum.skill(sid).is_empty() and Moves.M.has(Addendum.skill(sid)["move"]), "%s 기술 %s 에 동작" % [id, sid])
	# 하향: 하야부사 능력치는 신겐보다 낮고, 4인 · 하야부사 기술은 원본(신겐 · 마준영) 기술의 하향
	var sg := Addendum.stats_at("shingen", "")
	var hs := Addendum.stats_at("hayabusa", "")
	for k in sg:
		check(hs[k] < sg[k], "하야부사 %s < 신겐" % k)
	check(str(Addendum.skill("hayabusa_arc")["from"]) == "shingen_daegeuk", "하야부사 큰 호 베기는 신겐 대극의 하향")
	# castle_common 70차가 기술 1층(이름 · refs)을 가져갔다 — 1층은 공통 값, 동작(3층 move)은 이 판 표에서
	var arc := Addendum.skill("hayabusa_arc")
	check(arc["refs"] == ["019/046-065", "098/024-031"], "기술 1층은 castle_common 값 %s" % arc)
	check(arc["move"] == "s_hy_arc", "기술 동작(3층)은 이 판 표 %s" % arc)
	check(Addendum.skill("guilhwa_headbutt")["move"] == "s_gu_headbutt", "구일화 들이받기 동작")


## 능력치(1층) → 3층 배율: 맷집 → 체력, 힘 → 피해, 속도 → 걸음. 기준 80 = 1배
func test_stat_scaling() -> void:
	var k := Addendum.derive({"힘": 80, "속도": 80, "기술": 80, "맷집": 80})
	check(is_equal_approx(k["hp"], 1.0) and is_equal_approx(k["dmg"], 1.0) and is_equal_approx(k["speed"], 1.0), "80 = 1배 %s" % k)
	var k2 := Addendum.derive({"힘": 40, "속도": 100, "기술": 50, "맷집": 120})
	check(k2["hp"] > 1.0 and k2["dmg"] < 1.0 and k2["speed"] > 1.0 and k2["guard"] < k["guard"], "높고 낮음 %s" % k2)
	check(Addendum.derive({})["hp"] == 1.0, "능력치가 없으면 1배")
