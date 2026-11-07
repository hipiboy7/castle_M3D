extends RefCounted
## 방을 차례로 지나는 여러 사람 판(장 표 하나 = 장 하나 — 0장 블라디보스토크(src/data/prologue.gd) · 1장 회암시(hoeam.gd) ·
## 2장 하성 본사(haseong.gd — 방마다 김신 / 서진태 한 사람) · 11장 호텔 캐슬(hotel.gd — 층을 지나며 김신 · 피우진(교대)이 적 여럿과 싸운다)).
## 조작하는 사람은 장 표 HEROES 중 방 표 cast(없으면 전부) — 방에 1명이면 교대 없음. 순수 로직(노드 없음, 60프레임 고정,
## 같은 시드면 같은 결과) — 게임(main.gd) · 시험 · 자동 플레이가 같은 것을 쓴다. 결투(duel.gd)와 같은 모양의 사전을 돌려준다:
## world · hero(지금 조작하는 사람) · boss(화면 위 큰 막대에 보일 적, 없으면 null) + kind "stage" · heroes · enemies · allies.
## 방 · 역할 · 시점은 장 표(src/data/campaign.gd 가 장 id 로 고른다 — ch0 prologue · ch1 hoeam · ch11 hotel), 1층(등급 · 능력치 · 기술)은 castle_common → 없으면 src/data/addendum.gd(3D 덧붙임).
## 판 끝: 마지막 방(end)에 닿으면 win, 방에 나온 조작하는 사람이 다 쓰러지면 lose(world.over). 신겐은 체력 yield_at 에서 길을 내준다(062).
## 따돌리기 방(방 표 escape — 2장 남궁혁 030/013-024): secs 안에 exit 안에 들어서면 적이 남아도 방을 넘고, 못 들어서면 진다
## (버티기로는 안 넘는다 — rc.2 폰 2026-11-07 사용자). 싸움이 시작될 때 안내 글(방 대사 guide), 시간 초과 패배 글은 d["lose_line"].
## 신호(world.events 에 더함): ["room", 방 번호] · ["line", 제목, 작은 글, 초, (늦춤 초)] · ["swap", 새로 조작하는 사람] · ["yield", 적] · ["escape", 사람]

const Fighter = preload("res://src/combat/fighter.gd")
const World = preload("res://src/combat/world.gd")
const EnemyAI = preload("res://src/combat/enemy_ai.gd")
const Bot = preload("res://src/combat/bot.gd")
const Skills = preload("res://src/data/skills.gd")
const Common = preload("res://src/data/common.gd")
const Addendum = preload("res://src/data/addendum.gd")
const Campaign = preload("res://src/data/campaign.gd")
const Lines = preload("res://src/data/lines.gd")


## opts: chapter(장 id — 기본 ch11) · room(시작 방 번호 — 시험용) · crowd(첫 방에 엑스트라를 이만큼 더 — 성능 점검 '적 30명')
static func make(seed_value: int, opts := {}) -> Dictionary:
	var w = World.new()
	w.end_on_ko = false
	var ch := str(opts.get("chapter", "ch11"))
	var T = Campaign.table(ch)
	var d := {"kind": "stage", "chapter": ch, "tbl": T, "world": w, "heroes": [], "ctrl": 0, "room_i": -1, "room": {}, "enemies": [], "allies": [],
		"ais": {}, "bots": {}, "yield": {}, "seed": seed_value, "stage": "intro", "t": 0, "fight_t": 0, "cleared": 0,
		"times": {}, "look_of": {}, "hero": null, "boss": null, "crowd": int(opts.get("crowd", 0)), "n": 0, "cast": []}
	for id in T.HEROES:
		var h = _hero(id, T)
		d["bots"][h] = Bot.new(h, null, _rng(seed_value * 7919 + d["heroes"].size() + 1))
		d["heroes"].append(h)
	_enter(d, int(opts.get("room", 0)))
	return d


