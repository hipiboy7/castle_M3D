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
	var d2 := Stage.make(1, {"chapter": "ch13", "room": 2})
	check(d2["boss"].char_id == "woojin" and d2["boss"].team == 1 and d2["boss"].rank == "외성 상위", "13장 주먹 승부의 피우진은 적 · 외성 상위")
	# 같은 인물이 한 장에서 아군(조작)도 되고 적도 될 때: 적 칸은 방 표 덧붙임 role 로 다른 역할(체력 · AI)을 쓴다
	var d0 := Stage.make(1, {"chapter": "ch13", "room": 0})
	var wj = d0["heroes"].filter(func(h): return h.char_id == "woojin")[0]
	check(wj.hp_max < 400.0, "13장 습격의 피우진(조작 인물)은 사람 체력 — 적 역할 체력이 아니다 (%.0f)" % wj.hp_max)
	check(d2["boss"].hp_max >= 1000.0, "13장 주먹 승부의 피우진(적)은 보스 체력 (%.0f)" % d2["boss"].hp_max)


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
	for pair in [["ch3", 7], ["ch9", 3]]:
		var d := Stage.make(2, {"chapter": pair[0], "room": pair[1]})
		check(d["room"].has("escape") and d["boss"].hp_floor > 0.0, "%s 따돌리기 방 — 보스는 쓰러뜨릴 수 없다" % pair[0])
	var a := Stage.simulate(3, 60 * 40, {"chapter": "ch8"})
	var b := Stage.simulate(3, 60 * 40, {"chapter": "ch8"})
	check(a == b, "같은 시드 같은 결과(8장 40초)")
