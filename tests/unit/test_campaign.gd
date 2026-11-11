extends "res://tests/helpers.gd"
## 캠페인 골격(A 등급) — 장 목록(src/data/campaign.gd) · 장 데이터 검사(모든 인물 · 동작 · 외형 · 대사 · 진행 사건이 있다 —
## 기획서 02 3절 '모든 id 는 canon · data 에 있어야 한다') · 세이브(src/data/save.gd — 형식 버전 · 옛 · 깨진 · 새 세이브).

const Campaign = preload("res://src/data/campaign.gd")
const Save = preload("res://src/data/save.gd")
const Addendum = preload("res://src/data/addendum.gd")
const EnemyAI = preload("res://src/combat/enemy_ai.gd")
const Looks = preload("res://src/view/looks.gd")
const Lines = preload("res://src/data/lines.gd")
const Hotel = preload("res://src/data/hotel.gd")
const Hoeam = preload("res://src/data/hoeam.gd")
const Hotel3d = preload("res://src/view/hotel3d.gd")
const Town3d = preload("res://src/view/town3d.gd")
const Haseong3d = preload("res://src/view/haseong3d.gd")
const World3d = preload("res://src/view/world3d.gd")
## 지금 할 수 있는 장(장 목록 campaign.gd 와 같아야 한다 — 장을 더하면 여기도)
const PLAYABLE := ["ch0", "ch1", "ch2", "ch3", "ch4", "ch5", "ch6a", "ch6", "ch7", "ch8", "ch9", "ch10", "ch11", "ch12", "ch13"]
const Haseong = preload("res://src/data/haseong.gd")
const Stage = preload("res://src/combat/stage.gd")


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
		check(int(c["no"]) >= prev, "장 번호가 차례로 %s(한 장을 앞 · 뒤로 나눈 판은 같은 번호)" % id)
		prev = int(c["no"])
		check(c["kind"] in ["duel", "stage", "soon"], "장 종류 %s %s" % [id, c["kind"]])
		var t = Campaign.title(id)
		check(t is Array and t.size() == 2 and str(t[0]) != "", "장 이름 · 한 줄(lines.json chapters.%s)" % id)
	check(Campaign.playable_ids() == PLAYABLE, "지금 할 수 있는 장 %s" % [Campaign.playable_ids()])
	check(Campaign.playable("ch0") and Campaign.playable("ch11") and not Campaign.playable("nope"), "만든 장은 할 수 있고 없는 장은 못 한다")
	check(Campaign.view("ch0") == "town" and Campaign.view("ch1") == "town" and Campaign.view("ch2") == "haseong" and Campaign.view("ch11") == "hotel",
		"무대 그림 이름")
	check(Campaign.from_mode("duel") == "ch6" and Campaign.from_mode("stage") == "ch11" and Campaign.from_mode("ch11") == "ch11",
		"옛 실행 인자 --mode duel|stage 도 장 id 로")
	check(Campaign.from_mode("ch1") == "ch1" and Campaign.from_mode("x") == "", "장 id 는 그대로 · 없는 이름은 빈칸")
	check(Campaign.table("ch11") != null and Campaign.table("ch6") == null, "여러 사람 판만 장 표가 있다")
	check(Campaign.kind("ch6") == "duel" and Campaign.kind("ch11") == "stage" and Campaign.kind("nope") == "", "장 종류")
	check(Campaign.short_title("ch3") == "3장" and Campaign.short_title("ch6a") == "6장 앞" and Campaign.short_title("ch0") == "프롤로그"
		and Campaign.short_title("nope") == "", "짧은 이름(싸움 중 메뉴 작은 카드)")


