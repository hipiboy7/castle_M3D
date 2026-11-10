extends "res://tests/helpers.gd"
## 통합 시험(B 등급) — 방 규칙 칸(src/combat/stage.gd 머리 2026-11-10): 작은 예시 장 표(사전 — Stage.make opts table)로
## triggers(down → spawn · boss · recruit / hp → say + calm + clear / time · after · x · clear · survive) · survive · limit 짐 ·
## protect 짐 · escape(버틴 뒤 빠져나가기) · learn(10장 리천 뒤 김신 촌경 · 삼연타) · standing · auto(관전) · ranks · hold ·
## 같은 시드 같은 결과.

const Stage = preload("res://src/combat/stage.gd")
const Campaign = preload("res://src/data/campaign.gd")
const B := Rect2(-6.0, -2.4, 12.0, 4.8)


## 예시 장 표 — 10장 역할(ROLES)을 빌리고 방만 시험마다
func _tbl(rooms: Array, more := {}) -> Dictionary:
	var T := {"EVENT": "retreat:richeon", "PERIOD": "hwajin", "HEROES": ["kimshin", "woojin"], "LINES": "zz_test",
		"CROWD_ID": "street_thug", "ROLES": Campaign.table("ch10").ROLES, "ROOMS": rooms, "INTRO_T": 5, "CLEAR_T": 10,
		"END_T": 20, "HEAL_ON_CLEAR": 0.25, "MAX_ATTACKERS": 2}
	T.merge(more, true)
	return T


func _room(extra: Dictionary) -> Dictionary:
	var r := {"id": "r", "theme": "market_alley", "bounds": B, "cast": ["kimshin"], "heroes": [Vector2(-4.0, 0.0)],
		"allies": [], "enemies": []}
	r.merge(extra, true)
	return r


const END := {"id": "end", "theme": "market_alley", "bounds": B, "cast": ["kimshin"], "heroes": [Vector2(0, 0)],
	"allies": [], "enemies": [], "end": true}


func _mk(rooms: Array, seed_value := 1, more := {}) -> Dictionary:
	return Stage.make(seed_value, {"table": _tbl(rooms, more)})


## n 프레임(사람 입력 human — 기본 가만히). 신호를 모아 돌려준다
func _go(d: Dictionary, n: int, human = {}) -> Array:
	var ev: Array = []
	for i in n:
		if d["world"].over != "":
			break
		Stage.step(d, human)
		ev.append_array(d["world"].events)
		d["world"].events.clear()
	return ev


func _fight(d: Dictionary) -> void:
	_go(d, 6)


func _one(d: Dictionary, id: String):
	for f in d["world"].fighters:
		if f.char_id == id:
			return f
	return null


func test_down_spawns_and_sets_boss() -> void:
	var d := _mk([_room({"enemies": [["street_thug", Vector2(3.0, 1.5), {"tag": "first"}]],
		"triggers": [{"when": "down:first", "spawn": [["richeon", Vector2(4.0, 0.0)]], "boss": "richeon",
			"say": [["리천", "왔다"]]}]}), END])
	_fight(d)
	check(d["stage"] == "fight" and d["enemies"].size() == 1, "처음엔 한 사람")
	d["enemies"][0].die()
	var ev := _go(d, 1)
	var ri = _one(d, "richeon")
	check(ri != null and d["enemies"].has(ri) and ri.team == 1, "down:first → 리천이 선다")
	check(ev.any(func(e): return e[0] == "spawn" and e[1] == ri), "spawn 신호(main.gd 가 인형을 더한다)")
	check(d["boss"] == ri and ri.oneshot_immune, "boss: 큰 막대가 리천 · 한 방 안 받음")
	check(ev.any(func(e): return e[0] == "line" and e[1] == "리천"), "say 한 줄")
	check(d["stage"] == "fight", "새 적이 있어 방을 넘지 않는다")


