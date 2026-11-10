extends "res://tests/helpers.gd"
## 통합 시험(B 등급) — 2장 하성 본사 판(src/combat/stage.gd + 장 표 haseong.gd): 같은 시드 같은 결과 · 방마다 조작 인물(cast —
## 방에 없는 사람은 판에 없다 · 교대 없음 · 그 방 사람이 쓰러지면 진다) · 방 표 kit(공사장 맨손 김신) · 따돌리기 방(남궁혁 —
## 버티거나 출구에 닿으면 넘는다 · 쓰러뜨릴 수 없다) · 11장은 그대로 둘이 교대. 전투 내용(S5 묶음 4): 서진태 칼 · 이슬 적/아군 ·
## 2장 1층 기술 · 남궁혁 너클 카운터 · 신태진 2차 · 오지인 길 내주기 · 봇이 보스 방을 넘는다.
## 스테이지(사용자 2026-11-10): 1층 15명 세 무리 + 황보민철 · 위층 복도(피우진 · 김대건 지키며 남궁혁 지나기) · 대표실 한 방씩 · 긴 따돌리기 복도.

const Stage = preload("res://src/combat/stage.gd")
const Haseong = preload("res://src/data/haseong.gd")
const EnemyAI = preload("res://src/combat/enemy_ai.gd")
const Addendum = preload("res://src/data/addendum.gd")


func _room_of(id: String) -> int:
	for i in Haseong.ROOMS.size():
		if Haseong.ROOMS[i]["id"] == id:
			return i
	return -1


func _past_intro(d: Dictionary) -> void:
	for i in Haseong.INTRO_T + 1:
		Stage.step(d, {})
		d["world"].events.clear()


func test_ch2_deterministic() -> void:
	var a := Stage.simulate(5, 4000, {"chapter": "ch2"})
	var b := Stage.simulate(5, 4000, {"chapter": "ch2"})
	check(a == b, "2장 같은 시드면 같은 판\n%s\n%s" % [a, b])
	check(Stage.simulate(6, 4000, {"chapter": "ch2"}) != a, "2장 시드가 다르면 다른 판")


func test_cast_per_room() -> void:
	var d := Stage.make(1, {"chapter": "ch2"})
	var kim = d["heroes"][0]
	var jin = d["heroes"][1]
	check(kim.char_id == "kimshin" and jin.char_id == "jintae", "2장 조작 인물 = 김신 · 서진태")
	check(d["hero"] == kim and d["world"].fighters.has(kim) and not d["world"].fighters.has(jin), "공사장: 김신만 판에 있다")
	check(not Stage.can_swap(d) and Stage.partner(d) == null, "공사장: 교대 없음")
	check(str(kim.moveset["combo"]) == "kf_jab" and str(d["look_of"].get(kim, "")) == "kim_bare", "공사장 kit — 맨손 김신 %s" % [kim.moveset])
	Stage._enter(d, _room_of("lobby"))
	check(d["hero"] == jin and int(d["ctrl"]) == 1, "로비: 서진태를 조작한다")
	check(d["world"].fighters.has(jin) and not d["world"].fighters.has(kim), "로비: 김신은 판에 없다")
	check(d["allies"].any(func(a): return a.char_id == "iseul"), "로비: 이슬이 아군")
	check(not Stage.swap(d) and int(d["ctrl"]) == 1, "로비: 교대 안 된다")
	Stage._enter(d, _room_of("guard_corridor"))
	check(d["hero"] == kim and str(kim.moveset["combo"]) == "k_slash1" and not d["look_of"].has(kim), "대표실 앞: 칼 든 김신(장 표 외형)")
	# 그 방 사람이 쓰러지면 진다(방에 없는 사람이 살아 있어도)
	Stage._enter(d, _room_of("lobby"))
	_past_intro(d)
	jin.hp = 0.0
	jin.set_state("dead")
	for i in 3:
		Stage.step(d, {})
	check(d["world"].over == "lose" and kim.alive(), "로비에서 서진태가 쓰러지면 진다(김신이 살아 있어도) %s" % d["world"].over)


