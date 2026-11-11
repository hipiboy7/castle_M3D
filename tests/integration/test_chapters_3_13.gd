extends "res://tests/helpers.gd"
## 통합 시험(B 등급) — 3 ~ 13장(2026-11-08): 모든 방이 서고(인물 · 역할 · AI · 외형) 2초 동안 돌아간다 · 장 표 NPCS 가 등급을 덮는다 ·
## 대화 방(talk — 5 · 7장 · 13장 맺음)은 say 줄을 차례로 보이고 저절로 넘어간다 · 따돌리기 방(3장 오도화 · 9장 리천) · 같은 시드 같은 결과.

const Stage = preload("res://src/combat/stage.gd")
const Campaign = preload("res://src/data/campaign.gd")
const EnemyAI = preload("res://src/combat/enemy_ai.gd")
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
	var r := Stage.simulate(1, 60 * 300, {"chapter": "ch7"})
	check(r["over"] == "win", "7장(관전 · 대화)은 끝까지 간다 — 관전 방은 봇이 이긴다 %s" % r["over"])
	var T7 = Campaign.table("ch7")
	check(T7.ROOMS.filter(func(rm): return rm.get("auto", false)).size() >= 4, "7장은 관전 방(auto)이 넷 이상 — 컴퓨터끼리 싸우는 장면")


## 8장 등급(사용자 2026-11-10): 피우진 이스크라 평 킬러급 · 교류회 김신 톱 대 류지학 내성 중위. 9장 CLUB BUDAPEST: 바이슨 피 반 → 그롤라 등장 · 싸움 멈춤
func test_ch8_ranks_and_ch9_club_script() -> void:
	var d := Stage.make(1, {"chapter": "ch8", "room": 0})
	check(d["hero"].char_id == "woojin" and d["hero"].rank == "이스크라 평 킬러급", "8장 피우진 = 이스크라 평 킬러급 (%s)" % d["hero"].rank)
	var d2 := Stage.make(1, {"chapter": "ch8", "room": 3})
	check(d2["hero"].rank == "톱" and d2["boss"].char_id == "ryujihak" and d2["boss"].rank == "내성 중위",
		"8장 교류회 김신 톱 대 류지학 내성 중위 (%s / %s)" % [d2["hero"].rank, d2["boss"].rank])
	var d3 := Stage.make(1, {"chapter": "ch9", "room": 1})
	while d3["stage"] != "fight":
		Stage.step(d3)
	var bison = d3["enemies"].filter(func(e): return e.char_id == "bison")[0]
	bison.hp = bison.hp_max * 0.5
	for i in 3:
		Stage.step(d3)
	check(d3["enemies"].any(func(e): return e.char_id == "grolla"), "바이슨 피 반 → 그롤라가 나타난다")
	check(d3["enemies"].all(func(e): return e.inert or not e.alive()), "싸움이 멈춘다(calm)")
	var n := 0
	while d3["room_i"] == 1 and n < 60 * 60:
		Stage.step(d3)
		d3["world"].events.clear()
		n += 1
	check(d3["room_i"] == 2 and d3["allies"].is_empty(), "대사가 끝나면 장례식 방으로 (%d 프레임)" % n)


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