## 장 데이터 검사 — 장 표(hotel.gd 등)의 모든 id 가 1층(castle_common · 덧붙임) · 3층 표 · 외형 · 대사 · 진행에 있다
func test_chapter_data_ids_exist() -> void:
	for id in Campaign.playable_ids():
		var c := Campaign.chapter(id)
		# 장이 끝날 때의 진행 사건(프롤로그처럼 없을 수 있다 — 그때 장 표 시점은 다음 사건 앞)
		check(str(c["event"]) == "" or _has_event(str(c["event"])), "%s 진행 사건 %s 이 progression.json 에" % [id, c["event"]])
		var T = Campaign.table(id)
		if T == null:
			continue
		check(_has_event(str(T.EVENT)), "%s 장 표 시점 사건 %s 이 progression.json 에" % [id, T.EVENT])
		check(str(c["event"]) == "" or str(T.EVENT) == str(c["event"]), "%s 장 표의 사건이 장 목록과 같다" % id)
		var themes: Array = Hotel3d.THEMES          # (삼항식으로 고르면 정적 분석이 첫 쪽 상수를 읽는다 — if 로)
		if Campaign.view(id) == "town":
			themes = Town3d.THEMES
		if Campaign.view(id) == "haseong":
			themes = Haseong3d.themes()
		if Campaign.view(id) == "world":
			themes = World3d.themes()
		var looks: Array = []                       # 방 표 덧붙임의 외형 · AI(엑스트라 한 사람씩 — stage.gd _npc)
		check(Lines.at(T.LINES + ".start") != null, "%s 첫 글 %s.start" % [id, T.LINES])
		for h in T.HEROES:
			check(T.ROLES.has(h) and T.ROLES[h].has("moveset"), "%s 사람 %s 역할 · 동작 묶음" % [id, h])
		var ids: Array = T.HEROES.duplicate()
		ids.append(T.CROWD_ID)
		for room in T.ROOMS:
			check(Lines.at("%s.rooms.%s.enter" % [T.LINES, room["id"]]) != null, "%s 방 %s 들어서는 글" % [id, room["id"]])
			var cast: Array = Stage.cast_of(T, room)
			check(not cast.is_empty() and not cast.has(-1), "%s 방 %s 조작 인물(cast)이 HEROES 에" % [id, room["id"]])
			check(room["heroes"].size() >= cast.size(), "%s 방 %s 사람 자리" % [id, room["id"]])
			var kit: Dictionary = room.get("kit", {})
			for h in kit:
				var kr: Dictionary = T.ROLES.get(str(kit[h]), {})
				check(T.HEROES.has(h) and kr.has("moveset") and Looks.known(str(kr.get("look", ""))), "%s 방 %s kit %s → %s" % [id, room["id"], h, kit[h]])
				for k in kr.get("moveset", {}):
					check(Moves.M.has(kr["moveset"][k]), "%s 방 %s kit 동작 %s" % [id, room["id"], kr["moveset"][k]])
			if room.has("escape"):
				check(float(room["escape"]["secs"]) > 0.0 and room["bounds"].intersects(room["escape"]["exit"]), "%s 방 %s 따돌리기 출구가 걸을 곳 안" % [id, room["id"]])
			check(themes.has(str(room["theme"])), "%s 방 %s 무대 %s 를 그림이 그린다" % [id, room["id"], room["theme"]])
			for a in room["allies"] + room["enemies"]:
				ids.append(a[0])
				if a.size() > 2:
					if a[2].has("look"):
						looks.append(str(a[2]["look"]))
					if a[2].has("ai"):
						check(EnemyAI.PROFILES.has(str(a[2]["ai"])), "%s 방 %s 덧붙임 AI %s" % [id, room["id"], a[2]["ai"]])
			var boss := str(room.get("boss", ""))
			var foes: Array = room["enemies"].duplicate()          # + 싸움 중에 들어오는 적(triggers spawn — 보스가 나중에 들어오는 방)
			for t in room.get("triggers", []):
				foes.append_array(t.get("spawn", []))
			check(boss == "" or foes.any(func(e): return e[0] == boss), "%s 방 %s 보스 %s 가 그 방 적" % [id, room["id"], boss])
		for cid in ids:
			var ch := Addendum.character(cid)
			check(ch.has("name") and Addendum.rank_at(cid, T.PERIOD) != "", "%s 인물 %s 1층(이름 · 등급)" % [id, cid])
			check(T.ROLES.has(cid), "%s 인물 %s 3층 역할" % [id, cid])
			var role: Dictionary = T.ROLES.get(cid, {})
			check(Looks.known(str(role.get("look", ""))), "%s 인물 %s 외형 %s" % [id, cid, role.get("look")])
			if role.has("moveset"):
				for k in role["moveset"]:
					check(Moves.M.has(role["moveset"][k]), "%s 인물 %s 동작 %s" % [id, cid, role["moveset"][k]])
			if role.has("ai") or not (role.has("moveset") or T.HEROES.has(cid)):
				check(EnemyAI.PROFILES.has(str(role.get("ai", ""))), "%s 적 %s AI 프로필 %s" % [id, cid, role.get("ai")])
		for lk in looks:
			check(Looks.known(lk), "%s 덧붙임 외형 %s" % [id, lk])


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
	var dot := Save.parse('{"v": 1, "cleared": {}, "art": "b"}')
	check(dot["save"]["art"] == "a" and not Save.ARTS.has("b"), "옛 세이브의 그림 B(도트)는 A 로 — 처음 화면에서 뺐다(2026-11-11)")
	var odd := Save.parse('{"v": 1, "cleared": {"ch6": 3, "zz": {"count": 1}}, "art": "q"}')
	check(not Save.cleared(odd["save"], "ch6") and odd["save"]["art"] == "a", "모양이 틀린 칸은 버리고 기본값 %s" % odd["save"])
	check(odd["save"]["cleared"].has("zz"), "모르는 장 id 는 남긴다(다음 판이 만들 장)")