func test_ch11_still_swaps() -> void:
	var d := Stage.make(1, {"chapter": "ch11"})
	check(d["cast"] == [0, 1] and Stage.can_swap(d) and Stage.partner(d) == d["heroes"][1], "11장: 둘이 판에 · 교대 · 짝")
	check(Stage.swap(d) and d["hero"] == d["heroes"][1] and Stage.partner(d) == d["heroes"][0], "11장: 교대하면 짝이 바뀐다")


func test_escape_room_timeout_loses() -> void:
	# rc.2 폰(2026-11-07 사용자): 버티기로 넘으면 안 된다 — 정해진 초 안에 오른쪽 끝 문에 못 닿으면 그 방은 못 깬다(진다)
	var i := _room_of("upper_corridor")
	var d := Stage.make(3, {"chapter": "ch2", "room": i})
	var kim = d["heroes"][0]
	var boss = d["boss"]
	check(boss != null and boss.char_id == "namgunghyuk" and boss.hp_floor > 0.0, "위층 복도: 남궁혁 — 쓰러뜨릴 수 없다(hp_floor)")
	check(Stage.escape_left(d) < 0.0, "들어서는 동안은 남은 초가 없다")
	var guide := false
	for n in 200:
		Stage.step(d, {})
		if d["world"].events.any(func(e): return e[0] == "line" and str(e[1]).contains("문")):
			guide = true
		d["world"].events.clear()
		if d["stage"] == "fight":
			break
	check(guide, "싸움이 시작되면 안내 글(문으로 빠져나가라)이 뜬다")
	var secs: float = Haseong.ROOMS[i]["escape"]["secs"]
	check(secs <= 10.0 and absf(Stage.escape_left(d) - secs) < 0.1, "남은 초 = %.0f — 10초 안 (%.2f)" % [secs, Stage.escape_left(d)])
	for n in int(secs * 60.0) + 5:
		kim.hp = kim.hp_max                                # 버티기만(맞아도 안 쓰러지게)
		Stage.step(d, {})
		d["world"].events.clear()
		if d["world"].over != "":
			break
	check(d["world"].over == "lose" and d["stage"] != "clear", "%.0f초 안에 문에 못 닿으면 진다 — over=%s stage=%s" % [secs, d["world"].over, d["stage"]])
	check(d.get("lose_line", []).size() >= 2, "시간 초과 패배 글이 따로 있다")
	check(boss.hp >= boss.hp_max * boss.hp_floor - 0.01, "남궁혁 체력은 바닥 밑으로 안 내려간다")


func test_escape_room_bot_runs_to_exit() -> void:
	# 봇(자동 플레이)도 버티지 않고 문으로 달린다
	var i := _room_of("upper_corridor")
	var d := Stage.make(5, {"chapter": "ch2", "room": i})
	var secs: float = Haseong.ROOMS[i]["escape"]["secs"]
	for n in 75 + int(secs * 60.0) + 200:
		Stage.step(d)
		d["world"].events.clear()
		if d["stage"] == "clear" or d["world"].over != "":
			break
	check(d["stage"] == "clear" and d["world"].over == "", "봇이 %.0f초 안에 문에 닿는다 — stage=%s over=%s" % [secs, d["stage"], d["world"].over])


func test_escape_room_by_exit() -> void:
	var i := _room_of("upper_corridor")
	var d := Stage.make(3, {"chapter": "ch2", "room": i})
	var kim = d["heroes"][0]
	_past_intro(d)
	for n in 30:
		Stage.step(d, {})
		d["world"].events.clear()
	check(d["stage"] == "fight", "출구 밖에서는 싸움이 이어진다")
	var ex: Rect2 = Haseong.ROOMS[i]["escape"]["exit"]
	kim.pos = ex.get_center()
	Stage.step(d, {})
	check(d["stage"] == "clear" and float(d["times"]["upper_corridor"]) < float(Haseong.ROOMS[i]["escape"]["secs"]) * 60.0,
		"출구에 닿으면 바로 넘는다 %s" % d["stage"])


