extends RefCounted
## 방을 차례로 지나는 여러 사람 판(장 표 하나 = 장 하나 — 0장 블라디보스토크(src/data/prologue.gd) · 1장 회암시(hoeam.gd) ·
## 2장 하성 본사(haseong.gd — 방마다 김신 / 서진태 한 사람) · 11장 호텔 캐슬(hotel.gd — 층을 지나며 김신 · 피우진(교대)이 적 여럿과 싸운다)).
## 조작하는 사람은 장 표 HEROES 중 방 표 cast(없으면 전부) — 방에 1명이면 교대 없음. 순수 로직(노드 없음, 60프레임 고정,
## 같은 시드면 같은 결과) — 게임(main.gd) · 시험 · 자동 플레이가 같은 것을 쓴다. 결투(duel.gd)와 같은 모양의 사전을 돌려준다:
## world · hero(지금 조작하는 사람) · boss(화면 위 큰 막대에 보일 적, 없으면 null) + kind "stage" · heroes · enemies · allies · standing.
## 방 · 역할 · 시점은 장 표(src/data/campaign.gd 가 장 id 로 고른다 — ch0 prologue · ch1 hoeam · ch11 hotel), 1층(등급 · 능력치 · 기술)은 castle_common → 없으면 src/data/addendum.gd(3D 덧붙임).
## 판 끝: 마지막 방(end)에 닿으면 win, 방에 나온 조작하는 사람이 다 쓰러지면 lose(world.over). 신겐은 체력 yield_at 에서 길을 내준다(062).
## 따돌리기 방(방 표 escape — 2장 남궁혁 030/013-024): secs 안에 exit 안에 들어서면 적이 남아도 방을 넘고, 못 들어서면 진다
## (버티기로는 안 넘는다 — rc.2 폰 2026-11-07 사용자). 싸움이 시작될 때 안내 글(방 대사 guide), 시간 초과 패배 글은 d["lose_line"].
## 신호(world.events 에 더함): ["room", 방 번호] · ["line", 제목, 작은 글, 초, (늦춤 초)] · ["swap", 새로 조작하는 사람] · ["yield", 적] ·
##   ["escape", 사람] · ["spawn", 새로 선 사람] · ["recruit", 우리 편이 된 사람] · ["learn", 조작 인물, [새 기술 이름]] ·
##   ["leave", 빠진 조작 인물] · ["cast"] · ["stage_view"](무대를 다시 그림) · ["fade", 제목, 작은 글, 초]
##
## ── 장 표 머리 칸 ─────────────────────────────────────────────────────────────────────────────────────────────
## EVENT · PERIOD · HEROES · LINES · CROWD_ID · ROLES · ROOMS · INTRO_T · CLEAR_T · END_T · HEAL_ON_CLEAR · MAX_ATTACKERS(꼭) ·
## NPCS(그 장 시점 등급 · 능력치 · 이름) · HERO_RANKS {id: 등급}(조작 인물 등급을 장 전체에서 덮음 — 기술 수도 다시)
##
## ── 방 표 칸(ROOMS 한 줄 — 아래 '규칙 칸'은 모두 없어도 된다. 없으면 예전과 똑같이 돈다) ──────────────────────────────
## 기본: id · theme · bounds(Rect2 — 넓게 쓰면 긴 맵: 카메라가 앞장선 사람을 따른다) · cast · heroes(자리) · allies [[id, 자리]] ·
##   enemies [[id, 자리, {덧붙임}]] · boss · end · kit · talk · escape
##   덧붙임(enemies · spawn · standing 의 셋째 · 넷째 칸): role · look · ai · name · hp_k · leader · tag(같은 인물 여럿을 가를 이름 —
##   when "down:<tag>" · recruit · protect 가 id 대신 tag 로도 찾는다) · passive(적 — 치지도 막지도 않고 맞기만, 11장 천일도)
## 규칙 칸:
##   "triggers": [{when, (requires), ...do}] — 싸움 중 매 프레임 차례로 보고, 조건이 맞으면 한 번만 터진다(같은 프레임에 여럿도). 결정적.
##     requires: [번호, ..]      그 triggers 가 먼저 터져야 이것을 본다(12장 그롤라전 — 마준영 투입 뒤에야 피우진 투입)
##     when:  "down:<id>"        그 사람(char_id 또는 tag — 여럿이면 모두)이 쓰러지거나 물러남(inert). 서 있는 사람(standing)은 안 센다.
##                               조작 인물도 된다 — 이 trigger 가 남은 동안은 그 사람이 쓰러져 조작 인물이 없어도 지지 않는다
##                               (12장 마학영전: {"when": "down:jintae", "cast": ["kimshin"]})
##            "hp:<id>:<비율>"   그 사람(적 · 아군 · 조작 인물) 체력이 최대의 비율 이하(hp_floor · yield_at 와 같은 값이면 닿는 순간)
##            "time:<초>"        방 싸움 시간(대사 hold 동안은 멈춘다)
##            "x:<m>"            앞장선 조작 인물 x 가 m 이상(긴 복도 — 끝에서 다음 무리)
##            "after:<번호>:<초>" triggers 의 그 번호(0부터)가 터진 뒤 초
##            "clear"            남은 적이 모두 쓰러짐(방을 넘기 직전 — 넘기 대신 이것부터. spawn 이 없으면 대사 뒤에 넘는다)
##            "survive"          방 survive 초를 버팀
##     do(한 줄에 여럿):
##            "spawn": [[id, Vector2, {덧붙임}], ..]       적 등장(장 표 ROLES 에 그 id 가 있어야)
##            "spawn_allies": [[id, Vector2, {덧붙임}], ..] 아군 등장(봇 — ROLES 에 moveset). 자리가 bounds 밖이면 가장자리에
##                                        선다(가장자리에 세우면 걸어 들어오는 것처럼)
##            "boss": id                  화면 위 큰 막대를 이 사람으로(등급 차 한 방도 안 받는다)
##            "recruit": id               쓰러진 · 물러난 그 적을 우리 편으로(체력 RECRUIT_HP 까지 회복 · 팀 0 · ROLES 에 moveset 이 있으면
##                                        아군 봇, 없으면 제 AI 그대로 적을 친다)
##            "say": [[제목, 작은 글, (refs)], ..] 또는 "키"(lines.json <LINES>.rooms.<방>.<키> 의 줄 목록) — SAY_SECS 마다 하나씩,
##                                        앞 대사가 남았으면 그 뒤에 잇는다. 대사 중 싸움은 계속
##            "hold": true                이 대사가 끝날 때까지 모두 멈춘다(사람 입력도 — 연출). 싸움 시간도 멈춘다
##            "calm": true                모든 적 · 아군이 싸움을 멈춘다(inert — 싸움이 파함. 적이 다 멈추면 대사 뒤에 방을 넘는다)
##            "inert": [id, ..]           그 사람만 멈춘다
##            "clear": true               방을 깬 것으로(say 가 있으면 대사가 끝난 뒤)
##            "escape": {"exit": Rect2, "secs": n}  지금부터 n 초 안에 출구로(따돌리기와 같은 판정 · 남은 초 표시 · 못 닿으면 짐)
##            "cast": [id, ..] (+ "cast_at": [Vector2, ..])  조작 인물 묶음을 바꾼다 — 빠지는 사람은 퇴장(쓰러진 사람은 그 자리),
##                                        들어오는 사람은 cast_at 자리(없으면 왼쪽 가장자리)에서(12장 신겐 2차전 피우진 → 김신)
##            "bounds": Rect2 · "theme": 무대  싸움 중 맵을 넓히거나 무대를 바꾼다(main.gd 가 무대 그림을 다시 — 12장 구스타프전)
##            "learn": "<진행 사건 id>"   조작 인물들의 등급 · 기술을 그 사건까지(포함)의 castle_common 진행으로 다시(beat:richeon →
##                                        김신 재앙 · 촌경 · 리천식 삼연타). 새 기술 이름을 알림 글로
##   "survive": 초   그 시간을 버티면 방을 깬다. triggers 에 escape 가 있으면 깨지 않고 그 escape 를 마쳐야 깬다
##                   (예: {"when": "survive", "escape": {...}} — 버틴 뒤 빠져나가기)
##   "limit": 초     그 안에 방을 못 깨면 진다(패배 글 rooms.<방>.timeout, 없으면 lines.json stage.timeout)
##   "protect": [id, ..]  그중 누가 쓰러지면 진다(조작 인물 · 아군 — 패배 글 rooms.<방>.protect, 없으면 stage.protect)
##   "standing": [[id, Vector2, 팀, {덧붙임}], ..]  싸우지 않고 서 있는 사람(대화 장면 — 방 가운데를 보고, 맞지도 치지도 않는다)
##   "auto": true    컴퓨터끼리 싸우는 방(연출) — 조작 인물도 봇이 움직인다(사람 입력은 교대만). 화면 아래 '관전'
##   "hp_start": {id: 비율}  조작 인물이 이 체력으로 방을 시작(12장 마학영전 서진태 0.3)
##   "ally_heroes": [id 또는 [id, Vector2], ..]  cast 에 없는 조작 인물을 아군 봇으로 세운다(12장 최민욱 잡기 김신 — 쓰러져도 지지
##                   않는다. 지키려면 protect 에)
##   "fade": [제목, 작은 글] 또는 "키"  방을 깨면(끝 방 end 는 들어서면) 화면을 어둡게 하며 글(11장 '만인지상의 자리에 오르다') — FADE_T 머문다
##   "ranks": {id: 등급}  이 방에서 그 조작 인물 · 아군 · 적의 등급을 덮는다(기술 수도 다시 — 8장 교류회 김신 톱 · 류지학 내성 중위)
## 남은 초(escape · survive · limit)와 관전은 timers(d) → main.gd 가 화면 아래 한 줄로.
## 방을 넘지 않는 때: 대사(say)가 남음 · 앞으로 터질 spawn(time · after · x · survive 조건)이 남음 · 대화 방 talk 시간.