func test_next_chapter_and_unlock() -> void:
	var s := Save.fresh()
	check(Save.next_chapter(s) == "ch0", "처음 이어하기 = 할 수 있는 첫 장(프롤로그)")
	Save.record_clear(s, "ch0", 2000)
	check(Save.next_chapter(s) == "ch1", "프롤로그를 깨면 1장")
	Save.record_clear(s, "ch1", 9000)
	check(Save.next_chapter(s) == "ch2", "1장을 깨면 2장")
	Save.record_clear(s, "ch2", 9000)
	Save.record_clear(s, "ch6", 3000)
	check(Save.next_chapter(s) == "ch7", "6장(결투)을 깨면 7장")
	Save.record_clear(s, "ch13", 9000)
	check(Save.next_chapter(s) == "ch13", "끝 장(13장)을 깨면 끝 장 그대로")
	s["last"] = "ch11"
	check(Save.next_chapter(s) == "ch12", "마지막으로 깬 장의 다음 장")
	s["last"] = "nope"
	check(Save.next_chapter(s) == "ch0", "마지막 장이 못 하는 장이면 첫 장")
	# rc.2 폰(2026-11-07): 카드로 1장부터 깨면(프롤로그는 안 깸) 이어하기가 2장이어야 — 옛 규칙은 안 깬 첫 장(프롤로그)으로 갔다
	var u := Save.fresh()
	Save.record_clear(u, "ch1", 9000)
	check(Save.next_chapter(u) == "ch2", "프롤로그를 건너뛰고 1장을 깨도 이어하기는 2장 — %s" % Save.next_chapter(u))
	var t := Save.fresh()
	check(Save.unlocked(t, "ch0") and not Save.unlocked(t, "nope"), "첫 장은 열림 · 없는 장은 잠김")
	check(Save.unlocked(t, "ch11") == Campaign.OPEN_ALL, "11장은 시험판(OPEN_ALL)이면 처음부터 열림")
	check(Save.unlocked_by_order(t, "ch1") == false, "차례 규칙만으로는 프롤로그를 깨야 1장")
	Save.record_clear(t, "ch0", 1)
	check(Save.unlocked_by_order(t, "ch1"), "프롤로그를 깨면 1장이 열린다")
	Save.record_clear(t, "ch1", 1)
	check(Save.unlocked_by_order(t, "ch2") and not Save.unlocked_by_order(t, "ch6"), "1장을 깨면 2장이 열린다(6장은 아직)")
	Save.record_clear(t, "ch2", 1)
	var after2: String = Campaign.ids()[Campaign.ids().find("ch2") + 1]
	check(Save.unlocked_by_order(t, after2), "2장을 깨면 다음 장(%s)이 열린다" % after2)
	# 모든 장: 차례대로 깨면 다음 장이 열리고 이어하기가 그 장 — rc.4 폰(2026-11-09 "8장 깨도 9장으로 안넘어가")
	var all := Save.fresh()
	var ids := Campaign.playable_ids()
	for i in ids.size() - 1:
		check(not Save.unlocked_by_order(all, ids[i + 1]), "%s 를 깨기 전에는 %s 잠김" % [ids[i], ids[i + 1]])
		Save.record_clear(all, ids[i], 0)
		check(Save.unlocked_by_order(all, ids[i + 1]) and Save.next_chapter(all) == ids[i + 1],
			"%s 를 깨면 %s 열림 · 이어하기 %s" % [ids[i], ids[i + 1], Save.next_chapter(all)])