## ---- 2장 전투 내용(S5 묶음 4) — 적 프로필 · 동작(src/combat/enemy_ai.gd · src/data/moves.gd) · 3층 수치(haseong.gd)

## 서진태(로비 · 중앙계단 조작 인물)는 칼 · 이슬은 공사장에선 적(한 합 — 체력 반), 로비에선 아군(동작 · 1층 기술)
func test_ch2_jintae_blade_and_iseul_both_sides() -> void:
	var d := Stage.make(2, {"chapter": "ch2"})
	var ise = d["enemies"][0]
	check(ise.char_id == "iseul" and d["ais"].has(ise) and d["ais"][ise].prof == EnemyAI.PROFILES["iseul"], "공사장: 이슬은 적(프로필 iseul)")
	var full: float = float(Haseong.ROLES["iseul"]["hp"]) * float(Addendum.derive(Addendum.stats_at("iseul", Haseong.PERIOD))["hp"])
	check(absf(ise.hp_max - full * 0.5) < 0.5, "공사장은 한 합 — 체력 반 (%.0f / %.0f)" % [ise.hp_max, full])
	Stage._enter(d, _room_of("lobby"))
	var jin = d["hero"]
	check(str(jin.moveset["combo"]) == "jk_slash1" and str(Moves.get_move("jk_slash1")["sfx"]) == "knife", "로비: 서진태는 칼 %s" % [jin.moveset])
	check(not jin.can_parry and not jin.moveset.has("counter"), "서진태는 막기만(쳐내기 없음) — 반격 동작이 없다")
	var ally = null
	for a in d["allies"]:
		if a.char_id == "iseul":
			ally = a
	check(ally != null and not d["ais"].has(ally) and str(ally.moveset["combo"]) == "ia_hook", "로비: 이슬은 아군 봇(ia_ 동작)")
	check(ally != null and ally.skill_index("iseul_throw") >= 0 and ally.skill_index("iseul_double_slam") >= 0,
		"아군 이슬은 1층 기술(붙잡아 후려 날리기 · 메다꽂기)")
	var youth: Array = d["allies"].filter(func(a): return a.char_id == "namgu_youth")
	check(not youth.is_empty() and youth.all(func(a): return str(a.moveset["combo"]) == "ny_jab"), "남구청년회 아군 동작 ny_")


## 2장 인물 1층 기술(3D 덧붙임 후보)은 다 동작이 있다
func test_ch2_addendum_skills() -> void:
	for id in ["sintaejin", "hwangbomincheol", "iseul", "ojiin", "namgunghyuk"]:
		var sk: Array = Addendum.character(id)["skills"]
		check(not sk.is_empty(), "%s 1층 기술 후보" % id)
		for sid in sk:
			check(not Addendum.skill(sid).is_empty() and Moves.M.has(Addendum.skill(sid)["move"]), "%s 기술 %s 에 동작" % [id, sid])
	check(str(Addendum.skill("namgung_knuckle_counter")["name"]) == "너클 낀 주먹 카운터", "남궁혁 기술 책 이름 그대로(castle_common book)")


## 남궁혁 '너클 낀 주먹 카운터' — 김신이 치기 시작할 때 막지 않으면 맞받아 친다(1장 김대건 counter 와 같은 칸)
func test_ch2_namgung_counter() -> void:
	var d := Stage.make(3, {"chapter": "ch2", "room": _room_of("upper_corridor")})
	var ng = d["enemies"][0]
	var ai = d["ais"][ng]
	var kim = d["heroes"][0]
	check(ai.counter_rate >= 0.3 and str(EnemyAI.PROFILES["namgung"]["counter"][0]) == "ng_counter", "남궁혁은 자주 맞받는다 (%.2f)" % ai.counter_rate)
	check(int(Moves.get_move("ng_counter")["startup"]) <= 8, "너클 카운터는 빠르다")
	_past_intro(d)
	ai.guard_rate = 0.0
	ai.counter_rate = 1.0
	ai.cooldown = 9999
	kim.pos = ng.pos + Vector2(-1.0, 0.0)
	kim.facing = Vector2(1, 0)
	ng.set_state("idle")
	Stage.step(d, {"attack": true, "face": Vector2(1, 0)})
	var used := false
	for i in 12:
		Stage.step(d, {})
		used = used or (ng.state == "attack" and str(ng.move["name"]) == "ng_counter")
		d["world"].events.clear()
	check(used, "김신이 치면 남궁혁이 너클로 맞받는다")


