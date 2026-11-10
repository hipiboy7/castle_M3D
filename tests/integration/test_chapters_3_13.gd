extends "res://tests/helpers.gd"
## 통합 시험(B 등급) — 3 ~ 13장(2026-11-08): 모든 방이 서고(인물 · 역할 · AI · 외형) 2초 동안 돌아간다 · 장 표 NPCS 가 등급을 덮는다 ·
## 대화 방(talk — 5 · 7장 · 13장 맺음)은 say 줄을 차례로 보이고 저절로 넘어간다 · 따돌리기 방(3장 오도화 · 9장 리천) · 같은 시드 같은 결과.

const Stage = preload("res://src/combat/stage.gd")
const Campaign = preload("res://src/data/campaign.gd")
const NEW := ["ch3", "ch4", "ch5", "ch6a", "ch7", "ch8", "ch9", "ch10", "ch12", "ch13"]


func test_every_room_builds_and_runs() -> void:
	for ch in NEW:
		var T = Campaign.table(ch)
		for r in T.ROOMS.size():
			var d := Stage.make(5, {"chapter": ch, "room": r})
			check(d["room"]["id"] == T.ROOMS[r]["id"] and d["hero"] != null, "%s 방 %s 이 선다" % [ch, T.ROOMS[r]["id"]])
			for e in d["enemies"]:
				check(e.rank != "" and e.hp_max > 0.0 and d["ais"].has(e), "%s %s 적 %s 등급 · 체력 · AI" % [ch, T.ROOMS[r]["id"], e.char_id])
			for i in 120:
				Stage.step(d)
				d["world"].events.clear()
			check(d["world"].over != "lose", "%s 방 %s 2초 안에 지지 않는다" % [ch, T.ROOMS[r]["id"]])


func test_npcs_override_rank() -> void:
	var d := Stage.make(1, {"chapter": "ch3", "room": 7})
	var od = d["enemies"].filter(func(e): return e.char_id == "odohwa")[0]
	check(od.rank == "내성 하위", "3장 오도화 = (현 시점) 내성 하위 — 장 표 NPCS (%s)" % od.rank)
	# 13장 공터(2026-11-10 사용자): 경호대 50인(다섯 무리)을 다 쓰러뜨리면 피우진이 캐슬홀딩스 쪽에서 나와 김신과 1:1 — 백의는 물러선다
	var d2 := Stage.make(1, {"chapter": "ch13", "room": 0})
	var guards := 0
	for i in 60 * 20:
		Stage.step(d2)
		d2["world"].events.clear()
		for e in d2["enemies"]:
			if e.char_id == "elite_guard" and e.alive():
				e.die()
				guards += 1
		if d2["enemies"].any(func(e): return e.char_id == "woojin"):
			break
	var wj = d2["enemies"].filter(func(e): return e.char_id == "woojin")
	check(guards == 50 and wj.size() == 1, "13장 공터: 경호대 50인 → 피우진 (%d명)" % guards)
	if wj.size() == 1:
		check(wj[0].team == 1 and wj[0].rank == "외성 상위" and wj[0].oneshot_immune, "13장 주먹 승부의 피우진은 적 · 외성 상위 · 보스")
		check(wj[0].hp_max >= 700.0, "13장 주먹 승부의 피우진(적)은 보스 체력 (%.0f)" % wj[0].hp_max)
		check(d2["allies"].all(func(a): return a.inert), "피우진이 나오면 백의는 물러선다(1:1)")
	# 13장 대결 구도(canon fight:misulgwan_seupgyeok — 2026-11-10 사용자): 도학수 · 어광득은 김신(백의) 편, 피우진은 최민욱 쪽 — 조작 인물이 아니다
	var d0 := Stage.make(1, {"chapter": "ch13", "room": 0})
	var allies: Array = d0["allies"].map(func(a): return a.char_id)
	check(allies.has("dohaksu") and allies.has("eogwangdeuk") and d0["allies"].all(func(a): return a.team == 0), "13장 정문: 도학수 · 어광득은 아군 %s" % [allies])
	check(not d0["enemies"].any(func(e): return ["dohaksu", "eogwangdeuk", "woojin"].has(e.char_id)), "13장 정문: 백의 사람 · 피우진은 적 칸에 없다")
	check(not Campaign.table("ch13").HEROES.has("woojin"), "13장 피우진은 조작 인물이 아니다(최민욱 쪽)")


