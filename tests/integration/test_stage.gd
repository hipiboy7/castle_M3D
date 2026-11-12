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
	var d := Stage.make(1, {"room": 1})                   # 28층 중앙홀 — 김신 · 피우진(첫 방 지하주차장은 류지학)
	var kim = d["heroes"][0]
	var woo = d["heroes"][1]
	check(kim.rank == "재앙" and woo.rank == "외성 하위", "11장 앞 진행 — 김신 재앙(리천 이김) · 피우진 외성 하위(도우첸 이김) %s %s" % [kim.rank, woo.rank])
	check(kim.can_parry and not woo.can_parry, "칼날 쳐내기는 김신만(이 판의 사람 중)")
	check(kim.skill_index("offbeat") >= 0 and woo.skills.size() == 4 and woo.skill_index("woojin_core_counter") == 0,
		"김신은 엇박 계열을 안다 · 피우진(외성 하위)은 기술 4개 — 미친 코어 카운터가 먼저(skill_kit 2026-11-10) %d" % woo.skills.size())
	check(kim.skills.size() > 7, "김신(재앙)은 모든 기술 %d" % kim.skills.size())
	var named := 0
	for e in d["enemies"]:
		if not d["ais"][e].skills.is_empty():
			named += 1
	check(named == 0, "28층 중앙홀 경호원(엑스트라)은 기술 묶음이 없다")
	var ally_ids: Array = d["allies"].map(func(a): return a.char_id)
	check(ally_ids == ["guilhwa", "hantaecheol", "eogwangdeuk", "dohaksu", "choehyeokjin"] and d["allies"][0].rank == "전국구",
		"28층 아군 구일화(화진 전 전국구) · 한태철 · 어광득 · 도학수 · 최혁진 %s" % [ally_ids])
	check(d["enemies"].size() == 8, "28층 경호대 첫 무리 여덟(20명을 세 무리로)")
	var p := Stage.make(1)
	check(p["room"]["id"] == "parking" and p["hero"].char_id == "ryujihak" and p["hero"].rank == "내성 중위" and not Stage.can_swap(p),
		"첫 방 지하주차장: 류지학 혼자 조작(내성 중위 — 방 표 ranks)")
	check(p["allies"].any(func(a): return a.char_id == "hide") and p["room"]["protect"] == ["ryujihak", "hide"], "지하주차장: 히데 아군 · 둘을 지킨다")


func test_swap_and_auto_swap_on_down() -> void:
	var d := Stage.make(1, {"room": 1})
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
	var d := Stage.make(2, {"room": 3})                   # 71층 — 최후의 4인
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
	var d := Stage.make(1, {"room": 4})
	var sg = d["enemies"][0]
	check(sg.char_id == "shingen" and sg.rank == "내성 상위", "회장실 앞 신겐")
	sg.hp = sg.hp_max * 0.6
	var yielded := false
	for i in Hotel.INTRO_T + 4:
		Stage.step(d)
		for e in d["world"].events:
			yielded = yielded or e[0] == "yield"
		d["world"].events.clear()
	check(yielded and sg.inert and sg.alive(), "체력 2/3 밑에서 길을 내준다 (inert %s)" % sg.inert)
	check(d["stage"] == "clear", "신겐이 비키면 방을 넘는다 (%s)" % d["stage"])
	for i in Hotel.CLEAR_T + 2:
		Stage.step(d)
		d["world"].events.clear()
	check(str(d["room"]["id"]) == "office", "회장실로 — 천일도")
	var cd = d["enemies"][0]
	check(cd.char_id == "cheonildo" and d["passive"].has(cd), "천일도는 맞기만 한다(passive)")
	for i in Hotel.INTRO_T + 2:
		Stage.step(d)
		d["world"].events.clear()
	cd.die()
	var faded := false
	for i in Hotel.CLEAR_T + Hotel.INTRO_T + Hotel.END_T + 8:
		Stage.step(d)
		faded = faded or d["world"].events.any(func(e): return e[0] == "fade")
		d["world"].events.clear()
	check(faded and d["world"].over == "win", "천일도 뒤 끝 방 — 만인지상(fade) · 끝 (%s)" % d["world"].over)


func test_bots_clear_first_rooms() -> void:
	var r := Stage.simulate(1, 60 * 240, {"room": 1})
	check(int(r["cleared"]) >= 2, "봇이 28층 중앙홀 · 69층 계단을 넘는다 %s" % r)
	check(r["times"].has("hall28") and int(r["times"]["hall28"]) < 60 * 60, "28층 중앙홀은 1분 안 %s" % r["times"])


## 원작 대사 고르기(2026-11-13 rc.16 폰 리뷰 '방에 맞지 않는 멘트'): 말하는 사람이 반 넘게 방에 없으면 남은 줄은 대답 없는 토막이라
## 그 대목(open · close)을 통째로 안 튼다. 다 있는 짧은 대목 · 내레이션(@) · 이름 모를 사람(?)은 남긴다
func test_canon_keep_drops_broken_talk() -> void:
	var here := func(id: String) -> bool: return id in ["kimshin", "boss"]
	var full := [["kimshin", "a"], ["boss", "b"]]
	check(Stage.canon_keep(full, here).size() == 2, "다 있는 두 줄은 그대로")
	var half := [["kimshin", "a"], ["other", "b"], ["boss", "c"], ["@", "d"]]
	check(Stage.canon_keep(half, here).size() == 3, "없는 사람 한 줄만 빼고(@ 는 남김)")
	var broken := [["other", "a"], ["other", "b"], ["kimshin", "c"], ["other", "d"], ["boss", "e"]]
	check(Stage.canon_keep(broken, here).is_empty(), "반 넘게 없으면 대목째 뺀다")
	var thin := [["other", "a"], ["kimshin", "b"]]
	check(Stage.canon_keep(thin, here).is_empty(), "짧은 대목에서 빠진 줄이 있으면 남는 한 줄도 뺀다")
	var d := Stage.make(1, {"chapter": "ch11", "room": 2})
	check(Stage.canon_steps(d, "open").is_empty(), "11장 69층(말하는 이희성이 방에 없다) — 원작 대사 안 튼다")