## 신태진 2차(복면을 벗음 032/020-031): 체력 절반에서 — 배율이 늘고 2차 표에서 숨긴 두 번째 칼을 꺼낸다
func test_ch2_sintaejin_phase2() -> void:
	var d := Stage.make(1, {"chapter": "ch2", "room": _room_of("junkyard_night")})
	var st = d["enemies"][0]
	var ai = d["ais"][st]
	check(st.char_id == "sintaejin" and st.rank == "준10강", "부진폐차장: 신태진(준10강)")
	_past_intro(d)
	var dmg0: float = st.dmg_k
	st.hp = st.hp_max * 0.49
	d["world"]._check_hp(st)
	check(st.phase == 2, "체력 절반에서 2차")
	for i in World.PHASE2_FREEZE + 2:
		Stage.step(d, {})
		d["world"].events.clear()
	check(ai.phase == 2 and st.dmg_k > dmg0, "2차 배율 (dmg_k %.2f → %.2f)" % [dmg0, st.dmg_k])
	var prof: Dictionary = EnemyAI.PROFILES["sintaejin"]
	var p1 := {}
	for row in prof["weights"][0]:
		for step in prof["patterns"][row[0]]:
			p1[str(step[0])] = true
	var p2 := {}
	for i in 40:
		ai._pick()
		for step in ai.queue:
			p2[str(step[0])] = true
	check(not p1.has("st_second") and p2.has("st_second"), "숨긴 두 번째 칼은 2차부터 %s" % [p2.keys()])
	var mv := Moves.get_move("st_second")
	check(not mv["parryable"] and str(mv["telegraph"]) == "unblock", "두 번째 칼은 못 막는다(빨간 !)")


## 오지인은 '열에 아홉은 진다'며 칼을 내려놓는다(026/049-052) — yield_at 에서 길을 내주고, 경호팀 10명(5 + 5)이 다 쓰러졌으면 방을 넘는다
func test_ch2_ojiin_yields() -> void:
	var d := Stage.make(1, {"chapter": "ch2", "room": _room_of("guard_corridor")})
	_past_intro(d)
	var oj = null
	for e in d["enemies"]:
		if e.char_id == "ojiin":
			oj = e
		else:
			e.hp = 0.0
			e.die()
	check(oj != null and d["yield"].has(oj), "오지인은 길을 내주는 체력이 있다")
	Stage.step(d, {})
	d["world"].events.clear()
	var guards: Array = d["enemies"].filter(func(e): return e.char_id == "haseong_guard")
	check(guards.size() == 10 and guards.filter(func(e): return e.alive()).size() == 5, "첫 다섯이 쓰러지면 다섯이 더 — 경호팀 10인 (%d)" % guards.size())
	for e in guards:
		if e.alive():
			e.hp = 0.0
			e.die()
	oj.hp = oj.hp_max * 0.3
	d["world"]._check_hp(oj)
	var yielded := false
	for i in 60 * 5:                                          # 둘째 무리 대사(wave2)가 지나가면 넘는다
		Stage.step(d, {})
		yielded = yielded or d["world"].events.any(func(e): return e[0] == "yield")
		d["world"].events.clear()
		if d["stage"] != "fight":
			break
	check(yielded and oj.alive() and oj.inert and d["stage"] == "clear", "오지인이 비켜서고 방을 넘는다 %s" % d["stage"])


