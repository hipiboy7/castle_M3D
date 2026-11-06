extends SceneTree
## 여러 사람 판 자동 판 결과 (창 없음): <godot> --headless --path . -s res://tests/sim_stage.gd -- [장 id] 1 2 3 4 5 6
## 장 id(ch0 · ch1 · ch11, 기본 ch11)의 사람 · 아군은 봇 대 방마다의 적. 방마다 싸운 시간(초) · 끝 방 · 체력 — 수치 조정용.
## [장 id] 다음에 room=N 을 주면 그 방부터(보스 방만 여러 번 돌릴 때).

const Stage = preload("res://src/combat/stage.gd")


func _initialize() -> void:
	var seeds := OS.get_cmdline_user_args()
	var opts := {"chapter": "ch11"}
	if not seeds.is_empty() and seeds[0].begins_with("ch"):
		opts["chapter"] = seeds[0]
		seeds.remove_at(0)
	if not seeds.is_empty() and seeds[0].begins_with("room="):
		opts["room"] = int(seeds[0].substr(5))
		seeds.remove_at(0)
	if seeds.is_empty():
		seeds = PackedStringArray(["1", "2", "3", "4", "5", "6"])
	var wins := 0
	for s in seeds:
		var r := Stage.simulate(int(s), 60 * 600, opts)
		var t := []
		for k in r["times"]:
			t.append("%s %.0fs" % [k, r["times"][k] / 60.0])
		if r["over"] == "win":
			wins += 1
		print("seed %s: %s  %.0fs  room %s  hp %s  %s  %s" % [s, r["over"] if r["over"] != "" else "time", r["frames"] / 60.0,
			r["room"], r["heroes_hp"], " · ".join(t), r["stats"]])
	print("wins %d/%d" % [wins, seeds.size()])
	quit(0)
