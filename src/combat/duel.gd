extends RefCounted
## 결투 한 판 만들기 · 한 프레임 진행 — 게임(main.gd) · 테스트 · 자동 플레이가 같은 것을 쓴다.
## 체력 · 체간: 백도찬은 castle_M `castle_m/data/roster.py` 와 같다(400 · 220). 김신은 체간 60 그대로, 체력만
## 120 → 200 (초안 잠정 — 처음 잡는 터치 조작으로도 3D 손맛을 볼 만큼 버티게. 봇 6판 중 4판을 120 으로는 졌다).

const Fighter = preload("res://src/combat/fighter.gd")
const World = preload("res://src/combat/world.gd")
const BossAI = preload("res://src/combat/boss_ai.gd")
const Bot = preload("res://src/combat/bot.gd")
const Skills = preload("res://src/data/skills.gd")

const HERO := {"hp": 200.0, "posture": 60.0, "walk": 2.1, "run": 4.6, "stagger": 50}
const BOSS := {"hp": 400.0, "posture": 220.0, "walk": 1.9, "run": 4.0, "stagger": 100, "poise": 12.0}


static func make(seed_value: int) -> Dictionary:
	var w = World.new()
	var h = Fighter.new("김신", 0)
	h.hp = HERO["hp"]
	h.hp_max = HERO["hp"]
	h.posture_max = HERO["posture"]
	h.walk_speed = HERO["walk"]
	h.run_speed = HERO["run"]
	h.stagger_len = HERO["stagger"]
	h.moveset = {"combo": "k_slash1", "dash": "k_dash", "counter": "k_counter", "finisher": "k_finisher"}
	h.rank = Skills.KIM["rank"]
	h.skills = Skills.KIM_SKILLS
	h.gauge_max = Skills.KIM["bars"] * Skills.BAR
	h.gauge_rate = Skills.KIM["rate"]
	h.gauge = Skills.KIM_START_BARS * Skills.BAR
	h.pos = Vector2(-2.2, 0.5)
	h.facing = Vector2(1, 0)
	var b = Fighter.new("백도찬", 1)
	b.is_boss = true
	b.hp = BOSS["hp"]
	b.hp_max = BOSS["hp"]
	b.posture_max = BOSS["posture"]
	b.walk_speed = BOSS["walk"]
	b.run_speed = BOSS["run"]
	b.stagger_len = BOSS["stagger"]
	b.poise = BOSS["poise"]
	b.rank = Skills.RANK["톱"]
	b.pos = Vector2(2.2, -0.5)
	b.facing = Vector2(-1, 0)
	h.set_target(b)
	b.set_target(h)
	w.add(h)
	w.add(b)
	var r_ai := RandomNumberGenerator.new()
	r_ai.seed = seed_value
	var r_bot := RandomNumberGenerator.new()
	r_bot.seed = seed_value * 7919 + 1
	return {"world": w, "hero": h, "boss": b, "ai": BossAI.new(b, h, r_ai), "bot": Bot.new(h, b, r_bot)}


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
