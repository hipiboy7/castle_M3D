extends "res://tests/helpers.gd"
## 통합 시험(B 등급) — 11장 호텔 캐슬 판(src/combat/stage.gd): 같은 시드 같은 결과 · 방을 넘어간다 · 교대 · 협공 상한 ·
## 신겐이 길을 내준다 · 둘 다 쓰러지면 패배 · 11장 시점 등급.

const Stage = preload("res://src/combat/stage.gd")
const Hotel = preload("res://src/data/hotel.gd")


func test_stage_deterministic() -> void:
	var a := Stage.simulate(3, 5000)
	var b := Stage.simulate(3, 5000)
	check(a == b, "같은 시드면 같은 판\n%s\n%s" % [a, b])
	var c := Stage.simulate(3, 5000, {"chapter": "ch11"})
	check(a == c, "장 id 를 주어도 같은 판(기본 ch11 — 장 표 hotel.gd)")
	check(Stage.make(1)["tbl"] == Hotel and Stage.make(1)["chapter"] == "ch11", "판이 장 표를 들고 있다")


func test_ranks_and_parry_at_ch11() -> void:
	var d := Stage.make(1)
	var kim = d["heroes"][0]
	var woo = d["heroes"][1]
	check(kim.rank == "재앙" and woo.rank == "외성 하위", "11장 앞 진행 — 김신 재앙(리천 이김) · 피우진 외성 하위(도우첸 이김) %s %s" % [kim.rank, woo.rank])
	check(kim.can_parry and not woo.can_parry, "칼날 쳐내기는 김신만(이 판의 사람 중)")
	check(kim.skill_index("offbeat") >= 0 and woo.skills.size() == 1 and woo.skill_index("woojin_core_counter") == 0,
		"김신은 엇박 계열을 안다 · 피우진은 3D 덧붙임 미친 코어 카운터만(1층 skills [] — 묶음 B)")
	check(d["allies"].size() == 1 and d["allies"][0].char_id == "guilhwa" and d["allies"][0].rank == "전국구", "35층 홀 아군 구일화(화진 전 전국구)")
	check(d["enemies"].size() == 5, "35층 홀 경호원 다섯")


func test_swap_and_auto_swap_on_down() -> void:
	var d := Stage.make(1)
	Stage.step(d, {"swap": true})
	check(d["ctrl"] == 1 and d["hero"] == d["heroes"][1], "교대 — 피우진")
	var seen := false
	for e in d["world"].events:
		seen = seen or e[0] == "swap"
	check(seen, "swap 신호")
	d["world"].events.clear()
	d["heroes"][1].die()
	Stage.step(d, {})
	check(d["ctrl"] == 0, "조작하던 사람이 쓰러지면 남은 사람으로")
	d["heroes"][0].die()
	Stage.step(d, {})
	check(d["world"].over == "lose", "둘 다 쓰러지면 패배")
	check(not Stage.swap(d), "남은 사람이 없으면 교대 안 됨")


func test_attackers_capped() -> void:
	var d := Stage.make(2, {"room": 2})                   # 71층 회장실 앞 홀 — 최후의 4인
	var worst := 0
	for i in 1500:
		Stage.step(d)
		d["world"].events.clear()
		var busy := 0
		for e in d["enemies"]:
			if d["ais"][e].busy():
				busy += 1
		worst = maxi(worst, busy)
		if d["stage"] != "fight" and i > Hotel.INTRO_T + 5:
			break
	check(worst <= Hotel.MAX_ATTACKERS, "동시에 몰아치는 적은 %d 이하 (%d)" % [Hotel.MAX_ATTACKERS, worst])


func test_shingen_yields_then_room_clears() -> void:
	var d := Stage.make(1, {"room": 3})
	var sg = d["enemies"][0]
	check(sg.char_id == "shingen" and sg.rank == "내성 상위", "회장실 앞 신겐")
	sg.hp = sg.hp_max * 0.3
	var yielded := false
	for i in Hotel.INTRO_T + 4:
		Stage.step(d)
		for e in d["world"].events:
			yielded = yielded or e[0] == "yield"
		d["world"].events.clear()
	check(yielded and sg.inert and sg.alive(), "체력 30%% 에서 길을 내준다 (inert %s)" % sg.inert)
	check(d["stage"] == "clear", "신겐이 비키면 방을 넘는다 (%s)" % d["stage"])
	for i in Hotel.CLEAR_T + 2:
		Stage.step(d)
		d["world"].events.clear()
	check(str(d["room"]["id"]) == "office", "빈 회장실로")
	for i in Hotel.INTRO_T + Hotel.END_T + 4:
		Stage.step(d)
		d["world"].events.clear()
	check(d["world"].over == "win", "빈 회장실 — 끝 (%s)" % d["world"].over)


func test_bots_clear_first_rooms() -> void:
	var r := Stage.simulate(1, 60 * 240)
	check(int(r["cleared"]) >= 2, "봇이 35층 홀 · 비상구 계단을 넘는다 %s" % r)
	check(r["times"].has("hall35") and int(r["times"]["hall35"]) < 60 * 60, "35층 홀은 1분 안 %s" % r["times"])