## 뒤 장을 깬 기록이 있으면 그 앞 장은 모두 열림 — 모든 장 열림(OPEN_ALL) 때 7 ~ 12장을 깬 세이브에서 5 · 6장이 잠겼다(rc.4 폰 2026-11-10)
func test_unlock_before_furthest_clear() -> void:
	var s := Save.fresh()
	for id in ["ch0", "ch1", "ch2", "ch3", "ch7", "ch8", "ch9", "ch10", "ch11"]:
		Save.record_clear(s, id, 1)
	for id in ["ch4", "ch5", "ch6a", "ch6", "ch7", "ch12"]:
		check(Save.unlocked_by_order(s, id), "%s: 뒤 장(11장)을 깼으면 열림" % id)
	check(not Save.unlocked_by_order(s, "ch13"), "13장은 12장을 깨야")
	Save.record_clear(s, "ch12", 1)
	check(Save.unlocked_by_order(s, "ch13"), "12장을 깨면 13장")


## 중간 스테이지부터 한 판(난이도를 바꿔 다시 · 싸움 중 메뉴로 고른 스테이지)도 깬 장 — 가장 짧은 판은 첫 스테이지부터만(frames 0 = 안 잼)
func test_clear_from_middle_keeps_best() -> void:
	var s := Save.fresh()
	Save.record_clear(s, "ch8", 0)
	check(Save.cleared(s, "ch8") and int(s["cleared"]["ch8"]["best"]) == 0, "중간부터 깨도 깬 장 · 가장 짧은 판은 없음 %s" % s)
	Save.record_clear(s, "ch8", 5000)
	Save.record_clear(s, "ch8", 0)
	check(int(s["cleared"]["ch8"]["count"]) == 3 and int(s["cleared"]["ch8"]["best"]) == 5000, "중간부터 한 판은 가장 짧은 판을 안 바꾼다 %s" % s)


## 게임 속도(사용자 2026-11-06 "싸움이 너무 느린데 게임 속도를 더 빨리 할 수 있는 버튼") — 세이브에 남는 고르기
func test_save_speed() -> void:
	check(float(Save.fresh()["speed"]) == 1.0, "새 세이브는 ×1")
	check(Save.next_speed(1.0) == 1.5 and Save.next_speed(1.5) == 2.0 and Save.next_speed(2.0) == 1.0, "×1 → ×1.5 → ×2 → ×1")
	check(Save.next_speed(7.0) == 1.0, "모르는 값 다음은 ×1")
	check(float(Save.parse('{"v": 1, "cleared": {}}')["save"]["speed"]) == 1.0, "속도 칸이 없는 옛 세이브는 ×1")
	check(float(Save.parse('{"v": 1, "speed": 2}')["save"]["speed"]) == 2.0, "고른 속도는 남는다(JSON 정수 2 도)")
	check(float(Save.parse('{"v": 1, "speed": 9}')["save"]["speed"]) == 1.0, "고를 수 없는 속도는 ×1")
	check(Save.speed_label(1.0) == "×1" and Save.speed_label(1.5) == "×1.5" and Save.speed_label(2.0) == "×2", "버튼 글")


