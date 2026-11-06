extends "res://tests/helpers.gd"
## 통합 시험(B 등급) — 2장 하성 본사 판(src/combat/stage.gd + 장 표 haseong.gd): 같은 시드 같은 결과 · 방마다 조작 인물(cast —
## 방에 없는 사람은 판에 없다 · 교대 없음 · 그 방 사람이 쓰러지면 진다) · 방 표 kit(공사장 맨손 김신) · 따돌리기 방(남궁혁 —
## 버티거나 출구에 닿으면 넘는다 · 쓰러뜨릴 수 없다) · 11장은 그대로 둘이 교대.

const Stage = preload("res://src/combat/stage.gd")
const Haseong = preload("res://src/data/haseong.gd")


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


func test_escape_room_by_time() -> void:
	var i := _room_of("upper_corridor")
	var d := Stage.make(3, {"chapter": "ch2", "room": i})
	var kim = d["heroes"][0]
	var boss = d["boss"]
	check(boss != null and boss.char_id == "namgunghyuk" and boss.hp_floor > 0.0, "위층 복도: 남궁혁 — 쓰러뜨릴 수 없다(hp_floor)")
	check(Stage.escape_left(d) < 0.0, "들어서는 동안은 남은 초가 없다")
	_past_intro(d)
	var secs: float = Haseong.ROOMS[i]["escape"]["secs"]
	check(absf(Stage.escape_left(d) - secs) < 0.1, "싸움이 시작되면 남은 초 = %.0f (%.2f)" % [secs, Stage.escape_left(d)])
	var escaped := false
	for n in int(secs * 60.0) + 5:
		kim.hp = kim.hp_max                                # 버티기만(맞아도 안 쓰러지게)
		Stage.step(d, {})
		if d["world"].events.any(func(e): return e[0] == "escape"):
			escaped = true
		d["world"].events.clear()
		if d["stage"] == "clear":
			break
	check(escaped and d["stage"] == "clear" and boss.alive() and boss.inert, "%.0f초 버티면 남궁혁을 두고 방을 넘는다 %s" % [secs, d["stage"]])
	check(boss.hp >= boss.hp_max * boss.hp_floor - 0.01, "남궁혁 체력은 바닥 밑으로 안 내려간다")


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