func test_recruit_joins_our_side() -> void:
	var d := _mk([_room({"enemies": [["hantaecheol", Vector2(1.0, 0.0)], ["street_thug", Vector2(4.0, 1.5)]],
		"triggers": [{"when": "down:hantaecheol", "recruit": "hantaecheol", "say": [["한태철", "형님, 같이 갑시다"]]}]}), END])
	_fight(d)
	var ht = _one(d, "hantaecheol")
	ht.die()
	var ev := _go(d, 1)
	check(d["allies"].has(ht) and not d["enemies"].has(ht) and ht.team == 0, "recruit: 우리 편 칸 · 팀 0")
	check(ht.alive() and ht.hp >= ht.hp_max * Stage.RECRUIT_HP - 0.01 and not ht.inert, "일으켜 세우고 체력 회복")
	check(d["bots"].has(ht) and not d["ais"].has(ht) and not ht.is_boss, "moveset 이 있는 역할은 아군 봇")
	check(ev.any(func(e): return e[0] == "recruit" and e[1] == ht), "recruit 신호")
	_go(d, 240)
	check(d["world"].over != "lose", "합류한 뒤 4초 돈다")
	# moveset 없는 역할(리천)은 제 AI 그대로 적을 친다
	var d2 := _mk([_room({"enemies": [["richeon", Vector2(1.0, 0.0)], ["street_thug", Vector2(4.0, 1.5)]],
		"triggers": [{"when": "hp:richeon:0.9", "recruit": "richeon"}]}), END])
	_fight(d2)
	var ri = _one(d2, "richeon")
	ri.hp = ri.hp_max * 0.8
	_go(d2, 1)
	check(d2["allies"].has(ri) and d2["ais"].has(ri) and ri.team == 0, "moveset 없는 역할은 AI 그대로 아군")
	_go(d2, 120)
	check(ri.target() == null or ri.target().team == 1, "리천이 적(팀 1)을 겨눈다")


func test_hp_say_calm_clear_after_lines() -> void:
	var d := _mk([_room({"enemies": [["richeon", Vector2(1.5, 0.0)], ["street_thug", Vector2(3.0, 1.5)]],
		"triggers": [{"when": "hp:richeon:0.5", "say": [["앤디청", "여기까지"], ["서진태", "칫"]], "calm": true, "clear": true}]}), END])
	_fight(d)
	var ri = _one(d, "richeon")
	ri.hp = ri.hp_max * 0.45
	_go(d, 1)
	check(d["enemies"].all(func(e): return e.inert), "calm: 적이 모두 싸움을 멈춘다")
	_go(d, 300)
	check(d["stage"] == "fight", "대사(2줄 × %.1f초)가 남아 아직 방을 넘지 않는다" % Stage.SAY_SECS)
	_go(d, 140)
	check(d["stage"] == "clear" or d["room_i"] == 1, "대사가 끝나면 방을 깬다 (%s)" % d["stage"])


func test_time_after_and_clear_when() -> void:
	var d := _mk([_room({"enemies": [["street_thug", Vector2(3.0, 1.5)]],
		"triggers": [{"when": "time:0.5", "say": [["하나", "둘"]]},
			{"when": "after:0:1", "spawn": [["street_thug", Vector2(4.0, -1.5), {"tag": "late"}]]},
			{"when": "clear", "spawn": [["gang_blade", Vector2(4.0, 0.0), {"tag": "last"}]]}]}), END])
	_fight(d)
	_go(d, 31)
	check(d["fired"].has(0) and not d["fired"].has(1), "time:0.5 만 터졌다")
	_go(d, 60)
	check(d["fired"].has(1) and d["enemies"].size() == 2, "after:0:1 → 1초 뒤 둘째 무리")
	for e in d["enemies"]:
		e.die()
	_go(d, 1)
	check(d["fired"].has(2) and _one(d, "gang_blade") != null and d["stage"] == "fight", "clear: 넘기 대신 마지막 무리")
	_one(d, "gang_blade").die()
	_go(d, 1)
	check(d["stage"] == "fight" and int(d["n"]) < int(d["say_until"]), "대사(time:0.5)가 남아 아직 넘지 않는다")
	_go(d, int(d["say_until"]) - int(d["n"]) + 1)
	check(d["stage"] == "clear", "대사가 끝나면 넘는다 (%s)" % d["stage"])