## 1층: 하성 인력 15명이 세 무리(6 · 5 · 4)로 — 셋째 무리와 함께 황보민철. 서진태 쪽 아군은 이슬 · 청년회 3명 · 부진파 2명
func test_ch2_lobby_waves() -> void:
	var d := Stage.make(1, {"chapter": "ch2", "room": _room_of("lobby")})
	_past_intro(d)
	check(d["allies"].size() == 6 and d["allies"].filter(func(a): return a.name == "부진파").size() == 2, "아군 이슬 · 청년회 3 · 부진파 2")
	var seen := {}
	for wave in 3:
		for e in d["enemies"]:
			seen[e] = true
			if e.char_id == "haseong_suit" and e.alive():
				e.hp = 0.0
				e.die()
		Stage.step(d, {})
		d["world"].events.clear()
	for e in d["enemies"]:
		seen[e] = true
	var suits: int = seen.keys().filter(func(e): return e.char_id == "haseong_suit").size()
	check(suits == 15 and d["enemies"].any(func(e): return e.char_id == "hwangbomincheol" and e.alive()), "하성 인력 15명 + 황보민철 (%d)" % suits)


## 위층 복도(남궁혁 + 경호대 · 피우진 · 김대건 아군): 둘 중 하나가 쓰러지면 진다 · 김신이 오른쪽 끝에 닿으면 넘는다
func test_ch2_upper_hall_protect() -> void:
	var i := _room_of("upper_hall")
	var d := Stage.make(1, {"chapter": "ch2", "room": i})
	_past_intro(d)
	var wj = null
	for a in d["allies"]:
		if a.char_id == "woojin":
			wj = a
	check(wj != null and d["allies"].any(func(a): return a.char_id == "kimdaegeon"), "피우진 · 김대건이 아군")
	check(float(Haseong.ROOMS[i]["bounds"].size.x) >= 20.0, "긴 복도")
	wj.hp = 0.0
	wj.die()
	Stage.step(d, {})
	check(d["world"].over == "lose" and d.get("lose_line", []).size() >= 2, "피우진이 쓰러지면 진다")
	var d2 := Stage.make(1, {"chapter": "ch2", "room": i})
	_past_intro(d2)
	d2["heroes"][0].pos = (Haseong.ROOMS[i]["escape"]["exit"] as Rect2).get_center()
	Stage.step(d2, {})
	check(d2["stage"] == "clear", "끝 계단에 닿으면 넘는다 %s" % d2["stage"])


## 대표실: 강창석 · 김재훈 모두 김신의 한 방 — 둘 다 쓰러지면 김신의 멘트(원작 029/090 · 093-096) 뒤에 넘는다
func test_ch2_ceo_one_hit() -> void:
	var d := Stage.make(1, {"chapter": "ch2", "room": _room_of("ceo_office")})
	for e in d["enemies"]:
		check(not e.oneshot_immune, "%s 는 한 방을 받는다(방 보스 없음)" % e.name)
	var r := Stage.simulate(1, 60 * 60, {"chapter": "ch2", "room": _room_of("ceo_office")})
	var t := float(r["times"].get("ceo_office", -1)) / 60.0
	check(t > 0.0 and t < 25.0, "봇이 짧게 넘는다 (%.1f초)" % t)


## 봇이 2장 보스 방을 넘는다 — 몇 초 만에 녹지 않지만 1분 안(2장 보스는 모두 조작 인물보다 아랫급 — 사용자 2026-11-10). 수치 조정 회귀 막기
func test_ch2_bot_beats_bosses() -> void:
	for c in [["lobby", 2], ["junkyard_night", 2]]:
		var r := Stage.simulate(int(c[1]), 60 * 90 + Haseong.INTRO_T, {"chapter": "ch2", "room": _room_of(c[0])})
		var t := float(r["times"].get(c[0], -1)) / 60.0
		check(t > 8.0 and t < 60.0, "%s 봇이 넘는다 · 8 ~ 60초 (%.0f초) %s" % [c[0], t, r])
