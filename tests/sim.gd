extends SceneTree
## 시드별 자동 결투 결과 (창 없음): <godot> --headless --path . -s res://tests/sim.gd -- 1 2 3
## 봇(김신, 예고만 보고 받음) 대 백도찬 AI 를 최대 4분 돌려 승패 · 시간 · 체력 · 쳐내기 수를 찍는다 — 수치 조정용.

const Duel = preload("res://src/combat/duel.gd")


func _initialize() -> void:
	var seeds := OS.get_cmdline_user_args()
	if seeds.is_empty():
		seeds = PackedStringArray(["1", "2", "3"])
	for s in seeds:
		var r := Duel.simulate(int(s), 60 * 240)
		print("seed %s: %s  %.1fs  phase %d  hero %.0f  boss %.0f  %s" % [s, r["over"] if r["over"] != "" else "time",
			r["frames"] / 60.0, r["phase"], r["hero_hp"], r["boss_hp"], r["stats"]])
	quit(0)