func test_pending_spawn_waits() -> void:
	var d := _mk([_room({"enemies": [["street_thug", Vector2(3.0, 1.5)]],
		"triggers": [{"when": "time:2", "spawn": [["street_thug", Vector2(4.0, 0.0)]]}]}), END])
	_fight(d)
	d["enemies"][0].die()
	_go(d, 30)
	check(d["stage"] == "fight", "앞으로 터질 spawn 이 남으면 적이 없어도 방을 넘지 않는다")
	_go(d, 100)
	check(d["enemies"].size() == 2 and d["stage"] == "fight", "time:2 무리가 선다")


func test_long_map_x_trigger_bot_walks() -> void:
	var long := Rect2(-6.0, -2.4, 34.0, 4.8)
	var d := _mk([_room({"bounds": long, "enemies": [],
		"triggers": [{"when": "x:12", "spawn": [["street_thug", Vector2(18.0, 0.0)], ["street_thug", Vector2(19.0, 1.5)]]}]}), END])
	var n := 0
	while not d["fired"].has(0) and n < 60 * 20:
		Stage.step(d)                                      # 봇(자동 플레이)이 앞장서 오른쪽으로 걷는다
		d["world"].events.clear()
		n += 1
	check(d["fired"].has(0) and d["hero"].pos.x >= 12.0, "x:12 — 복도 끝에서 다음 무리 (%d 프레임)" % n)
	var r := _go(d, 60 * 40, null)
	check(d["room_i"] == 1 or d["world"].over == "win", "봇이 무리를 쓰러뜨리고 방을 넘는다 (%s · %s)" % [d["stage"], d["world"].over])


func test_survive_clears_and_limit_loses() -> void:
	var d := _mk([_room({"enemies": [["street_thug", Vector2(5.0, 2.0)]], "survive": 2.0}), END])
	_fight(d)
	_go(d, 90)
	check(d["stage"] == "fight" and Stage.timers(d)["survive"] > 0.0, "1.5초 — 아직 버티는 중 (남은 %.1f)" % Stage.timers(d)["survive"])
	_go(d, 40)
	check(d["stage"] == "clear" or d["room_i"] == 1, "2초를 버티면 깬다")
	check(d["enemies"].all(func(e): return not e.alive() or e.inert), "버틴 뒤 남은 적은 멈춘다")
	var d2 := _mk([_room({"enemies": [["richeon", Vector2(5.0, 2.0), {"hp_k": 10.0}]], "limit": 1.0}), END])
	_fight(d2)
	check(absf(Stage.timers(d2)["limit"] - 1.0) < 0.05, "limit 남은 초")
	_go(d2, 70)
	check(d2["world"].over == "lose" and d2.get("lose_line", []).size() == 2, "limit 안에 못 깨면 진다 · 패배 글 %s" % [d2.get("lose_line")])


func test_protect_loses_when_ally_down() -> void:
	var d := _mk([_room({"allies": [["hantaecheol", Vector2(-3.0, 1.0)]], "enemies": [["street_thug", Vector2(4.0, 0.0)]],
		"protect": ["hantaecheol"]}), END])
	_fight(d)
	_one(d, "hantaecheol").die()
	_go(d, 1)
	check(d["world"].over == "lose", "지킬 사람이 쓰러지면 진다")
	check(str(d.get("lose_line", ["", ""])[0]).contains("한태철"), "패배 글에 이름 %s" % [d.get("lose_line")])


