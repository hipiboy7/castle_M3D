extends SceneTree
## 방별 봇 판 (창 없음): <godot> --headless --path . -s res://tests/sim_rooms.gd -- [장 id ..] [seeds=1,2,3,4]
## 장마다 · 방마다(대화 방 빼고) 그 방부터 시작해 방을 넘거나(W) · 지거나(L) · 5분이 지날 때까지(T). 줄마다 이긴 판 수 · 판마다 초[사람 체력] —
## 장 다듬기 기준(CLAUDE.md 1절): 보통 난이도 봇 8판에서 보스 방 5/8 이상. 장 id 를 안 주면 여러 사람 판 장 전부
const Stage = preload("res://src/combat/stage.gd")
const Campaign = preload("res://src/data/campaign.gd")

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var chs: Array = []
	var seeds := [1, 2, 3, 4]
	for a in args:
		if a.begins_with("ch"):
			chs.append(a)
		elif a.begins_with("seeds="):
			seeds = []
			for s in a.substr(6).split(","):
				seeds.append(int(s))
	if chs.is_empty():
		chs = Campaign.playable_ids().filter(func(i): return Campaign.kind(i) == "stage")
	for ch in chs:
		var T = Campaign.table(ch)
		for i in T.ROOMS.size():
			var room: Dictionary = T.ROOMS[i]
			if room.has("talk"):
				continue
			var wins := 0
			var info := []
			for s in seeds:
				var d := Stage.make(s, {"chapter": ch, "room": i})
				var w = d["world"]
				var rid: String = str(d["room"]["id"])
				var n := 0
				while n < 60 * 300 and w.over == "" and str(d["room"]["id"]) == rid:
					Stage.step(d)
					w.events.clear()
					n += 1
				var ok: bool = w.over == "win" or str(d["room"]["id"]) != rid
				if ok:
					wins += 1
				var hp := []
				for h in d["heroes"]:
					hp.append(int(h.hp))
				info.append("%s%.0fs%s" % ["W" if ok else ("L" if w.over != "" else "T"), n / 60.0, str(hp)])
			print("%s %d %-18s %d/%d  %s  boss=%s" % [ch, i, T.ROOMS[i]["id"], wins, seeds.size(), " ".join(info), str(room.get("boss", ""))])
	quit(0)
