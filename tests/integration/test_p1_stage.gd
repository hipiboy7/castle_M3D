extends "res://tests/helpers.gd"
## 통합 시험(B 등급) — 0장 프롤로그(군터 호텔) · 1장 회암시 판(src/combat/stage.gd + 장 표 prologue.gd · hoeam.gd +
## src/combat/enemy_ai.gd 0 · 1장 프로필): 같은 시드 같은 결과 · 봇이 0장을 끝낸다 · 1장 시점(김신 내성 중위 · 맨손 · 서진태 아군) ·
## 총잡이는 떨어져서 쏜다(kite) · 김대건 크로스 카운터 · 2차(배율 · 2차 표) · 강만재 하이가드 · 보스가 몇 초 만에 녹지 않되 1분 안에 쓰러진다.
## 스테이지(사용자 2026-11-10): 0장 = 호텔 한 맵(복도 → 군터의 방) · 1장 = 김대건을 쓰러뜨리면 회유 · 합류, 거리에서 강만재 → 윤덕수.

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
	var r := Stage.simulate(1, 60 * 220, {"chapter": "ch0"})
	check(r["over"] == "win" and int(r["cleared"]) == 2, "봇이 0장(주점 장면 → 복도 → 군터의 방)을 끝낸다 %s" % r)
	var secs := float(r["frames"]) / 60.0
	check(secs >= 60.0 and secs <= 170.0, "0장 판 길이 %.0f초 (봇 기준 60 ~ 170 — 주점 장면 약 1분)" % secs)


## 0장 한 맵: 경호원이 다 쓰러지고 문틀 너머(x 8.6)에 들어서야 군터가 일어선다 — 그 전에는 방을 넘지 않는다
func test_ch0_gunter_after_corridor() -> void:
	var d := Stage.make(1, {"chapter": "ch0", "room": 1})
	_past_intro(d, Prologue.INTRO_T)
	check(Prologue.ROOMS.size() == 3 and d["enemies"].all(func(e): return e.char_id == "gunter_guard"), "주점 + 스테이지 하나 + 끝 방 · 처음엔 경호원만")
	for e in d["enemies"]:
		e.hp = 0.0
		e.die()
	for i in 10:
		Stage.step(d, {})
		d["world"].events.clear()
	check(d["stage"] == "fight" and not d["enemies"].any(func(e): return e.char_id == "gunter"), "복도만 비우면 아직 — 군터의 방으로 걸어가야 %s" % d["stage"])
	d["heroes"][0].pos = Vector2(9.0, 0.0)
	Stage.step(d, {})
	check(d["enemies"].any(func(e): return e.char_id == "gunter" and e.alive()) and d["boss"] != null and d["boss"].char_id == "gunter",
		"문틀을 지나면 군터가 일어선다(큰 막대)")


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
	var kim = d["heroes"][0]
	_past_intro(d, Prologue.INTRO_T)
	for e in d["enemies"]:
		e.hp = 0.0
		e.die()
	kim.pos = Vector2(9.0, 0.0)                              # 군터의 방에 들어선다(trigger x)
	Stage.step(d, {})
	d["world"].events.clear()
	var g = null
	for e in d["enemies"]:
		if e.char_id == "gunter":
			g = e
	check(g != null and d["ais"][g].kite, "군터의 방 — 군터는 총잡이")
	if g == null:
		return
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
	var d2 := Stage.make(2, {"chapter": "ch0", "room": 1})
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


## 보스는 몇 초 만에 녹지 않지만 1분 안에 쓰러진다(봇 판 — 1장 보스는 모두 김신보다 아랫급, 사용자 2026-11-10 "보스가 김신보다 약한대도
## 강하게 표현될 때가 있음"). 김대건은 10초가 지나도 서 있고 김신을 맞힌다 · 그래도 1분 안. 수치 조정 회귀 막기
func test_bosses_last() -> void:
	var r := Stage.simulate(1, 60 * 14 + Hoeam.INTRO_T, {"chapter": "ch1", "room": 2})      # 맵이 넓어져(2026-11-12) 다가가는 데 몇 초 더
	check(int(r["cleared"]) == 0 and r["over"] == "", "김대건은 14초 안에 안 쓰러진다 %s" % r)
	var full: float = Stage.make(1, {"chapter": "ch1", "room": 2})["heroes"][0].hp_max
	check(float(r["heroes_hp"][0]) < full - 1.0, "김대건이 김신을 맞힌다 (hp %s / %.0f)" % [r["heroes_hp"], full])
	for c in [[2, "junkyard_dusk"], [3, "street"]]:
		var r2 := Stage.simulate(1, 60 * 120, {"chapter": "ch1", "room": c[0]})
		var t := float(r2["times"].get(c[1], -1)) / 60.0
		check(t > 10.0 and t < 60.0, "%s 봇이 1분 안에 넘는다 (%.0f초) %s" % [c[1], t, r2["times"]])


## 김대건을 쓰러뜨리면 우리 편으로 일어서고(recruit) 회유 대사(원작 016/016-020 · 017/029)가 도는 동안 모두 멈춘다 → 합류 대사 뒤에 방을 넘는다
func test_daegeon_persuaded_joins() -> void:
	var d := Stage.make(1, {"chapter": "ch1", "room": 2})
	_past_intro(d, Hoeam.INTRO_T)
	var dg = d["enemies"][0]
	dg.hp = 0.0
	dg.die()
	var lines: Array = []
	var recruited := false
	Stage.step(d, {})
	recruited = d["world"].events.any(func(e): return e[0] == "recruit" and e[1] == dg)
	for e in d["world"].events:
		if e[0] == "line":
			lines.append(str(e[2]))
	d["world"].events.clear()
	check(recruited and dg.team == 0 and dg.alive() and d["allies"].has(dg), "김대건이 우리 편으로 일어선다")
	check(lines.any(func(t): return t.contains("함께 윤덕수를")) and lines.any(func(t): return t.contains("각오들 단단히")),
		"회유 · 합류 대사(원작) %s" % [lines])
	check(Stage._held(d), "회유 대사 동안 모두 멈춘다")
	var n := 0
	while d["stage"] == "fight" and n < 60 * 40:
		Stage.step(d, {})
		d["world"].events.clear()
		n += 1
	check(d["stage"] == "clear" and n > 60 * 15, "대사가 다 지나간 뒤에 방을 넘는다 (%.1f초)" % (n / 60.0))


## 회암시 거리: 강만재가 먼저 — 강만재가 쓰러지면 윤덕수가 나서서 큰 막대가 된다. 김대건 · 서진태는 아군
func test_street_manjae_then_deoksu() -> void:
	var d := Stage.make(1, {"chapter": "ch1", "room": 3})
	_past_intro(d, Hoeam.INTRO_T)
	check(d["allies"].any(func(a): return a.char_id == "kimdaegeon") and d["allies"].any(func(a): return a.char_id == "jintae"), "합류한 김대건 · 서진태가 아군")
	check(not d["enemies"].any(func(e): return e.char_id == "yundeoksu"), "처음엔 윤덕수가 없다")
	for e in d["enemies"]:
		if e.char_id == "gangmanjae":
			e.hp = 0.0
			e.die()
	Stage.step(d, {})
	var yd = null
	for e in d["enemies"]:
		if e.char_id == "yundeoksu":
			yd = e
	check(yd != null and yd.oneshot_immune and str(d["boss_id"]) == "yundeoksu", "강만재가 쓰러지면 윤덕수가 마지막 보스로")