const Fighter = preload("res://src/combat/fighter.gd")
const World = preload("res://src/combat/world.gd")
const EnemyAI = preload("res://src/combat/enemy_ai.gd")
const Bot = preload("res://src/combat/bot.gd")
const Skills = preload("res://src/data/skills.gd")
const Kit = preload("res://src/data/skill_kit.gd")
const Tech = preload("res://src/data/tech_moves.gd")
const Common = preload("res://src/data/common.gd")
const Addendum = preload("res://src/data/addendum.gd")
const Campaign = preload("res://src/data/campaign.gd")
const Lines = preload("res://src/data/lines.gd")
const Difficulty = preload("res://src/data/difficulty.gd")

const RECRUIT_HP := 0.5          # recruit: 우리 편이 될 때 체력을 최대의 이만큼까지(3층 · 잠정)
const PENDING_SPAWN := ["time", "after", "x", "survive"]   # 앞으로 반드시(또는 걸어가면) 터질 조건 — spawn 이 남았으면 방을 넘지 않는다


## opts: chapter(장 id — 기본 ch11) · room(시작 방 번호 — 시험용) · crowd(첫 방에 엑스트라를 이만큼 더 — 성능 점검 '적 30명') ·
##   difficulty(난이도 — 적에게만 배율, src/data/difficulty.gd · 기본 보통) · table(장 표를 직접 — 시험의 작은 예시 표, 사전도 된다)
static func make(seed_value: int, opts := {}) -> Dictionary:
	var w = World.new()
	w.end_on_ko = false
	var ch := str(opts.get("chapter", "ch11"))
	var T = opts["table"] if opts.has("table") else Campaign.table(ch)
	var d := {"kind": "stage", "chapter": ch, "tbl": T, "world": w, "heroes": [], "ctrl": 0, "room_i": -1, "room": {}, "enemies": [], "allies": [],
		"ais": {}, "bots": {}, "yield": {}, "seed": seed_value, "stage": "intro", "t": 0, "fight_t": 0, "cleared": 0,
		"times": {}, "look_of": {}, "hero": null, "boss": null, "crowd": int(opts.get("crowd", 0)), "n": 0, "cast": [],
		"difficulty": Difficulty.valid(opts.get("difficulty", Difficulty.DEFAULT)), "know": {}, "base_rank": {}, "standing": []}
	for id in T.HEROES:
		var h = _hero(d, id)
		d["bots"][h] = Bot.new(h, null, _rng(seed_value * 7919 + d["heroes"].size() + 1))
		d["heroes"].append(h)
	_enter(d, int(opts.get("room", 0)))
	return d


