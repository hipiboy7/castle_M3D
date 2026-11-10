extends RefCounted
## 결투 한 판 만들기 · 한 프레임 진행 — 게임(main.gd) · 테스트 · 자동 플레이가 같은 것을 쓴다.
## 인물은 id(castle_common characters.json — kimshin · baekdochan)로 만든다. 이름 · 등급 · 기술 · 게이지 칸 · 차는 배율 ·
## 비용은 공통 데이터(src/data/common.gd)에서: 김신은 이 결투 앞까지의 진행(progress — 6장 백도찬전 = 내성 상위),
## 백도찬은 characters.json 의 처음 등급(톱).
## 체력 · 체간 · 속도는 3층(이 판 소유): 백도찬은 castle_M `castle_m/data/roster.py` 와 같다(400 · 220). 김신은 체간 60
## 그대로, 체력만 120 → 200 (초안 잠정 — 처음 잡는 터치 조작으로도 3D 손맛을 볼 만큼 버티게. 봇 6판 중 4판을 120 으로는 졌다).

const Fighter = preload("res://src/combat/fighter.gd")
const World = preload("res://src/combat/world.gd")
const BossAI = preload("res://src/combat/boss_ai.gd")
const Bot = preload("res://src/combat/bot.gd")
const Skills = preload("res://src/data/skills.gd")
const Kit = preload("res://src/data/skill_kit.gd")
const Common = preload("res://src/data/common.gd")
const Difficulty = preload("res://src/data/difficulty.gd")

const HERO := {"hp": 200.0, "posture": 60.0, "walk": 2.1, "run": 4.6, "stagger": 50}
const BOSS := {"hp": 400.0, "posture": 220.0, "walk": 1.9, "run": 4.0, "stagger": 100, "poise": 12.0}


## opts: difficulty(난이도 — 백도찬에게만 배율, src/data/difficulty.gd · 기본 보통)
static func make(seed_value: int, opts := {}) -> Dictionary:
	var w = World.new()
	var kim: Array = Common.progress(Skills.HERO_ID, Common.events_until(Common.stage_of(Skills.DUEL_EVENT)))
	var h = Fighter.new(str(Common.character(Skills.HERO_ID)["name"]), 0)
	h.char_id = Skills.HERO_ID
	h.hp = HERO["hp"]
	h.hp_max = HERO["hp"]
	h.posture_max = HERO["posture"]
	h.walk_speed = HERO["walk"]
	h.run_speed = HERO["run"]
	h.stagger_len = HERO["stagger"]
	h.moveset = {"combo": "k_slash1", "dash": "k_dash", "counter": "k_counter", "finisher": "k_finisher"}
	h.rank = kim[0]
	h.skills = Kit.hero_kit(Skills.HERO_ID, h.rank, Skills.entries(kim[1], h.rank))   # 진행 기술 + 원작 기술 — 등급 수까지(skill_kit)
	h.oneshot_immune = true
	h.gauge_max = Common.bars_for(h.rank) * Common.bar_points()
	h.gauge_rate = Common.gauge_rate(h.rank, Common.tech_of(Skills.HERO_ID))
	h.gauge = Skills.KIM_START_BARS * Common.bar_points()
	h.pos = Vector2(-2.2, 0.5)
	h.facing = Vector2(1, 0)
	var b = Fighter.new(str(Common.character(Skills.BOSS_ID)["name"]), 1)
	b.char_id = Skills.BOSS_ID
	b.is_boss = true
	b.oneshot_immune = true
	b.hp = BOSS["hp"]
	b.hp_max = BOSS["hp"]
	b.posture_max = BOSS["posture"]
	b.walk_speed = BOSS["walk"]
	b.run_speed = BOSS["run"]
	b.stagger_len = BOSS["stagger"]
	b.poise = BOSS["poise"]
	b.finisher_cap = World.FINISHER_CAP_BOSS
	b.phase2_at = World.PHASE2_AT
	b.rank = str(Common.character(Skills.BOSS_ID)["rank"])          # 보스는 게이지 없이 패턴으로 기술을 쓴다(gauge_max 0)
	b.pos = Vector2(2.2, -0.5)
	b.facing = Vector2(-1, 0)
	h.apply_rank_power()                                            # 등급 능력(체력 · 빠르기 — rank_power.gd)
	b.apply_rank_power()
	h.set_target(b)
	b.set_target(h)
	w.add(h)
	w.add(b)
	var r_ai := RandomNumberGenerator.new()
	r_ai.seed = seed_value
	var r_bot := RandomNumberGenerator.new()
	r_bot.seed = seed_value * 7919 + 1
	var ai = BossAI.new(b, h, r_ai)
	Difficulty.apply_foe(b, ai, opts.get("difficulty", Difficulty.DEFAULT))
	return {"world": w, "hero": h, "boss": b, "ai": ai, "bot": Bot.new(h, b, r_bot)}


## 한 프레임. hero_intent 가 null 이면 봇이 김신을 움직인다. 역경직 중에는 AI 도 멈춘다(사람 입력만 버퍼에 남는다).
static func step(d: Dictionary, hero_intent = null) -> void:
	var w = d["world"]
	if w.hitstop == 0 and w.over == "":
		d["boss"].intent = d["ai"].decide()
		d["hero"].intent = hero_intent if hero_intent != null else d["bot"].decide()
	else:
		d["boss"].intent = {}
		d["hero"].intent = hero_intent if hero_intent != null else {}
	w.tick()
	if w.phase == 2 and d["ai"].phase == 1:
		d["ai"].enter_phase2()
	for e in w.events.duplicate():
		if e[0] == "skill" and e[1] == d["boss"] and str(e[2]["id"]) == "s_offbeat":
			_boss_offbeat(d)


## 백도찬이 엇박을 쓰는 순간: 첫 번은 슬로모션, 김신이 보고 엇박 계열을 얻는다
## (castle_common progression.json 'duel_offbeat:baekdochan' 사건으로 늘어나는 기술 — rank_order 순으로 목록 맨 앞에)
static func _boss_offbeat(d: Dictionary) -> void:
	var h = d["hero"]
	var w = d["world"]
	if d.get("learned", false):
		return
	d["learned"] = true
	w.slowmo = maxi(w.slowmo, int(Skills.BAEK_OFFBEAT["slowmo"]))
	var got := Skills.entries(Skills.learned_at(h.char_id, Skills.DUEL_EVENT), h.rank)
	h.skills = Kit.hero_kit(h.char_id, h.rank, got + h.skills.filter(func(e): return str(e.get("src", "")) != "canon"))   # 얻은 기술이 앞 · 등급 수까지
	h.skill_idx = maxi(0, h.skill_index("offbeat"))        # 방금 본 엇박을 골라 둔다
	var names: Array = []
	for sk in got:
		names.append(sk["name"])
	w.events.append(["learn", h, " · ".join(names)])


## 그림 없이 끝까지(또는 frames 까지) 돌린 결과 — 테스트 · --autoplay --headless 가 쓴다
static func simulate(seed_value: int, frames: int) -> Dictionary:
	var d := make(seed_value)
	var w = d["world"]
	var n := 0
	while n < frames and w.over == "":
		step(d)
		w.events.clear()
		n += 1
	return summary(d, n)


static func summary(d: Dictionary, n: int) -> Dictionary:
	var w = d["world"]
	return {"frames": n, "over": w.over, "phase": w.phase, "hero_hp": snappedf(d["hero"].hp, 0.01),
		"boss_hp": snappedf(d["boss"].hp, 0.01), "stats": w.stats.duplicate()}