func test_talk_room_says_lines_then_moves_on() -> void:
	var d := Stage.make(1, {"chapter": "ch5"})
	var lines := 0
	var n := 0
	while d["room_i"] == 0 and n < 60 * 30:
		Stage.step(d)
		for e in d["world"].events:
			if e[0] == "line" and e.size() > 4 and float(e[4]) > 0.0:
				lines += 1
		d["world"].events.clear()
		n += 1
	var say = Stage.Lines.at("ch5.rooms.funeral_hall.say")
	check(d["room_i"] == 1, "대화 방은 저절로 다음 방으로 (%d 프레임)" % n)
	check(lines >= say.size() - 1, "say 줄을 차례로(늦춤) 보인다 — %d줄" % lines)
	check(n >= int(Stage.SAY_SECS * say.size() * 60.0), "줄 수 × SAY_SECS 동안 머문다 (%d)" % n)
	var r := Stage.simulate(1, 60 * 120, {"chapter": "ch7"})
	check(r["over"] == "win", "7장(대화만)은 끝까지 간다 %s" % r["over"])


func test_escape_rooms_and_determinism() -> void:
	for ch in ["ch3", "ch9"]:
		var rooms: Array = Campaign.table(ch).ROOMS
		var ri := -1
		for i in rooms.size():
			if rooms[i].has("escape"):
				ri = i
		check(ri >= 0, "%s 에 따돌리기 방이 있다" % ch)
		var d := Stage.make(2, {"chapter": ch, "room": maxi(ri, 0)})
		check(d["room"].has("escape") and d["boss"].hp_floor > 0.0, "%s 따돌리기 방 — 보스는 쓰러뜨릴 수 없다" % ch)
	var a := Stage.simulate(3, 60 * 40, {"chapter": "ch8"})
	var b := Stage.simulate(3, 60 * 40, {"chapter": "ch8"})
	check(a == b, "같은 시드 같은 결과(8장 40초)")


## 12 · 13장 사람 수(사용자 2026-11-10 숫자 그대로 — 무리로 나눠 들어온다): 방 enemies + triggers spawn 의 경호대
func test_crowd_counts_12_13() -> void:
	var want := {"ch12": {"church_steps": 100, "vision_front": 10, "lobby_hold": 50, "parking": 10}, "ch13": {"museum_front": 50}}
	for ch in want:
		for room in Campaign.table(ch).ROOMS:
			if not want[ch].has(room["id"]):
				continue
			var n: int = room["enemies"].filter(func(e): return e[0] == "elite_guard").size()
			var most: int = n
			for t in room.get("triggers", []):
				var k: int = t.get("spawn", []).filter(func(e): return e[0] == "elite_guard").size()
				n += k
				most = maxi(most, k)
			check(n == int(want[ch][room["id"]]), "%s %s 경호대 %d명 (%d)" % [ch, room["id"], want[ch][room["id"]], n])
			check(most <= 11, "%s %s 한 무리는 11명 이하 (%d)" % [ch, room["id"], most])


## 맨손 방에서는 무기 기술을 안 쓴다(13장 주먹 승부 — 칼 기술이 주먹 승부에 섞이지 않게), 칼 든 방에서는 쓴다
func test_bare_room_drops_weapon_skills() -> void:
	var Tech = preload("res://src/data/tech_moves.gd")
	var rooms: Array = Campaign.table("ch13").ROOMS
	var ri := -1
	for i in rooms.size():
		if rooms[i].get("kit", {}).get("kimshin", "") == "kimshin_bare":   # 공터 — 경호대를 넘으면 피우진과 주먹 승부
			ri = i
	var d := Stage.make(1, {"chapter": "ch13", "room": ri})
	var kim = d["heroes"][0]
	check(not kim.skills.is_empty(), "맨손 김신도 기술이 있다 %d" % kim.skills.size())
	for e in kim.skills:
		check(not Tech.WEAPON.has(str(e["move"])), "주먹 승부에 무기 기술 없음 %s" % e["name"])
	var d2 := Stage.make(1, {"chapter": "ch12", "room": 0})
	check(d2["heroes"][0].skills.any(func(e): return Tech.WEAPON.has(str(e["move"]))), "칼 든 12장 김신은 칼 기술을 쓴다")
