extends "res://tests/helpers.gd"
## 난이도(A 등급 — src/data/difficulty.gd 표 · 세이브 칸 · 판에 들어가는 배율, 사용자 2026-11-09 "쉬움, 보통, 어려움, 헬난이도").
## 보통은 늘 배율 1 — 지금까지의 수치 조정(봇 판 · 시험)이 그대로 맞아야 한다.

const Difficulty = preload("res://src/data/difficulty.gd")
const Save = preload("res://src/data/save.gd")
const Stage = preload("res://src/combat/stage.gd")
const Replay = preload("res://src/combat/replay.gd")


func test_table() -> void:
	check(Difficulty.IDS == ["easy", "normal", "hard", "hell"], "쉬움 · 보통 · 어려움 · 헬 넷")
	check(Difficulty.DEFAULT == "normal", "기본은 보통")
	var n := Difficulty.of("normal")
	check(float(n["foe_hp"]) == 1.0 and float(n["foe_dmg"]) == 1.0 and float(n["foe_cd"]) == 1.0, "보통은 배율 1")
	var prev := Difficulty.of("easy")
	for id in ["normal", "hard", "hell"]:
		var c := Difficulty.of(id)
		check(float(c["foe_hp"]) > float(prev["foe_hp"]) and float(c["foe_dmg"]) > float(prev["foe_dmg"])
			and float(c["foe_cd"]) < float(prev["foe_cd"]), "%s 는 앞 단계보다 적이 단단하고 아프고 빠르다" % id)
		prev = c
	check(Difficulty.of("zzz") == Difficulty.of("normal"), "모르는 난이도는 보통")
	check(Difficulty.next("easy") == "normal" and Difficulty.next("hell") == "easy" and Difficulty.next("zzz") == "normal",
		"버튼: 쉬움 → 보통 → 어려움 → 헬 → 쉬움")
	check(Difficulty.label("easy") == "쉬움" and Difficulty.label("hell") == "헬", "버튼 글")


func test_save_field() -> void:
	check(str(Save.fresh()["difficulty"]) == "normal", "새 세이브는 보통")
	check(str(Save.parse('{"v": 1, "cleared": {}}')["save"]["difficulty"]) == "normal", "난이도 칸이 없는 옛 세이브는 보통")
	check(str(Save.parse('{"v": 1, "difficulty": "hell"}')["save"]["difficulty"]) == "hell", "고른 난이도는 남는다")
	check(str(Save.parse('{"v": 1, "difficulty": "nightmare"}')["save"]["difficulty"]) == "normal", "모르는 난이도는 보통")


func test_stage_scales_foes_only() -> void:
	var n := Stage.make(1, {"chapter": "ch11"})
	var h := Stage.make(1, {"chapter": "ch11", "difficulty": "hell"})
	var e := Stage.make(1, {"chapter": "ch11", "difficulty": "easy"})
	var k := Difficulty.of("hell")
	check(Stage.make(1, {"chapter": "ch11", "difficulty": "normal"})["enemies"][0].hp_max == n["enemies"][0].hp_max, "보통 = 칸 없음")
	for i in n["enemies"].size():
		check(is_equal_approx(h["enemies"][i].hp_max, n["enemies"][i].hp_max * float(k["foe_hp"])), "헬 적 체력 배율 %d" % i)
		check(is_equal_approx(h["enemies"][i].dmg_k, n["enemies"][i].dmg_k * float(k["foe_dmg"])), "헬 적 피해 배율 %d" % i)
		check(is_equal_approx(h["enemies"][i].hp, h["enemies"][i].hp_max), "체력은 꽉 찬 채로 %d" % i)
		check(e["enemies"][i].hp_max < n["enemies"][i].hp_max, "쉬움 적 체력은 적다 %d" % i)
		check(is_equal_approx(h["ais"][h["enemies"][i]].cd_k, float(k["foe_cd"])), "헬 적 공격 사이가 짧다 %d" % i)
	for i in n["heroes"].size():
		check(h["heroes"][i].hp_max == n["heroes"][i].hp_max and h["heroes"][i].dmg_k == n["heroes"][i].dmg_k, "조작 인물은 그대로 %d" % i)
	for i in n["allies"].size():
		check(h["allies"][i].hp_max == n["allies"][i].hp_max, "아군은 그대로 %d" % i)


func test_stage_rooms_after_first_keep_difficulty() -> void:
	var n := Stage.make(1, {"chapter": "ch11", "room": 2})
	var h := Stage.make(1, {"chapter": "ch11", "room": 2, "difficulty": "hard"})
	check(h["enemies"].size() > 0 and h["enemies"][0].hp_max > n["enemies"][0].hp_max, "다른 방으로 시작해도 난이도가 붙는다")


func test_duel_scales_boss() -> void:
	var n := Duel.make(1)
	var h := Duel.make(1, {"difficulty": "hell"})
	var k := Difficulty.of("hell")
	check(Duel.make(1, {"difficulty": "normal"})["boss"].hp_max == n["boss"].hp_max, "보통 = 칸 없음")
	check(is_equal_approx(h["boss"].hp_max, n["boss"].hp_max * float(k["foe_hp"])), "헬 백도찬 체력")
	check(is_equal_approx(h["boss"].dmg_k, n["boss"].dmg_k * float(k["foe_dmg"])), "헬 백도찬 피해")
	check(h["hero"].hp_max == n["hero"].hp_max, "김신은 그대로")
	h["ai"].enter_phase2()
	n["ai"].enter_phase2()
	check(is_equal_approx(h["boss"].dmg_k, n["boss"].dmg_k * float(k["foe_dmg"])), "2차(안경 벗기)에도 난이도 배율이 남는다")


func test_replay_keeps_difficulty() -> void:
	var rec := Replay.start("duel", 3, {"difficulty": "hard"})
	check(is_equal_approx(Replay.make(rec)["boss"].hp_max, Duel.make(3, {"difficulty": "hard"})["boss"].hp_max), "결투 리플레이도 난이도로 다시 만든다")
	var rs := Replay.start("stage", 3, {"chapter": "ch11", "difficulty": "easy"})
	check(is_equal_approx(Replay.make(rs)["enemies"][0].hp_max, Stage.make(3, {"chapter": "ch11", "difficulty": "easy"})["enemies"][0].hp_max), "판 리플레이도")


func test_harder_is_harder_for_bot() -> void:
	# 같은 시드 · 봇: 쉬움이 헬보다 김신이 더 오래 살아남거나 더 많이 이긴다(배율이 실제로 판에 닿는다)
	var e := Duel.make(5, {"difficulty": "easy"})
	var h := Duel.make(5, {"difficulty": "hell"})
	for i in 1800:
		Duel.step(e)
		Duel.step(h)
	var score := func(d: Dictionary) -> float: return d["hero"].hp / d["hero"].hp_max - d["boss"].hp / d["boss"].hp_max
	check(score.call(e) > score.call(h), "쉬움이 헬보다 김신에게 유리하다 %.2f > %.2f" % [score.call(e), score.call(h)])
