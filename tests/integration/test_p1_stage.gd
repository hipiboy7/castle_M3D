extends "res://tests/helpers.gd"
## 통합 시험(B 등급) — 0장 프롤로그(군터 호텔) · 1장 회암시 판(src/combat/stage.gd + 장 표 prologue.gd · hoeam.gd +
## src/combat/enemy_ai.gd 0 · 1장 프로필): 같은 시드 같은 결과 · 봇이 0장을 끝낸다 · 1장 시점(김신 내성 중위 · 맨손 · 서진태 아군) ·
## 총잡이는 떨어져서 쏜다(kite) · 김대건 크로스 카운터 · 2차(배율 · 2차 표) · 강만재 하이가드 · 보스가 몇 초 만에 녹지 않는다.

const Stage = preload("res://src/combat/stage.gd")
const EnemyAI = preload("res://src/combat/enemy_ai.gd")
const Prologue = preload("res://src/data/prologue.gd")
const Hoeam = preload("res://src/data/hoeam.gd")
const Addendum = preload("res://src/data/addendum.gd")


## 들어서는 동안을 넘긴다(그동안 AI 는 쉬고 사람은 서 있다)
func _past_intro(d: Dictionary, n: int) -> void:
	for i in n + 1:
		Stage.step(d, {})
		d["world"].events.clear()


func test_p1_deterministic() -> void:
	for ch in ["ch0", "ch1"]:
		var a := Stage.simulate(5, 4000, {"chapter": ch})
		var b := Stage.simulate(5, 4000, {"chapter": ch})
		check(a == b, "%s 같은 시드면 같은 판\n%s\n%s" % [ch, a, b])
		check(Stage.simulate(6, 4000, {"chapter": ch}) != a, "%s 시드가 다르면 다른 판" % ch)


func test_bot_clears_ch0() -> void:
	var r := Stage.simulate(1, 60 * 150, {"chapter": "ch0"})
	check(r["over"] == "win" and int(r["cleared"]) == 2, "봇이 0장(복도 · 군터 방)을 끝낸다 %s" % r)
	var secs := float(r["frames"]) / 60.0
	check(secs >= 45.0 and secs <= 120.0, "0장 판 길이 %.0f초 (봇 기준 60 ~ 100)" % secs)


func test_ch1_start() -> void:
	var d := Stage.make(1, {"chapter": "ch1"})
	var kim = d["heroes"][0]
	check(kim.rank == "내성 중위" and str(kim.moveset["combo"]) == "kf_jab", "1부 처음 김신 — 내성 중위 · 맨손 %s %s" % [kim.rank, kim.moveset])
	check(kim.skill_index("kickarts") >= 0 and kim.skill_index("offbeat") < 0, "각법은 있고 엇박은 아직(백도찬 전)")
	check(d["allies"].size() == 1 and d["allies"][0].char_id == "jintae" and str(d["allies"][0].moveset["combo"]) == "j_jab",
		"공사장 골목 아군 서진태")
	var r := Stage.simulate(1, 60 * 60, {"chapter": "ch1"})
	check(r["times"].has("site_alley") and int(r["times"]["site_alley"]) >= 60 * 8, "공사장 골목을 넘는다(몇 초 만은 아니다) %s" % r["times"])


## 총잡이(kite): 서 있는 김신에게 다가붙지 않고 떨어져서 쏜다 — 군터 · 대머리 · 장발. 주먹잡이는 다가온다
func test_gunmen_keep_distance_and_shoot() -> void:
	var d := Stage.make(2, {"chapter": "ch0", "room": 1})
	var g = d["enemies"][0]
	var kim = d["heroes"][0]
	check(g.char_id == "gunter" and d["ais"][g].kite, "군터 방 — 군터는 총잡이")
	_past_intro(d, Prologue.INTRO_T)
	var closest := INF
	var shot := false
	var hp0: float = kim.hp
	for i in 60 * 6:
		Stage.step(d, {})
		closest = minf(closest, g.dist_to(kim))
		shot = shot or (g.state == "attack" and str(g.move["name"]) == "gt_revolver")
		d["world"].events.clear()
	check(shot and kim.hp < hp0, "탁자 밑 리볼버를 쏘고 서 있으면 맞는다 (hp %.1f → %.1f)" % [hp0, kim.hp])
	check(closest > 3.0, "다가붙지 않는다 (가장 가까이 %.2f m)" % closest)
	# 정장(주먹잡이)은 다가온다
	var d2 := Stage.make(2, {"chapter": "ch0"})
	_past_intro(d2, Prologue.INTRO_T)
	var k2 = d2["heroes"][0]
	var near := INF
	for i in 60 * 6:
		Stage.step(d2, {})
		for e in d2["enemies"]:
			if not d2["ais"][e].kite:
				near = minf(near, e.dist_to(k2))
		d2["world"].events.clear()
	check(near < 1.6, "주먹잡이는 붙는다 (%.2f m)" % near)