## 스테이지 고르기(사용자 2026-11-06 "메뉴 · 선택 같은 거 … 스테이지 넘어갈 수 있게") — 장 안의 방 목록
func test_stages_of_chapter() -> void:
	var st := Campaign.stages("ch11")
	check(st.size() == _menu_rooms(Hotel), "11장 스테이지 = 끝 방을 뺀 여섯 %s" % [st])
	check(int(st[0]["room"]) == 0 and str(st[0]["title"]) == "호텔 캐슬 지하주차장", "첫 스테이지 이름은 방 들어서는 글 %s" % st[0])
	check(int(st[4]["room"]) == 4 and str(st[4]["title"]).contains("회장실"), "다섯째 = 회장실 앞 %s" % st[4])
	var d6 := Campaign.stages("ch6")
	check(d6.size() == 1 and int(d6[0]["room"]) == 0 and str(d6[0]["title"]) != "", "결투 장은 스테이지 하나 %s" % [d6])
	check(Campaign.stages("nope").is_empty(), "없는 장은 스테이지 없음")
	var s1 := Campaign.stages("ch1")
	check(s1.size() == _menu_rooms(Hoeam) and str(s1[0]["title"]) != "", "1장 스테이지 = 방 %d %s" % [Hoeam.ROOMS.size(), s1])
	var s2 := Campaign.stages("ch2")
	check(s2.size() == _menu_rooms(Haseong) and str(s2[1]["title"]).contains("1층"), "2장 스테이지 = 방 %d %s" % [Haseong.ROOMS.size(), s2])



## 스테이지 메뉴에 보이는 방 수 — 끝 방(end, 글만)은 빼고
func _menu_rooms(T) -> int:
	return T.ROOMS.filter(func(r): return not r.get("end", false)).size()


## canon 읽기(장 데이터 검사 전용 — data/common/canon/ 은 APK 에 안 들어간다: export_presets.cfg exclude_filter)
func _canon_ids(file: String, key: String) -> Dictionary:
	var j = JSON.parse_string(FileAccess.get_file_as_string("res://data/common/canon/%s.json" % file))
	var out := {}
	for e in (j[key] if j is Dictionary else j):
		out[str(e["id"])] = e
	return out