static func _rng(s: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = s
	return r


static func _base(f, role: Dictionary, stats: Dictionary) -> void:
	var k := Addendum.derive(stats)
	f.hp_max = float(role["hp"]) * float(k["hp"])
	f.hp = f.hp_max
	f.posture_max = float(role["posture"])
	f.walk_speed = float(role["walk"]) * float(k["speed"])
	f.run_speed = float(role["run"]) * float(k["speed"])
	f.stagger_len = int(role["stagger"])
	f.dmg_k = float(k["dmg"]) * float(role.get("dmg_k", 1.0))
	f.poise = float(role.get("poise", 0.0))


## 사람(김신 · 피우진): 등급 · 기술은 castle_common 진행(11장 앞까지), 칼날 쳐내기는 characters.json can_parry
static func _hero(id: String, T):
	var c := Addendum.character(id)
	var pr: Array = Common.progress(id, Common.events_until(Common.stage_of(T.EVENT)))
	var f = Fighter.new(str(c["name"]), 0)
	f.char_id = id
	f.rank = pr[0]
	var st := Addendum.stats_at(id, T.PERIOD)
	_base(f, T.ROLES[id], st)
	f.moveset = T.ROLES[id]["moveset"]
	f.can_parry = bool(c.get("can_parry", false))
	f.skills = Skills.entries(pr[1], f.rank)      # castle_common 진행 기술(동작이 있는 것 — 묶음 B 기술은 c3ed030 부터 공통)
	f.oneshot_immune = true
	f.gauge_max = Common.bars_for(f.rank) * Common.bar_points()
	f.gauge_rate = Common.gauge_rate(f.rank, st.get("기술"))
	f.gauge = minf(f.gauge_max, (Skills.KIM_START_BARS if id == Skills.HERO_ID else Skills.HERO_START_BARS) * Common.bar_points())
	return f


## 아군 · 적 — 1층은 addendum(castle_common 이 먼저), 3층은 장 표 ROLES
static func _npc(d: Dictionary, id: String, team: int, pos: Vector2, extra := {}):
	var T = d["tbl"]
	var c := Addendum.character(id)
	var role: Dictionary = T.ROLES[id]
	var f = Fighter.new(str(c["name"]), team)
	f.char_id = id
	f.rank = Addendum.rank_at(id, T.PERIOD)
	_base(f, role, Addendum.stats_at(id, T.PERIOD))
	f.can_parry = bool(c.get("can_parry", false))
	f.pos = pos
	f.facing = Vector2(-1, 0) if team == 1 else Vector2(1, 0)
	if extra.get("leader", false):
		f.hp_max *= 1.25
		f.hp = f.hp_max
		d["look_of"][f] = "g4_leader"                 # 그림: 희끗한 크루컷의 중심 인물(058/039-045)
	# 방 표의 덧붙임(엑스트라 한 사람씩 다르게): look 외형 · ai 적 프로필 · name 화면 이름 · hp_k 체력 배율
	if extra.has("look"):
		d["look_of"][f] = str(extra["look"])
	if extra.has("name"):
		f.name = str(extra["name"])
	if extra.has("hp_k"):
		f.hp_max *= float(extra["hp_k"])
		f.hp = f.hp_max
	var i: int = d["enemies"].size() + d["allies"].size() + 1
	if team == 1:
		f.is_boss = true                              # 적 쪽: 공격 준비 동안 상대 쪽으로 몸을 오래 튼다 · 늦은 쳐내기 없음
		f.finisher_cap = float(role.get("finisher_cap", 0.0))
		f.phase2_at = float(role.get("phase2_at", 0.0))
		if role.has("yield_at"):
			d["yield"][f] = float(role["yield_at"])
			f.hp_floor = float(role["yield_at"])      # 길을 내주기 전에는 이 밑으로 안 내려간다
		elif role.has("hp_floor"):
			f.hp_floor = float(role["hp_floor"])      # 쓰러뜨릴 수 없는 적(따돌리기 방 — 2장 남궁혁)
		var g: float = Addendum.derive(Addendum.stats_at(id, T.PERIOD))["guard"]
		d["ais"][f] = EnemyAI.new(f, str(extra.get("ai", role["ai"])), _rng(int(d["seed"]) * 131 + int(d["room_i"]) * 17 + i), g)
		d["enemies"].append(f)
	else:
		f.moveset = role["moveset"]
		var sk: Array = []
		for sid in c.get("skills", []):
			var s := Addendum.skill(sid)
			var mv_name := str(Skills.MOVE_OF.get(sid, s.get("move", "")))   # 공통 기술(묶음 B 조작 인물 기술 — 1장 아군 서진태)은 MOVE_OF
			if mv_name != "":
				sk.append({"id": sid, "name": str(s["name"]), "move": mv_name, "cost": 1.0})
		f.skills = sk
		f.gauge_max = Common.bars_for(f.rank) * Common.bar_points()
		f.gauge_rate = Common.gauge_rate(f.rank, Addendum.stats_at(id, T.PERIOD).get("기술"))
		var b = Bot.new(f, null, _rng(int(d["seed"]) * 977 + i))
		b.generic_skills = true
		d["bots"][f] = b
		d["allies"].append(f)
	d["world"].add(f)
	return f


static func _line(d: Dictionary, key: String, secs := 2.6, delay := 0.0) -> void:
	var v = Lines.at("%s.rooms.%s.%s" % [d["tbl"].LINES, d["room"]["id"], key])
	if v is Array and v.size() >= 2:
		d["world"].events.append(["line", str(v[0]), str(v[1]), secs, delay])


static func _enter(d: Dictionary, i: int) -> void:
	var w = d["world"]
	var T = d["tbl"]
	var room: Dictionary = T.ROOMS[i]
	d["room_i"] = i
	d["room"] = room
	for f in d["enemies"] + d["allies"]:
		d["bots"].erase(f)
		d["ais"].erase(f)
		d["look_of"].erase(f)
	d["enemies"] = []
	d["allies"] = []
	d["yield"] = {}
	w.fighters = []
	w.pending = []
	w.hitstop = 0
	w.bounds = room["bounds"]
	d["cast"] = cast_of(T, room)
	if not d["cast"].has(int(d["ctrl"])):
		d["ctrl"] = d["cast"][0]
	var kit: Dictionary = room.get("kit", {})
	for j in d["cast"].size():
		var h = d["heroes"][d["cast"][j]]
		h.pos = room["heroes"][j]
		h.facing = Vector2(1, 0)
		h.vel = Vector2.ZERO
		h.posture = 0.0
		if h.alive():
			h.set_state("idle")
		var rk: String = str(kit.get(h.char_id, h.char_id))   # 방 표 kit: 이 방에서만 다른 동작 · 외형(2장 공사장 맨손 김신)
		h.moveset = T.ROLES[rk]["moveset"]
		if rk != h.char_id:
			d["look_of"][h] = str(T.ROLES[rk]["look"])
		else:
			d["look_of"].erase(h)
		w.add(h)
	for a in room["allies"]:
		_npc(d, a[0], 0, a[1])
	for e in room["enemies"]:
		_npc(d, e[0], 1, e[1], e[2] if e.size() > 2 else {})
	for e in d["enemies"]:
		e.oneshot_immune = e.char_id == str(room.get("boss", ""))     # 방의 보스는 등급 차 한 방을 안 받는다
	if i == 0 and int(d["crowd"]) > 0:
		for k in int(d["crowd"]):                    # 성능 점검: 경호원을 둥글게 더 세운다
			var a := TAU * k / float(d["crowd"])
			_npc(d, T.CROWD_ID, 1, Vector2(1.6 + 3.2 * cos(a), 2.6 * sin(a)))
	d["stage"] = "intro"
	d["t"] = 0
	d["fight_t"] = 0
	w.events.append(["room", i])
	var after := 0.0
	if i == 0:                                       # 장 첫 글 → 그 뒤에 첫 방 글(같은 순간이면 첫 글이 덮여 안 보인다)
		var st = Lines.at(T.LINES + ".start")
		w.events.append(["line", str(st["text"]), str(st["sub"]), 2.4, 0.0])
		after = 2.4
	_line(d, "enter", 3.0, after)
	_focus(d)


## 방에 나오는 조작 인물(장 표 HEROES 의 번호) — 방 표 cast(인물 id), 없으면 전부. heroes 자리(방 표)도 이 차례
static func cast_of(T, room: Dictionary) -> Array:
	var out: Array = []
	if room.has("cast"):
		for id in room["cast"]:
			out.append(T.HEROES.find(id))
	else:
		for k in T.HEROES.size():
			out.append(k)
	return out


## 교대할 수 있는 판인가(방에 조작 인물이 둘 이상) — 교대 버튼 · 짝 막대(main.gd)
static func can_swap(d: Dictionary) -> bool:
	return d.get("kind", "") == "stage" and d.get("cast", []).size() > 1


## 교대 차례의 다음 사람(짝 막대) — 교대가 없으면 null
static func partner(d: Dictionary):
	if not can_swap(d):
		return null
	var c: Array = d["cast"]
	return d["heroes"][c[(c.find(int(d["ctrl"])) + 1) % c.size()]]


## 따돌리기 방에서 남은 초(화면 글) — 따돌리기 방이 아니거나 싸움 중이 아니면 -1
static func escape_left(d: Dictionary) -> float:
	var es: Dictionary = d["room"].get("escape", {})
	if es.is_empty() or d["stage"] != "fight":
		return -1.0
	return maxf(0.0, float(es["secs"]) - float(d["fight_t"]) / 60.0)


## 한 프레임. human 이 null 이면 봇이 지금 사람도 움직인다(자동 플레이). human["swap"] 이면 교대
static func step(d: Dictionary, human = null) -> void:
	var w = d["world"]
	var T = d["tbl"]
	d["t"] += 1
	d["n"] += 1
	match str(d["stage"]):
		"intro":
			if d["t"] >= T.INTRO_T:
				d["stage"] = "end" if d["room"].get("end", false) else "fight"
				d["t"] = 0
				if d["stage"] == "end":
					_line(d, "end", 5.0)
				elif d["room"].has("escape"):
					_line(d, "guide", 3.5)
		"fight":
			d["fight_t"] += 1
		"clear":
			if d["t"] >= T.CLEAR_T and d["room_i"] + 1 < T.ROOMS.size():
				_enter(d, d["room_i"] + 1)
				return
		"end":
			if d["t"] >= T.END_T and w.over == "":
				w.over = "win"
	if human != null and human.get("swap", false):
		swap(d)
	_targets(d)
	_intents(d, human)
	w.tick()
	_after(d)


## 교대: 다른 사람이 살아 있으면 조작을 넘긴다(지금 사람이 기술 · 맞음 중이어도 된다 — 넘겨받은 쪽은 봇이 이어 받는다).
## 조작하는 사람이 1명인 장(0 · 1장 김신)은 교대가 없다
static func swap(d: Dictionary) -> bool:
	var c: Array = d["cast"]
	if c.size() < 2:
		return false
	var other: int = c[(c.find(int(d["ctrl"])) + 1) % c.size()]
	if not d["heroes"][other].alive():
		return false
	d["ctrl"] = other
	d["world"].events.append(["swap", d["heroes"][other]])
	_focus(d)
	return true


static func _foes_of(d: Dictionary, f) -> Array:
	var out: Array = []
	for o in d["world"].fighters:
		if o.team != f.team and o.alive() and not o.inert:
			out.append(o)
	return out


## 저마다 가장 가까운 상대를 겨눈다(같은 거리면 먼저 넣은 쪽 — 결정적)
static func _targets(d: Dictionary) -> void:
	for f in d["world"].fighters:
		if not f.alive():
			continue
		var best = null
		var bd := INF
		for o in _foes_of(d, f):
			var dd: float = f.dist_to(o)
			if dd < bd:
				bd = dd
				best = o
		f.set_target(best)


static func _intents(d: Dictionary, human) -> void:
	var w = d["world"]
	var frozen: bool = w.hitstop > 0 or w.over != ""
	var fighting: bool = d["stage"] == "fight"
	var attackers := 0
	for e in d["enemies"]:
		if d["ais"][e].busy():
			attackers += 1
	for e in d["enemies"]:
		if frozen or not fighting:
			e.intent = {}
			continue
		var ai = d["ais"][e]
		var was: bool = ai.busy()
		e.intent = ai.decide(e.target(), was or attackers < int(d["tbl"].MAX_ATTACKERS))
		if not was and ai.busy():
			attackers += 1
	for k in d["heroes"].size():
		var h = d["heroes"][k]
		if k == int(d["ctrl"]) and human != null:
			h.intent = human
		elif frozen or not h.alive() or not d["cast"].has(k):
			h.intent = {}
		else:
			h.intent = _bot_intent(d, h, fighting)
	for a in d["allies"]:
		a.intent = {} if frozen else _bot_intent(d, a, fighting)


## 봇: 싸울 상대가 있으면 bot.gd, 없으면(들어서는 중 · 방을 넘음) 조작하는 사람 곁으로.
## 따돌리기 방의 조작 인물은 예고에만 답하고(쳐내기 · 구르기) 나머지는 출구로 달린다
static func _bot_intent(d: Dictionary, me, fighting: bool) -> Dictionary:
	var es: Dictionary = d["room"].get("escape", {})
	if fighting and not es.is_empty() and d["heroes"].has(me):
		var it: Dictionary = {"face": me.facing}
		if me.target() != null:
			var bb = d["bots"][me]
			bb.foe = me.target()
			bb.foes = _foes_of(d, me)
			it = bb.decide()
		if not (it.get("parry", false) or it.get("parry_held", false) or it.get("roll", false)):
			var to: Vector2 = (es["exit"] as Rect2).get_center() - me.pos
			it = {"move": to.normalized(), "face": to.normalized()}
		return it
	var tg = me.target()
	if not fighting or tg == null:
		var lead = d["heroes"][d["ctrl"]]
		if lead == me or not lead.alive():
			return {}
		var gap: float = me.dist_to(lead)
		return {"move": me.dir_to(lead) * 0.7 if gap > 1.6 else Vector2.ZERO, "face": me.facing}
	var b = d["bots"][me]
	b.foe = tg
	b.foes = _foes_of(d, me)
	return b.decide()


static func _after(d: Dictionary) -> void:
	var w = d["world"]
	for e in w.events.duplicate():
		if e[0] == "phase2" and d["enemies"].has(e[1]):
			_line(d, "phase2", 2.6)
	for e in d["yield"].keys():
		if e.alive() and not e.inert and e.hp <= e.hp_max * float(d["yield"][e]) + 0.001:
			e.inert = true                              # 고집에 밀려 길을 내준다 — 칼을 거두고 비켜선다(062)
			e.set_state("idle")
			e.intent = {}
			w.events.append(["yield", e])
			_line(d, "yield", 3.2)
	var lead = d["heroes"][d["ctrl"]]
	if not lead.alive():
		if swap(d):
			w.events.append(["line", str(Lines.at(d["tbl"].LINES + ".down")), "", 1.6])
	var alive := 0
	for k in d["cast"]:
		if d["heroes"][k].alive():
			alive += 1
	if alive == 0 and w.over == "":
		w.over = "lose"
		w.hitstop = maxi(w.hitstop, 30)
	if d["stage"] == "fight" and w.over == "":
		var left := 0
		for e in d["enemies"]:
			if e.alive() and not e.inert:
				left += 1
		var es: Dictionary = d["room"].get("escape", {})
		var got_away := false
		if not es.is_empty() and left > 0:
			got_away = lead.alive() and (es["exit"] as Rect2).has_point(lead.pos)
			if not got_away and float(d["fight_t"]) >= float(es["secs"]) * 60.0:
				w.over = "lose"                             # 시간 안에 못 빠져나갔다
				var tl = Lines.at("%s.rooms.%s.timeout" % [d["tbl"].LINES, d["room"]["id"]])
				if tl is Array and tl.size() >= 2:
					d["lose_line"] = [str(tl[0]), str(tl[1])]
				_focus(d)
				return
		if left == 0 or got_away:
			d["stage"] = "clear"
			d["t"] = 0
			d["cleared"] += 1
			d["times"][d["room"]["id"]] = d["fight_t"]
			for k in d["cast"]:
				var h = d["heroes"][k]
				if h.alive():
					h.hp = minf(h.hp_max, h.hp + h.hp_max * float(d["tbl"].HEAL_ON_CLEAR))
			if got_away:
				for e in d["enemies"]:
					e.inert = true                          # 따돌렸다 — 남은 적은 멈춘다(방을 넘는 동안 치지 않는다)
					e.intent = {}
				w.events.append(["escape", lead])
				_line(d, "escape", 2.8)
			else:
				_line(d, "clear", 2.4)
	_focus(d)


## 화면에 보일 두 사람: hero = 조작하는 사람, boss = 방의 큰 적(살아 있으면) → 아니면 조작하는 사람에게 가장 가까운 적
static func _focus(d: Dictionary) -> void:
	var h = d["heroes"][d["ctrl"]]
	d["hero"] = h
	var want := str(d["room"].get("boss", ""))
	var best = null
	var bd := INF
	for e in d["enemies"]:
		if not e.alive() or e.inert:
			continue
		var dd: float = h.dist_to(e) - (100.0 if e.char_id == want else 0.0)
		if dd < bd:
			bd = dd
			best = e
	d["boss"] = best


## 그림 없이 끝까지(또는 frames 까지) — 시험 · 자동 점검
static func simulate(seed_value: int, frames: int, opts := {}) -> Dictionary:
	var d := make(seed_value, opts)
	var w = d["world"]
	var n := 0
	while n < frames and w.over == "":
		step(d)
		w.events.clear()
		n += 1
	return summary(d, n)


static func summary(d: Dictionary, n: int) -> Dictionary:
	var w = d["world"]
	var hp: Array = []
	for h in d["heroes"]:
		hp.append(snappedf(h.hp, 0.01))
	return {"frames": n, "over": w.over, "room": str(d["room"]["id"]), "cleared": d["cleared"], "heroes_hp": hp,
		"times": d["times"].duplicate(), "stats": w.stats.duplicate()}
