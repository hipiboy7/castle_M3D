extends SceneTree
## 11장 호텔 캐슬 자동 판 결과 (창 없음): <godot> --headless --path . -s res://tests/sim_stage.gd -- 1 2 3 4 5 6
## 봇 둘(김신 · 피우진, 교대 없이 둘 다 봇) + 아군 구일화 대 층마다의 적. 방마다 싸운 시간(초) · 끝 방 · 체력 — 수치 조정용.

const Stage = preload("res://src/combat/stage.gd")


func _initialize() -> void:
	var seeds := OS.get_cmdline_user_args()
	if seeds.is_empty():
		seeds = PackedStringArray(["1", "2", "3", "4", "5", "6"])
	var wins := 0
	for s in seeds:
		var r := Stage.simulate(int(s), 60 * 600)
		var t := []
		for k in r["times"]:
			t.append("%s %.0fs" % [k, r["times"][k] / 60.0])
		if r["over"] == "win":
			wins += 1
		print("seed %s: %s  %.0fs  room %s  hp %s  %s  %s" % [s, r["over"] if r["over"] != "" else "time", r["frames"] / 60.0,
			r["room"], r["heroes_hp"], " · ".join(t), r["stats"]])
	print("wins %d/%d" % [wins, seeds.size()])
	quit(0)