## 10장 산 기슭(사용자 2026-11-11): 아킬라 대 구스타프(타격) — 구스타프 피가 50% 아래면 자유로운 영혼 팀 콘도르(쌍권총) · 헤론(저격 소총) ·
## 오울(돌격소총)이 뒤에서 → 총격전(아킬라 기본 공격이 리볼버 → 산탄총, 산길이 넓어짐). 넷 다 쓰러뜨려야 넘는다
func test_ch10_mountain_road_gunfight() -> void:
	var T = Campaign.table("ch10")
	var ri := -1
	for i in T.ROOMS.size():
		if T.ROOMS[i]["id"] == "mountain_road":
			ri = i
	var d := Stage.make(3, {"chapter": "ch10", "room": ri})
	var gus = d["enemies"].filter(func(e): return e.char_id == "gustav")[0]
	var aki = d["heroes"].filter(func(h): return h.char_id == "akila")[0]
	check(d["ais"][gus].prof == EnemyAI.PROFILES["x_master"] and not d["ais"][gus].prof.has("ranged"), "구스타프는 타격(총 없음)")
	for n in 240:
		Stage.step(d, {})
	check(d["enemies"].size() == 1, "처음엔 구스타프 혼자")
	var w0: float = d["world"].bounds.size.x
	gus.hp = gus.hp_max * 0.45
	for n in 10:
		Stage.step(d, {})
	var ids: Array = d["enemies"].map(func(e): return e.char_id)
	for id in ["condor", "heron", "owl"]:
		check(ids.has(id), "%s 등장 %s" % [id, ids])
	var team: Array = d["enemies"].filter(func(e): return e.char_id in ["condor", "heron", "owl"])
	check(team.all(func(e): return e.pos.x > gus.pos.x), "구스타프 뒤쪽에서")
	check(team.all(func(e): return d["ais"][e].kite and d["ais"][e].prof.has("ranged")), "셋 다 거리를 두는 총잡이")
	check(d["world"].bounds.size.x > w0, "산길이 넓어진다")
	check(str(aki.moveset.get("combo", "")) == "akg_1" and Moves.get_move("akg_1")["shape"] == "shot", "아킬라 기본 공격이 리볼버")
	check(Moves.get_move("akg_2")["next"] == "akg_3" and Moves.get_move("akg_3")["label"] == "펌프 산탄총", "리볼버 → 왼손 → 산탄총")
	# 헤론은 멀리서 저격(조준선 · 막을 수 없음) — 적 기술 이름도 원작대로
	var her = team.filter(func(e): return e.char_id == "heron")[0]
	var snipe := Moves.get_move("hr_snipe")
	check(bool(snipe["aim_line"]) and not snipe["parryable"] and float(snipe["reach"]) > float(Moves.get_move("t_shot")["reach"]) * 2.0, "저격은 조준선 · 사거리 길다")
	check(d["ais"][her].skills.any(func(k): return k["name"] == "저격 3연사"), "헤론 기술 묶음에 저격 3연사 %s" % [d["ais"][her].skills.map(func(k): return k["name"])])
	# 구스타프만 쓰러뜨려선 넘지 않는다
	gus.hp = 0.0
	for n in 30:
		Stage.step(d, {})
	check(d["stage"] == "fight", "자유로운 영혼 팀이 남으면 싸움이 이어진다 (%s)" % d["stage"])


## 자유로운 영혼 팀 AI: 헤론은 멀리(near 밖으로 물러남) · 거리 안이면 저격, 오울은 연사 · 수류탄 · 연막 중 굴림
func test_freesoul_ai_ranges() -> void:
	var her = Fighter.new("헤론", 1)
	her.char_id = "heron"
	var kim = Fighter.new("아킬라", 0)
	her.pos = Vector2(2.0, 0)
	kim.pos = Vector2(0, 0)
	var r := RandomNumberGenerator.new()
	r.seed = 5
	var ai = EnemyAI.new(her, "heron", r, 0.0)
	ai.cooldown = 999
	var it: Dictionary = ai.decide(kim, true)
	check(it["move"].x > 0.0, "헤론은 붙으면 물러난다 %s" % it["move"])
	her.pos = Vector2(9.0, 0)
	ai.ranged_cd = 0
	it = ai.decide(kim, true)
	check(str(it.get("use", "")) == "hr_snipe", "멀리서 저격 %s" % it)
	var seen := {}
	for k in 30:
		var owl = Fighter.new("오울", 1)
		owl.char_id = "owl"
		owl.pos = Vector2(4.0, 0)
		var r2 := RandomNumberGenerator.new()
		r2.seed = 100 + k
		var a2 = EnemyAI.new(owl, "owl", r2, 0.0)
		a2.ranged_cd = 0
		a2.cooldown = 999
		var it2: Dictionary = a2.decide(kim, true)
		if it2.has("use"):
			seen[str(it2["use"])] = true
	check(seen.has("ow_burst") and seen.has("ow_grenade") and seen.has("ow_smoke"), "오울은 연사 · 수류탄 · 연막 %s" % [seen.keys()])