func test_survive_then_escape() -> void:
	var exit := Rect2(4.6, -2.4, 1.4, 4.8)
	var rooms := [_room({"enemies": [["richeon", Vector2(5.0, 2.0), {"hp_k": 10.0}]], "survive": 1.0,
		"triggers": [{"when": "survive", "escape": {"exit": exit, "secs": 2.0}}]}), END]
	var d := _mk(rooms)
	_fight(d)
	_go(d, 70)
	check(d["stage"] == "fight" and Stage.timers(d)["escape"] > 1.0, "버틴 뒤에는 빠져나가야 깬다 (남은 %.1f)" % Stage.timers(d)["escape"])
	_go(d, 130)
	check(d["world"].over == "lose", "escape 시간 안에 못 닿으면 진다")
	var d2 := _mk(rooms)
	_fight(d2)
	_go(d2, 70)
	d2["hero"].pos = exit.get_center()
	var ev := _go(d2, 1)
	check(d2["stage"] == "clear" and ev.any(func(e): return e[0] == "escape"), "출구에 닿으면 깬다")


func test_learn_gives_inch_and_triple() -> void:
	var mv := Moves.get_move("s_inch")
	check(mv["skill_id"] == "inch" and mv["guard_break"] and int(mv["startup"]) <= 6 \
		and float(mv["knockback"]) > float(Moves.get_move("s_offbeat2")["knockback"]),
		"촌경 동작: 준비 짧음 · 가드 뚫음 · 큰 넉백")
	check(Skills.MOVE_OF.get("inch", "") == "s_inch", "inch → s_inch")
	var d := _mk([_room({"enemies": [["street_thug", Vector2(4.0, 1.5)]],
		"triggers": [{"when": "time:0.2", "learn": "beat:richeon"}]}), END])
	var k = d["heroes"][0]
	var ids0: Array = k.skills.map(func(e): return e["id"])
	check(k.rank == "톱" and not ids0.has("inch"), "리천 앞: 김신 톱 · 촌경 없음 (%s %s)" % [k.rank, ids0])
	_fight(d)
	var ev := _go(d, 15)
	var ids: Array = k.skills.map(func(e): return e["id"])
	check(k.rank == "재앙" and ids.has("inch") and ids.has("triple"), "learn beat:richeon → 재앙 · 촌경 · 삼연타 %s" % [ids])
	var got: Array = []
	for e in ev:
		if e[0] == "learn" and e[1] == k:
			got = e[2]
	check(got.has("촌경"), "새 기술 알림 %s" % [got])
	var inch: Dictionary = k.skills.filter(func(e): return e["id"] == "inch")[0]
	check(inch["move"] == "s_inch", "촌경은 s_inch 로 쓴다")


func test_standing_people_do_not_fight() -> void:
	var d := _mk([_room({"enemies": [["street_thug", Vector2(3.0, 1.5)]],
		"standing": [["hantaecheol", Vector2(0.0, 2.0), 0], ["gang_blade", Vector2(1.0, -2.0), 1, {"tag": "watcher"}]],
		"triggers": [{"when": "down:watcher", "say": [["안", "됨"]]}]}), END])
	_fight(d)
	check(d["standing"].size() == 2 and d["enemies"].size() == 1 and d["allies"].is_empty(), "서 있는 사람은 적 · 아군 칸에 없다")
	var hp0: Array = d["standing"].map(func(f): return f.hp)
	_go(d, 240, null)
	check(d["standing"].all(func(f): return f.inert and f.alive()), "서 있는 사람은 inert")
	check(d["standing"].map(func(f): return f.hp) == hp0, "맞지 않는다")
	check(not d["fired"].has(0), "서 있는 사람은 down 으로 안 센다")
	var s = d["standing"][0]
	check(s.facing.dot((B.get_center() - s.pos).normalized()) > 0.9, "가운데를 본다")


