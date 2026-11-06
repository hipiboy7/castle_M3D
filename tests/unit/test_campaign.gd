extends "res://tests/helpers.gd"
## 캠페인 골격(A 등급) — 장 목록(src/data/campaign.gd) · 장 데이터 검사(모든 인물 · 동작 · 외형 · 대사 · 진행 사건이 있다 —
## 기획서 02 3절 '모든 id 는 canon · data 에 있어야 한다') · 세이브(src/data/save.gd — 형식 버전 · 옛 · 깨진 · 새 세이브).

const Campaign = preload("res://src/data/campaign.gd")
const Save = preload("res://src/data/save.gd")
const Addendum = preload("res://src/data/addendum.gd")
const EnemyAI = preload("res://src/combat/enemy_ai.gd")
const Looks = preload("res://src/view/looks.gd")
const Lines = preload("res://src/data/lines.gd")


func _has_event(ev: String) -> bool:
	for e in Common.progression()["events"]:
		if e[0] == ev:
			return true
	return false


func test_chapter_list() -> void:
	var ids := Campaign.ids()
	check(ids.size() >= 4 and ids[0] == "ch0" and ids.has("ch6") and ids.has("ch11"), "장 목록 %s" % [ids])
	var prev := -1
	for id in ids:
		var c := Campaign.chapter(id)
		check(int(c["no"]) > prev, "장 번호가 차례로 %s" % id)
		prev = int(c["no"])
		check(c["kind"] in ["duel", "stage", "soon"], "장 종류 %s %s" % [id, c["kind"]])
		var t = Campaign.title(id)
		check(t is Array and t.size() == 2 and str(t[0]) != "", "장 이름 · 한 줄(lines.json chapters.%s)" % id)
	check(Campaign.playable_ids() == ["ch6", "ch11"], "지금 할 수 있는 장 = 6 · 11장 %s" % [Campaign.playable_ids()])
	check(not Campaign.playable("ch0") and Campaign.playable("ch11") and not Campaign.playable("nope"), "준비 중 · 없는 장은 못 한다")
	check(Campaign.from_mode("duel") == "ch6" and Campaign.from_mode("stage") == "ch11" and Campaign.from_mode("ch11") == "ch11",
		"옛 실행 인자 --mode duel|stage 도 장 id 로")
	check(Campaign.from_mode("ch0") == "" and Campaign.from_mode("x") == "", "못 하는 장 · 없는 이름은 빈칸")
	check(Campaign.table("ch11") != null and Campaign.table("ch6") == null, "여러 사람 판만 장 표가 있다")
	check(Campaign.kind("ch6") == "duel" and Campaign.kind("ch11") == "stage" and Campaign.kind("nope") == "", "장 종류")


## 장 데이터 검사 — 장 표(hotel.gd 등)의 모든 id 가 1층(castle_common · 덧붙임) · 3층 표 · 외형 · 대사 · 진행에 있다
func test_chapter_data_ids_exist() -> void:
	for id in Campaign.playable_ids():
		var c := Campaign.chapter(id)
		check(_has_event(str(c["event"])), "%s 진행 사건 %s 이 progression.json 에" % [id, c["event"]])
		var T = Campaign.table(id)
		if T == null:
			continue
		check(str(T.EVENT) == str(c["event"]), "%s 장 표의 사건이 장 목록과 같다" % id)
		check(Lines.at(T.LINES + ".start") != null, "%s 첫 글 %s.start" % [id, T.LINES])
		for h in T.HEROES:
			check(T.ROLES.has(h) and T.ROLES[h].has("moveset"), "%s 사람 %s 역할 · 동작 묶음" % [id, h])
		var ids: Array = T.HEROES.duplicate()
		ids.append(T.CROWD_ID)
		for room in T.ROOMS:
			check(Lines.at("%s.rooms.%s.enter" % [T.LINES, room["id"]]) != null, "%s 방 %s 들어서는 글" % [id, room["id"]])
			check(room["heroes"].size() >= T.HEROES.size(), "%s 방 %s 사람 자리" % [id, room["id"]])
			for a in room["allies"] + room["enemies"]:
				ids.append(a[0])
			var boss := str(room.get("boss", ""))
			check(boss == "" or room["enemies"].any(func(e): return e[0] == boss), "%s 방 %s 보스 %s 가 그 방 적" % [id, room["id"], boss])
		for cid in ids:
			var ch := Addendum.character(cid)
			check(ch.has("name") and Addendum.rank_at(cid, T.PERIOD) != "", "%s 인물 %s 1층(이름 · 등급)" % [id, cid])
			check(T.ROLES.has(cid), "%s 인물 %s 3층 역할" % [id, cid])
			var role: Dictionary = T.ROLES.get(cid, {})
			check(Looks.LOOKS.has(str(role.get("look", ""))), "%s 인물 %s 외형 %s" % [id, cid, role.get("look")])
			if role.has("moveset"):
				for k in role["moveset"]:
					check(Moves.M.has(role["moveset"][k]), "%s 인물 %s 동작 %s" % [id, cid, role["moveset"][k]])
			elif not T.HEROES.has(cid):
				check(EnemyAI.PROFILES.has(str(role.get("ai", ""))), "%s 적 %s AI 프로필 %s" % [id, cid, role.get("ai")])