## 장 데이터의 원작 id 검사(castle_common 요청 21 — 장 데이터의 무대 · 인물 · 대결 id · 대사 refs 가 canon 에 있다):
## 방마다 CANON 칸(fight · place) · 방 사람(엑스트라 빼고)은 canon 인물 · 대결의 사람 중 하나는 방에 있다 · 대사 refs 의 화가 있다
func test_chapter_canon_ids() -> void:
	var fights := _canon_ids("fights", "fights")
	var places := _canon_ids("locations", "locations")
	var people := _canon_ids("characters", "characters")
	check(fights.size() > 100 and places.size() > 50 and people.size() > 100, "canon 을 읽었다 %d · %d · %d" % [fights.size(), places.size(), people.size()])
	for id in Campaign.playable_ids():
		var T = Campaign.table(id)
		if T == null:
			continue
		for room in T.ROOMS:
			var rid := str(room["id"])
			check(T.CANON.has(rid), "%s 방 %s 원작 근거(CANON)" % [id, rid])
			var cn: Dictionary = T.CANON.get(rid, {})
			var fid := str(cn.get("fight", ""))
			check(places.has(str(cn.get("place", ""))), "%s 방 %s 장소 %s 가 canon 에" % [id, rid, cn.get("place")])
			check(fid == "" or fights.has(fid), "%s 방 %s 대결 %s 가 canon 에" % [id, rid, fid])
			check(fid != "" or room["enemies"].is_empty(), "%s 방 %s 적이 있으면 대결 id 가 있다" % [id, rid])
			var who: Array = T.HEROES.duplicate()
			for a in room["allies"] + room["enemies"]:
				who.append(a[0])
			for cid in who:
				check(Addendum.EXTRAS.has(cid) or people.has(cid), "%s 방 %s 인물 %s 가 canon 에(엑스트라가 아니면)" % [id, rid, cid])
			if fid != "" and fights.has(fid):
				var actors: Array = fights[fid]["actors"]
				check(who.any(func(c): return actors.has(c)), "%s 방 %s 의 사람 중 하나는 대결 %s 의 사람 %s" % [id, rid, fid, actors])
	_check_refs(Lines.all(), "lines")


## 대사 refs("056/039-040" · "p1:014/025-027")의 화가 canon episodes 에 있다
func _check_refs(v, path: String) -> void:
	if v is Dictionary:
		for k in v:
			if str(k) == "refs":
				for r in v[k]:
					check(_ep_exists(str(r)), "%s refs %s 의 화가 canon 에" % [path, r])
			else:
				_check_refs(v[k], path + "." + str(k))
	elif v is Array:
		for x in v:
			if x is Array and x.size() > 0 and x.all(func(e): return e is String and _is_ref(e)):
				for r in x:
					check(_ep_exists(str(r)), "%s refs %s 의 화가 canon 에" % [path, r])
			else:
				_check_refs(x, path)


func _is_ref(s: String) -> bool:
	return RegEx.create_from_string("^(p1:)?\\d{3}(/[\\d@\\-]+)?$").search(s) != null


func _ep_exists(r: String) -> bool:
	var m := RegEx.create_from_string("^(p1:)?(\\d{3})").search(r)
	if m == null:
		return false
	var f := ("p1_" if m.get_string(1) != "" else "") + m.get_string(2)
	return FileAccess.file_exists("res://data/common/canon/episodes/%s.json" % f)


## 음악(2026-11-09 — 장마다 곡): 모든 장의 곡 · 마지막 보스 방 곡 · 처음 화면 · 끝 곡 파일이 있고, 방에 따라 고른다
func test_chapter_songs() -> void:
	for id in Campaign.playable_ids():
		var rooms: int = Campaign.table(id).ROOMS.size() if Campaign.kind(id) == "stage" else 1
		for i in rooms:
			var s := Campaign.song_for(id, i)
			check(ResourceLoader.exists("res://assets/music/%s.ogg" % s), "%s 방 %d 곡 %s 파일" % [id, i, s])
	for s in [Campaign.TITLE_SONG, Campaign.ENDING_SONG, "victory", "gameover"]:
		check(ResourceLoader.exists("res://assets/music/%s.ogg" % s), "곡 %s 파일" % s)
	check(Campaign.song_for("ch6", 0) == "boss", "6장 결투는 boss")
	check(Campaign.song_for("ch5", 0) == "sad" and Campaign.song_for("ch7", 0) == "resolve", "대화 장은 장 곡")
	var r12: Array = Campaign.table("ch12").ROOMS
	var last := -1
	for i in r12.size():
		if str(r12[i].get("boss", "")) != "":
			last = i
	check(Campaign.song_for("ch12", last) == "final" and Campaign.song_for("ch12", 0) == "dungeon", "12장 최종 보스 방만 final")
	check(Campaign.song_for("ch1", 0) == "street", "1장 첫 방은 거리 곡")
	check(Campaign.song_for("zzz", 0) == "battle", "모르는 장은 battle")