func test_auto_room_ignores_human() -> void:
	var rooms := [_room({"cast": ["kimshin", "woojin"], "heroes": [Vector2(-4.0, -1.0), Vector2(-4.0, 1.0)], "auto": true,
		"enemies": [["street_thug", Vector2(2.0, 1.5)], ["street_thug", Vector2(3.0, -1.5)]]}), END]
	var push := {"move": Vector2(-1, 0), "face": Vector2(-1, 0)}
	var d := _mk(rooms)
	_fight(d)
	check(Stage.timers(d)["auto"], "관전 방 표시")
	_go(d, 1, push)
	check(d["hero"].intent != push, "사람 입력이 아니라 봇이 움직인다")
	_go(d, 60 * 40, push)
	check(d["room_i"] == 1 or d["world"].over == "win", "사람 입력 없이(왼쪽으로 밀어도) 봇끼리 방을 깬다 (%s)" % d["stage"])
	var a := Stage.simulate(3, 60 * 20, {"table": _tbl(rooms)})
	var b := Stage.simulate(3, 60 * 20, {"table": _tbl(rooms)})
	check(a == b, "관전 방 같은 시드 같은 결과")


func test_ranks_override() -> void:
	var rooms := [_room({"ranks": {"kimshin": "톱", "richeon": "내성 중위"}, "enemies": [["richeon", Vector2(3.0, 0.0)]]}),
		_room({"id": "r2", "enemies": [["street_thug", Vector2(3.0, 0.0)]]}), END]
	var d := _mk(rooms, 1, {"EVENT": "raid:castle_hotel", "HERO_RANKS": {"woojin": "외성 하위"}})
	var k = d["heroes"][0]
	check(k.rank == "톱" and k.skills.size() <= 7, "방 ranks: 김신 톱 · 기술 7개까지 (%d)" % k.skills.size())
	check(_one(d, "richeon").rank == "내성 중위", "방 ranks: 리천 내성 중위")
	check(d["heroes"][1].rank == "외성 하위", "장 표 HERO_RANKS: 피우진 외성 하위")
	Stage._enter(d, 1)
	check(k.rank == "재앙", "다음 방(ranks 없음)은 그 장 등급으로 돌아온다 (%s)" % k.rank)


func test_hold_freezes_everyone() -> void:
	var d := _mk([_room({"enemies": [["street_thug", Vector2(3.0, 1.5)]],
		"triggers": [{"when": "time:0.1", "say": [["연출", "모두 멈춤"]], "hold": true}]}), END])
	_fight(d)
	_go(d, 8)
	var ft: int = d["fight_t"]
	var x: float = d["hero"].pos.x
	_go(d, 60, {"move": Vector2(1, 0), "face": Vector2(1, 0)})
	check(d["fight_t"] == ft and absf(d["hero"].pos.x - x) < 0.05, "hold 동안 싸움 시간 · 사람 입력이 멈춘다")
	_go(d, 200, {"move": Vector2(1, 0), "face": Vector2(1, 0)})
	check(d["fight_t"] > ft and d["hero"].pos.x > x + 0.5, "대사가 끝나면 다시 움직인다")


func test_triggers_deterministic() -> void:
	var rooms := [_room({"cast": ["kimshin", "woojin"], "heroes": [Vector2(-4.0, -1.0), Vector2(-4.0, 1.0)],
		"enemies": [["street_thug", Vector2(2.0, 1.5), {"tag": "a"}], ["street_thug", Vector2(3.0, -1.5), {"tag": "a"}]],
		"triggers": [{"when": "down:a", "spawn": [["gang_blade", Vector2(4.0, 0.0)], ["street_thug", Vector2(4.0, 1.5)]]},
			{"when": "after:0:2", "spawn_allies": [["hantaecheol", Vector2(-5.0, 0.0)]]}]}), END]
	var a := Stage.simulate(7, 60 * 60, {"table": _tbl(rooms)})
	var b := Stage.simulate(7, 60 * 60, {"table": _tbl(rooms)})
	check(a == b, "triggers 판 같은 시드 같은 결과\n%s\n%s" % [a, b])
	check(a["over"] == "win", "봇이 두 무리를 넘어 끝까지 (%s)" % [a])