func test_save_fresh_and_roundtrip() -> void:
	var p := Save.parse("")
	check(p["state"] == "new" and p["save"] == Save.fresh(), "빈 파일 = 새 세이브")
	var s := Save.fresh()
	check(int(s["v"]) == Save.VERSION and s["art"] == "a", "새 세이브는 형식 %d · 그림 A(#9 결정)" % Save.VERSION)
	Save.record_clear(s, "ch6", 3000)
	Save.record_clear(s, "ch6", 2500)
	Save.record_clear(s, "ch6", 2800)
	check(Save.cleared(s, "ch6") and not Save.cleared(s, "ch11"), "깬 장")
	check(int(s["cleared"]["ch6"]["count"]) == 3 and int(s["cleared"]["ch6"]["best"]) == 2500, "깬 횟수 · 가장 짧은 판 %s" % s)
	var back := Save.parse(Save.dump(s))
	check(back["state"] == "ok" and back["save"] == s, "dump → parse 가 같다 %s" % back)


func test_save_old_broken_newer() -> void:
	var old := Save.parse('{"v": 1, "cleared": {"ch6": {"count": 1, "best": 4000}}}')
	check(old["state"] == "ok" and old["save"]["art"] == "a" and old["save"]["last"] == "", "빠진 칸은 기본값으로 채운다")
	check(Save.cleared(old["save"], "ch6"), "옛 칸은 그대로")
	var bad := Save.parse("{깨진")
	check(bad["state"] == "broken" and bad["save"] == Save.fresh(), "깨진 세이브 = 새로(파일은 main 이 .bak 으로 남긴다)")
	var arr := Save.parse("[1, 2]")
	check(arr["state"] == "broken", "모양이 다른 세이브도 깨진 것으로")
	var newer := Save.parse('{"v": 99, "cleared": {}}')
	check(newer["state"] == "newer", "더 새 형식은 읽기만(덮어쓰지 않는다)")
	var odd := Save.parse('{"v": 1, "cleared": {"ch6": 3, "zz": {"count": 1}}, "art": "q"}')
	check(not Save.cleared(odd["save"], "ch6") and odd["save"]["art"] == "a", "모양이 틀린 칸은 버리고 기본값 %s" % odd["save"])
	check(odd["save"]["cleared"].has("zz"), "모르는 장 id 는 남긴다(다음 판이 만들 장)")


func test_next_chapter_and_unlock() -> void:
	var s := Save.fresh()
	check(Save.next_chapter(s) == "ch6", "처음 이어하기 = 할 수 있는 첫 장(6장)")
	Save.record_clear(s, "ch6", 3000)
	check(Save.next_chapter(s) == "ch11", "6장을 깨면 11장")
	Save.record_clear(s, "ch11", 9000)
	s["last"] = "ch6"
	check(Save.next_chapter(s) == "ch6", "다 깨면 마지막으로 한 장")
	s["last"] = "ch0"
	check(Save.next_chapter(s) == "ch6", "마지막 장이 못 하는 장이면 첫 장")
	var t := Save.fresh()
	check(Save.unlocked(t, "ch6") and not Save.unlocked(t, "ch0"), "첫 장은 열림 · 준비 중은 잠김")
	check(Save.unlocked(t, "ch11") == Campaign.OPEN_ALL, "11장은 시험판(OPEN_ALL)이면 처음부터 열림")
	check(Save.unlocked_by_order(t, "ch11") == false, "차례 규칙만으로는 6장을 깨야 11장")
	Save.record_clear(t, "ch6", 1)
	check(Save.unlocked_by_order(t, "ch11"), "6장을 깨면 11장이 열린다")
