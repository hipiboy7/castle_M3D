extends RefCounted
## 시험 공통 — check · 두 사람을 마주 세운 판 · 손 입력 한 프레임 · 신호 고르기 · 엇박 습득.
## tests/unit/* · tests/integration/* 가 extends "res://tests/helpers.gd" 로 쓴다(tests/run_tests.gd 가 두 폴더를 돈다).

const Duel = preload("res://src/combat/duel.gd")
const Fighter = preload("res://src/combat/fighter.gd")
const Moves = preload("res://src/data/moves.gd")
const World = preload("res://src/combat/world.gd")
const Skills = preload("res://src/data/skills.gd")
const Common = preload("res://src/data/common.gd")

var failures: Array = []


func check(cond: bool, msg: String) -> void:
	if not cond:
		failures.append(msg)


## 두 사람을 가까이 마주 세운 판 (AI · 봇은 쓰지 않고 손으로 입력을 준다)
func _close(dist := 0.8) -> Dictionary:
	var d := Duel.make(1)
	d["hero"].pos = Vector2(0, 0)
	d["hero"].facing = Vector2(1, 0)
	d["boss"].pos = Vector2(dist, 0)
	d["boss"].facing = Vector2(-1, 0)
	for f in [d["hero"], d["boss"]]:
		f.rank_power = false                 # 판정 · 쳐내기 시험은 등급 능력 없이(프레임 · 피해를 그대로 — 등급 능력은 test_rank_power)
		f.apply_rank_power()
	return d


## 손 입력으로 한 프레임 (보스 입력도 직접)
func _tick(d: Dictionary, hero_it := {}, boss_it := {}) -> void:
	var w = d["world"]
	d["hero"].intent = hero_it
	d["boss"].intent = boss_it
	w.tick()


func _run(d: Dictionary, n: int) -> void:
	for i in n:
		_tick(d)


func _events(d: Dictionary, kind: String) -> Array:
	var out := []
	for e in d["world"].events:
		if e[0] == kind:
			out.append(e)
	return out


## 백도찬이 엇박을 쓴 것처럼 — 김신이 엇박 계열을 얻는다 (엇엇박 · 엇박 · 반대발 엇박 · 각법 · 삼연타)
func _learn(d: Dictionary) -> void:
	Duel._boss_offbeat(d)
	d["world"].slowmo = 0