static func _rng(s: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = s
	return r


## 장 표의 고를 수 있는 칸(NPCS · HERO_RANKS) — 스크립트 장 표 · 사전 장 표(시험) 모두
static func tconst(T, key: String, dflt = null):
	if T is Dictionary:
		return T.get(key, dflt)
	return T.get_script_constant_map().get(key, dflt)


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


## 사람(김신 · 피우진): 등급 · 기술은 castle_common 진행(장 표 EVENT 앞까지), 칼날 쳐내기는 characters.json can_parry.
## 장 표 HERO_RANKS 가 등급을 덮는다
static func _hero(d: Dictionary, id: String):
	var T = d["tbl"]
	var c := Addendum.character(id)
	var pr: Array = [str(c["rank"]), []]               # castle_common 에 등급이 없는 인물(표영 — 3장)은 진행 없이 1층 대체 등급
	if _has_progress(id):
		pr = Common.progress(id, Common.events_until(Common.stage_of(T.EVENT)))
	var f = Fighter.new(str(c["name"]), 0)
	f.char_id = id
	_base(f, T.ROLES[id], Addendum.stats_at(id, T.PERIOD))
	f.moveset = T.ROLES[id]["moveset"]
	f.can_parry = bool(c.get("can_parry", false))
	d["know"][f] = pr[1]
	d["base_rank"][f] = str(tconst(T, "HERO_RANKS", {}).get(id, pr[0]))
	_set_rank(d, f, d["base_rank"][f])
	f.oneshot_immune = true
	f.gauge = minf(f.gauge_max, (Skills.KIM_START_BARS if id == Skills.HERO_ID else Skills.HERO_START_BARS) * Common.bar_points())
	return f


static func _has_progress(id: String) -> bool:
	# castle_common 에 없는 조작 인물(7장 관전 방 임무열 · 히데, 9장 여민수 · 크로트, 12장 현석 · 쿄지)은 진행 없이 1층 대체 등급 — 묻기 전에 걸러 오류 글을 안 낸다
	if not Addendum._has_common(id):
		return false
	return Common.character(id).has("rank") and Common.character(id).get("rank") != null


## 조작 인물의 등급을 바꾸고 기술 묶음 · 게이지를 그 등급으로 다시(진행 기술 d.know + 1층 덧붙임 기술 → skill_kit 등급 수까지)
static func _set_rank(d: Dictionary, f, rank: String) -> void:
	var c := Addendum.character(f.char_id)
	f.rank = rank
	var known := Skills.entries(d["know"][f], rank)     # castle_common 진행 기술(동작이 있는 것)
	for e in _known(c):                                  # + 1층 기술 중 3D 덧붙임 동작이 있는 것(이슬 · 표영처럼 진행이 없는 조작 인물)
		if not known.any(func(k): return k["id"] == e["id"]):
			known.append(e)
	f.skills = Kit.hero_kit(f.char_id, rank, known)      # + 원작 기술 — 등급 수까지(skill_kit)
	f.skill_idx = clampi(f.skill_idx, 0, maxi(0, f.skills.size() - 1))
	f.gauge_max = Common.bars_for(rank) * Common.bar_points()
	f.gauge_rate = Common.gauge_rate(rank, Addendum.stats_at(f.char_id, d["tbl"].PERIOD).get("기술"))
	f.gauge = minf(f.gauge, f.gauge_max)
	if d.has("skills_all"):
		d["skills_all"].erase(f)                         # 맨손 방 거르기(_bare_skills)가 새 묶음에서 다시


## 아군 · 적 — 1층은 addendum(castle_common 이 먼저), 3층은 장 표 ROLES
static func _npc(d: Dictionary, id: String, team: int, pos: Vector2, extra := {}):
	var T = d["tbl"]
	var c := Addendum.character(id)
	var role: Dictionary = T.ROLES[str(extra.get("role", id))]   # 방 표 덧붙임 role: 같은 인물이 그 장에서 조작 인물도 될 때 적 역할(13장 피우진)
	var over: Dictionary = npc_over(T, id)
	var f = Fighter.new(str(over.get("name", c["name"])), team)
	f.char_id = id
	f.rank = str(over.get("rank", Addendum.rank_at(id, T.PERIOD)))
	f.rank = str(d["room"].get("ranks", {}).get(id, f.rank))     # 방 표 ranks(8장 교류회 류지학 내성 중위)
	var st: Dictionary = over.get("stats", Addendum.stats_at(id, T.PERIOD))
	_base(f, role, st)
	f.can_parry = bool(c.get("can_parry", false))
	f.pos = pos
	f.facing = Vector2(-1, 0) if team == 1 else Vector2(1, 0)
	if extra.get("leader", false):
		f.hp_max *= 1.25
		f.hp = f.hp_max
		d["look_of"][f] = "g4_leader"                 # 그림: 희끗한 크루컷의 중심 인물(058/039-045)
	# 방 표의 덧붙임(엑스트라 한 사람씩 다르게): role 역할 · look 외형 · ai 적 프로필 · name 화면 이름 · hp_k 체력 배율 · tag 찾는 이름
	if extra.has("look"):
		d["look_of"][f] = str(extra["look"])
	if extra.has("name"):
		f.name = str(extra["name"])
	if extra.has("hp_k"):
		f.hp_max *= float(extra["hp_k"])
		f.hp = f.hp_max
	if extra.has("tag"):
		d["tag_of"][f] = str(extra["tag"])
	if team == 1 and extra.get("passive", false):
		d["passive"][f] = true                         # 맞기만 하는 적(11장 천일도) — 치지도 막지도 않는다
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
		var g: float = Addendum.derive(st)["guard"]
		var ai := str(extra.get("ai", role.get("ai", "thug")))
		d["ais"][f] = EnemyAI.new(f, ai, _rng(int(d["seed"]) * 131 + int(d["room_i"]) * 17 + i), g)
		if not _extra(c):
			d["ais"][f].skills = Kit.npc_kit(id, f.rank, ai, _known(c), EnemyAI.moves_of(ai))   # 이름 있는 적: 등급 수만큼 기술(가끔 이름을 띄우며 쓴다 — enemy_ai SKILL_P)
		Difficulty.apply_foe(f, d["ais"][f], d.get("difficulty", Difficulty.DEFAULT))
		d["enemies"].append(f)
	else:
		f.moveset = role.get("moveset", {})
		_ally_kit(f, role, st, c)
		var b = Bot.new(f, null, _rng(int(d["seed"]) * 977 + i))
		b.generic_skills = true
		d["bots"][f] = b
		d["allies"].append(f)
	d["world"].add(f)
	return f


static func _ally_kit(f, role: Dictionary, st: Dictionary, c: Dictionary) -> void:
	f.skills = Kit.npc_kit(f.char_id, f.rank, str(role.get("ai", "")), _known(c)) if not _extra(c) else _known(c)
	f.gauge_max = Common.bars_for(f.rank) * Common.bar_points()
	f.gauge_rate = Common.gauge_rate(f.rank, st.get("기술"))


## 1층 기술 중 이 판 동작이 있는 것 — 공통 기술(묶음 B 조작 인물 기술 — 1장 아군 서진태)은 MOVE_OF, 3D 덧붙임은 addendum move
## 맨손 방(외형 *_bare — 0 · 1장 김신 · 2장 공사장 · 4장 케이지 · 13장 주먹 승부)에서는 무기 기술(tech_moves WEAPON — 칼 · 총 ·
## 소품)을 빼고, 다른 방에서는 다시 모두 쓴다(사용자 2026-11-10 "기술에 따른 행동을 다 구체화")
static func _bare_skills(d: Dictionary, h, bare: bool) -> void:
	if not d.has("skills_all"):
		d["skills_all"] = {}
	if not d["skills_all"].has(h):
		d["skills_all"][h] = h.skills
	var all: Array = d["skills_all"][h]
	h.skills = all.filter(func(e): return not Tech.WEAPON.has(str(e["move"]))) if bare else all
	h.skill_idx = clampi(h.skill_idx, 0, maxi(0, h.skills.size() - 1))


## 이 방에서 그 조작 인물이 맨손인가(방 표 kit 의 외형이 *_bare)
static func _room_bare(d: Dictionary, h) -> bool:
	var T = d["tbl"]
	var rk: String = str(d["room"].get("kit", {}).get(h.char_id, h.char_id))
	return str(T.ROLES[rk].get("look", T.ROLES[h.char_id].get("look", ""))).ends_with("_bare")


static func _known(c: Dictionary) -> Array:
	var sk: Array = []
	for sid in c.get("skills", []):
		var s := Addendum.skill(sid)
		var mv_name := str(Skills.MOVE_OF.get(sid, s.get("move", "")))
		if mv_name != "":
			sk.append({"id": sid, "name": str(s["name"]), "move": mv_name, "cost": 1.0})
	return sk


## 이름 없는 무리(3D 덧붙임 엑스트라 — 경호원 · 조직원)는 기술 묶음이 없다
static func _extra(c: Dictionary) -> bool:
	return str(c.get("src", "")).contains("엑스트라")


## 장 표 NPCS(3 ~ 13장 — 그 장 시점의 등급 · 능력치 · 화면 이름, 3D 덧붙임)가 1층을 덮는다. 칸이 없는 장 표는 빈 표
static func npc_over(T, id: String) -> Dictionary:
	var m: Dictionary = tconst(T, "NPCS", {})
	return m.get(id, {})


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
	for f in d["enemies"] + d["allies"] + d["standing"]:
		d["bots"].erase(f)
		d["ais"].erase(f)
		d["look_of"].erase(f)
	d["enemies"] = []
	d["allies"] = []
	d["standing"] = []
	d["yield"] = {}
	d["tag_of"] = {}
	d["fired"] = {}                                  # 터진 triggers 번호 → 그때 싸움 시간
	d["boss_id"] = str(room.get("boss", ""))
	d["esc"] = {}
	if room.has("escape"):
		d["esc"] = {"exit": room["escape"]["exit"], "secs": float(room["escape"]["secs"]), "t0": 0, "room": true}
	d["say_until"] = 0
	d["hold_until"] = 0
	d["clear_at"] = -1
	d["passive"] = {}
	d["ally_heroes"] = []
	d["theme"] = str(room.get("theme", ""))
	w.fighters = []
	w.pending = []
	w.hitstop = 0
	w.bounds = room["bounds"]
	d["cast"] = cast_of(T, room)
	if not d["cast"].has(int(d["ctrl"])):
		d["ctrl"] = d["cast"][0]
	for j in d["cast"].size():
		var h = d["heroes"][d["cast"][j]]
		_place_hero(d, h, room["heroes"][j])
		if room.get("hp_start", {}).has(h.char_id) and h.alive():
			h.hp = h.hp_max * float(room["hp_start"][h.char_id])     # 방 표 hp_start(12장 마학영전 서진태 30%)
	for a in room.get("ally_heroes", []):                # 조작하지 않는 조작 인물 — 아군 봇(12장 최민욱 잡기 김신)
		var aid := str(a[0] if a is Array else a)
		var h = d["heroes"][T.HEROES.find(aid)]
		if d["cast"].has(T.HEROES.find(aid)):
			continue
		var b: Rect2 = room["bounds"]
		_place_hero(d, h, a[1] if a is Array else Vector2(b.position.x + 0.8, b.get_center().y))
		d["ally_heroes"].append(h)
	for a in room["allies"]:
		_npc(d, a[0], 0, a[1], a[2] if a.size() > 2 else {})
	for e in room["enemies"]:
		_npc(d, e[0], 1, e[1], e[2] if e.size() > 2 else {})
	for e in d["enemies"]:
		e.oneshot_immune = e.char_id == d["boss_id"]     # 방의 보스는 등급 차 한 방을 안 받는다
	for s in room.get("standing", []):
		_stand(d, _npc(d, s[0], int(s[2]), s[1], s[3] if s.size() > 3 else {}))
	if i == 0 and int(d["crowd"]) > 0:
		for k in int(d["crowd"]):                    # 성능 점검: 경호원을 둥글게 더 세운다
			var a := TAU * k / float(d["crowd"])
			_npc(d, T.CROWD_ID, 1, Vector2(1.6 + 3.2 * cos(a), 2.6 * sin(a)))
	d["stage"] = "intro"
	d["t"] = 0
	d["fight_t"] = 0
	w.events.append(["room", i])
	var after := 0.0
	var st = Lines.at(str(T.LINES) + ".start")
	if i == 0 and st is Dictionary:                  # 장 첫 글 → 그 뒤에 첫 방 글(같은 순간이면 첫 글이 덮여 안 보인다)
		w.events.append(["line", str(st["text"]), str(st["sub"]), 2.4, 0.0])
		after = 2.4
	_line(d, "enter", 3.0, after)
	_focus(d)


## 조작 인물을 방에 세운다(자리 · 상태 · 방 표 kit 동작 · 외형 · ranks 등급 · 맨손 기술)
static func _place_hero(d: Dictionary, h, pos: Vector2) -> void:
	var T = d["tbl"]
	var room: Dictionary = d["room"]
	h.pos = pos
	h.facing = Vector2(1, 0)
	h.vel = Vector2.ZERO
	h.posture = 0.0
	if h.alive():
		h.set_state("idle")
	var rk: String = str(room.get("kit", {}).get(h.char_id, h.char_id))   # 방 표 kit: 이 방에서만 다른 동작 · 외형(2장 공사장 맨손 김신)
	h.moveset = T.ROLES[rk]["moveset"]
	if rk != h.char_id:
		d["look_of"][h] = str(T.ROLES[rk]["look"])
	else:
		d["look_of"].erase(h)
	var want := str(room.get("ranks", {}).get(h.char_id, d["base_rank"][h]))   # 방 표 ranks(8장 교류회 김신 톱)
	if h.rank != want:
		_set_rank(d, h, want)
	_bare_skills(d, h, _room_bare(d, h))
	d["world"].add(h)


## 서 있는 사람(방 표 standing): 판 · AI 없이 방 가운데를 보고 선다(inert — 치지도 맞지도 않는다)
static func _stand(d: Dictionary, f) -> void:
	d["enemies"].erase(f)
	d["allies"].erase(f)
	d["ais"].erase(f)
	d["bots"].erase(f)
	d["yield"].erase(f)
	f.inert = true
	f.facing = _to_center(d, f)
	d["standing"].append(f)


static func _to_center(d: Dictionary, f) -> Vector2:
	var to: Vector2 = (d["world"].bounds as Rect2).get_center() - f.pos
	return to.normalized() if to.length() > 0.01 else f.facing


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


## 따돌리기(방 표 escape · triggers escape)의 남은 초(화면 글) — 없거나 싸움 중이 아니면 -1
static func escape_left(d: Dictionary) -> float:
	return float(timers(d)["escape"])


## 화면 아래 한 줄에 보일 남은 초(없으면 -1) · 관전 방 — main.gd 가 글로 바꾼다
static func timers(d: Dictionary) -> Dictionary:
	var out := {"escape": -1.0, "survive": -1.0, "limit": -1.0, "auto": bool(d["room"].get("auto", false))}
	if d["stage"] != "fight":
		return out
	var ft: float = float(d["fight_t"]) / 60.0
	var es: Dictionary = d["esc"]
	if not es.is_empty():
		out["escape"] = maxf(0.0, float(es["secs"]) - (float(d["fight_t"]) - float(es["t0"])) / 60.0)
	if d["room"].has("survive") and ft < float(d["room"]["survive"]):
		out["survive"] = float(d["room"]["survive"]) - ft
	if d["room"].has("limit"):
		out["limit"] = maxf(0.0, float(d["room"]["limit"]) - ft)
	return out


## 한 프레임. human 이 null 이면 봇이 지금 사람도 움직인다(자동 플레이). human["swap"] 이면 교대.
## 관전 방(auto)은 사람 입력에서 교대만 쓰고 봇이 움직인다
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
					if not _fade(d):
						_line(d, "end", 5.0)
				elif d["room"].has("talk"):
					_say(d)
				elif _ruled(d["room"]):
					_line(d, "guide", 3.5)
		"fight":
			if not _held(d):
				d["fight_t"] += 1
		"clear":
			var wait: int = maxi(int(T.CLEAR_T), FADE_T if d["room"].has("fade") else 0)
			if d["t"] >= wait and d["room_i"] + 1 < T.ROOMS.size():
				_enter(d, d["room_i"] + 1)
				return
		"end":
			if d["t"] >= T.END_T and w.over == "":
				w.over = "win"
	if human != null and human.get("swap", false):
		swap(d)
	if d["room"].get("auto", false):
		human = null
	_targets(d)
	_intents(d, human)
	w.tick()
	_after(d)


## 안내 글(guide)을 띄울 방 — 따돌리기 · 버티기 · 제한 시간 · 지키기 · 관전
static func _ruled(room: Dictionary) -> bool:
	for k in ["escape", "survive", "limit", "protect", "auto"]:
		if room.has(k):
			return true
	return false


## 대사 hold 중(모두 멈춤)
static func _held(d: Dictionary) -> bool:
	return int(d["n"]) < int(d.get("hold_until", 0))


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
	var frozen: bool = w.hitstop > 0 or w.over != "" or _held(d)
	var fighting: bool = d["stage"] == "fight"
	var attackers := 0
	for e in d["enemies"]:
		if d["ais"][e].busy():
			attackers += 1
	for e in d["enemies"]:
		if frozen or not fighting or d["passive"].has(e):
			e.intent = {}
			continue
		var ai = d["ais"][e]
		var was: bool = ai.busy()
		e.intent = ai.decide(e.target(), was or attackers < int(d["tbl"].MAX_ATTACKERS))
		if not was and ai.busy():
			attackers += 1
	for k in d["heroes"].size():
		var h = d["heroes"][k]
		if k == int(d["ctrl"]) and human != null and not _held(d):
			h.intent = human
		elif frozen or not h.alive() or not (d["cast"].has(k) or d["ally_heroes"].has(h)):
			h.intent = {}
		else:
			h.intent = _bot_intent(d, h, fighting)
	for a in d["allies"]:
		if frozen:
			a.intent = {}
		elif d["ais"].has(a):                            # 제 AI 그대로 우리 편이 된 사람(recruit — moveset 없는 역할)
			a.intent = d["ais"][a].decide(a.target(), true) if fighting else {}
		else:
			a.intent = _bot_intent(d, a, fighting)
	for s in d["standing"]:
		s.intent = {"face": _to_center(d, s)}


## 봇: 싸울 상대가 있으면 bot.gd, 없으면(들어서는 중 · 방을 넘음) 조작하는 사람 곁으로.
## 따돌리기 중의 조작 인물은 예고에만 답하고(쳐내기 · 구르기) 나머지는 출구로 달린다. 앞장선 사람이 봇이고 적이 없는데
## 걸어가야 터지는 trigger(x:)가 남았으면 오른쪽으로 걷는다(긴 복도 — 자동 플레이 · 관전)
static func _bot_intent(d: Dictionary, me, fighting: bool) -> Dictionary:
	var es: Dictionary = d["esc"]
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
		if lead == me:
			if fighting and _walk_goal(d) > me.pos.x:
				return {"move": Vector2(0.8, 0), "face": Vector2(1, 0)}
			return {}
		if not lead.alive():
			return {}
		var gap: float = me.dist_to(lead)
		return {"move": me.dir_to(lead) * 0.7 if gap > 1.6 else Vector2.ZERO, "face": me.facing}
	if d["passive"].has(tg):                         # 맞기만 하는 적(11장 천일도) — 거리 재며 맴돌지 않고 다가가 친다(bot.gd 는 1.5m 밖에서 맴돈다)
		var to: Vector2 = me.dir_to(tg)
		return {"move": to if me.dist_to(tg) > 1.0 else Vector2.ZERO, "face": to, "attack": me.dist_to(tg) <= 1.2 and me.can_act()}
	var b = d["bots"][me]
	b.foe = tg
	b.foes = _foes_of(d, me)
	return b.decide()


## 아직 안 터진 x: trigger 중 가장 가까운 x(없으면 -INF)
static func _walk_goal(d: Dictionary) -> float:
	var trs: Array = d["room"].get("triggers", [])
	var best := INF
	for k in trs.size():
		var p: PackedStringArray = str(trs[k]["when"]).split(":")
		if not d["fired"].has(k) and p[0] == "x":
			best = minf(best, float(p[1]))
	return best if best < INF else -INF


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
	if not d["heroes"][d["ctrl"]].alive():
		if swap(d):
			w.events.append(["line", str(Lines.at(str(d["tbl"].LINES) + ".down")), "", 1.6])
	var lead = d["heroes"][d["ctrl"]]
	var alive := 0
	for k in d["cast"]:
		if d["heroes"][k].alive():
			alive += 1
	if alive == 0 and w.over == "" and not _rescue(d):
		w.over = "lose"
		w.hitstop = maxi(w.hitstop, 30)
	if d["stage"] == "fight" and w.over == "":
		_triggers(d)
		if _lost(d):
			_focus(d)
			return
		var left := _left(d)
		var es: Dictionary = d["esc"]
		var got_away := false
		if not es.is_empty() and (left > 0 or not es.get("room", false)):
			got_away = lead.alive() and (es["exit"] as Rect2).has_point(lead.pos)
			if not got_away and float(d["fight_t"]) - float(es["t0"]) >= float(es["secs"]) * 60.0:
				_lose(d, "timeout")                         # 시간 안에 못 빠져나갔다
				_focus(d)
				return
		var won := got_away
		if not won and int(d["clear_at"]) >= 0 and int(d["n"]) >= int(d["clear_at"]):
			won = true                                      # trigger clear(대사가 끝난 뒤)
		if not won and d["room"].has("survive") and float(d["fight_t"]) >= float(d["room"]["survive"]) * 60.0 \
				and not _survive_escapes(d):
			won = true                                      # 버텼다
		if not won and left == 0 and not _waits(d):
			won = not (d["room"].has("talk") and float(d["fight_t"]) < talk_secs(d) * 60.0)   # 대화 방: 대사가 다 지나갈 때까지 머문다
		if won:
			_clear(d, got_away)
	_focus(d)


## 조작 인물이 모두 쓰러져도 아직 지지 않는다: 그 사람의 down: trigger 가 남았다(12장 마학영전 — 서진태가 쓰러지면 김신이 나온다)
static func _rescue(d: Dictionary) -> bool:
	if d["stage"] != "fight":
		return false
	var trs: Array = d["room"].get("triggers", [])
	for k in trs.size():
		var p: PackedStringArray = str(trs[k]["when"]).split(":")
		if d["fired"].has(k) or p[0] != "down":
			continue
		for c in d["cast"]:
			if d["heroes"][c].char_id == p[1]:
				return true
	return false


## 남은 적(쓰러지지도 물러나지도 않은)
static func _left(d: Dictionary) -> int:
	var left := 0
	for e in d["enemies"]:
		if e.alive() and not e.inert:
			left += 1
	return left


## 적이 다 쓰러져도 아직 방을 넘지 않는다: 대사가 남음 · 앞으로 터질 spawn 이 남음
static func _waits(d: Dictionary) -> bool:
	if int(d["n"]) < int(d["say_until"]):
		return true
	var trs: Array = d["room"].get("triggers", [])
	for k in trs.size():
		if d["fired"].has(k) or not trs[k].has("spawn"):
			continue
		var p: PackedStringArray = str(trs[k]["when"]).split(":")
		if p[0] in PENDING_SPAWN and (p[0] != "after" or d["fired"].has(int(p[1]))):
			return true
	return false


## survive 방에 escape trigger 가 있으면 버티기만으로는 깨지 않는다(빠져나가야)
static func _survive_escapes(d: Dictionary) -> bool:
	return d["room"].get("triggers", []).any(func(t): return t.has("escape"))


## 방을 깼다: 다음 방으로 넘는 동안 남은 적은 멈추고, 조작 인물 체력 일부 회복
static func _clear(d: Dictionary, got_away: bool) -> void:
	var w = d["world"]
	d["stage"] = "clear"
	d["t"] = 0
	d["cleared"] += 1
	d["times"][d["room"]["id"]] = d["fight_t"]
	for k in d["cast"]:
		var h = d["heroes"][k]
		if h.alive():
			h.hp = minf(h.hp_max, h.hp + h.hp_max * float(d["tbl"].HEAL_ON_CLEAR))
	for e in d["enemies"]:
		if e.alive() and not e.inert:
			e.inert = true                              # 따돌렸다 · 버텼다 — 남은 적은 멈춘다(방을 넘는 동안 치지 않는다)
			e.intent = {}
	if got_away:
		w.events.append(["escape", d["heroes"][d["ctrl"]]])
		_line(d, "escape", 2.8)
	elif _fade(d):
		pass
	elif not d["room"].has("talk"):
		_line(d, "clear", 2.4)


## 방 끝 연출(방 표 fade — [제목, 작은 글] 또는 lines.json 방 대사 키): 깸 · 끝 방에서 화면을 어둡게 하며 글. 띄웠으면 true
const FADE_T := 240              # fade 방은 깬 뒤 이만큼 머문다(4초)


static func _fade(d: Dictionary) -> bool:
	var v = d["room"].get("fade", null)
	if v is String:
		v = Lines.at("%s.rooms.%s.%s" % [d["tbl"].LINES, d["room"]["id"], v])
	if not (v is Array and v.size() >= 2):
		return false
	d["world"].events.append(["fade", str(v[0]), str(v[1]), FADE_T / 60.0])
	return true


## 진다: limit 시간 초과 · protect 인물이 쓰러짐
static func _lost(d: Dictionary) -> bool:
	var room: Dictionary = d["room"]
	if room.has("limit") and float(d["fight_t"]) >= float(room["limit"]) * 60.0:
		_lose(d, "timeout")
		return true
	for id in room.get("protect", []):
		for f in _who(d, str(id)):
			if not f.alive():
				_lose(d, "protect", f.name)
				return true
	return false


## 패배 글: 방 대사 rooms.<방>.<key> → 없으면 lines.json stage.<key>(이름 %s)
static func _lose(d: Dictionary, key: String, who := "") -> void:
	d["world"].over = "lose"
	var tl = Lines.at("%s.rooms.%s.%s" % [d["tbl"].LINES, d["room"]["id"], key])
	if not (tl is Array and tl.size() >= 2):
		tl = Lines.at("stage." + key)
		if tl is Array and tl.size() >= 2 and str(tl[0]).contains("%s"):
			tl = [str(tl[0]) % who, tl[1]]
	if tl is Array and tl.size() >= 2:
		d["lose_line"] = [str(tl[0]), str(tl[1])]


## 그 id(char_id 또는 덧붙임 tag)인 판 위의 사람들
static func _who(d: Dictionary, id: String) -> Array:
	return d["world"].fighters.filter(func(f): return f.char_id == id or str(d["tag_of"].get(f, "")) == id)


# ---- triggers ---------------------------------------------------------------------------------------------------

static func _triggers(d: Dictionary) -> void:
	var trs: Array = d["room"].get("triggers", [])
	for k in trs.size():
		if d["fired"].has(k) or not trs[k].get("requires", []).all(func(j): return d["fired"].has(int(j))):
			continue
		if not _when(d, str(trs[k]["when"])):
			continue
		d["fired"][k] = d["fight_t"]
		_do(d, trs[k])


static func _when(d: Dictionary, when: String) -> bool:
	var p: PackedStringArray = when.split(":")
	match p[0]:
		"down":
			var who: Array = _who(d, p[1]).filter(func(f): return not d["standing"].has(f))
			return not who.is_empty() and who.all(func(f): return not f.alive() or f.inert)
		"hp":
			return _who(d, p[1]).any(func(f): return f.alive() and f.hp <= f.hp_max * float(p[2]) + 0.001)
		"time":
			return float(d["fight_t"]) >= float(p[1]) * 60.0
		"x":
			return d["heroes"][d["ctrl"]].pos.x >= float(p[1])
		"after":
			var j := int(p[1])
			return d["fired"].has(j) and float(d["fight_t"]) - float(d["fired"][j]) >= float(p[2]) * 60.0
		"clear":
			return _left(d) == 0
		"survive":
			return d["room"].has("survive") and float(d["fight_t"]) >= float(d["room"]["survive"]) * 60.0
	push_error("stage trigger: 모르는 when %s" % when)
	return false


static func _do(d: Dictionary, t: Dictionary) -> void:
	var w = d["world"]
	for s in t.get("spawn", []):
		var f = _npc(d, str(s[0]), 1, s[1], s[2] if s.size() > 2 else {})
		f.oneshot_immune = f.char_id == d["boss_id"]
		w.events.append(["spawn", f])
	for s in t.get("spawn_allies", []):
		w.events.append(["spawn", _npc(d, str(s[0]), 0, s[1], s[2] if s.size() > 2 else {})])
	if t.has("boss"):
		d["boss_id"] = str(t["boss"])
		for e in d["enemies"]:
			if e.char_id == d["boss_id"]:
				e.oneshot_immune = true
	if t.has("recruit"):
		for f in _who(d, str(t["recruit"])):
			if d["enemies"].has(f):
				_recruit(d, f)
	for id in t.get("inert", []):
		for f in _who(d, str(id)):
			_calm(f)
	if t.get("calm", false):
		for f in d["enemies"] + d["allies"]:
			_calm(f)
	if t.has("learn"):
		_learn(d, str(t["learn"]))
	if t.has("cast"):
		_set_cast(d, t["cast"], t.get("cast_at", []))
	if t.has("bounds") or t.has("theme"):
		if t.has("bounds"):
			w.bounds = t["bounds"]
		d["theme"] = str(t.get("theme", d["theme"]))
		w.events.append(["stage_view"])                 # main.gd 가 무대 그림을 새 넓이 · 무대로 다시
	if t.has("escape"):
		d["esc"] = {"exit": t["escape"]["exit"], "secs": float(t["escape"]["secs"]), "t0": d["fight_t"]}
	_say_lines(d, t.get("say", []))
	if t.get("hold", false):
		d["hold_until"] = maxi(int(d["hold_until"]), int(d["say_until"]))
	if t.get("clear", false):
		d["clear_at"] = maxi(int(d["n"]), int(d["say_until"]))


## 조작 인물 묶음을 바꾼다: 빠지는 사람은 퇴장(쓰러진 사람은 그 자리에 남는다), 들어오는 사람은 cast_at 자리(없으면 왼쪽 가장자리)에.
## 지금 조작하는 사람이 빠지면 새 묶음의 첫 사람으로
static func _set_cast(d: Dictionary, ids: Array, at: Array) -> void:
	var T = d["tbl"]
	var w = d["world"]
	var now: Array = ids.map(func(id): return T.HEROES.find(str(id)))
	for k in d["cast"]:
		var h = d["heroes"][k]
		if not now.has(k) and h.alive():
			w.fighters.erase(h)
			w.pending = w.pending.filter(func(p): return p[0] != h and p[1] != h)
			w.events.append(["leave", h])
	var b: Rect2 = w.bounds
	for j in now.size():
		var h = d["heroes"][now[j]]
		if d["cast"].has(now[j]):
			continue
		d["ally_heroes"].erase(h)
		if not w.fighters.has(h):
			_place_hero(d, h, at[j] if j < at.size() else Vector2(b.position.x + 0.4, b.get_center().y))
			w.events.append(["spawn", h])
	d["cast"] = now
	if not now.has(int(d["ctrl"])):
		d["ctrl"] = now[0]
		w.events.append(["swap", d["heroes"][now[0]]])
	w.events.append(["cast"])


## 싸움에서 빠진다(치지도 맞지도 않는다)
static func _calm(f) -> void:
	if not f.alive() or f.inert:
		return
	f.inert = true
	f.set_state("idle")
	f.intent = {}


## trigger say: 줄 목록(또는 lines.json 방 대사 키)을 앞 대사 뒤에 이어 SAY_SECS 마다
static func _say_lines(d: Dictionary, say) -> void:
	var v = say
	if say is String:
		v = Lines.at("%s.rooms.%s.%s" % [d["tbl"].LINES, d["room"]["id"], say])
	if not (v is Array) or v.is_empty():
		return
	var start: int = maxi(int(d["say_until"]), int(d["n"]))
	var k := 0
	for ln in v:
		if ln is Array and ln.size() >= 2:
			var delay: float = float(start - int(d["n"])) / 60.0 + k * SAY_SECS
			d["world"].events.append(["line", str(ln[0]), str(ln[1]), SAY_SECS - 0.2, delay])
			k += 1
	d["say_until"] = start + int(k * SAY_SECS * 60.0)


## 쓰러진 · 물러난 적을 우리 편으로: 일으켜 세우고 체력 RECRUIT_HP 까지 · 팀 0. ROLES 에 moveset 이 있으면 아군 봇(기술 묶음 ·
## 게이지), 없으면 제 AI 로 적을 친다
static func _recruit(d: Dictionary, f) -> void:
	var T = d["tbl"]
	d["enemies"].erase(f)
	d["yield"].erase(f)
	f.team = 0
	f.inert = false
	f.hp_floor = 0.0
	f.set_state("idle")
	f.hp = maxf(f.hp, f.hp_max * RECRUIT_HP)
	f.posture = 0.0
	f.vel = Vector2.ZERO
	var role: Dictionary = T.ROLES.get(f.char_id, {})
	if role.has("moveset"):
		d["ais"].erase(f)
		f.is_boss = false
		f.moveset = role["moveset"]
		_ally_kit(f, role, Addendum.stats_at(f.char_id, T.PERIOD), Addendum.character(f.char_id))
		var b = Bot.new(f, null, _rng(int(d["seed"]) * 977 + 500 + d["allies"].size()))
		b.generic_skills = true
		d["bots"][f] = b
	d["allies"].append(f)
	d["world"].events.append(["recruit", f])


## 진행 사건까지(포함) 다시: 조작 인물들의 등급 · 아는 기술 → 기술 묶음. 새 기술 이름을 알림(line · learn 신호)
static func _learn(d: Dictionary, event: String) -> void:
	var evs := Common.events_until(Common.stage_of(event) + 1)
	for h in d["heroes"]:
		if not _has_progress(h.char_id):
			continue
		var before: Array = d.get("skills_all", {}).get(h, h.skills).map(func(e): return str(e["name"]))
		var pr: Array = Common.progress(h.char_id, evs)
		d["know"][h] = pr[1]
		d["base_rank"][h] = pr[0]
		_set_rank(d, h, str(d["room"].get("ranks", {}).get(h.char_id, pr[0])))
		var now: Array = h.skills.map(func(e): return str(e["name"]))
		_bare_skills(d, h, _room_bare(d, h))
		var got: Array = now.filter(func(n): return not before.has(n))
		if got.is_empty():
			continue
		d["world"].events.append(["learn", h, got])
		var ln = Lines.at("stage.learn")
		if ln is Array and ln.size() >= 2:
			d["world"].events.append(["line", str(ln[0]) % h.name, str(ln[1]) % ", ".join(got), 3.0, 0.0])


## 대화 방(방 표 talk — 5 · 7장처럼 싸움 없는 장면): 대사 rooms.<방>.say(줄마다 [제목, 작은 글, (refs)])를 SAY_SECS 마다 하나씩.
## 머무는 시간 = 줄 수 × SAY_SECS(방 표 talk 값이 더 길면 그것). 끝나면 clear 글 없이 다음 방
const SAY_SECS := 3.4


static func _say(d: Dictionary) -> void:
	var v = Lines.at("%s.rooms.%s.say" % [d["tbl"].LINES, d["room"]["id"]])
	if not v is Array:
		return
	for k in v.size():
		var ln = v[k]
		if ln is Array and ln.size() >= 2:
			d["world"].events.append(["line", str(ln[0]), str(ln[1]), SAY_SECS - 0.2, k * SAY_SECS])


static func talk_secs(d: Dictionary) -> float:
	var v = Lines.at("%s.rooms.%s.say" % [d["tbl"].LINES, d["room"]["id"]])
	var n: int = v.size() if v is Array else 0
	return maxf(float(d["room"].get("talk", 0.0)), n * SAY_SECS)


## 화면에 보일 두 사람: hero = 조작하는 사람, boss = 방의 큰 적(방 표 boss · trigger boss — 살아 있으면) → 아니면 조작하는 사람에게
## 가장 가까운 적
static func _focus(d: Dictionary) -> void:
	var h = d["heroes"][d["ctrl"]]
	d["hero"] = h
	var want := str(d.get("boss_id", d["room"].get("boss", "")))
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