## 김대건 크로스 카운터(014/030-032): 김신이 치기 시작할 때 막지 않으면 맞받아 친다
func test_daegeon_cross_counter() -> void:
	var d := Stage.make(3, {"chapter": "ch1", "room": 2})
	var dg = d["enemies"][0]
	var ai = d["ais"][dg]
	var kim = d["heroes"][0]
	check(is_equal_approx(ai.counter_rate, float(EnemyAI.PROFILES["daegeon"]["counter"][1])), "맞받는 확률은 프로필 값")
	_past_intro(d, Hoeam.INTRO_T)
	ai.guard_rate = 0.0
	ai.counter_rate = 1.0
	ai.cooldown = 9999
	kim.pos = dg.pos + Vector2(-1.0, 0.0)
	kim.facing = Vector2(1, 0)
	dg.set_state("idle")
	Stage.step(d, {"attack": true, "face": Vector2(1, 0)})
	var used := false
	for i in 12:
		Stage.step(d, {})
		used = used or (dg.state == "attack" and str(dg.move["name"]) == "dg_cross")
		d["world"].events.clear()
	check(used, "김신이 치면 김대건이 맞받아 친다(크로스 카운터)")


## 2차: 김대건 '피떡이 돼야 시동' — 체력 절반에서 2차, 피해 · 맞받기가 늘고 2차 표(날아 무릎)에서 고른다
func test_daegeon_phase2() -> void:
	var d := Stage.make(1, {"chapter": "ch1", "room": 2})
	var dg = d["enemies"][0]
	var ai = d["ais"][dg]
	_past_intro(d, Hoeam.INTRO_T)
	var dmg0: float = dg.dmg_k
	var c0: float = ai.counter_rate
	dg.hp = dg.hp_max * 0.49
	d["world"]._check_hp(dg)
	check(dg.phase == 2 and is_equal_approx(dg.hp, dg.hp_max * 0.5), "체력 절반에서 2차 (phase %d hp %.0f)" % [dg.phase, dg.hp])
	for i in World.PHASE2_FREEZE + 2:                        # 2차로 넘어가는 멈춤(컷인) 뒤에 AI 가 2차로
		Stage.step(d, {})
		d["world"].events.clear()
	check(ai.phase == 2 and dg.dmg_k > dmg0 and ai.counter_rate > c0, "2차 배율 (dmg_k %.2f → %.2f · 맞받기 %.2f → %.2f)" % [dmg0, dg.dmg_k, c0, ai.counter_rate])
	var seen := {}
	for i in 40:
		ai._pick()
		for step in ai.queue:
			seen[str(step[0])] = true
	check(seen.has("dg_knee") and seen.has("dg_jab"), "2차 표에서 고른다(날아 무릎 · 잽 연타) %s" % [seen.keys()])


## 강만재 하이가드(006/009-011) — 같은 능력치 배율보다 더 자주 막는다
func test_manjae_high_guard() -> void:
	var d := Stage.make(1, {"chapter": "ch1", "room": 3})
	var mj = null
	var mob = null
	for e in d["enemies"]:
		if e.char_id == "gangmanjae":
			mj = e
		elif mob == null:
			mob = e
	check(mj != null and mob != null, "거리 방 — 강만재 · DS 정장")
	var g: float = Addendum.derive(Addendum.stats_at("gangmanjae", Hoeam.PERIOD))["guard"]
	check(is_equal_approx(d["ais"][mj].guard_rate, g + float(EnemyAI.PROFILES["manjae"]["guard_add"])), "하이가드 = 능력치 막기 + guard_add")


## 보스는 몇 초 만에 녹지 않는다(봇 판 — 김대건은 25초가 지나도 서 있고, 김신도 맞는다). 수치 조정 회귀 막기
func test_bosses_last() -> void:
	var r := Stage.simulate(1, 60 * 25 + Hoeam.INTRO_T, {"chapter": "ch1", "room": 2})
	check(int(r["cleared"]) == 0 and r["over"] == "", "김대건은 25초 안에 안 쓰러진다 %s" % r)
	check(float(r["heroes_hp"][0]) < 200.0, "김대건이 김신을 맞힌다 (hp %s)" % [r["heroes_hp"]])
	var r2 := Stage.simulate(1, 60 * 30 + Hoeam.INTRO_T, {"chapter": "ch1", "room": 4})
	check(int(r2["cleared"]) == 0, "윤덕수는 30초 안에 안 쓰러진다 %s" % r2)
